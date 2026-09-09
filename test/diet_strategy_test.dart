import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

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
    final schedule = CarbCycleSchedule.tryParse('HMHMMLL')!;

    test('handoff example: 2200/2000/2200/2000/2000/1800/1800', () {
      final plan = CarbCyclePlanner.compute(base, schedule);
      expect(plan.alpha, closeTo(1, 1e-9));
      expect(plan.requestedAmplitudeG, 50);
      final e = plan.days.map((d) => d.energy).toList();
      expect(e, [2200, 2000, 2200, 2000, 2000, 1800, 1800]);
      final c = plan.days.map((d) => d.carbG).toList();
      for (var i = 0; i < 7; i++) {
        expect(c[i], closeTo([265, 215, 265, 215, 215, 165, 165][i], 1e-9));
        expect(plan.days[i].proteinG, closeTo(150, 1e-9));
        expect(plan.days[i].fatG, closeTo(60, 1e-9));
        expect(plan.days[i].macroKcal, closeTo(e[i], 1e-9));
      }
      expect(plan.weeklyEnergy, closeTo(14000, 1e-6));
      expect(plan.weeklyAverage, closeTo(2000, 1e-6));
      expect(plan.usable, isTrue);
      expect(plan.amplitudeNegligible, isFalse);
    });

    test('home numbers: eaten 1120 on high/mid/low days', () {
      final plan = CarbCyclePlanner.compute(base, schedule);
      final high = plan.energyFor(CarbDayType.high)!;
      final mid = plan.energyFor(CarbDayType.mid)!;
      final low = plan.energyFor(CarbDayType.low)!;
      expect(high - 1120, 1080);
      expect(mid - 1120, 880);
      expect(low - 1120, 680);
      expect((1120 / high * 100).round(), 51);
    });

    test('any schedule keeps Σ E = 7 × E0 and 4P + 4C + 9F = E', () {
      final rng = math.Random(42);
      for (var trial = 0; trial < 500; trial++) {
        final days = List.generate(
          7,
          (_) => CarbDayType.values[rng.nextInt(3)],
        );
        final w = 50 + rng.nextDouble() * 60;
        final t = 1600 + rng.nextDouble() * 1800;
        final d = 0.10 + rng.nextDouble() * 0.10;
        final b = StrategyBaseline.fromDeficit(
          referenceWeightKg: w,
          tdee: t,
          deficitFraction: d,
        );
        if (!b.feasible) continue;
        final plan = CarbCyclePlanner.compute(b, CarbCycleSchedule(days));
        expect(plan.weeklyEnergy, closeTo(7 * b.energy, 1e-6));
        for (final day in plan.days) {
          expect(day.macroKcal, closeTo(day.energy, 1e-6));
          expect(day.energy, greaterThanOrEqualTo(b.minEnergy - 1e-6));
          expect(day.energy, lessThanOrEqualTo(b.maxEnergy + 1e-6));
          expect(day.proteinG, closeTo(b.proteinG, 1e-9));
          expect(day.fatG, closeTo(b.fatG, 1e-9));
        }
      }
    });

    test('boundary shrink is uniform (α < 1) and preserves the budget', () {
      // Six high days and one low day push the low day far below E_min.
      final b = StrategyBaseline.fromTargetEnergy(
        referenceWeightKg: 75,
        tdee: 2400,
        targetEnergy: 1950, // C0 202.5 → A = 50; room below = 150
      );
      expect(b.feasible, isTrue);
      final plan = CarbCyclePlanner.compute(
        b,
        CarbCycleSchedule.tryParse('HHHHHHL')!,
      );
      // ΔE_low = 200 × (−1 − 5/7) = −342.86 → α = 150 / 342.86 = 0.4375.
      expect(plan.alpha, closeTo(0.4375, 1e-9));
      expect(plan.alpha, greaterThan(0));
      expect(plan.shrunk, isTrue);
      final low = plan.days.last;
      expect(low.energy, closeTo(b.minEnergy, 1e-6));
      expect(plan.weeklyEnergy, closeTo(7 * b.energy, 1e-6));
      // The high days all moved by the same amount.
      final highs = plan.days.take(6).map((d) => d.energy).toSet();
      expect(highs.length, 1);
    });

    test('all-same schedule collapses to a fixed target', () {
      final plan = CarbCyclePlanner.compute(base, CarbCycleSchedule.allMid());
      for (final d in plan.days) {
        expect(d.energy, closeTo(2000, 1e-9));
      }
      expect(plan.amplitudeNegligible, isFalse);
      final allHigh = CarbCyclePlanner.compute(
        base,
        CarbCycleSchedule(List.filled(7, CarbDayType.high)),
      );
      for (final d in allHigh.days) {
        expect(d.energy, closeTo(2000, 1e-9));
      }
    });

    test('partial shrink: 6 high / 1 low with 120 kcal of room', () {
      final plan = CarbCyclePlanner.compute(
        StrategyBaseline.fromTargetEnergy(
          referenceWeightKg: 75,
          tdee: 2400,
          targetEnergy: 1920, // d = 20 %, E_min 1800 → room 120 below
        ),
        CarbCycleSchedule.tryParse('HHHHHHL')!,
      );
      // C0 = 195 → A = 48.75; ΔE_low = 4 × 48.75 × (−1 − 5/7) ≈ −334.3
      // → α = 120 / 334.3 ≈ 0.359.
      expect(plan.requestedAmplitudeG, closeTo(48.75, 1e-9));
      expect(plan.alpha, closeTo(120 / (4 * 48.75 * (1 + 5 / 7)), 1e-9));
      expect(plan.amplitudeNegligible, isFalse);
      expect(plan.weeklyEnergy, closeTo(7 * 1920, 1e-6));
    });

    test('negligible amplitude is reported when E0 sits on E_min', () {
      // W = 100 kg → fixed kcal 1520; +520 = 2040 = 0.85 × 2400 = E0.
      final b = StrategyBaseline.fromDeficit(
        referenceWeightKg: 100,
        tdee: 2400,
        deficitFraction: 0.15,
      );
      expect(b.feasible, isTrue);
      expect(b.carbG, closeTo(130, 1e-9));
      expect(b.minEnergy, closeTo(2040, 1e-9));
      final plan = CarbCyclePlanner.compute(b, schedule);
      expect(plan.alpha, closeTo(0, 1e-9));
      expect(plan.amplitudeNegligible, isTrue);
      expect(plan.usable, isTrue); // still a valid (flat) plan
      for (final d in plan.days) {
        expect(d.energy, closeTo(2040, 1e-9));
      }
    });

    test('infeasible baseline yields α = 0 and blocks use', () {
      final b = StrategyBaseline.fromDeficit(
        referenceWeightKg: 120,
        tdee: 2500,
      );
      final plan = CarbCyclePlanner.compute(b, schedule);
      expect(plan.alpha, 0);
      expect(plan.usable, isFalse);
    });

    test('integer export keeps Σ = round(7E0) and recomputes carbs', () {
      final b = StrategyBaseline.fromDeficit(
        referenceWeightKg: 68.3,
        tdee: 2233.7,
        deficitFraction: 0.13,
      );
      final plan = CarbCyclePlanner.compute(b, schedule);
      final ints = plan.integerDays();
      final sum = ints.fold<double>(0, (s, d) => s + d.energy);
      expect(sum, (7 * b.energy).round());
      for (final d in ints) {
        expect(d.energy, d.energy.roundToDouble());
        expect(d.macroKcal, closeTo(d.energy, 1e-6));
      }
    });

    test('schedule parsing rejects malformed codes', () {
      expect(CarbCycleSchedule.tryParse('HMHMML'), isNull);
      expect(CarbCycleSchedule.tryParse('HMHMMLX'), isNull);
      expect(CarbCycleSchedule.tryParse(null), isNull);
      expect(() => CarbCycleSchedule([CarbDayType.high]), throwsArgumentError);
      final s = CarbCycleSchedule.tryParse('HMHMMLL')!;
      expect(s.forDate(DateTime(2026, 9, 7)), CarbDayType.high); // Monday
      expect(s.forDate(DateTime(2026, 9, 13)), CarbDayType.low); // Sunday
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

  group('taper review', () {
    final today = DateTime(2026, 9, 30);
    Map<DateTime, double> weights(
      double start,
      double perDay, {
      int days = 14,
    }) {
      final m = <DateTime, double>{};
      for (var i = 0; i < days; i++) {
        final d = today.subtract(Duration(days: i));
        m[d] = start - perDay * (days - 1 - i);
      }
      return m;
    }

    Set<DateTime> complete(int n) => {
      for (var i = 0; i < n; i++) today.subtract(Duration(days: i)),
    };

    test('still observing before the window closes', () {
      final r = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 10)),
          requiredObservationDays: 14,
          dailyWeights: weights(80, 0.05),
          completeDietDays: complete(14),
        ),
        nextStageFeasible: true,
      );
      expect(r.status, TaperReviewStatus.observing);
      expect(r.daysObserved, 10);
      expect(r.nextReviewDate, today.add(const Duration(days: 4)));
      expect(r.canStepDown, isFalse);
    });

    test('missing weigh-ins block the review (missing ≠ zero)', () {
      final w = weights(80, 0.0);
      // Keep only 8 days.
      final keys = w.keys.toList()..sort();
      for (final k in keys.take(6)) {
        w.remove(k);
      }
      final r = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 20)),
          requiredObservationDays: 14,
          dailyWeights: w,
          completeDietDays: complete(14),
        ),
        nextStageFeasible: true,
      );
      expect(r.status, TaperReviewStatus.insufficientWeightData);
      expect(r.canStepDown, isFalse);
    });

    test('unconfirmed diet days block the review', () {
      final r = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 20)),
          requiredObservationDays: 14,
          dailyWeights: weights(80, 0.0),
          completeDietDays: complete(6),
        ),
        nextStageFeasible: true,
      );
      expect(r.status, TaperReviewStatus.insufficientDietData);
      expect(r.completeDietDays, 6);
    });

    test('rate inside band → hold; too high → stop; stalled → candidate', () {
      // 0.5%/week of 80 kg ≈ 0.4 kg per 7 days ≈ 0.057 kg/day.
      final inBand = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 20)),
          requiredObservationDays: 14,
          dailyWeights: weights(80, 0.057),
          completeDietDays: complete(14),
        ),
        nextStageFeasible: true,
      );
      expect(inBand.status, TaperReviewStatus.hold);
      expect(inBand.weeklyRate, closeTo(0.005, 0.0015));

      final fast = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 20)),
          requiredObservationDays: 14,
          dailyWeights: weights(80, 0.2),
          completeDietDays: complete(14),
        ),
        nextStageFeasible: true,
      );
      expect(fast.status, TaperReviewStatus.rateTooHigh);

      final stalled = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 20)),
          requiredObservationDays: 14,
          dailyWeights: weights(80, 0.0),
          completeDietDays: complete(14),
        ),
        nextStageFeasible: true,
      );
      expect(stalled.status, TaperReviewStatus.stepDownCandidate);
      expect(stalled.canStepDown, isTrue);

      final floor = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 20)),
          requiredObservationDays: 14,
          dailyWeights: weights(80, 0.0),
          completeDietDays: complete(14),
        ),
        nextStageFeasible: false,
      );
      expect(floor.status, TaperReviewStatus.floorReached);
      expect(floor.canStepDown, isFalse);
    });

    test('ignores non-finite weights and dates outside the window', () {
      final w = weights(80, 0.0);
      w[today.subtract(const Duration(days: 30))] = 95;
      w[today.add(const Duration(days: 3))] = 10;
      w[today.subtract(const Duration(days: 3))] = double.nan;
      final r = TaperReviewer.evaluate(
        TaperReviewInput(
          today: today,
          observationStart: today.subtract(const Duration(days: 20)),
          requiredObservationDays: 14,
          dailyWeights: w,
          completeDietDays: complete(14),
        ),
        nextStageFeasible: true,
      );
      expect(r.weightDays, 13);
      expect(r.weeklyRate, closeTo(0, 1e-9));
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

  group('training suggestion', () {
    test('maps weekday counts to high / mid / low without applying itself', () {
      final s = CarbCyclePlanner.suggestFromTraining({
        1: 4, // Mon trained every week → high
        2: 1, // Tue once in 4 weeks → mid
        3: 3,
        4: 0,
        5: 2,
        6: 0,
        7: 0,
      }, weeks: 4);
      expect(s.days[0], CarbDayType.high);
      expect(s.days[1], CarbDayType.mid);
      expect(s.days[2], CarbDayType.high);
      expect(s.days[3], CarbDayType.low);
      expect(s.days[4], CarbDayType.high); // 2*2 >= 4
      expect(s.days[5], CarbDayType.low);
      expect(s.days[6], CarbDayType.low);
    });
  });

  group('dates', () {
    test('next cycle starts on the Monday strictly after today', () {
      expect(
        StrategyDates.nextCycleStart(DateTime(2026, 9, 7)),
        DateTime(2026, 9, 14),
      ); // Monday → next Monday
      expect(
        StrategyDates.nextCycleStart(DateTime(2026, 9, 9)),
        DateTime(2026, 9, 14),
      ); // Wednesday
      expect(
        StrategyDates.nextCycleStart(DateTime(2026, 9, 13)),
        DateTime(2026, 9, 14),
      ); // Sunday
      expect(
        StrategyDates.cycleStartOf(DateTime(2026, 9, 13)),
        DateTime(2026, 9, 7),
      );
    });

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
}
