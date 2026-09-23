/// Fat-loss strategy calculations (pure functions, no Flutter imports).
///
/// Balanced/taper rules follow `design-handoff/fat-loss-strategy.md`. Carb
/// cycling was reworked to a day-count cycle (3-5 days, one high-carb day,
/// optional mid-carb day) driven directly by reference-weight multipliers —
/// see [CarbCycleSchedule] and [CarbCycleRates] — and no longer follows that
/// doc's weekday/deficit-amplitude model. All parameters are product
/// defaults for a self-service tool aimed at generally healthy adults; they
/// are not clinically validated prescriptions.
library;

import 'dart:math' as math;

/// Mutually exclusive primary strategy.
enum DietStrategyKind {
  /// Same energy / macros every day.
  balanced,

  /// A repeating N-day cycle with high / mid / low-carb days; energy comes
  /// directly from reference-weight multipliers, not a shared budget.
  carbCycle,

  /// Step-wise carbohydrate reduction; the user picks the stage — the app
  /// only calculates what each stage's kcal/carbs would be.
  carbTaper;

  static DietStrategyKind fromStorage(String? raw) {
    for (final k in values) {
      if (k.name == raw) return k;
    }
    return DietStrategyKind.balanced;
  }
}

/// Relative day type within a carb-cycle plan (relative to *this* plan,
/// not a nutritional low-carb classification).
enum CarbDayType {
  low('L'),
  mid('M'),
  high('H');

  const CarbDayType(this.code);

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

  /// Carb-cycle length choices (days per cycle).
  static const cycleLengthDaysOptions = [3, 4, 5];
  static const defaultCycleLengthDays = 4;

  /// Carb-cycle low-day multiplier ranges (g per kg reference weight).
  static const lowProteinPerKgMin = 1.8;
  static const lowProteinPerKgMax = 2.0;
  static const lowCarbPerKgMin = 1.0;
  static const lowCarbPerKgMax = 1.5;
  static const lowFatPerKgMin = 0.8;
  static const lowFatPerKgMax = 1.0;

  /// Carb-cycle high-day multiplier ranges (g per kg reference weight).
  static const highProteinPerKgMin = 1.2;
  static const highProteinPerKgMax = 1.8;
  static const highCarbPerKgMin = 3.5;
  static const highCarbPerKgMax = 5.0;
  static const highFatPerKgMin = 0.3;
  static const highFatPerKgMax = 0.8;

  /// Default multipliers: floor of each range above.
  static const defaultLowProteinPerKg = lowProteinPerKgMin;
  static const defaultLowCarbPerKg = lowCarbPerKgMin;
  static const defaultLowFatPerKg = lowFatPerKgMin;
  static const defaultHighProteinPerKg = highProteinPerKgMin;
  static const defaultHighCarbPerKg = highCarbPerKgMin;
  static const defaultHighFatPerKg = highFatPerKgMin;

  /// Carb-taper step: 25 g carbohydrate ≙ 100 kcal.
  static const taperStepCarbG = 25.0;
  static const taperStepKcal = 100.0;

  /// Minimum observation window before a taper review is possible.
  static const taperObservationDays = 14;

  /// Longer observation after carb cycling / large carb changes.
  static const taperObservationDaysAfterCarbShift = 21;

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
  invalidCarbCycleRate,
  carbCycleHighDayCarbDepleted,
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

/// Carb-cycle schedule: a repeating N-day pattern (N = 3, 4 or 5), anchored
/// to the plan's `effectiveFrom` date rather than the calendar weekday.
/// There is always exactly one high-carb day, and mid-carb days never
/// outnumber low-carb days. The user assigns each non-high day by hand (see
/// [cycleDayType]); the high day can only be moved between the first and
/// last position of the cycle (also via [cycleDayType]), never removed or
/// turned into mid/low directly.
class CarbCycleSchedule {
  CarbCycleSchedule(List<CarbDayType> days) : days = List.unmodifiable(days) {
    if (days.length < 3 || days.length > 5) {
      throw ArgumentError.value(
        days.length,
        'days',
        'cycle length must be 3, 4 or 5 days',
      );
    }
    final highCount = days.where((d) => d == CarbDayType.high).length;
    if (highCount != 1) {
      throw ArgumentError.value(
        highCount,
        'days',
        'a carb cycle has exactly one high-carb day',
      );
    }
    final midCount = days.where((d) => d == CarbDayType.mid).length;
    final lowCount = days.where((d) => d == CarbDayType.low).length;
    if (midCount > lowCount) {
      throw ArgumentError.value(
        midCount,
        'days',
        'mid-carb days must not exceed low-carb days',
      );
    }
  }

  /// Starting point for a fresh cycle of [cycleLengthDays] days: low days
  /// first, one high day on the last position. The user then hand-assigns
  /// any mid-carb days via [cycleDayType].
  factory CarbCycleSchedule.defaultFor(int cycleLengthDays) {
    if (!StrategyRules.cycleLengthDaysOptions.contains(cycleLengthDays)) {
      throw ArgumentError.value(
        cycleLengthDays,
        'cycleLengthDays',
        'must be 3, 4 or 5',
      );
    }
    return CarbCycleSchedule([
      ...List.filled(cycleLengthDays - 1, CarbDayType.low),
      CarbDayType.high,
    ]);
  }

  /// Decode a 3-5 letter H/M/L code; invalid input → null.
  static CarbCycleSchedule? tryParse(String? code) {
    if (code == null || code.length < 3 || code.length > 5) return null;
    final list = <CarbDayType>[];
    for (final ch in code.split('')) {
      CarbDayType? t;
      for (final v in CarbDayType.values) {
        if (v.code == ch) t = v;
      }
      if (t == null) return null;
      list.add(t);
    }
    try {
      return CarbCycleSchedule(list);
    } on ArgumentError {
      return null;
    }
  }

  final List<CarbDayType> days;

  int get cycleLengthDays => days.length;

  String get code => days.map((d) => d.code).join();

  int count(CarbDayType type) => days.where((d) => d == type).length;

  /// Day type at a 0-based position within the cycle (wraps automatically).
  CarbDayType dayAt(int cycleIndex) => days[cycleIndex % days.length];

  /// Taps day [index]:
  /// - If it's the high day, moves it to the other end of the cycle (index
  ///   0 ↔ the last index) and sets the day it left to low. This always
  ///   stays valid: whatever type sat at the target end is replaced by
  ///   high (mid count can only go down), and the vacated end becomes low
  ///   (low count can only go up) — mid ≤ low can never break.
  /// - Otherwise toggles that day between low and mid, skipping the
  ///   low → mid transition when it would push mid above low (returns the
  ///   unchanged schedule in that case; mid → low is always valid).
  CarbCycleSchedule cycleDayType(int index) {
    if (days[index] == CarbDayType.high) {
      final last = days.length - 1;
      final target = index == 0 ? last : 0;
      final next = [...days];
      next[index] = CarbDayType.low;
      next[target] = CarbDayType.high;
      return CarbCycleSchedule(next);
    }
    final next = [...days];
    if (days[index] == CarbDayType.low) {
      next[index] = CarbDayType.mid;
      if (!_isValid(next)) return this;
    } else {
      next[index] = CarbDayType.low;
    }
    return CarbCycleSchedule(next);
  }

  static bool _isValid(List<CarbDayType> days) {
    final mid = days.where((d) => d == CarbDayType.mid).length;
    final low = days.where((d) => d == CarbDayType.low).length;
    return mid <= low;
  }
}

/// Reference-weight multipliers (g per kg) for the low- and high-carb days
/// of a carb-cycle plan. The mid-carb day is not set directly — its rates
/// are the average of the low- and high-day rates for each macro.
class CarbCycleRates {
  const CarbCycleRates({
    required this.lowProteinPerKg,
    required this.lowCarbPerKg,
    required this.lowFatPerKg,
    required this.highProteinPerKg,
    required this.highCarbPerKg,
    required this.highFatPerKg,
  });

  factory CarbCycleRates.defaults() => const CarbCycleRates(
    lowProteinPerKg: StrategyRules.defaultLowProteinPerKg,
    lowCarbPerKg: StrategyRules.defaultLowCarbPerKg,
    lowFatPerKg: StrategyRules.defaultLowFatPerKg,
    highProteinPerKg: StrategyRules.defaultHighProteinPerKg,
    highCarbPerKg: StrategyRules.defaultHighCarbPerKg,
    highFatPerKg: StrategyRules.defaultHighFatPerKg,
  );

  final double lowProteinPerKg;
  final double lowCarbPerKg;
  final double lowFatPerKg;
  final double highProteinPerKg;
  final double highCarbPerKg;
  final double highFatPerKg;

  /// Mid-day rate for one macro: the weighted average of the low rate over
  /// (cycleLengthDays − 1) days and the high rate over 1 day — i.e. the
  /// per-day average of the canonical "1 high + rest low" cycle of this
  /// length. This keeps the mid day's energy equal to what the cycle's
  /// average would be without any mid days, independent of how many mid
  /// days actually end up in the schedule.
  double _midPerKgFor(int cycleLengthDays, double lowRate, double highRate) =>
      ((cycleLengthDays - 1) * lowRate + highRate) / cycleLengthDays;

  double midProteinPerKgFor(int cycleLengthDays) =>
      _midPerKgFor(cycleLengthDays, lowProteinPerKg, highProteinPerKg);
  double midCarbPerKgFor(int cycleLengthDays) =>
      _midPerKgFor(cycleLengthDays, lowCarbPerKg, highCarbPerKg);
  double midFatPerKgFor(int cycleLengthDays) =>
      _midPerKgFor(cycleLengthDays, lowFatPerKg, highFatPerKg);

  static bool _inRange(double v, double lo, double hi) =>
      v.isFinite && v >= lo - 1e-9 && v <= hi + 1e-9;

  List<StrategyIssue> validate() {
    final ok =
        _inRange(
          lowProteinPerKg,
          StrategyRules.lowProteinPerKgMin,
          StrategyRules.lowProteinPerKgMax,
        ) &&
        _inRange(
          lowCarbPerKg,
          StrategyRules.lowCarbPerKgMin,
          StrategyRules.lowCarbPerKgMax,
        ) &&
        _inRange(
          lowFatPerKg,
          StrategyRules.lowFatPerKgMin,
          StrategyRules.lowFatPerKgMax,
        ) &&
        _inRange(
          highProteinPerKg,
          StrategyRules.highProteinPerKgMin,
          StrategyRules.highProteinPerKgMax,
        ) &&
        _inRange(
          highCarbPerKg,
          StrategyRules.highCarbPerKgMin,
          StrategyRules.highCarbPerKgMax,
        ) &&
        _inRange(
          highFatPerKg,
          StrategyRules.highFatPerKgMin,
          StrategyRules.highFatPerKgMax,
        );
    return ok ? const [] : const [StrategyIssue.invalidCarbCycleRate];
  }
}

/// One cycle's worth of day targets, computed directly from reference
/// weight × per-macro multipliers (no deficit / TDEE involved).
class CarbCyclePlan {
  const CarbCyclePlan({
    required this.referenceWeightKg,
    required this.rates,
    required this.schedule,
    required this.days,
    required this.issues,
  });

  final double referenceWeightKg;
  final CarbCycleRates rates;
  final CarbCycleSchedule schedule;

  /// Full-precision day targets, in schedule/cycle order.
  final List<DayMacroTarget> days;

  final List<StrategyIssue> issues;

  bool get usable => issues.isEmpty;

  /// Σ E_i across one cycle.
  double get cycleEnergy => days.fold(0.0, (s, d) => s + d.energy);

  double get cycleAverageEnergy => cycleEnergy / days.length;

  DayMacroTarget dayAt(int cycleIndex) => days[cycleIndex % days.length];

  /// The (first) day with [type], or null if the schedule doesn't include
  /// it (e.g. no high day after the user cycled it away).
  DayMacroTarget? dayFor(CarbDayType type) {
    for (final d in days) {
      if (d.dayType == type) return d;
    }
    return null;
  }

  /// Energy of the (first) day with [type], or null if absent.
  double? energyFor(CarbDayType type) => dayFor(type)?.energy;

  /// Integer-gram macros per day; energy is recomputed from the rounded
  /// grams so 4P + 4C + 9F still matches exactly.
  List<DayMacroTarget> integerDays() {
    return [
      for (final d in days)
        DayMacroTarget(
          proteinG: d.proteinG.roundToDouble(),
          carbG: d.carbG.roundToDouble(),
          fatG: d.fatG.roundToDouble(),
          energy:
              d.proteinG.roundToDouble() * StrategyRules.kcalPerGramProtein +
              d.carbG.roundToDouble() * StrategyRules.kcalPerGramCarb +
              d.fatG.roundToDouble() * StrategyRules.kcalPerGramFat,
          dayType: d.dayType,
        ),
    ];
  }
}

/// Computes a [CarbCyclePlan] from reference weight, multipliers and
/// schedule — no shared weekly budget, no deficit/TDEE input.
///
/// Mid-day macros are the weighted average of the low/high rates over one
/// cycle of this length (see [CarbCycleRates.midCarbPerKgFor]), so a mid
/// day's energy always equals the cycle's average energy *before* any low
/// day was turned into a mid day. Introducing mid days would otherwise push
/// the cycle's average energy up (a mid day burns more than the low day it
/// replaced), so — to hold that average steady — the single high day's
/// carbohydrate (only; protein and fat stay at the user-set rate) is
/// reduced by the same total amount the mid days added. Low-day macros are
/// never touched.
abstract final class CarbCyclePlanner {
  static CarbCyclePlan compute({
    required double referenceWeightKg,
    required CarbCycleRates rates,
    required CarbCycleSchedule schedule,
  }) {
    final issues = <StrategyIssue>[];
    if (!_finitePositive(referenceWeightKg)) {
      issues.add(StrategyIssue.invalidWeight);
    }
    issues.addAll(rates.validate());
    final w = _finitePositive(referenceWeightKg) ? referenceWeightKg : 0.0;
    final n = schedule.cycleLengthDays;
    final midDays = schedule.count(CarbDayType.mid);

    final low = _macroDay(
      w,
      rates.lowProteinPerKg,
      rates.lowCarbPerKg,
      rates.lowFatPerKg,
      CarbDayType.low,
    );
    final mid = _macroDay(
      w,
      rates.midProteinPerKgFor(n),
      rates.midCarbPerKgFor(n),
      rates.midFatPerKgFor(n),
      CarbDayType.mid,
    );

    // Original (unadjusted) high day, and the compensated one actually used
    // when mid days are present.
    final highOriginal = _macroDay(
      w,
      rates.highProteinPerKg,
      rates.highCarbPerKg,
      rates.highFatPerKg,
      CarbDayType.high,
    );
    var high = highOriginal;
    if (midDays > 0) {
      // Total extra energy the mid days add relative to the low days they
      // replaced, spread evenly over the cycle: (midDays/n) × (E_high − E_low).
      final deltaEnergy = (midDays / n) * (highOriginal.energy - low.energy);
      final deltaCarbG = deltaEnergy / StrategyRules.kcalPerGramCarb;
      final adjustedCarbG = highOriginal.carbG - deltaCarbG;
      if (adjustedCarbG < -1e-6) {
        issues.add(StrategyIssue.carbCycleHighDayCarbDepleted);
      }
      final carbG = math.max(0.0, adjustedCarbG);
      high = DayMacroTarget(
        energy:
            highOriginal.proteinG * StrategyRules.kcalPerGramProtein +
            carbG * StrategyRules.kcalPerGramCarb +
            highOriginal.fatG * StrategyRules.kcalPerGramFat,
        proteinG: highOriginal.proteinG,
        carbG: carbG,
        fatG: highOriginal.fatG,
        dayType: CarbDayType.high,
      );
    }

    final byType = {
      CarbDayType.low: low,
      CarbDayType.mid: mid,
      CarbDayType.high: high,
    };
    final days = [for (final type in schedule.days) byType[type]!];
    if (days.isNotEmpty) {
      final minEnergy = days.map((d) => d.energy).reduce(math.min);
      if (minEnergy.isFinite &&
          minEnergy < StrategyRules.absoluteEnergyFloorKcal - 1e-6) {
        issues.add(StrategyIssue.energyBelowFloor);
      }
    }
    return CarbCyclePlan(
      referenceWeightKg: w,
      rates: rates,
      schedule: schedule,
      days: days,
      issues: List.unmodifiable(issues),
    );
  }

  static DayMacroTarget _macroDay(
    double referenceWeightKg,
    double proteinPerKg,
    double carbPerKg,
    double fatPerKg,
    CarbDayType type,
  ) {
    final p = referenceWeightKg * proteinPerKg;
    final c = referenceWeightKg * carbPerKg;
    final f = referenceWeightKg * fatPerKg;
    return DayMacroTarget(
      energy:
          p * StrategyRules.kcalPerGramProtein +
          c * StrategyRules.kcalPerGramCarb +
          f * StrategyRules.kcalPerGramFat,
      proteinG: p,
      carbG: c,
      fatG: f,
      dayType: type,
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

/// Cycle-date helpers (local calendar).
abstract final class StrategyDates {
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 0-based position of [date] within a [cycleLengthDays]-day cycle
  /// anchored at [cycleStart] (cycle day 0 = [cycleStart]).
  ///
  /// [restDaysBefore] counts 休息日-marked dates in `[cycleStart, date)`;
  /// each one pauses the cycle for a day, so later dates take on the index
  /// the rest day itself would have occupied. Defaults to 0 (no behavior
  /// change when there are no rest-day markers).
  static int cycleIndexOf(
    DateTime date,
    DateTime cycleStart,
    int cycleLengthDays, {
    int restDaysBefore = 0,
  }) {
    final diff =
        dayOnly(date).difference(dayOnly(cycleStart)).inDays - restDaysBefore;
    final idx = diff % cycleLengthDays;
    return idx < 0 ? idx + cycleLengthDays : idx;
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
