/// Per-day override marker: 放纵日 (cheatMeal), 休息日 (restDay) or 冲碳日
/// (carbLoad). Any of them may optionally pause the carb-cycle day-count —
/// see [DayMarkerSettings.pauseCarbCycle].
library;

import 'calendar_day.dart';

enum DayMarkerType {
  /// 放纵日: any date.
  cheatMeal,

  /// 休息日: any date, including the past. A rest day backfilled onto an
  /// already-past date is a historical record only and never retroactively
  /// shifts today's/future's targets — see [restDayCountsTowardProgression].
  restDay,

  /// 冲碳日: today or later, carb-cycle plans only. The day's target is the
  /// high day's protein/fat with carbs raised to
  /// [DayMarkerSettings.carbLoadCarbPerKg] (see `CarbCyclePlan.carbLoadDay`).
  carbLoad;

  static DayMarkerType? fromStorage(String? raw) {
    for (final t in values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}

/// Persisted cultivation and carb-cycle choices for one calendar day.
class DayMarkerSettings {
  const DayMarkerSettings({
    required this.type,
    this.pauseCarbCycle = false,
    this.cheatPenaltyEnabled = true,
    this.cheatPenaltyKcal = 1000,
    this.excludeContributions = false,
    this.includeSteps = true,
    bool? includeDiet,
    this.carbLoadCarbPerKg,
  }) : includeDiet = includeDiet ?? (type != DayMarkerType.cheatMeal);

  final DayMarkerType type;
  final bool pauseCarbCycle;
  final bool cheatPenaltyEnabled;
  final int cheatPenaltyKcal;
  final bool excludeContributions;
  final bool includeSteps;
  final bool includeDiet;

  /// 冲碳日 carbs (g per kg reference weight); null for other types.
  final double? carbLoadCarbPerKg;

  double get penaltyKcal =>
      type == DayMarkerType.cheatMeal && !includeDiet && cheatPenaltyEnabled
      ? -cheatPenaltyKcal.toDouble()
      : 0;
}

/// Whether a marker (any type) set on [date] and first marked at [updatedAt]
/// should count toward the carb-cycle day-count pause. True only when it was
/// marked on/before its own calendar day (the date was today-or-future at
/// marking time) — a marker backfilled onto a date that had already passed
/// is excluded, so retroactively marking a past day never shifts
/// already-computed today/future targets.
bool restDayCountsTowardProgression(DateTime date, DateTime updatedAt) {
  return !CalendarDay.dayOnly(updatedAt).isAfter(CalendarDay.dayOnly(date));
}
