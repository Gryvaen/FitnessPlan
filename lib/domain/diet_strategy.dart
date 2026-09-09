/// Fat-loss strategy calculations (pure functions, no Flutter imports).
///
/// Rules follow `design-handoff/fat-loss-strategy.md`. All parameters are
/// product defaults for a self-service tool aimed at generally healthy
/// adults; they are not clinically validated prescriptions.
library;

import 'dart:math' as math;

/// Mutually exclusive primary strategy.
enum DietStrategyKind {
  /// Same energy / macros every day.
  balanced,

  /// Weekly budget redistributed by carbohydrate across high / mid / low days.
  carbCycle,

  /// Step-wise carbohydrate reduction gated by explicit review.
  carbTaper;

  static DietStrategyKind fromStorage(String? raw) {
    for (final k in values) {
      if (k.name == raw) return k;
    }
    return DietStrategyKind.balanced;
  }
}

/// Relative day type within a carb-cycle week (relative to *this* plan,
/// not a nutritional low-carb classification).
enum CarbDayType {
  low(-1, 'L'),
  mid(0, 'M'),
  high(1, 'H');

  const CarbDayType(this.score, this.code);

  /// s_i in the algorithm.
  final int score;

  /// Single-letter code used for compact schedule storage.
  final String code;

  static CarbDayType fromCode(String code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return CarbDayType.mid;
  }
}

/// Product constraints for the self-service strategies.
abstract final class StrategyRules {
  /// Suggested starting deficit fraction.
  static const defaultDeficitFraction = 0.15;

  /// Self-service selectable deficit fraction range.
  static const minDeficitFraction = 0.10;
  static const maxDeficitFraction = 0.20;

  /// Protein g/kg for regular training adults (ISSN range 1.4–2.0).
  static const defaultProteinPerKg = 2.0;

  /// Fat g/kg baseline.
  static const defaultFatPerKg = 0.8;

  /// Largest daily deficit fraction tolerated by the product (E_min ≥ 0.75T).
  static const maxDailyDeficitFraction = 0.25;

  /// Absolute energy floor (kcal/day); 800–1200 is a supervised range.
  static const absoluteEnergyFloorKcal = 1201.0;

  /// Minimum daily carbohydrate for the regular template (g).
  static const minCarbG = 130.0;

  /// Default carb-cycle amplitude cap (g).
  static const maxCarbAmplitudeG = 50.0;

  /// Amplitude relative cap: 0.25 × C0.
  static const carbAmplitudeFraction = 0.25;

  /// Below this effective amplitude the weekly variation is treated as
  /// unusable and the UI should suggest balanced instead.
  static const negligibleAmplitudeG = 5.0;

  /// Carb-taper step: 25 g carbohydrate ≙ 100 kcal.
  static const taperStepCarbG = 25.0;
  static const taperStepKcal = 100.0;

  /// Minimum observation window before a taper review is possible.
  static const taperObservationDays = 14;

  /// Longer observation after carb cycling / large carb changes.
  static const taperObservationDaysAfterCarbShift = 21;

  /// Review data thresholds.
  static const reviewWindowDays = 14;
  static const reviewMinWeightDays = 10;
  static const reviewMinWeightDaysPerHalf = 4;
  static const reviewMinCompleteDietDays = 10;

  /// Weekly weight-change observation band (fraction of body weight).
  static const weeklyLossLowerBound = 0.0025;
  static const weeklyLossUpperBound = 0.0075;

  /// Minimum age for the self-service strategy flow.
  static const minAdultAge = 18;

  static const kcalPerGramProtein = 4.0;
  static const kcalPerGramCarb = 4.0;
  static const kcalPerGramFat = 9.0;
}

/// Reasons a baseline / plan cannot be generated or needs review.
enum StrategyIssue {
  invalidWeight,
  invalidTdee,
  invalidTargetEnergy,
  deficitBelowRange,
  deficitAboveRange,
  energyBelowFloor,
  energyAboveTdee,
  carbBelowMinimum,
  invalidSchedule,
  amplitudeNegligible,
  underage,
  goalNotCut,
}

bool _finitePositive(double v) => v.isFinite && v > 0;

/// Common baseline: T, E0, P, F, C0 and feasibility bounds.
class StrategyBaseline {
  const StrategyBaseline._({
    required this.referenceWeightKg,
    required this.tdee,
    required this.deficitFraction,
    required this.proteinPerKg,
    required this.fatPerKg,
    required this.energy,
    required this.proteinG,
    required this.fatG,
    required this.carbG,
    required this.minEnergy,
    required this.maxEnergy,
    required this.issues,
  });

  /// Build from a deficit fraction d: E0 = T × (1 − d).
  factory StrategyBaseline.fromDeficit({
    required double referenceWeightKg,
    required double tdee,
    double deficitFraction = StrategyRules.defaultDeficitFraction,
    double proteinPerKg = StrategyRules.defaultProteinPerKg,
    double fatPerKg = StrategyRules.defaultFatPerKg,
  }) {
    final issues = <StrategyIssue>{};
    if (!_finitePositive(referenceWeightKg)) {
      issues.add(StrategyIssue.invalidWeight);
    }
    if (!_finitePositive(tdee)) issues.add(StrategyIssue.invalidTdee);
    if (!deficitFraction.isFinite) {
      issues.add(StrategyIssue.invalidTargetEnergy);
    } else if (deficitFraction < StrategyRules.minDeficitFraction - 1e-9) {
      issues.add(StrategyIssue.deficitBelowRange);
    } else if (deficitFraction > StrategyRules.maxDeficitFraction + 1e-9) {
      issues.add(StrategyIssue.deficitAboveRange);
    }
    final w = _finitePositive(referenceWeightKg) ? referenceWeightKg : 0.0;
    final t = _finitePositive(tdee) ? tdee : 0.0;
    final d = deficitFraction.isFinite ? deficitFraction : 0.0;
    final energy = t * (1 - d);
    return StrategyBaseline._build(
      referenceWeightKg: w,
      tdee: t,
      deficitFraction: d,
      proteinPerKg: proteinPerKg,
      fatPerKg: fatPerKg,
      energy: energy,
      issues: issues,
    );
  }

  /// Build from a user-confirmed average target energy (kcal/day).
  factory StrategyBaseline.fromTargetEnergy({
    required double referenceWeightKg,
    required double tdee,
    required double targetEnergy,
    double proteinPerKg = StrategyRules.defaultProteinPerKg,
    double fatPerKg = StrategyRules.defaultFatPerKg,
  }) {
    final issues = <StrategyIssue>{};
    if (!_finitePositive(referenceWeightKg)) {
      issues.add(StrategyIssue.invalidWeight);
    }
    if (!_finitePositive(tdee)) issues.add(StrategyIssue.invalidTdee);
    if (!_finitePositive(targetEnergy)) {
      issues.add(StrategyIssue.invalidTargetEnergy);
    }
    final w = _finitePositive(referenceWeightKg) ? referenceWeightKg : 0.0;
    final t = _finitePositive(tdee) ? tdee : 0.0;
    final e = _finitePositive(targetEnergy) ? targetEnergy : 0.0;
    final d = t > 0 ? 1 - e / t : 0.0;
    if (t > 0 && e > 0) {
      if (d < StrategyRules.minDeficitFraction - 1e-9) {
        issues.add(StrategyIssue.deficitBelowRange);
      } else if (d > StrategyRules.maxDeficitFraction + 1e-9) {
        issues.add(StrategyIssue.deficitAboveRange);
      }
    }
    return StrategyBaseline._build(
      referenceWeightKg: w,
      tdee: t,
      deficitFraction: d,
      proteinPerKg: proteinPerKg,
      fatPerKg: fatPerKg,
      energy: e,
      issues: issues,
    );
  }

  factory StrategyBaseline._build({
    required double referenceWeightKg,
    required double tdee,
    required double deficitFraction,
    required double proteinPerKg,
    required double fatPerKg,
    required double energy,
    required Set<StrategyIssue> issues,
  }) {
    final proteinG = referenceWeightKg * proteinPerKg;
    final fatG = referenceWeightKg * fatPerKg;
    final fixedKcal =
        proteinG * StrategyRules.kcalPerGramProtein +
        fatG * StrategyRules.kcalPerGramFat;
    final carbG = (energy - fixedKcal) / StrategyRules.kcalPerGramCarb;
    final minEnergy = math.max(
      math.max(
        tdee * (1 - StrategyRules.maxDailyDeficitFraction),
        StrategyRules.absoluteEnergyFloorKcal,
      ),
      fixedKcal + StrategyRules.minCarbG * StrategyRules.kcalPerGramCarb,
    );
    final maxEnergy = tdee;
    if (issues.isEmpty) {
      if (energy < minEnergy - 1e-6) {
        issues.add(StrategyIssue.energyBelowFloor);
      }
      if (energy > maxEnergy + 1e-6) {
        issues.add(StrategyIssue.energyAboveTdee);
      }
      if (carbG < StrategyRules.minCarbG - 1e-6) {
        issues.add(StrategyIssue.carbBelowMinimum);
      }
    }
    return StrategyBaseline._(
      referenceWeightKg: referenceWeightKg,
      tdee: tdee,
      deficitFraction: deficitFraction,
      proteinPerKg: proteinPerKg,
      fatPerKg: fatPerKg,
      energy: energy,
      proteinG: proteinG,
      fatG: fatG,
      carbG: carbG,
      minEnergy: minEnergy,
      maxEnergy: maxEnergy,
      issues: List.unmodifiable(issues),
    );
  }

  /// W: reference weight confirmed for this plan (not re-read on every weigh-in).
  final double referenceWeightKg;

  /// T: estimated total daily energy expenditure.
  final double tdee;

  /// d: planned average deficit fraction.
  final double deficitFraction;
  final double proteinPerKg;
  final double fatPerKg;

  /// E0 (kcal/day).
  final double energy;

  /// P, F, C0 (g/day), full precision.
  final double proteinG;
  final double fatG;
  final double carbG;

  /// E_min = max(0.75T, 1201, 4P + 9F + 4×130).
  final double minEnergy;

  /// E_max = T.
  final double maxEnergy;

  final List<StrategyIssue> issues;

  bool get feasible => issues.isEmpty;

  /// Planned daily deficit = T − E0.
  double get dailyDeficit => tdee - energy;

  /// kcal from protein + fat (fixed across the week).
  double get fixedKcal =>
      proteinG * StrategyRules.kcalPerGramProtein +
      fatG * StrategyRules.kcalPerGramFat;

  /// Carbohydrate grams for a given energy with P/F fixed.
  double carbForEnergy(double e) =>
      (e - fixedKcal) / StrategyRules.kcalPerGramCarb;

  /// Same day every day: the balanced strategy target.
  DayMacroTarget get balancedDay => DayMacroTarget(
    energy: energy,
    proteinG: proteinG,
    carbG: carbG,
    fatG: fatG,
    dayType: CarbDayType.mid,
  );
}

/// Energy + macros for one day, full precision.
class DayMacroTarget {
  const DayMacroTarget({
    required this.energy,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.dayType,
  });

  final double energy;
  final double proteinG;
  final double carbG;
  final double fatG;
  final CarbDayType dayType;

  /// 4P + 4C + 9F.
  double get macroKcal =>
      proteinG * StrategyRules.kcalPerGramProtein +
      carbG * StrategyRules.kcalPerGramCarb +
      fatG * StrategyRules.kcalPerGramFat;

  DayMacroTarget copyWith({
    double? energy,
    double? proteinG,
    double? carbG,
    double? fatG,
    CarbDayType? dayType,
  }) => DayMacroTarget(
    energy: energy ?? this.energy,
    proteinG: proteinG ?? this.proteinG,
    carbG: carbG ?? this.carbG,
    fatG: fatG ?? this.fatG,
    dayType: dayType ?? this.dayType,
  );
}

/// Seven-day carb-cycle schedule (index 0 = Monday … 6 = Sunday).
class CarbCycleSchedule {
  CarbCycleSchedule(List<CarbDayType> days) : days = List.unmodifiable(days) {
    if (days.length != 7) {
      throw ArgumentError.value(days.length, 'days', 'must contain 7 days');
    }
  }

  /// All days mid; the default when no training schedule is known.
  factory CarbCycleSchedule.allMid() =>
      CarbCycleSchedule(List.filled(7, CarbDayType.mid));

  /// Decode a 7-letter H/M/L string; invalid input → null.
  static CarbCycleSchedule? tryParse(String? code) {
    if (code == null || code.length != 7) return null;
    final list = <CarbDayType>[];
    for (final ch in code.split('')) {
      CarbDayType? t;
      for (final v in CarbDayType.values) {
        if (v.code == ch) t = v;
      }
      if (t == null) return null;
      list.add(t);
    }
    return CarbCycleSchedule(list);
  }

  final List<CarbDayType> days;

  String get code => days.map((d) => d.code).join();

  /// Day type for a calendar date via `DateTime.weekday` (Mon=1..Sun=7).
  CarbDayType forDate(DateTime date) => days[date.weekday - 1];

  bool get allSame => days.every((d) => d == days.first);

  int count(CarbDayType type) => days.where((d) => d == type).length;

  CarbCycleSchedule withDay(int index, CarbDayType type) {
    final copy = [...days];
    copy[index] = type;
    return CarbCycleSchedule(copy);
  }
}

/// Result of distributing a weekly budget across a schedule.
class CarbCyclePlan {
  const CarbCyclePlan({
    required this.baseline,
    required this.schedule,
    required this.days,
    required this.requestedAmplitudeG,
    required this.alpha,
    required this.issues,
  });

  final StrategyBaseline baseline;
  final CarbCycleSchedule schedule;

  /// Seven full-precision day targets (Mon..Sun).
  final List<DayMacroTarget> days;

  /// A (g) before boundary shrink.
  final double requestedAmplitudeG;

  /// α ∈ [0,1] common shrink factor.
  final double alpha;
  final List<StrategyIssue> issues;

  double get effectiveAmplitudeG => requestedAmplitudeG * alpha;

  /// Σ E_i (should equal 7 × E0).
  double get weeklyEnergy => days.fold(0.0, (s, d) => s + d.energy);

  double get weeklyAverage => weeklyEnergy / 7;

  bool get shrunk => alpha < 1 - 1e-9;

  bool get amplitudeNegligible =>
      issues.contains(StrategyIssue.amplitudeNegligible);

  bool get usable => !issues.any((i) => i != StrategyIssue.amplitudeNegligible);

  DayMacroTarget forDate(DateTime date) => days[date.weekday - 1];

  /// Energy of the (first) day with [type], or null if absent.
  double? energyFor(CarbDayType type) {
    for (final d in days) {
      if (d.dayType == type) return d.energy;
    }
    return null;
  }

  /// Integer kcal per day using largest-remainder so that
  /// Σ = round(7 × E0); carbs recomputed from the integer energy.
  List<DayMacroTarget> integerDays() {
    final total = (7 * baseline.energy).round();
    final floors = days.map((d) => d.energy.floor()).toList();
    var remaining = total - floors.fold<int>(0, (s, v) => s + v);
    final order = List<int>.generate(7, (i) => i)
      ..sort(
        (a, b) =>
            (days[b].energy - floors[b]).compareTo(days[a].energy - floors[a]),
      );
    var k = 0;
    while (remaining > 0 && k < 7) {
      floors[order[k]] += 1;
      remaining--;
      k++;
    }
    while (remaining < 0 && k < 7) {
      floors[order[6 - k]] -= 1;
      remaining++;
      k++;
    }
    return [
      for (var i = 0; i < 7; i++)
        days[i].copyWith(
          energy: floors[i].toDouble(),
          carbG: baseline.carbForEnergy(floors[i].toDouble()),
        ),
    ];
  }
}

/// Carb-cycle distribution keeping the weekly budget and P/F fixed.
abstract final class CarbCyclePlanner {
  /// Default amplitude A = min(50, 0.25 × C0).
  static double defaultAmplitude(StrategyBaseline b) => math.max(
    0,
    math.min(
      StrategyRules.maxCarbAmplitudeG,
      StrategyRules.carbAmplitudeFraction * b.carbG,
    ),
  );

  /// Suggest a schedule from how often each weekday (1=Mon..7=Sun) had a
  /// planned workout over [weeks] observed weeks: trained in at least half
  /// of the weeks → high, never trained → low, otherwise mid. This is a
  /// suggestion that the user confirms; it never applies itself.
  static CarbCycleSchedule suggestFromTraining(
    Map<int, int> weekdayCounts, {
    required int weeks,
  }) {
    if (weeks <= 0) return CarbCycleSchedule.allMid();
    final days = <CarbDayType>[];
    for (var wd = 1; wd <= 7; wd++) {
      final c = weekdayCounts[wd] ?? 0;
      if (c <= 0) {
        days.add(CarbDayType.low);
      } else if (c * 2 >= weeks) {
        days.add(CarbDayType.high);
      } else {
        days.add(CarbDayType.mid);
      }
    }
    return CarbCycleSchedule(days);
  }

  static CarbCyclePlan compute(
    StrategyBaseline baseline,
    CarbCycleSchedule schedule, {
    double? amplitudeG,
  }) {
    final issues = <StrategyIssue>[...baseline.issues];
    var a = amplitudeG ?? defaultAmplitude(baseline);
    if (!a.isFinite || a < 0) {
      issues.add(StrategyIssue.invalidSchedule);
      a = 0;
    }
    final scores = schedule.days.map((d) => d.score).toList();
    final mean = scores.fold<int>(0, (s, v) => s + v) / 7;
    final deltas = [
      for (final s in scores) StrategyRules.kcalPerGramCarb * a * (s - mean),
    ];

    var alpha = 1.0;
    if (baseline.feasible) {
      for (final dE in deltas) {
        if (dE > 1e-9) {
          alpha = math.min(alpha, (baseline.maxEnergy - baseline.energy) / dE);
        } else if (dE < -1e-9) {
          alpha = math.min(alpha, (baseline.minEnergy - baseline.energy) / dE);
        }
      }
      alpha = alpha.clamp(0.0, 1.0);
      if (!alpha.isFinite) alpha = 0;
    } else {
      alpha = 0;
    }

    final days = <DayMacroTarget>[];
    for (var i = 0; i < 7; i++) {
      final e = baseline.energy + alpha * deltas[i];
      days.add(
        DayMacroTarget(
          energy: e,
          proteinG: baseline.proteinG,
          carbG: baseline.carbForEnergy(e),
          fatG: baseline.fatG,
          dayType: schedule.days[i],
        ),
      );
    }
    final effective = a * alpha;
    if (!schedule.allSame && effective < StrategyRules.negligibleAmplitudeG) {
      issues.add(StrategyIssue.amplitudeNegligible);
    }
    return CarbCyclePlan(
      baseline: baseline,
      schedule: schedule,
      days: days,
      requestedAmplitudeG: a,
      alpha: alpha,
      issues: List.unmodifiable(issues),
    );
  }
}

/// Stage j of the carb taper: E_j = E0 − 100j, C_j = C0 − 25j.
class CarbTaperStage {
  const CarbTaperStage._({
    required this.stage,
    required this.day,
    required this.feasible,
  });

  factory CarbTaperStage.of(StrategyBaseline b, int stage) {
    final j = stage < 0 ? 0 : stage;
    final e = b.energy - StrategyRules.taperStepKcal * j;
    final c = b.carbForEnergy(e);
    final feasible =
        b.feasible &&
        e >= b.minEnergy - 1e-6 &&
        c >= StrategyRules.minCarbG - 1e-6;
    return CarbTaperStage._(
      stage: j,
      day: DayMacroTarget(
        energy: e,
        proteinG: b.proteinG,
        carbG: c,
        fatG: b.fatG,
        dayType: CarbDayType.mid,
      ),
      feasible: feasible,
    );
  }

  final int stage;
  final DayMacroTarget day;

  /// False once the stage would breach E_min or the 130 g carb floor.
  final bool feasible;
}

abstract final class CarbTaperPlanner {
  static CarbTaperStage current(StrategyBaseline b, int stage) =>
      CarbTaperStage.of(b, stage);

  /// Next stage if it stays within constraints, else null (floor reached).
  static CarbTaperStage? nextStage(StrategyBaseline b, int stage) {
    final next = CarbTaperStage.of(b, stage + 1);
    return next.feasible ? next : null;
  }
}

/// Review outcome for the carb taper.
enum TaperReviewStatus {
  /// Observation window not yet complete.
  observing,

  /// Fewer than the required weighed days (total or per half).
  insufficientWeightData,

  /// Fewer than the required user-confirmed complete diet days.
  insufficientDietData,

  /// Weekly rate inside the target band → keep the current stage.
  hold,

  /// Weekly rate below the band with credible data → a step-down
  /// candidate exists (still requires explicit confirmation).
  stepDownCandidate,

  /// Weekly rate below the band but the next stage would breach limits.
  floorReached,

  /// Weekly rate above the band → stop lowering and review.
  rateTooHigh,
}

class TaperReviewInput {
  const TaperReviewInput({
    required this.today,
    required this.observationStart,
    required this.requiredObservationDays,
    required this.dailyWeights,
    required this.completeDietDays,
  });

  /// Local calendar day (time stripped).
  final DateTime today;

  /// Local calendar day the current stage started.
  final DateTime observationStart;
  final int requiredObservationDays;

  /// One value per local day (multiple weigh-ins already aggregated).
  final Map<DateTime, double> dailyWeights;

  /// Local days the user explicitly confirmed as complete.
  final Set<DateTime> completeDietDays;
}

class TaperReviewResult {
  const TaperReviewResult({
    required this.status,
    required this.daysObserved,
    required this.daysRequired,
    required this.nextReviewDate,
    required this.weightDays,
    required this.earlyWeightDays,
    required this.lateWeightDays,
    required this.completeDietDays,
    required this.weeklyRate,
    required this.nextStageFeasible,
  });

  final TaperReviewStatus status;
  final int daysObserved;
  final int daysRequired;

  /// Earliest date a review can be completed (observation end).
  final DateTime nextReviewDate;
  final int weightDays;
  final int earlyWeightDays;
  final int lateWeightDays;
  final int completeDietDays;

  /// r = (mean(early 7) − mean(late 7)) / mean(early 7); null when unknown.
  final double? weeklyRate;
  final bool nextStageFeasible;

  bool get canStepDown => status == TaperReviewStatus.stepDownCandidate;
}

abstract final class TaperReviewer {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static TaperReviewResult evaluate(
    TaperReviewInput input, {
    required bool nextStageFeasible,
  }) {
    final today = _day(input.today);
    final start = _day(input.observationStart);
    final observed = today.difference(start).inDays;
    final required = input.requiredObservationDays;
    final nextReview = start.add(Duration(days: required));

    // Window: last 14 days inclusive of today.
    final window = StrategyRules.reviewWindowDays;
    final windowStart = today.subtract(Duration(days: window - 1));
    final lateStart = today.subtract(const Duration(days: 6));

    final early = <double>[];
    final late = <double>[];
    for (final entry in input.dailyWeights.entries) {
      final d = _day(entry.key);
      final w = entry.value;
      if (!w.isFinite || w <= 0) continue;
      if (d.isBefore(windowStart) || d.isAfter(today)) continue;
      if (d.isBefore(lateStart)) {
        early.add(w);
      } else {
        late.add(w);
      }
    }
    var dietDays = 0;
    for (final d0 in input.completeDietDays) {
      final d = _day(d0);
      if (!d.isBefore(windowStart) && !d.isAfter(today)) dietDays++;
    }
    final weightDays = early.length + late.length;

    double? rate;
    if (early.isNotEmpty && late.isNotEmpty) {
      final e = early.reduce((a, b) => a + b) / early.length;
      final l = late.reduce((a, b) => a + b) / late.length;
      if (e > 0) rate = (e - l) / e;
    }

    TaperReviewStatus status;
    if (observed < required) {
      status = TaperReviewStatus.observing;
    } else if (weightDays < StrategyRules.reviewMinWeightDays ||
        early.length < StrategyRules.reviewMinWeightDaysPerHalf ||
        late.length < StrategyRules.reviewMinWeightDaysPerHalf ||
        rate == null) {
      status = TaperReviewStatus.insufficientWeightData;
    } else if (dietDays < StrategyRules.reviewMinCompleteDietDays) {
      status = TaperReviewStatus.insufficientDietData;
    } else if (rate > StrategyRules.weeklyLossUpperBound) {
      status = TaperReviewStatus.rateTooHigh;
    } else if (rate >= StrategyRules.weeklyLossLowerBound) {
      status = TaperReviewStatus.hold;
    } else if (nextStageFeasible) {
      status = TaperReviewStatus.stepDownCandidate;
    } else {
      status = TaperReviewStatus.floorReached;
    }

    return TaperReviewResult(
      status: status,
      daysObserved: observed < 0 ? 0 : observed,
      daysRequired: required,
      nextReviewDate: nextReview,
      weightDays: weightDays,
      earlyWeightDays: early.length,
      lateWeightDays: late.length,
      completeDietDays: dietDays,
      weeklyRate: rate,
      nextStageFeasible: nextStageFeasible,
    );
  }
}

/// Cycle-date helpers (local calendar; Monday starts a cycle).
abstract final class StrategyDates {
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// First Monday strictly after [today].
  static DateTime nextCycleStart(DateTime today) {
    final t = dayOnly(today);
    final daysUntil = 8 - t.weekday; // Mon(1)→7, Sun(7)→1
    return t.add(Duration(days: daysUntil));
  }

  /// Monday of the week containing [date].
  static DateTime cycleStartOf(DateTime date) {
    final d = dayOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String encode(DateTime d) {
    final x = dayOnly(d);
    final m = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return '${x.year}-$m-$dd';
  }

  static DateTime? tryDecode(String? raw) {
    if (raw == null || raw.length < 8) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final result = DateTime(y, m, d);
    if (result.month != m || result.day != d) return null;
    return result;
  }
}
