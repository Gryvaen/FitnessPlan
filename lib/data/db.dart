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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fitness_plan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
