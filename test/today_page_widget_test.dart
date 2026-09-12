import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:diet/ui/today/today_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  goalWeeks: 10,
  weeklyLossKg: 0.5,
  bmr: 1700,
  tdee: 2400,
  dailyDeficit: 400,
  calorieStandardSince: DateTime(2026, 1, 1),
);

class _Harness {
  _Harness(this.db, this.prefs, this.container);

  final AppDatabase db;
  final SharedPreferences prefs;
  final ProviderContainer container;
}

Future<_Harness> _harness({Map<String, Object> extraPrefs = const {}}) async {
  SharedPreferences.setMockInitialValues({
    'user_profile': jsonEncode(_profile().toJson()),
    ...extraPrefs,
  });
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
    ],
  );
  return _Harness(db, prefs, container);
}

Widget _app(_Harness h, {AppThemeId theme = AppThemeId.fresh}) {
  final router = GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(path: '/today', builder: (_, _) => const TodayPage()),
      GoRoute(
        path: '/log-meal',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('LOG_MEAL_PAGE'))),
      ),
      GoRoute(
        path: '/profile/nutrition',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('NUTRITION_PAGE'))),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: h.container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.ofId(theme),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Harness h, {
  Size size = const Size(360, 800),
  double textScale = 1.0,
  AppThemeId theme = AppThemeId.fresh,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(_app(h, theme: theme));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 1));
}

/// The water cup runs a gentle looping wave animation, so `pumpAndSettle`
/// would never return; advance time explicitly instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}

/// Fails the test if any layout overflow was reported by the framework.
void _expectNoOverflow(WidgetTester tester) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'layout error: $error');
}

/// Scrolls the page until [finder] is built and visible, then returns it.
///
/// The page body is a horizontal [PageView] (from `SwipeTabView`) wrapping a
/// vertical `ListView`, so `find.byType(Scrollable).first` can bind to the
/// outer pager instead of the list — harmless while everything fits on
/// screen without scrolling, but it silently stops finding anything the
/// moment the page actually needs a vertical scroll. Target the down-axis
/// Scrollable explicitly instead.
Future<Finder> _show(WidgetTester tester, Finder finder) async {
  final verticalScrollable = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: verticalScrollable.first,
  );
  await _settle(tester);
  return finder;
}

Finder _semantic(String label) =>
    find.bySemanticsLabel(RegExp(RegExp.escape(label)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Harness h;

  setUp(() async {
    h = await _harness();
  });

  tearDown(() async {
    h.container.dispose();
    await h.db.close();
  });

  group('today hero card layout', () {
    testWidgets('four macro columns on a 360px screen without overflow', (
      tester,
    ) async {
      await _pump(tester, h);
      _expectNoOverflow(tester);

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      // The water cup sits inside the hero card, not in its own card.
      expect(_semantic('Add 250 ml water'), findsOneWidget);

      final protein = tester.getTopLeft(find.text('Protein'));
      final water = tester.getTopLeft(find.text('Water'));
      // Same row: identical vertical position, water to the far right.
      expect((protein.dy - water.dy).abs(), lessThan(1));
      expect(water.dx, greaterThan(protein.dx));
    });

    testWidgets('large text (1.3x) still fits four columns', (tester) async {
      await _pump(tester, h, textScale: 1.3);
      _expectNoOverflow(tester);
      expect(find.text('Water'), findsOneWidget);
    });

    testWidgets(
      'value / target wrap instead of overflowing when water is high',
      (tester) async {
        final today = CalendarDay.todayLocal();
        await h.container
            .read(waterRepositoryProvider)
            .setMlForDay(today, 1250);
        await _pump(tester, h);
        _expectNoOverflow(tester);
        expect(find.textContaining('1250'), findsWidgets);
      },
    );
  });

  group('open sections', () {
    testWidgets('workout and meal empty states render inline by default', (
      tester,
    ) async {
      await _pump(tester, h);
      // No expand/collapse: the workout empty state shows straight away.
      expect(find.text('No workout planned yet'), findsOneWidget);
      // The meals empty state sits lower down the page.
      await _show(tester, find.text('No meals logged yet'));
      expect(find.text('No meals logged yet'), findsOneWidget);
      _expectNoOverflow(tester);
    });

    testWidgets('plain plus on logs opens the log flow', (tester) async {
      await _pump(tester, h);

      final plus = await _show(tester, _semantic('Log meal'));
      expect(plus, findsOneWidget);
      // Plain icon: no circular background / border / shadow.
      expect(
        find.ancestor(of: plus, matching: find.byType(FilledButton)),
        findsNothing,
      );
      expect(
        find.ancestor(of: plus, matching: find.byType(FloatingActionButton)),
        findsNothing,
      );
      final size = tester.getSize(plus);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));

      await tester.ensureVisible(plus);
      await _settle(tester);
      await tester.tap(
        find.descendant(of: plus, matching: find.byType(InkResponse)),
      );
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('LOG_MEAL_PAGE'), findsOneWidget);
    });

    testWidgets('plain plus on workout opens the plan picker', (tester) async {
      await _pump(tester, h);
      final plus = _semantic("Add today's workout");
      expect(plus, findsOneWidget);
      await tester.tap(plus);
      await tester.pump(const Duration(milliseconds: 500));
      // The empty state stays put (the picker is a sheet / dialog).
      expect(find.text('No workout planned yet'), findsOneWidget);
    });
  });

  group('water cup', () {
    testWidgets('cup adds 250 ml, lid undoes, never below zero', (
      tester,
    ) async {
      await _pump(tester, h);
      final today = CalendarDay.todayLocal();
      final water = h.container.read(waterRepositoryProvider);

      // Lid at 0 is disabled: nothing happens, no negative value.
      await tester.tap(_semantic('Undo 250 ml water'), warnIfMissed: false);
      await _settle(tester);
      expect(await water.mlForDay(today), 0);

      await tester.tap(_semantic('Add 250 ml water'));
      await _settle(tester);
      expect(await water.mlForDay(today), 250);
      await tester.tap(_semantic('Add 250 ml water'));
      await _settle(tester);
      expect(await water.mlForDay(today), 500);

      await tester.tap(_semantic('Undo 250 ml water'));
      await _settle(tester);
      expect(await water.mlForDay(today), 250);
      await tester.tap(_semantic('Undo 250 ml water'));
      await _settle(tester);
      expect(await water.mlForDay(today), 0);
      await tester.tap(_semantic('Undo 250 ml water'), warnIfMissed: false);
      await _settle(tester);
      expect(await water.mlForDay(today), 0);
      _expectNoOverflow(tester);
    });

    testWidgets('over-goal shows the real number', (tester) async {
      final today = CalendarDay.todayLocal();
      await h.container.read(waterRepositoryProvider).setMlForDay(today, 2750);
      await _pump(tester, h);
      _expectNoOverflow(tester);
      expect(find.textContaining('2750'), findsWidgets);
    });
  });

  group('themes', () {
    for (final id in AppThemeId.presets) {
      testWidgets('renders today page in ${id.name}', (tester) async {
        await _pump(tester, h, theme: id);
        _expectNoOverflow(tester);
        expect(find.text('Water'), findsOneWidget);
      });
    }

    test('stored theme id is restored on start', () async {
      final saved = await _harness(extraPrefs: {'app_theme_id': 'graphite'});
      expect(saved.container.read(themeProvider), AppThemeId.graphite);
      saved.container.dispose();
      await saved.db.close();
    });

    test('legacy theme ids map to a current theme', () async {
      final legacy = await _harness(extraPrefs: {'app_theme_id': 'night'});
      expect(legacy.container.read(themeProvider), AppThemeId.graphite);
      legacy.container.dispose();
      await legacy.db.close();
    });

    test('new users get Fresh Green', () async {
      expect(h.container.read(themeProvider), AppThemeId.fresh);
    });

    test('selecting a theme persists across a fresh container', () async {
      await h.container
          .read(themeProvider.notifier)
          .select(AppThemeId.graphite);
      final again = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(h.prefs),
          databaseProvider.overrideWithValue(h.db),
        ],
      );
      expect(again.read(themeProvider), AppThemeId.graphite);
      again.dispose();
    });
  });
}
