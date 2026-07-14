import 'models.dart';

/// Mifflin-St Jeor BMR → TDEE → goal calories → macros.
class CalorieCalculator {
  const CalorieCalculator();

  static const fatPerKg = 0.8;

  double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    // Men: 10w + 6.25h - 5a + 5
    // Women: 10w + 6.25h - 5a - 161
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return sex == Sex.male ? base + 5 : base - 161;
  }

  double tdee({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activity,
  }) {
    return bmr(
          sex: sex,
          weightKg: weightKg,
          heightCm: heightCm,
          age: age,
        ) *
        activity.factor;
  }

  MacroTargets calculate({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activity,
    required FitnessGoal goal,
  }) {
    final maintenance = tdee(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activity: activity,
    );
    final targetCalories = (maintenance * (1 + goal.calorieAdjust)).round();

    final proteinG = weightKg * goal.proteinPerKg;
    final fatG = weightKg * fatPerKg;
    final remainingKcal = targetCalories - proteinG * 4 - fatG * 9;
    final carbG = (remainingKcal / 4).clamp(0, double.infinity);

    return MacroTargets(
      calories: targetCalories,
      proteinG: _round1(proteinG),
      carbG: _round1(carbG.toDouble()),
      fatG: _round1(fatG),
    );
  }

  MacroTargets forProfile({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activity,
    required FitnessGoal goal,
  }) =>
      calculate(
        sex: sex,
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        activity: activity,
        goal: goal,
      );

  static double _round1(double v) => (v * 10).round() / 10;
}
