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

/// Like a phone alarm: a reminder either rings (plays a tone, [soundUri]
/// null means the system default) or just vibrates.
enum ReminderAlertMode { ring, vibrate }

/// `weekdays` uses DateTime weekday numbers (Mon = 1 … Sun = 7).
class ReminderSetting {
  const ReminderSetting({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.alertMode = ReminderAlertMode.ring,
    this.soundUri,
    this.soundTitle,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final Set<int> weekdays;

  /// Ring (with [soundUri], or the system default when null) or vibrate-only.
  final ReminderAlertMode alertMode;

  /// A content URI picked via the system ringtone picker; null = default
  /// notification sound.
  final String? soundUri;

  /// Display name for [soundUri], captured at pick time so the settings row
  /// doesn't have to resolve the URI itself.
  final String? soundTitle;

  bool firesOn(int weekday) => weekdays.contains(weekday);

  ReminderSetting copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    Set<int>? weekdays,
    ReminderAlertMode? alertMode,
    Object? soundUri = _unset,
    Object? soundTitle = _unset,
  }) => ReminderSetting(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
    alertMode: alertMode ?? this.alertMode,
    soundUri: identical(soundUri, _unset) ? this.soundUri : soundUri as String?,
    soundTitle: identical(soundTitle, _unset)
        ? this.soundTitle
        : soundTitle as String?,
  );
}

const _unset = Object();

extension ReminderChannelId on ReminderSetting {
  /// Deterministic Android notification channel id for this exact alert
  /// configuration. A changed tone or mode naturally produces a different
  /// id, since Android channels can't be edited in place once created.
  String channelIdFor(ReminderKind kind) {
    final soundKey = soundUri == null
        ? 'default'
        : soundUri!.hashCode.toRadixString(36);
    return 'reminder_${kind.name}_${alertMode.name}_$soundKey';
  }
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
    final modeRaw = _prefs.getString(_key(kind, 'alertMode'));
    final mode = ReminderAlertMode.values.firstWhere(
      (m) => m.name == modeRaw,
      orElse: () => ReminderAlertMode.ring,
    );
    return ReminderSetting(
      enabled: _prefs.getBool(_key(kind, 'enabled')) ?? false,
      hour: (_prefs.getInt(_key(kind, 'hour')) ?? t.hour).clamp(0, 23),
      minute: (_prefs.getInt(_key(kind, 'minute')) ?? t.minute).clamp(0, 59),
      weekdays: _parseWeekdays(_prefs.getString(_key(kind, 'weekdays'))),
      alertMode: mode,
      soundUri: _prefs.getString(_key(kind, 'soundUri')),
      soundTitle: _prefs.getString(_key(kind, 'soundTitle')),
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

  Future<void> setAlertMode(ReminderKind kind, ReminderAlertMode mode) =>
      _prefs.setString(_key(kind, 'alertMode'), mode.name);

  /// Pass `uri: null` to reset to the system default notification sound.
  Future<void> setSound(ReminderKind kind, {String? uri, String? title}) async {
    if (uri == null) {
      await _prefs.remove(_key(kind, 'soundUri'));
      await _prefs.remove(_key(kind, 'soundTitle'));
    } else {
      await _prefs.setString(_key(kind, 'soundUri'), uri);
      if (title != null) {
        await _prefs.setString(_key(kind, 'soundTitle'), title);
      } else {
        await _prefs.remove(_key(kind, 'soundTitle'));
      }
    }
  }

  /// The Android notification channel id last used to schedule [kind]'s
  /// alarms. Android channels are immutable once created (sound/vibration
  /// can't be changed in place), so a changed [ReminderSetting] gets a fresh
  /// deterministic channel id — this lets the native side delete the
  /// previous one instead of leaving an orphaned duplicate in system
  /// settings.
  String? lastChannelId(ReminderKind kind) =>
      _prefs.getString(_key(kind, 'lastChannelId'));

  Future<void> setLastChannelId(ReminderKind kind, String channelId) =>
      _prefs.setString(_key(kind, 'lastChannelId'), channelId);

  Future<void> clear() async {
    for (final kind in ReminderKind.values) {
      await _prefs.remove(_key(kind, 'enabled'));
      await _prefs.remove(_key(kind, 'hour'));
      await _prefs.remove(_key(kind, 'minute'));
      await _prefs.remove(_key(kind, 'weekdays'));
      await _prefs.remove(_key(kind, 'alertMode'));
      await _prefs.remove(_key(kind, 'soundUri'));
      await _prefs.remove(_key(kind, 'soundTitle'));
      await _prefs.remove(_key(kind, 'lastChannelId'));
    }
  }
}
