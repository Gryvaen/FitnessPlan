import 'models.dart';

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
    required this.safetyApplied,
    required this.proteinPerKg,
    this.targetWeightKg,
    this.goalWeeks,
    this.weeklyLossKg,
    this.requestedWeeklyLossKg,
    this.kgToLose,
    this.requestedDeficit,
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
  final bool safetyApplied;
  final double proteinPerKg;
  final double? targetWeightKg;
  final int? goalWeeks;
  final double? weeklyLossKg;
  final double? requestedWeeklyLossKg;
  final double? kgToLose;
  final double? requestedDeficit;
  final int calorieAdjustment;
  final bool missingCutInputs;
  final List<String> notes;

  String get bmrFormulaLabel => sex == Sex.male
      ? '男：10×体重 + 6.25×身高 − 5×年龄 + 5'
      : '女：10×体重 + 6.25×身高 − 5×年龄 − 161';

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
  static const maxDailyDeficit = 1000.0;
  static const minWeeklyLoss = 0.3;
  static const maxWeeklyLoss = 0.8;
  static const defaultWeeklyLoss = 0.5;
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
    return bmr(
          sex: sex,
          weightKg: weightKg,
          heightCm: heightCm,
          age: age,
        ) *
        activity.factor;
  }

  /// Protein g/kg by goal only.
  static double proteinPerKgFor(FitnessGoal goal) {
    if (goal == FitnessGoal.bulk) return 2.2;
    return 2.0;
  }

  /// Clamp weekly loss; returns (effectiveRate, wasClamped).
  static (double, bool) clampWeeklyLoss(double requested) {
    if (requested > maxWeeklyLoss) {
      return (maxWeeklyLoss, true);
    }
    if (requested < minWeeklyLoss) {
      return (minWeeklyLoss, true);
    }
    return (requested, false);
  }

  CaloriePlan plan({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activity,
    required FitnessGoal goal,
    double? targetWeightKg,
    double? weeklyLossKg,
    int? goalWeeks,
    int calorieAdjustment = 0,
  }) {
    final bmrValue = bmr(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );
    final tdeeValue = bmrValue * activity.factor;
    final notes = <String>[];
    final proteinRate = proteinPerKgFor(goal);

    double dailyDeficit = 0;
    double eat = tdeeValue;
    bool safetyApplied = false;
    bool missingCutInputs = false;
    double? kgToLose;
    double? requestedDeficit;
    double? effectiveWeekly;
    double? requestedWeekly;
    double? effectiveTarget;
    int? estimatedWeeks;

    switch (goal) {
      case FitnessGoal.maintain:
        eat = tdeeValue;
        dailyDeficit = 0;
      case FitnessGoal.bulk:
        eat = tdeeValue * 1.1;
        dailyDeficit = 0;
      case FitnessGoal.cut:
        effectiveTarget = targetWeightKg;
        requestedWeekly = weeklyLossKg;
        if (requestedWeekly == null &&
            goalWeeks != null &&
            effectiveTarget != null &&
            effectiveTarget < weightKg) {
          requestedWeekly = (weightKg - effectiveTarget) / goalWeeks;
        }
        requestedWeekly ??= defaultWeeklyLoss;

        final validCut =
            effectiveTarget != null && effectiveTarget < weightKg;
        if (!validCut) {
          missingCutInputs = true;
          eat = tdeeValue * 0.8;
          dailyDeficit = tdeeValue - eat;
          notes.add(
            '未填写有效的目标体重，暂按维持消耗的 80% 估算。'
            '请在「我的」中补全后重新计算。',
          );
        } else {
          final lose = weightKg - effectiveTarget;
          kgToLose = lose;

          final rawWeekly = requestedWeekly;
          final clamped = clampWeeklyLoss(requestedWeekly);
          final intendedWeekly = clamped.$1;
          final rateClamped = clamped.$2;
          requestedWeekly = intendedWeekly;

          if (rateClamped && rawWeekly > maxWeeklyLoss) {
            safetyApplied = true;
            notes.add(
              '不建议超过 1 kg/周（推荐 0.3–0.8 kg/周）。'
              '已自动调整为 ${maxWeeklyLoss.toStringAsFixed(1)} kg/周。',
            );
          } else if (rateClamped && rawWeekly < minWeeklyLoss) {
            notes.add(
              '每周降重已调整为不低于 ${minWeeklyLoss.toStringAsFixed(1)} kg/周。',
            );
          }

          var deficit = intendedWeekly * kcalPerKgFat / 7;
          requestedDeficit = intendedWeekly * kcalPerKgFat / 7;

          if (deficit > maxDailyDeficit) {
            deficit = maxDailyDeficit;
            safetyApplied = true;
          }

          eat = tdeeValue - deficit;
          dailyDeficit = deficit;

          if (dailyDeficit > 0) {
            effectiveWeekly = dailyDeficit * 7 / kcalPerKgFat;
            estimatedWeeks = (lose / effectiveWeekly).ceil().clamp(1, 520);
          } else {
            effectiveWeekly = 0;
            estimatedWeeks = null;
          }

          final rateWasLimited = safetyApplied &&
              dailyDeficit > 0 &&
              (effectiveWeekly < intendedWeekly - 0.001);
          if (rateWasLimited) {
            if (!notes.any((n) => n.contains('日缺口上限'))) {
              notes.add(
                '已按日缺口上限调整：不超过 ${maxDailyDeficit.toInt()} kcal/日。'
                '实际约 ${effectiveWeekly.toStringAsFixed(2)} kg/周，'
                '大约需要 $estimatedWeeks 周。',
              );
            }
          } else if (!notes.any((n) => n.contains('不建议超过'))) {
            notes.add(
              '按约 ${kcalPerKgFat.toInt()} kcal ≈ 1 kg 脂肪、'
              '每周 ${effectiveWeekly.toStringAsFixed(1)} kg 估算。'
              '预计约 $estimatedWeeks 周。',
            );
          } else {
            notes.add('预计约 $estimatedWeeks 周完成。');
          }
        }
    }

    final adj = calorieAdjustment.clamp(0, maxCalorieAdjustment);
    if (adj > 0) {
      eat = (eat - adj).clamp(0.0, double.infinity);
      notes.add('已应用平台期调整：额外减少 $adj kcal/日。');
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
      safetyApplied: safetyApplied,
      proteinPerKg: proteinRate,
      targetWeightKg: goal == FitnessGoal.cut ? effectiveTarget : null,
      goalWeeks: goal == FitnessGoal.cut ? estimatedWeeks : null,
      weeklyLossKg: goal == FitnessGoal.cut ? effectiveWeekly : null,
      requestedWeeklyLossKg:
          goal == FitnessGoal.cut ? requestedWeekly : null,
      kgToLose: kgToLose,
      requestedDeficit: requestedDeficit,
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
