import 'package:drift/drift.dart';

import '../../domain/day_marker.dart';
import '../../domain/diet_strategy.dart';
import '../db.dart';

/// Per-day 放纵日/休息日 markers. Both may be set on any date, past included;
/// see [setRestDay] and [restDayCountsTowardProgression] for how a
/// backfilled past 休息日 is excluded from the carb-cycle day-count math.
class DayMarkerRepository {
  DayMarkerRepository(this._db);

  final AppDatabase _db;

  DayMarkerType? _typeOf(DayMarkerRow row) =>
      DayMarkerType.fromStorage(row.type);

  DayMarkerSettings? _settingsOf(DayMarkerRow row) {
    final type = _typeOf(row);
    if (type == null) return null;
    final date = StrategyDates.tryDecode(row.date);
    return DayMarkerSettings(
      type: type,
      pauseCarbCycle:
          row.pauseCarbCycle &&
          date != null &&
          restDayCountsTowardProgression(date, row.updatedAt),
      cheatPenaltyEnabled: row.cheatPenaltyEnabled,
      cheatPenaltyKcal: row.cheatPenaltyKcal,
      excludeContributions: row.excludeContributions,
      includeSteps: row.includeSteps,
      includeDiet: row.includeDiet,
    );
  }

  Future<DayMarkerRow?> _rowForDay(DateTime day) => (_db.select(
    _db.dayMarkers,
  )..where((t) => t.date.equals(StrategyDates.encode(day)))).getSingleOrNull();

  Future<DayMarkerSettings?> settingsForDay(DateTime day) async {
    final row = await _rowForDay(day);
    return row == null ? null : _settingsOf(row);
  }

  Stream<DayMarkerSettings?> watchSettingsForDay(DateTime day) =>
      (_db.select(_db.dayMarkers)
            ..where((t) => t.date.equals(StrategyDates.encode(day))))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _settingsOf(row));

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

  /// Dates whose 休息日 marker counts toward the carb-cycle day-count pause
  /// (unordered, no range filter — used by the diet-strategy day-count math,
  /// which needs the full history). Excludes markers backfilled onto an
  /// already-past date — see [restDayCountsTowardProgression].
  Future<List<DateTime>> restDayDates() async {
    final rows = await (_db.select(
      _db.dayMarkers,
    )..where((t) => t.type.equals(DayMarkerType.restDay.name))).get();
    return progressionRestDayDates(rows);
  }

  /// Live version of [restDayDates] — re-emits whenever any marker changes,
  /// so carb-cycle previews stay in sync as 休息日 gets marked/cleared.
  Stream<List<DateTime>> watchRestDayDates() {
    return (_db.select(_db.dayMarkers)
          ..where((t) => t.type.equals(DayMarkerType.restDay.name)))
        .watch()
        .map(progressionRestDayDates);
  }

  /// Filters raw 休息日 marker rows down to the ones that count toward the
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
    // The original rest-day timestamp determines whether it may move the
    // cycle. Editing choices must not turn a contemporaneous mark into a
    // backfilled one (or vice versa).
    final markedAt =
        previous?.type == DayMarkerType.restDay.name &&
            settings.type == DayMarkerType.restDay
        ? previous!.updatedAt
        : now ?? DateTime.now();
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
          ),
        );
  }

  /// 放纵日: any date, past/today/future.
  Future<void> setCheatMeal(
    DateTime day, {
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

  Future<void> clear(DateTime day) async {
    await (_db.delete(
      _db.dayMarkers,
    )..where((t) => t.date.equals(StrategyDates.encode(day)))).go();
  }

  Future<void> clearAll() => _db.delete(_db.dayMarkers).go();
}
