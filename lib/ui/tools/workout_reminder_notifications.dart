import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'rest_timer_notifications.dart';

/// Daily workout reminder via [FlutterLocalNotificationsPlugin].
///
/// Schedules the next [daysAhead] one-shot notifications (not a repeating
/// alarm) so each day's body can reflect whether the previous day had sets.
abstract final class WorkoutReminderNotifications {
  static const _channelId = 'workout_reminder_v1';
  static const _channelName = 'Workout reminder';
  static const _channelDesc = 'Daily reminders to train';
  static const _baseNotificationId = 72001;
  static const daysAhead = 7;

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
        importance: Importance.defaultImportance,
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
    final utcNow = tz.TZDateTime.now(tz.UTC);
    var fireDay = DateTime(now.year, now.month, now.day, hour, minute);
    if (!fireDay.isAfter(now)) {
      fireDay = fireDay.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
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
      final when = utcNow.add(remaining);

      try {
        await _plugin.zonedSchedule(
          id: _baseNotificationId + i,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          id: _baseNotificationId + i,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }
}
