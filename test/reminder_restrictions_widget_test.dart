import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/tools/reminders_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const reminderChannel = MethodChannel('fitness_plan/workout_reminder');
  const permissionsChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  var notificationAllowed = true;
  var exactAllowed = true;
  var fullScreenAllowed = true;
  var aggressiveOem = false;
  bool? backgroundRestricted = false;
  var scheduled = 1;
  var failed = 0;
  var statusUnknown = false;
  var notificationRequests = 0;
  var autoStartResult = 'battery';
  var autoStartFails = false;
  var autoStartCalls = 0;
  var batteryStatusReads = 0;
  var batteryOptimizationRequests = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({'reminder_workout_enabled': true});
    notificationAllowed = true;
    exactAllowed = true;
    fullScreenAllowed = true;
    aggressiveOem = false;
    backgroundRestricted = false;
    scheduled = 1;
    failed = 0;
    statusUnknown = false;
    notificationRequests = 0;
    autoStartResult = 'battery';
    autoStartFails = false;
    autoStartCalls = 0;
    batteryStatusReads = 0;
    batteryOptimizationRequests = 0;
    messenger.setMockMethodCallHandler(permissionsChannel, (call) async {
      if (call.method == 'checkPermissionStatus') {
        return notificationAllowed ? 1 : 0;
      }
      if (call.method == 'requestPermissions') {
        notificationRequests++;
        return <int, int>{17: notificationAllowed ? 1 : 0};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(reminderChannel, (call) async {
      switch (call.method) {
        case 'alarmStatus':
          return {'exact': exactAllowed, 'fullScreen': fullScreenAllowed};
        case 'scheduleStatus':
          return statusUnknown
              ? null
              : {'scheduled': scheduled, 'failed': failed};
        case 'isAggressiveOem':
          return aggressiveOem;
        case 'isBackgroundRestricted':
          return backgroundRestricted;
        case 'isIgnoringBatteryOptimizations':
          batteryStatusReads++;
          return false;
        case 'requestIgnoreBatteryOptimizations':
          batteryOptimizationRequests++;
          return true;
        case 'openAutoStartSettings':
          autoStartCalls++;
          if (autoStartFails) {
            throw PlatformException(code: 'settings_unavailable');
          }
          return autoStartResult;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(reminderChannel, null);
    messenger.setMockMethodCallHandler(permissionsChannel, null);
  });

  Future<void> showPage(
    WidgetTester tester, {
    Locale locale = const Locale('zh'),
    double textScale = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
    'notification denied is a single actionable issue',
    (tester) async {
      notificationAllowed = false;
      await showPage(tester);
      expect(find.text('提醒可能收不到'), findsOneWidget);
      expect(find.text('1 项待检查'), findsOneWidget);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      // The detail is folded until the row is tapped.
      expect(find.text('通知已关闭，到点时可能无法显示提醒。'), findsNothing);
      await tester.tap(find.text('通知权限'));
      await tester.pumpAndSettle();
      expect(find.text('通知已关闭，到点时可能无法显示提醒。'), findsOneWidget);
      expect(find.text('去开启'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'multiple limits are listed separately in a scrolling sheet',
    (tester) async {
      exactAllowed = false;
      fullScreenAllowed = false;
      failed = 1;
      aggressiveOem = true;
      backgroundRestricted = true;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await showPage(tester, locale: const Locale('en'), textScale: 1.5);
      expect(find.text('Reminders may not arrive'), findsOneWidget);
      expect(find.text('4 to check'), findsOneWidget);
      await tester.tap(find.text('Reminders may not arrive'));
      await tester.pumpAndSettle();
      expect(find.text('Exact alarms'), findsOneWidget);
      expect(find.text('Lock screen alerts'), findsOneWidget);
      expect(find.text('Some reminders were not scheduled'), findsOneWidget);
      expect(find.text('Background activity is restricted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'unknown scheduling is distinct from failed scheduling',
    (tester) async {
      statusUnknown = true;
      await showPage(tester);
      expect(find.text('提醒可能收不到'), findsOneWidget);
      expect(find.text('1 项待检查'), findsOneWidget);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      expect(find.text('尚未确认排程结果'), findsOneWidget);
      expect(find.text('部分提醒安排失败'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'normal scheduling shows no restriction summary',
    (tester) async {
      await showPage(tester);
      expect(find.text('已安排 1 个提醒'), findsOneWidget);
      expect(find.textContaining('项待检查'), findsNothing);
      expect(find.text('训练提醒'), findsWidgets);
      expect(find.text('喝水提醒'), findsWidgets);
      expect(find.text('饮食记录'), findsWidgets);
      expect(find.text('体重提醒'), findsWidgets);
      await tester.tap(find.text('已安排 1 个提醒'));
      await tester.pumpAndSettle();
      expect(find.text('已向系统安排 1 个提醒；实际送达仍受设备设置影响。'), findsOneWidget);
      await tester.tapAt(const Offset(20, 300));
      await tester.pumpAndSettle();
      expect(find.text('已向系统安排 1 个提醒；实际送达仍受设备设置影响。'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'all reminders off and healthy shows only the four reminder rows',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await showPage(tester);
      expect(find.text('已安排 1 个提醒'), findsNothing);
      expect(find.textContaining('项待检查'), findsNothing);
      expect(find.text('训练提醒'), findsWidgets);
      expect(find.text('喝水提醒'), findsWidgets);
      expect(find.text('饮食记录'), findsWidgets);
      expect(find.text('体重提醒'), findsWidgets);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'exact alarm alone has the softer summary',
    (tester) async {
      exactAllowed = false;
      await showPage(tester);
      expect(find.text('提醒可能延迟或不在锁屏弹出'), findsOneWidget);
      expect(find.text('1 项待检查'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'notification action requests only notification access',
    (tester) async {
      notificationAllowed = false;
      await showPage(tester);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('去开启'));
      await tester.pumpAndSettle();
      expect(notificationRequests, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'brand and missing battery exemption alone are not pending issues',
    (tester) async {
      aggressiveOem = true;
      await showPage(tester);
      expect(find.textContaining('项待检查'), findsNothing);
      expect(find.text('已安排 1 个提醒'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'unknown background state is not a pending issue',
    (tester) async {
      aggressiveOem = true;
      backgroundRestricted = null;
      await showPage(tester);
      expect(find.textContaining('项待检查'), findsNothing);
      expect(find.text('已安排 1 个提醒'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'confirmed restriction clears after returning from settings',
    (tester) async {
      aggressiveOem = true;
      backgroundRestricted = true;
      await showPage(tester);
      expect(find.text('提醒可能收不到'), findsOneWidget);
      expect(find.text('1 项待检查'), findsOneWidget);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      expect(find.text('系统已限制后台运行'), findsOneWidget);
      await tester.tap(find.text('系统已限制后台运行'));
      await tester.pumpAndSettle();
      expect(find.textContaining('系统报告本应用受到后台限制'), findsOneWidget);
      await tester.tapAt(const Offset(20, 300));
      await tester.pumpAndSettle();
      backgroundRestricted = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.textContaining('项待检查'), findsNothing);
      expect(find.text('已安排 1 个提醒'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'confirmed restriction keeps unrelated permission issue visible',
    (tester) async {
      aggressiveOem = true;
      backgroundRestricted = true;
      notificationAllowed = false;
      await showPage(tester);
      expect(find.text('2 项待检查'), findsOneWidget);
      backgroundRestricted = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('1 项待检查'), findsOneWidget);
      expect(find.text('提醒可能收不到'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'battery settings fallback shows the real setting',
    (tester) async {
      aggressiveOem = true;
      backgroundRestricted = true;
      await showPage(tester);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      final button = find.text('去设置');
      expect(button, findsOneWidget);
      expect(find.text('关闭电池优化'), findsNothing);
      expect(batteryStatusReads, 0);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(autoStartCalls, 1);
      expect(batteryOptimizationRequests, 0);
      expect(find.text('请查看「允许后台使用」；如果已经开启，无需更改。'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('请查看「允许后台使用」；如果已经开启，无需更改。'), findsOneWidget);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      expect(find.text('请查看「允许后台使用」；如果已经开启，无需更改。'), findsWidgets);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'OEM settings uses the single background settings action',
    (tester) async {
      backgroundRestricted = true;
      autoStartResult = 'oem';
      await showPage(tester);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      expect(find.text('去设置'), findsOneWidget);
      expect(find.text('关闭电池优化'), findsNothing);
      await tester.tap(find.text('去设置'));
      await tester.pumpAndSettle();
      expect(autoStartCalls, 1);
      expect(batteryStatusReads, 0);
      expect(batteryOptimizationRequests, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'app details fallback explains where to check background usage',
    (tester) async {
      backgroundRestricted = true;
      autoStartResult = 'appDetails';
      await showPage(tester);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('去设置'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.textContaining('已打开应用信息'), findsOneWidget);
      expect(autoStartCalls, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'auto-start failure shows manual settings path',
    (tester) async {
      aggressiveOem = true;
      backgroundRestricted = true;
      autoStartFails = true;
      await showPage(tester);
      await tester.tap(find.text('提醒可能收不到'));
      await tester.pumpAndSettle();
      final button = find.text('去设置');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('应用的电池使用情况'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
