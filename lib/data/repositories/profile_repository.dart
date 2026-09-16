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

  // Only a goal switch resets the "new standard" clock here. Calorie/macro
  // numbers drift on their own with weight/height/age (see
  // `recalculateForWeight`) and must not retrigger it; a diet-strategy
  // change re-stamps separately via `markStandardChanged`.
  static bool _calorieStandardChanged(UserProfile old, UserProfile next) =>
      old.goal != next.goal;

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

  /// Re-stamps the "new standard" marker to [since] (day-only) when a diet
  /// strategy change makes it the effective date. No-ops when there's no
  /// profile yet or the stamp is already there. Returns the updated profile
  /// so callers can refresh dependent state, or null when nothing changed.
  Future<UserProfile?> markStandardChanged(DateTime since) async {
    final profile = load();
    if (profile == null) return null;
    final day = DateTime(since.year, since.month, since.day);
    if (profile.calorieStandardSince == day) return null;
    final updated = profile.copyWith(calorieStandardSince: day);
    await save(updated);
    return updated;
  }
}
