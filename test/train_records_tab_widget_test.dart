import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/step_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/providers/step_providers.dart';
import 'package:diet/providers/workout_providers.dart';
import 'package:diet/ui/records/train_records_tab.dart';
import 'package:diet/ui/shell/swipe_tab_view.dart';
import 'package:diet/ui/theme/sport_chrome.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Regression coverage for the CustomScrollView/SliverList.builder rewrite of
// the exercise library search panel and the "全部" history bottom sheets
// (lib/ui/records/train_records_tab.dart) — these previously built every
// matching row eagerly via ListView(children:)/a plain Column; confirms the
// lazy rewrite still filters/renders correctly, not just that it's lazy.

late AppDatabase _db;
late ProviderContainer _container;

Future<void> _setUp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  _container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(_db),
    ],
  );
  await _db
      .into(_db.exercises)
      .insert(
        ExercisesCompanion.insert(
          name: '杠铃卧推',
          unit: 'reps',
          category: const Value('chest'),
        ),
      );
  await _db
      .into(_db.exercises)
      .insert(
        ExercisesCompanion.insert(
          name: '深蹲',
          unit: 'reps',
          category: const Value('legs'),
        ),
      );
  await _db
      .into(_db.exercises)
      .insert(
        ExercisesCompanion.insert(
          name: '跑步机慢跑',
          unit: 'seconds',
          category: const Value('cardio'),
        ),
      );
}

Widget _app(Widget child) {
  // TrainRecordsTab reads GoRouterState (deep-link `?tab=&sub=` sync), so it
  // needs a real router under it, not a bare MaterialApp — matches the
  // '/records' location _syncSubFromRoute checks for.
  final router = GoRouter(
    initialLocation: '/records',
    routes: [
      GoRoute(
        path: '/records',
        builder: (_, _) => Scaffold(body: child),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: _container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(child));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_setUp);
  tearDown(() async {
    _container.dispose();
    await _db.close();
  });

  testWidgets(
    'exercise library search and category menu narrow the lazily-rendered list',
    (tester) async {
      // Matches only the exercise row, not the search TextField's own
      // echoed text once it contains the same string.
      Finder row(String name) => find.widgetWithText(SportListTile, name);

      await _pump(tester, const TrainRecordsTab(initialTab: 1));

      expect(row('杠铃卧推'), findsOneWidget);
      expect(row('深蹲'), findsOneWidget);
      expect(row('跑步机慢跑'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byKey(const ValueKey('exercise-library-search')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isFalse,
      );
      await tester.tapAt(const Offset(380, 24));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byKey(const ValueKey('exercise-library-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '深蹲');
      await tester.pumpAndSettle();
      expect(row('深蹲'), findsOneWidget);
      expect(row('杠铃卧推'), findsNothing);
      expect(row('跑步机慢跑'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(row('杠铃卧推'), findsOneWidget);
      expect(row('深蹲'), findsOneWidget);
      expect(row('跑步机慢跑'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('exercise-category-filter')));
      await tester.pumpAndSettle();
      expect(find.text('其他'), findsNothing);
      await tester.tap(find.text('腿'));
      await tester.pumpAndSettle();
      expect(row('深蹲'), findsOneWidget);
      expect(row('杠铃卧推'), findsNothing);
      expect(row('跑步机慢跑'), findsNothing);

      final search = find.byKey(const ValueKey('exercise-library-search'));
      if (search.evaluate().isNotEmpty) {
        await tester.tap(search);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('exercise-category-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();
      expect(row('杠铃卧推'), findsOneWidget);
      expect(row('深蹲'), findsOneWidget);
      expect(row('跑步机慢跑'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('exercise-library-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '卧推');
      await tester.pumpAndSettle();
      expect(row('杠铃卧推'), findsOneWidget);
      expect(row('深蹲'), findsNothing);

      // Tapping the field itself keeps the query; blank space clears it.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(row('杠铃卧推'), findsOneWidget);
      expect(row('深蹲'), findsNothing);

      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(row('杠铃卧推'), findsOneWidget);
      expect(row('深蹲'), findsOneWidget);
      expect(row('跑步机慢跑'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('exercise-library-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('exercise-category-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('腿'));
      await tester.pumpAndSettle();
      expect(row('深蹲'), findsOneWidget);
      expect(row('杠铃卧推'), findsNothing);

      await tester.tap(row('深蹲'));
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(row('深蹲'), findsOneWidget);
      expect(row('杠铃卧推'), findsNothing);

      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(row('深蹲'), findsOneWidget);
      expect(row('杠铃卧推'), findsNothing);
      expect(row('跑步机慢跑'), findsNothing);
    },
  );

  testWidgets('add exercise uses the selected category filter', (tester) async {
    Finder row(String name) => find.widgetWithText(SportListTile, name);

    await _pump(tester, const TrainRecordsTab(initialTab: 1));
    await tester.tap(find.byKey(const ValueKey('exercise-library-search')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('腿'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('添加动作'));
    await tester.pumpAndSettle();
    expect(find.text('腿'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(row('深蹲'), findsOneWidget);
    expect(row('杠铃卧推'), findsNothing);
    expect(row('跑步机慢跑'), findsNothing);
  });

  testWidgets('saving an exercise edit keeps the category filter', (
    tester,
  ) async {
    Finder row(String name) => find.widgetWithText(SportListTile, name);

    await _pump(tester, const TrainRecordsTab(initialTab: 1));
    await tester.tap(find.byKey(const ValueKey('exercise-library-search')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('腿'));
    await tester.pumpAndSettle();
    expect(row('深蹲'), findsOneWidget);
    expect(row('杠铃卧推'), findsNothing);

    await tester.tap(row('深蹲'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(row('深蹲'), findsOneWidget);
    expect(row('杠铃卧推'), findsNothing);
    expect(row('跑步机慢跑'), findsNothing);
  });

  testWidgets('plan search filters the list and blank space clears it', (
    tester,
  ) async {
    Finder row(String name) => find.widgetWithText(SportListTile, name);

    final bench = await (_db.select(
      _db.exercises,
    )..where((t) => t.name.equals('杠铃卧推'))).getSingle();
    final squat = await (_db.select(
      _db.exercises,
    )..where((t) => t.name.equals('深蹲'))).getSingle();
    final upperId = await _db
        .into(_db.workoutPlans)
        .insert(
          WorkoutPlansCompanion.insert(name: '上肢', createdAt: DateTime.now()),
        );
    await _db
        .into(_db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: upperId,
            exerciseId: bench.id,
            exerciseName: bench.name,
            targetSets: 3,
            targetReps: 12,
          ),
        );
    final legsId = await _db
        .into(_db.workoutPlans)
        .insert(
          WorkoutPlansCompanion.insert(name: '腿部', createdAt: DateTime.now()),
        );
    await _db
        .into(_db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: legsId,
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 3,
            targetReps: 10,
          ),
        );

    await _pump(tester, const TrainRecordsTab());

    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('plan-search')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isFalse,
    );
    // Keyboard never came up. Blank space outside the plan list — here the
    // empty area beside the sub-tabs — still closes the field.
    await tester.tapAt(const Offset(380, 24));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('plan-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '上肢');
    await tester.pumpAndSettle();
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsNothing);

    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的计划'), findsOneWidget);
    expect(row('上肢'), findsNothing);
    expect(row('腿部'), findsNothing);

    await tester.tapAt(const Offset(200, 700));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan-search')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-category-filter')));
    await tester.pumpAndSettle();
    expect(find.text('其他'), findsNothing);
    await tester.tap(find.text('腿'));
    await tester.pumpAndSettle();
    expect(row('腿部'), findsOneWidget);
    expect(row('上肢'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('plan-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);
    await tester.tapAt(const Offset(200, 700));
    await tester.pumpAndSettle();

    final plank = await _db
        .into(_db.exercises)
        .insertReturning(
          ExercisesCompanion.insert(
            name: '平板支撑',
            unit: 'seconds',
            category: const Value('core'),
          ),
        );
    final coreOnlyId = await _db
        .into(_db.workoutPlans)
        .insert(
          WorkoutPlansCompanion.insert(name: '核心单练', createdAt: DateTime.now()),
        );
    await _db
        .into(_db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: coreOnlyId,
            exerciseId: plank.id,
            exerciseName: plank.name,
            targetSets: 3,
            targetReps: 60,
          ),
        );
    final mixedId = await _db
        .into(_db.workoutPlans)
        .insert(
          WorkoutPlansCompanion.insert(name: '腿加核心', createdAt: DateTime.now()),
        );
    await _db
        .into(_db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: mixedId,
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 3,
            targetReps: 10,
          ),
        );
    await _db
        .into(_db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: mixedId,
            exerciseId: plank.id,
            exerciseName: plank.name,
            targetSets: 3,
            targetReps: 45,
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan-search')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('核心'));
    await tester.pumpAndSettle();
    expect(row('核心单练'), findsOneWidget);
    expect(row('腿加核心'), findsNothing);
    expect(row('上肢'), findsNothing);
    await tester.tapAt(const Offset(200, 700));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(row('核心单练'), findsOneWidget);
    expect(row('腿加核心'), findsNothing);
    expect(row('上肢'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('plan-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '上肢');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
    await tester.tap(find.text('动作库'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('exercise-library-search')),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => field.focusNode?.hasFocus != true),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('exercise-library-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '深蹲');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
    await tester.tap(find.text('计划'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-search')), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => field.focusNode?.hasFocus != true),
      isTrue,
    );
  });

  testWidgets(
    '全部 step history sheet lists every logged day via the lazy ListView.builder',
    (tester) async {
      final stepRepo = StepRepository(_db);
      final today = CalendarDay.todayLocal();
      final longAgo = today.subtract(const Duration(days: 13));
      await stepRepo.setStepsForDay(today, 4000);
      await stepRepo.setStepsForDay(longAgo, 6000);

      // Resolve (and, via `listen`, keep alive) the history streams through
      // the container *before* the widget ever mounts. Landing directly on
      // `initialTab: 2` while these are still AsyncLoading races
      // _ensureTrainTabAvailable's "no history yet" check against them
      // resolving a moment later — a separate, narrower timing issue from
      // what this test is actually covering (the ListView.builder rewrite).
      final keepAlive = [
        _container.listen(recentStepsProvider, (_, _) {}),
        _container.listen(allStepsProvider, (_, _) {}),
        _container.listen(workoutHistoryProvider, (_, _) {}),
        _container.listen(allWorkoutHistoryProvider, (_, _) {}),
      ];
      addTearDown(() {
        for (final s in keepAlive) {
          s.close();
        }
      });
      await _container.read(recentStepsProvider.future);
      await _container.read(allStepsProvider.future);
      await _container.read(workoutHistoryProvider.future);
      await _container.read(allWorkoutHistoryProvider.future);

      await _pump(tester, const TrainRecordsTab(initialTab: 2));

      // Two scopes are now available ("最近"/"全部", 13 days apart) — jump
      // straight to "全部" via the scope SportTabs (disambiguated from the
      // top-level 计划/动作库/历史 SportTabs by its item labels) rather than
      // tapping possibly-ambiguous "全部" text.
      final scopeTabs = tester
          .widgetList<SportTabs<int>>(find.byType(SportTabs<int>))
          .firstWhere((w) => w.items.values.contains('全部'));
      scopeTabs.onSelected(1);
      await tester.pumpAndSettle();

      await tester.tap(find.text('全部步数'));
      await tester.pumpAndSettle();

      // The page behind the modal sheet is still mounted (its own "最近"
      // summary tile also reads "4000 步", today's count) — scope to the
      // sheet itself so this actually verifies its ListView.builder rows,
      // not just that "4000 步" appears somewhere on screen.
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('全部步数')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('4000 步')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('6000 步')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'cold deep-link straight to the history sub-tab is not bounced back to 计划 while streams resolve',
    (tester) async {
      final stepRepo = StepRepository(_db);
      final today = CalendarDay.todayLocal();
      final longAgo = today.subtract(const Duration(days: 13));
      await stepRepo.setStepsForDay(today, 4000);
      await stepRepo.setStepsForDay(longAgo, 6000);

      // Deliberately no pre-resolution here (unlike the test above) — this
      // is exactly the race `_onTrainHistoryAvailabilityChanged` (driven by
      // `ref.listen`, not a `postFrameCallback` poll) has to get right: on
      // the very first build the history streams are still `AsyncLoading`,
      // and the fix must not mistake that for "no history" and bounce the
      // user to 计划 before they resolve.
      await _pump(tester, const TrainRecordsTab(initialTab: 2));

      // Assert against the actual state (SwipeTabView.index, driven by
      // TrainRecordsTab's `_tab`/`tab` computation) rather than which pages
      // happen to be built/retained on screen: `keepPagesAlive: true` +
      // PageView animating from page 0 (the very first build's index,
      // forced down while `showHistory` was still resolving) through to
      // page 2 legitimately builds-and-retains page 1's content along the
      // way, which would make a "is 动作库's content gone" check flaky for
      // reasons unrelated to this fix. `index == 2` here is exactly what
      // `_onTrainHistoryAvailabilityChanged` bouncing to 0 would break.
      final trainTabs = tester
          .widgetList<SwipeTabView>(find.byType(SwipeTabView))
          .where((w) => w.children.length == 3);
      expect(trainTabs, isNotEmpty);
      expect(trainTabs.single.index, 2);
    },
  );

  testWidgets(
    'a day with many plans opens the workout history sheet without a layout exception',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final today = CalendarDay.todayLocal();
      const names = [
        '胸部推举计划甲',
        '背部划船计划乙',
        '肩部推举计划丙',
        '腿部深蹲计划丁',
        '手臂弯举计划戊',
        '核心卷腹计划己',
      ];
      for (var i = 0; i < names.length; i++) {
        final workoutId = await _db
            .into(_db.dayWorkouts)
            .insert(
              DayWorkoutsCompanion.insert(
                date: today,
                planId: Value(i + 1),
                planName: Value(names[i]),
                sortOrder: Value(i),
              ),
            );
        await _db
            .into(_db.dayWorkoutItems)
            .insert(
              DayWorkoutItemsCompanion.insert(
                dayWorkoutId: workoutId,
                exerciseId: 1,
                exerciseName: '杠铃卧推',
                targetSets: 1,
                targetReps: 12,
                done: const Value(true),
              ),
            );
      }

      final keepAlive = [
        _container.listen(recentStepsProvider, (_, _) {}),
        _container.listen(allStepsProvider, (_, _) {}),
        _container.listen(workoutHistoryProvider, (_, _) {}),
        _container.listen(allWorkoutHistoryProvider, (_, _) {}),
      ];
      addTearDown(() {
        for (final s in keepAlive) {
          s.close();
        }
      });
      await _container.read(workoutHistoryProvider.future);

      await _pump(tester, const TrainRecordsTab(initialTab: 2));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('最近训练'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.textContaining('胸部推举计划甲')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.textContaining('核心卷腹计划己')),
        findsOneWidget,
      );
    },
  );
}
