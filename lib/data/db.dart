import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'db.g.dart';

@DriftDatabase(
  tables: [
    FoodItems,
    FoodServings,
    FavoriteFoods,
    WeightLogs,
    MealEntries,
    MealPresets,
    MealPresetItems,
    WaterLogs,
    StepLogs,
    AppMeta,
    Exercises,
    WorkoutPlans,
    WorkoutPlanItems,
    DayWorkouts,
    DayWorkoutItems,
    WorkoutSetLogs,
    DailyNotes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedBuiltinExercises();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(weightLogs, weightLogs.bodyFatPct);
          }
          if (from < 3) {
            await m.addColumn(weightLogs, weightLogs.exerciseMinutes);
            // v2 had minutes_per_session; copy into daily exercise_minutes.
            if (from >= 2) {
              await customStatement(
                'UPDATE weight_logs SET exercise_minutes = minutes_per_session '
                'WHERE exercise_minutes IS NULL AND minutes_per_session IS NOT NULL',
              );
            }
          }
          if (from < 4) {
            // Keep lowest id per duplicate name before unique index.
            await customStatement('''
DELETE FROM food_items
WHERE id NOT IN (
  SELECT MIN(id) FROM food_items GROUP BY name
)
''');
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS food_items_name_unique '
              'ON food_items (name)',
            );
            await m.createTable(appMeta);
          }
          if (from < 5) {
            await m.createTable(favoriteFoods);
          }
          if (from < 6) {
            await m.addColumn(foodItems, foodItems.alcoholPer100);
          }
          if (from < 7) {
            await m.addColumn(foodItems, foodItems.isCustom);
            await m.createTable(foodServings);
            await m.createTable(mealPresets);
            await m.createTable(mealPresetItems);
            await m.createTable(waterLogs);
          }
          if (from < 8) {
            await m.addColumn(mealEntries, mealEntries.alcoholG);
          }
          if (from < 9) {
            await m.createTable(exercises);
            await m.createTable(workoutPlans);
            await m.createTable(workoutPlanItems);
            await m.createTable(dayWorkouts);
            await m.createTable(dayWorkoutItems);
            await m.createTable(workoutSetLogs);
            await seedBuiltinExercises();
          }
          if (from < 10) {
            await m.createTable(dailyNotes);
          }
          if (from < 11) {
            await m.addColumn(exercises, exercises.category);
            await seedBuiltinExercises();
          }
          if (from < 12) {
            await customStatement(
              "UPDATE exercises SET category = 'shoulders' "
              "WHERE category = 'shoulders_arms'",
            );
            await customStatement(
              "UPDATE exercises SET category = 'core' "
              "WHERE category IN ('core_timed', 'other', 'custom')",
            );
            await seedBuiltinExercises();
          }
          if (from < 13) {
            await customStatement('DELETE FROM exercises WHERE is_custom = 0');
          }
          if (from < 14) {
            await m.createTable(stepLogs);
          }
          if (from < 15) {
            // Drop UNIQUE(date) so a day can hold multiple plans.
            await customStatement('''
CREATE TABLE day_workouts_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  plan_id INTEGER NULL,
  plan_name TEXT NULL
)
''');
            await customStatement(
              'INSERT INTO day_workouts_new (id, date, plan_id, plan_name) '
              'SELECT id, date, plan_id, plan_name FROM day_workouts',
            );
            await customStatement('DROP TABLE day_workouts');
            await customStatement(
              'ALTER TABLE day_workouts_new RENAME TO day_workouts',
            );
          }
          if (from < 16) {
            await m.addColumn(foodItems, foodItems.fiberPer100);
            await m.addColumn(foodItems, foodItems.sodiumMgPer100);
            await m.addColumn(foodItems, foodItems.sugarPer100);
            await m.addColumn(foodItems, foodItems.saturatedFatPer100);
            await m.addColumn(mealEntries, mealEntries.fiberG);
            await m.addColumn(mealEntries, mealEntries.sodiumMg);
            await m.addColumn(mealEntries, mealEntries.sugarG);
            await m.addColumn(mealEntries, mealEntries.saturatedFatG);
          }
        },
      );

  /// Legacy hook kept for migration call sites; no exercises are pre-seeded.
  Future<void> seedBuiltinExercises() async {}
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fitness_plan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
