import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';

class MealFormDefaults {
  const MealFormDefaults({required this.mealType, required this.grams});

  final MealType mealType;
  final double grams;
}

class WeightFormExtras {
  const WeightFormExtras({this.bodyFatPct, this.exerciseMinutes});

  final double? bodyFatPct;
  final int? exerciseMinutes;
}

/// Last target-set / target-value picks from the plan and quick-add forms.
class WorkoutTargetMemory {
  const WorkoutTargetMemory({
    this.sets = 3,
    this.reps = 12,
    this.seconds = 30,
    this.minutes = 20,
  });

  final int sets;
  final int reps;
  final int seconds;
  final int minutes;

  int valueFor(ExerciseUnit unit, {String? category}) {
    if (unit == ExerciseUnit.reps) return reps;
    if (category == 'cardio') return minutes;
    return seconds;
  }
}

/// Remembers last form selections across app restarts.
class FormMemoryRepository {
  FormMemoryRepository(this._prefs);

  static const _mealTypeKey = 'last_meal_type';
  static const _mealGramsKey = 'last_meal_grams';
  static const _bodyFatKey = 'last_body_fat_pct';
  static const _exerciseMinutesKey = 'last_exercise_minutes';
  static const _weightExtrasTouchedKey = 'weight_extras_touched';
  static const _exerciseCategoryKey = 'last_exercise_category';
  static const _targetSetsKey = 'last_target_sets';
  static const _targetRepsKey = 'last_target_reps';
  static const _targetSecondsKey = 'last_target_seconds';
  static const _targetMinutesKey = 'last_target_minutes';

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

  String loadExerciseCategory({String fallback = 'chest'}) {
    final raw = _prefs.getString(_exerciseCategoryKey);
    if (raw != null && kExerciseCategoryOrder.contains(raw)) return raw;
    return fallback;
  }

  Future<void> saveExerciseCategory(String category) async {
    if (!kExerciseCategoryOrder.contains(category)) return;
    await _prefs.setString(_exerciseCategoryKey, category);
  }

  WorkoutTargetMemory loadWorkoutTargets() {
    return WorkoutTargetMemory(
      sets: _prefs.getInt(_targetSetsKey) ?? 3,
      reps: _prefs.getInt(_targetRepsKey) ?? 12,
      seconds: _prefs.getInt(_targetSecondsKey) ?? 30,
      minutes: _prefs.getInt(_targetMinutesKey) ?? 20,
    );
  }

  Future<void> saveWorkoutTargets({
    required int sets,
    required int value,
    required ExerciseUnit unit,
    String? category,
  }) async {
    await _prefs.setInt(_targetSetsKey, sets);
    if (unit == ExerciseUnit.reps) {
      await _prefs.setInt(_targetRepsKey, value);
    } else if (category == 'cardio') {
      await _prefs.setInt(_targetMinutesKey, value);
    } else {
      await _prefs.setInt(_targetSecondsKey, value);
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_mealTypeKey),
      _prefs.remove(_mealGramsKey),
      _prefs.remove(_bodyFatKey),
      _prefs.remove(_exerciseMinutesKey),
      _prefs.remove(_weightExtrasTouchedKey),
      _prefs.remove(_exerciseCategoryKey),
      _prefs.remove(_targetSetsKey),
      _prefs.remove(_targetRepsKey),
      _prefs.remove(_targetSecondsKey),
      _prefs.remove(_targetMinutesKey),
    ]);
  }
}
