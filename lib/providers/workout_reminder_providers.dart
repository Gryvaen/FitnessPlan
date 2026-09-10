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
      );

  Future<void> setEnabled(ReminderKind kind, bool enabled) async {
    final previous = state;
    await ref.read(remindersRepositoryProvider).setEnabled(kind, enabled);
    state = {...state, kind: settingFor(kind).copyWith(enabled: enabled)};
    try {
      await syncSchedule();
    } catch (e) {
      await ref
          .read(remindersRepositoryProvider)
          .setEnabled(kind, previous[kind]?.enabled ?? false);
      state = previous;
      rethrow;
    }
  }

  Future<void> setTime(
    ReminderKind kind, {
    required int hour,
    required int minute,
  }) async {
    final previous = state;
    await ref
        .read(remindersRepositoryProvider)
        .setTime(kind, hour: hour, minute: minute);
    state = {
      ...state,
      kind: settingFor(kind).copyWith(hour: hour, minute: minute),
    };
    try {
      await syncSchedule();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

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
