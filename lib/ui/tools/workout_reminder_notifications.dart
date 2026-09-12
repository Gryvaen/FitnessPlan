import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/repositories/reminders_repository.dart';
import 'rest_timer_notifications.dart';

/// Daily reminders (workout / water / meal-log / weigh-in) via native
/// AlarmManager (Android) or [FlutterLocalNotificationsPlugin] (iOS / macOS).
///
/// Schedules the next [daysAhead] one-shot notifications per enabled kind so
/// the workout reminder's body can reflect whether the previous day had sets.
abstract final class ReminderNotifications {
  static const _channelDesc = 'Daily reminders';
  static const daysAhead = 7;
  static const _nativeChannel = MethodChannel('fitness_plan/workout_reminder');

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await RestTimerNotifications.ensureInitialized();
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      ),
    );

    // Each reminder's Android channel is created lazily, on first schedule,
    // with the id/sound/vibration baked in from its current settings — see
    // [rescheduleAll] and [_ScheduledReminder.channelId].
    _initialized = true;
  }

  static Future<({bool exact, bool fullScreen})> alarmStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return (exact: true, fullScreen: true);
    }
    try {
      final status = await _nativeChannel.invokeMapMethod<String, Object?>(
        'alarmStatus',
      );
      return (
        exact: status?['exact'] == true,
        fullScreen: status?['fullScreen'] == true,
      );
    } catch (_) {
      return (exact: false, fullScreen: false);
    }
  }

  static Future<bool> requestPermissions() =>
      RestTimerNotifications.requestPermissions();

  static Future<bool> permissionGranted() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// True on a manufacturer skin (ColorOS/MIUI/EMUI/OriginOS/Flyme/…) known
  /// to silently drop or mute scheduled alarms unless the user separately
  /// grants "auto-start" / exempts the app from battery optimization —
  /// neither of which any public API can request outright, only surface a
  /// settings screen for. See [DeviceReliability] on the native side.
  static Future<bool> isAggressiveOem() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _nativeChannel.invokeMethod<bool>('isAggressiveOem') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      return await _nativeChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system dialog to exempt this app from battery optimization.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _nativeChannel.invokeMethod<void>(
        'requestIgnoreBatteryOptimizations',
      );
    } catch (_) {
      // No matching system screen on this build — nothing else to do.
    }
  }

  /// Best-effort deep link into the OEM's own "auto-start" / "allow
  /// background running" screen; falls back to the app's system details
  /// page when the manufacturer's own screen can't be resolved.
  static Future<void> openAutoStartSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _nativeChannel.invokeMethod<void>('openAutoStartSettings');
    } catch (_) {
      // Nothing to fall back to from here.
    }
  }

  static Future<void> cancelAll() async {
    await ensureInitialized();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _nativeChannel.invokeMethod<void>('cancelAll');
      } catch (_) {
        // Fall through to plugin cancel for older installs.
      }
    }
    for (final kind in ReminderKind.values) {
      for (var i = 0; i < daysAhead; i++) {
        await _plugin.cancel(id: kind.idBase + i);
      }
    }
  }

  /// Cancels every reminder and re-schedules the next [daysAhead] days for each
  /// enabled kind. [hasWorkoutOnDay] receives a local calendar day; [titleFor]
  /// / [bodyFor] return localized copy (bodyFor gets `workedOut` for the
  /// workout kind); [channelNameFor] labels the Android notification channel
  /// (e.g. "Workout reminder") so it's recognizable in system settings.
  /// [repository] tracks each kind's last-used channel id so a changed tone
  /// or alert mode — which needs a fresh Android channel, since channels are
  /// immutable once created — can delete the stale one instead of leaving an
  /// orphaned duplicate behind.
  static Future<void> rescheduleAll({
    required Map<ReminderKind, ReminderSetting> settings,
    required Future<bool> Function(DateTime day) hasWorkoutOnDay,
    required String Function(ReminderKind kind) titleFor,
    required String Function(ReminderKind kind) channelNameFor,
    required String Function(ReminderKind kind, {required bool workedOut})
    bodyFor,
    required RemindersRepository repository,
  }) async {
    await ensureInitialized();
    await cancelAll();
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    final now = DateTime.now();
    final items = <_ScheduledReminder>[];
    final staleChannelIds = <String>{};

    for (final entry in settings.entries) {
      final kind = entry.key;
      final s = entry.value;
      if (!s.enabled) continue;

      final channelId = s.channelIdFor(kind);
      final previous = repository.lastChannelId(kind);
      if (previous != null && previous != channelId) {
        staleChannelIds.add(previous);
      }
      await repository.setLastChannelId(kind, channelId);

      var fireDay = DateTime(now.year, now.month, now.day, s.hour, s.minute);
      if (!fireDay.isAfter(now)) {
        fireDay = DateTime(now.year, now.month, now.day + 1, s.hour, s.minute);
      }

      for (var i = 0; i < daysAhead; i++) {
        final whenLocal = DateTime(
          fireDay.year,
          fireDay.month,
          fireDay.day + i,
          s.hour,
          s.minute,
        );
        if (whenLocal.difference(now).inSeconds < 1) continue;
        if (!s.firesOn(whenLocal.weekday)) continue;
        var workedOut = true;
        if (kind == ReminderKind.workout) {
          final prev = DateTime(
            whenLocal.year,
            whenLocal.month,
            whenLocal.day,
          ).subtract(const Duration(days: 1));
          workedOut = await hasWorkoutOnDay(prev);
        }
        items.add(
          _ScheduledReminder(
            id: kind.idBase + i,
            whenLocal: whenLocal,
            title: titleFor(kind),
            body: bodyFor(kind, workedOut: workedOut),
            channelId: channelId,
            channelName: channelNameFor(kind),
            sound: s.alertMode == ReminderAlertMode.ring,
            soundUri: s.soundUri,
          ),
        );
      }
    }
    if (items.isEmpty) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final native = await _scheduleAndroidNative(items, staleChannelIds);
      if (native) return;
      // Native AlarmManager path unavailable — fall back to the plugin.
    }
    await _schedulePlugin(items, now);
  }

  /// Opens the system ringtone picker (the same one the Clock app's alarm
  /// tone picker uses), preselecting [currentUri] when given. Returns null
  /// if the user cancelled, or on a non-Android platform.
  static Future<({String uri, String title})?> pickRingtone({
    String? currentUri,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final result = await _nativeChannel.invokeMapMethod<String, Object?>(
        'pickRingtone',
        {'currentUri': currentUri},
      );
      final uri = result?['uri'] as String?;
      if (uri == null) return null;
      return (uri: uri, title: result?['title'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Returns true when the native AlarmManager path handled the schedule.
  static Future<bool> _scheduleAndroidNative(
    List<_ScheduledReminder> items,
    Set<String> staleChannelIds,
  ) async {
    final payload = [
      for (final item in items)
        {
          'id': item.id,
          'triggerAtMillis': item.whenLocal.millisecondsSinceEpoch,
          'title': item.title,
          'body': item.body,
          'channelId': item.channelId,
          'channelName': item.channelName,
          'sound': item.sound,
          'soundUri': item.soundUri,
        },
    ];
    try {
      await _nativeChannel.invokeMethod<void>('scheduleAll', {
        'items': payload,
        'staleChannelIds': staleChannelIds.toList(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _schedulePlugin(
    List<_ScheduledReminder> items,
    DateTime now,
  ) async {
    final utcNow = tz.TZDateTime.now(tz.UTC);

    for (final item in items) {
      final remaining = item.whenLocal.difference(now);
      if (remaining.inSeconds < 1) continue;
      final when = utcNow.add(remaining);
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          item.channelId,
          item.channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: item.sound,
          sound: item.sound && item.soundUri != null
              ? UriAndroidNotificationSound(item.soundUri!)
              : null,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );
      await _zonedScheduleWithFallback(
        id: item.id,
        title: item.title,
        body: item.body,
        when: when,
        details: details,
      );
    }
  }

  static Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
  }) async {
    const modes = <AndroidScheduleMode>[
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];
    Object? lastError;
    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: mode,
        );
        return;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError;
  }
}

class _ScheduledReminder {
  const _ScheduledReminder({
    required this.id,
    required this.whenLocal,
    required this.title,
    required this.body,
    required this.channelId,
    required this.channelName,
    required this.sound,
    required this.soundUri,
  });

  final int id;
  final DateTime whenLocal;
  final String title;
  final String body;
  final String channelId;
  final String channelName;
  final bool sound;
  final String? soundUri;
}
