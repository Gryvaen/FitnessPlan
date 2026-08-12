import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/workout_reminder_repository.dart';
import '../l10n/app_localizations.dart';
import '../ui/tools/workout_reminder_notifications.dart';
import 'core_providers.dart';

final workoutReminderProvider =
    NotifierProvider<WorkoutReminderNotifier, WorkoutReminderSettings>(
  WorkoutReminderNotifier.new,
);

class WorkoutReminderNotifier extends Notifier<WorkoutReminderSettings> {
  @override
  WorkoutReminderSettings build() {
    return ref.read(workoutReminderRepositoryProvider).load();
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(workoutReminderRepositoryProvider).setEnabled(enabled);
    state = state.copyWith(enabled: enabled);
    await syncSchedule();
  }

  Future<void> setTime({required int hour, required int minute}) async {
    await ref
        .read(workoutReminderRepositoryProvider)
        .setTime(hour: hour, minute: minute);
    state = state.copyWith(hour: hour, minute: minute);
    await syncSchedule();
  }

  /// Recompute and schedule the next 7 daily reminders from current prefs + DB.
  Future<void> syncSchedule([AppLocalizations? l10n]) async {
    final settings = state;
    final loc = l10n ?? _platformL10n();
    final workoutRepo = ref.read(workoutRepositoryProvider);
    await WorkoutReminderNotifications.reschedule(
      enabled: settings.enabled,
      hour: settings.hour,
      minute: settings.minute,
      hasWorkoutOnDay: workoutRepo.hasAnySetOn,
      title: loc.workoutReminderTitle,
      bodyNormal: loc.workoutReminderBodyNormal,
      bodyEncourage: loc.workoutReminderBodyEncourage,
    );
  }

  static AppLocalizations _platformL10n() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }
}
