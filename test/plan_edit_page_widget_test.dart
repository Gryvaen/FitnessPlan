import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/records/plan_edit_page.dart';
import 'package:diet/ui/today/today_workout_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Reproduces the "首页今日训练 → 查看详情 → 点计划名字行" entry point
// (today_workout_card._editGroupPlan, which pushes /records/plan?id=&syncDay=)
// to check that PlanEditPage actually pre-fills the name + exercise rows
// instead of opening empty.

late AppDatabase _db;
late WorkoutRepository _repo;
late ProviderContainer _container;

Future<void> _setUp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  _repo = WorkoutRepository(_db);
  _container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(_db),
    ],
  );
}

Widget _app(Widget child) {
  final router = GoRouter(
    initialLocation: '/plan',
    routes: [GoRoute(path: '/plan', builder: (_, _) => child)],
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

Widget _detailsNavigationApp(DateTime day) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showDayWorkoutDetails(context, day),
              child: const Text('打开训练详情'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/records/plan',
        builder: (context, state) {
          final planId = int.parse(state.uri.queryParameters['id']!);
          final syncDay = DateTime.parse(state.uri.queryParameters['syncDay']!);
          return PlanEditPage(planId: planId, syncDay: syncDay);
        },
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

void main() {
  setUp(_setUp);
  tearDown(() async {
    _container.dispose();
    await _db.close();
  });

  testWidgets(
    'opening via a day-workout group tile (with syncDay) fills the plan '
    'name and its exercises instead of showing an empty form',
    (tester) async {
      final pushupId = await _repo.addCustomExercise(
        name: '俯卧撑',
        unit: ExerciseUnit.reps,
        category: 'chest',
      );
      final squatId = await _repo.addCustomExercise(
        name: '深蹲',
        unit: ExerciseUnit.reps,
        category: 'legs',
      );
      final planId = await _repo.createPlan(
        name: '上肢计划',
        items: [
          PlanDraftItem(
            exerciseId: pushupId,
            exerciseName: '俯卧撑',
            targetSets: 3,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squatId,
            exerciseName: '深蹲',
            targetSets: 4,
            targetReps: 8,
          ),
        ],
      );
      final today = CalendarDay.todayLocal();
      await _repo.applyPlanToDay(planId: planId, day: today);

      await tester.pumpWidget(
        _app(PlanEditPage(planId: planId, syncDay: today)),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '上肢计划'), findsOneWidget);
      expect(find.text('俯卧撑'), findsOneWidget);
      expect(find.text('深蹲'), findsOneWidget);
    },
  );

  testWidgets(
    'leaving a plan opened from workout details restores the details and '
    'allows editing again',
    (tester) async {
      final pushupId = await _repo.addCustomExercise(
        name: '俯卧撑',
        unit: ExerciseUnit.reps,
        category: 'chest',
      );
      final planId = await _repo.createPlan(
        name: '上肢计划',
        items: [
          PlanDraftItem(
            exerciseId: pushupId,
            exerciseName: '俯卧撑',
            targetSets: 3,
            targetReps: 10,
          ),
        ],
      );
      final today = CalendarDay.todayLocal();
      await _repo.applyPlanToDay(planId: planId, day: today);

      await tester.pumpWidget(_detailsNavigationApp(today));
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开训练详情'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('上肢计划'));
      await tester.pumpAndSettle();
      expect(find.text('编辑计划'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('上肢计划'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.tap(find.text('上肢计划'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '上肢计划 2');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('上肢计划 2'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.tap(find.text('上肢计划 2'));
      await tester.pumpAndSettle();
      expect(find.text('编辑计划'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'opening via the 计划 tab (no syncDay) also fills the plan name and '
    'template exercises',
    (tester) async {
      final pushupId = await _repo.addCustomExercise(
        name: '俯卧撑',
        unit: ExerciseUnit.reps,
        category: 'chest',
      );
      final planId = await _repo.createPlan(
        name: '上肢计划',
        items: [
          PlanDraftItem(
            exerciseId: pushupId,
            exerciseName: '俯卧撑',
            targetSets: 3,
            targetReps: 10,
          ),
        ],
      );

      await tester.pumpWidget(_app(PlanEditPage(planId: planId)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '上肢计划'), findsOneWidget);
      expect(find.text('俯卧撑'), findsOneWidget);
    },
  );

  testWidgets(
    'saving from the 计划 tab (no syncDay) still syncs today when the plan '
    'has already been "开始记录"-ed',
    (tester) async {
      final pushupId = await _repo.addCustomExercise(
        name: '俯卧撑',
        unit: ExerciseUnit.reps,
        category: 'chest',
      );
      final planId = await _repo.createPlan(
        name: '上肢计划',
        items: [
          PlanDraftItem(
            exerciseId: pushupId,
            exerciseName: '俯卧撑',
            targetSets: 3,
            targetReps: 10,
          ),
        ],
      );
      final today = CalendarDay.todayLocal();
      await _repo.applyPlanToDay(planId: planId, day: today);

      // Entered without syncDay, like tapping a plan in the 计划 tab list.
      await tester.pumpWidget(_app(PlanEditPage(planId: planId)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '上肢计划2');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final snap = await _repo.daySnapshot(today);
      expect(snap.groups.single.workout.planName, '上肢计划2');
    },
  );
}
