import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diet/data/repositories/form_memory_repository.dart';
import 'package:diet/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FormMemoryRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = FormMemoryRepository(prefs);
  });

  test('meal defaults fall back when never saved', () {
    final defaults = repo.loadMealDefaults();
    expect(defaults.mealType, MealType.lunch);
    expect(defaults.grams, 100);
  });

  test('meal defaults round-trip', () async {
    await repo.saveMealDefaults(mealType: MealType.dinner, grams: 200);
    final defaults = repo.loadMealDefaults();
    expect(defaults.mealType, MealType.dinner);
    expect(defaults.grams, 200);
  });

  test('invalid meal type falls back', () async {
    SharedPreferences.setMockInitialValues({
      'last_meal_type': 'not_a_meal',
      'last_meal_grams': 150.0,
    });
    final prefs = await SharedPreferences.getInstance();
    repo = FormMemoryRepository(prefs);
    final defaults = repo.loadMealDefaults();
    expect(defaults.mealType, MealType.lunch);
    expect(defaults.grams, 150);
  });

  test('weight extras are null when never saved', () {
    expect(repo.hasWeightExtrasMemory, isFalse);
    final extras = repo.loadWeightExtras();
    expect(extras.bodyFatPct, isNull);
    expect(extras.exerciseMinutes, isNull);
  });

  test('weight extras round-trip with values', () async {
    await repo.saveWeightExtras(bodyFatPct: 18.5, exerciseMinutes: 45);
    expect(repo.hasWeightExtrasMemory, isTrue);
    final extras = repo.loadWeightExtras();
    expect(extras.bodyFatPct, 18.5);
    expect(extras.exerciseMinutes, 45);
  });

  test('exercise category and workout targets round-trip', () async {
    expect(repo.loadExerciseCategory(), 'chest');
    final fresh = repo.loadWorkoutTargets();
    expect(fresh.sets, 3);
    expect(fresh.reps, 12);
    expect(fresh.valueFor(ExerciseUnit.seconds), 30);
    expect(fresh.valueFor(ExerciseUnit.seconds, category: 'cardio'), 20);

    await repo.saveExerciseCategory('legs');
    await repo.saveWorkoutTargets(sets: 5, value: 8, unit: ExerciseUnit.reps);
    await repo.saveWorkoutTargets(
      sets: 4,
      value: 45,
      unit: ExerciseUnit.seconds,
    );
    await repo.saveWorkoutTargets(
      sets: 4,
      value: 30,
      unit: ExerciseUnit.seconds,
      category: 'cardio',
    );

    expect(repo.loadExerciseCategory(), 'legs');
    final saved = repo.loadWorkoutTargets();
    expect(saved.sets, 4);
    expect(saved.reps, 8);
    expect(saved.seconds, 45);
    expect(saved.minutes, 30);
    expect(saved.valueFor(ExerciseUnit.reps), 8);
    expect(saved.valueFor(ExerciseUnit.seconds, category: 'cardio'), 30);

    await repo.saveExerciseCategory('not-a-category');
    expect(repo.loadExerciseCategory(), 'legs');

    await repo.clear();
    expect(repo.loadExerciseCategory(), 'chest');
    expect(repo.loadWorkoutTargets().sets, 3);
    expect(repo.loadWorkoutTargets().reps, 12);
  });

  test('weight extras remember explicit 不填写 as null', () async {
    await repo.saveWeightExtras(bodyFatPct: 20, exerciseMinutes: 30);
    await repo.saveWeightExtras(bodyFatPct: null, exerciseMinutes: null);
    expect(repo.hasWeightExtrasMemory, isTrue);
    final extras = repo.loadWeightExtras();
    expect(extras.bodyFatPct, isNull);
    expect(extras.exerciseMinutes, isNull);
  });
}
