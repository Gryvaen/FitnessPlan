import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/reminders_repository.dart';
import '../l10n/app_localizations.dart';
import '../ui/tools/workout_reminder_notifications.dart';
import 'core_providers.dart';

final remindersProvider =
    NotifierProvider<RemindersNotifier, Map<ReminderKind, ReminderSetting>>(
      RemindersNotifier.new,
    );

class RemindersNotifier extends Notifier<Map<ReminderKind, ReminderSetting>> {
  @override
  Map<ReminderKind, ReminderSetting> build() {
    return ref.read(remindersRepositoryProvider).loadAll();
  }

  ReminderSetting settingFor(ReminderKind kind) =>
      state[kind] ??
      ReminderSetting(
        enabled: false,
        hour: kind.defaultTime.hour,
        minute: kind.defaultTime.minute,
        weekdays: const {1, 2, 3, 4, 5, 6, 7},
      );

  Future<void> _apply(
    ReminderKind kind,
    ReminderSetting next,
    Future<void> Function() persist,
  ) async {
    await persist();
    state = {...state, kind: next};
    // Scheduling is best-effort: an OS-side failure (no permission, no exact
    // alarm, a platform without notifications) must not undo the user's choice.
    try {
      await syncSchedule();
    } catch (e) {
      debugPrint('reminder sync failed: $e');
    }
  }

  Future<void> setEnabled(ReminderKind kind, bool enabled) => _apply(
    kind,
    settingFor(kind).copyWith(enabled: enabled),
    () => ref.read(remindersRepositoryProvider).setEnabled(kind, enabled),
  );

  Future<void> setTime(
    ReminderKind kind, {
    required int hour,
    required int minute,
  }) => _apply(
    kind,
    settingFor(kind).copyWith(hour: hour, minute: minute),
    () => ref
        .read(remindersRepositoryProvider)
        .setTime(kind, hour: hour, minute: minute),
  );

  Future<void> setWeekdays(ReminderKind kind, Set<int> weekdays) => _apply(
    kind,
    settingFor(kind).copyWith(weekdays: weekdays),
    () => ref.read(remindersRepositoryProvider).setWeekdays(kind, weekdays),
  );

  /// Recompute and schedule the next days for every enabled reminder kind.
  Future<void> syncSchedule([AppLocalizations? l10n]) async {
    final loc = l10n ?? _platformL10n();
    final workoutRepo = ref.read(workoutRepositoryProvider);
    await ReminderNotifications.rescheduleAll(
      settings: state,
      hasWorkoutOnDay: workoutRepo.hasAnySetOn,
      titleFor: (kind) => switch (kind) {
        ReminderKind.workout => loc.workoutReminderTitle,
        ReminderKind.water => loc.reminderWaterTitle,
        ReminderKind.meal => loc.reminderMealTitle,
        ReminderKind.weighIn => loc.reminderWeighInTitle,
      },
      bodyFor: (kind, {required workedOut}) => switch (kind) {
        ReminderKind.workout =>
          workedOut
              ? loc.workoutReminderBodyNormal
              : loc.workoutReminderBodyEncourage,
        ReminderKind.water => loc.reminderWaterBody,
        ReminderKind.meal => loc.reminderMealBody,
        ReminderKind.weighIn => loc.reminderWeighInBody,
      },
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
