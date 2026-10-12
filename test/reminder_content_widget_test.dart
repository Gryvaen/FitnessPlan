import 'package:diet/data/db.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
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

  testWidgets(
    'editor is folded by default, auto-saves, and restores on reentry',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await showPage(tester, prefs);
      expect(find.text('通知内容'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('默认文案'), findsOneWidget);

      await tester.ensureVisible(find.text('通知内容'));
      await tester.tap(find.text('通知内容'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, ' 我的训练 ');
      await tester.pump(const Duration(milliseconds: 400));
      expect(prefs.getString('reminder_workout_customTitle'), isNull);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(prefs.getString('reminder_workout_customTitle'), '我的训练');
      expect(find.text('已自定义'), findsOneWidget);
      expect(scheduledPayloads, isNotEmpty);
      expect(
        scheduledPayloads.last.cast<Map<dynamic, dynamic>>().where(
          (item) => item['title'] == '我的训练',
        ),
        isNotEmpty,
      );
      final count = scheduledPayloads.length;
      await tester.tap(find.text('通知内容'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(scheduledPayloads.length, count);

      await tester.pumpWidget(const SizedBox.shrink());
      await showPage(tester, prefs);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('已自定义'), findsOneWidget);
      await tester.ensureVisible(find.text('通知内容'));
      await tester.tap(find.text('通知内容'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '我的训练',
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'clearing a field restores default copy on blur',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'reminder_workout_enabled': true,
        'reminder_workout_customBody': 'Run today',
      });
      final prefs = await SharedPreferences.getInstance();
      await showPage(tester, prefs);
      await tester.ensureVisible(find.text('通知内容'));
      await tester.tap(find.text('通知内容'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(prefs.getString('reminder_workout_customBody'), isNull);
      expect(find.text('默认文案'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'leaving the page before debounce saves the current draft',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await showPage(tester, prefs);
      await tester.ensureVisible(find.text('通知内容'));
      await tester.tap(find.text('通知内容'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '新标题');
      final pageContext = tester.element(find.byType(RemindersHubPage));
      Navigator.of(pageContext).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      expect(prefs.getString('reminder_workout_customTitle'), '新标题');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'disabling after editing cancels alarms without scheduling more',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await showPage(tester, prefs);
      await tester.ensureVisible(find.text('通知内容'));
      await tester.tap(find.text('通知内容'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '训练一下');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pumpAndSettle();
      final scheduledBeforeDisable = scheduledPayloads.length;
      final cancelledBeforeDisable = cancelCalls;
      await tester.tap(find.text('通知内容'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('训练提醒').first);
      await tester.pumpAndSettle();
      expect(prefs.getBool('reminder_workout_enabled'), false);
      expect(cancelCalls, greaterThan(cancelledBeforeDisable));
      expect(scheduledPayloads.length, scheduledBeforeDisable);
      expect(find.text('通知内容'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'English content editor remains readable on narrow large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final prefs = await SharedPreferences.getInstance();
      await showPage(tester, prefs, locale: const Locale('en'), textScale: 1.5);
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notification text'));
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
