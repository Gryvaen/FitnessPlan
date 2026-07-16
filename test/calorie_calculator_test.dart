import 'package:flutter_test/flutter_test.dart';
import 'package:diet/domain/calorie_calculator.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/domain/plateau.dart';

void main() {
  const calc = CalorieCalculator();

  group('CalorieCalculator', () {
    test('example male 70kg/183cm/23 moderate BMR and 0.5 kg/week cut', () {
      final bmr = calc.bmr(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
      );
      expect(bmr, closeTo(1733.75, 0.01));

      final plan = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.cut,
        targetWeightKg: 65,
        weeklyLossKg: 0.5,
      );

      expect(plan.tdee, closeTo(1733.75 * 1.55, 0.01));
      expect(plan.dailyDeficit, closeTo(550, 0.01));
      expect(plan.weeklyLossKg, 0.5);
      expect(plan.goalWeeks, 10);
      expect(plan.targets.calories, (plan.tdee - 550).round());
      expect(plan.proteinPerKg, 2.0);
      expect(plan.targets.proteinG, 140.0);
      expect(plan.targets.fatG, 56.0);
    });

    test('male sedentary maintain uses 2.0 g/kg protein', () {
      final plan = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 175,
        age: 30,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.maintain,
      );

      expect(plan.dailyDeficit, 0);
      expect(plan.proteinPerKg, 2.0);
      expect(plan.targets.proteinG, 140.0);
      expect(plan.targets.fatG, 56.0);
      expect(plan.targets.calories, plan.tdee.round());
    });

    test('request 2 kg/week clamps to 0.8 with note', () {
      final plan = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.cut,
        targetWeightKg: 65,
        weeklyLossKg: 2.0,
      );

      expect(plan.requestedWeeklyLossKg, CalorieCalculator.maxWeeklyLoss);
      expect(plan.safetyApplied, isTrue);
      expect(plan.weeklyLossKg, closeTo(CalorieCalculator.maxWeeklyLoss, 0.01));
      expect(plan.dailyDeficit, closeTo(0.8 * 7700 / 7, 0.01));
      expect(plan.goalWeeks, isNotNull);
      expect(
        plan.notes.any((n) => n.contains('不建议超过')),
        isTrue,
      );
    });

    test('legacy goalWeeks migrates to weekly rate inside plan', () {
      final plan = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 175,
        age: 30,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.cut,
        targetWeightKg: 65,
        goalWeeks: 10,
      );

      expect(plan.weeklyLossKg, closeTo(0.5, 0.01));
      expect(plan.dailyDeficit, closeTo(550, 0.01));
      expect(plan.safetyApplied, isFalse);
      expect(plan.targets.proteinG, 140.0);
    });

    test('cut has no calorie floor — uses TDEE minus full deficit', () {
      final plan = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 175,
        age: 30,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.cut,
        targetWeightKg: 65,
        weeklyLossKg: 0.5,
      );
      expect(plan.dailyDeficit, closeTo(550, 0.01));
      expect(plan.targets.calories, (plan.tdee - 550).round());
      expect(plan.weeklyLossKg, closeTo(0.5, 0.01));
      expect(plan.goalWeeks, 10);
      expect(plan.safetyApplied, isFalse);
    });

    test('cut without target falls back to 80% TDEE', () {
      final maintain = calc.tdee(
        sex: Sex.female,
        weightKg: 55,
        heightCm: 160,
        age: 28,
        activity: ActivityLevel.light,
      );
      final plan = calc.plan(
        sex: Sex.female,
        weightKg: 55,
        heightCm: 160,
        age: 28,
        activity: ActivityLevel.light,
        goal: FitnessGoal.cut,
      );
      expect(plan.missingCutInputs, isTrue);
      expect(plan.targets.calories, (maintain * 0.8).round());
    });

    test('calorieAdjustment reduces intake', () {
      final base = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.cut,
        targetWeightKg: 65,
        weeklyLossKg: 0.5,
      );
      final adjusted = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.cut,
        targetWeightKg: 65,
        weeklyLossKg: 0.5,
        calorieAdjustment: 100,
      );
      expect(adjusted.targets.calories, base.targets.calories - 100);
      expect(adjusted.calorieAdjustment, 100);
    });

    test('bulk uses 2.2 g/kg protein and +10% calories', () {
      final maintain = calc.tdee(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activity: ActivityLevel.moderate,
      );
      final plan = calc.plan(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.bulk,
      );
      expect(plan.targets.calories, (maintain * 1.1).round());
      expect(plan.targets.proteinG, 176.0);
      expect(plan.proteinPerKg, 2.2);
    });

    test('athlete activity factor is 1.9', () {
      final tdee = calc.tdee(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
        activity: ActivityLevel.athlete,
      );
      final bmr = calc.bmr(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
      );
      expect(tdee, closeTo(bmr * 1.9, 0.01));
    });
  });

  group('Plateau', () {
    test('detects flat weight over 14 days', () {
      final now = DateTime(2026, 7, 14);
      final logs = [
        (date: DateTime(2026, 6, 30), weightKg: 70.0),
        (date: DateTime(2026, 7, 7), weightKg: 69.9),
        (date: DateTime(2026, 7, 14), weightKg: 70.1),
      ];
      expect(Plateau.detect(logs, now: now), isTrue);
    });

    test('false when clear downward progress', () {
      final now = DateTime(2026, 7, 14);
      final logs = [
        (date: DateTime(2026, 6, 30), weightKg: 70.0),
        (date: DateTime(2026, 7, 14), weightKg: 69.0),
      ];
      expect(Plateau.detect(logs, now: now), isFalse);
    });

    test('false when span too short', () {
      final now = DateTime(2026, 7, 14);
      final logs = [
        (date: DateTime(2026, 7, 10), weightKg: 70.0),
        (date: DateTime(2026, 7, 14), weightKg: 70.0),
      ];
      expect(Plateau.detect(logs, now: now), isFalse);
    });
  });
}
