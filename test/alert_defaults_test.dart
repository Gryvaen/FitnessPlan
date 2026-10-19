import 'package:diet/data/repositories/reminders_repository.dart';
import 'package:diet/data/services/alert_defaults.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('an existing install keeps the old ring defaults', () async {
    final prefs = await prefsWith({
      'user_profile': '{}',
      'reminder_water_alertMode': 'vibrate',
    });
    await pinLegacyAlertDefaults(prefs);
    expect(prefs.getString('reminder_workout_alertMode'), 'ring');
    expect(prefs.getString('reminder_meal_alertMode'), 'ring');
    expect(prefs.getString('reminder_water_alertMode'), 'vibrate');
    expect(prefs.getString(kRestTimerAlertModeKey), 'ringAndVibrate');
  });

  test('an explicit timer choice is left alone', () async {
    final prefs = await prefsWith({
      'user_profile': '{}',
      kRestTimerAlertModeKey: 'ringOnly',
    });
    await pinLegacyAlertDefaults(prefs);
    expect(prefs.getString(kRestTimerAlertModeKey), 'ringOnly');
  });

  test('a fresh install writes nothing and vibrates', () async {
    final prefs = await prefsWith({});
    await pinLegacyAlertDefaults(prefs);
    expect(prefs.getString('reminder_workout_alertMode'), isNull);
    expect(prefs.getString(kRestTimerAlertModeKey), isNull);
    expect(
      RemindersRepository(prefs).get(ReminderKind.workout).alertMode,
      ReminderAlertMode.vibrate,
    );
  });

  test('runs only once', () async {
    final prefs = await prefsWith({});
    await pinLegacyAlertDefaults(prefs);
    // The profile created during onboarding must not pin the old defaults.
    await prefs.setString('user_profile', '{}');
    await pinLegacyAlertDefaults(prefs);
    expect(prefs.getString('reminder_workout_alertMode'), isNull);
    expect(prefs.getString(kRestTimerAlertModeKey), isNull);
  });
}
