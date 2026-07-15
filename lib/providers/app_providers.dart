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
    // Always hydrate from prefs so new fields get defaulted / migrated.
    return ref.read(profileRepositoryProvider).load();
  }

  Future<UserProfile> save({
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required FitnessGoal goal,
    double? targetWeightKg,
    double? weeklyLossKg,
    int? calorieAdjustment,
  }) async {
    final existing = state;
    final profile = await ref.read(profileRepositoryProvider).saveFromInputs(
          sex: sex,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
          activity: activity,
          goal: goal,
          targetWeightKg: targetWeightKg,
          weeklyLossKg: weeklyLossKg,
          calorieAdjustment:
              calorieAdjustment ?? existing?.calorieAdjustment ?? 0,
        );
    state = profile;
    return profile;
  }

  Future<UserProfile?> applyLatestWeight(double weightKg) async {
    final current = state;
    if (current == null) return null;
    final profile = await ref
        .read(profileRepositoryProvider)
        .recalculateForWeight(current, weightKg);
    state = profile;
    return profile;
  }

  Future<UserProfile?> applyPlateauCalorieCut({int kcal = 100}) async {
    final current = state;
    if (current == null) return null;
    final profile = await ref
        .read(profileRepositoryProvider)
        .applyCalorieAdjustment(current, kcal);
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

  void goToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }

  /// Shift by [delta] days, clamped to [earliest]..today (local calendar).
  void shiftDay(int delta, {DateTime? earliest}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final min = earliest ?? DateTime(today.year - 1, today.month, today.day);
    var next = state.add(Duration(days: delta));
    next = DateTime(next.year, next.month, next.day);
    if (next.isBefore(min)) next = min;
    if (next.isAfter(today)) next = today;
    state = next;
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
  await ref.watch(foodRepositoryProvider).syncSeedFromAsset();
});
