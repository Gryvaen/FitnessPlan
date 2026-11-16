@Tags(['implementation_preview'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:diet/app.dart';
import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _profile() => UserProfile(
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 75,
  activity: ActivityLevel.moderate,
  goal: FitnessGoal.cut,
  targets: const MacroTargets(
    calories: 2000,
    proteinG: 150,
    carbG: 215,
    fatG: 60,
  ),
  targetWeightKg: 70,
  bmr: 1700,
  tdee: 2400,
  dailyDeficit: 400,
  calorieStandardSince: DateTime(2026, 1, 1),
);

class _Harness {
  _Harness(this.db, this.container);

  final AppDatabase db;
  final ProviderContainer container;
}

Future<_Harness> _harness({AppThemeId theme = AppThemeId.fresh}) async {
  SharedPreferences.setMockInitialValues({
    'user_profile': jsonEncode(_profile().toJson()),
    'app_theme_id': theme.name,
    'water_goal_ml': 2000,
  });
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      foodsSeedProvider.overrideWith((ref) async {}),
    ],
  );
  return _Harness(db, container);
}

class _PreviewApp extends ConsumerWidget {
  const _PreviewApp({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeId = ref.watch(themeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: AppTheme.ofId(themeId),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: true, boldText: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

Future<void> _seedDemo(_Harness h) async {
  final today = CalendarDay.todayLocal();
  final repo = h.container.read(dietStrategyRepositoryProvider);
  await repo.createPlan(
    DietStrategyPlanDraft(
      kind: DietStrategyKind.carbCycle,
      effectiveFrom: today,
      referenceWeightKg: 75,
      estimatedTdee: 2400,
      baseEnergy: 2000,
      schedule: CarbCycleSchedule.tryParse('HMLL'),
      carbCycleRates: CarbCycleRates.defaults(),
      reason: 'preview',
    ),
  );
  await h.db
      .into(h.db.foodItems)
      .insert(
        FoodItemsCompanion.insert(
          name: 'Chicken breast',
          category: '肉类',
          kcalPer100: 133,
          proteinPer100: 31,
          carbPer100: 0,
          fatPer100: 1.2,
        ),
      );
  await h.db
      .into(h.db.foodItems)
      .insert(
        FoodItemsCompanion.insert(
          name: 'Oatmeal',
          category: '主食',
          kcalPer100: 377,
          proteinPer100: 13,
          carbPer100: 67,
          fatPer100: 7,
        ),
      );
  await h.db
      .into(h.db.mealEntries)
      .insert(
        MealEntriesCompanion.insert(
          date: today,
          mealType: MealType.lunch.name,
          foodId: 1,
          foodName: 'Chicken breast',
          grams: 200,
          calories: 266,
          proteinG: 62,
          carbG: 0,
          fatG: 2.4,
        ),
      );
  await h.db
      .into(h.db.mealEntries)
      .insert(
        MealEntriesCompanion.insert(
          date: today,
          mealType: MealType.breakfast.name,
          foodId: 2,
          foodName: 'Oatmeal',
          grams: 226.5,
          calories: 854,
          proteinG: 29.4,
          carbG: 151.8,
          fatG: 15.9,
        ),
      );
  await h.container.read(waterRepositoryProvider).setMlForDay(today, 1250);
  await h.db
      .into(h.db.weightLogs)
      .insert(WeightLogsCompanion.insert(date: today, weightKg: 75));
}

Future<void> _pump(
  WidgetTester tester,
  _Harness h, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: _PreviewApp(locale: locale),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _go(WidgetTester tester, _Harness h, String location) async {
  h.container.read(routerProvider).go(location);
  await tester.pump(const Duration(milliseconds: 400));
  // Let drift streams for the new route deliver before the shot.
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _shot(WidgetTester tester, String file) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../design-handoff/implementation-preview/$file'),
  );
}

Future<void> _scrollPage(WidgetTester tester) async {
  final lists = find.byType(ListView);
  final n = tester.widgetList(lists).length;
  if (n == 0) return;
  await tester.drag(lists.at(n - 1), const Offset(0, -320));
  await tester.pump(const Duration(milliseconds: 400));
}

void _mockPlugins() {
  const packageInfo = MethodChannel('dev.fluttercommunity.plus/package_info');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(packageInfo, (call) async {
        if (call.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'FitnessPlan',
            'packageName': 'com.fitnessplan.fitness_plan',
            'version': '2.0.11',
            'buildNumber': '26',
          };
        }
        return null;
      });
}

/// Loads the app's bundled fonts so screenshots show real Chinese glyphs
/// instead of the test font's boxes (font-size review needs the real face).
Future<void> _loadAppFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  final wenKai = FontLoader(AppTheme.bodyFontFamily)
    ..addFont(bytes('assets/fonts/LXGWWenKaiLite-Medium.ttf'));
  final noto = FontLoader('NotoSansSC')
    ..addFont(bytes('assets/fonts/NotoSansSC-Variable.ttf'));
  await Future.wait([wenKai.load(), noto.load()]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Harness h;

  setUpAll(_loadAppFonts);

  setUp(() async {
    _mockPlugins();
    h = await _harness();
    await _seedDemo(h);
  });

  tearDown(() async {
    h.container.dispose();
    await h.db.close();
  });

  testWidgets('english core screens', (tester) async {
    await _pump(tester, h);

    await _shot(tester, 'en-01-today.png');

    // The header now uses ink glyphs; skip the picker shot if the old
    // Material calendar icon isn't there instead of aborting the run.
    final calendar = find.byIcon(Icons.calendar_today_outlined);
    if (calendar.evaluate().isNotEmpty) {
      await tester.tap(calendar.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _shot(tester, 'en-04-date-picker.png');
      if (find.text('Cancel').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    await _scrollPage(tester);
    await _shot(tester, 'en-01b-today-bottom.png');

    h.container
        .read(selectedDayProvider.notifier)
        .setDay(CalendarDay.addDays(CalendarDay.todayLocal(), -1));
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'en-03-today-yesterday-history.png');

    h.container.read(selectedDayProvider.notifier).goToToday();
    await tester.pump(const Duration(milliseconds: 400));

    await _go(tester, h, '/log-meal');
    await _shot(tester, 'en-05-log-meal-flow.png');

    await _go(tester, h, '/profile/nutrition');
    await _shot(tester, 'en-06-nutrition-targets.png');
    await _scrollPage(tester);
    await _shot(tester, 'en-06b-nutrition-targets-bottom.png');

    await _go(tester, h, '/profile/nutrition/strategy');
    await _shot(tester, 'en-07-strategy-picker.png');

    await _go(
      tester,
      h,
      '/profile/nutrition/strategy/configure?kind=carbCycle',
    );
    await _shot(tester, 'en-08-carb-cycle-configure.png');
    await _scrollPage(tester);
    await _shot(tester, 'en-08b-carb-cycle-configure-bottom.png');

    await _go(
      tester,
      h,
      '/profile/nutrition/strategy/configure?kind=carbTaper',
    );
    await _shot(tester, 'en-09-carb-taper-configure.png');
    await _scrollPage(tester);
    await _shot(tester, 'en-09b-carb-taper-configure-bottom.png');

    await _go(tester, h, '/profile');
    await _shot(tester, 'en-10-profile.png');

    await _go(tester, h, '/profile/theme');
    await _shot(tester, 'en-11-theme-page.png');

    await _go(tester, h, '/foods');
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'en-13-foods.png');

    await _go(tester, h, '/records');
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'en-14-records.png');

    await _go(tester, h, '/profile/tools');
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'en-15-tools.png');
  });

  testWidgets('four themes on today', (tester) async {
    await _pump(tester, h);
    for (final id in AppThemeId.presets) {
      await h.container.read(themeProvider.notifier).select(id);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: const _PreviewApp(locale: Locale('en')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await _shot(tester, 'en-12-today-theme-${id.name}.png');
    }
  });

  testWidgets('chinese maintain strategy path', (tester) async {
    // While cutting, the 维持 tab walks the cut tab's path: no strategy →
    // picker (one default) → configure page.
    await _pump(tester, h, locale: const Locale('zh'));
    await _go(tester, h, '/profile/nutrition');
    await tester.tap(find.text('维持').first);
    // Let the tab pager finish sliding before the shot.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await _shot(tester, 'zh-10a-maintain-empty.png');
    await _go(tester, h, '/profile/nutrition/maintain');
    await _shot(tester, 'zh-10c-maintain-picker.png');
    await _go(tester, h, '/profile/nutrition/maintain/configure');
    await _shot(tester, 'zh-10d-maintain-configure.png');
    await tester.tap(find.byKey(const ValueKey('maintain-section-target')));
    // Let the fold's size animation finish.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _shot(tester, 'zh-10e-maintain-configure-rates.png');
    await _go(tester, h, '/profile/nutrition/strategy');
    await _shot(tester, 'zh-05-strategy-picker.png');
    await _go(tester, h, '/profile/nutrition/strategy/configure?kind=balanced');
    await _shot(tester, 'zh-06-strategy-configure-balanced.png');
  });

  testWidgets('chinese maintain tab', (tester) async {
    // Put the profile on the 维持 goal before the app starts (a direct
    // repository write; the goal-switch flow isn't what this shot is about).
    await tester.runAsync(() async {
      final repo = h.container.read(profileRepositoryProvider);
      final cut = repo.load()!;
      await repo.saveFromInputs(
        sex: cut.sex,
        age: cut.age,
        heightCm: cut.heightCm,
        weightKg: cut.weightKg,
        activity: cut.activity,
        goal: FitnessGoal.maintain,
      );
      for (final (daysAgo, kg) in [
        (9, 70.6),
        (5, 69.4),
        (2, 68.6),
        (0, 68.2),
      ]) {
        await h.db
            .into(h.db.weightLogs)
            .insert(
              WeightLogsCompanion.insert(
                date: CalendarDay.addDays(CalendarDay.todayLocal(), -daysAgo),
                weightKg: kg,
              ),
            );
      }
    });
    h.container.read(profileProvider.notifier).reload();
    await _pump(tester, h, locale: const Locale('zh'));
    await _go(tester, h, '/profile/nutrition');
    await _shot(tester, 'zh-10-maintain.png');
    await _scrollPage(tester);
    await _shot(tester, 'zh-10b-maintain-bottom.png');
  });

  testWidgets('chinese core screens', (tester) async {
    await _pump(tester, h, locale: const Locale('zh'));

    await _shot(tester, 'zh-01-today.png');
    await _scrollPage(tester);
    await _shot(tester, 'zh-01b-today-bottom.png');

    h.container
        .read(selectedDayProvider.notifier)
        .setDay(CalendarDay.addDays(CalendarDay.todayLocal(), -1));
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'zh-03-today-yesterday-history.png');

    h.container.read(selectedDayProvider.notifier).goToToday();
    await tester.pump(const Duration(milliseconds: 300));

    await _go(tester, h, '/profile/nutrition');
    await _shot(tester, 'zh-04-nutrition-targets.png');
    await _scrollPage(tester);
    await _shot(tester, 'zh-04b-nutrition-targets-bottom.png');

    await _go(tester, h, '/profile/nutrition/strategy');
    await _shot(tester, 'zh-05-strategy-picker.png');

    await _go(
      tester,
      h,
      '/profile/nutrition/strategy/configure?kind=carbCycle',
    );
    await _shot(tester, 'zh-06-carb-cycle-configure.png');
    await _scrollPage(tester);
    await _shot(tester, 'zh-06b-carb-cycle-configure-bottom.png');

    await _go(
      tester,
      h,
      '/profile/nutrition/strategy/configure?kind=carbTaper',
    );
    await _shot(tester, 'zh-07-carb-taper-configure.png');
    await _scrollPage(tester);
    await _shot(tester, 'zh-07b-carb-taper-configure-bottom.png');

    await _go(tester, h, '/profile');
    await _shot(tester, 'zh-08-profile.png');

    await _go(tester, h, '/profile/theme');
    await _shot(tester, 'zh-09-theme-page.png');
  });
}
