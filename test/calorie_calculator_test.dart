import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_plan/domain/calorie_calculator.dart';
import 'package:fitness_plan/domain/models.dart';

void main() {
  const calc = CalorieCalculator();

  group('CalorieCalculator', () {
    test('male sedentary maintain BMR and macros', () {
      // BMR = 10*70 + 6.25*175 - 5*30 + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
      final bmr = calc.bmr(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 175,
        age: 30,
      );
      expect(bmr, closeTo(1648.75, 0.01));

      final tdee = calc.tdee(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 175,
        age: 30,
        activity: ActivityLevel.sedentary,
      );
      expect(tdee, closeTo(1648.75 * 1.2, 0.01));

      final targets = calc.calculate(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 175,
        age: 30,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.maintain,
      );

      expect(targets.calories, 1979); // round(1978.5)
      expect(targets.proteinG, 140.0); // 70 * 2.0
      expect(targets.fatG, 56.0); // 70 * 0.8
      // carb = (1979 - 140*4 - 56*9) / 4 = (1979 - 560 - 504) / 4 = 915/4 = 228.75 → 228.8
      expect(targets.carbG, 228.8);
    });

    test('female cut reduces calories by 20%', () {
      final maintain = calc.tdee(
        sex: Sex.female,
        weightKg: 55,
        heightCm: 160,
        age: 28,
        activity: ActivityLevel.light,
      );
      final targets = calc.calculate(
        sex: Sex.female,
        weightKg: 55,
        heightCm: 160,
        age: 28,
        activity: ActivityLevel.light,
        goal: FitnessGoal.cut,
      );
      expect(targets.calories, (maintain * 0.8).round());
      expect(targets.proteinG, 110.0); // 55 * 2.0
    });

    test('bulk uses 2.2 g/kg protein and +10% calories', () {
      final maintain = calc.tdee(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activity: ActivityLevel.moderate,
      );
      final targets = calc.calculate(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.bulk,
      );
      expect(targets.calories, (maintain * 1.1).round());
      expect(targets.proteinG, 176.0); // 80 * 2.2
    });
  });
}
