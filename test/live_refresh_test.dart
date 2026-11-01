import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/food_repository.dart';
import 'package:diet/data/repositories/meal_preset_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/day_marker.dart';
import 'package:diet/domain/models.dart';
import 'package:drift/drift.dart' show TableUpdate;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Streams behind screens that used to need a manual invalidate (or a
// re-entry) to show edits made elsewhere.

Future<int> _food(AppDatabase db, String name) => db
    .into(db.foodItems)
    .insert(
      FoodItemsCompanion.insert(
        name: name,
        category: '谷物',
        kcalPer100: 100,
        proteinPer100: 5,
        carbPer100: 10,
        fatPer100: 2,
      ),
    );

/// Waits until [stream] emits a value matching [matcher].
Future<T> _until<T>(Stream<T> stream, bool Function(T) matcher) =>
    stream.firstWhere(matcher).timeout(const Duration(seconds: 5));

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('preset list follows create and clear-all', () async {
    final repo = MealPresetRepository(db, MealRepository(db));
    final values = <List<MealPreset>>[];
    final sub = repo.watchPresets().listen(values.add);
    addTearDown(sub.cancel);

    await db
        .into(db.mealPresets)
        .insert(
          MealPresetsCompanion.insert(name: '早餐', createdAt: DateTime.now()),
        );
    await _until(
      repo.watchPresets(),
      (presets) => presets.map((p) => p.name).contains('早餐'),
    );
    await repo.clearAll();
    expect(await _until(repo.watchPresets(), (p) => p.isEmpty), isEmpty);
  });

  test('favorites list follows toggles from any page', () async {
    final repo = FoodRepository(db);
    final id = await _food(db, '燕麦');
    expect(await repo.watchFavorites().first, isEmpty);
    await repo.toggleFavorite(id);
    await _until(
      repo.watchFavorites(),
      (foods) => foods.map((f) => f.id).contains(id),
    );
    await repo.clearFavorites();
    expect(await _until(repo.watchFavorites(), (l) => l.isEmpty), isEmpty);
  });

  test('recent foods follow logging and hiding', () async {
    final foods = FoodRepository(db);
    final meals = MealRepository(db);
    final id = await _food(db, '燕麦');
    final food = (await foods.byId(id))!;
    expect(await foods.watchRecentFoods().first, isEmpty);

    await meals.add(
      date: DateTime.now(),
      mealType: MealType.breakfast,
      food: food,
      grams: 100,
    );
    await _until(
      foods.watchRecentFoods(),
      (list) => list.map((f) => f.id).contains(id),
    );
    await foods.hideFromRecent(id);
    expect(await _until(foods.watchRecentFoods(), (l) => l.isEmpty), isEmpty);
  });

  test('day workout re-emits when only exercise unit changes', () async {
    final repo = WorkoutRepository(db);
    final today = CalendarDay.todayLocal();
    final exerciseId = await repo.addCustomExercise(
      name: '平板支撑',
      unit: ExerciseUnit.reps,
      category: 'core',
    );
    await repo.addQuickDayItem(
      day: today,
      exerciseId: exerciseId,
      targetSets: 3,
      targetReps: 30,
    );

    final snapshots = <DayWorkoutSnapshot>[];
    final sub = repo.watchDayWorkout(today).listen(snapshots.add);
    addTearDown(sub.cancel);
    await _until(repo.watchDayWorkout(today), (s) => s.groups.isNotEmpty);

    await repo.updateExercise(
      id: exerciseId,
      name: '平板支撑',
      unit: ExerciseUnit.seconds,
      category: 'core',
    );
    final updated = await _until(
      repo.watchDayWorkout(today),
      (s) => s.groups
          .expand((g) => g.items)
          .any((i) => i.unit == ExerciseUnit.seconds),
    );
    expect(updated.groups.single.items.single.unit, ExerciseUnit.seconds);
    // The long-lived subscription saw the change too, not just new ones.
    await pumpEventQueue();
    expect(
      snapshots.last.groups.single.items.single.unit,
      ExerciseUnit.seconds,
    );
  });

  test('day marker settings re-emit on snapshot-only writes', () async {
    final repo = DayMarkerRepository(db);
    final emissions = <DayMarkerSettings?>[];
    final sub = repo
        .watchSettingsForDay(CalendarDay.todayLocal())
        .listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    final before = emissions.length;
    // A past day's pause state lives on its frozen snapshot row.
    db.notifyUpdates({TableUpdate.onTable(db.dailyNutritionTargets)});
    await pumpEventQueue();
    expect(emissions.length, greaterThan(before));
  });
}
