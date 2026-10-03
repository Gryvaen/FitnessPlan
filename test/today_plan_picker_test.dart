import 'package:diet/data/db.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/today/today_workout_card.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final bench = await _db
      .into(_db.exercises)
      .insertReturning(
        ExercisesCompanion.insert(
          name: '杠铃卧推',
          unit: 'reps',
          category: const Value('chest'),
        ),
      );
  final squat = await _db
      .into(_db.exercises)
      .insertReturning(
        ExercisesCompanion.insert(
          name: '深蹲',
          unit: 'reps',
          category: const Value('legs'),
        ),
      );
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
          targetSets: 4,
          targetReps: 8,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_setUp);
  tearDown(() async {
    _container.dispose();
    await _db.close();
  });

  testWidgets('today workout plus groups plans under exercise categories', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayWorkoutCard(
              day: CalendarDay.todayLocal(),
              sectionPrefix: '今日',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('添加今日训练'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('today-plan-category-filter')),
      findsNothing,
    );

    final chest = tester.getTopLeft(find.text('胸')).dy;
    final upper = tester.getTopLeft(find.text('上肢')).dy;
    final legs = tester.getTopLeft(find.text('腿')).dy;
    final lower = tester.getTopLeft(find.text('腿部')).dy;
    expect(chest, lessThan(upper));
    expect(upper, lessThan(legs));
    expect(legs, lessThan(lower));
  });

  testWidgets('dragging a planned exercise out of its plan files it under 其他', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _container.read(workoutRepositoryProvider);
    final day = CalendarDay.todayLocal();
    final plans = await repo.listPlanSummaries();
    final upper = plans.firstWhere((plan) => plan.plan.name == '上肢');
    await repo.applyPlanToDay(planId: upper.plan.id, day: day);
    final itemId = (await repo.daySnapshot(day)).items.single.item.id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayWorkoutCard(
              day: day,
              sectionPrefix: '今日',
              showDetails: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('上肢'), findsOneWidget);
    expect(find.text('移到其他'), findsNothing);
    expect(find.text('其他'), findsNothing);

    final handle = find.byKey(ValueKey('day-workout-item-handle-$itemId'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 500));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('上肢'), findsNothing);
    expect(find.text('其他'), findsOneWidget);
    expect(find.text('杠铃卧推'), findsOneWidget);
    expect(await repo.itemsFor(upper.plan.id), isEmpty);
    expect(
      (await repo.listPlanSummaries()).map((plan) => plan.plan.name),
      isNot(contains('其他')),
    );
  });

  testWidgets('reordering inside a plan keeps the exercise in that plan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fly = await _db
        .into(_db.exercises)
        .insertReturning(
          ExercisesCompanion.insert(
            name: '哑铃飞鸟',
            unit: 'reps',
            category: const Value('chest'),
          ),
        );
    final repo = _container.read(workoutRepositoryProvider);
    final day = CalendarDay.todayLocal();
    final plans = await repo.listPlanSummaries();
    final upper = plans.firstWhere((plan) => plan.plan.name == '上肢');
    await _db
        .into(_db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: upper.plan.id,
            exerciseId: fly.id,
            exerciseName: fly.name,
            targetSets: 3,
            targetReps: 12,
            sortOrder: const Value(1),
          ),
        );
    await repo.applyPlanToDay(planId: upper.plan.id, day: day);
    final items = (await repo.daySnapshot(day)).items;
    final benchId = items
        .firstWhere((progress) => progress.item.exerciseName == '杠铃卧推')
        .item
        .id;
    final flyId = items
        .firstWhere((progress) => progress.item.exerciseName == '哑铃飞鸟')
        .item
        .id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayWorkoutCard(
              day: day,
              sectionPrefix: '今日',
              showDetails: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final start = tester.getCenter(
      find.byKey(ValueKey('day-workout-item-handle-$benchId')),
    );
    final secondRow = tester.getRect(
      find.byKey(ValueKey('day-workout-item-$flyId')),
    );
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    // Land on the next row, still inside the list. The lifted row only swaps
    // once its bottom sits in the lower half of that row.
    await gesture.moveTo(Offset(start.dx, secondRow.top + 8));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('上肢'), findsOneWidget);
    expect(find.text('其他'), findsNothing);
    final names = [
      for (final progress in (await repo.daySnapshot(day)).items)
        progress.item.exerciseName,
    ];
    expect(names, ['哑铃飞鸟', '杠铃卧推']);
  });

  testWidgets('dragging the only 其他 exercise onto a plan files it there', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final plank = await _db
        .into(_db.exercises)
        .insertReturning(
          ExercisesCompanion.insert(
            name: '平板支撑',
            unit: 'seconds',
            category: const Value('core'),
          ),
        );
    final repo = _container.read(workoutRepositoryProvider);
    final day = CalendarDay.todayLocal();
    final plans = await repo.listPlanSummaries();
    final upper = plans.firstWhere((plan) => plan.plan.name == '上肢');
    await repo.applyPlanToDay(planId: upper.plan.id, day: day);
    await repo.addQuickDayItem(
      day: day,
      exerciseId: plank.id,
      targetSets: 2,
      targetReps: 45,
    );
    final itemId = (await repo.daySnapshot(
      day,
    )).groups.last.items.single.item.id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayWorkoutCard(
              day: day,
              sectionPrefix: '今日',
              showDetails: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('其他'), findsOneWidget);
    final handle = tester.getCenter(
      find.byKey(ValueKey('day-workout-item-handle-$itemId')),
    );
    final planTitle = tester.getCenter(find.text('上肢'));
    final gesture = await tester.startGesture(handle);
    await tester.pump();
    await gesture.moveBy(const Offset(0, -24));
    await tester.pump();
    await gesture.moveTo(planTitle);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('其他'), findsNothing);
    expect(find.text('上肢'), findsOneWidget);
    expect(find.text('杠铃卧推'), findsOneWidget);
    expect(find.text('平板支撑'), findsOneWidget);
    final names = [
      for (final progress in (await repo.daySnapshot(day)).items)
        progress.item.exerciseName,
    ];
    expect(names, ['杠铃卧推', '平板支撑']);
    expect(
      (await repo.itemsFor(upper.plan.id)).map((item) => item.exerciseName),
      ['杠铃卧推', '平板支撑'],
    );
  });

  testWidgets('dragging an exercise onto another plan moves it there', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _container.read(workoutRepositoryProvider);
    final day = CalendarDay.todayLocal();
    final plans = await repo.listPlanSummaries();
    final upper = plans.firstWhere((plan) => plan.plan.name == '上肢');
    final legs = plans.firstWhere((plan) => plan.plan.name == '腿部');
    await repo.applyPlanToDay(planId: upper.plan.id, day: day);
    await repo.applyPlanToDay(planId: legs.plan.id, day: day);
    final squatId = (await repo.daySnapshot(
      day,
    )).groups.last.items.single.item.id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayWorkoutCard(
              day: day,
              sectionPrefix: '今日',
              showDetails: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final handle = tester.getCenter(
      find.byKey(ValueKey('day-workout-item-handle-$squatId')),
    );
    final planTitle = tester.getCenter(find.text('上肢'));
    final gesture = await tester.startGesture(handle);
    await tester.pump();
    await gesture.moveBy(const Offset(0, -24));
    await tester.pump();
    await gesture.moveTo(planTitle);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('腿部'), findsNothing);
    expect(find.text('上肢'), findsOneWidget);
    expect(find.text('其他'), findsNothing);
    final names = [
      for (final progress in (await repo.daySnapshot(day)).items)
        progress.item.exerciseName,
    ];
    expect(names, ['杠铃卧推', '深蹲']);
    expect(
      (await repo.itemsFor(upper.plan.id)).map((item) => item.exerciseName),
      ['杠铃卧推', '深蹲'],
    );
    expect(await repo.itemsFor(legs.plan.id), isEmpty);
  });
}
