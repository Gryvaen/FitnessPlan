import 'package:diet/data/db.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/ink/ink_icon.dart';
import 'package:diet/ui/tools/reminders_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const reminderChannel = MethodChannel('fitness_plan/workout_reminder');
  const localChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const permissionsChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final scheduledPayloads = <List<dynamic>>[];
  var cancelCalls = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({'reminder_workout_enabled': true});
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    scheduledPayloads.clear();
    cancelCalls = 0;
    messenger.setMockMethodCallHandler(localChannel, (call) async {
      if (call.method == 'initialize') return true;
      return null;
    });
    messenger.setMockMethodCallHandler(permissionsChannel, (call) async {
      if (call.method == 'checkPermissionStatus') return 1;
      return null;
    });
    messenger.setMockMethodCallHandler(reminderChannel, (call) async {
      switch (call.method) {
        case 'alarmStatus':
          return {'exact': true, 'fullScreen': true};
        case 'scheduleStatus':
          return {'scheduled': 1, 'failed': 0};
        case 'isAggressiveOem':
          return false;
        case 'isBackgroundRestricted':
          return false;
        case 'isIgnoringBatteryOptimizations':
          return true;
        case 'scheduleAll':
          final args = Map<Object?, Object?>.from(call.arguments as Map);
          final items = List<dynamic>.from(args['items'] as List);
          scheduledPayloads.add(items);
          return {'scheduled': items.length, 'failed': 0};
        case 'cancelAll':
          cancelCalls++;
          return null;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(localChannel, null);
    messenger.setMockMethodCallHandler(permissionsChannel, null);
    messenger.setMockMethodCallHandler(reminderChannel, null);
  });

  Future<void> showPage(
    WidgetTester tester,
    SharedPreferences prefs, {
    Locale locale = const Locale('zh'),
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) {
            final db = AppDatabase.forTesting(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const RemindersHubPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final gear = find.byKey(const ValueKey('reminders-settings'));
  Finder contentRow(String kind) =>
      find.byKey(ValueKey('reminder-content-$kind'));

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(gear);
    await tester.pumpAndSettle();
  }

  Future<void> openContent(WidgetTester tester, String kind) async {
    await tester.ensureVisible(contentRow(kind));
    await tester.tap(contentRow(kind));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'reminder rows keep only time and repeat; the rest lives in settings',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await showPage(tester, prefs);
      expect(find.text('提醒时间'), findsOneWidget);
      expect(find.text('响铃'), findsNothing);
      expect(find.text('铃声'), findsNothing);
      expect(find.text('通知内容'), findsNothing);
      await openSettings(tester);
      expect(find.text('响铃'), findsOneWidget);
      expect(find.text('振动'), findsOneWidget);
      expect(find.text('铃声'), findsNothing); // vibrate by default
      expect(find.text('通知内容'), findsOneWidget);
      expect(find.text('默认文案'), findsNWidgets(4));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('content is edited in a dialog, saved, and restored on reentry', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await showPage(tester, prefs);
    await openSettings(tester);
    await openContent(tester, 'workout');
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(
      find.byKey(const ValueKey('reminder-content-title')),
      ' 我的训练 ',
    );
    await tester.tap(find.byKey(const ValueKey('reminder-content-save')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(prefs.getString('reminder_workout_customTitle'), '我的训练');
    expect(find.text('已自定义'), findsOneWidget);
    expect(
      scheduledPayloads.last.cast<Map<dynamic, dynamic>>().where(
        (item) => item['title'] == '我的训练',
      ),
      isNotEmpty,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await showPage(tester, prefs);
    await openSettings(tester);
    expect(find.text('已自定义'), findsOneWidget);
    await openContent(tester, 'workout');
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('reminder-content-title')),
          )
          .controller!
          .text,
      '我的训练',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('cancelling the dialog keeps the saved content', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await showPage(tester, prefs);
    await openSettings(tester);
    await openContent(tester, 'water');
    await tester.enterText(
      find.byKey(const ValueKey('reminder-content-body')),
      '多喝水',
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(prefs.getString('reminder_water_customBody'), isNull);
    expect(find.text('默认文案'), findsNWidgets(4));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('clearing a field restores default copy', (tester) async {
    SharedPreferences.setMockInitialValues({
      'reminder_workout_enabled': true,
      'reminder_workout_customBody': 'Run today',
    });
    final prefs = await SharedPreferences.getInstance();
    await showPage(tester, prefs);
    await openSettings(tester);
    expect(find.text('已自定义'), findsOneWidget);
    await openContent(tester, 'workout');
    await tester.enterText(
      find.byKey(const ValueKey('reminder-content-body')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('reminder-content-save')));
    await tester.pumpAndSettle();
    expect(prefs.getString('reminder_workout_customBody'), isNull);
    expect(find.text('默认文案'), findsNWidgets(4));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('ring or vibrate applies to every reminder with one reschedule', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await showPage(tester, prefs);
    await openSettings(tester);
    // A fresh install vibrates, so there is no tone row yet.
    Finder checkOn(String mode) => find.descendant(
      of: find.byKey(ValueKey('reminder-alert-$mode')),
      matching: find.byType(InkIcon),
    );
    expect(checkOn('vibrate'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('reminder-sound')), findsNothing);
    final before = scheduledPayloads.length;
    await tester.tap(find.byKey(const ValueKey('reminder-alert-ring')));
    await tester.pumpAndSettle();
    for (final kind in ['workout', 'water', 'meal', 'weighIn']) {
      expect(prefs.getString('reminder_${kind}_alertMode'), 'ring');
    }
    expect(scheduledPayloads.length, before + 1);
    expect(checkOn('ring'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('reminder-sound')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminder-alert-vibrate')));
    await tester.pumpAndSettle();
    expect(prefs.getString('reminder_meal_alertMode'), 'vibrate');
    expect(find.byKey(const ValueKey('reminder-sound')), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'disabling after editing cancels alarms without scheduling more',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await showPage(tester, prefs);
      await openSettings(tester);
      await openContent(tester, 'workout');
      await tester.enterText(
        find.byKey(const ValueKey('reminder-content-body')),
        '训练一下',
      );
      await tester.tap(find.byKey(const ValueKey('reminder-content-save')));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      final scheduledBeforeDisable = scheduledPayloads.length;
      final cancelledBeforeDisable = cancelCalls;
      await tester.tap(find.text('训练提醒').first);
      await tester.pumpAndSettle();
      expect(prefs.getBool('reminder_workout_enabled'), false);
      expect(cancelCalls, greaterThan(cancelledBeforeDisable));
      expect(scheduledPayloads.length, scheduledBeforeDisable);
      expect(prefs.getString('reminder_workout_customBody'), '训练一下');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('English content dialog remains readable on narrow large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final prefs = await SharedPreferences.getInstance();
    await showPage(tester, prefs, locale: const Locale('en'), textScale: 1.5);
    await openSettings(tester);
    expect(find.text('Notification text'), findsOneWidget);
    await openContent(tester, 'workout');
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
