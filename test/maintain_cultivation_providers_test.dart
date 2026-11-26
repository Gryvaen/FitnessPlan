import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/maintain_balance.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late int foodId;

  Future<UserProfile> saveGoal(FitnessGoal goal) {
    return container
        .read(profileProvider.notifier)
        .save(
          sex: Sex.male,
          age: 30,
          heightCm: 175,
          weightKg: 75,
          activity: ActivityLevel.moderate,
          goal: goal,
        );
  }

  Future<void> logMeals(DateTime day, double totalKcal) async {
    for (final type in [MealType.breakfast, MealType.dinner]) {
      await db
          .into(db.mealEntries)
          .insert(
            MealEntriesCompanion.insert(
              date: day,
              mealType: type.name,
              foodId: foodId,
              foodName: 'test',
              grams: 100,
              calories: totalKcal / 2,
              proteinG: 1,
              carbG: 1,
              fatG: 1,
            ),
          );
    }
  }

  Future<List<MaintainHistorySection>> history() async {
    container.invalidate(maintainHistoryProvider);
    return container.read(maintainHistoryProvider.future);
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    // Keep autoDispose providers alive across reads.
    container.listen(maintainHistoryProvider, (_, _) {});
    foodId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: 'test',
            category: '自定义',
            kcalPer100: 100,
            proteinPer100: 1,
            carbPer100: 1,
            fatPer100: 1,
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'entering maintain opens a stretch; a TDEE-level day is balanced',
    () async {
      final profile = await saveGoal(FitnessGoal.maintain);
      final today = CalendarDay.todayLocal();
      expect(
        container.read(maintainCultivationStateProvider).openSegment?.start,
        today,
      );

      final tdee = profile.tdee!;
      await logMeals(today, tdee + 100);
      final sections = await history();
      final day = sections.single.days.single;
      expect(day.entry.netKcal, closeTo(100, 0.01));
      expect(day.entry.balanced, isTrue);

      final balance = container.read(maintainBalanceProvider);
      expect(balance.rightKcal, closeTo(100, 0.01));
      expect(balance.leftKcal, 0);
      expect(container.read(mindProgressProvider).balancedDays, 1);
      expect(container.read(maintainTodayEntryProvider)?.balanced, isTrue);
    },
  );

  test('a single meal type keeps the day off the scale', () async {
    await saveGoal(FitnessGoal.maintain);
    final today = CalendarDay.todayLocal();
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: today,
            mealType: MealType.lunch.name,
            foodId: foodId,
            foodName: 'test',
            grams: 100,
            calories: 3000,
            proteinG: 1,
            carbG: 1,
            fatG: 1,
          ),
        );
    final sections = await history();
    expect(sections.single.days, isEmpty);
    expect(container.read(maintainTodayEntryProvider), isNull);
  });

  test('indulgence day uses the user surplus even with meals logged', () async {
    final profile = await saveGoal(FitnessGoal.maintain);
    final today = CalendarDay.todayLocal();
    await logMeals(today, profile.tdee!);
    await DayMarkerRepository(db).setCheatMeal(today, penaltyKcal: 800);

    final day = (await history()).single.days.single;
    expect(day.entry.netKcal, closeTo(800, 0.01));
    expect(day.entry.estimated, isTrue);
    expect(day.entry.balanced, isFalse);
    expect(
      container.read(maintainBalanceProvider).rightKcal,
      closeTo(800, 0.01),
    );
  });

  test('balanced days are banked across goal switches; scale resets', () async {
    final profile = await saveGoal(FitnessGoal.maintain);
    final today = CalendarDay.todayLocal();
    await logMeals(today, profile.tdee! - 50);
    await history();
    expect(container.read(mindProgressProvider).balancedDays, 1);

    await saveGoal(FitnessGoal.cut);
    var ledger = container.read(maintainCultivationStateProvider);
    expect(ledger.openSegment, isNull);
    expect(ledger.frozenBalancedDays, 1);

    await saveGoal(FitnessGoal.maintain);
    ledger = container.read(maintainCultivationStateProvider);
    // Previous stretch ended today, so the new one starts tomorrow.
    expect(ledger.openSegment?.start, today.add(const Duration(days: 1)));
    final sections = await history();
    expect(sections, hasLength(2));
    expect(container.read(maintainBalanceProvider).weighedDays, 0);
    expect(container.read(mindProgressProvider).balancedDays, 1);
    expect(container.read(mindProgressProvider).realm, MindRealm.restless);
  });

  test(
    'switching away from cut with live cut history does not throw',
    () async {
      await saveGoal(FitnessGoal.cut);
      container.listen(cultivationProgressProvider, (_, _) {});
      await container.read(cultivationHistoryProvider.future);
      await saveGoal(FitnessGoal.maintain);
      expect(container.read(cutCultivationStateProvider).openSegment, isNull);
      expect(
        container.read(maintainCultivationStateProvider).openSegment,
        isNotNull,
      );
      await saveGoal(FitnessGoal.cut);
      expect(
        container.read(cutCultivationStateProvider).openSegment,
        isNotNull,
      );
    },
  );
}
