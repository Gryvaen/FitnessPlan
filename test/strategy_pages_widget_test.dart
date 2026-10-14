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
    expect(find.text('Fat-loss strategy'), findsOneWidget);
    expect(find.text('No strategy'), findsOneWidget);
    expect(find.text('Stop strategy'), findsNothing);
  });

  testWidgets('weight change suggests review without changing saved plan', (
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
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsOneWidget);
    expect(find.textContaining('Current weight 72.7 kg'), findsOneWidget);
    expect((await repo.activePlan())!.estimatedTdee, original.estimatedTdee);
    expect(
      (await repo.targetForDay(today, updated))!.calories,
      originalTarget.calories,
    );
    await tester.tap(
      await _show(tester, find.byKey(const ValueKey('activeStrategyDetails'))),
    );
    await _settle(tester);
    expect(find.text('This plan’s baseline'), findsOneWidget);
    expect(find.textContaining('Ref. weight 75.0 kg'), findsOneWidget);
    await tester.tap(await _show(tester, find.text('Review strategy')));
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
    expect(find.text('Proposed target'), findsOneWidget);
    expect(find.textContaining('Apply from'), findsOneWidget);
    _expectNoLayoutErrors(tester);
  });

  testWidgets('matching scheduled plan shows disabled scheduled status', (
    tester,
  ) async {
    final tomorrow = CalendarDay.todayLocal().add(const Duration(days: 1));
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

  testWidgets('review prompt dismissal persists until another 3% change', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.balanced);
    await _pump(tester, '/profile/nutrition');
    await _container.read(profileProvider.notifier).applyLatestWeight(72.7);
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsOneWidget);
    await tester.tap(await _show(tester, find.text('Later')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);
    _container.invalidate(strategyReviewDismissalProvider);
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);

    await _container.read(profileProvider.notifier).applyLatestWeight(70.6);
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);
    await _container.read(profileProvider.notifier).applyLatestWeight(70.5);
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsOneWidget);
    _expectNoLayoutErrors(tester);
  });

  testWidgets('future strategy does not suggest review', (tester) async {
    await _createPlan(
      DietStrategyKind.balanced,
      effectiveFrom: CalendarDay.todayLocal().add(const Duration(days: 1)),
    );
    await _pump(tester, '/profile/nutrition');
    await _container.read(profileProvider.notifier).applyLatestWeight(70);
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);
  });

  for (final field in ['sex', 'age', 'height', 'weight', 'activity']) {
    testWidgets('saving $field in profile suggests strategy review', (
      tester,
    ) async {
      await _createPlan(DietStrategyKind.balanced);
      final savedPlan = (await _container
          .read(dietStrategyRepositoryProvider)
          .activePlan())!;
      await _pump(tester, '/profile/edit');
      switch (field) {
        case 'sex':
          tester
              .widget<AppDropdown<Sex>>(find.byType(AppDropdown<Sex>))
              .onChanged(Sex.female);
        case 'age':
          tester
              .widget<AppDropdown<int>>(find.byType(AppDropdown<int>).first)
              .onChanged(31);
        case 'height':
          tester
              .widget<AppDropdown<int>>(find.byType(AppDropdown<int>).last)
              .onChanged(176);
        case 'weight':
          tester
              .widget<AppDropdown<double>>(find.byType(AppDropdown<double>))
              .onChanged(74.75);
        case 'activity':
          tester
              .widget<AppDropdown<ActivityLevel>>(
                find.byType(AppDropdown<ActivityLevel>),
              )
              .onChanged(ActivityLevel.light);
      }
      await _settle(tester);
      await tester.tap(await _show(tester, find.text('Save')));
      await _settle(tester);
      expect(
        (await _container.read(dietStrategyRepositoryProvider).activePlan())!
            .id,
        savedPlan.id,
      );
      expect(_container.read(profileStrategyReviewProvider)?.revision, 1);
      await _pump(tester, '/profile/nutrition');
      expect(find.textContaining('Profile updated'), findsOneWidget);
      expect(find.text('Compare targets'), findsOneWidget);
      _expectNoLayoutErrors(tester);
    });
  }

  testWidgets('water-only edit does not suggest nutrition review', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.balanced);
    await _pump(tester, '/profile/edit');
    await _show(tester, find.byType(AppOptionalDropdown<int>));
    tester
        .widget<AppOptionalDropdown<int>>(find.byType(AppOptionalDropdown<int>))
        .onChanged(2500);
    await _settle(tester);
    await tester.tap(await _show(tester, find.text('Save')));
    await _settle(tester);
    expect(_container.read(profileStrategyReviewProvider), isNull);
  });

  testWidgets(
    'profile review survives restart and Later only dismisses this edit',
    (tester) async {
      await _createPlan(DietStrategyKind.balanced);
      final plan = (await _container
          .read(dietStrategyRepositoryProvider)
          .activePlan())!;
      await _container.read(profileProvider.notifier).applyLatestWeight(74.75);
      await _container
          .read(profileStrategyReviewProvider.notifier)
          .record(plan);
      await _pump(tester, '/profile/nutrition');
      expect(find.text('Compare targets'), findsOneWidget);
      await tester.tap(await _show(tester, find.text('Later')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);
      _container.invalidate(profileStrategyReviewProvider);
      await _settle(tester);
      expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);
      await _container
          .read(profileStrategyReviewProvider.notifier)
          .record(plan);
      await _settle(tester);
      expect(find.text('Compare targets'), findsOneWidget);
    },
  );

  testWidgets(
    'scheduled strategy reviews a saved profile change before start',
    (tester) async {
      await _createPlan(
        DietStrategyKind.balanced,
        effectiveFrom: CalendarDay.todayLocal().add(const Duration(days: 1)),
      );
      await _pump(tester, '/profile/edit');
      tester
          .widget<AppDropdown<double>>(find.byType(AppDropdown<double>))
          .onChanged(74.75);
      await _settle(tester);
      await tester.tap(await _show(tester, find.text('Save')));
      await _settle(tester);
      await _pump(tester, '/profile/nutrition');
      expect(find.text('Compare targets'), findsOneWidget);
      await tester.tap(await _show(tester, find.text('Compare targets')));
      await _settle(tester);
      expect(find.byType(StrategyConfigurePage), findsOneWidget);
      expect(find.text('Proposed target'), findsOneWidget);
    },
  );

  testWidgets('profile and weight reviews collapse into one dismissal', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.balanced);
    final plan = (await _container
        .read(dietStrategyRepositoryProvider)
        .activePlan())!;
    await _container.read(profileProvider.notifier).applyLatestWeight(70);
    await _container.read(profileStrategyReviewProvider.notifier).record(plan);
    await _pump(tester, '/profile/nutrition');
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsOneWidget);
    expect(find.text('Compare targets'), findsOneWidget);
    await tester.tap(await _show(tester, find.text('Later')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('strategyReviewPrompt')), findsNothing);
    expect(_container.read(strategyReviewDismissalProvider)?.weightKg, 70);
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
    expect(_container.read(profileStrategyReviewProvider), isNull);
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
    for (var i = 0;
        i < 20 && _container.read(profileProvider)?.goal != FitnessGoal.maintain;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_container.read(profileProvider)?.goal, FitnessGoal.maintain);
    final ledger = _container.read(cutCultivationStateProvider);
    expect(ledger.openSegment, isNull);
    expect(ledger.frozenKcal, -500);
  });

  testWidgets(
    'failed profile save keeps the edit and creates no review event',
    (tester) async {
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
      expect(_container.read(profileStrategyReviewProvider), isNull);
    },
  );

  test('new matching version clears the prior profile review', () async {
    await _createPlan(DietStrategyKind.balanced);
    final repo = _container.read(dietStrategyRepositoryProvider);
    final first = (await repo.activePlan())!;
    final profile = await _container
        .read(profileProvider.notifier)
        .applyLatestWeight(74.75);
    await _container.read(profileStrategyReviewProvider.notifier).record(first);
    expect(
      shouldSuggestProfileStrategyReview(
        plan: first,
        profile: profile,
        review: _container.read(profileStrategyReviewProvider),
      ),
      isTrue,
    );
    final second = await repo.createPlan(
      DietStrategyPlanDraft(
        kind: DietStrategyKind.balanced,
        effectiveFrom: CalendarDay.todayLocal(),
        referenceWeightKg: profile!.weightKg,
        estimatedTdee: profile.tdee!,
        baseEnergy: profile.tdee! * (1 - first.deficitFraction),
        proteinPerKg: first.proteinPerKg,
        fatPerKg: first.fatPerKg,
      ),
    );
    expect(second.version, first.version + 1);
    expect(
      shouldSuggestProfileStrategyReview(
        plan: second,
        profile: profile,
        review: _container.read(profileStrategyReviewProvider),
      ),
      isFalse,
    );
  });

  test('review threshold covers gains and resets for a new version', () async {
    await _createPlan(DietStrategyKind.balanced);
    final repo = _container.read(dietStrategyRepositoryProvider);
    final first = (await repo.activePlan())!;
    expect(
      shouldSuggestStrategyReview(
        plan: first,
        currentWeightKg: 77.24,
        dismissal: null,
      ),
      isFalse,
    );
    expect(
      shouldSuggestStrategyReview(
        plan: first,
        currentWeightKg: 77.25,
        dismissal: null,
      ),
      isTrue,
    );
    await _container
        .read(strategyReviewDismissalProvider.notifier)
        .dismiss(first, 77.25);
    final dismissal = _container.read(strategyReviewDismissalProvider);
    expect(
      shouldSuggestStrategyReview(
        plan: first,
        currentWeightKg: 77.25,
        dismissal: dismissal,
      ),
      isFalse,
    );
    await _createPlan(DietStrategyKind.balanced);
    final second = (await repo.activePlan())!;
    expect(second.version, first.version + 1);
    expect(
      shouldSuggestStrategyReview(
        plan: second,
        currentWeightKg: 77.25,
        dismissal: dismissal,
      ),
      isTrue,
    );
  });

  for (final themeId in [AppThemeId.fresh, AppThemeId.graphite]) {
    testWidgets('review prompt fits ${themeId.name} at 360px', (tester) async {
      await _createPlan(DietStrategyKind.balanced);
      await _container.read(profileProvider.notifier).applyLatestWeight(72.7);
      await _pump(tester, '/profile/nutrition', themeId: themeId);
      expect(
        find.byKey(const ValueKey('strategyReviewPrompt')),
        findsOneWidget,
      );
      _expectNoLayoutErrors(tester);
    });
    testWidgets('profile review fits ${themeId.name} at 360px', (tester) async {
      await _createPlan(DietStrategyKind.balanced);
      final plan = (await _container
          .read(dietStrategyRepositoryProvider)
          .activePlan())!;
      await _container.read(profileProvider.notifier).applyLatestWeight(74.75);
      await _container
          .read(profileStrategyReviewProvider.notifier)
          .record(plan);
      await _pump(tester, '/profile/nutrition', themeId: themeId);
      expect(find.text('Compare targets'), findsOneWidget);
      _expectNoLayoutErrors(tester);
    });
  }

  testWidgets('carb-cycle actions expand with strategy details', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.carbCycle);
    await _pump(tester, '/profile/nutrition');

    expect(find.text('Adjust schedule'), findsNothing);
    expect(find.text('Stop strategy'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('activeStrategyDetails')));
    await _settle(tester);

    expect(find.byKey(const ValueKey('cycleDay-0')), findsNothing);
    await _openStrategySection(tester, 'activeCyclePreview');
    expect(find.byKey(const ValueKey('cycleDay-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('activeCyclePreview')));
    await _settle(tester);
    expect(find.text('Adjust schedule'), findsOneWidget);
    expect(find.text('Stop strategy'), findsOneWidget);

    await tester.tap(await _show(tester, find.text('Stop strategy')));
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

    await tester.ensureVisible(find.text('Adjust schedule'));
    await tester.tap(find.text('Adjust schedule'));
    await _settle(tester);
    await _openStrategySection(tester, 'strategy-section-profile');
    expect(
      find.byKey(const ValueKey('strategyReferenceWeight')),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);
    _expectNoLayoutErrors(tester);
  });

  testWidgets('carb-taper actions expand with strategy details', (
    tester,
  ) async {
    await _createPlan(DietStrategyKind.carbTaper);
    await _pump(tester, '/profile/nutrition');

    expect(find.text('Taper stages'), findsNothing);
    expect(find.text('Stop strategy'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('activeStrategyDetails')));
    await _settle(tester);

    expect(find.text('Taper stages'), findsOneWidget);
    expect(find.text('Stop strategy'), findsOneWidget);

    await tester.ensureVisible(find.text('Taper stages'));
    await tester.tap(find.text('Taper stages'));
    await _settle(tester);
    expect(find.textContaining('Stage 0'), findsWidgets);
    _expectNoLayoutErrors(tester);
  });

  testWidgets('scheduled strategy cancellation expands with details', (
    tester,
  ) async {
    await _createPlan(
      DietStrategyKind.carbTaper,
      effectiveFrom: CalendarDay.todayLocal().add(const Duration(days: 1)),
    );
    await _pump(tester, '/profile/nutrition');

    expect(find.text('Cancel scheduled change'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('activeStrategyDetails')));
    await _settle(tester);
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
    expect(find.textContaining('A 3-5 day cycle'), findsNothing);
    await tester.tap(find.text('Carb cycling'));
    await _settle(tester);
    expect(find.textContaining('A 3-5 day cycle'), findsOneWidget);
    expect(find.text('Configure strategy'), findsOneWidget);
    await tester.tap(find.text('Carb taper'));
    await _settle(tester);
    expect(find.textContaining('A 3-5 day cycle'), findsNothing);
    expect(find.textContaining('Start at the baseline'), findsOneWidget);
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
    expect(
      find.byWidgetPredicate(
        (widget) => widget is InkIcon && widget.glyph == InkGlyph.radioChecked,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Carb cycling'));
    await _settle(tester);
    await tester.tap(rules);
    await _settle(tester);
    expect(tester.getSemantics(rules).label, 'Rules, Collapse');
    expect(find.textContaining('A 3-5 day cycle'), findsOneWidget);
    expect(find.textContaining('Choose one primary strategy'), findsOneWidget);
    expect(find.textContaining('Switching to maintain'), findsOneWidget);
    expect(find.textContaining('Product defaults'), findsOneWidget);

    await tester.tap(find.text('Carb taper'));
    await _settle(tester);
    expect(find.textContaining('A 3-5 day cycle'), findsNothing);
    expect(find.textContaining('Start at the baseline'), findsOneWidget);
    expect(find.textContaining('Choose one primary strategy'), findsOneWidget);
    await tester.tap(rules);
    await _settle(tester);
    expect(tester.getSemantics(rules).label, 'Rules, Expand');
    expect(find.textContaining('Choose one primary strategy'), findsNothing);
    expect(find.textContaining('Start at the baseline'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is InkIcon && widget.glyph == InkGlyph.radioChecked,
      ),
      findsOneWidget,
    );
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
    await tester.tap(find.text('Configure strategy'));
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
    expect(weight, findsNothing);
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
    await _openStrategySection(tester, 'strategy-section-profile');
    expect(find.byType(Slider), findsNothing);
    expect(tester.widget<Text>(summary).data, after);
    await _openStrategySection(tester, 'strategy-section-target');
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.widget<Text>(summary).data, after);
    await _openStrategySection(tester, 'strategy-section-effective');
    expect(find.byType(Slider), findsNothing);
    await tester.tap(find.text('Start today'));
    await _settle(tester);
    expect(find.textContaining('Apply from'), findsOneWidget);
    _expectNoLayoutErrors(tester);
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('compact strategy flow fits ${themeId.name} at 360px', (
      tester,
    ) async {
      await _pump(tester, '/profile/nutrition/strategy', themeId: themeId);
      await tester.tap(find.text('Carb cycling'));
      await _settle(tester);
      expect(find.text('Configure strategy'), findsOneWidget);
      await tester.tap(find.text('Configure strategy'));
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
    expect(find.textContaining('Stage 1'), findsNothing);
    await _openStrategySection(tester, 'taperStageSection');
    expect(find.textContaining('Stage 1'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is InkIcon && widget.glyph == InkGlyph.chevronRight,
      ),
      findsWidgets,
    );
    await _openStrategySection(tester, 'taperRulesSection');
    expect(find.textContaining('Stage 1'), findsNothing);
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
