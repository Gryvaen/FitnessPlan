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

/// Regression fixture shaped after the phone backup of 2026-10-16:
///
/// - v1 LLLH started and was replaced on 9/15 (zero-length);
/// - v2 LLMH from 9/15; 9/23 休息日 marked that evening with the cycle
///   paused (recorded L/L/L on 9/23–9/25), although its stored toggle now
///   reads off; 10/14 休息日 backfilled on 10/15, not paused;
/// - v3 LLMH (67 kg) from 10/15, reset to slot 0 by the old logic.
///
/// Real sequence: 9/22 H → 9/23 rest → 9/24 L① → 9/25 L② → 9/26 M …
/// 10/13 H → 10/14 rest + L① → 10/15 L② → 10/16 M → 10/17 H.
DateTime _d(DateTime t, int offset) =>
    DateTime(t.year, t.month, t.day + offset);

DietStrategyPlanDraft _cycle(
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

const _kcal = {'L': 1288.0, 'M': 1342.25, 'H': 1450.75};

Future<void> _snapshot(
  AppDatabase db,
  DateTime day,
  int planId,
  int version,
  String type, {
  String source = 'strategy',
  double? calories,
}) => db.customStatement(
  'INSERT OR REPLACE INTO daily_nutrition_targets (date, plan_id, '
  'plan_version, strategy, day_type, calories, protein_g, carb_g, fat_g, '
  "source, updated_at) VALUES (?, ?, ?, 'carbCycle', ?, ?, 120, 100, 50, ?, ?)",
  [
    StrategyDates.encode(day),
    planId,
    version,
    type,
    calories ?? _kcal[type],
    source,
    day.millisecondsSinceEpoch ~/ 1000,
  ],
);

/// Seeds the phone timeline with today = [t] (10/16 in the real data).
/// With [v32Repair], also adds the faulty v32 version from today (slot 3,
/// high) with its today snapshot.
Future<void> seedPhoneTimeline(
  AppDatabase db,
  DateTime t, {
  bool v32Repair = false,
}) async {
  final repo = DietStrategyRepository(db);
  final start = _d(t, -31); // 9/15
  final change = _d(t, -1); // 10/15
  await repo.createPlan(_cycle(start, code: 'LLLH'), now: start);
  await repo.createPlan(_cycle(start), now: start);
  await repo.createPlan(_cycle(change, weight: 67), now: change);
  // Old versions always reset their effective-date position.
  await db.customStatement(
    'UPDATE diet_strategy_plans SET cycle_start_index = 0',
  );
  final markers = DayMarkerRepository(db);
  final rest = _d(t, -23); // 9/23
  await markers.setRestDay(
    rest,
    now: DateTime(rest.year, rest.month, rest.day, 21, 57),
  );
  await markers.setRestDay(
    _d(t, -2), // 10/14, edited on 10/15
    now: DateTime(change.year, change.month, change.day, 9, 23),
  );
  const schedule = 'LLMH';
  for (var k = 0; k <= 29; k++) {
    final index = k <= 8 ? k % 4 : (k - 9) % 4;
    await _snapshot(db, _d(start, k), 2, 2, schedule[index]);
  }
  await _snapshot(db, change, 3, 3, 'L');
  if (v32Repair) {
    final date = StrategyDates.encode(t);
    await db.customStatement(
      "UPDATE diet_strategy_plans SET ended_on = ?, status = 'superseded' "
      'WHERE id = 3',
      [date],
    );
    final v3 =
        (await db
                .customSelect('SELECT * FROM diet_strategy_plans WHERE id = 3')
                .getSingle())
            .data;
    final v4 = Map<String, Object?>.from(v3)
      ..remove('id')
      ..['version'] = 4
      ..['status'] = 'active'
      ..['ended_on'] = null
      ..['effective_from'] = date
      ..['cycle_start_index'] = 3
      ..['reason'] = '${v3['reason']};cycleAlignmentRepair';
    await db.customStatement(
      'INSERT INTO diet_strategy_plans (${v4.keys.join(', ')}) '
      'VALUES (${List.filled(v4.length, '?').join(', ')})',
      v4.values.toList(),
    );
    await _snapshot(db, t, 4, 4, 'H');
  } else {
    await _snapshot(db, t, 3, 3, 'L');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t = DateTime(2026, 10, 16);
  late AppDatabase db;
  late DietStrategyRepository repo;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DietStrategyRepository(db);
  });
  tearDown(() => db.close());

  Future<Map<DateTime, DailyNutritionTarget>> days(DateTime now) =>
      repo.targetsBetween(_d(t, -24), _d(t, 2), null, now: now);

  Future<Map<String, Object?>> row(DateTime day) async =>
      (await db
              .customSelect(
                'SELECT * FROM daily_nutrition_targets WHERE date = ?',
                variables: [Variable.withString(StrategyDates.encode(day))],
              )
              .getSingle())
          .data;

  void expectPhoneSequence(
    Map<DateTime, DailyNutritionTarget> out, {
    bool overrideOnL1 = false,
  }) {
    expect(out[_d(t, -24)]!.dayType, CarbDayType.high); // 9/22
    expect(out[_d(t, -23)]!.cyclePaused, isTrue); // 9/23 rest
    if (!overrideOnL1) expect(out[_d(t, -22)]!.cycleIndex, 0); // 9/24 L①
    expect(out[_d(t, -21)]!.cycleIndex, 1); // 9/25 L②
    expect(out[_d(t, -20)]!.dayType, CarbDayType.mid); // 9/26
    expect(out[_d(t, -3)]!.dayType, CarbDayType.high); // 10/13
    expect(out[_d(t, -2)]!.cycleIndex, 0); // 10/14 L①
    expect(out[_d(t, -2)]!.cyclePaused, isFalse);
    expect(out[_d(t, 0)]!.dayType, CarbDayType.mid); // 10/16
    expect(out[_d(t, 0)]!.cycleIndex, 2);
    expect(out[_d(t, 1)]!.dayType, CarbDayType.high); // 10/17
  }

  test('v31 phone data: 9/23 pause recovered, 10/16 is mid-carb', () async {
    await seedPhoneTimeline(db, t);
    await repairLegacyCycleAlignment(db, now: t);
    expectPhoneSequence(await days(t));
    final rest = await row(_d(t, -23));
    expect(rest['cycle_paused'], 1);
    expect(rest['calories'], _kcal['L']); // History kept as recorded.
    expect((await row(_d(t, -2)))['cycle_paused'], 0);
    expect((await row(_d(t, -1)))['cycle_index'], isNull); // Reset version.
    final restDays = await DayMarkerRepository(db).restDayDates(now: t);
    expect(restDays, [_d(t, -23)]);
    final current = (await repo.planCovering(t))!;
    expect(current.version, 4);
    expect(current.cycleStartIndex, 2);
    expect(current.referenceWeightKg, 67);
    expect(current.reason, contains('cycleHistoryRepair'));
    final markerSettings = await DayMarkerRepository(
      db,
    ).settingsForDay(_d(t, -23));
    expect(markerSettings!.pauseCarbCycle, isTrue);
  });

  test('v32 faulty repair is excluded and replaced from today', () async {
    await seedPhoneTimeline(db, t, v32Repair: true);
    await repairLegacyCycleAlignment(db, now: t);
    expectPhoneSequence(await days(t));
    final plans = await repo.listPlans();
    expect(plans, hasLength(5));
    final current = (await repo.planCovering(t))!;
    expect(current.version, 5);
    expect(current.cycleStartIndex, 2);
    expect(current.reason, isNot(contains('cycleAlignmentRepair;')));
    await repairLegacyCycleAlignment(db, now: _d(t, 1));
    expect(await repo.listPlans(), hasLength(5));
  });

  test('repair a day later keeps the recorded v32 day as history', () async {
    await seedPhoneTimeline(db, t, v32Repair: true);
    final tomorrow = _d(t, 1);
    await repairLegacyCycleAlignment(db, now: tomorrow);
    expect((await row(t))['day_type'], 'H');
    expect(
      (await repo.targetForDay(tomorrow, null, now: tomorrow))!.dayType,
      CarbDayType.high,
    );
    // 9/23 was still recovered from v2's own history.
    expect((await row(_d(t, -23)))['cycle_paused'], 1);
  });

  test(
    'later toggle edits do not rewrite history; today follows the toggle',
    () async {
      await seedPhoneTimeline(db, t);
      await repairLegacyCycleAlignment(db, now: t);
      final markers = DayMarkerRepository(db);
      await markers.setRestDay(_d(t, -23), now: t);
      expect(
        (await repo.targetForDay(t, null, now: t))!.dayType,
        CarbDayType.mid,
      );
      await markers.setRestDay(t, pauseCarbCycle: true, now: t);
      final out = await days(t);
      expect(out[t]!.cyclePaused, isTrue);
      expect(out[_d(t, 1)]!.dayType, CarbDayType.mid);
      expect(out[_d(t, 2)]!.dayType, CarbDayType.high);
      await markers.setRestDay(t, now: t);
      expect((await days(t))[_d(t, 1)]!.dayType, CarbDayType.high);
    },
  );

  test('manual overrides are not position evidence and are kept', () async {
    await seedPhoneTimeline(db, t);
    await _snapshot(
      db,
      _d(t, -22),
      2,
      2,
      'H',
      source: 'override',
      calories: 1777,
    );
    await repairLegacyCycleAlignment(db, now: t);
    expectPhoneSequence(await days(t), overrideOnL1: true);
    final override = await row(_d(t, -22));
    expect(override['source'], 'override');
    expect(override['calories'], 1777);
    expect(override['cycle_index'], isNull);
  });

  test('ambiguous history is left as recorded', () async {
    // LLMH from 9/15; 9/23 rest (eligible, toggle off) with only one L
    // recorded after it: paused or not, 9/24 is low either way.
    final start = _d(t, -31);
    await repo.createPlan(_cycle(start), now: start);
    final rest = _d(start, 8);
    await DayMarkerRepository(db).setRestDay(rest, now: rest);
    for (var k = 0; k <= 9; k++) {
      await _snapshot(db, _d(start, k), 1, 1, 'LLMH'[k <= 8 ? k % 4 : 0]);
    }
    final next = _d(start, 10);
    await repo.createPlan(_cycle(next), now: next);
    await db.customStatement(
      'UPDATE diet_strategy_plans SET cycle_start_index = 0',
    );
    final now = _d(next, 1);
    await repairLegacyCycleAlignment(db, now: now);
    expect(await repo.listPlans(), hasLength(2));
    expect((await row(rest))['cycle_paused'], isNull);
    expect((await row(start))['cycle_index'], 0); // Unique positions freeze.
  });

  group('database upgrade', () {
    Future<File> legacyFile(int userVersion) async {
      final dir = await Directory.systemTemp.createTemp('cycle-v$userVersion-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/legacy.sqlite');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final seed = AppDatabase.forTesting(NativeDatabase(file));
      await seedPhoneTimeline(seed, today, v32Repair: userVersion == 32);
      await seed.close();
      final old = NativeDatabase(file);
      await old.ensureOpen(_LegacyUser(userVersion));
      for (final c in ['cycle_index', 'cycle_paused']) {
        await old.runCustom(
          'ALTER TABLE daily_nutrition_targets DROP COLUMN $c',
        );
      }
      if (userVersion < 32) {
        await old.runCustom(
          'ALTER TABLE diet_strategy_plans DROP COLUMN cycle_start_index',
        );
      }
      await old.runCustom('PRAGMA user_version = $userVersion');
      await old.close();
      return file;
    }

    for (final version in [31, 32]) {
      test('v$version → v33 repairs today once, across restarts', () async {
        final file = await legacyFile(version);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        for (var launch = 0; launch < 2; launch++) {
          final upgraded = AppDatabase.forTesting(NativeDatabase(file));
          final r = DietStrategyRepository(upgraded);
          expect((await r.targetForDay(today, null))!.dayType, CarbDayType.mid);
          expect(await r.listPlans(), hasLength(version == 31 ? 4 : 5));
          final rest = DateTime(today.year, today.month, today.day - 23);
          expect(
            (await DayMarkerRepository(upgraded).restDayDates()),
            contains(rest),
          );
          await upgraded.close();
        }
      });
    }
  });
}

class _LegacyUser extends QueryExecutorUser {
  _LegacyUser(this.schemaVersion);
  @override
  final int schemaVersion;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
