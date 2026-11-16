import 'calendar_day.dart';
import 'cut_cultivation.dart';
import 'models.dart';

/// One stretch on a single profile goal (减脂 / 维持 / 增肌), drawn on the
/// deficit calendar as a bracket from [start] to [end]. Stretches never
/// overlap: a switch on day D ends the previous one on D − 1.
class GoalPeriod {
  const GoalPeriod({required this.goal, required this.start, this.end});

  final FitnessGoal goal;

  /// Inclusive first local day.
  final DateTime start;

  /// Inclusive last local day; null while still on this goal.
  final DateTime? end;

  bool get isOpen => end == null;

  bool containsDay(DateTime day) {
    final d = CalendarDay.dayOnly(day);
    if (d.isBefore(CalendarDay.dayOnly(start))) return false;
    final e = end;
    return e == null || !d.isAfter(CalendarDay.dayOnly(e));
  }

  GoalPeriod endOn(DateTime day) =>
      GoalPeriod(goal: goal, start: start, end: CalendarDay.dayOnly(day));

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'start': _day(start),
    'end': end == null ? null : _day(end!),
  };

  static GoalPeriod? fromJson(Map<String, dynamic> json) {
    final goal = FitnessGoal.values.asNameMap()[json['goal']];
    final start = _parse(json['start'] as String?);
    if (goal == null || start == null) return null;
    return GoalPeriod(
      goal: goal,
      start: start,
      end: _parse(json['end'] as String?),
    );
  }

  static String _day(DateTime d) {
    final day = CalendarDay.dayOnly(d);
    final m = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '${day.year}-$m-$dd';
  }

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? null : CalendarDay.dayOnly(parsed);
  }
}

/// [periods] after switching to [goal] on [day]: the open stretch ends the
/// day before (dropped if it only began that day, i.e. a second switch the
/// same day) and a new one opens on [day]. Unchanged when already on [goal].
List<GoalPeriod> switchGoalPeriods(
  List<GoalPeriod> periods,
  FitnessGoal goal,
  DateTime day,
) {
  final d = CalendarDay.dayOnly(day);
  final open = periods.where((p) => p.isOpen).lastOrNull;
  if (open?.goal == goal) return periods;
  final kept = [
    for (final p in periods)
      if (!p.isOpen)
        p
      else if (CalendarDay.dayOnly(p.start).isBefore(d))
        p.endOn(CalendarDay.addDays(d, -1)),
  ];
  // Switching back the same day (cut → maintain → cut): the stretch that
  // was just closed simply carries on, instead of being split in two.
  final last = kept.lastOrNull;
  if (last != null &&
      last.goal == goal &&
      last.end == CalendarDay.addDays(d, -1)) {
    return [
      ...kept.take(kept.length - 1),
      GoalPeriod(goal: goal, start: last.start),
    ];
  }
  return [...kept, GoalPeriod(goal: goal, start: d)];
}

/// Goal stretches reconstructed for installs from before they were recorded:
/// each cut round becomes a 减脂 stretch; after the last closed round, a
/// non-cut current goal runs from its switch day ([UserProfile.
/// calorieStandardSince], which a goal switch stamps), or from the day
/// after the round. Never having cut, a non-cut goal runs from that same
/// day when known. Gaps between rounds were maintenance or bulk — which one
/// is unknown, so they stay unbracketed.
List<GoalPeriod> backfillGoalPeriods(
  List<CutCultivationSegment> segments,
  UserProfile? profile,
) {
  final out = [
    for (final s in segments)
      GoalPeriod(
        goal: FitnessGoal.cut,
        start: CalendarDay.dayOnly(s.start),
        end: s.end == null ? null : CalendarDay.dayOnly(s.end!),
      ),
  ];
  if (profile == null || profile.goal == FitnessGoal.cut) return out;
  final since = profile.calorieStandardSince == null
      ? null
      : CalendarDay.dayOnly(profile.calorieStandardSince!);
  if (out.isEmpty) {
    return since == null ? out : [GoalPeriod(goal: profile.goal, start: since)];
  }
  final last = out.last;
  if (last.isOpen) return out;
  final lastEnd = last.end!;
  final start = since != null && since.isAfter(last.start)
      ? since
      : CalendarDay.addDays(lastEnd, 1);
  // The switch day itself belongs to the new goal.
  if (!lastEnd.isBefore(start)) {
    out[out.length - 1] = last.endOn(CalendarDay.addDays(start, -1));
  }
  out.add(GoalPeriod(goal: profile.goal, start: start));
  return out;
}
