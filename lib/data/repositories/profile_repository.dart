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
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(UserProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<UserProfile> saveFromInputs({
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required FitnessGoal goal,
  }) async {
    final targets = _calc.calculate(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activity: activity,
      goal: goal,
    );
    final profile = UserProfile(
      sex: sex,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      activity: activity,
      goal: goal,
      targets: targets,
    );
    await save(profile);
    return profile;
  }

  Future<void> clear() async => _prefs.remove(_key);
}
