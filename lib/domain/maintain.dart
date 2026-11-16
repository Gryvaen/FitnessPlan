/// 维持 (maintenance) rules: the daily target band and weight averages.
library;

import 'calendar_day.dart';
import 'diet_plan.dart';

/// A maintenance day counts as on target within ±10% of its calories.
const double maintainBandFraction = 0.10;

/// Inclusive kcal band around a maintenance target.
({double low, double high}) maintainBand(double kcal) => (
  low: kcal * (1 - maintainBandFraction),
  high: kcal * (1 + maintainBandFraction),
);

/// A 增肌 day counts as on target from its calories up to +10%.
const double bulkBandFraction = 0.10;

/// The kcal band a day is judged by, or null when it only has a ceiling:
/// 维持 days ±[maintainBandFraction]; 增肌 days from the target up to
/// +[bulkBandFraction] (eating too little misses the surplus, far more is
/// fat gain); fat-loss and other days just stay at or under the target.
({double low, double high})? intakeBand(DailyNutritionTarget target) {
  final kcal = target.calories;
  if (target.isMaintainDay) return maintainBand(kcal);
  if (target.isBulkDay) return (low: kcal, high: kcal * (1 + bulkBandFraction));
  return null;
}

/// Whether [intake] meets [target]: inside its [intakeBand] when it has one,
/// otherwise at or under its calories.
bool intakeMet(DailyNutritionTarget target, double intake) {
  final band = intakeBand(target);
  if (band != null) return intake >= band.low && intake <= band.high;
  return intake <= target.calories;
}

/// Mean of the weigh-ins on local days in `[from, to]` (inclusive), or null
/// when there are none.
double? averageWeight(
  Iterable<(DateTime, double)> logs, {
  required DateTime from,
  required DateTime to,
}) {
  final start = CalendarDay.dayOnly(from);
  final end = CalendarDay.dayOnly(to);
  var sum = 0.0;
  var n = 0;
  for (final (date, kg) in logs) {
    final d = CalendarDay.dayOnly(date);
    if (d.isBefore(start) || d.isAfter(end) || !kg.isFinite || kg <= 0) {
      continue;
    }
    sum += kg;
    n++;
  }
  return n == 0 ? null : sum / n;
}

/// The 7-day average ending on [today].
double? recentWeightAverage(
  Iterable<(DateTime, double)> logs, {
  required DateTime today,
}) => averageWeight(logs, from: CalendarDay.addDays(today, -6), to: today);

/// Reference weight at the start of maintenance: the average of the week
/// up to and including [since]; with no weigh-in there, the first weigh-in
/// after it.
double? maintainBaselineWeight(
  Iterable<(DateTime, double)> logs, {
  required DateTime since,
}) {
  final week = averageWeight(
    logs,
    from: CalendarDay.addDays(since, -6),
    to: since,
  );
  if (week != null) return week;
  final start = CalendarDay.dayOnly(since);
  (DateTime, double)? first;
  for (final log in logs) {
    final d = CalendarDay.dayOnly(log.$1);
    if (d.isBefore(start) || !log.$2.isFinite || log.$2 <= 0) continue;
    if (first == null || d.isBefore(CalendarDay.dayOnly(first.$1))) {
      first = log;
    }
  }
  return first?.$2;
}
