import 'calendar_day.dart';
import 'day_marker.dart';
import 'diet_plan.dart';
import 'maintain.dart';

/// A past day's diet verdict, judged like the deficit calendar's green/red:
/// `true` when intake stayed within the day's target, `false` when it went
/// over, `null` when the day isn't judged — no meal log, no target or a
/// legacy estimate, or a 放纵日/休息日 (a 冲碳日 keeps its real target and is
/// judged as usual). Inside a cut round a later standard change does not
/// blank earlier days, so no calorie-standard cut-off applies here.
bool? dietDayMet({
  required DailyNutritionTarget? target,
  required double? intake,
  required DayMarkerType? marker,
}) {
  if (intake == null || target == null || target.isLegacyEstimate) return null;
  if (marker == DayMarkerType.cheatMeal || marker == DayMarkerType.restDay) {
    return null;
  }
  return intakeMet(target, intake);
}

/// A cut round's start and latest weight, smoothed against water weight.
class RoundWeightTrend {
  const RoundWeightTrend({
    required this.endKg,
    required this.endSamples,
    this.startKg,
    this.startSamples = 0,
  });

  /// Mean of the last kept weigh-ins.
  final double endKg;
  final int endSamples;

  /// Mean of the first kept weigh-ins; null with fewer than two kept.
  final double? startKg;
  final int startSamples;
}

/// Days a weigh-in is skewed by a 放纵日 (water and glycogen, not fat): the
/// 放纵日 itself and the [afterCheatDays] days after it.
const cheatWeightWindowDays = 3;

/// Whether [day] falls on a 放纵日 in [cheatDays] or within
/// [afterCheatDays] days after one. [cheatDays] must be day-only dates.
bool isWithinCheatWindow(
  DateTime day,
  Set<DateTime> cheatDays, {
  int afterCheatDays = cheatWeightWindowDays,
}) {
  final d = CalendarDay.dayOnly(day);
  for (var back = 0; back <= afterCheatDays; back++) {
    if (cheatDays.contains(CalendarDay.addDays(d, -back))) return true;
  }
  return false;
}

/// Drops weigh-ins taken on a 放纵日 or the [afterCheatDays] days after it
/// (water and glycogen, not fat), then averages the first [window] kept for
/// the start and the last [window] for the end. With fewer than
/// `2 × window` kept they are split in halves instead, so start and end never
/// share a weigh-in; a single one is the end only. [cheatDays] should include
/// 放纵日 up to [afterCheatDays] before the round, which still skew its first
/// weigh-ins. `trend` is null when nothing is left; `excluded` counts the
/// dropped weigh-ins.
({RoundWeightTrend? trend, int excluded}) roundWeightTrend({
  required List<({DateTime day, double kg})> logs,
  required Set<DateTime> cheatDays,
  int window = 3,
  int afterCheatDays = cheatWeightWindowDays,
}) {
  final cheat = {for (final d in cheatDays) CalendarDay.dayOnly(d)};
  final kept = [
    for (final log in logs)
      if (!isWithinCheatWindow(log.day, cheat, afterCheatDays: afterCheatDays))
        log,
  ]..sort((a, b) => a.day.compareTo(b.day));
  final excluded = logs.length - kept.length;
  final n = kept.length;
  if (n == 0) return (trend: null, excluded: excluded);

  double mean(Iterable<({DateTime day, double kg})> xs) =>
      xs.fold<double>(0, (s, x) => s + x.kg) / xs.length;

  if (n == 1) {
    return (
      trend: RoundWeightTrend(endKg: kept.single.kg, endSamples: 1),
      excluded: excluded,
    );
  }
  final startCount = n >= 2 * window ? window : n ~/ 2;
  final endCount = n >= 2 * window ? window : n - startCount;
  return (
    trend: RoundWeightTrend(
      endKg: mean(kept.skip(n - endCount)),
      endSamples: endCount,
      startKg: mean(kept.take(startCount)),
      startSamples: startCount,
    ),
    excluded: excluded,
  );
}
