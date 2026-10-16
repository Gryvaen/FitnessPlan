import 'diet_strategy.dart';

/// A carb-cycle position frozen by a past strategy snapshot. Later days are
/// counted from the latest anchor, so an executed day sequence survives
/// changes to rest-day toggles or plan parameters.
class CycleAnchor {
  const CycleAnchor(this.date, this.index);
  final DateTime date;
  final int index;
}

/// Resolved position of one calendar day. A paused day is a standalone
/// 休息日: it keeps [index] (the slot the next day continues with) for its
/// macros, but is not shown as a regular cycle day.
class CycleDay {
  const CycleDay(this.index, this.paused);
  final int index;
  final bool paused;
}

/// The single day-sequence resolver behind today's target, the calendar
/// and every strategy preview.
///
/// [pauses] is the effective pause set: frozen snapshot decisions for past
/// days, the live marker toggles for today and the future. Each paused day
/// holds the cycle for one day, matching [StrategyDates.cycleIndexOf].
CycleDay resolveCycleDay({
  required DateTime day,
  required DateTime start,
  required int startIndex,
  required int length,
  Iterable<DateTime> pauses = const [],
  Iterable<CycleAnchor> anchors = const [],
}) {
  final d = StrategyDates.dayOnly(day);
  var from = StrategyDates.dayOnly(start);
  var index = startIndex;
  for (final a in anchors) {
    final date = StrategyDates.dayOnly(a.date);
    if (date.isBefore(from) || date.isAfter(d)) continue;
    from = date;
    index = a.index;
  }
  final held = pauses
      .map(StrategyDates.dayOnly)
      .where((p) => !p.isBefore(from) && p.isBefore(d))
      .toSet()
      .length;
  return CycleDay(
    StrategyDates.cycleIndexOf(
      d,
      from,
      length,
      startIndex: index,
      restDaysBefore: held,
    ),
    pauses.any((p) => StrategyDates.dayOnly(p) == d),
  );
}

/// One recorded day of a plan: the day type it was given, plus any
/// position/pause already frozen on its snapshot.
class CycleObservation {
  const CycleObservation(this.date, this.type, {this.index, this.paused});
  final DateTime date;
  final CarbDayType type;
  final int? index;
  final bool? paused;
}

/// All positions and pause decisions supported by the complete observation
/// window. Repeated low days are not treated as interchangeable positions.
class CycleHistory {
  const CycleHistory(this.positions, this.pauses);
  final Map<DateTime, Set<int>> positions;
  final Map<DateTime, Set<bool>> pauses;
  bool get isConsistent => positions.isNotEmpty;

  /// Position on [day], projected past the last observation with
  /// [currentPauses]. Null when the evidence leaves it ambiguous.
  int? project(DateTime day, int length, Set<DateTime> currentPauses) {
    if (positions.isEmpty) return null;
    final last = positions.keys.last;
    if (!day.isAfter(last)) {
      final indices = positions[day];
      return indices?.length == 1 ? indices!.single : null;
    }
    var indices = positions[last]!;
    for (var d = last; d.isBefore(day); d = _next(d)) {
      final choices = pauses[d] ?? {currentPauses.contains(d)};
      indices = {
        for (final i in indices)
          for (final pause in choices) (i + (pause ? 0 : 1)) % length,
      };
    }
    return indices.length == 1 ? indices.single : null;
  }
}

DateTime _next(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Forward/backward finite-state inference over one plan's observations.
///
/// Only [eligibleRestDays] may have paused; the current toggle is not
/// historical proof, so both choices stay open there until the recorded
/// day types decide. The last observed day's own choice is never constrained
/// by evidence and follows [currentPauses]. Callers persist only singleton
/// decisions.
CycleHistory inferCycleHistory(
  CarbCycleSchedule schedule,
  List<CycleObservation> observations,
  Set<DateTime> eligibleRestDays, {
  Set<DateTime> currentPauses = const {},
}) {
  if (observations.isEmpty) return const CycleHistory({}, {});
  final sorted = [...observations]..sort((a, b) => a.date.compareTo(b.date));
  final byDay = {for (final o in sorted) o.date: o};
  final dates = <DateTime>[
    for (var d = sorted.first.date; !d.isAfter(sorted.last.date); d = _next(d))
      d,
  ];
  final length = schedule.cycleLengthDays;

  Set<bool> choices(DateTime d) {
    final recorded = byDay[d]?.paused;
    if (recorded != null) return {recorded};
    if (d == dates.last) return {currentPauses.contains(d)};
    return eligibleRestDays.contains(d) ? {false, true} : {false};
  }

  bool matches(DateTime d, int index) {
    final o = byDay[d];
    return o == null ||
        (schedule.days[index] == o.type &&
            (o.index == null || o.index == index));
  }

  final forward = <Set<int>>[];
  var reachable = {for (var i = 0; i < length; i++) i};
  for (final d in dates) {
    final here = reachable.where((i) => matches(d, i)).toSet();
    if (here.isEmpty) return const CycleHistory({}, {});
    forward.add(here);
    reachable = {
      for (final i in here)
        for (final pause in choices(d)) (i + (pause ? 0 : 1)) % length,
    };
  }

  final positions = <DateTime, Set<int>>{dates.last: forward.last};
  final pauses = <DateTime, Set<bool>>{dates.last: choices(dates.last)};
  var supported = forward.last;
  for (var n = dates.length - 2; n >= 0; n--) {
    final d = dates[n];
    final here = <int>{};
    final possible = <bool>{};
    for (final i in forward[n]) {
      for (final pause in choices(d)) {
        if (supported.contains((i + (pause ? 0 : 1)) % length)) {
          here.add(i);
          possible.add(pause);
        }
      }
    }
    positions[d] = here;
    pauses[d] = possible;
    supported = here;
  }
  // Chronological order for projection and latest-anchor lookup.
  return CycleHistory(
    {for (final d in dates) d: positions[d]!},
    {for (final d in dates) d: pauses[d]!},
  );
}
