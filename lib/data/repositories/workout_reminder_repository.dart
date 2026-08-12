import 'package:shared_preferences/shared_preferences.dart';

const _enabledKey = 'workout_reminder_enabled';
const _hourKey = 'workout_reminder_hour';
const _minuteKey = 'workout_reminder_minute';

const kDefaultWorkoutReminderHour = 8;
const kDefaultWorkoutReminderMinute = 0;

class WorkoutReminderSettings {
  const WorkoutReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  WorkoutReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return WorkoutReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class WorkoutReminderRepository {
  WorkoutReminderRepository(this._prefs);

  final SharedPreferences _prefs;

  WorkoutReminderSettings load() {
    return WorkoutReminderSettings(
      enabled: _prefs.getBool(_enabledKey) ?? false,
      hour: (_prefs.getInt(_hourKey) ?? kDefaultWorkoutReminderHour).clamp(
        0,
        23,
      ),
      minute: (_prefs.getInt(_minuteKey) ?? kDefaultWorkoutReminderMinute)
          .clamp(0, 59),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_enabledKey, enabled);
  }

  Future<void> setTime({required int hour, required int minute}) async {
    await _prefs.setInt(_hourKey, hour.clamp(0, 23));
    await _prefs.setInt(_minuteKey, minute.clamp(0, 59));
  }

  Future<void> save(WorkoutReminderSettings settings) async {
    await setEnabled(settings.enabled);
    await setTime(hour: settings.hour, minute: settings.minute);
  }
}
