import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/day_marker.dart';
import 'core_providers.dart';

/// Marker (放纵日/休息日/none) for a single local day.
final dayMarkerProvider = StreamProvider.family<DayMarkerType?, DateTime>((
  ref,
  day,
) {
  return ref.watch(dayMarkerRepositoryProvider).watchMarkerForDay(day);
});

final dayMarkerSettingsProvider =
    StreamProvider.family<DayMarkerSettings?, DateTime>((ref, day) {
      return ref.watch(dayMarkerRepositoryProvider).watchSettingsForDay(day);
    });

/// Rest dates eligible and selected to pause the carb cycle. Previews stay
/// live as markers change.
final restDayDatesProvider = StreamProvider<List<DateTime>>((ref) {
  return ref.watch(dayMarkerRepositoryProvider).watchRestDayDates();
});
