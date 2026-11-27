import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/cultivation_repository.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/goal_history_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/goal_period.dart';
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
  late SharedPreferences prefs;

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
    prefs = await SharedPreferences.getInstance();
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

  test('balanced days are banked across goal switches; scale keeps '
      'accumulating', () async {
    final profile = await saveGoal(FitnessGoal.maintain);
    final today = CalendarDay.todayLocal();
    await logMeals(today, profile.tdee! - 50);
    await history();
    expect(container.read(mindProgressProvider).balancedDays, 1);
    expect(container.read(maintainBalanceProvider).leftKcal, closeTo(50, 0.01));

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
    // The closed stretch stays on the scale.
    final balance = container.read(maintainBalanceProvider);
    expect(balance.weighedDays, 1);
    expect(balance.leftKcal, closeTo(50, 0.01));
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

  group('past stretches from the goal history', () {
    final today = CalendarDay.todayLocal();
    DateTime ago(int n) => CalendarDay.addDays(today, -n);

    Future<void> setGoalHistory(List<GoalPeriod> periods) async {
      await GoalHistoryRepository(prefs).save(periods);
      container.read(goalPeriodsProvider.notifier).reload();
    }

    test(
      'maintain imports past stretches once and banks balanced days',
      () async {
        final profile = await saveGoal(FitnessGoal.maintain);
        final tdee = profile.tdee!;
        await setGoalHistory([
          GoalPeriod(goal: FitnessGoal.maintain, start: ago(20), end: ago(15)),
          GoalPeriod(goal: FitnessGoal.cut, start: ago(14), end: ago(8)),
          GoalPeriod(goal: FitnessGoal.maintain, start: ago(7)),
        ]);
        // The setUp listener already ran the (empty) import: start over.
        final repo = MaintainCultivationRepository(prefs);
        await repo.save(repo.load().copyWith(goalPeriodsImported: false));
        container.read(maintainCultivationStateProvider.notifier).reload();

        await logMeals(ago(18), tdee + 50); // balanced, past stretch
        await logMeals(ago(17), tdee - 60); // balanced, past stretch
        await logMeals(ago(16), tdee + 900); // surplus, past stretch
        await logMeals(ago(5), tdee); // balanced, current stretch

        var sections = await history();
        sections = await history();
        expect(sections, hasLength(2));
        final ledger = container.read(maintainCultivationStateProvider);
        expect(ledger.goalPeriodsImported, isTrue);
        expect(ledger.frozenBalancedDays, 2);
        expect(ledger.openSegment?.start, ago(7));
        expect(container.read(mindProgressProvider).balancedDays, 3);

        // The scale sums every stretch, past and current.
        final balance = container.read(maintainBalanceProvider);
        expect(balance.weighedDays, 4);
        expect(balance.rightKcal, closeTo(950, 0.01));
        expect(balance.leftKcal, closeTo(60, 0.01));
        expect(balance.balancedDays, 3);

        await history();
        expect(container.read(mindProgressProvider).balancedDays, 3);
        expect(
          container.read(maintainCultivationStateProvider).frozenBalancedDays,
          2,
        );
      },
    );

    test('cut imports a missing past round once and banks its kcal', () async {
      final profile = await saveGoal(FitnessGoal.cut);
      final tdee = profile.tdee!;
      container.listen(cultivationHistoryProvider, (_, _) {});
      await container.read(cultivationHistoryProvider.future);
      await setGoalHistory([
        GoalPeriod(goal: FitnessGoal.cut, start: ago(20), end: ago(15)),
        GoalPeriod(goal: FitnessGoal.maintain, start: ago(14), end: ago(1)),
        GoalPeriod(goal: FitnessGoal.cut, start: today),
      ]);
      final repo = CultivationRepository(prefs);
      await repo.save(repo.load().copyWith(goalPeriodsImported: false));
      container.read(cutCultivationStateProvider.notifier).reload();

      await logMeals(ago(18), tdee - 500);

      Future<List<CultivationHistorySection>> cutHistory() async {
        container.invalidate(cultivationHistoryProvider);
        return container.read(cultivationHistoryProvider.future);
      }

      var sections = await cutHistory();
      sections = await cutHistory();
      expect(sections, hasLength(2));
      final ledger = container.read(cutCultivationStateProvider);
      expect(ledger.goalPeriodsImported, isTrue);
      expect(ledger.frozenKcal, closeTo(500, 0.01));

      await cutHistory();
      expect(
        container.read(cutCultivationStateProvider).frozenKcal,
        closeTo(500, 0.01),
      );
    });
  });
}
