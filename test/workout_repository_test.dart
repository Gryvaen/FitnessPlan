import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/models.dart';

Future<Exercise> addTestExercise(
  WorkoutRepository repo, {
  required String name,
  ExerciseUnit unit = ExerciseUnit.reps,
  String category = 'chest',
}) async {
  final id = await repo.addCustomExercise(
    name: name,
    unit: unit,
    category: category,
  );
  final exercise = await repo.exerciseById(id);
  expect(exercise, isNotNull);
  return exercise!;
}

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('fresh database has no pre-seeded exercises', () async {
    final exercises = await repo.listExercises();
    expect(exercises, isEmpty);
    await db.seedBuiltinExercises();
    expect(await repo.listExercises(), isEmpty);
  });

  test('v13 migration removes builtin exercises', () async {
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: '内置俯卧撑',
            unit: 'reps',
            category: const Value('chest'),
            isCustom: const Value(false),
          ),
        );
    final customId = await repo.addCustomExercise(
      name: '自定义划船',
      unit: ExerciseUnit.reps,
      category: 'back',
    );

    await db.customStatement('DELETE FROM exercises WHERE is_custom = 0');

    final exercises = await repo.listExercises();
    expect(exercises, hasLength(1));
    expect(exercises.single.id, customId);
    expect(exercises.single.name, '自定义划船');
  });

  test('applyPlanToDay copies items into day snapshot', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final planId = await repo.createPlan(
      name: '上肢',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 4,
          targetReps: 12,
        ),
      ],
    );

    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: planId, day: day);

    final snap = await repo.daySnapshot(day);
    expect(snap.workout?.planName, '上肢');
    expect(snap.items, hasLength(1));
    expect(snap.items.first.item.targetSets, 4);
    expect(snap.items.first.item.targetReps, 12);
    expect(snap.items.first.completedSets, 0);
  });

  test('applyPlanToDay rejects past days', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final planId = await repo.createPlan(
      name: '过去日拒写',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 3,
          targetReps: 10,
        ),
      ],
    );
    final yesterday = CalendarDay.todayLocal().subtract(
      const Duration(days: 1),
    );
    await expectLater(
      repo.applyPlanToDay(planId: planId, day: yesterday),
      throwsA(isA<StateError>()),
    );
  });

  test('logSet auto-marks done when target sets reached', () async {
    final plank = await addTestExercise(
      repo,
      name: '平板支撑',
      unit: ExerciseUnit.seconds,
      category: 'core',
    );
    expect(ExerciseUnit.fromStorage(plank.unit), ExerciseUnit.seconds);

    final planId = await repo.createPlan(
      name: '核心',
      items: [
        PlanDraftItem(
          exerciseId: plank.id,
          exerciseName: plank.name,
          targetSets: 2,
          targetReps: 60,
        ),
      ],
    );
    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: planId, day: day);
    var snap = await repo.daySnapshot(day);
    final itemId = snap.items.first.item.id;

    await repo.logSet(
      day: day,
      exerciseId: plank.id,
      exerciseName: plank.name,
      dayWorkoutItemId: itemId,
      durationSec: 60,
    );
    snap = await repo.daySnapshot(day);
    expect(snap.items.first.completedSets, 1);
    expect(snap.items.first.item.done, isFalse);

    await repo.logSet(
      day: day,
      exerciseId: plank.id,
      exerciseName: plank.name,
      dayWorkoutItemId: itemId,
      durationSec: 55,
    );
    snap = await repo.daySnapshot(day);
    expect(snap.items.first.completedSets, 2);
    expect(snap.items.first.item.done, isTrue);
  });

  test('item writes reject a past item even when passed today', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final planId = await repo.createPlan(
      name: '日期归属校验',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 3,
          targetReps: 10,
        ),
      ],
    );
    final today = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: planId, day: today);
    final snapshot = await repo.daySnapshot(today);
    final itemId = snapshot.items.single.item.id;
    final yesterday = today.subtract(const Duration(days: 1));
    await (db.update(db.dayWorkouts)
          ..where((t) => t.id.equals(snapshot.workout!.id)))
        .write(DayWorkoutsCompanion(date: Value(yesterday)));

    await expectLater(
      repo.updateDayItemProgress(
        dayWorkoutItemId: itemId,
        day: today,
        completedSets: 1,
        perSetValue: 10,
        unit: ExerciseUnit.reps,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repo.logSet(
        day: today,
        exerciseId: pushup.id,
        exerciseName: pushup.name,
        dayWorkoutItemId: itemId,
        reps: 10,
      ),
      throwsA(isA<StateError>()),
    );

    final past = await repo.daySnapshot(yesterday);
    expect(past.items.single.completedSets, 0);
    expect(past.items.single.item.done, isFalse);
  });

  test('addCustomExercise rejects duplicate names', () async {
    await addTestExercise(repo, name: '俯卧撑');
    await expectLater(
      repo.addCustomExercise(name: '俯卧撑', unit: ExerciseUnit.reps),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('已存在同名动作'),
        ),
      ),
    );

    final id = await repo.addCustomExercise(
      name: '弹力带侧平举',
      unit: ExerciseUnit.reps,
    );
    expect(id, greaterThan(0));
    final created = await repo.exerciseById(id);
    expect(created?.name, '弹力带侧平举');
    expect(created?.isCustom, isTrue);
    expect(created?.category, 'chest');
  });

  test('addCustomExercise writes into given category', () async {
    final id = await repo.addCustomExercise(
      name: '弹力带划船',
      unit: ExerciseUnit.reps,
      category: 'back',
    );
    final created = await repo.exerciseById(id);
    expect(created?.name, '弹力带划船');
    expect(created?.isCustom, isTrue);
    expect(created?.category, 'back');
  });

  test('updateExercise edits custom exercise', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    await repo.updateExercise(
      id: pushup.id,
      name: '俯卧撑（改）',
      unit: ExerciseUnit.reps,
      category: 'shoulders',
    );
    final updated = await repo.exerciseById(pushup.id);
    expect(updated?.name, '俯卧撑（改）');
    expect(updated?.category, 'shoulders');
    expect(updated?.isCustom, isTrue);
  });

  test('updateExercise rejects duplicate names', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(
      repo,
      name: '深蹲',
      category: 'legs',
    );
    await expectLater(
      repo.updateExercise(
        id: squat.id,
        name: pushup.name,
        unit: ExerciseUnit.reps,
        category: 'legs',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('已存在同名动作'),
        ),
      ),
    );
  });

  test('category migration maps legacy custom to core', () async {
    final id = await repo.addCustomExercise(
      name: '旧分类动作',
      unit: ExerciseUnit.reps,
      category: 'back',
    );
    await (db.update(db.exercises)..where((t) => t.id.equals(id))).write(
      const ExercisesCompanion(category: Value('custom')),
    );
    await db.customStatement(
      "UPDATE exercises SET category = 'core' "
      "WHERE category IN ('core_timed', 'other', 'custom')",
    );
    final migrated = await repo.exerciseById(id);
    expect(migrated?.category, 'core');
  });

  test('createPlanFromDay copies today workout into a reusable plan', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final planId = await repo.createPlan(
      name: '源计划',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 4,
          targetReps: 12,
        ),
      ],
    );
    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: planId, day: day);

    final savedPlanId = await repo.createPlanFromDay(
      day: day,
      name: '今日备份',
    );

    final summaries = await repo.listPlanSummaries();
    final saved = summaries.firstWhere((s) => s.plan.id == savedPlanId);
    expect(saved.plan.name, '今日备份');
    expect(saved.items, hasLength(1));
    expect(saved.items.first.exerciseName, pushup.name);
    expect(saved.items.first.targetSets, 4);
    expect(saved.items.first.targetReps, 12);
  });

  test('watchDayWorkout emits non-empty snapshot after first add', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final planId = await repo.createPlan(
      name: '上肢',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 3,
          targetReps: 10,
        ),
      ],
    );

    final day = CalendarDay.todayLocal();
    final events = <DayWorkoutSnapshot>[];
    final sub = repo.watchDayWorkout(day).listen(events.add);

    await Future<void>.delayed(Duration.zero);
    expect(events, isNotEmpty);
    expect(events.last.isEmpty, isTrue);

    await repo.applyPlanToDay(planId: planId, day: day);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events.last.isEmpty, isFalse);
    expect(events.last.items, hasLength(1));
    expect(events.last.workout?.planName, '上肢');

    await sub.cancel();
  });
}
