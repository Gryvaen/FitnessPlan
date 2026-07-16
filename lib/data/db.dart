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
  int get schemaVersion => 11;

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
        },
      );

  /// Upserts built-in exercises by name and backfills category for builtins.
  Future<void> seedBuiltinExercises() async {
    const seeds = <(String name, String unit, String category)>[
      ('俯卧撑', 'reps', 'chest'),
      ('宽距俯卧撑', 'reps', 'chest'),
      ('钻石俯卧撑', 'reps', 'chest'),
      ('跪姿俯卧撑', 'reps', 'chest'),
      ('引体向上', 'reps', 'back'),
      ('反向划船', 'reps', 'back'),
      ('超人式', 'reps', 'back'),
      ('深蹲', 'reps', 'legs'),
      ('弓步蹲', 'reps', 'legs'),
      ('保加利亚分腿蹲', 'reps', 'legs'),
      ('臀桥', 'reps', 'legs'),
      ('提踵', 'reps', 'legs'),
      ('卷腹', 'reps', 'core'),
      ('俄罗斯转体', 'reps', 'core'),
      ('登山跑', 'reps', 'core'),
      ('死虫', 'reps', 'core'),
      ('平板支撑', 'seconds', 'core_timed'),
      ('侧平板', 'seconds', 'core_timed'),
      ('开合跳', 'reps', 'cardio'),
      ('高抬腿', 'reps', 'cardio'),
      ('波比跳', 'reps', 'cardio'),
      ('原地慢跑', 'reps', 'cardio'),
      ('肩推（徒手）', 'reps', 'shoulders_arms'),
      ('三头臂屈伸', 'reps', 'shoulders_arms'),
      ('肱二头弯举（徒手）', 'reps', 'shoulders_arms'),
    ];
    for (final (name, unit, category) in seeds) {
      final existing = await (select(exercises)
            ..where((t) => t.name.equals(name)))
          .getSingleOrNull();
      if (existing == null) {
        await into(exercises).insert(
          ExercisesCompanion.insert(
            name: name,
            unit: unit,
            category: Value(category),
            isCustom: const Value(false),
          ),
        );
      } else if (!existing.isCustom && existing.category != category) {
        await (update(exercises)..where((t) => t.id.equals(existing.id)))
            .write(ExercisesCompanion(category: Value(category)));
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fitness_plan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
