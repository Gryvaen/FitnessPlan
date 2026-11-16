import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/day_marker.dart';
import 'core_providers.dart';

/// Marker (放纵日/休息日/冲碳日/none) for a single local day. Auto-disposed:
/// paging the Today page back a year would otherwise keep one DB watcher
/// per day visited until the process ends.
final dayMarkerProvider = StreamProvider.autoDispose
    .family<DayMarkerType?, DateTime>((ref, day) {
      return ref.watch(dayMarkerRepositoryProvider).watchMarkerForDay(day);
    });

final dayMarkerSettingsProvider = StreamProvider.autoDispose
    .family<DayMarkerSettings?, DateTime>((ref, day) {
      return ref.watch(dayMarkerRepositoryProvider).watchSettingsForDay(day);
    });

/// Marker settings from today on, for carb-cycle previews (paused-row labels
/// and 冲碳日 macros).
final upcomingDayMarkersProvider =
    StreamProvider<Map<DateTime, DayMarkerSettings>>((ref) {
      return ref.watch(dayMarkerRepositoryProvider).watchUpcomingSettings();
    });

/// Marker dates (any type) eligible and selected to pause the carb cycle.
/// Previews stay live as markers change.
final restDayDatesProvider = StreamProvider<List<DateTime>>((ref) {
  return ref.watch(dayMarkerRepositoryProvider).watchRestDayDates();
});
