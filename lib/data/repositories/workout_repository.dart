import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db.dart';

class PlanDraftItem {
  const PlanDraftItem({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
  });

  final int exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
}

class DayWorkoutItemProgress {
  const DayWorkoutItemProgress({
    required this.item,
    required this.completedSets,
    required this.unit,
  });

  final DayWorkoutItem item;
  final int completedSets;
  final ExerciseUnit unit;
}

class DayWorkoutSnapshot {
  const DayWorkoutSnapshot({
    this.workout,
    this.items = const [],
  });

  final DayWorkout? workout;
  final List<DayWorkoutItemProgress> items;

  bool get isEmpty => items.isEmpty;

  int get doneCount => items.where((e) => e.item.done).length;
}

class WorkoutHistoryDay {
  const WorkoutHistoryDay({
    required this.date,
    required this.sets,
  });

  final DateTime date;
  final List<WorkoutSetLog> sets;
}

class WorkoutPlanSummary {
  const WorkoutPlanSummary({
    required this.plan,
    required this.items,
  });

  final WorkoutPlan plan;
  final List<WorkoutPlanItem> items;
}

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  Stream<List<Exercise>> watchExercises() {
    return (_db.select(_db.exercises)
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCustom),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  Future<List<Exercise>> listExercises() {
    return (_db.select(_db.exercises)
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCustom),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  Future<Exercise?> exerciseById(int id) {
    return (_db.select(_db.exercises)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Exercise?> exerciseByName(String name) {
    final trimmed = name.trim();
    return (_db.select(_db.exercises)..where((t) => t.name.equals(trimmed)))
        .getSingleOrNull();
  }

  Future<int> addCustomExercise({
    required String name,
    required ExerciseUnit unit,
    String category = 'custom',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('动作名称不能为空');
    final existing = await exerciseByName(trimmed);
    if (existing != null) {
      throw StateError('已存在同名动作，请换一个名称');
    }
    return _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(
            name: trimmed,
            unit: unit.name,
            isCustom: const Value(true),
            category: Value(category),
          ),
        );
  }

  Future<void> deleteCustomExercise(int id) async {
    final ex = await exerciseById(id);
    if (ex == null || !ex.isCustom) {
      throw StateError('只能删除自定义动作');
    }
    await (_db.delete(_db.exercises)..where((t) => t.id.equals(id))).go();
  }

  Future<List<WorkoutPlanSummary>> listPlanSummaries() async {
    final plans = await (_db.select(_db.workoutPlans)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final out = <WorkoutPlanSummary>[];
    for (final plan in plans) {
      out.add(WorkoutPlanSummary(plan: plan, items: await itemsFor(plan.id)));
    }
    return out;
  }

  Stream<List<WorkoutPlan>> watchPlans() {
    return (_db.select(_db.workoutPlans)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<WorkoutPlanItem>> itemsFor(int planId) {
    return (_db.select(_db.workoutPlanItems)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<int> createPlan({
    required String name,
    required List<PlanDraftItem> items,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('计划名称不能为空');
    if (items.isEmpty) throw ArgumentError('至少添加一个动作');

    return _db.transaction(() async {
      final planId = await _db.into(_db.workoutPlans).insert(
            WorkoutPlansCompanion.insert(
              name: trimmed,
              createdAt: DateTime.now(),
            ),
          );
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await _db.into(_db.workoutPlanItems).insert(
              WorkoutPlanItemsCompanion.insert(
                planId: planId,
                exerciseId: item.exerciseId,
                exerciseName: item.exerciseName,
                targetSets: item.targetSets,
                targetReps: item.targetReps,
                sortOrder: Value(i),
              ),
            );
      }
      return planId;
    });
  }

  Future<void> updatePlan({
    required int planId,
    required String name,
    required List<PlanDraftItem> items,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('计划名称不能为空');
    if (items.isEmpty) throw ArgumentError('至少添加一个动作');

    await _db.transaction(() async {
      await (_db.update(_db.workoutPlans)..where((t) => t.id.equals(planId)))
          .write(WorkoutPlansCompanion(name: Value(trimmed)));
      await (_db.delete(_db.workoutPlanItems)
            ..where((t) => t.planId.equals(planId)))
          .go();
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await _db.into(_db.workoutPlanItems).insert(
              WorkoutPlanItemsCompanion.insert(
                planId: planId,
                exerciseId: item.exerciseId,
                exerciseName: item.exerciseName,
                targetSets: item.targetSets,
                targetReps: item.targetReps,
                sortOrder: Value(i),
              ),
            );
      }
    });
  }

  Future<void> deletePlan(int planId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.workoutPlanItems)
            ..where((t) => t.planId.equals(planId)))
          .go();
      await (_db.delete(_db.workoutPlans)..where((t) => t.id.equals(planId)))
          .go();
    });
  }

  Future<DayWorkout?> dayWorkoutFor(DateTime day) {
    final start = _dayStart(day);
    return (_db.select(_db.dayWorkouts)..where((t) => t.date.equals(start)))
        .getSingleOrNull();
  }

  Future<List<DayWorkoutItem>> dayItemsFor(int dayWorkoutId) {
    return (_db.select(_db.dayWorkoutItems)
          ..where((t) => t.dayWorkoutId.equals(dayWorkoutId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<DayWorkoutSnapshot> daySnapshot(DateTime day) async {
    final start = _dayStart(day);
    final workout = await (_db.select(_db.dayWorkouts)
          ..where((t) => t.date.equals(start)))
        .getSingleOrNull();
    if (workout == null) return const DayWorkoutSnapshot();
    final items = await dayItemsFor(workout.id);
    final progress = <DayWorkoutItemProgress>[];
    for (final item in items) {
      final sets = await _setsForDayItem(item.id);
      final ex = await exerciseById(item.exerciseId);
      progress.add(
        DayWorkoutItemProgress(
          item: item,
          completedSets: sets.length,
          unit: ExerciseUnit.fromStorage(ex?.unit ?? 'reps'),
        ),
      );
    }
    return DayWorkoutSnapshot(workout: workout, items: progress);
  }

  /// Emits when day workout rows or that day's set logs change.
  Stream<DayWorkoutSnapshot> watchDayWorkout(DateTime day) {
    final start = _dayStart(day);
    late final StreamController<DayWorkoutSnapshot> controller;
    var pushing = false;
    var dirty = false;

    Future<void> push() async {
      if (controller.isClosed) return;
      if (pushing) {
        dirty = true;
        return;
      }
      pushing = true;
      try {
        do {
          dirty = false;
          if (controller.isClosed) return;
          controller.add(await daySnapshot(start));
        } while (dirty && !controller.isClosed);
      } finally {
        pushing = false;
      }
    }

    controller = StreamController<DayWorkoutSnapshot>(
      onListen: () {
        final subs = <StreamSubscription<dynamic>>[
          (_db.select(_db.dayWorkouts)..where((t) => t.date.equals(start)))
              .watch()
              .listen((_) => push()),
          (_db.select(_db.dayWorkoutItems)).watch().listen((_) => push()),
          (_db.select(_db.workoutSetLogs)..where((t) => t.date.equals(start)))
              .watch()
              .listen((_) => push()),
        ];
        controller.onCancel = () async {
          for (final s in subs) {
            await s.cancel();
          }
        };
        push();
      },
    );
    return controller.stream;
  }

  Future<List<WorkoutSetLog>> _setsForDayItem(int dayWorkoutItemId) {
    return (_db.select(_db.workoutSetLogs)
          ..where((t) => t.dayWorkoutItemId.equals(dayWorkoutItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.setIndex)]))
        .get();
  }

  Future<int> _countSetsForDayItem(int dayWorkoutItemId) async {
    final rows = await _setsForDayItem(dayWorkoutItemId);
    return rows.length;
  }

  /// Replaces any existing day workout with a snapshot from [planId].
  Future<void> applyPlanToDay({
    required int planId,
    required DateTime day,
  }) async {
    final plan = await (_db.select(_db.workoutPlans)
          ..where((t) => t.id.equals(planId)))
        .getSingleOrNull();
    if (plan == null) throw StateError('计划不存在');
    final planItems = await itemsFor(planId);
    if (planItems.isEmpty) throw StateError('计划没有动作');

    final start = _dayStart(day);
    await _db.transaction(() async {
      await _clearDayWorkout(start);
      final dayId = await _db.into(_db.dayWorkouts).insert(
            DayWorkoutsCompanion.insert(
              date: start,
              planId: Value(plan.id),
              planName: Value(plan.name),
            ),
          );
      for (var i = 0; i < planItems.length; i++) {
        final item = planItems[i];
        await _db.into(_db.dayWorkoutItems).insert(
              DayWorkoutItemsCompanion.insert(
                dayWorkoutId: dayId,
                exerciseId: item.exerciseId,
                exerciseName: item.exerciseName,
                targetSets: item.targetSets,
                targetReps: item.targetReps,
                sortOrder: Value(i),
              ),
            );
      }
    });
  }

  Future<void> _clearDayWorkout(DateTime start) async {
    final existing = await (_db.select(_db.dayWorkouts)
          ..where((t) => t.date.equals(start)))
        .getSingleOrNull();
    if (existing == null) return;
    final items = await dayItemsFor(existing.id);
    for (final item in items) {
      await (_db.delete(_db.workoutSetLogs)
            ..where((t) => t.dayWorkoutItemId.equals(item.id)))
          .go();
    }
    await (_db.delete(_db.dayWorkoutItems)
          ..where((t) => t.dayWorkoutId.equals(existing.id)))
        .go();
    await (_db.delete(_db.dayWorkouts)..where((t) => t.id.equals(existing.id)))
        .go();
  }

  Future<void> addQuickDayItem({
    required DateTime day,
    required int exerciseId,
    required int targetSets,
    required int targetReps,
  }) async {
    final ex = await exerciseById(exerciseId);
    if (ex == null) throw StateError('动作不存在');
    final start = _dayStart(day);

    await _db.transaction(() async {
      var workout = await (_db.select(_db.dayWorkouts)
            ..where((t) => t.date.equals(start)))
          .getSingleOrNull();
      if (workout == null) {
        final id = await _db.into(_db.dayWorkouts).insert(
              DayWorkoutsCompanion.insert(date: start),
            );
        workout = await (_db.select(_db.dayWorkouts)
              ..where((t) => t.id.equals(id)))
            .getSingle();
      }
      final existing = await dayItemsFor(workout.id);
      await _db.into(_db.dayWorkoutItems).insert(
            DayWorkoutItemsCompanion.insert(
              dayWorkoutId: workout.id,
              exerciseId: ex.id,
              exerciseName: ex.name,
              targetSets: targetSets,
              targetReps: targetReps,
              sortOrder: Value(existing.length),
            ),
          );
    });
  }

  Future<void> setItemDone(int dayWorkoutItemId, bool done) async {
    await (_db.update(_db.dayWorkoutItems)
          ..where((t) => t.id.equals(dayWorkoutItemId)))
        .write(DayWorkoutItemsCompanion(done: Value(done)));
  }

  /// Removes one day-workout item and its set logs; drops empty day row.
  Future<void> deleteDayWorkoutItem(int dayWorkoutItemId) async {
    await _db.transaction(() async {
      final item = await (_db.select(_db.dayWorkoutItems)
            ..where((t) => t.id.equals(dayWorkoutItemId)))
          .getSingleOrNull();
      if (item == null) return;

      await (_db.delete(_db.workoutSetLogs)
            ..where((t) => t.dayWorkoutItemId.equals(dayWorkoutItemId)))
          .go();
      await (_db.delete(_db.dayWorkoutItems)
            ..where((t) => t.id.equals(dayWorkoutItemId)))
          .go();

      final remaining = await dayItemsFor(item.dayWorkoutId);
      if (remaining.isEmpty) {
        await (_db.delete(_db.dayWorkouts)
              ..where((t) => t.id.equals(item.dayWorkoutId)))
            .go();
      }
    });
  }

  /// Sets completed set count and per-set reps/seconds for a day item.
  Future<void> updateDayItemProgress({
    required int dayWorkoutItemId,
    required DateTime day,
    required int completedSets,
    required int perSetValue,
    required ExerciseUnit unit,
  }) async {
    if (completedSets < 0) throw ArgumentError('组数不能为负');
    if (perSetValue <= 0) throw ArgumentError('次数/秒须大于 0');

    final start = _dayStart(day);
    await _db.transaction(() async {
      final item = await (_db.select(_db.dayWorkoutItems)
            ..where((t) => t.id.equals(dayWorkoutItemId)))
          .getSingleOrNull();
      if (item == null) throw StateError('待办不存在');

      await (_db.update(_db.dayWorkoutItems)
            ..where((t) => t.id.equals(dayWorkoutItemId)))
          .write(
            DayWorkoutItemsCompanion(
              targetReps: Value(perSetValue),
              done: Value(completedSets >= item.targetSets),
            ),
          );

      await (_db.delete(_db.workoutSetLogs)
            ..where((t) => t.dayWorkoutItemId.equals(dayWorkoutItemId)))
          .go();

      for (var i = 1; i <= completedSets; i++) {
        await _db.into(_db.workoutSetLogs).insert(
              WorkoutSetLogsCompanion.insert(
                date: start,
                exerciseId: item.exerciseId,
                exerciseName: item.exerciseName,
                setIndex: i,
                reps: Value(unit == ExerciseUnit.reps ? perSetValue : null),
                durationSec:
                    Value(unit == ExerciseUnit.seconds ? perSetValue : null),
                dayWorkoutItemId: Value(dayWorkoutItemId),
              ),
            );
      }
    });
  }

  Future<int> logSet({
    required DateTime day,
    required int exerciseId,
    required String exerciseName,
    int? dayWorkoutItemId,
    int? reps,
    int? durationSec,
  }) async {
    final start = _dayStart(day);
    return _db.transaction(() async {
      var setIndex = 1;
      if (dayWorkoutItemId != null) {
        setIndex = await _countSetsForDayItem(dayWorkoutItemId) + 1;
      } else {
        final existing = await (_db.select(_db.workoutSetLogs)
              ..where(
                (t) =>
                    t.date.equals(start) &
                    t.exerciseId.equals(exerciseId) &
                    t.dayWorkoutItemId.isNull(),
              ))
            .get();
        setIndex = existing.length + 1;
      }

      final id = await _db.into(_db.workoutSetLogs).insert(
            WorkoutSetLogsCompanion.insert(
              date: start,
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              setIndex: setIndex,
              reps: Value(reps),
              durationSec: Value(durationSec),
              dayWorkoutItemId: Value(dayWorkoutItemId),
            ),
          );

      if (dayWorkoutItemId != null) {
        final item = await (_db.select(_db.dayWorkoutItems)
              ..where((t) => t.id.equals(dayWorkoutItemId)))
            .getSingleOrNull();
        if (item != null) {
          final count = await _countSetsForDayItem(dayWorkoutItemId);
          if (count >= item.targetSets && !item.done) {
            await setItemDone(dayWorkoutItemId, true);
          }
        }
      }
      return id;
    });
  }

  Future<List<WorkoutHistoryDay>> recentHistory({int limitDays = 14}) async {
    final logs = await (_db.select(_db.workoutSetLogs)
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.asc(t.exerciseName),
            (t) => OrderingTerm.asc(t.setIndex),
          ]))
        .get();
    final byDay = <DateTime, List<WorkoutSetLog>>{};
    for (final log in logs) {
      final day = _dayStart(log.date);
      byDay.putIfAbsent(day, () => []).add(log);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final d in days.take(limitDays))
        WorkoutHistoryDay(date: d, sets: byDay[d]!),
    ];
  }

  Future<void> clearAll() async {
    await _db.delete(_db.workoutSetLogs).go();
    await _db.delete(_db.dayWorkoutItems).go();
    await _db.delete(_db.dayWorkouts).go();
    await _db.delete(_db.workoutPlanItems).go();
    await _db.delete(_db.workoutPlans).go();
    await (_db.delete(_db.exercises)..where((t) => t.isCustom.equals(true)))
        .go();
  }
}
