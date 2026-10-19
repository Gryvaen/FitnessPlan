import 'package:drift/drift.dart';

import '../../domain/day_marker.dart';
import '../../domain/calendar_day.dart';
import '../../domain/diet_strategy.dart';
import '../db.dart';

/// Per-day 放纵日/休息日/冲碳日 markers. 放纵日/休息日 may be set on any date,
/// past included; 冲碳日 is set from today on. Any of them may pause the
/// carb-cycle day-count — see [restDayCountsTowardProgression] for how a
/// backfilled past marker is excluded from that math.
class DayMarkerRepository {
  DayMarkerRepository(this._db);

  final AppDatabase _db;

  DayMarkerType? _typeOf(DayMarkerRow row) =>
      DayMarkerType.fromStorage(row.type);

  DayMarkerSettings? _settingsOf(DayMarkerRow row, {bool? frozenPause}) {
    final type = _typeOf(row);
    if (type == null) return null;
    final date = StrategyDates.tryDecode(row.date);
    return DayMarkerSettings(
      type: type,
      pauseCarbCycle:
          frozenPause ??
          (row.pauseCarbCycle &&
              date != null &&
              restDayCountsTowardProgression(date, row.updatedAt)),
      cheatPenaltyEnabled: row.cheatPenaltyEnabled,
      cheatPenaltyKcal: row.cheatPenaltyKcal,
      excludeContributions: row.excludeContributions,
      includeSteps: row.includeSteps,
      includeDiet: row.includeDiet,
      carbLoadCarbPerKg: row.carbLoadCarbPerKg,
    );
  }

  Future<DayMarkerRow?> _rowForDay(DateTime day) => (_db.select(
    _db.dayMarkers,
  )..where((t) => t.date.equals(StrategyDates.encode(day)))).getSingleOrNull();

  Future<DayMarkerSettings?> settingsForDay(DateTime day) async {
    final row = await _rowForDay(day);
    if (row == null) return null;
    final snap = StrategyDates.dayOnly(day).isBefore(CalendarDay.todayLocal())
        ? await (_db.select(_db.dailyNutritionTargets)
                ..where((t) => t.date.equals(StrategyDates.encode(day))))
              .getSingleOrNull()
        : null;
    return _settingsOf(row, frozenPause: snap?.cyclePaused);
  }

  Stream<DayMarkerSettings?> watchSettingsForDay(DateTime day) =>
      (_db.select(_db.dayMarkers)
            ..where((t) => t.date.equals(StrategyDates.encode(day))))
          .watchSingleOrNull()
          .asyncMap((_) => settingsForDay(day));

  Future<DayMarkerType?> markerForDay(DateTime day) async {
    final row = await _rowForDay(day);
    return row == null ? null : _typeOf(row);
  }

  Stream<DayMarkerType?> watchMarkerForDay(DateTime day) {
    return (_db.select(_db.dayMarkers)
          ..where((t) => t.date.equals(StrategyDates.encode(day))))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _typeOf(row));
  }

  /// Markers for every local day in `[start, end]` (inclusive).
  Future<Map<DateTime, DayMarkerType>> markersBetween(
    DateTime start,
    DateTime end,
  ) async {
    final s = StrategyDates.dayOnly(start);
    final e = StrategyDates.dayOnly(end);
    if (e.isBefore(s)) return const {};
    final rows =
        await (_db.select(_db.dayMarkers)..where(
              (t) => t.date.isBetweenValues(
                StrategyDates.encode(s),
                StrategyDates.encode(e),
              ),
            ))
            .get();
    final out = <DateTime, DayMarkerType>{};
    for (final row in rows) {
      final date = StrategyDates.tryDecode(row.date);
      final type = _typeOf(row);
      if (date != null && type != null) out[date] = type;
    }
    return out;
  }

  Future<Map<DateTime, DayMarkerSettings>> settingsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final s = StrategyDates.dayOnly(start);
    final e = StrategyDates.dayOnly(end);
    if (e.isBefore(s)) return const {};
    final rows =
        await (_db.select(_db.dayMarkers)..where(
              (t) => t.date.isBetweenValues(
                StrategyDates.encode(s),
                StrategyDates.encode(e),
              ),
            ))
            .get();
    final out = <DateTime, DayMarkerSettings>{};
    for (final row in rows) {
      final date = StrategyDates.tryDecode(row.date);
      final settings = _settingsOf(row);
      if (date != null && settings != null) out[date] = settings;
    }
    return out;
  }

  /// Settings of every marker from today on, keyed by day — what carb-cycle
  /// previews need to label paused rows and show 冲碳日 macros.
  Stream<Map<DateTime, DayMarkerSettings>> watchUpcomingSettings() {
    final today = StrategyDates.encode(CalendarDay.todayLocal());
    return (_db.select(
      _db.dayMarkers,
    )..where((t) => t.date.isBiggerOrEqualValue(today))).watch().map(
      (rows) => {
        for (final row in rows)
          if ((StrategyDates.tryDecode(row.date), _settingsOf(row)) case (
            final date?,
            final settings?,
          ))
            date: settings,
      },
    );
  }

  /// The effective carb-cycle pause set, sorted (no range filter — the
  /// diet-strategy day-count math needs the full history).
  ///
  /// Past days use the pause frozen on their snapshot, so later toggle edits
  /// never rewrite an executed day sequence; today and the future follow the
  /// markers of every type whose pause switch is on. Markers backfilled onto
  /// an already-past date never count — see
  /// [restDayCountsTowardProgression].
  Future<List<DateTime>> restDayDates({DateTime? now}) async {
    final rows = await (_db.select(
      _db.dayMarkers,
    )..where((t) => t.pauseCarbCycle.equals(true))).get();
    final dates = progressionRestDayDates(rows).toSet();
    final today = StrategyDates.encode(CalendarDay.todayLocal(now));
    final snapshots =
        await (_db.select(_db.dailyNutritionTargets)..where(
              (t) =>
                  t.date.isSmallerThanValue(today) &
                  t.cyclePaused.isNotNull() &
                  t.strategy.equals('carbCycle'),
            ))
            .get();
    for (final row in snapshots) {
      final day = StrategyDates.tryDecode(row.date);
      if (day == null) continue;
      if (row.cyclePaused!) {
        dates.add(day);
      } else {
        dates.remove(day);
      }
    }
    return dates.toList()..sort();
  }

  Stream<List<DateTime>> watchRestDayDates() => _db
      .customSelect(
        'SELECT date FROM day_markers UNION '
        'SELECT date FROM daily_nutrition_targets WHERE cycle_paused IS NOT NULL',
        readsFrom: {_db.dayMarkers, _db.dailyNutritionTargets},
      )
      .watch()
      .asyncMap((_) => restDayDates());

  /// Filters raw marker rows down to the ones that count toward the
  /// carb-cycle day-count progression (see [restDayCountsTowardProgression]).
  /// Shared with [DietStrategyRepository], which queries `day_markers`
  /// directly (bounded by plan range) rather than going through this
  /// repository.
  static List<DateTime> progressionRestDayDates(List<DayMarkerRow> rows) => [
    for (final row in rows)
      if (StrategyDates.tryDecode(row.date) case final date?)
        if (row.pauseCarbCycle &&
            restDayCountsTowardProgression(date, row.updatedAt))
          date,
  ];

  Future<void> _set(
    DateTime day,
    DayMarkerSettings settings, {
    DateTime? now,
  }) async {
    final previous = await _rowForDay(day);
    // The original mark timestamp determines whether it may move the cycle.
    // Editing choices — or switching type — must not turn a contemporaneous
    // mark into a backfilled one (or vice versa).
    final markedAt = previous?.updatedAt ?? now ?? DateTime.now();
    await _db
        .into(_db.dayMarkers)
        .insertOnConflictUpdate(
          DayMarkersCompanion.insert(
            date: StrategyDates.encode(day),
            type: settings.type.name,
            updatedAt: markedAt,
            pauseCarbCycle: Value(settings.pauseCarbCycle),
            cheatPenaltyEnabled: Value(settings.cheatPenaltyEnabled),
            cheatPenaltyKcal: Value(settings.cheatPenaltyKcal),
            excludeContributions: const Value(false),
            includeSteps: Value(settings.includeSteps),
            includeDiet: Value(settings.includeDiet),
            carbLoadCarbPerKg: Value(settings.carbLoadCarbPerKg),
          ),
        );
  }

  /// 放纵日: any date, past/today/future.
  Future<void> setCheatMeal(
    DateTime day, {
    bool pauseCarbCycle = false,
    bool includeSteps = true,
    bool includeDiet = false,
    bool deductKcal = true,
    int penaltyKcal = 1000,
    DateTime? now,
  }) {
    if (penaltyKcal <= 0) throw ArgumentError.value(penaltyKcal, 'penaltyKcal');
    return _set(
      day,
      DayMarkerSettings(
        type: DayMarkerType.cheatMeal,
        pauseCarbCycle: pauseCarbCycle,
        includeSteps: includeSteps,
        includeDiet: includeDiet,
        cheatPenaltyEnabled: deductKcal,
        cheatPenaltyKcal: penaltyKcal,
      ),
      now: now,
    );
  }

  /// 休息日: any date, past included. A past date marked this way is a
  /// historical record only — see [restDayCountsTowardProgression].
  Future<void> setRestDay(
    DateTime day, {
    bool pauseCarbCycle = false,
    bool includeSteps = true,
    bool includeDiet = true,
    DateTime? now,
  }) {
    return _set(
      day,
      DayMarkerSettings(
        type: DayMarkerType.restDay,
        pauseCarbCycle: pauseCarbCycle,
        includeSteps: includeSteps,
        includeDiet: includeDiet,
      ),
      now: now,
    );
  }

  /// 冲碳日: today or later, carb-cycle plans only (enforced by the UI).
  /// [carbPerKg] is clamped to the plan's high day when the target is
  /// resolved, so only the absolute ceiling is checked here.
  Future<void> setCarbLoad(
    DateTime day, {
    required double carbPerKg,
    bool pauseCarbCycle = false,
    bool includeSteps = true,
    bool includeDiet = true,
    DateTime? now,
  }) {
    if (!carbPerKg.isFinite ||
        carbPerKg <= 0 ||
        carbPerKg > StrategyRules.carbLoadCarbPerKgMax + 1e-9) {
      throw ArgumentError.value(carbPerKg, 'carbPerKg');
    }
    return _set(
      day,
      DayMarkerSettings(
        type: DayMarkerType.carbLoad,
        pauseCarbCycle: pauseCarbCycle,
        includeSteps: includeSteps,
        includeDiet: includeDiet,
        carbLoadCarbPerKg: carbPerKg,
      ),
      now: now,
    );
  }

  Future<void> clear(DateTime day) async {
    await (_db.delete(
      _db.dayMarkers,
    )..where((t) => t.date.equals(StrategyDates.encode(day)))).go();
  }

  Future<void> clearAll() => _db.delete(_db.dayMarkers).go();
}
