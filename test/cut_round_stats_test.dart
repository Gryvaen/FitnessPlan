import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/step_repository.dart';
import 'package:diet/data/repositories/weight_repository.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/cut_round_stats.dart';
import 'package:diet/domain/day_marker.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/profile/cut_round_stats_view.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = CalendarDay.todayLocal();
DateTime _ago(int days) => CalendarDay.addDays(_today, -days);

/// One day-workout group with items given as (name, done, sets).
Future<void> _group(
  AppDatabase db,
  DateTime day,
  String? planName,
  List<(String, bool, int)> items, {

  /// Load entered per exercise name: (kg, entry unit).
  Map<String, (double, String)> loads = const {},
}) async {
  final groupId = await db
      .into(db.dayWorkouts)
      .insert(
        DayWorkoutsCompanion.insert(date: day, planName: Value(planName)),
      );
  for (final (name, done, sets) in items) {
    final itemId = await db
        .into(db.dayWorkoutItems)
        .insert(
          DayWorkoutItemsCompanion.insert(
            dayWorkoutId: groupId,
            exerciseId: name.hashCode,
            exerciseName: name,
            targetSets: 3,
            targetReps: 10,
            done: Value(done),
            actualWeightKg: Value(loads[name]?.$1),
            actualWeightUnit: Value(loads[name]?.$2),
          ),
        );
    for (var i = 1; i <= sets; i++) {
      await db
          .into(db.workoutSetLogs)
          .insert(
            WorkoutSetLogsCompanion.insert(
              date: day,
              exerciseId: name.hashCode,
              exerciseName: name,
              setIndex: i,
              reps: const Value(10),
              dayWorkoutItemId: Value(itemId),
            ),
          );
    }
  }
}

/// Training, steps and weights over the last few days plus noise outside.
Future<void> _seed(AppDatabase db) async {
  // Catalog rows give 卧推 / 划船 a body part; 深蹲 stays unknown.
  for (final (name, category) in [('卧推', 'chest'), ('划船', 'back')]) {
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: Value(name.hashCode),
            name: name,
            unit: 'reps',
            category: Value(category),
          ),
        );
  }
  await _group(db, _ago(3), '上肢', [('卧推', true, 3), ('划船', false, 0)]);
  // Only scheduled: the plan and its exercise don't count.
  await _group(db, _ago(3), '腿', [('深蹲', false, 0)]);
  // Two groups of the same plan on one day count once; done with no sets
  // still counts.
  await _group(db, _ago(2), '上肢', [('卧推', false, 2)]);
  await _group(db, _ago(2), ' 上肢 ', [('划船', true, 0)]);
  // 「其他」: not a plan, but its exercise counts.
  await _group(db, _ago(1), null, [('卧推', false, 1)]);
  await _group(db, _ago(10), '上肢', [('卧推', true, 3)]);

  final steps = StepRepository(db);
  await steps.setStepsForDay(_ago(3), 1000);
  await steps.setStepsForDay(_ago(2), 2000);
  await steps.setStepsForDay(_today, 500);
  await steps.setStepsForDay(_ago(10), 9999);

  for (final (day, kg) in [
    (_ago(10), 85.0),
    (_ago(3), 80.0),
    (_ago(1), 79.2),
  ]) {
    await db
        .into(db.weightLogs)
        .insert(WeightLogsCompanion.insert(date: day, weightKg: kg));
  }
}

DailyNutritionTarget _target({bool legacy = false}) => DailyNutritionTarget(
  date: _today,
  calories: 2000,
  proteinG: 150,
  carbG: 200,
  fatG: 60,
  source: TargetSource.profile,
  estimatedTdee: 2500,
  isLegacyEstimate: legacy,
);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seed(db);
  });

  tearDown(() => db.close());

  test('training is tallied by plan and exercise name', () async {
    final tally = await WorkoutRepository(
      db,
    ).trainingTallyBetween(_ago(3), _today);
    expect(tally.plans, [(name: '上肢', count: 2)]);
    expect(tally.exercises, [
      (name: '卧推', count: 3, sets: 6),
      (name: '划船', count: 1, sets: 0),
    ]);
    expect(tally.trainingDays, 3);
  });

  test('steps and weights are bounded by the round, ends included', () async {
    expect(await StepRepository(db).totalStepsBetween(_ago(3), _today), 3500);
    final weights = WeightRepository(db);
    expect(
      [for (final w in await weights.logsBetween(_ago(3), _today)) w.weightKg],
      [80.0, 79.2],
    );
    expect(await weights.logsBetween(_ago(30), _ago(20)), isEmpty);
  });

  group('roundWeightTrend', () {
    List<({DateTime day, double kg})> logs(Map<int, double> byDaysAgo) => [
      for (final e in byDaysAgo.entries) (day: _ago(e.key), kg: e.value),
    ];

    test('drops the cheat day and the 3 days after it', () {
      final r = roundWeightTrend(
        // Cheat 10 days ago: 10, 9 and 7 are dropped, 11 and 6 are kept.
        logs: logs({11: 80.0, 10: 82.0, 9: 81.5, 7: 81.0, 6: 79.6}),
        cheatDays: {_ago(10)},
      );
      expect(r.excluded, 3);
      expect(r.trend!.startKg, 80.0);
      expect(r.trend!.endKg, 79.6);
    });

    test('a cheat day just before the round still counts', () {
      final r = roundWeightTrend(
        logs: logs({5: 82.0, 1: 79.0}),
        cheatDays: {_ago(7)},
      );
      expect(r.excluded, 1);
      expect(r.trend!.startKg, isNull);
      expect(r.trend!.endKg, 79.0);
      expect(r.trend!.endSamples, 1);
    });

    test('nothing left, or nothing at all', () {
      final all = roundWeightTrend(
        logs: logs({2: 81.0, 1: 80.5}),
        cheatDays: {_ago(3)},
      );
      expect(all.trend, isNull);
      expect(all.excluded, 2);
      final none = roundWeightTrend(logs: const [], cheatDays: const {});
      expect(none.trend, isNull);
      expect(none.excluded, 0);
    });

    test('fewer than 6 kept are split in halves', () {
      final r = roundWeightTrend(
        logs: logs({4: 82.0, 3: 81.0, 2: 80.0, 1: 79.0}),
        cheatDays: const {},
      );
      expect(r.trend!.startSamples, 2);
      expect(r.trend!.startKg, 81.5);
      expect(r.trend!.endSamples, 2);
      expect(r.trend!.endKg, 79.5);
    });

    test('6 or more kept average the first and last 3', () {
      final r = roundWeightTrend(
        logs: logs({for (var i = 8; i >= 1; i--) i: 80.0 + i}),
        cheatDays: const {},
      );
      expect(r.trend!.startSamples, 3);
      expect(r.trend!.startKg, closeTo(87.0, 1e-9));
      expect(r.trend!.endSamples, 3);
      expect(r.trend!.endKg, closeTo(82.0, 1e-9));
    });
  });

  test('body parts fold legacy keys and unknown exercises', () async {
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: Value('平板支撑'.hashCode),
            name: '平板支撑',
            unit: 'seconds',
            category: const Value('core_timed'),
          ),
        );
    await _group(db, _ago(1), null, [('平板支撑', false, 2)]);
    await _group(db, _ago(2), null, [('自创动作', true, 1)]);
    final tally = await WorkoutRepository(
      db,
    ).trainingTallyBetween(_ago(3), _today);
    final byPart = {for (final c in tally.categories) c.name: c};
    // 卧推 on 3 days (twice on one of them still once), 6 sets.
    expect(byPart['chest'], (name: 'chest', count: 3, sets: 6));
    expect(byPart['back'], (name: 'back', count: 1, sets: 0));
    expect(byPart['core'], (name: 'core', count: 1, sets: 2));
    expect(byPart['other'], (name: 'other', count: 1, sets: 1));
    expect(byPart.length, 4);
  });

  test('diet verdict follows the calendar', () {
    expect(dietDayMet(target: _target(), intake: 2000, marker: null), isTrue);
    expect(dietDayMet(target: _target(), intake: 2001, marker: null), isFalse);
    expect(
      dietDayMet(
        target: _target(),
        intake: 2500,
        marker: DayMarkerType.carbLoad,
      ),
      isFalse,
    );
    for (final marker in [DayMarkerType.cheatMeal, DayMarkerType.restDay]) {
      expect(
        dietDayMet(target: _target(), intake: 2500, marker: marker),
        isNull,
      );
    }
    expect(dietDayMet(target: _target(), intake: null, marker: null), isNull);
    expect(dietDayMet(target: null, intake: 1500, marker: null), isNull);
    expect(
      dietDayMet(target: _target(legacy: true), intake: 1500, marker: null),
      isNull,
    );
  });

  test('round stats combine every total', () async {
    final foodId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '测试',
            category: '自定义',
            kcalPer100: 100,
            proteinPer100: 1,
            carbPer100: 1,
            fatPer100: 1,
          ),
        );
    // 3 days ago within target, 2 days ago over, yesterday a cheat day (not
    // judged), today unfinished (not judged).
    for (final (day, intake) in [
      (_ago(3), 1500.0),
      (_ago(2), 2100.0),
      (_ago(1), 3000.0),
      (_today, 2500.0),
    ]) {
      await db
          .into(db.dailyNutritionTargets)
          .insert(
            DailyNutritionTargetsCompanion.insert(
              date: StrategyDates.encode(day),
              calories: 2000,
              proteinG: 100,
              carbG: 200,
              fatG: 70,
              estimatedTdee: const Value(2400),
              source: 'strategy',
              updatedAt: day,
            ),
          );
      await db
          .into(db.mealEntries)
          .insert(
            MealEntriesCompanion.insert(
              date: day,
              mealType: MealType.lunch.name,
              foodId: foodId,
              foodName: '测试',
              grams: 100,
              calories: intake,
              proteinG: 1,
              carbG: 1,
              fatG: 1,
            ),
          );
    }
    await DayMarkerRepository(db).setCheatMeal(_ago(1));

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    final stats = await container.read(
      cutRoundStatsProvider((start: _ago(3), end: null)).future,
    );
    expect(stats.dayCount, 4);
    expect(stats.steps, 3500);
    expect(stats.avgSteps, 875);
    expect(stats.training.trainingDays, 3);
    // Yesterday is a cheat day, so its 79.2 kg weigh-in is dropped.
    expect(stats.weightExcluded, 1);
    expect(stats.weight!.endKg, 80.0);
    expect(stats.weight!.startKg, isNull);
    expect(stats.dietMetDays, 1);
    expect(stats.dietMissedDays, 1);
  });

  for (final (locale, width) in [
    (const Locale('zh'), 412.0),
    (const Locale('zh'), 320.0),
    (const Locale('en'), 320.0),
  ]) {
    testWidgets('stats tab lays out cleanly: $locale @ $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CutRoundStatsView(
                segment: CutCultivationSegment(start: _ago(3)),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (locale.languageCode == 'zh') {
        expect(find.text('第 4 天'), findsOneWidget);
        expect(find.text('3,500 步'), findsOneWidget);
        expect(find.text('875 步'), findsOneWidget);
        expect(find.text('80.0 kg'), findsOneWidget);
        expect(find.text('79.2 kg'), findsOneWidget);
        expect(find.text('较起始 −0.8 kg'), findsOneWidget);
        expect(find.text('最终'), findsOneWidget);
        expect(find.text('单次称重'), findsNWidgets(2));
        expect(find.textContaining('已排除'), findsNothing);
        expect(find.text('胸'), findsOneWidget);
        expect(find.text('背'), findsOneWidget);
        // The counting rules are folded until tapped.
        const rule = '每天实际记录的步数直接相加';
        expect(find.textContaining(rule), findsNothing);
        await tester.tap(find.text('统计说明'));
        await tester.pumpAndSettle();
        expect(find.textContaining(rule), findsOneWidget);
        expect(find.text('上肢'), findsOneWidget);
        // Plan-session total and the 上肢 row.
        expect(find.text('2 次'), findsNWidgets(2));
        expect(find.text('卧推'), findsOneWidget);
        // 卧推 and 胸 rows.
        expect(find.text('3 次'), findsNWidgets(2));
        expect(find.text('6 组'), findsNWidgets(2));
        expect(find.text('划船'), findsOneWidget);
        // 划船 and 背 rows.
        expect(find.text('0 组'), findsNWidgets(2));
        final noLifts = find.text('本轮动作暂无重量记录');
        await tester.scrollUntilVisible(noLifts, 300);
        expect(noLifts, findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('stats tab notes weigh-ins dropped after a cheat day', (
    tester,
  ) async {
    await DayMarkerRepository(db).setCheatMeal(_ago(1));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
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
          home: Scaffold(
            body: CutRoundStatsView(
              segment: CutCultivationSegment(start: _ago(3)),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('80.0 kg'), findsOneWidget);
    expect(find.text('79.2 kg'), findsNothing);
    expect(find.text('已排除放纵日后 3 天内的 1 次称重'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  /// 卧推 loads: 60 kg, then 62.5 and 65 kg on one day, then 70 kg entered in
  /// lbs; plus an undone 深蹲 load and one outside the round.
  Future<void> seedLoads() async {
    await _group(
      db,
      _ago(3),
      null,
      [('卧推', true, 1)],
      loads: {'卧推': (60.0, 'kg')},
    );
    await _group(
      db,
      _ago(2),
      null,
      [('卧推', true, 1)],
      loads: {'卧推': (62.5, 'kg')},
    );
    await _group(
      db,
      _ago(2),
      null,
      [('卧推', true, 1)],
      loads: {'卧推': (65.0, 'kg')},
    );
    await _group(
      db,
      _ago(1),
      null,
      [('卧推', false, 1), ('深蹲', false, 0)],
      loads: {'卧推': (70.0, 'lbs'), '深蹲': (100.0, 'kg')},
    );
    await _group(
      db,
      _ago(10),
      null,
      [('卧推', true, 1)],
      loads: {'卧推': (90.0, 'kg')},
    );
  }

  test('lifts keep each exercise first and last load', () async {
    await seedLoads();
    final tally = await WorkoutRepository(
      db,
    ).trainingTallyBetween(_ago(3), _today);
    final bench = tally.lifts['卧推']!;
    expect(bench.firstKg, 60.0);
    expect(bench.firstDay, _ago(3));
    expect(bench.lastKg, 70.0);
    expect(bench.lastDay, _ago(1));
    expect(bench.unit, 'lbs');
    // Undone exercises don't count, whatever load was entered.
    expect(tally.lifts.containsKey('深蹲'), isFalse);
    // The heaviest of the day wins.
    final twoDays = await WorkoutRepository(
      db,
    ).trainingTallyBetween(_ago(2), _ago(2));
    expect(twoDays.lifts['卧推']!.lastKg, 65.0);
  });

  testWidgets('stats tab shows current strength', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await seedLoads();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
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
          home: Scaffold(
            body: CutRoundStatsView(
              segment: CutCultivationSegment(start: _ago(3)),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('当前实力'), findsOneWidget);
    // 70 kg entered in lbs shows as lbs; 60 kg → 70 kg is +22.05 lbs.
    expect(find.text('154.32 lbs'), findsOneWidget);
    expect(find.textContaining('较首次 +22.05 lbs'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
