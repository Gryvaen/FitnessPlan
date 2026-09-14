import 'package:flutter_test/flutter_test.dart';

import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/domain/strategy_eligibility.dart';

void main() {
  // Synthetic acceptance example from the handoff: 75 kg, TDEE 2400,
  // confirmed average 2000 kcal → P150 / F60 / C215.
  final base = StrategyBaseline.fromTargetEnergy(
    referenceWeightKg: 75,
    tdee: 2400,
    targetEnergy: 2000,
  );

  group('baseline', () {
    test('example produces P150 F60 C215 with feasible bounds', () {
      expect(base.feasible, isTrue);
      expect(base.proteinG, closeTo(150, 1e-9));
      expect(base.fatG, closeTo(60, 1e-9));
      expect(base.carbG, closeTo(215, 1e-9));
      expect(base.deficitFraction, closeTo(400 / 2400, 1e-9));
      expect(base.minEnergy, closeTo(1800, 1e-9));
      expect(base.maxEnergy, 2400);
      expect(base.dailyDeficit, closeTo(400, 1e-9));
    });

    test('fromDeficit default 15% matches T × 0.85', () {
      final b = StrategyBaseline.fromDeficit(referenceWeightKg: 75, tdee: 2400);
      expect(b.energy, closeTo(2040, 1e-9));
      expect(b.feasible, isTrue);
    });

    test('rejects NaN / infinite / zero / negative inputs', () {
      for (final bad in [double.nan, double.infinity, 0.0, -5.0]) {
        final b = StrategyBaseline.fromTargetEnergy(
          referenceWeightKg: bad,
          tdee: 2400,
          targetEnergy: 2000,
        );
        expect(b.issues, contains(StrategyIssue.invalidWeight));
        expect(b.feasible, isFalse);
        final t = StrategyBaseline.fromTargetEnergy(
          referenceWeightKg: 75,
          tdee: bad,
          targetEnergy: 2000,
        );
        expect(t.issues, contains(StrategyIssue.invalidTdee));
        final e = StrategyBaseline.fromTargetEnergy(
          referenceWeightKg: 75,
          tdee: 2400,
          targetEnergy: bad,
        );
        expect(e.issues, contains(StrategyIssue.invalidTargetEnergy));
      }
      final d = StrategyBaseline.fromDeficit(
        referenceWeightKg: 75,
        tdee: 2400,
        deficitFraction: double.nan,
      );
      expect(d.feasible, isFalse);
    });

    test('deficit outside 10–20% is flagged', () {
      final low = StrategyBaseline.fromDeficit(
        referenceWeightKg: 75,
        tdee: 2400,
        deficitFraction: 0.05,
      );
      expect(low.issues, contains(StrategyIssue.deficitBelowRange));
      final high = StrategyBaseline.fromDeficit(
        referenceWeightKg: 75,
        tdee: 2400,
        deficitFraction: 0.30,
      );
      expect(high.issues, contains(StrategyIssue.deficitAboveRange));
    });

    test('heavy user with low TDEE hits carb floor instead of clamping', () {
      // 120 kg → P240 F96 → fixed 1824 kcal; +520 = 2344 floor.
      final b = StrategyBaseline.fromDeficit(
        referenceWeightKg: 120,
        tdee: 2500,
        deficitFraction: 0.15,
      );
      expect(b.feasible, isFalse);
      expect(b.issues, contains(StrategyIssue.energyBelowFloor));
      expect(b.issues, contains(StrategyIssue.carbBelowMinimum));
      // Carbs are reported as-is (negative or low) rather than silently 0.
      expect(b.carbG, lessThan(StrategyRules.minCarbG));
    });
  });

  group('carb cycle', () {
    final rates = CarbCycleRates.defaults();

    test('defaultFor: one high day on the last position, the rest low', () {
      for (final n in StrategyRules.cycleLengthDaysOptions) {
        final s = CarbCycleSchedule.defaultFor(n);
        expect(s.cycleLengthDays, n);
        expect(s.count(CarbDayType.high), 1);
        expect(s.count(CarbDayType.mid), 0);
        expect(s.count(CarbDayType.low), n - 1);
        expect(s.days.last, CarbDayType.high);
      }
    });

    test('cycleDayType: non-high days toggle low <-> mid, skipping invalid', () {
      // 3-day cycle: [low, low, high]. Tapping day 0 (low) goes to mid
      // (valid: 1 mid ≤ 1 low remaining elsewhere).
      var s = CarbCycleSchedule.defaultFor(3);
      s = s.cycleDayType(0); // low -> mid
      expect(s.days[0], CarbDayType.mid);
      expect(s.count(CarbDayType.mid), 1);
      expect(s.count(CarbDayType.low), 1);

      // Tapping day 1 (still low) would need mid=2 > low=0 — invalid, so it
      // stays low (mid -> low is always the other direction; there's no
      // "skip to high" anymore, only the high day itself can become high).
      final before = s.days[1];
      s = s.cycleDayType(1);
      expect(s.days[1], before);

      // A mid day always reverts to low with no validity check needed.
      s = s.cycleDayType(0); // mid -> low
      expect(s.days[0], CarbDayType.low);
      expect(s.count(CarbDayType.mid), 0);
    });

    test('cycleDayType: tapping the high day swaps it to the other end', () {
      // 3-day cycle: [low, low, high] (high on the last position).
      var s = CarbCycleSchedule.defaultFor(3);
      s = s.cycleDayType(0); // day 0: low -> mid, so target overwrite is visible
      expect(s.days, [CarbDayType.mid, CarbDayType.low, CarbDayType.high]);

      // Tap the high day (index 2, the last day): moves to index 0
      // (overwriting whatever was there — here the mid day), and the
      // vacated last day becomes low.
      s = s.cycleDayType(2);
      expect(s.days, [CarbDayType.high, CarbDayType.low, CarbDayType.low]);
      expect(s.count(CarbDayType.high), 1);
      expect(s.count(CarbDayType.mid), 0); // the mid day was overwritten

      // Tapping it again from the front swaps it straight back to the end.
      s = s.cycleDayType(0);
      expect(s.days, [CarbDayType.low, CarbDayType.low, CarbDayType.high]);
    });

    test('schedule constructor rejects invalid layouts', () {
      expect(() => CarbCycleSchedule([CarbDayType.high]), throwsArgumentError);
      expect(
        () => CarbCycleSchedule(List.filled(4, CarbDayType.high)),
        throwsArgumentError,
      );
      expect(
        () => CarbCycleSchedule(List.filled(3, CarbDayType.low)),
        throwsArgumentError,
      ); // zero high days is no longer allowed
      expect(
        () => CarbCycleSchedule([
          CarbDayType.high,
          CarbDayType.mid,
          CarbDayType.mid,
          CarbDayType.low,
        ]),
        throwsArgumentError,
      );
      expect(CarbCycleSchedule.tryParse('HML'), isNotNull);
      expect(CarbCycleSchedule.tryParse('HM'), isNull); // too short
      expect(CarbCycleSchedule.tryParse('LLL'), isNull); // no high day
      expect(CarbCycleSchedule.tryParse('HMMML'), isNull); // mid > low
      expect(CarbCycleSchedule.tryParse('HHMLL'), isNull); // 2 high
      expect(CarbCycleSchedule.tryParse(null), isNull);
    });

    test(
      'mid-day rate is the (N-1 low + 1 high) weighted average per macro',
      () {
        const n = 4;
        expect(
          rates.midProteinPerKgFor(n),
          closeTo(
            ((n - 1) * rates.lowProteinPerKg + rates.highProteinPerKg) / n,
            1e-9,
          ),
        );
        expect(
          rates.midCarbPerKgFor(n),
          closeTo(
            ((n - 1) * rates.lowCarbPerKg + rates.highCarbPerKg) / n,
            1e-9,
          ),
        );
        expect(
          rates.midFatPerKgFor(n),
          closeTo(((n - 1) * rates.lowFatPerKg + rates.highFatPerKg) / n, 1e-9),
        );
        // Mid energy therefore equals the baseline (no-mid) cycle average.
        final baseline = CarbCyclePlanner.compute(
          referenceWeightKg: 75,
          rates: rates,
          schedule: CarbCycleSchedule.defaultFor(4),
        );
        final withMid = CarbCyclePlanner.compute(
          referenceWeightKg: 75,
          rates: rates,
          schedule: CarbCycleSchedule.defaultFor(4).cycleDayType(1),
        );
        expect(
          withMid.energyFor(CarbDayType.mid),
          closeTo(baseline.cycleAverageEnergy, 1e-6),
        );
      },
    );

    test(
      'adding a mid day keeps the cycle average steady by trimming the '
      'high day\'s carbs only (protein/fat and the low day stay put)',
      () {
        final baseline = CarbCyclePlanner.compute(
          referenceWeightKg: 75,
          rates: rates,
          schedule: CarbCycleSchedule.defaultFor(4),
        );
        final withMid = CarbCyclePlanner.compute(
          referenceWeightKg: 75,
          rates: rates,
          schedule: CarbCycleSchedule.defaultFor(4).cycleDayType(1),
        );
        // The cycle-wide average energy is unchanged by introducing a mid day.
        expect(
          withMid.cycleAverageEnergy,
          closeTo(baseline.cycleAverageEnergy, 1e-6),
        );
        final baseHigh = baseline.days.firstWhere(
          (d) => d.dayType == CarbDayType.high,
        );
        final adjustedHigh = withMid.days.firstWhere(
          (d) => d.dayType == CarbDayType.high,
        );
        expect(adjustedHigh.carbG, lessThan(baseHigh.carbG));
        expect(adjustedHigh.proteinG, closeTo(baseHigh.proteinG, 1e-9));
        expect(adjustedHigh.fatG, closeTo(baseHigh.fatG, 1e-9));
        // ΔC = (midDays/N) × (E_high − E_low) / 4, computed independently
        // of CarbCyclePlanner so this isn't just re-asserting the impl.
        const w = 75.0, n = 4, m = 1;
        final elow =
            w *
            (4 * rates.lowProteinPerKg +
                4 * rates.lowCarbPerKg +
                9 * rates.lowFatPerKg);
        final ehigh =
            w *
            (4 * rates.highProteinPerKg +
                4 * rates.highCarbPerKg +
                9 * rates.highFatPerKg);
        final deltaCarbG = (m / n) * (ehigh - elow) / 4;
        final expectedHighCarbG = w * rates.highCarbPerKg - deltaCarbG;
        expect(adjustedHigh.carbG, closeTo(expectedHighCarbG, 1e-6));
        expect(
          adjustedHigh.energy,
          closeTo(adjustedHigh.macroKcal, 1e-6),
        );
        final low = withMid.days.firstWhere((d) => d.dayType == CarbDayType.low);
        final baseLow = baseline.days.firstWhere(
          (d) => d.dayType == CarbDayType.low,
        );
        expect(low.carbG, closeTo(baseLow.carbG, 1e-9));
        expect(low.energy, closeTo(elow, 1e-6));
      },
    );

    test('day macros scale linearly with reference weight', () {
      final schedule = CarbCycleSchedule.defaultFor(4);
      final plan = CarbCyclePlanner.compute(
        referenceWeightKg: 80,
        rates: rates,
        schedule: schedule,
      );
      for (final d in plan.days) {
        expect(d.macroKcal, closeTo(d.energy, 1e-6));
        if (d.dayType == CarbDayType.low) {
          expect(d.proteinG, closeTo(80 * rates.lowProteinPerKg, 1e-9));
          expect(d.carbG, closeTo(80 * rates.lowCarbPerKg, 1e-9));
          expect(d.fatG, closeTo(80 * rates.lowFatPerKg, 1e-9));
        } else if (d.dayType == CarbDayType.high) {
          expect(d.proteinG, closeTo(80 * rates.highProteinPerKg, 1e-9));
          expect(d.carbG, closeTo(80 * rates.highCarbPerKg, 1e-9));
          expect(d.fatG, closeTo(80 * rates.highFatPerKg, 1e-9));
        }
      }
      expect(plan.usable, isTrue);
    });

    test('rates outside the recommended range are flagged', () {
      const bad = CarbCycleRates(
        lowProteinPerKg: 1.0, // below 1.8 min
        lowCarbPerKg: 1.2,
        lowFatPerKg: 0.9,
        highProteinPerKg: 1.5,
        highCarbPerKg: 4.0,
        highFatPerKg: 0.5,
      );
      final plan = CarbCyclePlanner.compute(
        referenceWeightKg: 75,
        rates: bad,
        schedule: CarbCycleSchedule.defaultFor(3),
      );
      expect(plan.issues, contains(StrategyIssue.invalidCarbCycleRate));
      expect(plan.usable, isFalse);
    });

    test('integer export rounds grams and recomputes energy', () {
      final plan = CarbCyclePlanner.compute(
        referenceWeightKg: 68.3,
        rates: rates,
        schedule: CarbCycleSchedule.defaultFor(5).cycleDayType(1),
      );
      final ints = plan.integerDays();
      for (final d in ints) {
        expect(d.proteinG, d.proteinG.roundToDouble());
        expect(d.carbG, d.carbG.roundToDouble());
        expect(d.fatG, d.fatG.roundToDouble());
        expect(d.macroKcal, closeTo(d.energy, 1e-6));
      }
    });

    test('cycleAverageEnergy is the mean of the cycle\'s day energies', () {
      final schedule = CarbCycleSchedule.defaultFor(4).cycleDayType(1);
      final plan = CarbCyclePlanner.compute(
        referenceWeightKg: 75,
        rates: rates,
        schedule: schedule,
      );
      final mean =
          plan.days.fold<double>(0, (s, d) => s + d.energy) / plan.days.length;
      expect(plan.cycleAverageEnergy, closeTo(mean, 1e-9));
    });
  });

  group('cycle date indexing', () {
    test('cycleIndexOf wraps around the anchor date', () {
      final anchor = DateTime(2026, 9, 1);
      expect(StrategyDates.cycleIndexOf(anchor, anchor, 4), 0);
      expect(
        StrategyDates.cycleIndexOf(anchor.add(const Duration(days: 3)), anchor, 4),
        3,
      );
      expect(
        StrategyDates.cycleIndexOf(anchor.add(const Duration(days: 4)), anchor, 4),
        0,
      );
      expect(
        StrategyDates.cycleIndexOf(anchor.add(const Duration(days: 9)), anchor, 4),
        1,
      );
      // Before the anchor still resolves to a valid 0-based index.
      expect(
        StrategyDates.cycleIndexOf(anchor.subtract(const Duration(days: 1)), anchor, 4),
        3,
      );
    });
  });

  group('carb taper', () {
    test('stages 2000/215 → 1900/190 → 1800/165 then floor', () {
      final s0 = CarbTaperStage.of(base, 0);
      final s1 = CarbTaperPlanner.nextStage(base, 0)!;
      final s2 = CarbTaperPlanner.nextStage(base, 1)!;
      expect(s0.day.energy, 2000);
      expect(s0.day.carbG, closeTo(215, 1e-9));
      expect(s1.day.energy, 1900);
      expect(s1.day.carbG, closeTo(190, 1e-9));
      expect(s2.day.energy, 1800);
      expect(s2.day.carbG, closeTo(165, 1e-9));
      // 1700 < E_min (1800) → no further step.
      expect(CarbTaperPlanner.nextStage(base, 2), isNull);
      expect(CarbTaperStage.of(base, 3).feasible, isFalse);
      for (final s in [s0, s1, s2]) {
        expect(s.day.macroKcal, closeTo(s.day.energy, 1e-9));
        expect(s.day.proteinG, 150);
        expect(s.day.fatG, 60);
      }
    });

    test('negative stage clamps to 0', () {
      expect(CarbTaperStage.of(base, -3).stage, 0);
    });
  });

  group('eligibility', () {
    UserProfile profile({int age = 30, FitnessGoal goal = FitnessGoal.cut}) {
      return UserProfile(
        sex: Sex.male,
        age: age,
        heightCm: 175,
        weightKg: 75,
        activity: ActivityLevel.moderate,
        goal: goal,
        targets: const MacroTargets(
          calories: 2000,
          proteinG: 150,
          carbG: 215,
          fatG: 60,
        ),
        tdee: 2400,
      );
    }

    test('adult cut users are eligible; minors and non-cut goals are not', () {
      expect(StrategyEligibility.eligible(profile()), isTrue);
      expect(StrategyEligibility.check(profile()), isEmpty);

      final minor = StrategyEligibility.check(profile(age: 16));
      expect(minor, contains(StrategyIssue.underage));
      expect(StrategyEligibility.eligible(profile(age: 17)), isFalse);

      expect(
        StrategyEligibility.check(profile(goal: FitnessGoal.maintain)),
        contains(StrategyIssue.goalNotCut),
      );
      expect(
        StrategyEligibility.check(profile(goal: FitnessGoal.bulk)),
        contains(StrategyIssue.goalNotCut),
      );
      expect(StrategyEligibility.eligible(null), isFalse);
    });
  });

  group('dates', () {
    test('encode / decode round-trips and rejects garbage', () {
      expect(StrategyDates.encode(DateTime(2026, 3, 29, 23, 59)), '2026-03-29');
      expect(StrategyDates.tryDecode('2026-03-29'), DateTime(2026, 3, 29));
      expect(StrategyDates.tryDecode('2026-02-30'), isNull);
      expect(StrategyDates.tryDecode('2026-13-01'), isNull);
      expect(StrategyDates.tryDecode('nope'), isNull);
      expect(StrategyDates.tryDecode(null), isNull);
    });

    test('DST transition days still map to the same local date', () {
      // Local midnight arithmetic across a hypothetical DST edge keeps the
      // calendar day (Dart DateTime() normalises overflow by calendar).
      final d = DateTime(2026, 3, 29);
      final next = DateTime(d.year, d.month, d.day + 1);
      expect(StrategyDates.encode(next), '2026-03-30');
      expect(next.difference(d).inHours, anyOf(23, 24, 25));
    });
  });

  group('fixedPlannedDeficit', () {
    DailyNutritionTarget target({
      required TargetSource source,
      DietStrategyKind? strategy,
      double calories = 2000,
      double? tdee = 2400,
    }) {
      return DailyNutritionTarget(
        date: DateTime(2026, 9, 13),
        calories: calories,
        proteinG: 150,
        carbG: 200,
        fatG: 60,
        source: source,
        estimatedTdee: tdee,
        strategy: strategy,
      );
    }

    test('only balanced strategy exposes fixed planned deficit', () {
      final balanced = target(
        source: TargetSource.strategy,
        strategy: DietStrategyKind.balanced,
      );
      expect(balanced.hasFixedPlannedDeficit, isTrue);
      expect(balanced.fixedPlannedDeficit, closeTo(400, 1e-9));

      final cycle = target(
        source: TargetSource.strategy,
        strategy: DietStrategyKind.carbCycle,
      );
      expect(cycle.hasFixedPlannedDeficit, isFalse);
      expect(cycle.fixedPlannedDeficit, isNull);
      // Raw gap still exists for macros math.
      expect(cycle.plannedDeficit, closeTo(400, 1e-9));

      final profile = target(source: TargetSource.profile);
      expect(profile.hasFixedPlannedDeficit, isFalse);
      expect(profile.fixedPlannedDeficit, isNull);
    });
  });
}
