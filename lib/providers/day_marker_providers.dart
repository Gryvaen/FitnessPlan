import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/day_marker.dart';
import 'core_providers.dart';

/// Marker (放纵餐/休息日/none) for a single local day.
final dayMarkerProvider = StreamProvider.family<DayMarkerType?, DateTime>((
  ref,
  day,
) {
  return ref.watch(dayMarkerRepositoryProvider).watchMarkerForDay(day);
});

/// Every date currently marked as 休息日. Drives the carb-cycle day-count
/// shift so previews stay live as markers change.
final restDayDatesProvider = StreamProvider<List<DateTime>>((ref) {
  return ref.watch(dayMarkerRepositoryProvider).watchRestDayDates();
});
