import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'rest_timer_notifications.dart';

/// Daily workout reminder via native AlarmManager (Android) or
/// [FlutterLocalNotificationsPlugin] (iOS / macOS).
///
/// Schedules the next [daysAhead] one-shot notifications (not a repeating
/// alarm) so each day's body can reflect whether the previous day had sets.
abstract final class WorkoutReminderNotifications {
  static const _channelId = 'workout_reminder_v2';
  static const _channelName = 'Workout reminder';
  static const _channelDesc = 'Daily reminders to train';
  static const _baseNotificationId = 72001;
  static const daysAhead = 7;
  static const _nativeChannel = MethodChannel('fitness_plan/workout_reminder');

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    // Rest timer may already have initialized timezones + plugin; safe to
    // call again for this plugin instance and create our channel.
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
        // Required by the plugin when running the desktop build on Linux.
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
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
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  /// Requests notification permission (reuses rest-timer permission flow).
  static Future<bool> requestPermissions() =>
      RestTimerNotifications.requestPermissions();

  static Future<void> cancelAll() async {
    await ensureInitialized();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _nativeChannel.invokeMethod<void>('cancelAll');
      } catch (_) {
        // Fall through to plugin cancel for older installs.
      }
    }
    for (var i = 0; i < daysAhead; i++) {
      await _plugin.cancel(id: _baseNotificationId + i);
    }
  }

  /// Cancels existing reminders and schedules the next [daysAhead] days.
  ///
  /// [hasWorkoutOnDay] receives a local calendar day and returns whether any
  /// set was logged that day. [title], [bodyNormal], [bodyEncourage] are
  /// localized by the caller.
  static Future<void> reschedule({
    required bool enabled,
    required int hour,
    required int minute,
    required Future<bool> Function(DateTime day) hasWorkoutOnDay,
    required String title,
    required String bodyNormal,
    required String bodyEncourage,
  }) async {
    await ensureInitialized();
    await cancelAll();
    if (!enabled) return;
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    final now = DateTime.now();
    var fireDay = DateTime(now.year, now.month, now.day, hour, minute);
    if (!fireDay.isAfter(now)) {
      fireDay = fireDay.add(const Duration(days: 1));
    }

    final items = <_ScheduledReminder>[];
    for (var i = 0; i < daysAhead; i++) {
      final whenLocal = fireDay.add(Duration(days: i));
      final previousDay = DateTime(
        whenLocal.year,
        whenLocal.month,
        whenLocal.day,
      ).subtract(const Duration(days: 1));
      final workedOut = await hasWorkoutOnDay(previousDay);
      final body = workedOut ? bodyNormal : bodyEncourage;
      final remaining = whenLocal.difference(now);
      if (remaining.inSeconds < 1) continue;
      items.add(
        _ScheduledReminder(
          id: _baseNotificationId + i,
          whenLocal: whenLocal,
          title: title,
          body: body,
        ),
      );
    }
    if (items.isEmpty) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _scheduleAndroidNative(items);
      return;
    }

    await _schedulePlugin(items, now);
  }

  static Future<void> _scheduleAndroidNative(
    List<_ScheduledReminder> items,
  ) async {
    final payload = [
      for (final item in items)
        {
          'id': item.id,
          'triggerAtMillis': item.whenLocal.millisecondsSinceEpoch,
          'title': item.title,
          'body': item.body,
        },
    ];
    await _nativeChannel.invokeMethod<void>('scheduleAll', {'items': payload});
  }

  static Future<void> _schedulePlugin(
    List<_ScheduledReminder> items,
    DateTime now,
  ) async {
    final utcNow = tz.TZDateTime.now(tz.UTC);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
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

    for (final item in items) {
      final remaining = item.whenLocal.difference(now);
      if (remaining.inSeconds < 1) continue;
      final when = utcNow.add(remaining);
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
    if (lastError != null) {
      throw lastError;
    }
  }
}

class _ScheduledReminder {
  const _ScheduledReminder({
    required this.id,
    required this.whenLocal,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime whenLocal;
  final String title;
  final String body;
}
