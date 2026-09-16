import 'package:flutter_test/flutter_test.dart';
import 'package:diet/domain/calorie_calculator.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/domain/plateau.dart';

void main() {
  const calc = CalorieCalculator();

  group('CalorieCalculator', () {
    test('example male 70kg/183cm/23 moderate cut eats at TDEE', () {
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
      );

      // No fixed deficit — a fat-loss strategy plan is what creates one now.
      expect(plan.tdee, closeTo(1733.75 * 1.55, 0.01));
      expect(plan.dailyDeficit, 0);
      expect(plan.targets.calories, plan.tdee.round());
      expect(plan.kgToLose, closeTo(5, 0.01));
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

    test('cut without a target weight still eats at TDEE', () {
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
      // No target weight is a normal state (it's no longer a collected
      // input), not an error — just no kgToLose to show.
      expect(plan.kgToLose, isNull);
      expect(plan.targetWeightKg, isNull);
      expect(plan.dailyDeficit, 0);
      expect(plan.targets.calories, maintain.round());
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
      );
      final adjusted = calc.plan(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 183,
        age: 23,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.cut,
        targetWeightKg: 65,
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
    test('detects flat weight across last 7 logs', () {
      final logs = [
        for (var i = 0; i < 7; i++)
          (
            date: DateTime(2026, 7, 1 + i),
            weightKg: 70.0 + (i.isEven ? 0.1 : 0.0),
          ),
      ];
      expect(Plateau.detect(logs), isTrue);
    });

    test('false when latest is at least 0.3 kg below earliest', () {
      final logs = [
        (date: DateTime(2026, 7, 1), weightKg: 70.0),
        (date: DateTime(2026, 7, 2), weightKg: 70.0),
        (date: DateTime(2026, 7, 3), weightKg: 69.9),
        (date: DateTime(2026, 7, 4), weightKg: 69.9),
        (date: DateTime(2026, 7, 5), weightKg: 69.8),
        (date: DateTime(2026, 7, 6), weightKg: 69.75),
        (date: DateTime(2026, 7, 7), weightKg: 69.7), // −0.3 vs earliest
      ];
      expect(Plateau.detect(logs), isFalse);
    });

    test('false when clear downward progress', () {
      final logs = [
        for (var i = 0; i < 7; i++)
          (date: DateTime(2026, 7, 1 + i), weightKg: 70.0 - i * 0.2),
      ];
      expect(Plateau.detect(logs), isFalse);
    });

    test('false when fewer than 7 logs', () {
      final logs = [
        (date: DateTime(2026, 7, 10), weightKg: 70.0),
        (date: DateTime(2026, 7, 14), weightKg: 70.0),
      ];
      expect(Plateau.detect(logs), isFalse);
    });

    test('uses only the most recent 7 logs', () {
      final logs = [
        (date: DateTime(2026, 6, 1), weightKg: 75.0),
        for (var i = 0; i < 7; i++)
          (date: DateTime(2026, 7, 1 + i), weightKg: 70.0),
      ];
      expect(Plateau.detect(logs), isTrue);
    });
  });
}
