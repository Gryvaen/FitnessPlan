import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../db.dart';

class ExerciseTargetChoice {
  const ExerciseTargetChoice({required this.sets, required this.reps});

  final int sets;
  final int reps;
}

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
    this.category = 'chest',
  });

  final DayWorkoutItem item;
  final int completedSets;
  final ExerciseUnit unit;
  final String category;
}

class DayWorkoutGroup {
  const DayWorkoutGroup({required this.workout, required this.items});

  final DayWorkout workout;
  final List<DayWorkoutItemProgress> items;

  int get doneCount => items.where((e) => e.item.done).length;
}

class DayWorkoutSnapshot {
  const DayWorkoutSnapshot({this.groups = const []});

  final List<DayWorkoutGroup> groups;

  bool get isEmpty => groups.isEmpty || groups.every((g) => g.items.isEmpty);

  List<DayWorkoutItemProgress> get items => [
    for (final group in groups) ...group.items,
  ];

  int get doneCount => items.where((e) => e.item.done).length;
}

/// Categories left out of history highlighting: cardio, anaerobic, core,
/// plus legacy keys that were migrated into core.
const historyHighlightExcludedCategories = {
  'cardio',
  'anaerobic',
  'core',
  'core_timed',
  'custom',
};

class WorkoutHistoryDay {
  const WorkoutHistoryDay({
    required this.date,
    required this.sets,
    this.completedItems = const [],
    this.planSummaries = const [],
    this.highlightExerciseIds = const {},
  });

  final DateTime date;
  final List<WorkoutSetLog> sets;
  final List<DayWorkoutItem> completedItems;
  final List<WorkoutHistoryPlanSummary> planSummaries;

  /// Exercises on this day that can match another day in history.
  /// Includes every day-workout item and every set log, except cardio,
  /// anaerobic, and core.
  final Set<int> highlightExerciseIds;

  bool get hasActivity =>
      sets.isNotEmpty || completedItems.isNotEmpty || planSummaries.isNotEmpty;
}

/// Per-day-workout completion summary (one per [DayWorkout] on that day).
class WorkoutHistoryPlanSummary {
  const WorkoutHistoryPlanSummary({
    required this.planId,
    required this.planName,
    required this.doneCount,
    required this.totalCount,
  });

  /// Null for a free-form day workout that was never saved as a plan.
  final int? planId;
  final String? planName;
  final int doneCount;
  final int totalCount;
}

class _WorkoutHistoryAgg {
  _WorkoutHistoryAgg({this.planId, this.planName});
  final int? planId;
  final String? planName;
  int total = 0;
  int done = 0;
}

class WorkoutPlanSummary {
  const WorkoutPlanSummary({required this.plan, required this.items});

  final WorkoutPlan plan;
  final List<WorkoutPlanItem> items;

  /// Whether this plan belongs under [category] when filtering/grouping.
  ///
  /// Core, cardio, and anaerobic match only when every exercise with a known
  /// category is that type. A mixed plan (squat + plank) stays out of core.
  /// Other categories match when any exercise is that type.
  bool matchesExerciseCategory(
    String category,
    Map<int, String> categoryByExerciseId,
  ) {
    final known = [
      for (final item in items)
        if (categoryByExerciseId[item.exerciseId] case final String value)
          value,
    ];
    if (known.isEmpty) return false;
    if (kSoloPlanCategories.contains(category)) {
      return known.every((value) => value == category);
    }
    return known.contains(category);
  }
}

/// Core, cardio, and anaerobic match only when the whole plan is that type.
const kSoloPlanCategories = {'cardio', 'anaerobic', 'core'};

class CopyDayWorkoutResult {
  const CopyDayWorkoutResult({
    required this.groupsCopied,
    required this.itemsCopied,
    required this.groupsSkippedDuplicate,
  });

  final int groupsCopied;
  final int itemsCopied;
  final int groupsSkippedDuplicate;
}

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  DateTime _dayStart(DateTime d) => CalendarDay.dayOnly(d);

  Future<DateTime?> _dayForWorkoutItem(int dayWorkoutItemId) async {
    final item = await (_db.select(
      _db.dayWorkoutItems,
    )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
    if (item == null) return null;
    final workout = await (_db.select(
      _db.dayWorkouts,
    )..where((t) => t.id.equals(item.dayWorkoutId))).getSingleOrNull();
    return workout?.date;
  }

  Future<void> _ensureEditableWorkoutItem(
    int dayWorkoutItemId, {
    DateTime? expectedDay,
  }) async {
    final actualDay = await _dayForWorkoutItem(dayWorkoutItemId);
    if (actualDay == null) throw StateError('待办不存在');
    CalendarDay.ensureEditableDay(actualDay);
    if (expectedDay != null &&
        CalendarDay.dayOnly(actualDay) != CalendarDay.dayOnly(expectedDay)) {
      throw ArgumentError('待办不属于指定日期');
    }
  }

  Stream<List<Exercise>> watchExercises() {
    return (_db.select(_db.exercises)..orderBy([
          (t) => OrderingTerm.asc(t.isCustom),
          (t) => OrderingTerm.asc(t.name),
        ]))
        .watch();
  }

  Future<List<Exercise>> listExercises() {
    return (_db.select(_db.exercises)..orderBy([
          (t) => OrderingTerm.asc(t.isCustom),
          (t) => OrderingTerm.asc(t.name),
        ]))
        .get();
  }

  // `exercises` is small and changes only through the three mutators below
  // (add/update/delete), but `exerciseById` is called once per workout item
  // inside `daySnapshot`/`_progressForItem` — which reruns for every day a
  // `watchDayWorkout` stream re-triggers on (any write anywhere in
  // day_workouts/day_workout_items/workout_set_logs, per Drift's per-table
  // watch granularity). Caching turns repeated lookups of the same id
  // during one session into memory reads instead of a fresh SELECT each
  // time; cleared on any exercise mutation to stay correct.
  final _exerciseCache = <int, Exercise?>{};

  Future<Exercise?> exerciseById(int id) async {
    if (_exerciseCache.containsKey(id)) return _exerciseCache[id];
    final ex = await (_db.select(
      _db.exercises,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    _exerciseCache[id] = ex;
    return ex;
  }

  Future<Exercise?> exerciseByName(String name) {
    final trimmed = name.trim();
    return (_db.select(
      _db.exercises,
    )..where((t) => t.name.equals(trimmed))).getSingleOrNull();
  }

  Future<int> addCustomExercise({
    required String name,
    required ExerciseUnit unit,
    String category = 'chest',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('动作名称不能为空');
    if (!kExerciseCategoryOrder.contains(category)) {
      throw ArgumentError('无效的动作分类');
    }
    final existing = await exerciseByName(trimmed);
    if (existing != null) {
      throw StateError('已存在同名动作，请换一个名称');
    }
    return _db
        .into(_db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: trimmed,
            unit: unit.name,
            isCustom: const Value(true),
            category: Value(category),
          ),
        );
  }

  Future<void> updateExercise({
    required int id,
    required String name,
    required ExerciseUnit unit,
    required String category,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('动作名称不能为空');
    if (!kExerciseCategoryOrder.contains(category)) {
      throw ArgumentError('无效的动作分类');
    }
    final existing = await exerciseById(id);
    if (existing == null) throw StateError('动作不存在');
    final duplicate = await exerciseByName(trimmed);
    if (duplicate != null && duplicate.id != id) {
      throw StateError('已存在同名动作，请换一个名称');
    }
    final nameChanged = trimmed != existing.name;
    await _db.transaction(() async {
      await (_db.update(_db.exercises)..where((t) => t.id.equals(id))).write(
        ExercisesCompanion(
          name: Value(trimmed),
          unit: Value(unit.name),
          category: Value(category),
        ),
      );
      if (!nameChanged) return;
      // Names are copied onto plans, today's items, and set logs. Keep those
      // copies in step so a rename shows up everywhere at once.
      await (_db.update(_db.workoutPlanItems)
            ..where((t) => t.exerciseId.equals(id)))
          .write(WorkoutPlanItemsCompanion(exerciseName: Value(trimmed)));
      await (_db.update(_db.dayWorkoutItems)
            ..where((t) => t.exerciseId.equals(id)))
          .write(DayWorkoutItemsCompanion(exerciseName: Value(trimmed)));
      await (_db.update(_db.workoutSetLogs)
            ..where((t) => t.exerciseId.equals(id)))
          .write(WorkoutSetLogsCompanion(exerciseName: Value(trimmed)));
    });
    _exerciseCache.remove(id);
  }

  Future<void> deleteCustomExercise(int id) async {
    final ex = await exerciseById(id);
    if (ex == null || !ex.isCustom) {
      throw StateError('只能删除自定义动作');
    }
    await (_db.delete(_db.exercises)..where((t) => t.id.equals(id))).go();
    _exerciseCache.remove(id);
  }

  Future<List<WorkoutPlanSummary>> listPlanSummaries() async {
    await discardRetiredOtherPlan();
    final plans = await (_db.select(
      _db.workoutPlans,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    if (plans.isEmpty) return const [];

    // One batched query for every plan's items instead of one per plan.
    // [watchPlanSummaries] reruns this when either table changes.
    final planIds = [for (final p in plans) p.id];
    final allItems =
        await (_db.select(_db.workoutPlanItems)
              ..where((t) => t.planId.isIn(planIds))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    final itemsByPlan = <int, List<WorkoutPlanItem>>{};
    for (final item in allItems) {
      (itemsByPlan[item.planId] ??= []).add(item);
    }
    return [
      for (final plan in plans)
        WorkoutPlanSummary(plan: plan, items: itemsByPlan[plan.id] ?? const []),
    ];
  }

  Stream<List<WorkoutPlan>> watchPlans() {
    return (_db.select(
      _db.workoutPlans,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// Plan list with exercise counts. Emits when a plan row or a template
  /// exercise row changes, so dragging an exercise in or out updates the
  /// count without waiting for the plan itself to be rewritten.
  Stream<List<WorkoutPlanSummary>> watchPlanSummaries() {
    late final StreamController<List<WorkoutPlanSummary>> controller;
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
          controller.add(await listPlanSummaries());
        } while (dirty && !controller.isClosed);
      } finally {
        pushing = false;
      }
    }

    controller = StreamController<List<WorkoutPlanSummary>>(
      onListen: () {
        final subs = <StreamSubscription<dynamic>>[
          watchPlans().listen((_) => push()),
          _db.select(_db.workoutPlanItems).watch().listen((_) => push()),
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
      final planId = await _db
          .into(_db.workoutPlans)
          .insert(
            WorkoutPlansCompanion.insert(
              name: trimmed,
              createdAt: DateTime.now(),
            ),
          );
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await _db
            .into(_db.workoutPlanItems)
            .insert(
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

  Future<int> createPlanFromDay({
    required DateTime day,
    required String name,
  }) async {
    final snap = await daySnapshot(day);
    if (snap.isEmpty) throw StateError('当日无训练可保存');
    final items = [
      for (final progress in snap.items)
        PlanDraftItem(
          exerciseId: progress.item.exerciseId,
          exerciseName: progress.item.exerciseName,
          targetSets: progress.item.targetSets,
          targetReps: progress.item.targetReps,
        ),
    ];
    return createPlan(name: name, items: items);
  }

  Future<void> updatePlan({
    required int planId,
    required String name,
    required List<PlanDraftItem> items,
    DateTime? syncDay,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('计划名称不能为空');
    if (items.isEmpty) throw ArgumentError('至少添加一个动作');
    if (syncDay != null) CalendarDay.ensureEditableDay(syncDay);

    await _db.transaction(() async {
      await (_db.update(_db.workoutPlans)..where((t) => t.id.equals(planId)))
          .write(WorkoutPlansCompanion(name: Value(trimmed)));
      await (_db.delete(
        _db.workoutPlanItems,
      )..where((t) => t.planId.equals(planId))).go();
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await _db
            .into(_db.workoutPlanItems)
            .insert(
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
      if (syncDay != null) {
        await _syncPlanToDay(
          planId: planId,
          planName: trimmed,
          items: items,
          day: syncDay,
        );
      }
    });
  }

  Future<void> _syncPlanToDay({
    required int planId,
    required String planName,
    required List<PlanDraftItem> items,
    required DateTime day,
  }) async {
    final groups =
        await (_db.select(_db.dayWorkouts)..where(
              (t) => t.planId.equals(planId) & t.date.equals(_dayStart(day)),
            ))
            .get();
    for (final group in groups) {
      await (_db.update(_db.dayWorkouts)..where((t) => t.id.equals(group.id)))
          .write(DayWorkoutsCompanion(planName: Value(planName)));
      final remaining = (await dayItemsFor(group.id)).toList();
      for (var i = 0; i < items.length; i++) {
        final draft = items[i];
        final existingIndex = remaining.indexWhere(
          (row) => row.exerciseId == draft.exerciseId,
        );
        if (existingIndex >= 0) {
          final existing = remaining.removeAt(existingIndex);
          await (_db.update(
            _db.dayWorkoutItems,
          )..where((t) => t.id.equals(existing.id))).write(
            DayWorkoutItemsCompanion(
              exerciseName: Value(draft.exerciseName),
              targetSets: Value(draft.targetSets),
              targetReps: Value(draft.targetReps),
              sortOrder: Value(i),
            ),
          );
        } else {
          await _db
              .into(_db.dayWorkoutItems)
              .insert(
                DayWorkoutItemsCompanion.insert(
                  dayWorkoutId: group.id,
                  exerciseId: draft.exerciseId,
                  exerciseName: draft.exerciseName,
                  targetSets: draft.targetSets,
                  targetReps: draft.targetReps,
                  sortOrder: Value(i),
                ),
              );
        }
      }
      for (final removed in remaining) {
        await (_db.delete(
          _db.workoutSetLogs,
        )..where((t) => t.dayWorkoutItemId.equals(removed.id))).go();
        await (_db.delete(
          _db.dayWorkoutItems,
        )..where((t) => t.id.equals(removed.id))).go();
      }
    }
  }

  Future<void> deletePlan(int planId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.workoutPlanItems,
      )..where((t) => t.planId.equals(planId))).go();
      await (_db.delete(
        _db.workoutPlans,
      )..where((t) => t.id.equals(planId))).go();
    });
  }

  Future<List<DayWorkoutItem>> dayItemsFor(int dayWorkoutId) {
    return (_db.select(_db.dayWorkoutItems)
          ..where((t) => t.dayWorkoutId.equals(dayWorkoutId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Current day-workout items for [planId] on [day], if that plan has an
  /// applied day-workout there — reflects whatever is actually scheduled for
  /// that day right now (including ad-hoc "quick add"/removed items), unlike
  /// [itemsFor] which reads the saved plan template. Empty when the plan
  /// hasn't been applied to that day (or was since removed).
  Future<List<DayWorkoutItem>> dayItemsForPlanOnDay({
    required int planId,
    required DateTime day,
  }) async {
    final start = _dayStart(day);
    final groups = await (_db.select(
      _db.dayWorkouts,
    )..where((t) => t.planId.equals(planId) & t.date.equals(start))).get();
    if (groups.isEmpty) return const [];
    return dayItemsFor(groups.first.id);
  }

  Future<List<DayWorkout>> dayWorkoutsFor(DateTime day) {
    final start = _dayStart(day);
    return (_db.select(_db.dayWorkouts)
          ..where((t) => t.date.equals(start))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<int> _nextGroupSortOrder(DateTime start) async {
    final rows = await (_db.select(
      _db.dayWorkouts,
    )..where((t) => t.date.equals(start))).get();
    return rows.length;
  }

  Future<DayWorkoutItemProgress> _progressForItem(DayWorkoutItem item) async {
    final sets = await _setsForDayItem(item.id);
    final ex = await exerciseById(item.exerciseId);
    return DayWorkoutItemProgress(
      item: item,
      completedSets: sets.length,
      unit: ExerciseUnit.fromStorage(ex?.unit ?? 'reps'),
      category: ex?.category ?? 'chest',
    );
  }

  Future<DayWorkoutSnapshot> daySnapshot(DateTime day) async {
    final workouts = await dayWorkoutsFor(day);
    if (workouts.isEmpty) return const DayWorkoutSnapshot();
    final groups = <DayWorkoutGroup>[];
    for (final workout in workouts) {
      final items = await dayItemsFor(workout.id);
      final progress = <DayWorkoutItemProgress>[];
      for (final item in items) {
        progress.add(await _progressForItem(item));
      }
      if (progress.isEmpty) continue;
      groups.add(DayWorkoutGroup(workout: workout, items: progress));
    }
    return DayWorkoutSnapshot(groups: groups);
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
          (_db.select(
            _db.dayWorkouts,
          )..where((t) => t.date.equals(start))).watch().listen((_) => push()),
          (_db.select(_db.dayWorkoutItems)).watch().listen((_) => push()),
          (_db.select(
            _db.workoutSetLogs,
          )..where((t) => t.date.equals(start))).watch().listen((_) => push()),
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

  /// Combined [daySnapshot] for a whole set of days in one subscription —
  /// used where a screen would otherwise watch [watchDayWorkout] once per
  /// day (e.g. the cultivation history screen's rolling window of up to 14
  /// days). One shared set of table-level watches replaces N independent
  /// ones, and one push recomputes every requested day together instead of
  /// N separate `StreamController`s each firing their own push loop for the
  /// same underlying write.
  Stream<Map<DateTime, DayWorkoutSnapshot>> watchDayWorkoutsForDays(
    List<DateTime> days,
  ) {
    final starts = {for (final d in days) _dayStart(d)}.toList();
    if (starts.isEmpty) return Stream.value(const {});
    late final StreamController<Map<DateTime, DayWorkoutSnapshot>> controller;
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
          final out = <DateTime, DayWorkoutSnapshot>{};
          for (final day in starts) {
            out[day] = await daySnapshot(day);
          }
          controller.add(out);
        } while (dirty && !controller.isClosed);
      } finally {
        pushing = false;
      }
    }

    controller = StreamController<Map<DateTime, DayWorkoutSnapshot>>(
      onListen: () {
        final subs = <StreamSubscription<dynamic>>[
          (_db.select(
            _db.dayWorkouts,
          )..where((t) => t.date.isIn(starts))).watch().listen((_) => push()),
          (_db.select(_db.dayWorkoutItems)).watch().listen((_) => push()),
          (_db.select(
            _db.workoutSetLogs,
          )..where((t) => t.date.isIn(starts))).watch().listen((_) => push()),
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

  /// Most recent earlier day on which this exercise was actually performed.
  Future<DayWorkoutItem?> _lastTrainedItem(int exerciseId, DateTime day) async {
    final rows =
        await (_db.select(_db.dayWorkoutItems).join([
                innerJoin(
                  _db.dayWorkouts,
                  _db.dayWorkouts.id.equalsExp(
                    _db.dayWorkoutItems.dayWorkoutId,
                  ),
                ),
              ])
              ..where(
                _db.dayWorkoutItems.exerciseId.equals(exerciseId) &
                    _db.dayWorkouts.date.isSmallerThanValue(_dayStart(day)),
              )
              ..orderBy([
                OrderingTerm.desc(_db.dayWorkouts.date),
                OrderingTerm.desc(_db.dayWorkoutItems.id),
              ]))
            .get();
    for (final row in rows) {
      final item = row.readTable(_db.dayWorkoutItems);
      if (item.done || await _countSetsForDayItem(item.id) > 0) return item;
    }
    return null;
  }

  /// Appends a plan snapshot as a new day-workout group (does not clear existing).
  Future<void> applyPlanToDay({
    required int planId,
    required DateTime day,
  }) async {
    CalendarDay.ensureEditableDay(day);
    final plan = await (_db.select(
      _db.workoutPlans,
    )..where((t) => t.id.equals(planId))).getSingleOrNull();
    if (plan == null) throw StateError('计划不存在');
    final planItems = await itemsFor(planId);
    if (planItems.isEmpty) throw StateError('计划没有动作');

    final start = _dayStart(day);
    await _db.transaction(() async {
      final dayId = await _db
          .into(_db.dayWorkouts)
          .insert(
            DayWorkoutsCompanion.insert(
              date: start,
              planId: Value(plan.id),
              planName: Value(plan.name),
              sortOrder: Value(await _nextGroupSortOrder(start)),
            ),
          );
      for (var i = 0; i < planItems.length; i++) {
        final item = planItems[i];
        final previous = await _lastTrainedItem(item.exerciseId, start);
        await _db
            .into(_db.dayWorkoutItems)
            .insert(
              DayWorkoutItemsCompanion.insert(
                dayWorkoutId: dayId,
                exerciseId: item.exerciseId,
                exerciseName: item.exerciseName,
                targetSets: previous?.targetSets ?? item.targetSets,
                targetReps: previous?.targetReps ?? item.targetReps,
                actualWeightKg: Value(previous?.actualWeightKg),
                actualWeightUnit: Value(previous?.actualWeightUnit),
                sortOrder: Value(i),
              ),
            );
      }
    });
  }

  /// Appends [from]'s day-workout groups absent by plan name on [to]. New
  /// groups carry exercise targets but no `done`/set-log progress.
  ///
  /// When [sourceDayWorkoutId] is set, only that group is copied.
  Future<CopyDayWorkoutResult> copyDayWorkout({
    required DateTime from,
    required DateTime to,
    int? sourceDayWorkoutId,
  }) async {
    CalendarDay.ensureEditableDay(to);
    final snap = await daySnapshot(from);
    final groups = sourceDayWorkoutId == null
        ? snap.groups
        : snap.groups
              .where((g) => g.workout.id == sourceDayWorkoutId)
              .toList(growable: false);
    if (groups.isEmpty) {
      return const CopyDayWorkoutResult(
        groupsCopied: 0,
        itemsCopied: 0,
        groupsSkippedDuplicate: 0,
      );
    }

    final start = _dayStart(to);
    var itemsCopied = 0;
    var groupsCopied = 0;
    var groupsSkippedDuplicate = 0;
    await _db.transaction(() async {
      var nextGroupSortOrder = await _nextGroupSortOrder(start);
      final existing = await dayWorkoutsFor(start);
      String nameKey(String? name) => name?.trim() ?? '';
      final names = {for (final group in existing) nameKey(group.planName)};
      for (final group in groups) {
        if (!names.add(nameKey(group.workout.planName))) {
          groupsSkippedDuplicate++;
          continue;
        }
        final dayId = await _db
            .into(_db.dayWorkouts)
            .insert(
              DayWorkoutsCompanion.insert(
                date: start,
                planId: Value(group.workout.planId),
                planName: Value(group.workout.planName),
                sortOrder: Value(nextGroupSortOrder++),
              ),
            );
        for (var i = 0; i < group.items.length; i++) {
          final item = group.items[i].item;
          await _db
              .into(_db.dayWorkoutItems)
              .insert(
                DayWorkoutItemsCompanion.insert(
                  dayWorkoutId: dayId,
                  exerciseId: item.exerciseId,
                  exerciseName: item.exerciseName,
                  targetSets: item.targetSets,
                  targetReps: item.targetReps,
                  sortOrder: Value(i),
                ),
              );
          itemsCopied++;
        }
        groupsCopied++;
      }
    });
    return CopyDayWorkoutResult(
      groupsCopied: groupsCopied,
      itemsCopied: itemsCopied,
      groupsSkippedDuplicate: groupsSkippedDuplicate,
    );
  }

  Future<void> _deleteDayWorkoutById(int dayWorkoutId) async {
    final items = await dayItemsFor(dayWorkoutId);
    for (final item in items) {
      await (_db.delete(
        _db.workoutSetLogs,
      )..where((t) => t.dayWorkoutItemId.equals(item.id))).go();
    }
    await (_db.delete(
      _db.dayWorkoutItems,
    )..where((t) => t.dayWorkoutId.equals(dayWorkoutId))).go();
    await (_db.delete(
      _db.dayWorkouts,
    )..where((t) => t.id.equals(dayWorkoutId))).go();
  }

  /// Removes an entire day-workout group and its set logs.
  Future<void> deleteDayWorkout(int dayWorkoutId) async {
    final workout = await (_db.select(
      _db.dayWorkouts,
    )..where((t) => t.id.equals(dayWorkoutId))).getSingleOrNull();
    if (workout == null) return;
    CalendarDay.ensureEditableDay(workout.date);
    await _db.transaction(() async {
      await _deleteDayWorkoutById(dayWorkoutId);
    });
  }

  /// Last chosen sets and reps/seconds for [exerciseId].
  ///
  /// Prefers the newest day-workout item (logging a set writes the chosen
  /// count back onto that item), then the newest plan item. Null when the
  /// exercise has never been given a target.
  Future<ExerciseTargetChoice?> lastExerciseTargets(int exerciseId) async {
    final dayRow =
        await (_db.select(_db.dayWorkoutItems).join([
                innerJoin(
                  _db.dayWorkouts,
                  _db.dayWorkouts.id.equalsExp(
                    _db.dayWorkoutItems.dayWorkoutId,
                  ),
                ),
              ])
              ..where(_db.dayWorkoutItems.exerciseId.equals(exerciseId))
              ..orderBy([
                OrderingTerm.desc(_db.dayWorkouts.date),
                OrderingTerm.desc(_db.dayWorkoutItems.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (dayRow != null) {
      final item = dayRow.readTable(_db.dayWorkoutItems);
      return ExerciseTargetChoice(sets: item.targetSets, reps: item.targetReps);
    }
    final planItem =
        await (_db.select(_db.workoutPlanItems)
              ..where((t) => t.exerciseId.equals(exerciseId))
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (planItem == null) return null;
    return ExerciseTargetChoice(
      sets: planItem.targetSets,
      reps: planItem.targetReps,
    );
  }

  /// Last chosen reps or seconds for [exerciseId]. See [lastExerciseTargets].
  Future<int?> lastTargetReps(int exerciseId) async {
    return (await lastExerciseTargets(exerciseId))?.reps;
  }

  Future<void> addQuickDayItem({
    required DateTime day,
    required int exerciseId,
    required int targetSets,
    required int targetReps,
  }) async {
    CalendarDay.ensureEditableDay(day);
    final ex = await exerciseById(exerciseId);
    if (ex == null) throw StateError('动作不存在');
    final start = _dayStart(day);

    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.dayWorkouts)
                ..where((t) => t.date.equals(start) & t.planId.isNull())
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
      DayWorkout workout;
      if (existing.isNotEmpty) {
        workout = existing.first;
      } else {
        final id = await _db
            .into(_db.dayWorkouts)
            .insert(
              DayWorkoutsCompanion.insert(
                date: start,
                sortOrder: Value(await _nextGroupSortOrder(start)),
              ),
            );
        workout = await (_db.select(
          _db.dayWorkouts,
        )..where((t) => t.id.equals(id))).getSingle();
      }
      final items = await dayItemsFor(workout.id);
      await _db
          .into(_db.dayWorkoutItems)
          .insert(
            DayWorkoutItemsCompanion.insert(
              dayWorkoutId: workout.id,
              exerciseId: ex.id,
              exerciseName: ex.name,
              targetSets: targetSets,
              targetReps: targetReps,
              sortOrder: Value(items.length),
            ),
          );
    });
  }

  Future<void> setItemDone(int dayWorkoutItemId, bool done) async {
    final day = await _dayForWorkoutItem(dayWorkoutItemId);
    if (day == null) return;
    CalendarDay.ensureEditableDay(day);

    if (!done) {
      await _db.transaction(() async {
        final item = await (_db.select(
          _db.dayWorkoutItems,
        )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
        if (item == null) return;

        // Checking remembers how many sets were already logged and fills the
        // rest. Unchecking puts that count back; it does not zero the item.
        final restore = item.setsBeforeDone;
        if (restore != null) {
          final logs = await _setsForDayItem(dayWorkoutItemId);
          if (logs.length > restore) {
            final dropIds = [for (final log in logs.skip(restore)) log.id];
            await (_db.delete(
              _db.workoutSetLogs,
            )..where((t) => t.id.isIn(dropIds))).go();
          }
        }
        await (_db.update(
          _db.dayWorkoutItems,
        )..where((t) => t.id.equals(dayWorkoutItemId))).write(
          const DayWorkoutItemsCompanion(
            done: Value(false),
            setsBeforeDone: Value(null),
          ),
        );
      });
      return;
    }

    await _db.transaction(() async {
      final item = await (_db.select(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
      if (item == null) return;

      final existing = await _countSetsForDayItem(dayWorkoutItemId);
      if (existing < item.targetSets) {
        final ex = await exerciseById(item.exerciseId);
        final unit = ExerciseUnit.fromStorage(ex?.unit ?? 'reps');
        final start = _dayStart(day);
        for (var i = existing + 1; i <= item.targetSets; i++) {
          await _db
              .into(_db.workoutSetLogs)
              .insert(
                WorkoutSetLogsCompanion.insert(
                  date: start,
                  exerciseId: item.exerciseId,
                  exerciseName: item.exerciseName,
                  setIndex: i,
                  reps: Value(
                    unit == ExerciseUnit.reps ? item.targetReps : null,
                  ),
                  durationSec: Value(
                    unit == ExerciseUnit.seconds ? item.targetReps : null,
                  ),
                  dayWorkoutItemId: Value(dayWorkoutItemId),
                ),
              );
        }
      }

      await (_db.update(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).write(
        DayWorkoutItemsCompanion(
          done: const Value(true),
          // A second check while already done must not overwrite the
          // count captured the first time.
          setsBeforeDone: item.done ? const Value.absent() : Value(existing),
        ),
      );
    });
  }

  static const _retiredOtherPlanMetaKey = 'other_workout_plan_id';

  /// Removes the catch-all plan created by an earlier build. 「其他」 is only
  /// today's untitled group, not a saved template.
  Future<void> discardRetiredOtherPlan() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_retiredOtherPlanMetaKey))).getSingleOrNull();
    if (row == null) return;
    final id = int.tryParse(row.value);
    if (id != null) {
      await (_db.update(_db.dayWorkouts)..where((t) => t.planId.equals(id)))
          .write(const DayWorkoutsCompanion(planId: Value(null)));
      await (_db.delete(
        _db.workoutPlanItems,
      )..where((t) => t.planId.equals(id))).go();
      await (_db.delete(_db.workoutPlans)..where((t) => t.id.equals(id))).go();
    }
    await (_db.delete(
      _db.appMeta,
    )..where((t) => t.key.equals(_retiredOtherPlanMetaKey))).go();
  }

  /// Moves one exercise out of its plan group into today's untitled group
  /// ("其他"). Progress stays on the same row. The source plan template loses
  /// this exercise. 「其他」 itself is not a plan template.
  Future<void> moveDayWorkoutItemToOther(int dayWorkoutItemId) async {
    final day = await _dayForWorkoutItem(dayWorkoutItemId);
    if (day == null) return;
    CalendarDay.ensureEditableDay(day);
    final start = _dayStart(day);

    await _db.transaction(() async {
      final item = await (_db.select(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
      if (item == null) return;
      final source = await (_db.select(
        _db.dayWorkouts,
      )..where((t) => t.id.equals(item.dayWorkoutId))).getSingleOrNull();
      if (source == null || _isUntitledDayWorkout(source)) return;
      final otherGroupId = await _ensureUntitledDayGroup(start);
      await _moveItemOntoGroup(
        item: item,
        source: source,
        targetDayWorkoutId: otherGroupId,
      );
    });
  }

  /// Moves one exercise onto [targetDayWorkoutId], including from one named
  /// plan to another. Progress stays on the same row. A named plan's template
  /// gains or loses the exercise, and an existing row picks up today's sets
  /// and reps. An untitled 「其他」 group has no template. An emptied source
  /// day group is removed.
  Future<void> moveDayWorkoutItemIntoPlan({
    required int dayWorkoutItemId,
    required int targetDayWorkoutId,
  }) async {
    final day = await _dayForWorkoutItem(dayWorkoutItemId);
    if (day == null) return;
    CalendarDay.ensureEditableDay(day);
    final start = _dayStart(day);

    await _db.transaction(() async {
      final item = await (_db.select(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
      if (item == null) return;
      final source = await (_db.select(
        _db.dayWorkouts,
      )..where((t) => t.id.equals(item.dayWorkoutId))).getSingleOrNull();
      if (source == null || source.id == targetDayWorkoutId) return;

      final target = await (_db.select(
        _db.dayWorkouts,
      )..where((t) => t.id.equals(targetDayWorkoutId))).getSingleOrNull();
      if (target == null || _dayStart(target.date) != start) return;

      final int resolvedTargetId;
      if (_isUntitledDayWorkout(target)) {
        resolvedTargetId = await _ensureUntitledDayGroup(start);
      } else if (target.planId == null) {
        return;
      } else {
        resolvedTargetId = target.id;
      }
      if (source.id == resolvedTargetId) return;
      await _moveItemOntoGroup(
        item: item,
        source: source,
        targetDayWorkoutId: resolvedTargetId,
      );
    });
  }

  /// Today's untitled group. It is not linked to a saved plan.
  Future<int> _ensureUntitledDayGroup(DateTime start) async {
    final groups =
        await (_db.select(_db.dayWorkouts)
              ..where((t) => t.date.equals(start))
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    for (final group in groups) {
      if (!_isUntitledDayWorkout(group)) continue;
      if (group.planId != null) {
        await (_db.update(_db.dayWorkouts)..where((t) => t.id.equals(group.id)))
            .write(const DayWorkoutsCompanion(planId: Value(null)));
      }
      return group.id;
    }
    return _db
        .into(_db.dayWorkouts)
        .insert(
          DayWorkoutsCompanion.insert(
            date: start,
            sortOrder: Value(groups.length),
          ),
        );
  }

  Future<void> _moveItemOntoGroup({
    required DayWorkoutItem item,
    required DayWorkout source,
    required int targetDayWorkoutId,
  }) async {
    final target = await (_db.select(
      _db.dayWorkouts,
    )..where((t) => t.id.equals(targetDayWorkoutId))).getSingleOrNull();
    if (target == null) return;

    final targetItems = await dayItemsFor(target.id);
    await (_db.update(
      _db.dayWorkoutItems,
    )..where((t) => t.id.equals(item.id))).write(
      DayWorkoutItemsCompanion(
        dayWorkoutId: Value(target.id),
        sortOrder: Value(targetItems.length),
      ),
    );

    final sourcePlanId = source.planId;
    if (sourcePlanId != null) {
      await _removeExerciseFromPlanTemplate(
        planId: sourcePlanId,
        exerciseId: item.exerciseId,
      );
    }
    final targetPlanId = target.planId;
    if (targetPlanId != null) {
      await _appendExerciseToPlanTemplate(planId: targetPlanId, item: item);
    }

    final remaining = await dayItemsFor(source.id);
    if (remaining.isEmpty) {
      await (_db.delete(
        _db.dayWorkouts,
      )..where((t) => t.id.equals(source.id))).go();
    }
  }

  Future<void> _appendExerciseToPlanTemplate({
    required int planId,
    required DayWorkoutItem item,
  }) async {
    final template = await itemsFor(planId);
    if (template.any((row) => row.exerciseId == item.exerciseId)) {
      await _writePlanItemTargets(
        planId: planId,
        exerciseId: item.exerciseId,
        targetSets: item.targetSets,
        targetReps: item.targetReps,
      );
      return;
    }
    await _db
        .into(_db.workoutPlanItems)
        .insert(
          WorkoutPlanItemsCompanion.insert(
            planId: planId,
            exerciseId: item.exerciseId,
            exerciseName: item.exerciseName,
            targetSets: item.targetSets,
            targetReps: item.targetReps,
            sortOrder: Value(template.length),
          ),
        );
  }

  /// Updates sets and reps on the template row for [exerciseId]. Leaves every
  /// other template exercise in place.
  Future<void> _writePlanItemTargets({
    required int planId,
    required int exerciseId,
    required int targetSets,
    required int targetReps,
  }) async {
    await (_db.update(_db.workoutPlanItems)..where(
          (t) => t.planId.equals(planId) & t.exerciseId.equals(exerciseId),
        ))
        .write(
          WorkoutPlanItemsCompanion(
            targetSets: Value(targetSets),
            targetReps: Value(targetReps),
          ),
        );
  }

  /// Today's order becomes the template order for exercises that are on both.
  /// Template exercises missing from today keep their relative order and sit
  /// after the ones trained today.
  Future<void> _syncPlanItemOrderFromDay({
    required int planId,
    required int dayWorkoutId,
  }) async {
    final dayItems = await dayItemsFor(dayWorkoutId);
    final template = await itemsFor(planId);
    final templateIds = {for (final row in template) row.exerciseId};
    final todayIds = <int>[];
    for (final item in dayItems) {
      if (!templateIds.contains(item.exerciseId)) continue;
      if (todayIds.contains(item.exerciseId)) continue;
      todayIds.add(item.exerciseId);
    }
    final todaySet = todayIds.toSet();
    var order = 0;
    for (final exerciseId in todayIds) {
      await (_db.update(_db.workoutPlanItems)..where(
            (t) => t.planId.equals(planId) & t.exerciseId.equals(exerciseId),
          ))
          .write(WorkoutPlanItemsCompanion(sortOrder: Value(order)));
      order++;
    }
    for (final row in template) {
      if (todaySet.contains(row.exerciseId)) continue;
      await (_db.update(_db.workoutPlanItems)
            ..where((t) => t.id.equals(row.id)))
          .write(WorkoutPlanItemsCompanion(sortOrder: Value(order)));
      order++;
    }
  }

  Future<void> _removeExerciseFromPlanTemplate({
    required int planId,
    required int exerciseId,
  }) async {
    await (_db.delete(_db.workoutPlanItems)..where(
          (t) => t.planId.equals(planId) & t.exerciseId.equals(exerciseId),
        ))
        .go();
    final left = await itemsFor(planId);
    if (left.isEmpty) {
      await (_db.delete(
        _db.workoutPlans,
      )..where((t) => t.id.equals(planId))).go();
    }
  }

  bool _isUntitledDayWorkout(DayWorkout workout) {
    final name = workout.planName?.trim();
    return name == null || name.isEmpty;
  }

  /// Removes one day-workout item and its set logs; drops an empty day row.
  /// A named plan also loses this exercise from its template, matching a drag
  /// out to 「其他」. An emptied template is deleted. 「其他」 has no template.
  Future<void> deleteDayWorkoutItem(int dayWorkoutItemId) async {
    final day = await _dayForWorkoutItem(dayWorkoutItemId);
    if (day == null) return;
    CalendarDay.ensureEditableDay(day);
    await _db.transaction(() async {
      final item = await (_db.select(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
      if (item == null) return;
      final workout = await (_db.select(
        _db.dayWorkouts,
      )..where((t) => t.id.equals(item.dayWorkoutId))).getSingleOrNull();

      await (_db.delete(
        _db.workoutSetLogs,
      )..where((t) => t.dayWorkoutItemId.equals(dayWorkoutItemId))).go();
      await (_db.delete(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).go();

      final remaining = await dayItemsFor(item.dayWorkoutId);
      if (remaining.isEmpty) {
        await (_db.delete(
          _db.dayWorkouts,
        )..where((t) => t.id.equals(item.dayWorkoutId))).go();
      }
      final planId = workout?.planId;
      if (planId != null) {
        await _removeExerciseFromPlanTemplate(
          planId: planId,
          exerciseId: item.exerciseId,
        );
      }
    });
  }

  /// Persists a new manual ordering for [day]'s workout groups (plans) —
  /// [orderedDayWorkoutIds] is the full day-workout-id list in its new
  /// display order.
  Future<void> reorderDayWorkoutGroups({
    required DateTime day,
    required List<int> orderedDayWorkoutIds,
  }) async {
    CalendarDay.ensureEditableDay(day);
    final start = _dayStart(day);

    await _db.transaction(() async {
      for (var i = 0; i < orderedDayWorkoutIds.length; i++) {
        await (_db.update(_db.dayWorkouts)..where(
              (t) =>
                  t.id.equals(orderedDayWorkoutIds[i]) & t.date.equals(start),
            ))
            .write(DayWorkoutsCompanion(sortOrder: Value(i)));
      }
    });
  }

  /// Persists a new manual ordering for [dayWorkoutId]'s items — [orderedItemIds]
  /// is the full item-id list in its new display order.
  Future<void> reorderDayWorkoutItems({
    required int dayWorkoutId,
    required List<int> orderedItemIds,
  }) async {
    final workout = await (_db.select(
      _db.dayWorkouts,
    )..where((t) => t.id.equals(dayWorkoutId))).getSingleOrNull();
    if (workout == null) return;
    CalendarDay.ensureEditableDay(workout.date);

    await _db.transaction(() async {
      for (var i = 0; i < orderedItemIds.length; i++) {
        await (_db.update(_db.dayWorkoutItems)..where(
              (t) =>
                  t.id.equals(orderedItemIds[i]) &
                  t.dayWorkoutId.equals(dayWorkoutId),
            ))
            .write(DayWorkoutItemsCompanion(sortOrder: Value(i)));
      }
      final planId = workout.planId;
      if (planId != null) {
        await _syncPlanItemOrderFromDay(
          planId: planId,
          dayWorkoutId: dayWorkoutId,
        );
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
    double? actualWeightKg,
    String? actualWeightUnit,
    String? note,
  }) async {
    CalendarDay.ensureEditableDay(day);
    await _ensureEditableWorkoutItem(dayWorkoutItemId, expectedDay: day);
    if (completedSets < 0) throw ArgumentError('组数不能为负');
    if (perSetValue <= 0) throw ArgumentError('次数/秒须大于 0');

    final start = _dayStart(day);
    final trimmedNote = note?.trim();
    final unitLabel = actualWeightKg == null
        ? null
        : (actualWeightUnit?.trim().toLowerCase() == 'lbs' ? 'lbs' : 'kg');
    await _db.transaction(() async {
      final item = await (_db.select(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
      if (item == null) throw StateError('待办不存在');

      await (_db.update(
        _db.dayWorkoutItems,
      )..where((t) => t.id.equals(dayWorkoutItemId))).write(
        DayWorkoutItemsCompanion(
          targetReps: Value(perSetValue),
          done: Value(completedSets >= item.targetSets),
          setsBeforeDone: const Value(null),
          actualWeightKg: Value(actualWeightKg),
          actualWeightUnit: Value(unitLabel),
          note: Value(
            (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
          ),
        ),
      );

      await (_db.delete(
        _db.workoutSetLogs,
      )..where((t) => t.dayWorkoutItemId.equals(dayWorkoutItemId))).go();

      for (var i = 1; i <= completedSets; i++) {
        await _db
            .into(_db.workoutSetLogs)
            .insert(
              WorkoutSetLogsCompanion.insert(
                date: start,
                exerciseId: item.exerciseId,
                exerciseName: item.exerciseName,
                setIndex: i,
                reps: Value(unit == ExerciseUnit.reps ? perSetValue : null),
                durationSec: Value(
                  unit == ExerciseUnit.seconds ? perSetValue : null,
                ),
                dayWorkoutItemId: Value(dayWorkoutItemId),
              ),
            );
      }

      final workout = await (_db.select(
        _db.dayWorkouts,
      )..where((t) => t.id.equals(item.dayWorkoutId))).getSingleOrNull();
      final planId = workout?.planId;
      if (planId != null) {
        await _writePlanItemTargets(
          planId: planId,
          exerciseId: item.exerciseId,
          targetSets: item.targetSets,
          targetReps: perSetValue,
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
    CalendarDay.ensureEditableDay(day);
    if (dayWorkoutItemId != null) {
      await _ensureEditableWorkoutItem(dayWorkoutItemId, expectedDay: day);
    }
    final start = _dayStart(day);
    return _db.transaction(() async {
      var setIndex = 1;
      if (dayWorkoutItemId != null) {
        setIndex = await _countSetsForDayItem(dayWorkoutItemId) + 1;
      } else {
        final existing =
            await (_db.select(_db.workoutSetLogs)..where(
                  (t) =>
                      t.date.equals(start) &
                      t.exerciseId.equals(exerciseId) &
                      t.dayWorkoutItemId.isNull(),
                ))
                .get();
        setIndex = existing.length + 1;
      }

      final id = await _db
          .into(_db.workoutSetLogs)
          .insert(
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
        final item = await (_db.select(
          _db.dayWorkoutItems,
        )..where((t) => t.id.equals(dayWorkoutItemId))).getSingleOrNull();
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

  SimpleSelectStatement<$WorkoutSetLogsTable, WorkoutSetLog> _historyQuery() =>
      _db.select(_db.workoutSetLogs)..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.asc(t.exerciseName),
        (t) => OrderingTerm.asc(t.setIndex),
      ]);

  Stream<List<WorkoutHistoryDay>> watchRecentHistory({
    int? limitDays = 14,
  }) => _db
      .customSelect(
        'SELECT date FROM workout_set_logs UNION '
        'SELECT day_workouts.date FROM day_workouts '
        'JOIN day_workout_items ON day_workout_items.day_workout_id = day_workouts.id',
        readsFrom: {_db.workoutSetLogs, _db.dayWorkouts, _db.dayWorkoutItems},
      )
      .watch()
      .asyncMap((_) => recentHistory(limitDays: limitDays));

  /// Continuous local calendar days ending today (newest first).
  /// Days without added items or set logs are empty placeholders.
  Stream<List<WorkoutHistoryDay>> watchRecentCalendarHistory({
    int limitDays = 14,
  }) => _db
      .customSelect(
        'SELECT date FROM workout_set_logs UNION '
        'SELECT day_workouts.date FROM day_workouts '
        'JOIN day_workout_items ON day_workout_items.day_workout_id = day_workouts.id',
        readsFrom: {_db.workoutSetLogs, _db.dayWorkouts, _db.dayWorkoutItems},
      )
      .watch()
      .asyncMap((_) => recentCalendarHistory(limitDays: limitDays));

  /// [limitDays] caps how many active days to return (newest first).
  /// Pass `null` for the full history.
  Future<List<WorkoutHistoryDay>> recentHistory({int? limitDays = 14}) async {
    final logs = await _historyQuery().get();
    final allItems = await (_db.select(_db.dayWorkoutItems).join([
      innerJoin(
        _db.dayWorkouts,
        _db.dayWorkouts.id.equalsExp(_db.dayWorkoutItems.dayWorkoutId),
      ),
    ])).get();
    final categoryById = {
      for (final exercise in await listExercises())
        exercise.id: exercise.category,
    };
    final byDay = <DateTime, List<WorkoutSetLog>>{};
    final doneByDay = <DateTime, List<DayWorkoutItem>>{};
    final workoutsByDay = <DateTime, Map<int, _WorkoutHistoryAgg>>{};
    final highlightByDay = <DateTime, Set<int>>{};
    void considerHighlight(DateTime day, int exerciseId) {
      final category = categoryById[exerciseId];
      if (category == null ||
          historyHighlightExcludedCategories.contains(category)) {
        return;
      }
      highlightByDay.putIfAbsent(day, () => {}).add(exerciseId);
    }

    for (final log in logs) {
      final day = _dayStart(log.date);
      byDay.putIfAbsent(day, () => []).add(log);
      considerHighlight(day, log.exerciseId);
    }
    for (final row in allItems) {
      final workout = row.readTable(_db.dayWorkouts);
      final item = row.readTable(_db.dayWorkoutItems);
      final day = _dayStart(workout.date);
      considerHighlight(day, item.exerciseId);
      if (item.done) {
        doneByDay.putIfAbsent(day, () => []).add(item);
      }
      final agg = workoutsByDay
          .putIfAbsent(day, () => {})
          .putIfAbsent(
            workout.id,
            () => _WorkoutHistoryAgg(
              planId: workout.planId,
              planName: workout.planName,
            ),
          );
      agg.total++;
      if (item.done) agg.done++;
    }
    // A plan or quick-added day item enters history immediately, including
    // when its completed exercise count is still zero.
    final days = {
      ...byDay.keys,
      ...doneByDay.keys,
      ...workoutsByDay.keys,
    }.toList()..sort((a, b) => b.compareTo(a));
    final selected = limitDays == null ? days : days.take(limitDays);
    return [
      for (final d in selected)
        WorkoutHistoryDay(
          date: d,
          sets: byDay[d] ?? [],
          completedItems: doneByDay[d] ?? [],
          planSummaries: [
            for (final agg in (workoutsByDay[d] ?? {}).values)
              WorkoutHistoryPlanSummary(
                planId: agg.planId,
                planName: agg.planName,
                doneCount: agg.done,
                totalCount: agg.total,
              ),
          ],
          highlightExerciseIds: Set.unmodifiable(
            highlightByDay[d] ?? const <int>{},
          ),
        ),
    ];
  }

  Future<List<WorkoutHistoryDay>> recentCalendarHistory({
    int limitDays = 14,
  }) async {
    final active = await recentHistory(limitDays: null);
    final byDate = <DateTime, WorkoutHistoryDay>{
      for (final day in active) day.date: day,
    };
    final today = CalendarDay.todayLocal();
    return [
      for (var i = 0; i < limitDays; i++)
        byDate[CalendarDay.dayOnly(today.subtract(Duration(days: i)))] ??
            WorkoutHistoryDay(
              date: CalendarDay.dayOnly(today.subtract(Duration(days: i))),
              sets: const [],
            ),
    ];
  }

  /// True when [day] has at least one set log (counts as "worked out").
  Future<bool> hasAnySetOn(DateTime day) async {
    final key = _dayStart(day);
    final row =
        await (_db.select(_db.workoutSetLogs)
              ..where((t) => t.date.equals(key))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> clearAll() async {
    await _db.delete(_db.workoutSetLogs).go();
    await _db.delete(_db.dayWorkoutItems).go();
    await _db.delete(_db.dayWorkouts).go();
    await _db.delete(_db.workoutPlanItems).go();
    await _db.delete(_db.workoutPlans).go();
    await (_db.delete(
      _db.exercises,
    )..where((t) => t.isCustom.equals(true))).go();
  }
}
