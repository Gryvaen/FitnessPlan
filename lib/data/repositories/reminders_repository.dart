import 'package:shared_preferences/shared_preferences.dart';

/// The reminder types the app can schedule. Each gets its own on/off, time and
/// repeat-days, plus a distinct notification-id range (100 slots).
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

/// `weekdays` uses DateTime weekday numbers (Mon = 1 … Sun = 7).
class ReminderSetting {
  const ReminderSetting({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.weekdays,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final Set<int> weekdays;

  bool firesOn(int weekday) => weekdays.contains(weekday);

  ReminderSetting copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    Set<int>? weekdays,
  }) => ReminderSetting(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
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

  Set<int> _parseWeekdays(String? raw) {
    if (raw == null || raw.isEmpty) return {1, 2, 3, 4, 5, 6, 7};
    final out = <int>{};
    for (final c in raw.split(',')) {
      final n = int.tryParse(c.trim());
      if (n != null && n >= 1 && n <= 7) out.add(n);
    }
    return out.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : out;
  }

  ReminderSetting get(ReminderKind kind) {
    final t = kind.defaultTime;
    return ReminderSetting(
      enabled: _prefs.getBool(_key(kind, 'enabled')) ?? false,
      hour: (_prefs.getInt(_key(kind, 'hour')) ?? t.hour).clamp(0, 23),
      minute: (_prefs.getInt(_key(kind, 'minute')) ?? t.minute).clamp(0, 59),
      weekdays: _parseWeekdays(_prefs.getString(_key(kind, 'weekdays'))),
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

  Future<void> setWeekdays(ReminderKind kind, Set<int> weekdays) async {
    final valid = weekdays.where((d) => d >= 1 && d <= 7).toList()..sort();
    await _prefs.setString(_key(kind, 'weekdays'), valid.join(','));
  }

  Future<void> clear() async {
    for (final kind in ReminderKind.values) {
      await _prefs.remove(_key(kind, 'enabled'));
      await _prefs.remove(_key(kind, 'hour'));
      await _prefs.remove(_key(kind, 'minute'));
      await _prefs.remove(_key(kind, 'weekdays'));
    }
  }
}
