import 'package:diet/data/repositories/reminders_repository.dart';
import 'package:diet/ui/tools/workout_reminder_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const reminderChannel = MethodChannel('fitness_plan/workout_reminder');
  const localChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(localChannel, (call) async {
      if (call.method == 'initialize') return true;
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(reminderChannel, null);
    messenger.setMockMethodCallHandler(localChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'each reminder stores its own title and body; clearing restores defaults',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = RemindersRepository(prefs);
      for (final kind in ReminderKind.values) {
        await repository.setNotificationContent(
          kind,
          title: ' ${kind.name} title ',
          body: ' ${kind.name} body ',
        );
      }
      final restored = RemindersRepository(prefs).loadAll();
      for (final kind in ReminderKind.values) {
        expect(restored[kind]!.customTitle, '${kind.name} title');
        expect(restored[kind]!.customBody, '${kind.name} body');
      }

      await repository.setNotificationContent(
        ReminderKind.workout,
        title: '  ',
        body: 'Custom training body',
      );
      final workout = RemindersRepository(prefs).get(ReminderKind.workout);
      expect(
        workout.notificationTitle('Default workout title'),
        'Default workout title',
      );
      expect(workout.notificationBody('Normal body'), 'Custom training body');
      expect(
        workout.notificationBody('Encouragement body'),
        'Custom training body',
      );

      await repository.setNotificationContent(ReminderKind.workout, body: '  ');
      final reset = RemindersRepository(prefs).get(ReminderKind.workout);
      expect(reset.notificationBody('Normal body'), 'Normal body');
      expect(
        reset.notificationBody('Encouragement body'),
        'Encouragement body',
      );
      expect(
        RemindersRepository(prefs).get(ReminderKind.water).customTitle,
        'water title',
      );
    },
  );

  test(
    'Android alarm payload uses custom text and default text per field',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = RemindersRepository(prefs);
      final payloads = <List<dynamic>>[];
      messenger.setMockMethodCallHandler(reminderChannel, (call) async {
        if (call.method == 'scheduleAll') {
          final args = Map<Object?, Object?>.from(call.arguments as Map);
          final items = List<dynamic>.from(args['items'] as List);
          payloads.add(items);
          return {'scheduled': items.length, 'failed': 0};
        }
        return null;
      });
      final settings = {
        for (final kind in ReminderKind.values)
          kind: ReminderSetting(
            enabled: true,
            hour: kind.defaultTime.hour,
            minute: kind.defaultTime.minute,
            weekdays: const {1, 2, 3, 4, 5, 6, 7},
            customTitle: kind == ReminderKind.water ? 'Drink now' : null,
            customBody: kind == ReminderKind.workout ? 'Go train' : null,
          ),
      };
      Future<void> schedule(bool workedOut) =>
          ReminderNotifications.rescheduleAll(
            settings: settings,
            hasWorkoutOnDay: (_) async => workedOut,
            titleFor: (kind) => 'Default ${kind.name} title',
            bodyFor: (kind, {required workedOut}) =>
                kind == ReminderKind.workout
                ? (workedOut ? 'Normal training' : 'Encourage training')
                : 'Default ${kind.name} body',
            channelNameFor: (kind) => kind.name,
            repository: repository,
          );

      await schedule(false);
      final first = payloads.last.cast<Map<dynamic, dynamic>>();
      expect(first.where((item) => item['title'] == 'Drink now'), isNotEmpty);
      expect(first.where((item) => item['body'] == 'Go train'), isNotEmpty);
      expect(
        first.where((item) => item['title'] == 'Default meal title'),
        isNotEmpty,
      );

      settings[ReminderKind.workout] = settings[ReminderKind.workout]!.copyWith(
        customBody: null,
      );
      await schedule(false);
      expect(
        payloads.last.cast<Map<dynamic, dynamic>>().where(
          (item) => item['body'] == 'Encourage training',
        ),
        isNotEmpty,
      );
    },
  );
}
