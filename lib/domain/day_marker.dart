/// Per-day override marker: 放纵餐 (cheatMeal) or 休息日 (restDay).
library;

import 'calendar_day.dart';

enum DayMarkerType {
  /// 放纵餐: any date. Zeroes that day's diet kcal in 修行记录; steps unaffected.
  cheatMeal,

  /// 休息日: any date, including the past. Zeroes that day's diet + steps
  /// kcal in 修行记录. Only pauses the carb-cycle day-count for later dates
  /// when it was marked on/before its own date — see
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

/// Whether a 休息日 marker set on [date] and last touched at [updatedAt]
/// should count toward the carb-cycle day-count pause. True only when it was
/// marked on/before its own calendar day (the date was today-or-future at
/// marking time) — a marker backfilled onto a date that had already passed
/// is excluded, so retroactively marking a past day rest never shifts
/// already-computed today/future targets.
bool restDayCountsTowardProgression(DateTime date, DateTime updatedAt) {
  return !CalendarDay.dayOnly(updatedAt).isAfter(CalendarDay.dayOnly(date));
}
