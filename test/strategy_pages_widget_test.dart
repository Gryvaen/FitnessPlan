import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/strategy/nutrition_targets_page.dart';
import 'package:diet/ui/strategy/strategy_configure_page.dart';
import 'package:diet/ui/strategy/strategy_picker_page.dart';
import 'package:diet/ui/strategy/taper_review_page.dart';
import 'package:diet/ui/profile/profile_edit_page.dart';
import 'package:diet/ui/widgets/form_options.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:diet/ui/ink/ink_icon.dart';
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

class _FailingStrategyActions extends DietStrategyActions {
  _FailingStrategyActions(super.ref);

  @override
  Future<DietStrategyPlan> applyPlan(DietStrategyPlanDraft draft) async {
    throw StateError('test save failure');
  }
}

class _FailingProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile> save({
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required FitnessGoal goal,
    double? targetWeightKg,
    int? calorieAdjustment,
  }) async => throw StateError('profile save failure');
}

Future<void> _setUp({
  UserProfile? profile,
  bool failApply = false,
  bool failProfile = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'user_profile': jsonEncode((profile ?? _profile()).toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  _container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(_db),
      if (failApply)
        dietStrategyActionsProvider.overrideWith(_FailingStrategyActions.new),
      if (failProfile)
        profileProvider.overrideWith(_FailingProfileNotifier.new),
    ],
  );
}

Widget _app(String initialLocation, {AppThemeId themeId = AppThemeId.fresh}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/today', builder: (_, _) => const TodayPage()),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Me')),
        routes: [
          GoRoute(path: 'edit', builder: (_, _) => const ProfileEditPage()),
        ],
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
      theme: AppTheme.ofId(themeId),
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

Future<void> _pump(
  WidgetTester tester,
  String location, {
  AppThemeId themeId = AppThemeId.fresh,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(location, themeId: themeId));
  await _settle(tester);
  await tester.pump(const Duration(seconds: 1));
}

Future<Finder> _show(
  WidgetTester tester,
  Finder finder, {
  double delta = 120,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await _settle(tester);
  return finder;
}

/// Like [_show], but scrolls the visible vertical list. The nutrition page
/// nests its lists in a horizontal goal pager, which is the first Scrollable.
Future<Finder> _showInPage(
  WidgetTester tester,
  Finder finder, {
  double delta = 120,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .hitTestable()
        .first,
  );
  await _settle(tester);
  return finder;
}

Future<void> _openStrategySection(WidgetTester tester, String key) async {
  await tester.tap(await _show(tester, find.byKey(ValueKey(key))));
  await _settle(tester);
}

void _expectNoLayoutErrors(WidgetTester tester) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'layout error: $error');
}

Future<void> _createPlan(
  DietStrategyKind kind, {
  DateTime? effectiveFrom,
}) async {
  await _container
      .read(dietStrategyRepositoryProvider)
      .createPlan(
        DietStrategyPlanDraft(
          kind: kind,
          effectiveFrom: effectiveFrom ?? CalendarDay.todayLocal(),
          referenceWeightKg: 75,
          estimatedTdee: 2400,
          baseEnergy: 2000,
          schedule: kind == DietStrategyKind.carbCycle
              ? CarbCycleSchedule.defaultFor(4)
              : null,
          carbCycleRates: kind == DietStrategyKind.carbCycle
              ? CarbCycleRates.defaults()
              : null,
          observationStart: kind == DietStrategyKind.carbTaper
              ? CalendarDay.todayLocal()
              : null,
          reason: 'test',
        ),
      );
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
    expect(find.byKey(const ValueKey('noStrategyEmpty')), findsOneWidget);
    expect(find.text('No strategy'), findsOneWidget);
    expect(find.text('Choose strategy'), findsOneWidget);
    expect(find.text('Stop strategy'), findsNothing);
    await tester.tap(find.text('Choose strategy'));
    await _settle(tester);
    expect(find.text('Balanced deficit'), findsOneWidget);
  });

  testWidgets('weight change keeps saved plan until re-applied', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.balanced);
    final repo = _container.read(dietStrategyRepositoryProvider);
    final original = (await repo.activePlan())!;
    final today = CalendarDay.todayLocal();
    final originalTarget = (await repo.targetForDay(
      today,
      _container.read(profileProvider),
    ))!;
    await _pump(tester, '/profile/nutrition');

    await _container.read(profileProvider.notifier).applyLatestWeight(72.8);
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);

    final updated = (await _container
        .read(profileProvider.notifier)
        .applyLatestWeight(72.7))!;
    await _settle(tester);
    expect(updated.tdee, isNot(2400));
    // No review prompt any more: the saved plan simply stays in force.
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);
    expect((await repo.activePlan())!.estimatedTdee, original.estimatedTdee);
    expect(
      (await repo.targetForDay(today, updated))!.calories,
      originalTarget.calories,
    );
    await _show(tester, find.text('This plan’s baseline'));
    expect(find.text('This plan’s baseline'), findsOneWidget);
    expect(find.textContaining('75.0'), findsWidgets);
    await tester.pumpWidget(
      _app('/profile/nutrition/strategy/configure?kind=balanced'),
    );
    await _settle(tester);
    expect(
      find.descendant(
        of: find.byType(StrategyConfigurePage),
        matching: find.text('This plan’s baseline'),
      ),
      findsOneWidget,
    );
    expect(find.text('Proposed target'), findsOneWidget);
    await _openStrategySection(tester, 'strategy-section-profile');
    expect(find.text('Current profile'), findsOneWidget);
    expect(find.text('72.7', skipOffstage: false), findsWidgets);
    _expectNoLayoutErrors(tester);

    await tester.tap(await _show(tester, find.textContaining('Apply from')));
    await _settle(tester);
    final applied = (await repo.activePlan())!;
    expect(applied.version, original.version + 1);
    expect(applied.referenceWeightKg, 72.7);
    expect(applied.estimatedTdee, updated.tdee);
    expect(
      applied.baseEnergy,
      closeTo(updated.tdee! * (1 - original.deficitFraction), 1e-6),
    );
    expect(
      applied.baseline.balancedDay.proteinG,
      closeTo(72.7 * applied.proteinPerKg, 1e-6),
    );
    expect(
      (await repo.targetForDay(today, updated))!.calories,
      originalTarget.calories,
    );
    await tester.pumpWidget(
      _app('/profile/nutrition/strategy/configure?kind=balanced'),
    );
    await _settle(tester);
    expect(find.text('This plan’s baseline'), findsOneWidget);
    expect(find.text('Proposed target'), findsNothing);
    expect(find.text('Scheduled to apply'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Scheduled to apply'),
          )
          .onPressed,
      isNull,
    );
    await _container.read(profileProvider.notifier).applyLatestWeight(71.0);
    await _settle(tester);
    expect(find.text('Proposed target'), findsOneWidget);
    expect(find.textContaining('Apply from'), findsOneWidget);
  });

  testWidgets('matching plan hides proposal until parameters change', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.balanced);
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=balanced');
    expect(find.text('This plan’s baseline'), findsOneWidget);
    expect(find.text('Proposed target'), findsNothing);
    expect(find.text('Currently applied'), findsOneWidget);
    final repo = _container.read(dietStrategyRepositoryProvider);
    final version = (await repo.activePlan())!.version;

    await _openStrategySection(tester, 'strategy-section-effective');
    await tester.tap(await _show(tester, find.text('Start today')));
    await _settle(tester);
    expect(find.text('Proposed target'), findsNothing);
    expect(find.text('Currently applied'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Currently applied'),
          )
          .onPressed,
      isNull,
    );
    expect((await repo.activePlan())!.version, version);

    await _openStrategySection(tester, 'strategy-section-target');
    await tester.ensureVisible(find.byType(Slider));
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await _settle(tester);
    // Sections stay open together, so the summary sits above the viewport.
    expect(
      await _show(tester, find.text('Proposed target'), delta: -120),
      findsOneWidget,
    );
    expect(find.textContaining('Apply from'), findsOneWidget);
    _expectNoLayoutErrors(tester);
  });

  testWidgets('applied plan can be re-applied from a different start date', (
    tester,
  ) async {
    final today = CalendarDay.todayLocal();
    final tomorrow = CalendarDay.addDays(today, 1);
    await _createPlan(DietStrategyKind.balanced);
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=balanced');
    VoidCallback? applyPressed() => tester
        .widget<FilledButton>(
          find.ancestor(
            of: find.textContaining(RegExp('Currently applied|Apply from')),
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed;
    expect(find.text('Currently applied'), findsOneWidget);
    expect(applyPressed(), isNull);

    await _openStrategySection(tester, 'strategy-section-effective');
    // The section summary repeats the chosen label; the option comes last.
    final tomorrowOption = find.textContaining('Tomorrow (').last;
    await tester.tap(await _show(tester, tomorrowOption));
    await _settle(tester);
    await _show(tester, find.textContaining('Apply from'), delta: -120);
    expect(applyPressed(), isNotNull);
    expect(find.text('Proposed target'), findsNothing);

    await tester.tap(await _show(tester, find.text('Start today').last));
    await _settle(tester);
    await _show(tester, find.text('Currently applied'), delta: -120);
    expect(applyPressed(), isNull);

    await tester.tap(await _show(tester, tomorrowOption));
    await _settle(tester);
    await tester.tap(
      await _show(tester, find.textContaining('Apply from'), delta: -120),
    );
    await _settle(tester);
    final repo = _container.read(dietStrategyRepositoryProvider);
    final active = (await repo.activePlan())!;
    expect(active.version, 2);
    expect(active.effectiveFrom, tomorrow);
    expect((await repo.planCovering(today))!.version, 1);
  });

  testWidgets('matching scheduled plan shows disabled scheduled status', (
    tester,
  ) async {
    final tomorrow = CalendarDay.addDays(CalendarDay.todayLocal(), 1);
    await _createPlan(DietStrategyKind.balanced, effectiveFrom: tomorrow);
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=balanced');
    expect(find.text('Scheduled to apply'), findsOneWidget);
    expect(find.text('Proposed target'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Scheduled to apply'),
          )
          .onPressed,
      isNull,
    );
    expect(
      (await _container.read(dietStrategyRepositoryProvider).activePlan())!
          .version,
      1,
    );
  });

  testWidgets('scheduled carb cycle can be moved to start today', (
    tester,
  ) async {
    final today = CalendarDay.todayLocal();
    final tomorrow = CalendarDay.addDays(today, 1);
    final schedule = CarbCycleSchedule.defaultFor(4);
    final rates = CarbCycleRates.defaults();
    await _container
        .read(dietStrategyActionsProvider)
        .applyPlan(
          DietStrategyPlanDraft(
            kind: DietStrategyKind.carbCycle,
            effectiveFrom: tomorrow,
            referenceWeightKg: 75,
            estimatedTdee: 2400,
            baseEnergy: CarbCyclePlanner.compute(
              referenceWeightKg: 75,
              rates: rates,
              schedule: schedule,
            ).cycleAverageEnergy,
            schedule: schedule,
            carbCycleRates: rates,
            reason: 'test',
          ),
        );
    expect(_container.read(profileProvider)!.calorieStandardSince, tomorrow);
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Scheduled to apply'),
          )
          .onPressed,
      isNull,
    );

    await _openStrategySection(tester, 'strategy-section-effective');
    await tester.tap(await _show(tester, find.text('Start today')));
    await _settle(tester);
    expect(find.text('Scheduled to apply'), findsNothing);
    expect(find.text('Proposed target'), findsNothing);
    final apply = await _show(tester, find.textContaining('Apply from'));
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: apply, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(apply);
    await _settle(tester);

    final repo = _container.read(dietStrategyRepositoryProvider);
    final active = (await repo.activePlan())!;
    expect(active.version, 2);
    expect(active.effectiveFrom, today);
    expect((await repo.planCovering(tomorrow))!.version, 2);
    // The new standard now starts today, not on the cancelled tomorrow.
    expect(_container.read(profileProvider)!.calorieStandardSince, today);
  });

  testWidgets('65 kg cycle shows advisory and still applies', (tester) async {
    _container.dispose();
    await _db.close();
    await _setUp(profile: _profile().copyWith(weightKg: 65));
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    expect(
      find.byKey(const ValueKey('strategyLowEnergyNotice')),
      findsOneWidget,
    );
    expect(find.textContaining('1196 kcal'), findsOneWidget);
    _expectNoLayoutErrors(tester);
    final apply = await _show(tester, find.textContaining('Apply from'));
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: apply, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(apply);
    await _settle(tester);
    final active = await _container
        .read(dietStrategyRepositoryProvider)
        .activePlan();
    expect(active?.referenceWeightKg, 65);
    expect(
      active?.carbCyclePlan?.energyFor(CarbDayType.low),
      closeTo(1196, 1e-9),
    );
  });

  for (final kind in [DietStrategyKind.balanced, DietStrategyKind.carbTaper]) {
    testWidgets('${kind.name} shows a non-blocking low-energy notice', (
      tester,
    ) async {
      _container.dispose();
      await _db.close();
      await _setUp(profile: _profile().copyWith(weightKg: 40, tdee: 1350));
      await _pump(
        tester,
        '/profile/nutrition/strategy/configure?kind=${kind.name}',
        themeId: AppThemeId.graphite,
      );
      expect(
        find.byKey(const ValueKey('strategyLowEnergyNotice')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('strategyLowEnergyNotice')),
          matching: find.textContaining('1148 kcal'),
        ),
        findsOneWidget,
      );
      final apply = await _show(tester, find.textContaining('Apply from'));
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(of: apply, matching: find.byType(FilledButton)),
            )
            .onPressed,
        isNotNull,
      );
      _expectNoLayoutErrors(tester);
    });
  }

  testWidgets('carb-cycle schedule edits show a pending proposal', (
    tester,
  ) async {
    final schedule = CarbCycleSchedule.defaultFor(4);
    final rates = CarbCycleRates.defaults();
    final energy = CarbCyclePlanner.compute(
      referenceWeightKg: 75,
      rates: rates,
      schedule: schedule,
    ).cycleAverageEnergy;
    await _container
        .read(dietStrategyRepositoryProvider)
        .createPlan(
          DietStrategyPlanDraft(
            kind: DietStrategyKind.carbCycle,
            effectiveFrom: CalendarDay.todayLocal(),
            referenceWeightKg: 75,
            estimatedTdee: 2400,
            baseEnergy: energy,
            schedule: schedule,
            carbCycleRates: rates,
          ),
        );
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    expect(find.text('Proposed target'), findsNothing);
    await _openStrategySection(tester, 'strategy-section-schedule');
    await tester.tap(
      await _show(tester, find.byKey(const ValueKey('cycleDay-1'))),
    );
    await _settle(tester);
    await _show(
      tester,
      find.byKey(const ValueKey('strategyTopSummary')),
      delta: -120,
    );
    expect(find.text('Proposed target'), findsOneWidget);
  });

  testWidgets('failed apply keeps proposed target on configuration page', (
    tester,
  ) async {
    _container.dispose();
    await _db.close();
    await _setUp(failApply: true);
    await _createPlan(DietStrategyKind.balanced);
    await _container.read(profileProvider.notifier).applyLatestWeight(72.7);
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=balanced');
    expect(find.text('Proposed target'), findsOneWidget);
    await tester.tap(await _show(tester, find.textContaining('Apply from')));
    await _settle(tester);
    expect(find.byType(StrategyConfigurePage), findsOneWidget);
    expect(find.text('Proposed target'), findsOneWidget);
    expect(find.textContaining('test save failure'), findsOneWidget);
    expect(find.textContaining('Apply from'), findsOneWidget);
    expect(
      (await _container.read(dietStrategyRepositoryProvider).activePlan())!
          .version,
      1,
    );
  });

  testWidgets('profile edit without strategy reports updated profile target', (
    tester,
  ) async {
    final oldKcal = _container.read(profileProvider)!.targets.calories;
    await _pump(tester, '/profile/edit');
    tester
        .widget<AppDropdown<ActivityLevel>>(
          find.byType(AppDropdown<ActivityLevel>),
        )
        .onChanged(ActivityLevel.light);
    await _settle(tester);
    await tester.tap(await _show(tester, find.text('Save')));
    await _settle(tester);
    final newKcal = _container.read(profileProvider)!.targets.calories;
    expect(newKcal, isNot(oldKcal));
    expect(
      find.text('Profile calorie target updated: $oldKcal → $newKcal kcal'),
      findsOneWidget,
    );
  });

  testWidgets('leaving cut stops its strategy and explains the change', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.balanced);
    await _pump(tester, '/profile/edit');
    tester
        .widget<AppDropdown<FitnessGoal>>(find.byType(AppDropdown<FitnessGoal>))
        .onChanged(FitnessGoal.maintain);
    await _settle(tester);
    await tester.tap(await _show(tester, find.text('Save')));
    await _settle(tester);
    expect(
      await _container.read(dietStrategyRepositoryProvider).activePlan(),
      isNull,
    );
    expect(
      find.textContaining('previous fat-loss strategy has stopped'),
      findsOneWidget,
    );
  });

  testWidgets('leaving cut banks the open cultivation segment', (tester) async {
    final today = CalendarDay.todayLocal();
    await _container
        .read(cutCultivationStateProvider.notifier)
        .ensureOpenForCut(preferredStart: today);
    await _container
        .read(dayMarkerRepositoryProvider)
        .setCheatMeal(today, penaltyKcal: 500);
    await _pump(tester, '/profile/edit');
    tester
        .widget<AppDropdown<FitnessGoal>>(find.byType(AppDropdown<FitnessGoal>))
        .onChanged(FitnessGoal.maintain);
    await _settle(tester);
    await tester.tap(await _show(tester, find.text('Save')));
    await _settle(tester);
    for (
      var i = 0;
      i < 20 && _container.read(profileProvider)?.goal != FitnessGoal.maintain;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_container.read(profileProvider)?.goal, FitnessGoal.maintain);
    final ledger = _container.read(cutCultivationStateProvider);
    expect(ledger.openSegment, isNull);
    expect(ledger.frozenKcal, -500);
  });

  testWidgets('failed profile save keeps the edit', (tester) async {
    await _setUp(failProfile: true);
    await _createPlan(DietStrategyKind.balanced);
    await _pump(tester, '/profile/edit');
    tester
        .widget<AppDropdown<double>>(find.byType(AppDropdown<double>))
        .onChanged(74.75);
    await _settle(tester);
    await tester.tap(await _show(tester, find.text('Save')));
    await _settle(tester);
    expect(find.byType(ProfileEditPage), findsOneWidget);
    expect(find.textContaining('profile save failure'), findsOneWidget);
  });

  testWidgets('carb-cycle page shows schedule and actions without folds', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.carbCycle);
    await _pump(tester, '/profile/nutrition');

    expect(find.byKey(const ValueKey('strategyOverviewCard')), findsOneWidget);
    expect(find.textContaining('Today ·'), findsOneWidget);
    expect(find.byKey(const ValueKey('cycleDay-0')), findsOneWidget);
    await _showInPage(tester, find.text('Adjust schedule'));
    expect(find.text('Adjust schedule'), findsOneWidget);
    await _showInPage(tester, find.text('Stop strategy'));
    expect(find.text('Stop strategy'), findsOneWidget);
    expect(find.text('Change strategy'), findsOneWidget);

    await tester.tap(await _showInPage(tester, find.text('Stop strategy')));
    await _settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Stop strategy'),
      ),
      findsWidgets,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await _settle(tester);
    expect(
      (await _container.read(dietStrategyRepositoryProvider).activePlan())
          ?.kind,
      DietStrategyKind.carbCycle,
    );

    await tester.tap(
      await _showInPage(tester, find.text('Adjust schedule'), delta: -120),
    );
    await _settle(tester);
    await _openStrategySection(tester, 'strategy-section-profile');
    expect(
      find.byKey(const ValueKey('strategyReferenceWeight')),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);
    _expectNoLayoutErrors(tester);
  });

  testWidgets('re-applying on the same day does not bump the shown version', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.balanced);
    await _createPlan(DietStrategyKind.balanced);
    await _createPlan(DietStrategyKind.carbCycle);
    final repo = _container.read(dietStrategyRepositoryProvider);
    expect((await repo.activePlan())!.version, 3);
    await _pump(tester, '/profile/nutrition');
    expect(find.text('Carb cycling · v1'), findsOneWidget);

    // A switch scheduled for tomorrow will be the second applied version.
    await _createPlan(
      DietStrategyKind.balanced,
      effectiveFrom: CalendarDay.addDays(CalendarDay.todayLocal(), 1),
    );
    await _settle(tester);
    expect(find.text('Balanced deficit · v2'), findsOneWidget);
  });

  testWidgets('carb-taper page shows stage entry and actions', (tester) async {
    await _createPlan(DietStrategyKind.carbTaper);
    await _pump(tester, '/profile/nutrition');

    expect(find.text('Taper stages'), findsOneWidget);
    await _showInPage(tester, find.text('Stop strategy'));
    expect(find.text('Stop strategy'), findsOneWidget);

    await tester.tap(
      await _showInPage(tester, find.text('Taper stages'), delta: -120),
    );
    await _settle(tester);
    expect(find.textContaining('Stage 0'), findsWidgets);
    _expectNoLayoutErrors(tester);
  });

  testWidgets('scheduled strategy shows status and cancellation', (
    tester,
  ) async {
    await _createPlan(
      DietStrategyKind.carbTaper,
      effectiveFrom: CalendarDay.addDays(CalendarDay.todayLocal(), 1),
    );
    await _pump(tester, '/profile/nutrition');

    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.textContaining('First day'), findsOneWidget);
    await _showInPage(tester, find.text('Cancel scheduled change'));
    expect(find.text('Cancel scheduled change'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancel scheduled change'));
    await tester.tap(find.text('Cancel scheduled change'));
    await _settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel scheduled change'),
      ),
      findsWidgets,
    );
    _expectNoLayoutErrors(tester);
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
    // Descriptions are always visible; a row opens configuration directly.
    expect(find.textContaining('A 3-5 day cycle'), findsOneWidget);
    expect(find.textContaining('Start at the baseline'), findsOneWidget);
    await tester.tap(find.text('Carb cycling'));
    await _settle(tester);
    expect(find.byType(StrategyConfigurePage), findsOneWidget);
    expect(find.byKey(const ValueKey('strategyTopSummary')), findsOneWidget);
  });

  testWidgets('picker rules are secondary and expand independently', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _createPlan(DietStrategyKind.balanced);
    await _pump(tester, '/profile/nutrition/strategy');

    final rules = find.byKey(const ValueKey('strategyPickerRules'));
    final ruleRadio = find.descendant(
      of: rules,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is InkIcon &&
            (widget.glyph == InkGlyph.radioEmpty ||
                widget.glyph == InkGlyph.radioChecked),
      ),
    );
    expect(rules, findsOneWidget);
    expect(ruleRadio, findsNothing);
    expect(tester.getSemantics(rules).label, 'Rules, Expand');
    expect(find.textContaining('Choose one primary strategy'), findsNothing);
    expect(find.textContaining('Switching to maintain'), findsNothing);
    expect(find.textContaining('Product defaults'), findsNothing);
    // The active strategy is marked with a "Current" chip, not a radio.
    expect(find.text('Current'), findsOneWidget);

    await tester.tap(rules);
    await _settle(tester);
    expect(tester.getSemantics(rules).label, 'Rules, Collapse');
    expect(find.textContaining('A 3-5 day cycle'), findsOneWidget);
    expect(find.textContaining('Choose one primary strategy'), findsOneWidget);
    expect(find.textContaining('Switching to maintain'), findsOneWidget);
    expect(find.textContaining('Product defaults'), findsOneWidget);

    await tester.tap(rules);
    await _settle(tester);
    expect(tester.getSemantics(rules).label, 'Rules, Expand');
    expect(find.textContaining('Choose one primary strategy'), findsNothing);
    expect(find.textContaining('Start at the baseline'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    _expectNoLayoutErrors(tester);
    semantics.dispose();
  });

  for (final themeId in [AppThemeId.fresh, AppThemeId.graphite]) {
    testWidgets('picker rules fit ${themeId.name} at 360px', (tester) async {
      await _pump(tester, '/profile/nutrition/strategy', themeId: themeId);
      await tester.tap(find.byKey(const ValueKey('strategyPickerRules')));
      await _settle(tester);
      expect(find.textContaining('Product defaults'), findsOneWidget);
      _expectNoLayoutErrors(tester);
    });
  }

  testWidgets('configure uses read-only profile metrics and back returns', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy');
    await tester.tap(find.text('Balanced deficit'));
    await _settle(tester);

    expect(find.byKey(const ValueKey('strategyReferenceWeight')), findsNothing);
    await _openStrategySection(tester, 'strategy-section-profile');

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
    expect(find.text('75.0'), findsOneWidget);
    expect(find.text('2400'), findsOneWidget);

    await _openStrategySection(tester, 'strategy-section-target');
    final energy = find.byKey(const ValueKey('strategyAverageTargetEnergy'));
    // Opening another section keeps the profile section open.
    expect(weight, findsOneWidget);
    expect(energy, findsOneWidget);
    expect(
      find.descendant(of: energy, matching: find.byType(TextField)),
      findsNothing,
    );

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(find.text('Fat-loss strategy'), findsOneWidget);
  });

  testWidgets('carb cycle shows the same read-only profile metrics', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    expect(find.byKey(const ValueKey('strategyReferenceWeight')), findsNothing);
    await _openStrategySection(tester, 'strategy-section-profile');
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
      expect(find.byType(Slider), findsNothing);
      await _openStrategySection(tester, 'strategy-section-target');
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 240);
      expect(slider.max, 480);
      expect(slider.divisions, 10);
      expect(find.textContaining('Allowed'), findsNothing);
    }
  });

  testWidgets('configuration keeps edited values while sections switch', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=balanced');
    expect(find.byType(Slider), findsNothing);
    final summary = find.byKey(const ValueKey('strategyTopSummary'));
    final before = tester.widget<Text>(summary).data;
    await _openStrategySection(tester, 'strategy-section-target');
    await tester.drag(find.byType(Slider), const Offset(70, 0));
    await _settle(tester);
    final after = tester.widget<Text>(summary).data;
    expect(after, isNot(before));
    // Sections open independently: the target stays open beside profile.
    await _openStrategySection(tester, 'strategy-section-profile');
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.widget<Text>(summary).data, after);
    // Collapse via the header row; the expanded body would take a centre tap.
    final targetSection = await _show(
      tester,
      find.byKey(const ValueKey('strategy-section-target')),
      delta: -120,
    );
    await tester.tapAt(tester.getTopLeft(targetSection) + const Offset(24, 24));
    await _settle(tester);
    expect(find.byType(Slider), findsNothing);
    expect(tester.widget<Text>(summary).data, after);
    await _openStrategySection(tester, 'strategy-section-target');
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.widget<Text>(summary).data, after);
    await _openStrategySection(tester, 'strategy-section-effective');
    await tester.tap(await _show(tester, find.text('Start today')));
    await _settle(tester);
    expect(
      await _show(tester, find.textContaining('Apply from'), delta: -120),
      findsOneWidget,
    );
    _expectNoLayoutErrors(tester);
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('compact strategy flow fits ${themeId.name} at 360px', (
      tester,
    ) async {
      await _pump(tester, '/profile/nutrition/strategy', themeId: themeId);
      await tester.tap(find.text('Carb cycling'));
      await _settle(tester);
      expect(find.byKey(const ValueKey('strategyTopSummary')), findsOneWidget);
      expect(find.byKey(const ValueKey('cycleDay-0')), findsNothing);
      _expectNoLayoutErrors(tester);
    });
  }

  testWidgets('carb cycle configure → apply today → Today hero follows plan', (
    tester,
  ) async {
    await _pump(tester, '/profile/nutrition/strategy/configure?kind=carbCycle');
    _expectNoLayoutErrors(tester);
    expect(find.byKey(const ValueKey('cycleDay-1')), findsNothing);
    await _openStrategySection(tester, 'strategy-section-schedule');

    // Tap day 1 (low -> mid) and confirm the high-day carb stepper itself
    // switches to the compensated effective rate, with a "[Modified]"
    // marker on its label (not a separate note line).
    await tester.tap(
      await _show(tester, find.byKey(const ValueKey('cycleDay-1'))),
    );
    await _settle(tester);
    await _openStrategySection(tester, 'strategy-section-high');
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
    expect(find.text('${effective.toStringAsFixed(1)} g/kg'), findsOneWidget);

    await _openStrategySection(tester, 'strategy-section-effective');
    await tester.tap(await _show(tester, find.text('Start today')));
    await _settle(tester);
    final apply = await _show(
      tester,
      find.textContaining('Apply from'),
      delta: -120,
    );
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
        CalendarDay.addDays(today, i),
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
        CalendarDay.addDays(today, cycleLength - 1),
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
    // No observation/review gating — every reachable stage is listed flat
    // and immediately tappable (other than the current one).
    expect(find.byKey(const ValueKey('taperOverviewCard')), findsOneWidget);
    expect(find.textContaining('Stage 0'), findsWidgets);
    expect(find.byKey(const ValueKey('taperStageSection')), findsOneWidget);
    expect(find.textContaining('Stage 1'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is InkIcon && widget.glyph == InkGlyph.chevronRight,
      ),
      findsWidgets,
    );
    // Rules open beside the stages; both stay expanded.
    await _openStrategySection(tester, 'taperRulesSection');
    expect(find.textContaining('Stage 1'), findsWidgets);
    expect(
      find.textContaining('Each stage reduces carbohydrate'),
      findsOneWidget,
    );
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
    // The empty state hides "Choose strategy" while eligibility is blocked
    // and lists the reason instead.
    expect(find.byKey(const ValueKey('noStrategyEmpty')), findsOneWidget);
    expect(find.text('Choose strategy'), findsNothing);
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
    expect(find.byKey(const ValueKey('noStrategyEmpty')), findsOneWidget);
    expect(find.text('Choose strategy'), findsNothing);
    expect(find.text('Only available with the cut goal.'), findsOneWidget);
  });
}
