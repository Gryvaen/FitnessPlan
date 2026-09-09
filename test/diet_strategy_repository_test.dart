import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
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

DietStrategyPlanDraft _carbCycleDraft(
  DateTime from, {
  String code = 'HMHMMLL',
}) {
  return DietStrategyPlanDraft(
    kind: DietStrategyKind.carbCycle,
    effectiveFrom: from,
    referenceWeightKg: 75,
    estimatedTdee: 2400,
    baseEnergy: 2000,
    schedule: CarbCycleSchedule.tryParse(code),
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
      'plan starting next cycle leaves today on the profile target',
      () async {
        final from = StrategyDates.nextCycleStart(today);
        final plan = await repo.createPlan(_carbCycleDraft(from));
        expect(plan.version, 1);
        expect(plan.status, DietPlanStatus.active);
        final t = (await repo.targetForDay(today, _profile()))!;
        expect(t.source, TargetSource.profile);
        final future = (await repo.targetForDay(from, _profile()))!;
        expect(future.source, TargetSource.strategy);
        expect(future.dayType, CarbDayType.high); // Monday = H
        expect(future.calories, 2200);
        expect(future.isSnapshot, isFalse); // future never persisted
      },
    );

    test('plan starting today is used immediately and snapshotted', () async {
      await repo.targetForDay(today, _profile()); // legacy snapshot first
      await repo.createPlan(_carbCycleDraft(today));
      final t = (await repo.targetForDay(today, _profile()))!;
      expect(t.source, TargetSource.strategy);
      final expected = CarbCycleSchedule.tryParse('HMHMMLL')!.forDate(today);
      expect(t.dayType, expected);
      final e = switch (expected) {
        CarbDayType.high => 2200.0,
        CarbDayType.mid => 2000.0,
        CarbDayType.low => 1800.0,
      };
      expect(t.calories, e);
      expect(t.proteinG, closeTo(150, 1e-9));
      expect(t.fatG, closeTo(60, 1e-9));
      expect(4 * t.proteinG + 4 * t.carbG + 9 * t.fatG, closeTo(e, 1e-6));
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
      await repo.stopActivePlan(reason: 'goalChanged:maintain');
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

        await repo.stopActivePlan();

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
      final weekTotal = [
        for (var i = 0; i < 7; i++) map[today.add(Duration(days: i))]!.calories,
      ].fold<double>(0, (s, v) => s + v);
      expect(weekTotal, closeTo(14000, 1e-6));
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
      expect(plan.carbCyclePlan!.weeklyEnergy, closeTo(14000, 1e-6));
      expect(plan.baseline.feasible, isTrue);
      expect(plan.legacyCalories, 2137);
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

  group('migration v16 → v17', () {
    test('adds tables without touching existing rows', () async {
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
      await legacy.runCustom(
        'INSERT INTO weight_logs (date, weight_kg) VALUES (1700000000, 80.5)',
      );
      await legacy.runCustom(
        'INSERT INTO water_logs (date, ml) VALUES (1700000000, 1250)',
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
      expect(version.data.values.first, 17);
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
