import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../db.dart';

/// Inputs for a new immutable strategy version.
class DietStrategyPlanDraft {
  const DietStrategyPlanDraft({
    required this.kind,
    required this.effectiveFrom,
    required this.referenceWeightKg,
    required this.estimatedTdee,
    required this.baseEnergy,
    this.proteinPerKg = StrategyRules.defaultProteinPerKg,
    this.fatPerKg = StrategyRules.defaultFatPerKg,
    this.schedule,
    this.carbAmplitudeG,
    this.taperStage = 0,
    this.observationStart,
    this.observationDays = StrategyRules.taperObservationDays,
    this.reason = 'created',
    this.legacyCalories,
  });

  final DietStrategyKind kind;
  final DateTime effectiveFrom;
  final double referenceWeightKg;
  final double estimatedTdee;
  final double baseEnergy;
  final double proteinPerKg;
  final double fatPerKg;
  final CarbCycleSchedule? schedule;
  final double? carbAmplitudeG;
  final int taperStage;
  final DateTime? observationStart;
  final int observationDays;
  final String reason;
  final int? legacyCalories;

  StrategyBaseline get baseline => StrategyBaseline.fromTargetEnergy(
    referenceWeightKg: referenceWeightKg,
    tdee: estimatedTdee,
    targetEnergy: baseEnergy,
    proteinPerKg: proteinPerKg,
    fatPerKg: fatPerKg,
  );

  /// Preview of the version as it would be stored (id/version = 0).
  DietStrategyPlan preview({DateTime? now}) => DietStrategyPlan(
    id: 0,
    version: 0,
    kind: kind,
    status: DietPlanStatus.active,
    effectiveFrom: StrategyDates.dayOnly(effectiveFrom),
    endedOn: null,
    createdAt: now ?? DateTime.now(),
    referenceWeightKg: referenceWeightKg,
    estimatedTdee: estimatedTdee,
    deficitFraction: baseline.deficitFraction,
    proteinPerKg: proteinPerKg,
    fatPerKg: fatPerKg,
    baseEnergy: baseEnergy,
    schedule: schedule,
    carbAmplitudeG: carbAmplitudeG,
    taperStage: taperStage,
    observationStart: observationStart,
    observationDays: observationDays,
    reason: reason,
    legacyCalories: legacyCalories,
  );

  /// Validation errors that must block persistence.
  List<StrategyIssue> validate() {
    final issues = <StrategyIssue>[...baseline.issues];
    if (kind == DietStrategyKind.carbCycle) {
      if (schedule == null) {
        issues.add(StrategyIssue.invalidSchedule);
      } else {
        final plan = CarbCyclePlanner.compute(
          baseline,
          schedule!,
          amplitudeG: carbAmplitudeG,
        );
        for (final i in plan.issues) {
          if (i != StrategyIssue.amplitudeNegligible && !issues.contains(i)) {
            issues.add(i);
          }
        }
      }
    }
    if (kind == DietStrategyKind.carbTaper) {
      final stage = CarbTaperStage.of(baseline, taperStage);
      if (!stage.feasible) issues.add(StrategyIssue.energyBelowFloor);
    }
    return issues;
  }
}

/// Persists strategy versions, per-day target snapshots and diet
/// completeness confirmations; resolves the target for any local date.
class DietStrategyRepository {
  DietStrategyRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------- plans

  DietStrategyPlan _fromRow(DietStrategyPlanRow r) => DietStrategyPlan(
    id: r.id,
    version: r.version,
    kind: DietStrategyKind.fromStorage(r.strategy),
    status: DietPlanStatus.fromStorage(r.status),
    effectiveFrom:
        StrategyDates.tryDecode(r.effectiveFrom) ?? DateTime(1970, 1, 1),
    endedOn: StrategyDates.tryDecode(r.endedOn),
    createdAt: r.createdAt,
    referenceWeightKg: r.referenceWeightKg,
    estimatedTdee: r.estimatedTdee,
    deficitFraction: r.deficitFraction,
    proteinPerKg: r.proteinPerKg,
    fatPerKg: r.fatPerKg,
    baseEnergy: r.baseEnergy,
    schedule: CarbCycleSchedule.tryParse(r.schedule),
    carbAmplitudeG: r.carbAmplitudeG,
    taperStage: r.taperStage,
    observationStart: StrategyDates.tryDecode(r.observationStart),
    observationDays: r.observationDays,
    reason: r.reason,
    legacyCalories: r.legacyCalories,
  );

  Future<List<DietStrategyPlan>> listPlans() async {
    final rows = await (_db.select(
      _db.dietStrategyPlans,
    )..orderBy([(t) => OrderingTerm.asc(t.version)])).get();
    return rows.map(_fromRow).toList();
  }

  Stream<List<DietStrategyPlan>> watchPlans() {
    return (_db.select(_db.dietStrategyPlans)
          ..orderBy([(t) => OrderingTerm.asc(t.version)]))
        .watch()
        .map((rows) => rows.map(_fromRow).toList());
  }

  Future<DietStrategyPlan?> activePlan() async {
    final row =
        await (_db.select(_db.dietStrategyPlans)
              ..where((t) => t.status.equals(DietPlanStatus.active.name))
              ..orderBy([(t) => OrderingTerm.desc(t.version)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Stream<DietStrategyPlan?> watchActivePlan() {
    return (_db.select(_db.dietStrategyPlans)
          ..where((t) => t.status.equals(DietPlanStatus.active.name))
          ..orderBy([(t) => OrderingTerm.desc(t.version)])
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _fromRow(row));
  }

  /// Version governing [day], if any (independent of status).
  Future<DietStrategyPlan?> planCovering(DateTime day) async {
    final plans = await listPlans();
    return _covering(plans, day);
  }

  DietStrategyPlan? _covering(List<DietStrategyPlan> plans, DateTime day) {
    DietStrategyPlan? found;
    for (final p in plans) {
      if (p.covers(day)) found = p; // later versions win
    }
    return found;
  }

  /// Inserts a new version and supersedes the currently active one.
  ///
  /// Throws [ArgumentError] when the draft is infeasible.
  Future<DietStrategyPlan> createPlan(
    DietStrategyPlanDraft draft, {
    DateTime? now,
  }) async {
    final issues = draft.validate();
    if (issues.isNotEmpty) {
      throw ArgumentError.value(
        issues.map((e) => e.name).join(','),
        'draft',
        'strategy draft infeasible',
      );
    }
    final today = CalendarDay.todayLocal(now);
    final from = StrategyDates.dayOnly(draft.effectiveFrom);
    if (from.isBefore(today)) {
      throw ArgumentError.value(from, 'effectiveFrom', 'cannot be in the past');
    }
    return _db.transaction(() async {
      final existing = await listPlans();
      var nextVersion = 1;
      for (final p in existing) {
        if (p.version >= nextVersion) nextVersion = p.version + 1;
        if (p.status == DietPlanStatus.active) {
          // Historical range stays intact: end it where the new one starts.
          final end = p.effectiveFrom.isAfter(from) ? p.effectiveFrom : from;
          await (_db.update(
            _db.dietStrategyPlans,
          )..where((t) => t.id.equals(p.id))).write(
            DietStrategyPlansCompanion(
              status: Value(DietPlanStatus.superseded.name),
              endedOn: Value(StrategyDates.encode(end)),
            ),
          );
        }
      }
      final id = await _db
          .into(_db.dietStrategyPlans)
          .insert(
            DietStrategyPlansCompanion.insert(
              version: nextVersion,
              strategy: draft.kind.name,
              status: DietPlanStatus.active.name,
              effectiveFrom: StrategyDates.encode(from),
              createdAt: now ?? DateTime.now(),
              referenceWeightKg: draft.referenceWeightKg,
              estimatedTdee: draft.estimatedTdee,
              deficitFraction: draft.baseline.deficitFraction,
              proteinPerKg: draft.proteinPerKg,
              fatPerKg: draft.fatPerKg,
              baseEnergy: draft.baseEnergy,
              schedule: Value(draft.schedule?.code),
              carbAmplitudeG: Value(draft.carbAmplitudeG),
              taperStage: Value(draft.taperStage),
              observationStart: Value(
                draft.observationStart == null
                    ? null
                    : StrategyDates.encode(draft.observationStart!),
              ),
              observationDays: Value(draft.observationDays),
              reason: Value(draft.reason),
              legacyCalories: Value(draft.legacyCalories),
            ),
          );
      // Only today's snapshot may be affected (future days are never stored).
      if (!from.isAfter(today)) {
        await _deleteSnapshot(today);
      }
      final row = await (_db.select(
        _db.dietStrategyPlans,
      )..where((t) => t.id.equals(id))).getSingle();
      return _fromRow(row);
    });
  }

  /// Ends the active version so that [endedOn] (default today) and later
  /// days fall back to the profile target.
  ///
  /// If the active version has not started yet (a scheduled switch), stopping
  /// it cancels the switch: the version it superseded — which still governs
  /// today — is reinstated as active instead of leaving nothing in effect.
  Future<void> stopActivePlan({
    String reason = 'stopped',
    DateTime? now,
  }) async {
    final today = CalendarDay.todayLocal(now);
    await _db.transaction(() async {
      final active = await activePlan();
      if (active == null) return;
      final pending = active.effectiveFrom.isAfter(today);
      final end = pending ? active.effectiveFrom : today;
      await (_db.update(
        _db.dietStrategyPlans,
      )..where((t) => t.id.equals(active.id))).write(
        DietStrategyPlansCompanion(
          status: Value(DietPlanStatus.stopped.name),
          endedOn: Value(StrategyDates.encode(end)),
          reason: Value('${active.reason};$reason'),
        ),
      );
      if (pending) {
        final plans = await listPlans();
        DietStrategyPlan? previous;
        for (final p in plans) {
          if (p.status == DietPlanStatus.superseded &&
              p.endedOn != null &&
              p.endedOn!.isAtSameMomentAs(active.effectiveFrom) &&
              (previous == null || p.version > previous.version)) {
            previous = p;
          }
        }
        if (previous != null) {
          await (_db.update(
            _db.dietStrategyPlans,
          )..where((t) => t.id.equals(previous!.id))).write(
            DietStrategyPlansCompanion(
              status: Value(DietPlanStatus.active.name),
              endedOn: const Value(null),
            ),
          );
        }
      }
      await _deleteSnapshot(today);
    });
  }

  // ------------------------------------------------------------ snapshots

  Future<void> _deleteSnapshot(DateTime day) async {
    await (_db.delete(
      _db.dailyNutritionTargets,
    )..where((t) => t.date.equals(StrategyDates.encode(day)))).go();
  }

  DailyNutritionTarget _fromSnapshot(DailyNutritionTargetRow r) {
    final source = TargetSource.values.firstWhere(
      (s) => s.name == r.source,
      orElse: () => TargetSource.profile,
    );
    return DailyNutritionTarget(
      date: StrategyDates.tryDecode(r.date) ?? DateTime(1970),
      calories: r.calories,
      proteinG: r.proteinG,
      carbG: r.carbG,
      fatG: r.fatG,
      source: source,
      estimatedTdee: r.estimatedTdee,
      planId: r.planId,
      planVersion: r.planVersion,
      strategy: r.strategy == null
          ? null
          : DietStrategyKind.fromStorage(r.strategy),
      dayType: r.dayType == null ? null : CarbDayType.fromCode(r.dayType!),
      isSnapshot: true,
      reason: r.reason,
    );
  }

  static bool _sameTarget(DailyNutritionTarget a, DailyNutritionTarget b) =>
      (a.calories - b.calories).abs() < 1e-6 &&
      (a.proteinG - b.proteinG).abs() < 1e-6 &&
      (a.carbG - b.carbG).abs() < 1e-6 &&
      (a.fatG - b.fatG).abs() < 1e-6 &&
      a.source == b.source &&
      a.planId == b.planId &&
      a.planVersion == b.planVersion &&
      a.dayType == b.dayType &&
      a.reason == b.reason &&
      ((a.estimatedTdee ?? -1) - (b.estimatedTdee ?? -1)).abs() < 1e-6;

  /// Writes the snapshot only when it differs, so watchers that recompute on
  /// table updates do not loop.
  Future<void> _upsertSnapshot(DailyNutritionTarget t, {DateTime? now}) async {
    final existing = await snapshotFor(t.date);
    if (existing != null && _sameTarget(existing, t)) return;
    await _db
        .into(_db.dailyNutritionTargets)
        .insertOnConflictUpdate(
          DailyNutritionTargetsCompanion.insert(
            date: StrategyDates.encode(t.date),
            planId: Value(t.planId),
            planVersion: Value(t.planVersion),
            strategy: Value(t.strategy?.name),
            dayType: Value(t.dayType?.code),
            calories: t.calories,
            proteinG: t.proteinG,
            carbG: t.carbG,
            fatG: t.fatG,
            estimatedTdee: Value(t.estimatedTdee),
            source: t.source.name,
            status: const Value('confirmed'),
            reason: Value(t.reason),
            updatedAt: now ?? DateTime.now(),
          ),
        );
  }

  Future<DailyNutritionTarget?> snapshotFor(DateTime day) async {
    final row =
        await (_db.select(_db.dailyNutritionTargets)
              ..where((t) => t.date.equals(StrategyDates.encode(day))))
            .getSingleOrNull();
    return row == null ? null : _fromSnapshot(row);
  }

  /// Manual per-date override (today only; history stays immutable).
  Future<void> setOverride(
    DateTime day,
    DayMacroTarget target, {
    String reason = 'manualOverride',
    DateTime? now,
  }) async {
    final today = CalendarDay.todayLocal(now);
    final d = StrategyDates.dayOnly(day);
    if (d != today) {
      throw StateError('只能覆盖今天的目标');
    }
    final plan = await planCovering(d);
    await _upsertSnapshot(
      DailyNutritionTarget(
        date: d,
        calories: target.energy,
        proteinG: target.proteinG,
        carbG: target.carbG,
        fatG: target.fatG,
        source: TargetSource.override,
        estimatedTdee: plan?.estimatedTdee,
        planId: plan?.id,
        planVersion: plan?.version,
        strategy: plan?.kind,
        dayType: target.dayType,
        isSnapshot: true,
        reason: reason,
      ),
      now: now,
    );
  }

  // ----------------------------------------------------------- resolution

  DailyNutritionTarget _fromPlan(DietStrategyPlan plan, DateTime day) {
    final t = plan.targetFor(day);
    return DailyNutritionTarget(
      date: day,
      calories: t.energy,
      proteinG: t.proteinG,
      carbG: t.carbG,
      fatG: t.fatG,
      source: TargetSource.strategy,
      estimatedTdee: plan.estimatedTdee,
      planId: plan.id,
      planVersion: plan.version,
      strategy: plan.kind,
      dayType: plan.kind == DietStrategyKind.carbCycle ? t.dayType : null,
      reason: plan.kind == DietStrategyKind.carbTaper
          ? 'taperStage:${plan.taperStage}'
          : null,
    );
  }

  DailyNutritionTarget? _fromProfile(
    UserProfile? profile,
    DateTime day, {
    required bool isPast,
  }) {
    if (profile == null) return null;
    final since = profile.calorieStandardSince;
    final beforeStandard = since != null && day.isBefore(since);
    return DailyNutritionTarget(
      date: day,
      calories: profile.targets.calories.toDouble(),
      proteinG: profile.targets.proteinG,
      carbG: profile.targets.carbG,
      fatG: profile.targets.fatG,
      source: TargetSource.profile,
      estimatedTdee: profile.tdee,
      isLegacyEstimate: isPast && beforeStandard,
      reason: profile.calorieAdjustment > 0
          ? 'plateauAdj:${profile.calorieAdjustment}'
          : null,
    );
  }

  /// Resolve the target for [day]. Today is always recomputed and written
  /// as the snapshot of record; past snapshots are never rewritten.
  Future<DailyNutritionTarget?> targetForDay(
    DateTime day,
    UserProfile? profile, {
    DateTime? now,
  }) async {
    final d = StrategyDates.dayOnly(day);
    final today = CalendarDay.todayLocal(now);
    final isToday = d == today;
    final isPast = d.isBefore(today);

    if (!isToday) {
      final snap = await snapshotFor(d);
      if (snap != null) return snap;
    } else {
      // A manual override for today survives recomputation.
      final snap = await snapshotFor(d);
      if (snap != null && snap.source == TargetSource.override) return snap;
    }

    final plan = await planCovering(d);
    final resolved = plan != null
        ? _fromPlan(plan, d)
        : _fromProfile(profile, d, isPast: isPast);
    if (resolved == null) return null;
    if (isToday) {
      await _upsertSnapshot(resolved, now: now);
      return DailyNutritionTarget(
        date: resolved.date,
        calories: resolved.calories,
        proteinG: resolved.proteinG,
        carbG: resolved.carbG,
        fatG: resolved.fatG,
        source: resolved.source,
        estimatedTdee: resolved.estimatedTdee,
        planId: resolved.planId,
        planVersion: resolved.planVersion,
        strategy: resolved.strategy,
        dayType: resolved.dayType,
        isSnapshot: true,
        reason: resolved.reason,
      );
    }
    return resolved;
  }

  /// Recomputes whenever plans or snapshots change.
  Stream<DailyNutritionTarget?> watchTargetForDay(
    DateTime day,
    UserProfile? profile,
  ) async* {
    final d = StrategyDates.dayOnly(day);
    yield await targetForDay(d, profile);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.dietStrategyPlans,
        _db.dailyNutritionTargets,
      ]),
    );
    await for (final _ in updates) {
      yield await targetForDay(d, profile);
    }
  }

  /// Targets for every local day in [[start], [end]] (inclusive), without
  /// writing snapshots except for today.
  Future<Map<DateTime, DailyNutritionTarget>> targetsBetween(
    DateTime start,
    DateTime end,
    UserProfile? profile, {
    DateTime? now,
  }) async {
    final s = StrategyDates.dayOnly(start);
    final e = StrategyDates.dayOnly(end);
    if (e.isBefore(s)) return const {};
    final today = CalendarDay.todayLocal(now);
    final plans = await listPlans();
    final snapRows =
        await (_db.select(_db.dailyNutritionTargets)..where(
              (t) => t.date.isBetweenValues(
                StrategyDates.encode(s),
                StrategyDates.encode(e),
              ),
            ))
            .get();
    final snaps = <DateTime, DailyNutritionTarget>{
      for (final r in snapRows)
        StrategyDates.dayOnly(_fromSnapshot(r).date): _fromSnapshot(r),
    };
    final out = <DateTime, DailyNutritionTarget>{};
    for (var d = s; !d.isAfter(e); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d == today) {
        final t = await targetForDay(d, profile, now: now);
        if (t != null) out[d] = t;
        continue;
      }
      final snap = snaps[d];
      if (snap != null) {
        out[d] = snap;
        continue;
      }
      final plan = _covering(plans, d);
      final t = plan != null
          ? _fromPlan(plan, d)
          : _fromProfile(profile, d, isPast: d.isBefore(today));
      if (t != null) out[d] = t;
    }
    return out;
  }

  // -------------------------------------------------------- confirmations

  Future<void> setDayComplete(
    DateTime day,
    bool complete, {
    DateTime? now,
  }) async {
    CalendarDay.ensureEditableDay(day, now);
    await _db
        .into(_db.dayDietConfirmations)
        .insertOnConflictUpdate(
          DayDietConfirmationsCompanion.insert(
            date: StrategyDates.encode(day),
            complete: complete,
            updatedAt: now ?? DateTime.now(),
          ),
        );
  }

  /// null = unknown (never confirmed).
  Future<bool?> dayComplete(DateTime day) async {
    final row =
        await (_db.select(_db.dayDietConfirmations)
              ..where((t) => t.date.equals(StrategyDates.encode(day))))
            .getSingleOrNull();
    return row?.complete;
  }

  Stream<bool?> watchDayComplete(DateTime day) {
    return (_db.select(_db.dayDietConfirmations)
          ..where((t) => t.date.equals(StrategyDates.encode(day))))
        .watchSingleOrNull()
        .map((row) => row?.complete);
  }

  Future<Set<DateTime>> completeDaysBetween(
    DateTime start,
    DateTime end,
  ) async {
    final rows =
        await (_db.select(_db.dayDietConfirmations)..where(
              (t) =>
                  t.complete.equals(true) &
                  t.date.isBetweenValues(
                    StrategyDates.encode(start),
                    StrategyDates.encode(end),
                  ),
            ))
            .get();
    return {
      for (final r in rows)
        if (StrategyDates.tryDecode(r.date) != null)
          StrategyDates.tryDecode(r.date)!,
    };
  }

  Future<void> clearAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.dietStrategyPlans).go();
      await _db.delete(_db.dailyNutritionTargets).go();
      await _db.delete(_db.dayDietConfirmations).go();
    });
  }
}
