import 'package:diet/ui/tools/workout_reminder_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fitness_plan/workout_reminder');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'exact alarm and full-screen permissions are checked separately',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'alarmStatus');
        return {'exact': false, 'fullScreen': true};
      });
      expect(await ReminderNotifications.alarmStatus(), (
        exact: false,
        fullScreen: true,
      ));
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'exact': true, 'fullScreen': false},
      );
      expect(await ReminderNotifications.alarmStatus(), (
        exact: true,
        fullScreen: false,
      ));
    },
  );

  test(
    'native check failure must not claim alarm permissions are granted',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      expect(await ReminderNotifications.alarmStatus(), (
        exact: false,
        fullScreen: false,
      ));
    },
  );

  test(
    'schedule status reports partial failure and unavailable bridge',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'scheduleStatus');
        return {'scheduled': 3, 'failed': 1};
      });
      expect(await ReminderNotifications.scheduleStatus(), (
        scheduled: 3,
        failed: 1,
      ));
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      expect(await ReminderNotifications.scheduleStatus(), isNull);
    },
  );

  test(
    'auto-start settings reports the opened page and propagates errors',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'openAutoStartSettings');
        return 'oem';
      });
      expect(
        await ReminderNotifications.openAutoStartSettings(),
        AutoStartSettingsDestination.oem,
      );
      messenger.setMockMethodCallHandler(channel, (_) async => 'appDetails');
      expect(
        await ReminderNotifications.openAutoStartSettings(),
        AutoStartSettingsDestination.appDetails,
      );
      messenger.setMockMethodCallHandler(channel, (_) async => 'battery');
      expect(
        await ReminderNotifications.openAutoStartSettings(),
        AutoStartSettingsDestination.battery,
      );
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'settings_unavailable'),
      );
      await expectLater(
        ReminderNotifications.openAutoStartSettings(),
        throwsA(isA<PlatformException>()),
      );
    },
  );
}
