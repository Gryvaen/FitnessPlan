/// Per-day override marker: 放纵日 (cheatMeal) or 休息日 (restDay).
library;

import 'calendar_day.dart';

enum DayMarkerType {
  /// 放纵日: any date.
  cheatMeal,

  /// 休息日: any date, including the past. May pause the carb-cycle day-count
  /// for later dates when chosen and marked on/before its own date — see
  /// [restDayCountsTowardProgression]; a rest day backfilled onto an
  /// already-past date is a historical record only and never retroactively
  /// shifts today's/future's targets.
  restDay;

  static DayMarkerType? fromStorage(String? raw) {
    for (final t in values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}

/// Persisted choices for one calendar marker. [excludeContributions] is only
/// true for markers created before the editable marker settings existed.
class DayMarkerSettings {
  const DayMarkerSettings({
    required this.type,
    this.pauseCarbCycle = false,
    this.cheatPenaltyEnabled = true,
    this.cheatPenaltyKcal = 1000,
    this.excludeContributions = false,
  });

  final DayMarkerType type;
  final bool pauseCarbCycle;
  final bool cheatPenaltyEnabled;
  final int cheatPenaltyKcal;
  final bool excludeContributions;

  double get penaltyKcal =>
      type == DayMarkerType.cheatMeal && cheatPenaltyEnabled
      ? -cheatPenaltyKcal.toDouble()
      : 0;
}

/// Whether a 休息日 marker set on [date] and last touched at [updatedAt]
/// should count toward the carb-cycle day-count pause. True only when it was
/// marked on/before its own calendar day (the date was today-or-future at
/// marking time) — a marker backfilled onto a date that had already passed
/// is excluded, so retroactively marking a past day rest never shifts
/// already-computed today/future targets.
bool restDayCountsTowardProgression(DateTime date, DateTime updatedAt) {
  return !CalendarDay.dayOnly(updatedAt).isAfter(CalendarDay.dayOnly(date));
}
