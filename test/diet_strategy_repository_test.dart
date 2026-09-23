import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';

UserProfile _profile({int calories = 2137, DateTime? since, int adj = 0}) {
  return UserProfile(
    sex: Sex.male,
    age: 30,
    heightCm: 178,
    weightKg: 75,
    activity: ActivityLevel.moderate,
    goal: FitnessGoal.cut,
    targets: MacroTargets(
      calories: calories,
      proteinG: 150,
      carbG: 240,
      fatG: 60,
    ),
    tdee: 2687,
    calorieAdjustment: adj,
    calorieStandardSince: since,
  );
}

final _carbCycleRates = CarbCycleRates.defaults();

DietStrategyPlanDraft _carbCycleDraft(
  DateTime from, {
  String code = 'HMLL',
}) {
  final schedule = CarbCycleSchedule.tryParse(code)!;
  final plan = CarbCyclePlanner.compute(
    referenceWeightKg: 75,
    rates: _carbCycleRates,
    schedule: schedule,
  );
  return DietStrategyPlanDraft(
    kind: DietStrategyKind.carbCycle,
    effectiveFrom: from,
    referenceWeightKg: 75,
    estimatedTdee: 2400,
    baseEnergy: plan.cycleAverageEnergy,
    schedule: schedule,
    carbCycleRates: _carbCycleRates,
    legacyCalories: 2137,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DietStrategyRepository repo;
  final today = CalendarDay.todayLocal();
  final yesterday = today.subtract(const Duration(days: 1));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DietStrategyRepository(db);
  });

  tearDown(() => db.close());

  group('resolution', () {
    test(
      'no plan → profile target, past days before standard are estimates',
      () async {
        final profile = _profile(since: today);
        final t = (await repo.targetForDay(today, profile))!;
        expect(t.source, TargetSource.profile);
        expect(t.calories, 2137);
        expect(t.isSnapshot, isTrue);
        expect(t.isLegacyEstimate, isFalse);

        final past = (await repo.targetForDay(yesterday, profile))!;
        expect(past.source, TargetSource.profile);
        expect(past.isSnapshot, isFalse);
        expect(past.isLegacyEstimate, isTrue);
        // Past days are never written as snapshots.
        expect(await repo.snapshotFor(yesterday), isNull);
      },
    );

    test('today snapshot follows profile changes on the same day', () async {
      await repo.targetForDay(today, _profile(calories: 2137));
      final t2 = (await repo.targetForDay(today, _profile(calories: 1900)))!;
      expect(t2.calories, 1900);
      expect((await repo.snapshotFor(today))!.calories, 1900);
    });

    test(
      'plan starting tomorrow leaves today on the profile target',
      () async {
        final from = today.add(const Duration(days: 1));
        final plan = await repo.createPlan(_carbCycleDraft(from));
        expect(plan.version, 1);
        expect(plan.status, DietPlanStatus.active);
        final t = (await repo.targetForDay(today, _profile()))!;
        expect(t.source, TargetSource.profile);
        final future = (await repo.targetForDay(from, _profile()))!;
        expect(future.source, TargetSource.strategy);
        // Cycle day 0 (effectiveFrom itself) is always the high day.
        expect(future.dayType, CarbDayType.high);
        final expectedHigh = CarbCyclePlanner.compute(
          referenceWeightKg: 75,
          rates: _carbCycleRates,
          schedule: CarbCycleSchedule.tryParse('HMLL')!,
        ).energyFor(CarbDayType.high)!;
        expect(future.calories, closeTo(expectedHigh, 1e-6));
        expect(future.isSnapshot, isFalse); // future never persisted
      },
    );

    test('plan starting today is used immediately and snapshotted', () async {
      await repo.targetForDay(today, _profile()); // legacy snapshot first
      await repo.createPlan(_carbCycleDraft(today));
      final t = (await repo.targetForDay(today, _profile()))!;
      expect(t.source, TargetSource.strategy);
      // effectiveFrom is cycle day 0, which is always the high day.
      expect(t.dayType, CarbDayType.high);
      // 'HMLL' has a mid day, so the high day's carbs (only) are trimmed to
      // keep the cycle average steady — see CarbCyclePlanner.compute.
      final expectedHigh = CarbCyclePlanner.compute(
        referenceWeightKg: 75,
        rates: _carbCycleRates,
        schedule: CarbCycleSchedule.tryParse('HMLL')!,
      ).energyFor(CarbDayType.high)!;
      expect(t.calories, closeTo(expectedHigh, 1e-6));
      expect(t.proteinG, closeTo(75 * _carbCycleRates.highProteinPerKg, 1e-9));
      expect(t.fatG, closeTo(75 * _carbCycleRates.highFatPerKg, 1e-9));
      expect(
        4 * t.proteinG + 4 * t.carbG + 9 * t.fatG,
        closeTo(t.calories, 1e-6),
      );
    });

    test('history is not rewritten when a new version starts later', () async {
      // Simulate a plan that has governed the last 10 days.
      final start = today.subtract(const Duration(days: 10));
      await db
          .into(db.dietStrategyPlans)
          .insert(
            DietStrategyPlansCompanion.insert(
              version: 1,
              strategy: DietStrategyKind.balanced.name,
              status: DietPlanStatus.active.name,
              effectiveFrom: StrategyDates.encode(start),
              createdAt: start,
              referenceWeightKg: 75,
              estimatedTdee: 2400,
              deficitFraction: 1 - 2000 / 2400,
              proteinPerKg: 2.0,
              fatPerKg: 0.8,
              baseEnergy: 2000,
            ),
          );
      final before = (await repo.targetForDay(yesterday, _profile()))!;
      expect(before.calories, 2000);
      expect(before.planVersion, 1);

      // New version with a different base from today → yesterday unchanged.
      await repo.createPlan(
        DietStrategyPlanDraft(
          kind: DietStrategyKind.balanced,
          effectiveFrom: today,
          referenceWeightKg: 72,
          estimatedTdee: 2300,
          baseEnergy: 1950,
        ),
      );
      final after = (await repo.targetForDay(yesterday, _profile()))!;
      expect(after.calories, 2000);
      expect(after.planVersion, 1);
      final todayT = (await repo.targetForDay(today, _profile()))!;
      expect(todayT.calories, 1950);
      expect(todayT.planVersion, 2);

      final plans = await repo.listPlans();
      expect(plans.first.status, DietPlanStatus.superseded);
      expect(plans.first.endedOn, today);
      expect(plans.last.status, DietPlanStatus.active);
    });

    test('stopping the plan reverts today to the profile target', () async {
      await repo.createPlan(_carbCycleDraft(today));
      expect(
        (await repo.targetForDay(today, _profile()))!.source,
        TargetSource.strategy,
      );
      final restamp = await repo.stopActivePlan(
        reason: 'goalChanged:maintain',
      );
      expect(restamp, today);
      final t = (await repo.targetForDay(today, _profile()))!;
      expect(t.source, TargetSource.profile);
      expect(await repo.activePlan(), isNull);
      final plans = await repo.listPlans();
      expect(plans.single.status, DietPlanStatus.stopped);
      expect(plans.single.endedOn, today);
    });

    test(
      'stopping a not-yet-started version reinstates the previous one',
      () async {
        final tomorrow = today.add(const Duration(days: 1));
        final v1 = await repo.createPlan(_carbCycleDraft(today));
        await repo.createPlan(
          DietStrategyPlanDraft(
            kind: DietStrategyKind.carbTaper,
            effectiveFrom: tomorrow,
            referenceWeightKg: 75,
            estimatedTdee: 2400,
            baseEnergy: 2000,
            observationStart: tomorrow,
          ),
        );
        expect((await repo.activePlan())!.kind, DietStrategyKind.carbTaper);

        final restamp = await repo.stopActivePlan();
        // The cancelled switch never took effect: the marker falls back to
        // whichever plan now governs, not "today".
        expect(restamp, today);

        final active = await repo.activePlan();
        expect(active, isNotNull);
        expect(active!.id, v1.id);
        expect(active.status, DietPlanStatus.active);
        expect(active.endedOn, isNull);
        // Today and tomorrow both stay on the carb cycle.
        for (final d in [today, tomorrow]) {
          final t = (await repo.targetForDay(d, _profile()))!;
          expect(t.strategy, DietStrategyKind.carbCycle);
        }
        final plans = await repo.listPlans();
        expect(
          plans.where((p) => p.status == DietPlanStatus.stopped).single.kind,
          DietStrategyKind.carbTaper,
        );
      },
    );

    test('infeasible draft and past effective date are rejected', () async {
      final bad = DietStrategyPlanDraft(
        kind: DietStrategyKind.balanced,
        effectiveFrom: today,
        referenceWeightKg: 120,
        estimatedTdee: 2500,
        baseEnergy: 2125,
      );
      expect(bad.validate(), isNotEmpty);
      await expectLater(repo.createPlan(bad), throwsArgumentError);
      await expectLater(
        repo.createPlan(_carbCycleDraft(yesterday)),
        throwsArgumentError,
      );
      expect(await repo.listPlans(), isEmpty);
    });

    test('targetsBetween mixes snapshots, plans and estimates', () async {
      final profile = _profile(calories: 2137, since: yesterday);
      await repo.createPlan(_carbCycleDraft(today));
      final map = await repo.targetsBetween(
        today.subtract(const Duration(days: 3)),
        today.add(const Duration(days: 8)),
        profile,
      );
      expect(map.length, 12);
      expect(map[today]!.source, TargetSource.strategy);
      expect(map[yesterday]!.source, TargetSource.profile);
      expect(map[yesterday]!.isLegacyEstimate, isFalse);
      final older = today.subtract(const Duration(days: 2));
      expect(map[older]!.isLegacyEstimate, isTrue);
      // Each day within the cycle repeats the schedule's H/M/L/L pattern
      // (effectiveFrom = today = cycle day 0).
      final cyclePlan = CarbCyclePlanner.compute(
        referenceWeightKg: 75,
        rates: _carbCycleRates,
        schedule: CarbCycleSchedule.tryParse('HMLL')!,
      );
      for (var i = 0; i < 8; i++) {
        final t = map[today.add(Duration(days: i))]!;
        expect(t.calories, closeTo(cyclePlan.dayAt(i % 4).energy, 1e-6));
      }
    });

    test('override for today wins and past override is refused', () async {
      await repo.setOverride(
        today,
        const DayMacroTarget(
          energy: 2100,
          proteinG: 150,
          carbG: 240,
          fatG: 60,
          dayType: CarbDayType.mid,
        ),
      );
      final t = (await repo.targetForDay(today, _profile()))!;
      expect(t.source, TargetSource.override);
      expect(t.calories, 2100);
      await expectLater(
        repo.setOverride(
          yesterday,
          const DayMacroTarget(
            energy: 1,
            proteinG: 1,
            carbG: 1,
            fatG: 1,
            dayType: CarbDayType.mid,
          ),
        ),
        throwsStateError,
      );
    });

    test('overeating today does not change tomorrow\'s quota', () async {
      await repo.createPlan(_carbCycleDraft(today));
      final tomorrow = today.add(const Duration(days: 1));
      final before = (await repo.targetForDay(tomorrow, _profile()))!;

      await db
          .into(db.mealEntries)
          .insert(
            MealEntriesCompanion.insert(
              date: today,
              mealType: MealType.lunch.name,
              foodId: 1,
              foodName: 'overeat',
              grams: 800,
              calories: 3500,
              proteinG: 80,
              carbG: 400,
              fatG: 80,
            ),
          );

      final after = (await repo.targetForDay(tomorrow, _profile()))!;
      expect(after.calories, before.calories);
      expect(after.proteinG, before.proteinG);
      expect(after.carbG, before.carbG);
      expect(after.fatG, before.fatG);
    });

    test('plan model helpers', () async {
      final plan = await repo.createPlan(_carbCycleDraft(today));
      expect(plan.covers(today), isTrue);
      expect(plan.covers(yesterday), isFalse);
      expect(plan.carbCyclePlan!.days.length, 4);
      expect(plan.carbCyclePlan!.usable, isTrue);
      expect(plan.legacyCalories, 2137);
    });
  });

  group('isStructuralChange', () {
    test('no prior plan is always a structural change', () {
      expect(
        DietStrategyRepository.isStructuralChange(null, _carbCycleDraft(today)),
        isTrue,
      );
    });

    test('switching kind is a structural change', () async {
      final old = await repo.createPlan(_carbCycleDraft(today));
      final draft = DietStrategyPlanDraft(
        kind: DietStrategyKind.carbTaper,
        effectiveFrom: today,
        referenceWeightKg: 75,
        estimatedTdee: 2400,
        baseEnergy: 2000,
      );
      expect(DietStrategyRepository.isStructuralChange(old, draft), isTrue);
    });

    test(
      'carb cycle: re-saving the same schedule/rates is not a change',
      () async {
        final old = await repo.createPlan(_carbCycleDraft(today));
        expect(
          DietStrategyRepository.isStructuralChange(
            old,
            _carbCycleDraft(today),
          ),
          isFalse,
        );
      },
    );

    test('carb cycle: a different schedule is a structural change', () async {
      final old = await repo.createPlan(_carbCycleDraft(today));
      expect(
        DietStrategyRepository.isStructuralChange(
          old,
          _carbCycleDraft(today, code: 'HMLLL'),
        ),
        isTrue,
      );
    });

    test(
      'carb cycle: reference weight drifting alone is not a change',
      () async {
        final old = await repo.createPlan(_carbCycleDraft(today));
        final schedule = CarbCycleSchedule.tryParse('HMLL')!;
        final drifted = DietStrategyPlanDraft(
          kind: DietStrategyKind.carbCycle,
          effectiveFrom: today,
          referenceWeightKg: 74, // weighed in lighter since last time
          estimatedTdee: 2360,
          baseEnergy: old.baseEnergy,
          schedule: schedule,
          carbCycleRates: _carbCycleRates,
        );
        expect(
          DietStrategyRepository.isStructuralChange(old, drifted),
          isFalse,
        );
      },
    );

    test('carb taper: advancing a stage is a structural change', () async {
      final old = await repo.createPlan(
        DietStrategyPlanDraft(
          kind: DietStrategyKind.carbTaper,
          effectiveFrom: today,
          referenceWeightKg: 75,
          estimatedTdee: 2400,
          baseEnergy: 2000,
        ),
      );
      final draft = DietStrategyPlanDraft(
        kind: DietStrategyKind.carbTaper,
        effectiveFrom: today,
        referenceWeightKg: 75,
        estimatedTdee: 2400,
        baseEnergy: 2000,
        taperStage: 1,
      );
      expect(DietStrategyRepository.isStructuralChange(old, draft), isTrue);
    });
  });

  group('diet completeness confirmations', () {
    test('unknown by default, editable today only', () async {
      expect(await repo.dayComplete(today), isNull);
      await repo.setDayComplete(today, true);
      expect(await repo.dayComplete(today), isTrue);
      await repo.setDayComplete(today, false);
      expect(await repo.dayComplete(today), isFalse);
      await expectLater(repo.setDayComplete(yesterday, true), throwsStateError);
      expect(await repo.dayComplete(yesterday), isNull);
    });

    test('completeDaysBetween only returns confirmed-true days', () async {
      await repo.setDayComplete(today, true);
      final set = await repo.completeDaysBetween(
        today.subtract(const Duration(days: 13)),
        today,
      );
      expect(set, {today});
    });
  });

  group('rest day shifts the carb cycle', () {
    test(
      'a marked rest day pushes the cycle index for later days back by one',
      () async {
        await repo.createPlan(_carbCycleDraft(today)); // 'HMLL', day0 = today
        final cyclePlan = CarbCyclePlanner.compute(
          referenceWeightKg: 75,
          rates: _carbCycleRates,
          schedule: CarbCycleSchedule.tryParse('HMLL')!,
        );
        final tomorrow = today.add(const Duration(days: 1));
        final dayAfter = today.add(const Duration(days: 2));
        final day3 = today.add(const Duration(days: 3));
        final day4 = today.add(const Duration(days: 4));

        // Unshifted: today=H(0) tomorrow=M(1) dayAfter=L(2) day3=L(3) day4=H(0)
        expect(
          (await repo.targetForDay(dayAfter, _profile()))!.calories,
          closeTo(cyclePlan.dayAt(2).energy, 1e-6),
        );

        final markerRepo = DayMarkerRepository(db);
        await markerRepo.setRestDay(tomorrow);

        // dayAfter's diff (2) minus the 1 rest day before it (tomorrow) → index 1 (M).
        final afterMark = (await repo.targetForDay(dayAfter, _profile()))!;
        expect(afterMark.calories, closeTo(cyclePlan.dayAt(1).energy, 1e-6));
        // day3: diff 3 - 1 = 2 → L.
        expect(
          (await repo.targetForDay(day3, _profile()))!.calories,
          closeTo(cyclePlan.dayAt(2).energy, 1e-6),
        );
        // day4: diff 4 - 1 = 3 → L.
        expect(
          (await repo.targetForDay(day4, _profile()))!.calories,
          closeTo(cyclePlan.dayAt(3).energy, 1e-6),
        );
      },
    );

    test('targetsBetween applies the same rest-day shift', () async {
      await repo.createPlan(_carbCycleDraft(today));
      final cyclePlan = CarbCyclePlanner.compute(
        referenceWeightKg: 75,
        rates: _carbCycleRates,
        schedule: CarbCycleSchedule.tryParse('HMLL')!,
      );
      final tomorrow = today.add(const Duration(days: 1));
      final markerRepo = DayMarkerRepository(db);
      await markerRepo.setRestDay(tomorrow);

      final map = await repo.targetsBetween(
        today,
        today.add(const Duration(days: 4)),
        _profile(),
      );
      expect(map[today]!.calories, closeTo(cyclePlan.dayAt(0).energy, 1e-6));
      final dayAfter = today.add(const Duration(days: 2));
      final day3 = today.add(const Duration(days: 3));
      final day4 = today.add(const Duration(days: 4));
      expect(
        map[dayAfter]!.calories,
        closeTo(cyclePlan.dayAt(1).energy, 1e-6),
      );
      expect(map[day3]!.calories, closeTo(cyclePlan.dayAt(2).energy, 1e-6));
      expect(map[day4]!.calories, closeTo(cyclePlan.dayAt(3).energy, 1e-6));
    });

    test(
      'a rest day backfilled onto an already-past date does not shift '
      'the cycle',
      () async {
        await repo.createPlan(_carbCycleDraft(today)); // 'HMLL', day0 = today
        final cyclePlan = CarbCyclePlanner.compute(
          referenceWeightKg: 75,
          rates: _carbCycleRates,
          schedule: CarbCycleSchedule.tryParse('HMLL')!,
        );
        final dayAfter = today.add(const Duration(days: 2)); // unshifted: L
        final day4 = today.add(const Duration(days: 4)); // unshifted: H

        final markerRepo = DayMarkerRepository(db);
        // Backfilled well after the fact — updatedAt trails the marked date
        // by days, unlike a contemporaneous marker — so it must not count
        // toward the day-count progression.
        await markerRepo.setRestDay(
          dayAfter,
          now: today.add(const Duration(days: 5)),
        );

        final t = (await repo.targetForDay(day4, _profile()))!;
        expect(t.calories, closeTo(cyclePlan.dayAt(0).energy, 1e-6));

        final map = await repo.targetsBetween(today, day4, _profile());
        expect(map[day4]!.calories, closeTo(cyclePlan.dayAt(0).energy, 1e-6));
      },
    );

    test('rest days do not affect non-carb-cycle strategies', () async {
      await repo.createPlan(
        DietStrategyPlanDraft(
          kind: DietStrategyKind.balanced,
          effectiveFrom: today,
          referenceWeightKg: 75,
          estimatedTdee: 2400,
          baseEnergy: 2000,
        ),
      );
      final tomorrow = today.add(const Duration(days: 1));
      final markerRepo = DayMarkerRepository(db);
      await markerRepo.setRestDay(tomorrow);
      final dayAfter = today.add(const Duration(days: 2));
      final t = (await repo.targetForDay(dayAfter, _profile()))!;
      expect(t.calories, 2000);
    });
  });

  group('migration v16 → latest', () {
    test('adds tables/columns without touching existing rows', () async {
      final dir = await Directory.systemTemp.createTemp('fp_mig_');
      final file = File('${dir.path}/legacy.sqlite');
      // Minimal v16 fixture: a few legacy tables with data.
      final legacy = NativeDatabase(file);
      await legacy.ensureOpen(_NoopUser());
      await legacy.runCustom('''
CREATE TABLE weight_logs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  weight_kg REAL NOT NULL,
  body_fat_pct REAL NULL,
  exercise_minutes INTEGER NULL
)''');
      await legacy.runCustom('''
CREATE TABLE water_logs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  ml INTEGER NOT NULL,
  UNIQUE (date)
)''');
      await legacy.runCustom('''
CREATE TABLE food_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  kcal_per100 REAL NOT NULL,
  protein_per100 REAL NOT NULL,
  carb_per100 REAL NOT NULL,
  fat_per100 REAL NOT NULL,
  alcohol_per100 REAL NOT NULL DEFAULT 0.0,
  fiber_per100 REAL NOT NULL DEFAULT 0.0,
  sodium_mg_per100 REAL NOT NULL DEFAULT 0.0,
  sugar_per100 REAL NOT NULL DEFAULT 0.0,
  saturated_fat_per100 REAL NOT NULL DEFAULT 0.0,
  is_custom BOOLEAN NOT NULL DEFAULT 0,
  UNIQUE (name)
)''');
      await legacy.runCustom('''
CREATE TABLE meal_entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  meal_type TEXT NOT NULL,
  food_id INTEGER NOT NULL,
  food_name TEXT NOT NULL,
  grams REAL NOT NULL,
  calories REAL NOT NULL,
  protein_g REAL NOT NULL,
  carb_g REAL NOT NULL,
  fat_g REAL NOT NULL,
  alcohol_g REAL NOT NULL DEFAULT 0.0,
  fiber_g REAL NOT NULL DEFAULT 0.0,
  sodium_mg REAL NOT NULL DEFAULT 0.0,
  sugar_g REAL NOT NULL DEFAULT 0.0,
  saturated_fat_g REAL NOT NULL DEFAULT 0.0
)''');
      // Present since v1; needed so the v20 ADD COLUMN migrations have a
      // table to alter, matching every real pre-v20 install.
      await legacy.runCustom('''
CREATE TABLE workout_plan_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER NOT NULL,
  exercise_id INTEGER NOT NULL,
  exercise_name TEXT NOT NULL,
  target_sets INTEGER NOT NULL,
  target_reps INTEGER NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
)''');
      await legacy.runCustom('''
CREATE TABLE day_workout_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  day_workout_id INTEGER NOT NULL,
  exercise_id INTEGER NOT NULL,
  exercise_name TEXT NOT NULL,
  target_sets INTEGER NOT NULL,
  target_reps INTEGER NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  done BOOLEAN NOT NULL DEFAULT 0
)''');
      // Present since v1 (schema unchanged since); needed so the v24
      // date-index migration has tables to index, matching every real
      // pre-v16 install.
      await legacy.runCustom('''
CREATE TABLE day_workouts (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  plan_id INTEGER NULL,
  plan_name TEXT NULL
)''');
      await legacy.runCustom('''
CREATE TABLE workout_set_logs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  exercise_id INTEGER NOT NULL,
  exercise_name TEXT NOT NULL,
  set_index INTEGER NOT NULL,
  reps INTEGER NULL,
  duration_sec INTEGER NULL,
  day_workout_item_id INTEGER NULL
)''');
      await legacy.runCustom(
        'INSERT INTO weight_logs (date, weight_kg) VALUES (1700000000, 80.5)',
      );
      await legacy.runCustom(
        'INSERT INTO water_logs (date, ml) VALUES (1700000000, 1250)',
      );
      await legacy.runCustom(
        "INSERT INTO food_items (name, category, kcal_per100, protein_per100, carb_per100, fat_per100) "
        "VALUES ('米饭', '主食', 116, 2.6, 25.9, 0.3)",
      );
      await legacy.runCustom('PRAGMA user_version = 16');
      await legacy.close();

      final migrated = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await migrated.close();
        await dir.delete(recursive: true);
      });
      final weights = await migrated.select(migrated.weightLogs).get();
      expect(weights.single.weightKg, 80.5);
      final water = await migrated.select(migrated.waterLogs).get();
      expect(water.single.ml, 1250);
      final foods = await migrated.select(migrated.foodItems).get();
      expect(foods.single.name, '米饭');
      expect(foods.single.calciumMgPer100, 0.0);
      // v20 additive columns exist (empty tables, so just check they open).
      expect(await migrated.select(migrated.workoutPlanItems).get(), isEmpty);
      expect(await migrated.select(migrated.dayWorkoutItems).get(), isEmpty);
      // v24: date indices exist on the tables that previously had none.
      final indexNames = (await migrated
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'index' "
                "AND name LIKE 'idx_%_date'",
              )
              .get())
          .map((r) => r.read<String>('name'))
          .toSet();
      expect(indexNames, {
        'idx_weight_logs_date',
        'idx_meal_entries_date',
        'idx_day_workouts_date',
        'idx_workout_set_logs_date',
      });
      // New tables exist and are empty.
      expect(await migrated.select(migrated.dietStrategyPlans).get(), isEmpty);
      expect(
        await migrated.select(migrated.dailyNutritionTargets).get(),
        isEmpty,
      );
      expect(
        await migrated.select(migrated.dayDietConfirmations).get(),
        isEmpty,
      );
      final version = await migrated
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.first, migrated.schemaVersion);
    });
  });
}

/// Minimal QueryExecutorUser so the raw fixture executor can be opened.
class _NoopUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 16;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
