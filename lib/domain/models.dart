enum Sex { male, female }

enum ActivityLevel {
  sedentary(1.2, '久坐'),
  light(1.375, '轻度活动'),
  moderate(1.55, '中度活动'),
  high(1.725, '较高活动'),
  athlete(1.9, '运动员级');

  const ActivityLevel(this.factor, this.label);
  final double factor;
  final String label;
}

enum FitnessGoal {
  cut(-0.20, '减脂'),
  maintain(0.0, '维持'),
  bulk(0.10, '增肌');

  const FitnessGoal(this.calorieAdjust, this.label);
  final double calorieAdjust;
  final String label;
}

enum MealType {
  breakfast('早餐'),
  lunch('午餐'),
  dinner('晚餐'),
  snack('加餐');

  const MealType(this.label);
  final String label;
}

class MacroTargets {
  const MacroTargets({
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final int calories;
  final double proteinG;
  final double carbG;
  final double fatG;

  factory MacroTargets.fromJson(Map<String, dynamic> json) => MacroTargets(
        calories: json['calories'] as int,
        proteinG: (json['proteinG'] as num).toDouble(),
        carbG: (json['carbG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbG': carbG,
        'fatG': fatG,
      };
}

class UserProfile {
  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    required this.targets,
    this.targetWeightKg,
    this.goalWeeks,
    this.weeklyLossKg,
    int calorieAdjustment = 0,
    this.bmr,
    this.tdee,
    this.dailyDeficit,
    bool calorieFloorApplied = false,
    this.adjustedWeeks,
    bool missingCutInputs = false,
    this.calorieStandardSince,
  })  : _calorieAdjustment = calorieAdjustment,
        _calorieFloorApplied = calorieFloorApplied,
        _missingCutInputs = missingCutInputs;

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final FitnessGoal goal;
  final MacroTargets targets;
  final double? targetWeightKg;
  final int? goalWeeks;
  final double? weeklyLossKg;
  final int? _calorieAdjustment;
  final double? bmr;
  final double? tdee;
  final double? dailyDeficit;
  final bool? _calorieFloorApplied;
  final int? adjustedWeeks;
  final bool? _missingCutInputs;
  /// Local calendar day when calorie targets / deficit last changed.
  final DateTime? calorieStandardSince;

  int get calorieAdjustment => _calorieAdjustment ?? 0;
  bool get calorieFloorApplied => _calorieFloorApplied ?? false;
  bool get missingCutInputs => _missingCutInputs ?? false;

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    FitnessGoal? goal,
    MacroTargets? targets,
    double? targetWeightKg,
    int? goalWeeks,
    double? weeklyLossKg,
    int? calorieAdjustment,
    double? bmr,
    double? tdee,
    double? dailyDeficit,
    bool? calorieFloorApplied,
    int? adjustedWeeks,
    bool? missingCutInputs,
    DateTime? calorieStandardSince,
    bool clearTargetWeightKg = false,
    bool clearCalorieStandardSince = false,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      targets: targets ?? this.targets,
      targetWeightKg:
          clearTargetWeightKg ? null : (targetWeightKg ?? this.targetWeightKg),
      goalWeeks: goalWeeks ?? this.goalWeeks,
      weeklyLossKg: weeklyLossKg ?? this.weeklyLossKg,
      calorieAdjustment: calorieAdjustment ?? this.calorieAdjustment,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      dailyDeficit: dailyDeficit ?? this.dailyDeficit,
      calorieFloorApplied: calorieFloorApplied ?? this.calorieFloorApplied,
      adjustedWeeks: adjustedWeeks ?? this.adjustedWeeks,
      missingCutInputs: missingCutInputs ?? this.missingCutInputs,
      calorieStandardSince: clearCalorieStandardSince
          ? null
          : (calorieStandardSince ?? this.calorieStandardSince),
    );
  }

  static DateTime? _dayFromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! String || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _dayToJson(DateTime? day) {
    if (day == null) return null;
    final d = DateTime(day.year, day.month, day.day);
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        sex: Sex.values.byName(json['sex'] as String),
        age: json['age'] as int,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        activity: ActivityLevel.values.byName(json['activity'] as String),
        goal: FitnessGoal.values.byName(json['goal'] as String),
        targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
        targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
        goalWeeks: json['goalWeeks'] as int?,
        weeklyLossKg: (json['weeklyLossKg'] as num?)?.toDouble(),
        calorieAdjustment: json['calorieAdjustment'] as int? ?? 0,
        bmr: (json['bmr'] as num?)?.toDouble(),
        tdee: (json['tdee'] as num?)?.toDouble(),
        dailyDeficit: (json['dailyDeficit'] as num?)?.toDouble(),
        calorieFloorApplied: json['calorieFloorApplied'] as bool? ?? false,
        adjustedWeeks: json['adjustedWeeks'] as int?,
        missingCutInputs: json['missingCutInputs'] as bool? ?? false,
        calorieStandardSince: _dayFromJson(json['calorieStandardSince']),
      );

  Map<String, dynamic> toJson() => {
        'sex': sex.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activity': activity.name,
        'goal': goal.name,
        'targets': targets.toJson(),
        'targetWeightKg': targetWeightKg,
        'goalWeeks': goalWeeks,
        'weeklyLossKg': weeklyLossKg,
        'calorieAdjustment': calorieAdjustment,
        'bmr': bmr,
        'tdee': tdee,
        'dailyDeficit': dailyDeficit,
        'calorieFloorApplied': calorieFloorApplied,
        'adjustedWeeks': adjustedWeeks,
        'missingCutInputs': missingCutInputs,
        'calorieStandardSince': _dayToJson(calorieStandardSince),
      };
}

class MacroIntake {
  const MacroIntake({
    this.calories = 0,
    this.proteinG = 0,
    this.carbG = 0,
    this.fatG = 0,
  });

  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;

  MacroIntake operator +(MacroIntake other) => MacroIntake(
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        carbG: carbG + other.carbG,
        fatG: fatG + other.fatG,
      );

  static MacroIntake fromGrams({
    required double grams,
    required double kcalPer100,
    required double proteinPer100,
    required double carbPer100,
    required double fatPer100,
  }) {
    final factor = grams / 100.0;
    return MacroIntake(
      calories: kcalPer100 * factor,
      proteinG: proteinPer100 * factor,
      carbG: carbPer100 * factor,
      fatG: fatPer100 * factor,
    );
  }
}
