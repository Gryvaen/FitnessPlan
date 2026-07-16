import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/domain/models.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.seedBuiltinExercises();
    repo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('seedBuiltinExercises inserts catalog once', () async {
    final first = await repo.listExercises();
    expect(first, isNotEmpty);
    await db.seedBuiltinExercises();
    final second = await repo.listExercises();
    expect(second.length, first.length);
  });

  test('applyPlanToDay copies items into day snapshot', () async {
    final exercises = await repo.listExercises();
    final pushup = exercises.firstWhere((e) => e.name == '俯卧撑');
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

    final day = DateTime(2026, 7, 16);
    await repo.applyPlanToDay(planId: planId, day: day);

    final snap = await repo.daySnapshot(day);
    expect(snap.workout?.planName, '上肢');
    expect(snap.items, hasLength(1));
    expect(snap.items.first.item.targetSets, 4);
    expect(snap.items.first.item.targetReps, 12);
    expect(snap.items.first.completedSets, 0);
  });

  test('logSet auto-marks done when target sets reached', () async {
    final exercises = await repo.listExercises();
    final plank = exercises.firstWhere((e) => e.name == '平板支撑');
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
    final day = DateTime(2026, 7, 16);
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

  test('addCustomExercise rejects duplicate names', () async {
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
      name: '保加利亚分腿蹲',
      unit: ExerciseUnit.reps,
    );
    expect(id, greaterThan(0));
    final created = await repo.exerciseById(id);
    expect(created?.name, '保加利亚分腿蹲');
    expect(created?.isCustom, isTrue);
  });

  test('watchDayWorkout emits non-empty snapshot after first add', () async {
    final exercises = await repo.listExercises();
    final pushup = exercises.firstWhere((e) => e.name == '俯卧撑');
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

    final day = DateTime(2026, 7, 16);
    final events = <DayWorkoutSnapshot>[];
    final sub = repo.watchDayWorkout(day).listen(events.add);

    // Allow initial empty emit.
    await Future<void>.delayed(Duration.zero);
    expect(events, isNotEmpty);
    expect(events.last.isEmpty, isTrue);

    await repo.applyPlanToDay(planId: planId, day: day);
    // Concurrent table watches should still settle on a non-empty snapshot.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events.last.isEmpty, isFalse);
    expect(events.last.items, hasLength(1));
    expect(events.last.workout?.planName, '上肢');

    await sub.cancel();
  });
}
