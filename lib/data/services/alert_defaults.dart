import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/reminders_repository.dart';

/// Where the rest timer stores its [RestTimerAlertMode] name.
const kRestTimerAlertModeKey = 'rest_timer_alert_mode';

const _kPinned = 'alert_default_vibrate_v1';

/// Reminders and the rest timer now default to vibrating. Existing installs
/// that never chose keep what they had been hearing (reminders ring, the
/// timer rings and vibrates): once, write those old defaults explicitly.
/// A fresh install writes nothing and gets the new default. Runs at startup,
/// before anything reads these settings.
Future<void> pinLegacyAlertDefaults(SharedPreferences prefs) async {
  if (prefs.getBool(_kPinned) ?? false) return;
  if (prefs.containsKey('user_profile')) {
    for (final kind in ReminderKind.values) {
      final key = RemindersRepository.alertModeKey(kind);
      if (!prefs.containsKey(key)) {
        await prefs.setString(key, ReminderAlertMode.ring.name);
      }
    }
    if (!prefs.containsKey(kRestTimerAlertModeKey)) {
      await prefs.setString(kRestTimerAlertModeKey, 'ringAndVibrate');
    }
  }
  await prefs.setBool(_kPinned, true);
}
