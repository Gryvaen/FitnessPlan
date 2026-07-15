import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';

class ProfileRepository {
  ProfileRepository(this._prefs);

  static const _key = 'user_profile';
  final SharedPreferences _prefs;
  final _calc = const CalorieCalculator();

  UserProfile? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    var profile =
        UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    profile = _migrateWeeklyLoss(profile);

    final needsRebuild = profile.bmr == null ||
        profile.tdee == null ||
        (profile.weeklyLossKg == null && profile.goal == FitnessGoal.cut);
    if (needsRebuild) {
      return _profileFromPlan(
        plan: buildPlan(profile),
        activity: profile.activity,
        calorieAdjustment: profile.calorieAdjustment,
        calorieStandardSince: profile.calorieStandardSince,
      );
    }
    return profile;
  }

  UserProfile _migrateWeeklyLoss(UserProfile profile) {
    if (profile.weeklyLossKg != null) return profile;
    if (profile.goal == FitnessGoal.cut &&
        profile.targetWeightKg != null &&
        profile.goalWeeks != null &&
        profile.goalWeeks! >= 1 &&
        profile.targetWeightKg! < profile.weightKg) {
      final raw =
          (profile.weightKg - profile.targetWeightKg!) / profile.goalWeeks!;
      final clamped = CalorieCalculator.clampWeeklyLoss(raw).$1;
      return profile.copyWith(weeklyLossKg: clamped);
    }
    if (profile.goal == FitnessGoal.cut) {
      return profile.copyWith(weeklyLossKg: CalorieCalculator.defaultWeeklyLoss);
    }
    return profile;
  }

  Future<void> save(UserProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static bool _calorieStandardChanged(UserProfile old, UserProfile next) {
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
    double? weeklyLossKg,
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
      weeklyLossKg: weeklyLossKg,
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
      weeklyLossKg: current.weeklyLossKg,
      calorieAdjustment: current.calorieAdjustment,
    );
  }

  Future<UserProfile> applyCalorieAdjustment(
    UserProfile current,
    int additionalKcal,
  ) async {
    final next = (current.calorieAdjustment + additionalKcal)
        .clamp(0, CalorieCalculator.maxCalorieAdjustment);
    return saveFromInputs(
      sex: current.sex,
      age: current.age,
      heightCm: current.heightCm,
      weightKg: current.weightKg,
      activity: current.activity,
      goal: current.goal,
      targetWeightKg: current.targetWeightKg,
      weeklyLossKg: current.weeklyLossKg,
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
      goalWeeks: plan.goalWeeks,
      weeklyLossKg: plan.requestedWeeklyLossKg ?? plan.weeklyLossKg,
      calorieAdjustment: calorieAdjustment,
      bmr: plan.bmr,
      tdee: plan.tdee,
      dailyDeficit: plan.dailyDeficit,
      calorieFloorApplied: plan.safetyApplied,
      adjustedWeeks: plan.adjustedWeeks,
      missingCutInputs: plan.missingCutInputs,
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
      weeklyLossKg: profile.weeklyLossKg,
      goalWeeks: profile.goalWeeks,
      calorieAdjustment: profile.calorieAdjustment,
    );
  }

  Future<void> clear() async => _prefs.remove(_key);
}
