import 'dart:io';

import 'package:diet/data/cycle_alignment_migration.dart';
import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DietStrategyPlanDraft cycle(
  DateTime from, {
  String code = 'LLMH',
  double weight = 70,
}) {
  final schedule = CarbCycleSchedule.tryParse(code)!;
  final rates = CarbCycleRates.defaults();
  return DietStrategyPlanDraft(
    kind: DietStrategyKind.carbCycle,
    effectiveFrom: from,
    referenceWeightKg: weight,
    estimatedTdee: 2400,
    baseEnergy: CarbCyclePlanner.compute(
      referenceWeightKg: weight,
      rates: rates,
      schedule: schedule,
    ).cycleAverageEnergy,
    schedule: schedule,
    carbCycleRates: rates,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late DietStrategyRepository repo;
  final start = DateTime(2026, 9, 15);
  final change = DateTime(2026, 10, 15);
  final today = DateTime(2026, 10, 16);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DietStrategyRepository(db);
  });
  tearDown(() => db.close());

  test(
    'weight/rates version continues mid/high positions without rest days',
    () async {
      await repo.createPlan(cycle(start), now: start);
      final next = await repo.createPlan(
        cycle(change, weight: 67),
        now: change,
      );
      expect(next.cycleStartIndex, 2);
      expect(
        (await repo.targetForDay(change, null, now: change))!.dayType,
        CarbDayType.mid,
      );
      expect(
        (await repo.targetForDay(today, null, now: today))!.dayType,
        CarbDayType.high,
      );
      final days = await repo.targetsBetween(change, today, null, now: today);
      expect(days[change]!.dayType, CarbDayType.mid);
      expect(days[today]!.dayType, CarbDayType.high);
      final loaded = (await repo.activePlan())!;
      expect(loaded.cycleStartIndex, next.cycleStartIndex);
    },
  );

  test(
    'schedule growth, shrink, and reorder inherit position modulo new length',
    () async {
      await repo.createPlan(cycle(start), now: start);
      final fourth = start.add(const Duration(days: 3));
      final longer = await repo.createPlan(
        cycle(fourth, code: 'LLLMH'),
        now: fourth,
      );
      expect(longer.cycleStartIndex, 3);
      final shorter = await repo.createPlan(
        cycle(fourth, code: 'LMH'),
        now: fourth,
      );
      expect(shorter.cycleStartIndex, 0);
      final reordered = await repo.createPlan(
        cycle(fourth, code: 'HML'),
        now: fourth,
      );
      expect(reordered.cycleStartIndex, 0);
      expect(reordered.targetFor(fourth).dayType, CarbDayType.high);
    },
  );

  test('consecutive rest days carry across versions exactly once', () async {
    await repo.createPlan(cycle(start), now: start);
    final markers = DayMarkerRepository(db);
    for (final n in [1, 2]) {
      final date = start.add(Duration(days: n));
      await markers.setRestDay(date, pauseCarbCycle: true, now: date);
    }
    final from = start.add(const Duration(days: 3));
    final next = await repo.createPlan(cycle(from), now: from);
    expect(next.cycleStartIndex, 1);
    await markers.setRestDay(from, pauseCarbCycle: true, now: from);
    final after = from.add(const Duration(days: 1));
    expect(
      (await repo.targetForDay(after, null, now: after))!.dayType,
      CarbDayType.low,
    );
    final third = await repo.createPlan(cycle(after), now: after);
    expect(third.cycleStartIndex, 1);
    final mid = after.add(const Duration(days: 1));
    expect(
      (await repo.targetForDay(mid, null, now: mid))!.dayType,
      CarbDayType.mid,
    );
  });

  test(
    'pending replacement and same-day saves preserve the actual effective slot',
    () async {
      await repo.createPlan(cycle(start), now: start);
      final tomorrow = change.add(const Duration(days: 1));
      final pending = await repo.createPlan(cycle(tomorrow), now: change);
      expect(pending.cycleStartIndex, 3);
      final replacement = await repo.createPlan(
        cycle(tomorrow, weight: 67),
        now: change,
      );
      expect(replacement.cycleStartIndex, 3);
      final immediate = await repo.createPlan(cycle(change), now: change);
      expect(immediate.cycleStartIndex, 2);
      final again = await repo.createPlan(cycle(change), now: change);
      expect(again.cycleStartIndex, 2);
      expect((await repo.planCovering(tomorrow))!.id, again.id);
    },
  );

  test(
    'stop/restart and switching from a different strategy start at zero',
    () async {
      await repo.createPlan(cycle(start), now: start);
      await repo.stopActivePlan(now: change);
      expect(
        (await repo.createPlan(cycle(change), now: change)).cycleStartIndex,
        0,
      );
      await repo.createPlan(
        DietStrategyPlanDraft(
          kind: DietStrategyKind.balanced,
          effectiveFrom: today,
          referenceWeightKg: 70,
          estimatedTdee: 2400,
          baseEnergy: 2000,
        ),
        now: today,
      );
      expect(
        (await repo.createPlan(cycle(today), now: today)).cycleStartIndex,
        0,
      );
    },
  );

  test(
    'preview helper agrees with transactional saves and rest pauses',
    () async {
      await repo.createPlan(cycle(start), now: start);
      await DayMarkerRepository(
        db,
      ).setRestDay(change, pauseCarbCycle: true, now: change);
      final index = DietStrategyRepository.continuationIndex(
        plans: await repo.listPlans(),
        restDays: await DayMarkerRepository(db).restDayDates(),
        effectiveFrom: today,
        schedule: cycle(today).schedule!,
      );
      final saved = await repo.createPlan(cycle(today), now: change);
      expect(saved.cycleStartIndex, index);
      expect(index, 2);
    },
  );

  Future<void> legacyChain({bool future = false}) async {
    await repo.createPlan(cycle(start), now: start);
    await repo.createPlan(cycle(change, weight: 67), now: change);
    // Emulate old versions that always reset their effective-date position.
    await db.customStatement(
      'UPDATE diet_strategy_plans SET cycle_start_index = 0',
    );
    await repo.targetForDay(change, null, now: change); // Legacy low snapshot.
    await repo.targetForDay(today, null, now: today);
    if (future) {
      await repo.createPlan(
        cycle(today.add(const Duration(days: 2))),
        now: today,
      );
      await db.customStatement(
        'UPDATE diet_strategy_plans SET cycle_start_index = 0',
      );
    }
  }

  test(
    'legacy repair starts today, keeps historical version/snapshot, and runs once',
    () async {
      await legacyChain();
      final before = await repo.planCovering(change);
      await repairLegacyCycleAlignment(db, now: today);
      expect((await repo.planCovering(change))!.id, before!.id);
      expect(
        (await repo.targetForDay(change, null, now: today))!.dayType,
        CarbDayType.low,
      );
      expect(
        (await repo.targetForDay(today, null, now: today))!.dayType,
        CarbDayType.high,
      );
      final count = (await repo.listPlans()).length;
      expect(count, 3);
      await repairLegacyCycleAlignment(
        db,
        now: today.add(const Duration(days: 1)),
      );
      expect((await repo.listPlans()).length, count);
    },
  );

  test(
    'legacy repair preserves pending switch boundary and parameters',
    () async {
      await legacyChain(future: true);
      final future = today.add(const Duration(days: 2));
      final pending = (await repo.activePlan())!;
      await repairLegacyCycleAlignment(db, now: today);
      final current = (await repo.planCovering(today))!;
      expect(current.effectiveFrom, today);
      expect(current.endedOn, future);
      expect(current.status, DietPlanStatus.superseded);
      expect(
        (await repo.targetForDay(today, null, now: today))!.dayType,
        CarbDayType.high,
      );
      final next = (await repo.activePlan())!;
      expect(next.id, pending.id);
      expect(next.effectiveFrom, future);
      expect(next.referenceWeightKg, pending.referenceWeightKg);
      expect(next.cycleStartIndex, 1);
    },
  );

  test(
    'v31 database upgrade repairs today without rewriting yesterday',
    () async {
      final dir = await Directory.systemTemp.createTemp('cycle-v31-');
      final file = File('${dir.path}/legacy.sqlite');
      final realToday = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final oldStart = realToday.subtract(const Duration(days: 31));
      final yesterday = realToday.subtract(const Duration(days: 1));
      final seed = AppDatabase.forTesting(NativeDatabase(file));
      final seedRepo = DietStrategyRepository(seed);
      await seedRepo.createPlan(cycle(oldStart), now: oldStart);
      await seedRepo.createPlan(cycle(yesterday), now: yesterday);
      await seed.customStatement(
        'UPDATE diet_strategy_plans SET cycle_start_index = 0',
      );
      await seedRepo.targetForDay(yesterday, null, now: yesterday);
      await seedRepo.targetForDay(realToday, null, now: realToday);
      await seed.close();
      final old = NativeDatabase(file);
      await old.ensureOpen(_V31User());
      await old.runCustom(
        'ALTER TABLE diet_strategy_plans DROP COLUMN cycle_start_index',
      );
      await old.runCustom('PRAGMA user_version = 31');
      await old.close();
      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await upgraded.close();
        await dir.delete(recursive: true);
      });
      final upgradedRepo = DietStrategyRepository(upgraded);
      expect(
        (await upgradedRepo.targetForDay(
          realToday,
          null,
          now: realToday,
        ))!.dayType,
        CarbDayType.high,
      );
      expect(
        (await upgradedRepo.targetForDay(
          yesterday,
          null,
          now: realToday,
        ))!.dayType,
        CarbDayType.low,
      );
      expect((await upgradedRepo.listPlans()).length, 3);
    },
  );

  test('repair and same-day edits preserve manual target snapshots', () async {
    await legacyChain();
    await (db.update(
      db.dailyNutritionTargets,
    )..where((t) => t.date.equals(StrategyDates.encode(today)))).write(
      const DailyNutritionTargetsCompanion(
        source: Value('override'),
        calories: Value(1777),
      ),
    );
    await repairLegacyCycleAlignment(db, now: today);
    expect((await repo.targetForDay(today, null, now: today))!.calories, 1777);
    await repo.createPlan(cycle(today), now: today);
    expect((await repo.targetForDay(today, null, now: today))!.calories, 1777);
  });
}

class _V31User extends QueryExecutorUser {
  @override
  int get schemaVersion => 31;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
