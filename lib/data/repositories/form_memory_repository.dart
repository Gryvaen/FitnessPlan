import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models.dart';

class MealFormDefaults {
  const MealFormDefaults({
    required this.mealType,
    required this.grams,
  });

  final MealType mealType;
  final double grams;
}

class WeightFormExtras {
  const WeightFormExtras({
    this.bodyFatPct,
    this.exerciseMinutes,
  });

  final double? bodyFatPct;
  final int? exerciseMinutes;
}

/// Remembers last form selections across app restarts.
class FormMemoryRepository {
  FormMemoryRepository(this._prefs);

  static const _mealTypeKey = 'last_meal_type';
  static const _mealGramsKey = 'last_meal_grams';
  static const _bodyFatKey = 'last_body_fat_pct';
  static const _exerciseMinutesKey = 'last_exercise_minutes';
  static const _weightExtrasTouchedKey = 'weight_extras_touched';

  final SharedPreferences _prefs;

  MealFormDefaults loadMealDefaults({
    MealType fallbackMealType = MealType.lunch,
    double fallbackGrams = 100,
  }) {
    final rawType = _prefs.getString(_mealTypeKey);
    var mealType = fallbackMealType;
    if (rawType != null) {
      for (final t in MealType.values) {
        if (t.name == rawType) {
          mealType = t;
          break;
        }
      }
    }
    final grams = _prefs.getDouble(_mealGramsKey) ?? fallbackGrams;
    return MealFormDefaults(mealType: mealType, grams: grams);
  }

  Future<void> saveMealDefaults({
    required MealType mealType,
    required double grams,
  }) async {
    await _prefs.setString(_mealTypeKey, mealType.name);
    await _prefs.setDouble(_mealGramsKey, grams);
  }

  /// Returns last body-fat / exercise choices. Both null when never set or
  /// when the user last chose「不填写」.
  WeightFormExtras loadWeightExtras() {
    return WeightFormExtras(
      bodyFatPct: _prefs.containsKey(_bodyFatKey)
          ? _prefs.getDouble(_bodyFatKey)
          : null,
      exerciseMinutes: _prefs.containsKey(_exerciseMinutesKey)
          ? _prefs.getInt(_exerciseMinutesKey)
          : null,
    );
  }

  bool get hasWeightExtrasMemory =>
      _prefs.getBool(_weightExtrasTouchedKey) ?? false;

  Future<void> saveWeightExtras({
    double? bodyFatPct,
    int? exerciseMinutes,
  }) async {
    await _prefs.setBool(_weightExtrasTouchedKey, true);
    if (bodyFatPct == null) {
      await _prefs.remove(_bodyFatKey);
    } else {
      await _prefs.setDouble(_bodyFatKey, bodyFatPct);
    }
    if (exerciseMinutes == null) {
      await _prefs.remove(_exerciseMinutesKey);
    } else {
      await _prefs.setInt(_exerciseMinutesKey, exerciseMinutes);
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_mealTypeKey),
      _prefs.remove(_mealGramsKey),
      _prefs.remove(_bodyFatKey),
      _prefs.remove(_exerciseMinutesKey),
      _prefs.remove(_weightExtrasTouchedKey),
    ]);
  }
}
