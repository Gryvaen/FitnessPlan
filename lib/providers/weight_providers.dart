import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../data/repositories/day_marker_repository.dart';
import '../data/repositories/weight_repository.dart';
import '../domain/calendar_day.dart';
import '../domain/cut_round_stats.dart';
import '../domain/day_marker.dart';
import 'core_providers.dart';

final weightLogsProvider = StreamProvider<List<WeightLog>>((ref) {
  return ref.watch(weightRepositoryProvider).watchAll();
});

Set<DateTime> _cheatDaysOf(Map<DateTime, DayMarkerType> markers) => {
  for (final e in markers.entries)
    if (e.value == DayMarkerType.cheatMeal) CalendarDay.dayOnly(e.key),
};

/// Whether a weigh-in on [day] falls on a 放纵日 or within
/// [cheatWeightWindowDays] days after one, so it must not drive the profile.
Future<bool> weighInSkewedByCheatDay(
  DayMarkerRepository markers,
  DateTime day,
) async {
  final d = CalendarDay.dayOnly(day);
  final window = await markers.markersBetween(
    CalendarDay.addDays(d, -cheatWeightWindowDays),
    d,
  );
  return isWithinCheatWindow(d, _cheatDaysOf(window));
}

/// Newest weigh-in the profile may follow: the latest one not skewed by a
/// 放纵日 (see [weighInSkewedByCheatDay]); null when none qualifies.
Future<WeightLog?> latestProfileWeighIn(
  WeightRepository weights,
  DayMarkerRepository markers,
) async {
  final newest = await weights.latest();
  if (newest == null) return null;
  final end = CalendarDay.dayOnly(newest.date);
  final logs = await weights.logsBetween(DateTime(1970), end);
  if (logs.isEmpty) return null;
  final cheat = _cheatDaysOf(
    await markers.markersBetween(
      CalendarDay.addDays(
        CalendarDay.dayOnly(logs.first.date),
        -cheatWeightWindowDays,
      ),
      end,
    ),
  );
  for (final log in logs.reversed) {
    if (!isWithinCheatWindow(log.date, cheat)) return log;
  }
  return null;
}
