import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/strategy/nutrition_targets_page.dart';
import 'package:diet/ui/strategy/strategy_configure_page.dart';
import 'package:diet/ui/strategy/strategy_picker_page.dart';
import 'package:diet/ui/strategy/taper_review_page.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:diet/ui/today/today_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _profile({FitnessGoal goal = FitnessGoal.cut}) => UserProfile(
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 75,
  activity: ActivityLevel.moderate,
  goal: goal,
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

late AppDatabase _db;
late ProviderContainer _container;

Future<void> _setUp({UserProfile? profile}) async {
  SharedPreferences.setMockInitialValues({
    'user_profile': jsonEncode((profile ?? _profile()).toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  _container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(_db),
    ],
  );
}

Widget _app(String initialLocation) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/today', builder: (_, _) => const TodayPage()),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Me')),
      ),
      GoRoute(
        path: '/profile/nutrition',
        builder: (_, _) => const NutritionTargetsPage(),
        routes: [
          GoRoute(
            path: 'strategy',
            builder: (_, _) => const StrategyPickerPage(),
            routes: [
              GoRoute(
                path: 'configure',
                builder: (_, state) => StrategyConfigurePage(
                  kind: DietStrategyKind.fromStorage(
                    state.uri.queryParameters['kind'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(path: 'taper', builder: (_, _) => const TaperReviewPage()),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: _container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.ofId(AppThemeId.fresh),
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

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _pump(WidgetTester tester, String location) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(location));
  await _settle(tester);
  await tester.pump(const Duration(seconds: 1));
}

Future<Finder> _show(WidgetTester tester, Finder finder, {double delta = 120}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await _settle(tester);
  return finder;
}

void _expectNoLayoutErrors(WidgetTester tester) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'layout error: $error');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _setUp());
  tearDown(() async {
    _container.dispose();
    await _db.close();
  });

  testWidgets('nutrition targets page renders without a plan', (tester) async {
    await _pump(tester, '/profile/nutrition');
    _expectNoLayoutErrors(tester);
    expect(find.text('Fat-loss strategy'), findsOneWidget);
    expect(find.text('No strategy'), findsOneWidget);
    expect(find.text('Stop strategy'), findsNothing);
  });

  testWidgets('Today offers strategy selection for a cut profile', (
    tester,
  ) async {
    await _pump(tester, '/today');
    expect(find.text('Cut'), findsOneWidget);
    final choose = find.text('Fat-loss strategy available');
    expect(choose, findsOneWidget);

    await tester.tap(choose);
    await _settle(tester);
    expect(find.text('Balanced deficit'), findsOneWidget);
  });

  testWidgets('picker lists exactly the three primary strategies', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy');
    _expectNoLayoutErrors(tester);
    expect(find.text('Balanced deficit'), findsOneWidget);
    expect(find.text('Carb cycling'), findsOneWidget);
    expect(find.text('Carb taper'), findsOneWidget);
    expect(find.textContaining('keto', findRichText: true), findsNothing);
  });

  testWidgets('configure uses read-only profile metrics and back returns', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy');
    await tester.tap(find.text('Balanced deficit'));
    await _settle(tester);

    final weight = find.byKey(const ValueKey('strategyReferenceWeight'));
    final tdee = find.byKey(const ValueKey('strategyEstimatedTdee'));
    final energy = find.byKey(const ValueKey('strategyAverageTargetEnergy'));
    expect(weight, findsOneWidget);
    expect(tdee, findsOneWidget);
    expect(energy, findsOneWidget);
    expect(
      find.descendant(of: weight, matching: find.byType(TextField)),
      findsNothing,
    );
    expect(
      find.descendant(of: tdee, matching: find.byType(TextField)),
      findsNothing,
    );
    expect(
      find.descendant(of: energy, matching: find.byType(TextField)),
      findsNothing,
    );
    expect(find.text('75.0'), findsOneWidget);
    expect(find.text('2400'), findsOneWidget);

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(find.text('Fat-loss strategy'), findsOneWidget);
  });

  testWidgets('carb cycle shows the same read-only profile metrics', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    final weight = find.byKey(const ValueKey('strategyReferenceWeight'));
    final tdee = find.byKey(const ValueKey('strategyEstimatedTdee'));
    expect(weight, findsOneWidget);
    expect(tdee, findsOneWidget);
    expect(
      find.descendant(of: weight, matching: find.byType(TextField)),
      findsNothing,
    );
    expect(
      find.descendant(of: tdee, matching: find.byType(TextField)),
      findsNothing,
    );
    _expectNoLayoutErrors(tester);
  });

  testWidgets('balanced and taper deficits are bounded by the slider', (
    tester,
  ) async {
    for (final kind in ['balanced', 'carbTaper']) {
      await _pump(tester, '/profile/nutrition/strategy/configure?kind=$kind');
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 240);
      expect(slider.max, 480);
      expect(slider.divisions, 10);
      expect(find.textContaining('Allowed'), findsNothing);
    }
  });

  testWidgets('carb cycle configure → apply today → Today hero follows plan', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    _expectNoLayoutErrors(tester);
    expect(await _show(tester, find.text('Cycle schedule')), findsOneWidget);

    // Tap day 1 (low -> mid) and confirm the high-day carb stepper itself
    // switches to the compensated effective rate, with a "[Modified]"
    // marker on its label (not a separate note line).
    await tester.tap(
      await _show(tester, find.byKey(const ValueKey('cycleDay-1'))),
    );
    await _settle(tester);
    // 4-day cycle, 1 mid day (defaultFor(4) + toggling day 1): the high
    // day's carbs are trimmed by (1/4) × (E_high − E_low) / 4 to hold the
    // cycle average steady, using the default low/high rates. This is a
    // per-kg calculation, so the reference weight (75, from the fixture
    // profile below) cancels out.
    const elowPerKg =
        4 * StrategyRules.defaultLowProteinPerKg +
        4 * StrategyRules.defaultLowCarbPerKg +
        9 * StrategyRules.defaultLowFatPerKg;
    const ehighPerKg =
        4 * StrategyRules.defaultHighProteinPerKg +
        4 * StrategyRules.defaultHighCarbPerKg +
        9 * StrategyRules.defaultHighFatPerKg;
    const deltaCarbPerKg = (1 / 4) * (ehighPerKg - elowPerKg) / 4;
    const effective = StrategyRules.defaultHighCarbPerKg - deltaCarbPerKg;
    // Scroll back up: the stepper sits in the parameters section, above the
    // schedule table we just scrolled down to tap. The label stays plain
    // ("Carb per kg"); the adjustment shows as an icon badge, not text.
    expect(
      await _show(
        tester,
        find.byTooltip('Automatically adjusted to balance mid-carb days'),
        delta: -120,
      ),
      findsOneWidget,
    );
    expect(
      find.text('${effective.toStringAsFixed(1)} g/kg'),
      findsOneWidget,
    );

    await tester.tap(await _show(tester, find.text('Start today')));
    await _settle(tester);
    final apply = await _show(tester, find.textContaining('Apply from'));
    await tester.tap(apply);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 1));

    final repo = _container.read(dietStrategyRepositoryProvider);
    final profile = _container.read(profileProvider);
    final active = await repo.activePlan();
    expect(active, isNotNull);
    expect(active!.kind, DietStrategyKind.carbCycle);
    expect(active.effectiveFrom, CalendarDay.todayLocal());

    // Every day's macros are internally consistent (4P + 4C + 9F = kcal),
    // and the schedule repeats on the configured cycle length.
    final today = CalendarDay.todayLocal();
    final cycleLength = active.schedule!.cycleLengthDays;
    for (var i = 0; i < cycleLength * 2; i++) {
      final t = (await repo.targetForDay(
        today.add(Duration(days: i)),
        profile,
      ))!;
      expect(
        (4 * t.proteinG + 4 * t.carbG + 9 * t.fatG - t.calories).abs(),
        lessThan(1.0),
      );
    }
    // Cycle last day is the high-carb day by default.
    expect(
      (await repo.targetForDay(
        today.add(Duration(days: cycleLength - 1)),
        profile,
      ))!.dayType,
      CarbDayType.high,
    );

    // Applying completes the flow and returns directly to Me.
    expect(find.text('Me'), findsOneWidget);
    final todayTarget = (await repo.targetForDay(today, profile))!;
    await tester.pumpWidget(_app('/today'));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 1));
    _expectNoLayoutErrors(tester);
    expect(find.textContaining('Carb cycling'), findsWidgets);
    expect(find.text('${todayTarget.caloriesRounded}'), findsWidgets);
  });

  testWidgets('taper review page lets the user switch stages freely', (
    tester,
  ) async {
    final repo = _container.read(dietStrategyRepositoryProvider);
    await repo.createPlan(
      DietStrategyPlanDraft(
        kind: DietStrategyKind.carbTaper,
        effectiveFrom: CalendarDay.todayLocal(),
        referenceWeightKg: 75,
        estimatedTdee: 2400,
        baseEnergy: 2000,
        observationStart: CalendarDay.todayLocal(),
        reason: 'test',
      ),
    );
    await _pump(tester, '/profile/nutrition/taper');
    _expectNoLayoutErrors(tester);
    // No observation/review gating — every reachable stage is listed and
    // immediately tappable (other than the current one).
    expect(find.textContaining('Stage 0'), findsWidgets);
    expect(find.textContaining('Stage 1'), findsWidgets);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });

  testWidgets('underage profile cannot start a fat-loss strategy', (
    tester,
  ) async {
    _container.dispose();
    await _db.close();
    await _setUp(
      profile: UserProfile(
        sex: Sex.male,
        age: 16,
        heightCm: 170,
        weightKg: 60,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.cut,
        targets: const MacroTargets(
          calories: 1800,
          proteinG: 120,
          carbG: 200,
          fatG: 50,
        ),
        tdee: 2200,
        calorieStandardSince: DateTime(2026, 1, 1),
      ),
    );
    await _pump(tester, '/profile/nutrition');
    _expectNoLayoutErrors(tester);
    // Strategy row is a list tile (aligned with TDEE); it stays non-tappable
    // while eligibility is blocked.
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Fat-loss strategy'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.onTap, isNull);
    expect(find.textContaining('adults (18+)'), findsOneWidget);
  });

  testWidgets('maintain goal is not eligible for a fat-loss strategy', (
    tester,
  ) async {
    _container.dispose();
    await _db.close();
    await _setUp(profile: _profile(goal: FitnessGoal.maintain));
    await _pump(tester, '/profile/nutrition');
    _expectNoLayoutErrors(tester);
    // Nutrition targets now opens on the profile's own goal tab (维持 for
    // this profile), which is just a "coming soon" placeholder — switch to
    // 减脂/Cut to see the (blocked) strategy section this test is about.
    await tester.tap(find.text('Cut'));
    await tester.pumpAndSettle();
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Fat-loss strategy'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.onTap, isNull);
    expect(find.text('Only available with the cut goal.'), findsOneWidget);
  });
}
