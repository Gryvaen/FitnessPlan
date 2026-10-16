import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

enum RestTimerAlertMode {
  ringAndVibrate,
  ringOnly,
  vibrateOnly;

  bool get soundEnabled => this != RestTimerAlertMode.vibrateOnly;
  bool get vibrationEnabled => this != RestTimerAlertMode.ringOnly;
}

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for rest-timer alerts.
abstract final class RestTimerNotifications {
  // Channel settings are immutable on Android. Keep a versioned id so users
  // upgrading from the old one-shot channel receive alarm-level behavior.
  static const _channelId = 'rest_timer_alarm_v2';

  /// English channel name for system settings (not re-localized easily).
  static const _channelName = 'Rest timer';
  static const _channelDesc = 'Between-set rest alerts';
  static const notificationId = 71001;
  static const _dismissActionId = 'dismiss_rest_timer';
  static const _darwinCategoryId = 'rest_timer_alarm';
  static const _nativeAlarmChannel = MethodChannel(
    'fitness_plan/rest_timer_alarm',
  );

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _darwinCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(_dismissActionId, 'Close / 关闭'),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        // Required by the plugin when running the desktop build on Linux.
        linux: const LinuxInitializationSettings(defaultActionName: 'Open'),
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  /// Requests notification (+ exact alarm on Android). Returns whether
  /// notifications are likely allowed.
  static Future<bool> requestPermissions() async {
    await ensureInitialized();
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final notifStatus = await Permission.notification.request();
      try {
        await Permission.scheduleExactAlarm.request();
      } catch (_) {
        // Permission screens vary by device; the native scheduler still tries.
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      try {
        await android?.requestExactAlarmsPermission();
        await android?.requestFullScreenIntentPermission();
      } catch (_) {
        // Missing settings activities must not stop the foreground countdown.
      }
      return notifStatus.isGranted || notifStatus.isLimited;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }

    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null) {
      return await mac.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  static Future<({bool notifications, bool exact})> alarmStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return (notifications: true, exact: true);
    }
    bool notifications;
    try {
      final status = await Permission.notification.status;
      notifications = status.isGranted || status.isLimited;
    } catch (_) {
      notifications = false;
    }
    bool exact;
    try {
      exact =
          await _nativeAlarmChannel.invokeMethod<bool>(
            'canScheduleExactAlarms',
          ) ??
          false;
    } catch (_) {
      exact = false;
    }
    return (notifications: notifications, exact: exact);
  }

  /// Schedules a rest-end alert. Pass localized [title]/[body] from the UI.
  static Future<void> scheduleRestEnd(
    DateTime endsAt, {
    required String title,
    required String body,
    required String dismissLabel,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required String countdownTitle,
  }) async {
    final remaining = endsAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      throw StateError('Rest timer deadline has already passed');
    }

    await cancel();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _nativeAlarmChannel.invokeMethod<void>('schedule', {
        'triggerAtMillis': endsAt.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'dismissLabel': dismissLabel,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'countdownTitle': countdownTitle,
      });
      return;
    }

    await ensureInitialized();
    final when = tz.TZDateTime.now(tz.UTC).add(remaining);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: true,
        additionalFlags: Int32List.fromList(const <int>[4]),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _dismissActionId,
            dismissLabel,
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        categoryIdentifier: _darwinCategoryId,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        categoryIdentifier: _darwinCategoryId,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// How late the last Android alert arrived when the system held it back
  /// (e.g. ColorOS freezing the app in the background). Read once: the
  /// native side clears it. Null when nothing was delayed.
  static Future<Duration?> takeLastAlarmDelay() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final ms = await _nativeAlarmChannel.invokeMethod<int>('takeLastDelayMs');
      return ms == null ? null : Duration(milliseconds: ms);
    } catch (_) {
      return null;
    }
  }

  static Future<void> cancel() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _nativeAlarmChannel.invokeMethod<void>('cancel');
    }
    try {
      await ensureInitialized();
      await _plugin.cancel(id: notificationId);
    } catch (_) {
      // The old plugin notification is best-effort cleanup on Android.
      if (defaultTargetPlatform != TargetPlatform.android) rethrow;
    }
  }
}
