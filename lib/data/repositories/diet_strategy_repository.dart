import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../../domain/cycle_history.dart';
import '../../domain/day_marker.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../db.dart';
import 'day_marker_repository.dart';

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
    this.carbCycleRates,
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
  final CarbCycleRates? carbCycleRates;
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
    carbCycleRates: carbCycleRates,
    taperStage: taperStage,
    observationStart: observationStart,
    observationDays: observationDays,
    reason: reason,
    legacyCalories: legacyCalories,
  );

  /// Validation errors that must block persistence.
  List<StrategyIssue> validate() {
    if (kind == DietStrategyKind.carbCycle) {
      final issues = <StrategyIssue>[];
      if (!referenceWeightKg.isFinite || referenceWeightKg <= 0) {
        issues.add(StrategyIssue.invalidWeight);
      }
      final s = schedule;
      final r = carbCycleRates;
      if (s == null || r == null) {
        issues.add(StrategyIssue.invalidSchedule);
        return issues;
      }
      final plan = CarbCyclePlanner.compute(
        referenceWeightKg: referenceWeightKg,
        rates: r,
        schedule: s,
      );
      for (final i in plan.issues) {
        if (!issues.contains(i)) issues.add(i);
      }
      return issues;
    }
    final issues = <StrategyIssue>[...baseline.issues];
    if (kind == DietStrategyKind.carbTaper) {
      final stage = CarbTaperStage.of(baseline, taperStage);
      if (!stage.feasible && !issues.contains(StrategyIssue.carbBelowMinimum)) {
        issues.add(StrategyIssue.carbBelowMinimum);
      }
    }
    return issues;
  }
}

/// Persists strategy versions, per-day target snapshots and diet
/// completeness confirmations; resolves the target for any local date.
class DietStrategyRepository {
  DietStrategyRepository(this._db);

  final AppDatabase _db;

  // ------------------------------------------------------------- standard

  /// Whether [next] is a structurally different standard than [old] — a
  /// change of strategy kind, or a change to the parameters that actually
  /// shape day-to-day targets under the same kind. Fields that drift on
  /// their own with body weight (reference weight, estimated TDEE, base
  /// energy) are deliberately excluded so re-opening and re-saving the same
  /// strategy after a routine weigh-in doesn't move the calendar's "new
  /// standard" marker. A carb-cycle schedule edit (cycle length or the
  /// high/medium/low order) is excluded too: it only rearranges days within
  /// the same strategy, it doesn't change what a day is judged against.
  static bool isStructuralChange(
    DietStrategyPlan? old,
    DietStrategyPlanDraft next,
  ) {
    if (old == null) return true;
    if (old.kind != next.kind) return true;
    switch (next.kind) {
      case DietStrategyKind.balanced:
        return !_closeEnough(
              old.deficitFraction,
              next.baseline.deficitFraction,
            ) ||
            !_closeEnough(old.proteinPerKg, next.proteinPerKg) ||
            !_closeEnough(old.fatPerKg, next.fatPerKg);
      case DietStrategyKind.carbCycle:
        return !_sameRates(old.carbCycleRates, next.carbCycleRates);
      case DietStrategyKind.carbTaper:
        return old.taperStage != next.taperStage;
    }
  }

  static bool _closeEnough(double a, double b) => (a - b).abs() < 1e-6;

  static bool _sameRates(CarbCycleRates? a, CarbCycleRates? b) {
    if (a == null || b == null) return a == b;
    return _closeEnough(a.lowProteinPerKg, b.lowProteinPerKg) &&
        _closeEnough(a.lowCarbPerKg, b.lowCarbPerKg) &&
        _closeEnough(a.lowFatPerKg, b.lowFatPerKg) &&
        _closeEnough(a.highProteinPerKg, b.highProteinPerKg) &&
        _closeEnough(a.highCarbPerKg, b.highCarbPerKg) &&
        _closeEnough(a.highFatPerKg, b.highFatPerKg);
  }

  // ---------------------------------------------------------------- plans

  DietStrategyPlan _fromRow(DietStrategyPlanRow r) => DietStrategyPlan(
    id: r.id,
    version: r.version,
    cycleStartIndex: r.cycleStartIndex,
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
    carbCycleRates:
        r.lowProteinPerKg != null &&
            r.lowCarbPerKg != null &&
            r.lowFatPerKg != null &&
            r.highProteinPerKg != null &&
            r.highCarbPerKg != null &&
            r.highFatPerKg != null
        ? CarbCycleRates(
            lowProteinPerKg: r.lowProteinPerKg!,
            lowCarbPerKg: r.lowCarbPerKg!,
            lowFatPerKg: r.lowFatPerKg!,
            highProteinPerKg: r.highProteinPerKg!,
            highCarbPerKg: r.highCarbPerKg!,
            highFatPerKg: r.highFatPerKg!,
          )
        : null,
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

  /// Resolves the old position at the effective date before changing versions.
  /// Shared by configuration previews and transactional persistence.
  static int continuationIndex({
    required List<DietStrategyPlan> plans,
    required List<DateTime> restDays,
    required DateTime effectiveFrom,
    required CarbCycleSchedule schedule,
    List<DailyNutritionTarget> snapshots = const [],
  }) {
    final day = StrategyDates.dayOnly(effectiveFrom);
    DietStrategyPlan? previous;
    for (final plan in plans) {
      if (plan.covers(day)) previous = plan;
    }
    if (previous == null ||
        previous.kind != DietStrategyKind.carbCycle ||
        previous.status == DietPlanStatus.stopped ||
        previous.schedule == null) {
      return 0;
    }
    return previous
            .cycleDayOn(
              day,
              pauses: restDays,
              anchors: cycleAnchorsOf(snapshots, previous.id),
            )!
            .index %
        schedule.cycleLengthDays;
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
      final cycleStartIndex =
          draft.kind == DietStrategyKind.carbCycle && draft.schedule != null
          ? continuationIndex(
              plans: existing,
              snapshots: (await _db.select(_db.dailyNutritionTargets).get())
                  .map(_fromSnapshot)
                  .toList(),
              restDays: await DayMarkerRepository(_db).restDayDates(now: now),
              effectiveFrom: from,
              schedule: draft.schedule!,
            )
          : 0;
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
              cycleStartIndex: Value(cycleStartIndex),
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
              lowProteinPerKg: Value(draft.carbCycleRates?.lowProteinPerKg),
              lowCarbPerKg: Value(draft.carbCycleRates?.lowCarbPerKg),
              lowFatPerKg: Value(draft.carbCycleRates?.lowFatPerKg),
              highProteinPerKg: Value(draft.carbCycleRates?.highProteinPerKg),
              highCarbPerKg: Value(draft.carbCycleRates?.highCarbPerKg),
              highFatPerKg: Value(draft.carbCycleRates?.highFatPerKg),
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
        await (_db.delete(_db.dailyNutritionTargets)..where(
              (t) =>
                  t.date.equals(StrategyDates.encode(today)) &
                  t.source.isNotValue(TargetSource.override.name),
            ))
            .go();
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
  ///
  /// Returns the day-only date the "new standard" marker should be re-stamped
  /// to, or null when nothing about the day-to-day standard actually changed
  /// (there was no active plan, or the cancelled plan hadn't started yet and
  /// there's no earlier plan to fall back to).
  Future<DateTime?> stopActivePlan({
    String reason = 'stopped',
    DateTime? now,
  }) async {
    final today = CalendarDay.todayLocal(now);
    return _db.transaction(() async {
      final active = await activePlan();
      if (active == null) return null;
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
      DateTime? restoredEffectiveFrom;
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
          restoredEffectiveFrom = previous.effectiveFrom;
        }
      }
      await _deleteSnapshot(today);
      // A cancelled scheduled switch never took effect, so today's standard
      // hasn't changed — re-stamp to whatever plan now governs, or leave the
      // marker alone if there's nothing earlier to fall back to.
      return pending ? restoredEffectiveFrom : today;
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
      cycleIndex: r.cycleIndex,
      cyclePaused: r.cyclePaused,
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
      a.cycleIndex == b.cycleIndex &&
      a.cyclePaused == b.cyclePaused &&
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
            cycleIndex: Value(t.cycleIndex),
            cyclePaused: Value(t.cyclePaused),
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
    // The day's cycle position is recorded so its pause stays frozen once
    // past; anchors never use override rows as position evidence.
    final cycleDay = plan?.cycleDayOn(
      d,
      pauses: await DayMarkerRepository(_db).restDayDates(now: now),
      anchors: await _anchorsBefore(plan, d),
    );
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
        cycleIndex: cycleDay?.index,
        cyclePaused: cycleDay?.paused,
        isSnapshot: true,
        reason: reason,
      ),
      now: now,
    );
  }

  // ----------------------------------------------------------- resolution

  /// [pauses]/[anchors] feed the shared cycle resolver and [carbLoadPerKg]
  /// (a 冲碳日 marker's carbs) replaces the day's macros; all are ignored for
  /// non-`carbCycle` plans.
  DailyNutritionTarget _fromPlan(
    DietStrategyPlan plan,
    DateTime day, {
    Iterable<DateTime> pauses = const [],
    Iterable<CycleAnchor> anchors = const [],
    double? carbLoadPerKg,
  }) {
    final cycleDay = plan.cycleDayOn(day, pauses: pauses, anchors: anchors);
    final cyclePlan = plan.kind == DietStrategyKind.carbCycle
        ? plan.carbCyclePlan
        : null;
    final loadPerKg = carbLoadPerKg != null && cyclePlan != null
        ? cyclePlan.clampCarbLoadPerKg(carbLoadPerKg)
        : null;
    final t = loadPerKg != null
        ? cyclePlan!.carbLoadDay(loadPerKg)
        : plan.targetFor(day, cycleDay: cycleDay);
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
      dayType: cycleDay == null ? null : t.dayType,
      cycleIndex: cycleDay?.index,
      cyclePaused: cycleDay?.paused,
      reason: plan.kind == DietStrategyKind.carbTaper
          ? 'taperStage:${plan.taperStage}'
          : loadPerKg != null
          ? '${DailyNutritionTarget.carbLoadReasonPrefix}'
                '${loadPerKg.toStringAsFixed(1)}'
          : null,
    );
  }

  /// 冲碳日 carbs (g/kg) of [day]'s marker, or null when it isn't one.
  Future<double?> _carbLoadPerKgOn(DateTime day) async {
    final row =
        await (_db.select(_db.dayMarkers)
              ..where((t) => t.date.equals(StrategyDates.encode(day))))
            .getSingleOrNull();
    return _carbLoadPerKgOf(row);
  }

  static double? _carbLoadPerKgOf(DayMarkerRow? row) =>
      row != null && row.type == DayMarkerType.carbLoad.name
      ? row.carbLoadCarbPerKg ?? StrategyRules.defaultCarbLoadCarbPerKg
      : null;

  /// Positions frozen by [plan]'s snapshots strictly before [day].
  Future<List<CycleAnchor>> _anchorsBefore(
    DietStrategyPlan plan,
    DateTime day,
  ) async {
    if (plan.kind != DietStrategyKind.carbCycle) return const [];
    final rows =
        await (_db.select(_db.dailyNutritionTargets)..where(
              (t) =>
                  t.planId.equals(plan.id) &
                  t.cycleIndex.isNotNull() &
                  t.date.isSmallerThanValue(StrategyDates.encode(day)),
            ))
            .get();
    return cycleAnchorsOf(rows.map(_fromSnapshot), plan.id);
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
        ? _fromPlan(
            plan,
            d,
            pauses: plan.kind == DietStrategyKind.carbCycle
                ? await DayMarkerRepository(_db).restDayDates(now: now)
                : const [],
            anchors: await _anchorsBefore(plan, d),
            carbLoadPerKg: plan.kind == DietStrategyKind.carbCycle
                ? await _carbLoadPerKgOn(d)
                : null,
          )
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
        cycleIndex: resolved.cycleIndex,
        cyclePaused: resolved.cyclePaused,
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
  ) {
    final d = StrategyDates.dayOnly(day);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.dietStrategyPlans,
        _db.dailyNutritionTargets,
        _db.dayMarkers,
      ]),
    );
    late final StreamController<DailyNutritionTarget?> controller;
    var resolving = false;
    var dirty = false;
    var cancelled = false;

    Future<void> resolve() async {
      if (cancelled || controller.isClosed) return;
      if (resolving) {
        dirty = true;
        return;
      }
      resolving = true;
      try {
        do {
          dirty = false;
          try {
            final target = await targetForDay(d, profile);
            if (!cancelled && !controller.isClosed) controller.add(target);
          } catch (error, stackTrace) {
            if (!cancelled && !controller.isClosed) {
              controller.addError(error, stackTrace);
            }
          }
        } while (dirty && !cancelled && !controller.isClosed);
      } finally {
        resolving = false;
      }
    }

    controller = StreamController<DailyNutritionTarget?>(
      onListen: () {
        // Listen before the initial read so a plan stopped during that read
        // cannot leave the provider showing the old carb-day target.
        final subscription = updates.listen((_) => resolve());
        controller.onCancel = () {
          cancelled = true;
          return subscription.cancel();
        };
        resolve();
      },
    );
    return controller.stream;
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
    final hasCarbCycle = plans.any((p) => p.kind == DietStrategyKind.carbCycle);
    final restDayDates = hasCarbCycle
        ? await DayMarkerRepository(_db).restDayDates(now: now)
        : const <DateTime>[];
    final carbLoads = <DateTime, double>{};
    if (hasCarbCycle) {
      final markerRows =
          await (_db.select(_db.dayMarkers)..where(
                (t) =>
                    t.type.equals(DayMarkerType.carbLoad.name) &
                    t.date.isBetweenValues(
                      StrategyDates.encode(s),
                      StrategyDates.encode(e),
                    ),
              ))
              .get();
      for (final row in markerRows) {
        final date = StrategyDates.tryDecode(row.date);
        final perKg = _carbLoadPerKgOf(row);
        if (date != null && perKg != null) carbLoads[date] = perKg;
      }
    }
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
    final anchorRows = hasCarbCycle
        ? await (_db.select(
            _db.dailyNutritionTargets,
          )..where((t) => t.cycleIndex.isNotNull())).get()
        : const <DailyNutritionTargetRow>[];
    final anchorSnaps = anchorRows.map(_fromSnapshot).toList();
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
          ? _fromPlan(
              plan,
              d,
              pauses: restDayDates,
              anchors: cycleAnchorsOf(
                anchorSnaps.where((a) => a.date.isBefore(d)),
                plan.id,
              ),
              carbLoadPerKg: carbLoads[d],
            )
          : _fromProfile(profile, d, isPast: d.isBefore(today));
      if (t != null) out[d] = t;
    }
    return out;
  }

  /// Persisted carb-cycle snapshots: the anchors shared by previews.
  Stream<List<DailyNutritionTarget>> watchCycleSnapshots() =>
      (_db.select(_db.dailyNutritionTargets)..where(
            (t) =>
                t.source.equals(TargetSource.strategy.name) &
                t.strategy.equals(DietStrategyKind.carbCycle.name),
          ))
          .watch()
          .map((rows) => rows.map(_fromSnapshot).toList());

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
