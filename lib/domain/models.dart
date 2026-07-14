enum Sex { male, female }

enum ActivityLevel {
  sedentary(1.2, '久坐'),
  light(1.375, '轻度活动'),
  moderate(1.55, '中度活动'),
  high(1.725, '较高活动');

  const ActivityLevel(this.factor, this.label);
  final double factor;
  final String label;
}

enum FitnessGoal {
  cut(-0.20, '减脂', 2.0),
  maintain(0.0, '维持', 2.0),
  bulk(0.10, '增肌', 2.2);

  const FitnessGoal(this.calorieAdjust, this.label, this.proteinPerKg);
  final double calorieAdjust;
  final String label;
  final double proteinPerKg;
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
  });

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final FitnessGoal goal;
  final MacroTargets targets;

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    FitnessGoal? goal,
    MacroTargets? targets,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      targets: targets ?? this.targets,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        sex: Sex.values.byName(json['sex'] as String),
        age: json['age'] as int,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        activity: ActivityLevel.values.byName(json['activity'] as String),
        goal: FitnessGoal.values.byName(json['goal'] as String),
        targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'sex': sex.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activity': activity.name,
        'goal': goal.name,
        'targets': targets.toJson(),
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
