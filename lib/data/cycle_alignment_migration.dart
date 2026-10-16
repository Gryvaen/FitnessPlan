import 'package:drift/drift.dart';

import '../domain/calendar_day.dart';
import '../domain/cycle_history.dart';
import '../domain/day_marker.dart';
import '../domain/diet_strategy.dart';

/// Run-once marker, independent of the v32 calendar-only repair it replaces.
const _repairedKey = 'cycle_alignment_v33_repaired';

/// Reason tag of the faulty v32 repair: its versions and snapshots were
/// derived from current toggles, so they are never historical evidence.
const _v32RepairTag = 'cycleAlignmentRepair';

/// Restores the executed carb-cycle day sequence of databases written by
/// versions that reset the cycle on every new plan version (≤ v31) or by
/// the v32 repair.
///
/// Historical targets, meals, weights and overrides are immutable. Only
/// position/pause metadata uniquely supported by the recorded day types is
/// backfilled; when the evidence is ambiguous, history stays as it is. The
/// version covering today is replaced from today when its position differs,
/// and scheduled versions get a corrected start index.
Future<void> repairLegacyCycleAlignment(
  GeneratedDatabase db, {
  DateTime? now,
}) => db.transaction(() async {
  await db.customStatement(
    'CREATE TABLE IF NOT EXISTS app_meta '
    '(key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
  );
  final done = await db
      .customSelect(
        'SELECT value FROM app_meta WHERE key = ?',
        variables: [Variable.withString(_repairedKey)],
      )
      .get();
  if (done.isNotEmpty) return;

  final today = CalendarDay.todayLocal(now);
  final plans = [
    for (final r
        in await db
            .customSelect(
              'SELECT * FROM diet_strategy_plans ORDER BY version, id',
            )
            .get())
      _Plan(r.data),
  ];

  // Rest days marked on or before their date may have paused the cycle;
  // [pauses] starts from the current toggles and absorbs frozen decisions.
  final eligible = <DateTime>{};
  final pauses = <DateTime>{};
  for (final r
      in await db
          .customSelect("SELECT * FROM day_markers WHERE type = 'restDay'")
          .get()) {
    final day = StrategyDates.tryDecode(r.data['date'] as String?);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      (r.data['updated_at'] as int) * 1000,
    );
    if (day == null || !restDayCountsTowardProgression(day, updatedAt)) {
      continue;
    }
    eligible.add(day);
    if (r.data['pause_carb_cycle'] == 1) pauses.add(day);
  }

  final snapshots = [
    for (final r
        in await db
            .customSelect(
              "SELECT * FROM daily_nutrition_targets WHERE source = 'strategy' "
              "AND strategy = 'carbCycle' AND day_type IS NOT NULL ORDER BY date",
            )
            .get())
      if (DateTime.parse(r.data['date'] as String).isBefore(today)) r.data,
  ];

  final histories = <int, CycleHistory>{};
  for (final p in plans) {
    final schedule = p.schedule;
    if (schedule == null || p.isV32Repair) continue;
    final observations = [
      for (final s in snapshots)
        if (s['plan_id'] == p.id)
          CycleObservation(
            DateTime.parse(s['date'] as String),
            CarbDayType.fromCode(s['day_type'] as String),
            index: s['cycle_index'] as int?,
            paused: s['cycle_paused'] == null ? null : s['cycle_paused'] == 1,
          ),
    ];
    if (observations.isEmpty) continue;
    histories[p.id] = inferCycleHistory(
      schedule,
      observations,
      eligible,
      currentPauses: pauses,
    );
  }

  int held(DateTime from, DateTime until) =>
      pauses.where((d) => !d.isBefore(from) && d.isBefore(until)).length;

  // Correct start index per version, null when it cannot be determined.
  final desired = <int, int?>{};
  final misaligned = <int>{};
  for (final p in plans) {
    desired[p.id] = p.startIndex;
    final schedule = p.schedule;
    if (!p.isCarbCycle || schedule == null) continue;
    final previous = _previous(plans, p);
    final oldSchedule = previous?.schedule;
    if (previous != null &&
        previous.isCarbCycle &&
        !previous.isStopped &&
        oldSchedule != null) {
      final history = misaligned.contains(previous.id)
          ? null
          : histories[previous.id];
      final previousIndex = desired[previous.id];
      final inherited = history != null
          ? history.project(p.from, oldSchedule.cycleLengthDays, pauses)
          : previousIndex == null
          ? null
          : StrategyDates.cycleIndexOf(
              p.from,
              previous.from,
              oldSchedule.cycleLengthDays,
              startIndex: previousIndex,
              restDaysBefore: held(previous.from, p.from),
            );
      desired[p.id] = inherited == null
          ? null
          : inherited % schedule.cycleLengthDays;
    }
    if (desired[p.id] != p.startIndex) misaligned.add(p.id);

    // Freeze singleton decisions of versions whose own history is trusted.
    final history = histories[p.id];
    if (history == null || misaligned.contains(p.id)) continue;
    for (final s in snapshots.where((s) => s['plan_id'] == p.id)) {
      final day = DateTime.parse(s['date'] as String);
      final positions = history.positions[day];
      final decisions = history.pauses[day];
      final index = positions?.length == 1 ? positions!.single : null;
      final pause = decisions?.length == 1 ? decisions!.single : null;
      if (index == null && pause == null) continue;
      await db.customStatement(
        'UPDATE daily_nutrition_targets SET '
        'cycle_index = COALESCE(cycle_index, ?), '
        'cycle_paused = COALESCE(cycle_paused, ?) WHERE date = ?',
        [index, pause == null ? null : (pause ? 1 : 0), s['date']],
      );
      if (pause == true) pauses.add(day);
      if (pause == false) pauses.remove(day);
    }
  }

  // Scheduled versions keep their dates and parameters.
  for (final p in plans) {
    final index = desired[p.id];
    if (p.from.isAfter(today) &&
        p.isCarbCycle &&
        !p.isStopped &&
        index != null &&
        index != p.startIndex) {
      await db.customStatement(
        'UPDATE diet_strategy_plans SET cycle_start_index = ? WHERE id = ?',
        [index, p.id],
      );
    }
  }

  final current = plans.where((p) => p.covers(today)).lastOrNull;
  final schedule = current?.schedule;
  final ideal = current == null ? null : desired[current.id];
  if (current != null && current.isCarbCycle && schedule != null) {
    final length = schedule.cycleLengthDays;
    final history = misaligned.contains(current.id)
        ? null
        : histories[current.id];
    final expected = history != null
        ? history.project(today, length, pauses)
        : ideal == null
        ? null
        : StrategyDates.cycleIndexOf(
            today,
            current.from,
            length,
            startIndex: ideal,
            restDaysBefore: held(current.from, today),
          );
    final actual = StrategyDates.cycleIndexOf(
      today,
      current.from,
      length,
      startIndex: current.startIndex,
      restDaysBefore: held(current.from, today),
    );
    if (expected != null && expected != actual) {
      await _replaceFromToday(db, plans, current, expected, today, now);
    }
  }

  await db.customStatement(
    'INSERT OR REPLACE INTO app_meta (key, value) VALUES (?, ?)',
    [_repairedKey, '1'],
  );
});

/// The version that governed the day before [p] started.
_Plan? _previous(List<_Plan> plans, _Plan p) {
  final dayBefore = DateTime(p.from.year, p.from.month, p.from.day - 1);
  return plans
      .where((c) => c.version < p.version && c.covers(dayBefore))
      .lastOrNull;
}

/// Ends [current] today and continues it from today at [index], keeping its
/// parameters and any scheduled switch boundary. Only today's strategy
/// snapshot is dropped; manual overrides survive.
Future<void> _replaceFromToday(
  GeneratedDatabase db,
  List<_Plan> plans,
  _Plan current,
  int index,
  DateTime today,
  DateTime? now,
) async {
  final date = StrategyDates.encode(today);
  final maxVersion = plans
      .map((p) => p.version)
      .reduce((a, b) => a > b ? a : b);
  final copy = Map<String, dynamic>.from(current.row)
    ..remove('id')
    ..['version'] = maxVersion + 1
    ..['effective_from'] = date
    ..['created_at'] = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000
    ..['cycle_start_index'] = index
    ..['reason'] =
        '${(current.row['reason'] as String).replaceAll(';$_v32RepairTag', '')}'
        ';cycleHistoryRepair';
  await db.customStatement(
    "UPDATE diet_strategy_plans SET ended_on = ?, status = 'superseded' "
    'WHERE id = ?',
    [date, current.id],
  );
  final columns = copy.keys.map((k) => '"$k"').join(', ');
  final values = List.filled(copy.length, '?').join(', ');
  await db.customStatement(
    'INSERT INTO diet_strategy_plans ($columns) VALUES ($values)',
    copy.values.toList(),
  );
  await db.customStatement(
    "DELETE FROM daily_nutrition_targets WHERE date = ? AND source = 'strategy'",
    [date],
  );
}

/// Raw `diet_strategy_plans` row as seen by the migration.
class _Plan {
  _Plan(this.row);
  final Map<String, dynamic> row;

  int get id => row['id'] as int;
  int get version => row['version'] as int;
  int get startIndex => row['cycle_start_index'] as int;
  DateTime get from => DateTime.parse(row['effective_from'] as String);
  DateTime? get endedOn => StrategyDates.tryDecode(row['ended_on'] as String?);
  bool get isCarbCycle => row['strategy'] == 'carbCycle';
  bool get isStopped => row['status'] == 'stopped';
  bool get isV32Repair => (row['reason'] as String).contains(_v32RepairTag);
  CarbCycleSchedule? get schedule =>
      CarbCycleSchedule.tryParse(row['schedule'] as String?);

  bool covers(DateTime day) {
    final end = endedOn;
    return !day.isBefore(from) && (end == null || day.isBefore(end));
  }
}
