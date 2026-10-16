import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/tools/rest_timer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/src/platform_flutter_local_notifications.dart'
    show MethodChannelFlutterLocalNotificationsPlugin;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const alarm = MethodChannel('fitness_plan/rest_timer_alarm');
  const reminder = MethodChannel('fitness_plan/workout_reminder');
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final alarmCalls = <MethodCall>[];
  final notificationCalls = <MethodCall>[];
  var notificationGranted = true;
  var exactGranted = true;
  var scheduleFails = false;
  var aggressiveOem = false;
  int? lastDelayMs;
  final reminderCalls = <String>[];

  setUp(() {
    FlutterLocalNotificationsPlatform.instance =
        MethodChannelFlutterLocalNotificationsPlugin();
    SharedPreferences.setMockInitialValues({});
    alarmCalls.clear();
    notificationCalls.clear();
    notificationGranted = true;
    exactGranted = true;
    scheduleFails = false;
    aggressiveOem = false;
    lastDelayMs = null;
    reminderCalls.clear();
    messenger.setMockMethodCallHandler(reminder, (call) async {
      reminderCalls.add(call.method);
      if (call.method == 'isAggressiveOem') return aggressiveOem;
      if (call.method == 'openAutoStartSettings') return 'battery';
      return null;
    });
    messenger.setMockMethodCallHandler(alarm, (call) async {
      alarmCalls.add(call);
      if (call.method == 'canScheduleExactAlarms') return exactGranted;
      if (call.method == 'takeLastDelayMs') {
        final delay = lastDelayMs;
        lastDelayMs = null;
        return delay;
      }
      if (call.method == 'schedule' && scheduleFails) {
        throw PlatformException(code: 'schedule_failed');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'checkPermissionStatus') {
        return notificationGranted ? 1 : 0;
      }
      if (call.method == 'requestPermissions') {
        return <int, int>{
          for (final id in call.arguments as List<dynamic>)
            id as int: id == 17 && !notificationGranted ? 0 : 1,
        };
      }
      return null;
    });
    messenger.setMockMethodCallHandler(notifications, (call) async {
      notificationCalls.add(call);
      if (call.method == 'initialize' ||
          call.method == 'requestExactAlarmsPermission' ||
          call.method == 'requestFullScreenIntentPermission') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(alarm, null);
    messenger.setMockMethodCallHandler(reminder, null);
    messenger.setMockMethodCallHandler(permissions, null);
    messenger.setMockMethodCallHandler(notifications, null);
  });

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> showPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RestTimerPage(),
      ),
    );
    await flush(tester);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Alert settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Badge settingsBadge(WidgetTester tester) => tester.widget<Badge>(
    find.descendant(
      of: find.byKey(const ValueKey('rest-timer-settings')),
      matching: find.byType(Badge),
    ),
  );

  Future<void> expandIssue(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<void> chooseMode(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await flush(tester);
  }

  testWidgets(
    'start, pause, resume, and reset manage one Android alarm',
    (tester) async {
      await showPage(tester);
      await tester.tap(find.text('Start'));
      await flush(tester);
      expect(find.text('Resting'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('rest_timer_deadline_ms'), isNotNull);
      expect(find.textContaining('Could not schedule'), findsNothing);
      final scheduled = alarmCalls
          .where((c) => c.method == 'schedule')
          .toList();
      expect(
        scheduled,
        hasLength(1),
        reason:
            '${alarmCalls.map((c) => c.method).toList()} / ${notificationCalls.map((c) => c.method).toList()}',
      );
      final trigger =
          (scheduled.single.arguments as Map)['triggerAtMillis'] as int;
      expect((scheduled.single.arguments as Map)['soundEnabled'], isTrue);
      expect((scheduled.single.arguments as Map)['vibrationEnabled'], isTrue);
      expect(prefs.getInt('rest_timer_deadline_ms'), trigger);

      await tester.tap(find.text('Pause'));
      await flush(tester);
      expect(find.text('Paused'), findsOneWidget);
      expect(prefs.getInt('rest_timer_deadline_ms'), isNull);
      expect(alarmCalls.where((c) => c.method == 'cancel'), isNotEmpty);

      await tester.tap(find.text('Resume'));
      await flush(tester);
      expect(alarmCalls.where((c) => c.method == 'schedule'), hasLength(2));

      await tester.tap(find.text('Reset'));
      await flush(tester);
      expect(find.text('01:30'), findsOneWidget);
      expect(prefs.getInt('rest_timer_deadline_ms'), isNull);
      expect(alarmCalls.last.method, 'cancel');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'alert mode persists and re-arms an active timer at the same deadline',
    (tester) async {
      await showPage(tester);
      await tester.tap(find.text('Start'));
      await flush(tester);
      final initial = alarmCalls.where((c) => c.method == 'schedule').single;
      final deadline = (initial.arguments as Map)['triggerAtMillis'];

      await openSettings(tester);
      await chooseMode(tester, 'Vibrate only');
      final afterVibrate = alarmCalls.where((c) => c.method == 'schedule').last;
      expect((afterVibrate.arguments as Map)['triggerAtMillis'], deadline);
      expect((afterVibrate.arguments as Map)['soundEnabled'], isFalse);
      expect((afterVibrate.arguments as Map)['vibrationEnabled'], isTrue);
      expect(alarmCalls.where((c) => c.method == 'schedule'), hasLength(2));

      await openSettings(tester);
      final selected = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Vibrate only'),
          matching: find.byType(ListTile),
        ),
      );
      expect(selected.trailing, isNotNull);
      await chooseMode(tester, 'Ring only');
      final afterRing = alarmCalls.where((c) => c.method == 'schedule').last;
      expect((afterRing.arguments as Map)['triggerAtMillis'], deadline);
      expect((afterRing.arguments as Map)['soundEnabled'], isTrue);
      expect((afterRing.arguments as Map)['vibrationEnabled'], isFalse);
      expect(alarmCalls.where((c) => c.method == 'schedule'), hasLength(3));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('rest_timer_alert_mode'), 'ringOnly');

      await tester.pumpWidget(const SizedBox.shrink());
      await showPage(tester);
      await openSettings(tester);
      final restored = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Ring only'),
          matching: find.byType(ListTile),
        ),
      );
      expect(restored.trailing, isNotNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'failed re-arm keeps the original deadline and shows an alert warning',
    (tester) async {
      await showPage(tester);
      await tester.tap(find.text('Start'));
      await flush(tester);
      final prefs = await SharedPreferences.getInstance();
      final deadline = prefs.getInt('rest_timer_deadline_ms');
      scheduleFails = true;
      await openSettings(tester);
      await chooseMode(tester, 'Vibrate only');
      expect(prefs.getInt('rest_timer_deadline_ms'), deadline);
      expect(settingsBadge(tester).isLabelVisible, isTrue);
      await openSettings(tester);
      await expandIssue(tester, 'Some reminders were not scheduled');
      expect(find.textContaining('Could not schedule'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Resting'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'changing mode while paused applies when resumed',
    (tester) async {
      await showPage(tester);
      await tester.tap(find.text('Start'));
      await flush(tester);
      await tester.tap(find.text('Pause'));
      await flush(tester);
      final before = alarmCalls.where((c) => c.method == 'schedule').length;
      await openSettings(tester);
      await chooseMode(tester, 'Ring only');
      expect(
        alarmCalls.where((c) => c.method == 'schedule'),
        hasLength(before),
      );
      await tester.tap(find.text('Resume'));
      await flush(tester);
      final resumed = alarmCalls.where((c) => c.method == 'schedule').last;
      expect((resumed.arguments as Map)['soundEnabled'], isTrue);
      expect((resumed.arguments as Map)['vibrationEnabled'], isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'expired timer stays complete after page reentry',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'rest_timer_selected_seconds': 60,
        'rest_timer_deadline_ms': DateTime.now()
            .subtract(const Duration(seconds: 2))
            .millisecondsSinceEpoch,
      });
      await showPage(tester);
      expect(find.text('Rest complete'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rest_timer_finished'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await showPage(tester);
      expect(find.text('Rest complete'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'denied permissions and scheduling failure are listed in settings',
    (tester) async {
      notificationGranted = false;
      exactGranted = false;
      scheduleFails = true;
      await showPage(tester);
      // Nothing crowds the timer itself; the settings icon carries a dot.
      expect(find.textContaining('Allow notifications'), findsNothing);
      expect(settingsBadge(tester).isLabelVisible, isTrue);
      await openSettings(tester);
      // Rows show title and action only; details unfold on tap.
      expect(find.textContaining('Allow notifications'), findsNothing);
      await expandIssue(tester, 'Notification permission');
      await expandIssue(tester, 'Exact alarms');
      expect(find.textContaining('Allow notifications'), findsOneWidget);
      expect(find.textContaining('reliable on-time alerts'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // Dismiss the sheet.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await flush(tester);
      expect(find.text('Resting'), findsOneWidget);
      await openSettings(tester);
      await expandIssue(tester, 'Some reminders were not scheduled');
      expect(find.textContaining('Could not schedule'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'no dot or permission rows when alerts are fully allowed',
    (tester) async {
      await showPage(tester);
      expect(settingsBadge(tester).isLabelVisible, isFalse);
      await openSettings(tester);
      expect(find.text('Reminder permissions'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'aggressive OEM lists the background issue until settings are opened',
    (tester) async {
      aggressiveOem = true;
      await showPage(tester);
      expect(settingsBadge(tester).isLabelVisible, isTrue);

      await tester.tap(find.text('Start'));
      await flush(tester);
      expect(
        find.text('Alerts may be delayed while you use other apps'),
        findsOneWidget,
      );
      final scheduled = alarmCalls.where((c) => c.method == 'schedule').last;
      expect((scheduled.arguments as Map)['countdownTitle'], 'Resting');

      await openSettings(tester);
      expect(find.text('May be late in background'), findsOneWidget);
      await tester.tap(find.text('Settings').last);
      await flush(tester);
      expect(reminderCalls, contains('openAutoStartSettings'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rest_timer_background_ack'), isTrue);
      expect(settingsBadge(tester).isLabelVisible, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a delayed alarm is reported and re-arms the background issue',
    (tester) async {
      aggressiveOem = true;
      SharedPreferences.setMockInitialValues({
        'rest_timer_background_ack': true,
      });
      lastDelayMs = 90000;
      await showPage(tester);
      expect(
        find.text('Your last rest alert was delayed 90s by the system'),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rest_timer_background_ack'), isFalse);
      expect(settingsBadge(tester).isLabelVisible, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
