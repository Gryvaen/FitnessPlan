import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/meal_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/weight_repository.dart';
import '../domain/models.dart';

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

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(ref.watch(databaseProvider));
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(databaseProvider));
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository(ref.watch(databaseProvider));
});

final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    return ref.read(profileRepositoryProvider).load();
  }

  Future<UserProfile> save({
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required FitnessGoal goal,
  }) async {
    final profile = await ref.read(profileRepositoryProvider).saveFromInputs(
          sex: sex,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
          activity: activity,
          goal: goal,
        );
    state = profile;
    return profile;
  }

  void reload() {
    state = ref.read(profileRepositoryProvider).load();
  }
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime>(
  SelectedDayNotifier.new,
);

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDay(DateTime day) {
    state = DateTime(day.year, day.month, day.day);
  }
}

final todayMealsProvider = StreamProvider<List<MealEntry>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(mealRepositoryProvider).watchForDay(day);
});

final todayIntakeProvider = Provider<MacroIntake>((ref) {
  final meals = ref.watch(todayMealsProvider).value ?? const [];
  return meals.fold<MacroIntake>(
    const MacroIntake(),
    (sum, e) =>
        sum +
        MacroIntake(
          calories: e.calories,
          proteinG: e.proteinG,
          carbG: e.carbG,
          fatG: e.fatG,
        ),
  );
});

final weightLogsProvider = StreamProvider<List<WeightLog>>((ref) {
  return ref.watch(weightRepositoryProvider).watchAll();
});

final foodsSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(foodRepositoryProvider).seedFromAssetIfNeeded();
});
