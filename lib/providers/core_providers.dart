import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/form_memory_repository.dart';
import '../data/repositories/meal_preset_repository.dart';
import '../data/repositories/meal_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/water_repository.dart';
import '../data/repositories/weight_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(sharedPreferencesProvider));
});

final formMemoryRepositoryProvider = Provider<FormMemoryRepository>((ref) {
  return FormMemoryRepository(ref.watch(sharedPreferencesProvider));
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(ref.watch(databaseProvider));
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(databaseProvider));
});

final mealPresetRepositoryProvider = Provider<MealPresetRepository>((ref) {
  return MealPresetRepository(
    ref.watch(databaseProvider),
    ref.watch(mealRepositoryProvider),
  );
});

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(
    ref.watch(databaseProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository(ref.watch(databaseProvider));
});
