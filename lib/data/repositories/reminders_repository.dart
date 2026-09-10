import 'package:shared_preferences/shared_preferences.dart';

/// The reminder types the app can schedule. Each gets its own on/off + time
/// and a distinct notification-id range (100 slots) so they never collide.
enum ReminderKind { workout, water, meal, weighIn }

extension ReminderKindMeta on ReminderKind {
  int get idBase => switch (this) {
    ReminderKind.workout => 72001,
    ReminderKind.water => 72101,
    ReminderKind.meal => 72201,
    ReminderKind.weighIn => 72301,
  };

  ({int hour, int minute}) get defaultTime => switch (this) {
    ReminderKind.workout => (hour: 18, minute: 0),
    ReminderKind.water => (hour: 10, minute: 0),
    ReminderKind.meal => (hour: 20, minute: 0),
    ReminderKind.weighIn => (hour: 7, minute: 30),
  };
}

class ReminderSetting {
  const ReminderSetting({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSetting copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSetting(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

class RemindersRepository {
  RemindersRepository(this._prefs) {
    _migrateLegacyWorkoutKeys();
  }

  final SharedPreferences _prefs;

  String _key(ReminderKind kind, String field) =>
      'reminder_${kind.name}_$field';

  /// v2.0.x stored the single workout reminder under `workout_reminder_*`.
  void _migrateLegacyWorkoutKeys() {
    const legacyEnabled = 'workout_reminder_enabled';
    if (!_prefs.containsKey(legacyEnabled)) return;
    final target = _key(ReminderKind.workout, 'enabled');
    if (_prefs.containsKey(target)) return;
    _prefs.setBool(target, _prefs.getBool(legacyEnabled) ?? false);
    final h = _prefs.getInt('workout_reminder_hour');
    final m = _prefs.getInt('workout_reminder_minute');
    if (h != null) _prefs.setInt(_key(ReminderKind.workout, 'hour'), h);
    if (m != null) _prefs.setInt(_key(ReminderKind.workout, 'minute'), m);
  }

  ReminderSetting get(ReminderKind kind) {
    final t = kind.defaultTime;
    return ReminderSetting(
      enabled: _prefs.getBool(_key(kind, 'enabled')) ?? false,
      hour: (_prefs.getInt(_key(kind, 'hour')) ?? t.hour).clamp(0, 23),
      minute: (_prefs.getInt(_key(kind, 'minute')) ?? t.minute).clamp(0, 59),
    );
  }

  Map<ReminderKind, ReminderSetting> loadAll() => {
    for (final kind in ReminderKind.values) kind: get(kind),
  };

  Future<void> setEnabled(ReminderKind kind, bool enabled) =>
      _prefs.setBool(_key(kind, 'enabled'), enabled);

  Future<void> setTime(
    ReminderKind kind, {
    required int hour,
    required int minute,
  }) async {
    await _prefs.setInt(_key(kind, 'hour'), hour.clamp(0, 23));
    await _prefs.setInt(_key(kind, 'minute'), minute.clamp(0, 59));
  }

  Future<void> clear() async {
    for (final kind in ReminderKind.values) {
      await _prefs.remove(_key(kind, 'enabled'));
      await _prefs.remove(_key(kind, 'hour'));
      await _prefs.remove(_key(kind, 'minute'));
    }
  }
}
