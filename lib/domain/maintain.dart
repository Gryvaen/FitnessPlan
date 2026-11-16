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

/// Whether [intake] meets [target]: maintenance days must land inside the
/// band (eating far too little is a miss too); every other day only has to
/// stay at or under its calories.
bool intakeMet(DailyNutritionTarget target, double intake) {
  if (target.isMaintainDay) {
    final band = maintainBand(target.calories);
    return intake >= band.low && intake <= band.high;
  }
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
