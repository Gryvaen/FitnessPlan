/// Versioned strategy plans and per-date nutrition targets.
library;

import 'diet_strategy.dart';
import 'models.dart';

enum DietPlanStatus {
  /// Currently governs dates ≥ effectiveFrom (until endedOn, exclusive).
  active,

  /// Replaced by a newer version; still governs its historical range.
  superseded,

  /// Stopped by the user or by a goal change; governs dates before endedOn.
  stopped;

  static DietPlanStatus fromStorage(String? raw) {
    for (final s in values) {
      if (s.name == raw) return s;
    }
    return DietPlanStatus.stopped;
  }
}

/// Immutable strategy version. Never mutate persisted rows; create a new
/// version with a new `effectiveFrom` instead.
class DietStrategyPlan {
  const DietStrategyPlan({
    required this.id,
    required this.version,
    required this.kind,
    required this.status,
    required this.effectiveFrom,
    required this.endedOn,
    required this.createdAt,
    required this.referenceWeightKg,
    required this.estimatedTdee,
    required this.deficitFraction,
    required this.proteinPerKg,
    required this.fatPerKg,
    required this.baseEnergy,
    required this.schedule,
    required this.carbAmplitudeG,
    required this.taperStage,
    required this.observationStart,
    required this.observationDays,
    required this.reason,
    required this.legacyCalories,
  });

  final int id;
  final int version;
  final DietStrategyKind kind;
  final DietPlanStatus status;

  /// First local day governed by this version.
  final DateTime effectiveFrom;

  /// First local day *not* governed (exclusive); null = open-ended.
  final DateTime? endedOn;
  final DateTime createdAt;

  final double referenceWeightKg;
  final double estimatedTdee;
  final double deficitFraction;
  final double proteinPerKg;
  final double fatPerKg;

  /// E0 confirmed for this version.
  final double baseEnergy;

  /// Carb-cycle schedule (Mon..Sun); null for other strategies.
  final CarbCycleSchedule? schedule;
  final double? carbAmplitudeG;

  /// Carb-taper stage j (0 = base).
  final int taperStage;

  /// Start of the current taper observation window.
  final DateTime? observationStart;
  final int observationDays;

  /// Free-form machine reason (e.g. `created`, `scheduleChanged`).
  final String reason;

  /// Previous profile target at creation, for migration transparency.
  final int? legacyCalories;

  StrategyBaseline get baseline => StrategyBaseline.fromTargetEnergy(
    referenceWeightKg: referenceWeightKg,
    tdee: estimatedTdee,
    targetEnergy: baseEnergy,
    proteinPerKg: proteinPerKg,
    fatPerKg: fatPerKg,
  );

  CarbCyclePlan? get carbCyclePlan {
    final s = schedule;
    if (kind != DietStrategyKind.carbCycle || s == null) return null;
    return CarbCyclePlanner.compute(baseline, s, amplitudeG: carbAmplitudeG);
  }

  bool covers(DateTime day) {
    final d = StrategyDates.dayOnly(day);
    if (d.isBefore(effectiveFrom)) return false;
    final end = endedOn;
    if (end != null && !d.isBefore(end)) return false;
    return true;
  }

  /// Full-precision target for a date governed by this version.
  DayMacroTarget targetFor(DateTime day) {
    switch (kind) {
      case DietStrategyKind.balanced:
        return baseline.balancedDay;
      case DietStrategyKind.carbCycle:
        final plan = carbCyclePlan;
        if (plan == null) return baseline.balancedDay;
        return plan.forDate(day);
      case DietStrategyKind.carbTaper:
        return CarbTaperStage.of(baseline, taperStage).day;
    }
  }

  /// Weekly average energy (carb cycle keeps 7 × E0 by construction).
  double get weeklyAverage => baseEnergy;
}

/// Where a day's target came from.
enum TargetSource {
  /// Computed from an active strategy version.
  strategy,

  /// Profile targets (Mifflin-St Jeor plan, optional plateau adjustment).
  profile,

  /// Manual per-date override.
  override,
}

/// Target for one local calendar day, resolved from a single source.
class DailyNutritionTarget {
  const DailyNutritionTarget({
    required this.date,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.source,
    required this.estimatedTdee,
    this.planId,
    this.planVersion,
    this.strategy,
    this.dayType,
    this.isSnapshot = false,
    this.isLegacyEstimate = false,
    this.reason,
  });

  final DateTime date;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final TargetSource source;
  final double? estimatedTdee;
  final int? planId;
  final int? planVersion;
  final DietStrategyKind? strategy;
  final CarbDayType? dayType;

  /// True when read from the per-day snapshot table.
  final bool isSnapshot;

  /// True for past days that have no snapshot and whose profile-derived
  /// target may not match what was shown at the time.
  final bool isLegacyEstimate;
  final String? reason;

  int get caloriesRounded => calories.round();

  /// Planned deficit = estimated TDEE − target (null if TDEE unknown).
  double? get plannedDeficit {
    final t = estimatedTdee;
    if (t == null || !t.isFinite) return null;
    return t - calories;
  }

  MacroTargets toMacroTargets() => MacroTargets(
    calories: caloriesRounded,
    proteinG: proteinG,
    carbG: carbG,
    fatG: fatG,
  );
}
