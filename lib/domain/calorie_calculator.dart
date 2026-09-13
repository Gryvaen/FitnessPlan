import 'models.dart';

/// Identifiers for calorie-plan notes (localized in UI).
enum CalorieNoteId { missingTargetWeight, plateauAdj }

class CalorieNote {
  const CalorieNote(this.id, [this.params = const {}]);

  final CalorieNoteId id;
  final Map<String, Object> params;
}

/// Full calorie plan with intermediate values for transparent UI.
class CaloriePlan {
  const CaloriePlan({
    required this.bmr,
    required this.tdee,
    required this.activityFactor,
    required this.goal,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.dailyDeficit,
    required this.targets,
    required this.proteinPerKg,
    this.targetWeightKg,
    this.kgToLose,
    this.calorieAdjustment = 0,
    this.missingCutInputs = false,
    this.notes = const [],
  });

  final double bmr;
  final double tdee;
  final double activityFactor;
  final FitnessGoal goal;
  final double weightKg;
  final double heightCm;
  final int age;
  final Sex sex;
  final double dailyDeficit;
  final MacroTargets targets;
  final double proteinPerKg;
  final double? targetWeightKg;
  final double? kgToLose;
  final int calorieAdjustment;
  final bool missingCutInputs;
  final List<CalorieNote> notes;

  String get bmrSubstituted {
    final signConst = sex == Sex.male ? '+ 5' : '− 161';
    return '10×${_fmt(weightKg)} + 6.25×${_fmt(heightCm)} − 5×$age $signConst '
        '= ${_fmt(bmr)} kcal';
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

/// Mifflin-St Jeor BMR → TDEE → goal calories → macros.
class CalorieCalculator {
  const CalorieCalculator();

  static const fatPerKg = 0.8;
  static const kcalPerKgFat = 7700.0;
  static const maxCalorieAdjustment = 300;

  double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
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
    return bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age) *
        activity.factor;
  }

  /// Protein g/kg by goal only.
  static double proteinPerKgFor(FitnessGoal goal) {
    if (goal == FitnessGoal.bulk) return 2.2;
    return 2.0;
  }

  CaloriePlan plan({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activity,
    required FitnessGoal goal,
    double? targetWeightKg,
    int calorieAdjustment = 0,
  }) {
    final bmrValue = bmr(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );
    final tdeeValue = bmrValue * activity.factor;
    final notes = <CalorieNote>[];
    final proteinRate = proteinPerKgFor(goal);

    double dailyDeficit = 0;
    double eat = tdeeValue;
    bool missingCutInputs = false;
    double? kgToLose;
    double? effectiveTarget;

    switch (goal) {
      case FitnessGoal.maintain:
        eat = tdeeValue;
        dailyDeficit = 0;
      case FitnessGoal.bulk:
        eat = tdeeValue * 1.1;
        dailyDeficit = 0;
      case FitnessGoal.cut:
        // No fixed calorie deficit here — a fat-loss deficit only ever comes
        // from an active diet-strategy plan (see DietStrategyRepository).
        // Absent one, `cut` eats at TDEE just like `maintain`; target weight
        // is kept purely as a stated goal to show progress against.
        eat = tdeeValue;
        dailyDeficit = 0;
        effectiveTarget = targetWeightKg;
        final validCut = effectiveTarget != null && effectiveTarget < weightKg;
        if (!validCut) {
          missingCutInputs = true;
          notes.add(const CalorieNote(CalorieNoteId.missingTargetWeight));
        } else {
          kgToLose = weightKg - effectiveTarget;
        }
    }

    final adj = calorieAdjustment.clamp(0, maxCalorieAdjustment);
    if (adj > 0) {
      eat = (eat - adj).clamp(0.0, double.infinity);
      notes.add(CalorieNote(CalorieNoteId.plateauAdj, {'adj': adj.toString()}));
    }

    final targets = _macrosFor(
      calorieTarget: eat.round(),
      weightKg: weightKg,
      proteinPerKg: proteinRate,
    );

    return CaloriePlan(
      bmr: bmrValue,
      tdee: tdeeValue,
      activityFactor: activity.factor,
      goal: goal,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      sex: sex,
      dailyDeficit: dailyDeficit,
      targets: targets,
      proteinPerKg: proteinRate,
      targetWeightKg: goal == FitnessGoal.cut ? effectiveTarget : null,
      kgToLose: kgToLose,
      calorieAdjustment: adj,
      missingCutInputs: missingCutInputs,
      notes: notes,
    );
  }

  MacroTargets _macrosFor({
    required int calorieTarget,
    required double weightKg,
    required double proteinPerKg,
  }) {
    final proteinG = weightKg * proteinPerKg;
    final fatG = weightKg * fatPerKg;
    final remainingKcal = calorieTarget - proteinG * 4 - fatG * 9;
    final carbG = (remainingKcal / 4).clamp(0, double.infinity);
    return MacroTargets(
      calories: calorieTarget,
      proteinG: _round1(proteinG),
      carbG: _round1(carbG.toDouble()),
      fatG: _round1(fatG),
    );
  }

  static double _round1(double v) => (v * 10).round() / 10;
}
