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
  goalWeeks: 10,
  weeklyLossKg: 0.5,
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

Future<Finder> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
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
    expect(find.text('Choose strategy'), findsOneWidget);
    expect(find.text('Stop strategy'), findsNothing);
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

  testWidgets('carb cycle configure → apply today → Today hero follows plan', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    _expectNoLayoutErrors(tester);
    expect(find.text('7-day schedule'), findsOneWidget);

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

    // Budget conservation across the next full planned week (a mid-cycle
    // start leaves the already-passed days of this week untouched).
    final today = CalendarDay.todayLocal();
    final monday = today.add(Duration(days: 8 - today.weekday));
    double sum = 0;
    for (var i = 0; i < 7; i++) {
      final t = (await repo.targetForDay(
        monday.add(Duration(days: i)),
        profile,
      ))!;
      sum += t.calories;
      expect(
        (4 * t.proteinG + 4 * t.carbG + 9 * t.fatG - t.calories).abs(),
        lessThan(1.0),
      );
    }
    expect((sum - 7 * active.baseEnergy).abs(), lessThan(1.0));

    // Back on the targets page after apply; then the Today hero shows the
    // plan chip and the plan's numbers instead of the profile target.
    expect(find.text('Stop strategy'), findsOneWidget);
    final todayTarget = (await repo.targetForDay(today, profile))!;
    await tester.pumpWidget(_app('/today'));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 1));
    _expectNoLayoutErrors(tester);
    expect(find.textContaining('Carb cycling'), findsWidgets);
    expect(find.text('${todayTarget.caloriesRounded}'), findsWidgets);
  });

  testWidgets('taper review page shows the observing state', (tester) async {
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
    expect(find.text('Observing'), findsWidgets);
    expect(find.textContaining('Stage 0'), findsWidgets);
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
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Choose strategy'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
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
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Choose strategy'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Only available with the cut goal.'), findsOneWidget);
  });
}
