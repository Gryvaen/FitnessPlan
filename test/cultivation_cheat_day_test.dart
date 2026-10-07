import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/cultivation_repository.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/data/repositories/step_repository.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cultivation.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/profile/cultivation_history_page.dart';
import 'package:diet/ui/profile/cultivation_page.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CutProfileNotifier extends ProfileNotifier {
  @override
  UserProfile? build() => const UserProfile(
    sex: Sex.male,
    age: 30,
    heightCm: 175,
    weightKg: 75,
    activity: ActivityLevel.moderate,
    goal: FitnessGoal.cut,
    targets: MacroTargets(calories: 2000, proteinG: 100, carbG: 200, fatG: 70),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cheat marker alone creates a fixed negative history day', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = CalendarDay.todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await CultivationRepository(prefs).save(
      CutCultivationState(
        frozenKcal: 2000,
        segments: [CutCultivationSegment(start: yesterday)],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    final markers = DayMarkerRepository(db);
    await markers.setCheatMeal(yesterday);

    Future<CultivationDayRecord> yesterdayRecord() async {
      container.invalidate(cultivationHistoryProvider);
      final sections = await container.read(cultivationHistoryProvider.future);
      return sections.single.days.singleWhere((d) => d.date == yesterday);
    }

    var record = await yesterdayRecord();
    expect(record.totalKcal, kCheatMealCultivationPenaltyKcal);
    expect(record.cheatPenaltyKcal, -1000);
    expect(record.stepsKcal, 0);
    expect(record.dietKcal, 0);
    expect(
      container.read(cultivationProgressProvider).kgLost,
      closeTo(1000 / kKcalPerKg, 0.000001),
    );

    await StepRepository(db).setStepsForDay(yesterday, 10000);
    final foodId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '放纵餐测试食材',
            category: '自定义',
            kcalPer100: 200,
            proteinPer100: 1,
            carbPer100: 2,
            fatPer100: 3,
          ),
        );
    final meals = MealRepository(db);
    for (final type in [MealType.breakfast, MealType.dinner]) {
      await db
          .into(db.mealEntries)
          .insert(
            MealEntriesCompanion.insert(
              date: yesterday,
              mealType: type.name,
              foodId: foodId,
              foodName: '放纵餐测试食材',
              grams: 100,
              calories: 200,
              proteinG: 1,
              carbG: 2,
              fatG: 3,
            ),
          );
    }
    record = await yesterdayRecord();
    expect(record.totalKcal, -1000);
    expect(record.stepsKcal, 0);
    expect(record.dietKcal, 0);
    expect(
      (await meals.forDay(yesterday)).fold<double>(0, (s, m) => s + m.calories),
      400,
    );

    await markers.clear(yesterday);
    record = await yesterdayRecord();
    expect(record.cheatPenaltyKcal, 0);
    expect(record.stepsKcal, 400);
    expect(record.totalKcal, greaterThanOrEqualTo(400));
    expect(
      container.read(cultivationProgressProvider).kgLost,
      closeTo((2000 + record.totalKcal) / kKcalPerKg, 0.000001),
    );

    await markers.setRestDay(yesterday);
    record = await yesterdayRecord();
    expect(record.totalKcal, 0);
    expect(record.cheatPenaltyKcal, 0);
  });

  test('today cheat marker contributes -1000 without meal logs', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    final today = CalendarDay.todayLocal();
    final markers = DayMarkerRepository(db);
    await markers.setCheatMeal(today);
    final subscription = container.listen(dayMarkerProvider(today), (_, _) {});
    addTearDown(subscription.close);
    await container.read(dayMarkerProvider(today).future);
    expect(container.read(cultivationStepsTodayProvider), 0);
    expect(container.read(cultivationDietKcalTodayProvider), 0);
    expect(container.read(cultivationCheatPenaltyTodayProvider), -1000);
    expect(container.read(cultivationTodayKcalProvider), -1000);
  });

  testWidgets('history labels the fixed cheat deduction separately', (
    tester,
  ) async {
    final today = CalendarDay.todayLocal();
    final section = CultivationHistorySection(
      segment: CutCultivationSegment(start: today),
      days: [
        CultivationDayRecord(
          date: today,
          stepsKcal: 0,
          dietKcal: 0,
          cheatPenaltyKcal: -1000,
          workout: const DayWorkoutSnapshot(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cultivationHistoryProvider.overrideWith((ref) async => [section]),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CultivationHistoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('放纵默认 -1,000 kcal'), findsOneWidget);
    expect(find.text('合计 -1,000 kcal'), findsNWidgets(2));
    expect(find.text('步数贡献 0 kcal'), findsOneWidget);
    expect(find.text('饮食 0 kcal'), findsOneWidget);
  });

  testWidgets('today realm shows the fixed cheat deduction', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(_CutProfileNotifier.new),
          cultivationProgressProvider.overrideWithValue(
            const CultivationProgress(
              kgLost: 0,
              realm: CultivationRealm.qiRefining,
              layer: 1,
              layerProgress: 0,
              kcalToNextLayer: 2500,
              kcalToNextRealm: 23000,
            ),
          ),
          cultivationStepsTodayProvider.overrideWithValue(0),
          cultivationDietKcalTodayProvider.overrideWithValue(0),
          cultivationCheatPenaltyTodayProvider.overrideWithValue(-1000),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CultivationGoalScreen(goal: FitnessGoal.cut),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('放纵默认 -1,000 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
