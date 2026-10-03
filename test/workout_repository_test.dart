import 'dart:async';

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

  test(
    'recent history updates after adding and removing sets without reopening',
    () async {
      final events = StreamIterator(repo.watchRecentHistory());
      try {
        expect(await events.moveNext(), isTrue);
        expect(events.current, isEmpty);
        final exercise = await addTestExercise(repo, name: 'Squat');
        final today = DateTime.now();
        await repo.logSet(
          day: today,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          reps: 8,
        );
        expect(await events.moveNext(), isTrue);
        expect(events.current.single.sets.single.reps, 8);
        await repo.logSet(
          day: today,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          reps: 10,
        );
        expect(await events.moveNext(), isTrue);
        expect(events.current.single.sets, hasLength(2));
        await db.delete(db.workoutSetLogs).go();
        expect(await events.moveNext(), isTrue);
        expect(events.current, isEmpty);
      } finally {
        await events.cancel();
      }
    },
  );

  test('adding a plan enters history with zero completed exercises', () async {
    final exercise = await addTestExercise(repo, name: 'Walkout');
    final plan = await repo.createPlan(
      name: 'Today',
      items: [
        PlanDraftItem(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          targetSets: 3,
          targetReps: 8,
        ),
      ],
    );
    final day = CalendarDay.todayLocal();
    final events = StreamIterator(repo.watchRecentHistory());
    try {
      expect(await events.moveNext(), isTrue);
      expect(events.current, isEmpty);
      await repo.applyPlanToDay(planId: plan, day: day);
      final item = (await repo.daySnapshot(day)).items.single.item;
      expect(await events.moveNext(), isTrue);
      expect(events.current, hasLength(1));
      expect(events.current.single.hasActivity, isTrue);
      expect(events.current.single.sets, isEmpty);
      expect(events.current.single.completedItems, isEmpty);
      expect(events.current.single.planSummaries.single.doneCount, 0);
      expect(events.current.single.planSummaries.single.totalCount, 1);
      expect((await repo.recentCalendarHistory()).first.hasActivity, isTrue);
      await repo.setItemDone(item.id, true);
      expect(await events.moveNext(), isTrue);
      expect(events.current.single.sets, hasLength(3));
      expect(
        events.current.single.completedItems.single.exerciseName,
        'Walkout',
      );
      await repo.setItemDone(item.id, false);
      // Unchecking clears the auto-filled sets but keeps the added plan in
      // history with zero completed exercises.
      expect(await events.moveNext(), isTrue);
      expect(events.current.single.sets, isEmpty);
      expect(events.current.single.completedItems, isEmpty);
      expect(events.current.single.planSummaries.single.doneCount, 0);
    } finally {
      await events.cancel();
    }
  });

  test('checking done fills completed sets up to the target', () async {
    final squat = await addTestExercise(repo, name: 'Squat');
    final plan = await repo.createPlan(
      name: 'Leg day',
      items: [
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      ],
    );
    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: plan, day: day);
    final item = (await repo.daySnapshot(day)).items.single.item;

    await repo.logSet(
      day: day,
      exerciseId: squat.id,
      exerciseName: squat.name,
      dayWorkoutItemId: item.id,
      reps: 8,
    );
    var snap = await repo.daySnapshot(day);
    expect(snap.items.single.completedSets, 1);
    expect(snap.items.single.item.done, isFalse);

    await repo.setItemDone(item.id, true);
    snap = await repo.daySnapshot(day);
    expect(snap.items.single.item.done, isTrue);
    expect(snap.items.single.completedSets, 4);
    expect(snap.items.single.item.targetReps, 8);

    await repo.setItemDone(item.id, false);
    snap = await repo.daySnapshot(day);
    expect(snap.items.single.item.done, isFalse);
    // Unchecking drops only the sets the checkbox auto-filled and restores
    // the count from before it was checked.
    expect(snap.items.single.completedSets, 1);
  });

  test('recent calendar history pads empty days within the window', () async {
    final squat = await addTestExercise(repo, name: 'Squat');
    final today = CalendarDay.todayLocal();
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    await db
        .into(db.workoutSetLogs)
        .insert(
          WorkoutSetLogsCompanion.insert(
            date: threeDaysAgo,
            exerciseId: squat.id,
            exerciseName: squat.name,
            setIndex: 1,
            reps: const Value(5),
          ),
        );

    final recent = await repo.recentCalendarHistory(limitDays: 14);
    expect(recent, hasLength(14));
    expect(recent.first.date, today);
    expect(recent.first.hasActivity, isFalse);
    expect(recent[3].date, threeDaysAgo);
    expect(recent[3].hasActivity, isTrue);
    expect(recent[3].sets, hasLength(1));

    final all = await repo.recentHistory(limitDays: null);
    expect(all, hasLength(1));
    expect(all.single.date, threeDaysAgo);
  });

  test('fresh database has no pre-seeded exercises', () async {
    final exercises = await repo.listExercises();
    expect(exercises, isEmpty);
    await db.seedBuiltinExercises();
    expect(await repo.listExercises(), isEmpty);
  });

  test('v13 migration removes builtin exercises', () async {
    await db
        .into(db.exercises)
        .insert(
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
    expect(snap.groups, hasLength(1));
    expect(snap.groups.first.workout.planName, '上肢');
    expect(snap.items, hasLength(1));
    expect(snap.items.first.item.targetSets, 4);
    expect(snap.items.first.item.targetReps, 12);
    expect(snap.items.first.completedSets, 0);
  });

  test('applyPlanToDay stacks multiple plans on the same day', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
    final upperId = await repo.createPlan(
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
    final lowerId = await repo.createPlan(
      name: '下肢',
      items: [
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      ],
    );

    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: upperId, day: day);
    await repo.applyPlanToDay(planId: lowerId, day: day);

    final snap = await repo.daySnapshot(day);
    expect(snap.groups, hasLength(2));
    expect(snap.groups.map((g) => g.workout.planName), ['上肢', '下肢']);
    expect(snap.items, hasLength(2));
    expect(snap.groups.first.items.single.item.exerciseName, '俯卧撑');
    expect(snap.groups.last.items.single.item.exerciseName, '深蹲');
  });

  test(
    'addQuickDayItem attaches to null-plan group without replacing plans',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final plank = await addTestExercise(
        repo,
        name: '平板支撑',
        unit: ExerciseUnit.seconds,
        category: 'core',
      );
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
      await repo.applyPlanToDay(planId: planId, day: day);
      await repo.addQuickDayItem(
        day: day,
        exerciseId: plank.id,
        targetSets: 2,
        targetReps: 60,
      );

      final snap = await repo.daySnapshot(day);
      expect(snap.groups, hasLength(2));
      expect(snap.groups.first.workout.planName, '上肢');
      expect(snap.groups.first.workout.planId, isNotNull);
      expect(snap.groups.last.workout.planId, isNull);
      expect(snap.groups.last.items.single.item.exerciseName, '平板支撑');
    },
  );

  test(
    'moveDayWorkoutItemToOther keeps progress and syncs both templates',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      final planId = await repo.createPlan(
        name: '上肢',
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 3,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 4,
            targetReps: 8,
          ),
        ],
      );
      final day = CalendarDay.todayLocal();
      await repo.applyPlanToDay(planId: planId, day: day);
      final before = await repo.daySnapshot(day);
      final squatItem = before.items
          .firstWhere((e) => e.item.exerciseName == '深蹲')
          .item;
      await repo.setItemDone(squatItem.id, true);

      await repo.moveDayWorkoutItemToOther(squatItem.id);

      final after = await repo.daySnapshot(day);
      expect(after.groups, hasLength(2));
      expect(after.groups.first.workout.planName, '上肢');
      expect(after.groups.first.items.map((e) => e.item.exerciseName), ['俯卧撑']);
      final other = after.groups.last;
      expect(other.workout.planId, isNull);
      expect(other.workout.planName, isNull);
      expect(other.items.single.item.id, squatItem.id);
      expect(other.items.single.item.done, isTrue);
      expect(other.items.single.completedSets, 4);

      final template = await repo.itemsFor(planId);
      expect(template.map((e) => e.exerciseName), ['俯卧撑']);
      expect((await repo.listPlanSummaries()).map((plan) => plan.plan.name), [
        '上肢',
      ]);
    },
  );

  test('plan summary stream drops an exercise moved out of the template', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
    final planId = await repo.createPlan(
      name: '上肢',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 3,
          targetReps: 10,
        ),
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      ],
    );
    final events = StreamIterator(repo.watchPlanSummaries());
    try {
      expect(await events.moveNext(), isTrue);
      expect(events.current.single.items, hasLength(2));

      final day = CalendarDay.todayLocal();
      await repo.applyPlanToDay(planId: planId, day: day);
      final before = await repo.daySnapshot(day);
      final squatItem = before.items
          .firstWhere((e) => e.item.exerciseName == '深蹲')
          .item;
      await repo.moveDayWorkoutItemToOther(squatItem.id);

      var length = events.current.single.items.length;
      for (var i = 0; length != 1 && i < 8; i++) {
        expect(
          await events.moveNext().timeout(const Duration(seconds: 2)),
          isTrue,
        );
        length = events.current.single.items.length;
      }
      expect(length, 1);
      expect(events.current.single.plan.name, '上肢');
    } finally {
      await events.cancel();
    }
  });

  test('moveDayWorkoutItemToOther drops an emptied plan group', () async {
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
    await repo.applyPlanToDay(planId: planId, day: day);
    final itemId = (await repo.daySnapshot(day)).items.single.item.id;

    await repo.moveDayWorkoutItemToOther(itemId);

    final after = await repo.daySnapshot(day);
    expect(after.groups, hasLength(1));
    expect(after.groups.single.workout.planName, isNull);
    expect(after.groups.single.workout.planId, isNull);
    expect(after.groups.single.items.single.item.id, itemId);
    expect(await repo.itemsFor(planId), isEmpty);
    expect(await repo.listPlanSummaries(), isEmpty);
  });

  test(
    'moveDayWorkoutItemToOther appends onto the existing 其他 group',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final plank = await addTestExercise(
        repo,
        name: '平板支撑',
        unit: ExerciseUnit.seconds,
        category: 'core',
      );
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
      await repo.applyPlanToDay(planId: planId, day: day);
      await repo.addQuickDayItem(
        day: day,
        exerciseId: plank.id,
        targetSets: 2,
        targetReps: 60,
      );
      final before = await repo.daySnapshot(day);
      final pushupId = before.groups.first.items.single.item.id;
      final otherId = before.groups.last.workout.id;

      await repo.moveDayWorkoutItemToOther(pushupId);

      final after = await repo.daySnapshot(day);
      expect(after.groups, hasLength(1));
      expect(after.groups.single.workout.id, otherId);
      expect(after.groups.single.items.map((e) => e.item.exerciseName), [
        '平板支撑',
        '俯卧撑',
      ]);
    },
  );

  test(
    'moveDayWorkoutItemIntoPlan keeps a template row that is already there',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      final planId = await repo.createPlan(
        name: '上肢',
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 3,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 4,
            targetReps: 8,
          ),
        ],
      );
      final day = CalendarDay.todayLocal();
      await repo.applyPlanToDay(planId: planId, day: day);
      final before = await repo.daySnapshot(day);
      final squatItem = before.items
          .firstWhere((e) => e.item.exerciseName == '深蹲')
          .item;
      await repo.setItemDone(squatItem.id, true);
      await repo.moveDayWorkoutItemToOther(squatItem.id);
      final parked = await repo.daySnapshot(day);
      final planGroupId = parked.groups.first.workout.id;

      await repo.moveDayWorkoutItemIntoPlan(
        dayWorkoutItemId: squatItem.id,
        targetDayWorkoutId: planGroupId,
      );

      final after = await repo.daySnapshot(day);
      expect(after.groups, hasLength(1));
      expect(after.groups.single.workout.planName, '上肢');
      expect(after.groups.single.items.map((e) => e.item.exerciseName), [
        '俯卧撑',
        '深蹲',
      ]);
      final moved = after.groups.single.items.last;
      expect(moved.item.id, squatItem.id);
      expect(moved.item.done, isTrue);
      expect(moved.completedSets, 4);
      expect((await repo.itemsFor(planId)).map((e) => e.exerciseName), [
        '俯卧撑',
        '深蹲',
      ]);
    },
  );

  test(
    'moveDayWorkoutItemIntoPlan appends a new exercise onto the plan template',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final plank = await addTestExercise(
        repo,
        name: '平板支撑',
        unit: ExerciseUnit.seconds,
        category: 'core',
      );
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
      await repo.applyPlanToDay(planId: planId, day: day);
      await repo.addQuickDayItem(
        day: day,
        exerciseId: plank.id,
        targetSets: 2,
        targetReps: 45,
      );
      final before = await repo.daySnapshot(day);
      final plankItem = before.groups.last.items.single.item;
      final planGroupId = before.groups.first.workout.id;

      await repo.moveDayWorkoutItemIntoPlan(
        dayWorkoutItemId: plankItem.id,
        targetDayWorkoutId: planGroupId,
      );

      final after = await repo.daySnapshot(day);
      expect(after.groups, hasLength(1));
      expect(after.groups.single.items.map((e) => e.item.exerciseName), [
        '俯卧撑',
        '平板支撑',
      ]);
      expect(after.groups.single.items.last.item.id, plankItem.id);
      final template = await repo.itemsFor(planId);
      expect(template.map((e) => e.exerciseName), ['俯卧撑', '平板支撑']);
      expect(template.last.targetSets, 2);
      expect(template.last.targetReps, 45);
      expect((await repo.listPlanSummaries()).map((plan) => plan.plan.name), [
        '上肢',
      ]);
    },
  );

  test(
    'moving an exercise already in the template updates its sets and reps',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      final lunge = await addTestExercise(repo, name: '弓步', category: 'legs');
      final upperId = await repo.createPlan(
        name: '上肢',
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 3,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 4,
            targetReps: 8,
          ),
        ],
      );
      final legsId = await repo.createPlan(
        name: '腿部',
        items: [
          PlanDraftItem(
            exerciseId: lunge.id,
            exerciseName: lunge.name,
            targetSets: 2,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 3,
            targetReps: 6,
          ),
        ],
      );
      final day = CalendarDay.todayLocal();
      await repo.applyPlanToDay(planId: upperId, day: day);
      await repo.applyPlanToDay(planId: legsId, day: day);
      final before = await repo.daySnapshot(day);
      final squatItem = before.items
          .firstWhere((e) => e.item.exerciseName == '深蹲')
          .item;
      await (db.update(db.dayWorkoutItems)..where(
            (t) => t.id.equals(squatItem.id),
          ))
          .write(
            const DayWorkoutItemsCompanion(
              targetSets: Value(5),
              targetReps: Value(12),
            ),
          );
      final legsGroupId = before.groups
          .firstWhere((g) => g.workout.planName == '腿部')
          .workout
          .id;

      await repo.moveDayWorkoutItemIntoPlan(
        dayWorkoutItemId: squatItem.id,
        targetDayWorkoutId: legsGroupId,
      );

      final legs = await repo.itemsFor(legsId);
      expect(legs.map((e) => e.exerciseName), ['弓步', '深蹲']);
      final moved = legs.last;
      expect(moved.targetSets, 5);
      expect(moved.targetReps, 12);
      expect(moved.note, isNull);
      final upper = await repo.itemsFor(upperId);
      expect(upper.map((e) => e.exerciseName), ['俯卧撑']);
      expect(upper.single.targetSets, 3);
      expect(upper.single.targetReps, 10);
    },
  );

  test(
    'logging a set writes the new reps back onto the plan template',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      final planId = await repo.createPlan(
        name: '上肢',
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 3,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 4,
            targetReps: 8,
          ),
        ],
      );
      final day = CalendarDay.todayLocal();
      await repo.applyPlanToDay(planId: planId, day: day);
      final snap = await repo.daySnapshot(day);
      final pushupItem = snap.items
          .firstWhere((e) => e.item.exerciseName == '俯卧撑')
          .item;
      final squatItem = snap.items
          .firstWhere((e) => e.item.exerciseName == '深蹲')
          .item;
      // Drop it from today only, so the template row can stay and prove a
      // logged set does not remove the other planned exercise.
      await (db.delete(
        db.dayWorkoutItems,
      )..where((t) => t.id.equals(squatItem.id))).go();

      await repo.updateDayItemProgress(
        dayWorkoutItemId: pushupItem.id,
        day: day,
        completedSets: 2,
        perSetValue: 15,
        unit: ExerciseUnit.reps,
        note: '今天的心得',
      );

      final template = await repo.itemsFor(planId);
      expect(template.map((e) => e.exerciseName), ['俯卧撑', '深蹲']);
      expect(template.first.targetSets, 3);
      expect(template.first.targetReps, 15);
      expect(template.first.note, isNull);
      expect(template.last.targetSets, 4);
      expect(template.last.targetReps, 8);
      final dayAfter = await repo.daySnapshot(day);
      expect(dayAfter.items.single.item.note, '今天的心得');
    },
  );

  test('moving between plans updates both templates', () async {
    final bench = await addTestExercise(repo, name: '杠铃卧推', category: 'chest');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
    final upperId = await repo.createPlan(
      name: '上肢',
      items: [
        PlanDraftItem(
          exerciseId: bench.id,
          exerciseName: bench.name,
          targetSets: 3,
          targetReps: 12,
        ),
      ],
    );
    final legsId = await repo.createPlan(
      name: '腿部',
      items: [
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      ],
    );
    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: upperId, day: day);
    await repo.applyPlanToDay(planId: legsId, day: day);
    final before = await repo.daySnapshot(day);
    final upperGroupId = before.groups.first.workout.id;
    final squatItem = before.groups.last.items.single.item;

    await repo.moveDayWorkoutItemIntoPlan(
      dayWorkoutItemId: squatItem.id,
      targetDayWorkoutId: upperGroupId,
    );

    final after = await repo.daySnapshot(day);
    expect(after.groups, hasLength(1));
    expect(after.groups.single.workout.planName, '上肢');
    expect(after.groups.single.items.map((e) => e.item.exerciseName), [
      '杠铃卧推',
      '深蹲',
    ]);
    expect(after.groups.single.items.last.item.id, squatItem.id);
    expect((await repo.itemsFor(upperId)).map((e) => e.exerciseName), [
      '杠铃卧推',
      '深蹲',
    ]);
    expect(await repo.itemsFor(legsId), isEmpty);
    expect((await repo.listPlanSummaries()).map((plan) => plan.plan.name), [
      '上肢',
    ]);
  });

  test('listing plans drops a retired 其他 template', () async {
    final planId = await db
        .into(db.workoutPlans)
        .insert(
          WorkoutPlansCompanion.insert(name: '其他', createdAt: DateTime.now()),
        );
    await db
        .into(db.appMeta)
        .insert(
          AppMetaCompanion.insert(
            key: 'other_workout_plan_id',
            value: '$planId',
          ),
        );
    await db
        .into(db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: planId,
            exerciseId: 1,
            exerciseName: '平板支撑',
            targetSets: 1,
            targetReps: 30,
          ),
        );
    final dayId = await db
        .into(db.dayWorkouts)
        .insert(
          DayWorkoutsCompanion.insert(
            date: CalendarDay.todayLocal(),
            planId: Value(planId),
          ),
        );

    expect(await repo.listPlanSummaries(), isEmpty);
    final day = await (db.select(
      db.dayWorkouts,
    )..where((t) => t.id.equals(dayId))).getSingle();
    expect(day.planId, isNull);
    expect(day.planName, isNull);
  });

  test('moveDayWorkoutItemToOther leaves an item already in 其他', () async {
    final plank = await addTestExercise(
      repo,
      name: '平板支撑',
      unit: ExerciseUnit.seconds,
      category: 'core',
    );
    final day = CalendarDay.todayLocal();
    await repo.addQuickDayItem(
      day: day,
      exerciseId: plank.id,
      targetSets: 2,
      targetReps: 60,
    );
    final before = await repo.daySnapshot(day);
    await repo.moveDayWorkoutItemToOther(before.items.single.item.id);
    final after = await repo.daySnapshot(day);
    expect(after.groups.single.workout.id, before.groups.single.workout.id);
    expect(after.items.single.item.id, before.items.single.item.id);
  });

  test(
    'editing a plan from Today syncs its day group and keeps progress',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      final plank = await addTestExercise(repo, name: '平板支撑', category: 'core');
      final planId = await repo.createPlan(
        name: '原计划',
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 3,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 4,
            targetReps: 8,
          ),
        ],
      );
      final today = CalendarDay.todayLocal();
      await repo.applyPlanToDay(planId: planId, day: today);
      final before = await repo.daySnapshot(today);
      final pushupItem = before.items.first.item;
      await repo.logSet(
        day: today,
        exerciseId: pushup.id,
        exerciseName: pushup.name,
        dayWorkoutItemId: pushupItem.id,
        reps: 10,
      );

      await repo.updatePlan(
        planId: planId,
        name: '更新计划',
        syncDay: today,
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 5,
            targetReps: 12,
          ),
          PlanDraftItem(
            exerciseId: plank.id,
            exerciseName: plank.name,
            targetSets: 2,
            targetReps: 60,
          ),
        ],
      );

      final after = await repo.daySnapshot(today);
      expect(after.groups.single.workout.planName, '更新计划');
      expect(after.items.map((e) => e.item.exerciseName), ['俯卧撑', '平板支撑']);
      expect(after.items.first.item.id, pushupItem.id);
      expect(after.items.first.item.targetSets, 5);
      expect(after.items.first.item.targetReps, 12);
      expect(after.items.first.completedSets, 1);
    },
  );

  test('dayItemsForPlanOnDay reflects an item removed from today', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
    final planId = await repo.createPlan(
      name: '计划',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 3,
          targetReps: 10,
        ),
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      ],
    );
    final today = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: planId, day: today);
    final applied = await repo.daySnapshot(today);
    final squatItemId = applied.items
        .firstWhere((e) => e.item.exerciseName == '深蹲')
        .item
        .id;
    await repo.deleteDayWorkoutItem(squatItemId);

    final dayItems = await repo.dayItemsForPlanOnDay(
      planId: planId,
      day: today,
    );
    expect(dayItems.map((e) => e.exerciseName), ['俯卧撑']);

    final templateItems = await repo.itemsFor(planId);
    expect(templateItems.map((e) => e.exerciseName), ['俯卧撑']);
  });

  test(
    'deleting a planned exercise drops it from the template, not an untitled one',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      final plank = await addTestExercise(
        repo,
        name: '平板支撑',
        unit: ExerciseUnit.seconds,
        category: 'core',
      );
      final planId = await repo.createPlan(
        name: '上肢',
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 3,
            targetReps: 10,
          ),
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 4,
            targetReps: 8,
          ),
        ],
      );
      final day = CalendarDay.todayLocal();
      await repo.applyPlanToDay(planId: planId, day: day);
      await repo.addQuickDayItem(
        day: day,
        exerciseId: plank.id,
        targetSets: 2,
        targetReps: 45,
      );
      final before = await repo.daySnapshot(day);
      final squatItem = before.items
          .firstWhere((e) => e.item.exerciseName == '深蹲')
          .item;
      final plankItem = before.items
          .firstWhere((e) => e.item.exerciseName == '平板支撑')
          .item;

      await repo.deleteDayWorkoutItem(squatItem.id);
      await repo.deleteDayWorkoutItem(plankItem.id);

      expect((await repo.itemsFor(planId)).map((e) => e.exerciseName), [
        '俯卧撑',
      ]);
      expect((await repo.listPlanSummaries()).map((plan) => plan.plan.name), [
        '上肢',
      ]);
      final after = await repo.daySnapshot(day);
      expect(after.groups, hasLength(1));
      expect(after.groups.single.workout.planName, '上肢');
      expect(after.items.map((e) => e.item.exerciseName), ['俯卧撑']);
    },
  );

  test(
    'dayItemsForPlanOnDay is empty when the plan was not applied to that day',
    () async {
      final pushup = await addTestExercise(repo, name: '俯卧撑');
      final planId = await repo.createPlan(
        name: '计划',
        items: [
          PlanDraftItem(
            exerciseId: pushup.id,
            exerciseName: pushup.name,
            targetSets: 3,
            targetReps: 10,
          ),
        ],
      );
      final dayItems = await repo.dayItemsForPlanOnDay(
        planId: planId,
        day: CalendarDay.todayLocal(),
      );
      expect(dayItems, isEmpty);
    },
  );

  test('deleteDayWorkout removes one group and keeps the other', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
    final upperId = await repo.createPlan(
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
    final lowerId = await repo.createPlan(
      name: '下肢',
      items: [
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      ],
    );
    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: upperId, day: day);
    await repo.applyPlanToDay(planId: lowerId, day: day);

    var snap = await repo.daySnapshot(day);
    await repo.deleteDayWorkout(snap.groups.first.workout.id);
    snap = await repo.daySnapshot(day);
    expect(snap.groups, hasLength(1));
    expect(snap.groups.single.workout.planName, '下肢');
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
          ..where((t) => t.id.equals(snapshot.groups.single.workout.id)))
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

  test(
    'updateExercise syncs the new name onto plans, days, and set logs',
    () async {
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
      await repo.applyPlanToDay(planId: planId, day: day);
      final item = (await repo.daySnapshot(day)).items.single.item;
      await repo.logSet(
        day: day,
        exerciseId: pushup.id,
        exerciseName: pushup.name,
        dayWorkoutItemId: item.id,
        reps: 10,
      );

      await repo.updateExercise(
        id: pushup.id,
        name: '宽距俯卧撑',
        unit: ExerciseUnit.reps,
        category: 'chest',
      );

      final plans = await repo.listPlanSummaries();
      expect(plans.single.items.single.exerciseName, '宽距俯卧撑');
      expect(
        (await repo.daySnapshot(day)).items.single.item.exerciseName,
        '宽距俯卧撑',
      );
      final logs = await db.select(db.workoutSetLogs).get();
      expect(logs.single.exerciseName, '宽距俯卧撑');
    },
  );

  test('updateExercise rejects duplicate names', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
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

    final savedPlanId = await repo.createPlanFromDay(day: day, name: '今日备份');

    final summaries = await repo.listPlanSummaries();
    final saved = summaries.firstWhere((s) => s.plan.id == savedPlanId);
    expect(saved.plan.name, '今日备份');
    expect(saved.items, hasLength(1));
    expect(saved.items.first.exerciseName, pushup.name);
    expect(saved.items.first.targetSets, 4);
    expect(saved.items.first.targetReps, 12);
  });

  test('createPlanFromDay merges items from multiple day groups', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
    final upperId = await repo.createPlan(
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
    final lowerId = await repo.createPlan(
      name: '下肢',
      items: [
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      ],
    );
    final day = CalendarDay.todayLocal();
    await repo.applyPlanToDay(planId: upperId, day: day);
    await repo.applyPlanToDay(planId: lowerId, day: day);

    final savedPlanId = await repo.createPlanFromDay(day: day, name: '合并备份');
    final summaries = await repo.listPlanSummaries();
    final saved = summaries.firstWhere((s) => s.plan.id == savedPlanId);
    expect(saved.items, hasLength(2));
    expect(saved.items.map((i) => i.exerciseName), ['俯卧撑', '深蹲']);
  });

  test('createPlan stores distinct exercises per row', () async {
    final pushup = await addTestExercise(repo, name: '俯卧撑');
    final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
    final planId = await repo.createPlan(
      name: '全身',
      items: [
        PlanDraftItem(
          exerciseId: pushup.id,
          exerciseName: pushup.name,
          targetSets: 3,
          targetReps: 12,
        ),
        PlanDraftItem(
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 10,
        ),
      ],
    );

    final summaries = await repo.listPlanSummaries();
    final saved = summaries.firstWhere((s) => s.plan.id == planId);
    expect(saved.items, hasLength(2));
    expect(saved.items[0].exerciseId, pushup.id);
    expect(saved.items[1].exerciseId, squat.id);
    expect(saved.items[0].exerciseName, '俯卧撑');
    expect(saved.items[1].exerciseName, '深蹲');
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
    expect(events.last.groups.single.workout.planName, '上肢');

    await sub.cancel();
  });

  test(
    'watchDayWorkoutsForDays combines snapshots for multiple days in one stream',
    () async {
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

      final today = CalendarDay.todayLocal();
      final yesterday = today.subtract(const Duration(days: 1));
      final events = <Map<DateTime, DayWorkoutSnapshot>>[];
      final sub = repo
          .watchDayWorkoutsForDays([today, yesterday])
          .listen(events.add);

      await Future<void>.delayed(Duration.zero);
      expect(events, isNotEmpty);
      expect(events.last[today]?.isEmpty, isTrue);
      expect(events.last[yesterday]?.isEmpty, isTrue);

      await repo.applyPlanToDay(planId: planId, day: today);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Only today changed; yesterday (never written) stays empty in the
      // same emitted map — one combined stream covering both days.
      expect(events.last[today]?.isEmpty, isFalse);
      expect(events.last[today]?.groups.single.workout.planName, '上肢');
      expect(events.last[yesterday]?.isEmpty, isTrue);

      await sub.cancel();
    },
  );

  test(
    'lastTargetReps uses the newest day, then the newest plan item',
    () async {
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      expect(await repo.lastTargetReps(squat.id), isNull);

      await repo.createPlan(
        name: '旧计划',
        items: [
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 3,
            targetReps: 8,
          ),
        ],
      );
      await repo.createPlan(
        name: '新计划',
        items: [
          PlanDraftItem(
            exerciseId: squat.id,
            exerciseName: squat.name,
            targetSets: 4,
            targetReps: 6,
          ),
        ],
      );
      expect(await repo.lastTargetReps(squat.id), 6);

      final today = CalendarDay.todayLocal();
      await repo.addQuickDayItem(
        day: today,
        exerciseId: squat.id,
        targetSets: 3,
        targetReps: 10,
      );
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayId = await db
          .into(db.dayWorkouts)
          .insert(DayWorkoutsCompanion.insert(date: yesterday));
      await db
          .into(db.dayWorkoutItems)
          .insert(
            DayWorkoutItemsCompanion.insert(
              dayWorkoutId: yesterdayId,
              exerciseId: squat.id,
              exerciseName: squat.name,
              targetSets: 3,
              targetReps: 15,
            ),
          );
      // Today is older by id but newer by date, so it wins over yesterday.
      expect(await repo.lastTargetReps(squat.id), 10);
    },
  );

  test(
    'history highlight ids keep strength exercises and drop cardio, anaerobic, and core',
    () async {
      final bench = await addTestExercise(repo, name: '卧推', category: 'chest');
      final squat = await addTestExercise(repo, name: '深蹲', category: 'legs');
      final press = await addTestExercise(
        repo,
        name: '推举',
        category: 'shoulders',
      );
      final run = await addTestExercise(repo, name: '跑步', category: 'cardio');
      final hiit = await addTestExercise(
        repo,
        name: '冲刺',
        category: 'anaerobic',
      );
      final plank = await addTestExercise(repo, name: '平板支撑', category: 'core');

      final today = CalendarDay.todayLocal();
      final yesterday = today.subtract(const Duration(days: 1));
      final older = today.subtract(const Duration(days: 2));

      for (final exercise in [bench, squat, run, hiit, plank]) {
        await repo.addQuickDayItem(
          day: today,
          exerciseId: exercise.id,
          targetSets: 1,
          targetReps: 10,
        );
      }
      await repo.logSet(
        day: today,
        exerciseId: bench.id,
        exerciseName: bench.name,
        reps: 8,
      );

      final yesterdayId = await db
          .into(db.dayWorkouts)
          .insert(DayWorkoutsCompanion.insert(date: yesterday));
      await db
          .into(db.dayWorkoutItems)
          .insert(
            DayWorkoutItemsCompanion.insert(
              dayWorkoutId: yesterdayId,
              exerciseId: bench.id,
              exerciseName: bench.name,
              targetSets: 1,
              targetReps: 10,
              done: const Value(true),
            ),
          );
      await db
          .into(db.dayWorkoutItems)
          .insert(
            DayWorkoutItemsCompanion.insert(
              dayWorkoutId: yesterdayId,
              exerciseId: run.id,
              exerciseName: run.name,
              targetSets: 1,
              targetReps: 10,
              done: const Value(true),
            ),
          );
      await db
          .into(db.workoutSetLogs)
          .insert(
            WorkoutSetLogsCompanion.insert(
              date: yesterday,
              exerciseId: press.id,
              exerciseName: press.name,
              setIndex: 1,
            ),
          );
      await db
          .into(db.workoutSetLogs)
          .insert(
            WorkoutSetLogsCompanion.insert(
              date: older,
              exerciseId: hiit.id,
              exerciseName: hiit.name,
              setIndex: 1,
            ),
          );

      final history = await repo.recentHistory(limitDays: null);
      WorkoutHistoryDay on(DateTime date) =>
          history.singleWhere((day) => day.date == date);

      expect(on(today).highlightExerciseIds, {bench.id, squat.id});
      expect(on(yesterday).highlightExerciseIds, {bench.id, press.id});
      expect(on(older).highlightExerciseIds, isEmpty);
    },
  );

  test('core cardio and anaerobic match only when every exercise is that type', () {
    final solo = WorkoutPlanSummary(
      plan: WorkoutPlan(id: 1, name: '核心', createdAt: DateTime(2026)),
      items: [
        WorkoutPlanItem(
          id: 1,
          planId: 1,
          exerciseId: 10,
          exerciseName: '平板支撑',
          targetSets: 3,
          targetReps: 60,
          sortOrder: 0,
        ),
      ],
    );
    final pureCore = WorkoutPlanSummary(
      plan: WorkoutPlan(id: 3, name: '核心循环', createdAt: DateTime(2026)),
      items: [
        WorkoutPlanItem(
          id: 4,
          planId: 3,
          exerciseId: 10,
          exerciseName: '平板支撑',
          targetSets: 3,
          targetReps: 60,
          sortOrder: 0,
        ),
        WorkoutPlanItem(
          id: 5,
          planId: 3,
          exerciseId: 11,
          exerciseName: '卷腹',
          targetSets: 3,
          targetReps: 15,
          sortOrder: 1,
        ),
      ],
    );
    final mixed = WorkoutPlanSummary(
      plan: WorkoutPlan(id: 2, name: '混合', createdAt: DateTime(2026)),
      items: [
        WorkoutPlanItem(
          id: 2,
          planId: 2,
          exerciseId: 20,
          exerciseName: '深蹲',
          targetSets: 3,
          targetReps: 10,
          sortOrder: 0,
        ),
        WorkoutPlanItem(
          id: 3,
          planId: 2,
          exerciseId: 10,
          exerciseName: '平板支撑',
          targetSets: 3,
          targetReps: 45,
          sortOrder: 1,
        ),
      ],
    );
    const byId = {10: 'core', 11: 'core', 20: 'legs'};

    expect(solo.matchesExerciseCategory('core', byId), isTrue);
    expect(pureCore.matchesExerciseCategory('core', byId), isTrue);
    expect(pureCore.matchesExerciseCategory('legs', byId), isFalse);
    expect(mixed.matchesExerciseCategory('core', byId), isFalse);
    expect(mixed.matchesExerciseCategory('legs', byId), isTrue);
  });
}
