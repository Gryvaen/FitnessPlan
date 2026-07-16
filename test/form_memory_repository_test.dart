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

  test('weight extras remember explicit 不填写 as null', () async {
    await repo.saveWeightExtras(bodyFatPct: 20, exerciseMinutes: 30);
    await repo.saveWeightExtras(bodyFatPct: null, exerciseMinutes: null);
    expect(repo.hasWeightExtrasMemory, isTrue);
    final extras = repo.loadWeightExtras();
    expect(extras.bodyFatPct, isNull);
    expect(extras.exerciseMinutes, isNull);
  });
}
