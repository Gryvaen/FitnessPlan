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

Widget _app(Widget child, {Locale locale = const Locale('zh')}) {
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
      locale: locale,
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

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  Locale locale = const Locale('zh'),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(child, locale: locale));
  await tester.pumpAndSettle();
}

Finder _row(String name) => find.widgetWithText(SportListTile, name);

/// Opens the category pill [filterKey] and picks [label]. The pill itself may
/// show the same label, so the menu item is the last match.
Future<void> _pickCategory(
  WidgetTester tester,
  String filterKey,
  String label,
) async {
  await tester.tap(find.byKey(ValueKey(filterKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder _pillLabel(String filterKey, String label) => find.descendant(
  of: find.byKey(ValueKey(filterKey)),
  matching: find.text(label),
);

/// Width of the animated container that reveals the search box [searchKey].
double _searchWidth(WidgetTester tester, String searchKey) => tester
    .getSize(
      find
          .ancestor(
            of: find.byKey(ValueKey(searchKey)),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    )
    .width;

/// Taps a collapsed search icon and waits for the box to slide open.
Future<void> _open(WidgetTester tester, String openKey) async {
  await tester.tap(find.byKey(ValueKey(openKey)));
  await tester.pumpAndSettle();
}

Finder _clearButton(String searchKey) => find.descendant(
  of: find.byKey(ValueKey(searchKey)),
  matching: find.byType(IconButton),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_setUp);
  tearDown(() async {
    _container.dispose();
    await _db.close();
  });

  testWidgets('training filters use taps and swipe the parent segment', (
    tester,
  ) async {
    var branch = 2;
    var segment = 1;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => ShellSwipe(
          currentBranch: branch,
          branchCount: 4,
          onNudge: (delta) {
            setState(() => branch += delta);
            return true;
          },
          child: SwipeTabView(
            branchIndex: 2,
            index: segment,
            onIndexChanged: (i) => setState(() => segment = i),
            children: const [
              Center(child: Text('Body segment')),
              TrainRecordsTab(),
              Center(child: Text('Notes segment')),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, '动作库'));
    await tester.pumpAndSettle();
    expect(find.text('杠铃卧推'), findsOneWidget);

    await tester.flingFrom(const Offset(200, 500), const Offset(-180, 0), 2000);
    await tester.pumpAndSettle();
    expect(segment, 2);
    expect(branch, 2);

    await tester.flingFrom(const Offset(200, 500), const Offset(180, 0), 2000);
    await tester.pumpAndSettle();
    expect(segment, 1);
    expect(find.text('杠铃卧推'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '动作库'))
          .selected,
      isTrue,
    );
  });

  testWidgets('training filter chips wrap at large text sizes', (tester) async {
    await _pump(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: TrainRecordsTab(),
      ),
    );

    expect(find.widgetWithText(ChoiceChip, '计划'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '动作库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'exercise library search and category menu narrow the lazily-rendered list',
    (tester) async {
      const searchKey = 'exercise-library-search';
      const openKey = 'exercise-library-search-open';
      const filterKey = 'exercise-category-filter';
      final search = find.byKey(const ValueKey(searchKey));

      await _pump(tester, const TrainRecordsTab(initialTab: 1));

      // At rest it is just the search icon, unfocused (no keyboard).
      expect(_searchWidth(tester, searchKey), 48);
      expect(find.byKey(const ValueKey(openKey)), findsOneWidget);
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);

      // Tapping it slides the box open to the right, without focusing it:
      // no keyboard for someone who only wants to pick a category.
      await tester.tap(find.byKey(const ValueKey(openKey)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 130));
      final midway = _searchWidth(tester, searchKey);
      await tester.pumpAndSettle();
      final full = _searchWidth(tester, searchKey);
      expect(midway, greaterThan(48));
      expect(midway, lessThan(full));
      expect(full, greaterThan(300));
      expect(find.byKey(const ValueKey(openKey)), findsNothing);
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
      expect(_pillLabel(filterKey, '全部'), findsOneWidget);
      expect(_clearButton(searchKey), findsNothing);

      // Filtering by category never brings the keyboard up either.
      await _pickCategory(tester, filterKey, '腿');
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('杠铃卧推'), findsNothing);
      await _pickCategory(tester, filterKey, '全部');

      // Only tapping the text area focuses the box.
      if (find.byKey(const ValueKey(openKey)).evaluate().isNotEmpty) {
        await _open(tester, openKey);
      }
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
      expect(_row('杠铃卧推'), findsOneWidget);
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('跑步机慢跑'), findsOneWidget);

      await tester.enterText(search, '深蹲');
      await tester.pumpAndSettle();
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('杠铃卧推'), findsNothing);
      expect(_row('跑步机慢跑'), findsNothing);

      // The clear button empties the box and restores the list.
      await tester.tap(_clearButton(searchKey));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(_clearButton(searchKey), findsNothing);
      expect(_row('杠铃卧推'), findsOneWidget);
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('跑步机慢跑'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(filterKey)));
      await tester.pumpAndSettle();
      expect(find.text('其他'), findsNothing);
      await tester.tap(find.text('腿').last);
      await tester.pumpAndSettle();
      // The filter names the active part.
      expect(_pillLabel(filterKey, '腿'), findsOneWidget);
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('杠铃卧推'), findsNothing);
      expect(_row('跑步机慢跑'), findsNothing);

      await _pickCategory(tester, filterKey, '全部');
      expect(_pillLabel(filterKey, '全部'), findsOneWidget);
      expect(_row('杠铃卧推'), findsOneWidget);
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('跑步机慢跑'), findsOneWidget);

      await tester.enterText(search, '卧推');
      await tester.pumpAndSettle();
      expect(_row('杠铃卧推'), findsOneWidget);
      expect(_row('深蹲'), findsNothing);

      // Tapping the field itself keeps the query; blank space clears it.
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(_row('杠铃卧推'), findsOneWidget);
      expect(_row('深蹲'), findsNothing);

      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      // No keyword and no category left: it folds back to the icon.
      expect(find.byKey(const ValueKey(openKey)), findsOneWidget);
      expect(_row('杠铃卧推'), findsOneWidget);
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('跑步机慢跑'), findsOneWidget);

      await _open(tester, openKey);
      await _pickCategory(tester, filterKey, '腿');
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('杠铃卧推'), findsNothing);

      await tester.tap(_row('深蹲'));
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('杠铃卧推'), findsNothing);

      // Blank space keeps the chosen category, and the box stays open.
      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey(openKey)), findsNothing);
      expect(_pillLabel(filterKey, '腿'), findsOneWidget);
      expect(_row('深蹲'), findsOneWidget);
      expect(_row('杠铃卧推'), findsNothing);
      expect(_row('跑步机慢跑'), findsNothing);
    },
  );

  testWidgets('add exercise uses the selected category filter', (tester) async {
    await _pump(tester, const TrainRecordsTab(initialTab: 1));
    await _open(tester, 'exercise-library-search-open');
    await _pickCategory(tester, 'exercise-category-filter', '腿');

    await tester.tap(find.byTooltip('添加动作'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('腿')),
      findsOneWidget,
    );

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(_row('深蹲'), findsOneWidget);
    expect(_row('杠铃卧推'), findsNothing);
    expect(_row('跑步机慢跑'), findsNothing);
  });

  testWidgets('saving an exercise edit keeps the category filter', (
    tester,
  ) async {
    await _pump(tester, const TrainRecordsTab(initialTab: 1));
    await _open(tester, 'exercise-library-search-open');
    await _pickCategory(tester, 'exercise-category-filter', '腿');
    expect(_row('深蹲'), findsOneWidget);
    expect(_row('杠铃卧推'), findsNothing);

    await tester.tap(_row('深蹲'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(_row('深蹲'), findsOneWidget);
    expect(_row('杠铃卧推'), findsNothing);
    expect(_row('跑步机慢跑'), findsNothing);
  });

  testWidgets('cancelling a plan delete keeps the search keyword', (
    tester,
  ) async {
    Finder row(String name) => find.widgetWithText(SportListTile, name);
    for (final name in ['上肢', '腿部']) {
      await _db
          .into(_db.workoutPlans)
          .insert(
            WorkoutPlansCompanion.insert(name: name, createdAt: DateTime.now()),
          );
    }
    final search = find.byKey(const ValueKey('plan-search'));
    await _pump(tester, const TrainRecordsTab());
    await _open(tester, 'plan-search-open');
    await tester.enterText(search, '上肢');
    await tester.pumpAndSettle();
    expect(row('腿部'), findsNothing);

    // The dialog is outside the search's tap region; tapping in it (here:
    // Cancel) must not clear the filter.
    await tester.tap(
      find.descendant(of: row('上肢'), matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, '上肢');
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsNothing);
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

    const searchKey = 'plan-search';
    const openKey = 'plan-search-open';
    const filterKey = 'plan-category-filter';
    final search = find.byKey(const ValueKey(searchKey));

    await _pump(tester, const TrainRecordsTab());

    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);
    expect(_searchWidth(tester, searchKey), 48);
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
    await _open(tester, openKey);
    expect(_pillLabel(filterKey, '全部'), findsOneWidget);
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);

    await tester.enterText(search, '上肢');
    await tester.pumpAndSettle();
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsNothing);

    await tester.tap(_clearButton(searchKey));
    await tester.pumpAndSettle();
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);

    await tester.enterText(search, '不存在');
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的计划'), findsOneWidget);
    expect(row('上肢'), findsNothing);
    expect(row('腿部'), findsNothing);

    await tester.tapAt(const Offset(200, 700));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(find.byKey(const ValueKey(openKey)), findsOneWidget);
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);

    await _open(tester, openKey);
    await tester.tap(find.byKey(const ValueKey(filterKey)));
    await tester.pumpAndSettle();
    expect(find.text('其他'), findsNothing);
    await tester.tap(find.text('腿').last);
    await tester.pumpAndSettle();
    expect(_pillLabel(filterKey, '腿'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);
    expect(row('上肢'), findsNothing);
    // Back to 全部 without ever typing: the idle box folds to its icon.
    await _pickCategory(tester, filterKey, '全部');
    expect(find.byKey(const ValueKey(openKey)), findsOneWidget);
    expect(row('上肢'), findsOneWidget);
    expect(row('腿部'), findsOneWidget);

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

    await _open(tester, openKey);
    await _pickCategory(tester, filterKey, '核心');
    expect(row('核心单练'), findsOneWidget);
    expect(row('腿加核心'), findsNothing);
    expect(row('上肢'), findsNothing);
    await tester.tapAt(const Offset(200, 700));
    await tester.pumpAndSettle();
    expect(_pillLabel(filterKey, '核心'), findsOneWidget);
    expect(row('核心单练'), findsOneWidget);
    expect(row('腿加核心'), findsNothing);
    expect(row('上肢'), findsNothing);

    // Back to 全部 while unfocused folds the box; open it again to type.
    await _pickCategory(tester, filterKey, '全部');
    expect(find.byKey(const ValueKey(openKey)), findsOneWidget);
    await _open(tester, openKey);
    await tester.enterText(search, '上肢');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
    await tester.tap(find.text('动作库'));
    await tester.pumpAndSettle();
    final librarySearch = find.byKey(const ValueKey('exercise-library-search'));
    expect(librarySearch, findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => field.focusNode?.hasFocus != true),
      isTrue,
    );

    await _open(tester, 'exercise-library-search-open');
    await tester.enterText(librarySearch, '深蹲');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(librarySearch).focusNode!.hasFocus, isTrue);
    await tester.tap(find.text('计划'));
    await tester.pumpAndSettle();
    expect(search, findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => field.focusNode?.hasFocus != true),
      isTrue,
    );
  });

  testWidgets('search box folds back only when idle', (tester) async {
    const openKey = 'exercise-library-search-open';
    const filterKey = 'exercise-category-filter';
    final icon = find.byKey(const ValueKey(openKey));
    Future<void> blank() async {
      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
    }

    await _pump(tester, const TrainRecordsTab(initialTab: 1));

    // Opened but left empty: blank space folds it.
    await _open(tester, openKey);
    await blank();
    expect(icon, findsOneWidget);

    // A chosen category keeps it open, so the filter stays visible.
    await _open(tester, openKey);
    await _pickCategory(tester, filterKey, '腿');
    await blank();
    expect(icon, findsNothing);
    expect(_pillLabel(filterKey, '腿'), findsOneWidget);

    // Clearing the category while unfocused folds it.
    await _pickCategory(tester, filterKey, '全部');
    expect(icon, findsOneWidget);

    // Leaving the sub-tab folds an empty box too.
    await _open(tester, openKey);
    await tester.tap(find.text('计划'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('动作库'));
    await tester.pumpAndSettle();
    expect(icon, findsOneWidget);
  });

  for (final (name, locale) in [
    ('zh', const Locale('zh')),
    ('en', const Locale('en')),
  ]) {
    testWidgets('search header fits a narrow screen with large text: $name', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        const TrainRecordsTab(initialTab: 1),
        size: const Size(320, 700),
        locale: locale,
      );
      await _open(tester, 'exercise-library-search-open');
      await _pickCategory(
        tester,
        'exercise-category-filter',
        name == 'zh' ? '肩' : 'Shoulders',
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(name == 'zh' ? '计划' : 'Plans'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    '全部 step history sheet lists every logged day via the lazy ListView.builder',
    (tester) async {
      final stepRepo = StepRepository(_db);
      final today = CalendarDay.todayLocal();
      final longAgo = CalendarDay.addDays(today, -13);
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
      expect(find.text('最近训练'), findsNothing);

      // Two scopes are now available ("最近"/"全部", 13 days apart) — jump
      // straight to "全部" via the scope chip, distinct from the top-level
      // 计划/动作库/历史 tabs.
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
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
      final longAgo = CalendarDay.addDays(today, -13);
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
    'an added training plan appears in history with zero completed actions',
    (tester) async {
      final today = CalendarDay.todayLocal();
      final workoutId = await _db
          .into(_db.dayWorkouts)
          .insert(
            DayWorkoutsCompanion.insert(
              date: today,
              planId: const Value(1),
              planName: const Value('今日测试计划'),
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
            ),
          );

      final keepAlive = [
        _container.listen(recentStepsProvider, (_, _) {}),
        _container.listen(allStepsProvider, (_, _) {}),
        _container.listen(workoutHistoryProvider, (_, _) {}),
        _container.listen(allWorkoutHistoryProvider, (_, _) {}),
      ];
      addTearDown(() {
        for (final subscription in keepAlive) {
          subscription.close();
        }
      });
      await _container.read(workoutHistoryProvider.future);
      await _container.read(allWorkoutHistoryProvider.future);

      await _pump(tester, const TrainRecordsTab(initialTab: 2));
      expect(find.text('最近训练'), findsOneWidget);
      expect(find.textContaining('今日测试计划 · 0/1'), findsOneWidget);

      await tester.tap(find.text('最近训练'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('今日测试计划 · 0/1'),
        ),
        findsOneWidget,
      );
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
