import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calendar_day.dart';
import 'goal_schedule_providers.dart';
import 'meal_providers.dart';
import 'step_providers.dart';

/// The app's notion of "today" (local calendar day). Providers that are
/// about today watch it, so they recompute when the day rolls over while
/// the app stays open (see [dayRolloverProvider]).
final currentDayProvider = NotifierProvider<CurrentDayNotifier, DateTime>(
  CurrentDayNotifier.new,
);

class CurrentDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => CalendarDay.todayLocal();

  /// Moves to the current calendar day. Returns the previous day when it
  /// changed, null otherwise.
  DateTime? refresh({DateTime? now}) {
    final today = CalendarDay.todayLocal(now);
    if (today == state) return null;
    final previous = state;
    state = today;
    return previous;
  }
}

/// Day rollover, run by the shell at local midnight and on resume:
/// - moves "today" on, and the Today page with it when it was showing the
///   old today (a deliberately picked earlier day stays put);
/// - re-syncs steps, which start over each day;
/// - carries out a goal switch booked for the new day.
///
/// Returns whether the day changed.
final dayRolloverProvider = Provider<Future<bool> Function({DateTime? now})>(
  (ref) => ({DateTime? now}) async {
    final previous = ref.read(currentDayProvider.notifier).refresh(now: now);
    if (previous != null) {
      final selected = ref.read(selectedDayProvider.notifier);
      if (ref.read(selectedDayProvider) == previous) {
        selected.setDay(CalendarDay.todayLocal(now));
      }
      ref.invalidate(stepsSyncProvider);
    }
    await applyDueGoalSwitch(ref, today: now);
    return previous != null;
  },
);

/// Time until just after the next local midnight (a second past it, so the
/// clock reads the new day when the timer fires).
Duration untilNextDay({DateTime? now}) {
  final t = now ?? DateTime.now();
  final next = DateTime(t.year, t.month, t.day + 1);
  return next.difference(t) + const Duration(seconds: 1);
}
