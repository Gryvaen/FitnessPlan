import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';

class ProfileRepository {
  ProfileRepository(this._prefs);

  static const _key = 'user_profile';
  static const _nameKey = 'user_name';
  final SharedPreferences _prefs;
  final _calc = const CalorieCalculator();

  UserProfile? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final profile = UserProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );

      final needsRebuild = profile.bmr == null || profile.tdee == null;
      if (needsRebuild) {
        return _profileFromPlan(
          plan: buildPlan(profile),
          activity: profile.activity,
          calorieAdjustment: profile.calorieAdjustment,
          calorieStandardSince: profile.calorieStandardSince,
        );
      }
      return profile;
    } catch (_) {
      // Corrupted JSON: treat as no profile so onboarding can recover.
      return null;
    }
  }

  Future<void> save(UserProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static bool _calorieStandardChanged(UserProfile old, UserProfile next) {
    // Switching goal resets the cultivation / deficit "new standard" clock
    // even when calorie numbers happen to match.
    if (old.goal != next.goal) return true;
    if (old.targets.calories != next.targets.calories) return true;
    final oldDef = (old.dailyDeficit ?? 0).round();
    final nextDef = (next.dailyDeficit ?? 0).round();
    return oldDef != nextDef;
  }

  static DateTime _todayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<UserProfile> saveFromInputs({
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required FitnessGoal goal,
    double? targetWeightKg,
    int calorieAdjustment = 0,
  }) async {
    final old = load();
    final plan = _calc.plan(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activity: activity,
      goal: goal,
      targetWeightKg: targetWeightKg,
      calorieAdjustment: calorieAdjustment,
    );
    var profile = _profileFromPlan(
      plan: plan,
      activity: activity,
      calorieAdjustment: calorieAdjustment,
    );
    if (old != null && _calorieStandardChanged(old, profile)) {
      profile = profile.copyWith(calorieStandardSince: _todayLocal());
    } else {
      profile = profile.copyWith(
        calorieStandardSince: old?.calorieStandardSince,
      );
    }
    await save(profile);
    return profile;
  }

  Future<UserProfile> recalculateForWeight(
    UserProfile current,
    double newWeightKg,
  ) async {
    return saveFromInputs(
      sex: current.sex,
      age: current.age,
      heightCm: current.heightCm,
      weightKg: newWeightKg,
      activity: current.activity,
      goal: current.goal,
      targetWeightKg: current.targetWeightKg,
      calorieAdjustment: current.calorieAdjustment,
    );
  }

  Future<UserProfile> applyCalorieAdjustment(
    UserProfile current,
    int additionalKcal,
  ) async {
    final next = (current.calorieAdjustment + additionalKcal).clamp(
      0,
      CalorieCalculator.maxCalorieAdjustment,
    );
    return saveFromInputs(
      sex: current.sex,
      age: current.age,
      heightCm: current.heightCm,
      weightKg: current.weightKg,
      activity: current.activity,
      goal: current.goal,
      targetWeightKg: current.targetWeightKg,
      calorieAdjustment: next,
    );
  }

  UserProfile _profileFromPlan({
    required CaloriePlan plan,
    required ActivityLevel activity,
    int calorieAdjustment = 0,
    DateTime? calorieStandardSince,
  }) {
    return UserProfile(
      sex: plan.sex,
      age: plan.age,
      heightCm: plan.heightCm,
      weightKg: plan.weightKg,
      activity: activity,
      goal: plan.goal,
      targets: plan.targets,
      targetWeightKg: plan.targetWeightKg,
      calorieAdjustment: calorieAdjustment,
      bmr: plan.bmr,
      tdee: plan.tdee,
      dailyDeficit: plan.dailyDeficit,
      calorieStandardSince: calorieStandardSince,
    );
  }

  CaloriePlan buildPlan(UserProfile profile) {
    return _calc.plan(
      sex: profile.sex,
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      activity: profile.activity,
      goal: profile.goal,
      targetWeightKg: profile.targetWeightKg,
      calorieAdjustment: profile.calorieAdjustment,
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    await _prefs.remove(_nameKey);
  }
}
