import 'package:shared_preferences/shared_preferences.dart';

/// Whether to nudge the user to allow auto-start / background activity.
///
/// ColorOS and similar skins block alarms and kill the step service unless
/// the user flips these in system settings, and no API reports whether they
/// did. Tapping the settings shortcut counts as done; a reminder that is
/// later found missed resets it so the nudge comes back. Reminders and the
/// steps service share one flag because it is one system setting.
abstract final class OemBackgroundGuide {
  static const ackKey = 'oem_background_ack';

  static bool acknowledged(SharedPreferences prefs) =>
      prefs.getBool(ackKey) ?? false;

  static Future<void> acknowledge(SharedPreferences prefs) =>
      prefs.setBool(ackKey, true);

  static Future<void> reset(SharedPreferences prefs) => prefs.remove(ackKey);
}
