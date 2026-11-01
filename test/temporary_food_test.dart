import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/food_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/data/repositories/meal_preset_repository.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/domain/temporary_food_draft.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late MealRepository meals;
  late FoodRepository foods;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    meals = MealRepository(db);
    foods = FoodRepository(db);
  });
  tearDown(() => db.close());

  test(
    'total portion preserves exact intake, stays hidden and permits same name',
    () async {
      final regular = await foods.createCustom(
        name: '饭',
        kcalPer100: 100,
        proteinPer100: 1,
        carbPer100: 2,
        fatPer100: 3,
      );
      const draft = TemporaryFoodDraft(
        name: '饭',
        totalGrams: 300,
        nutrition: MacroIntake(
          calories: 500,
          proteinG: 30,
          sodiumMg: 123.456,
          calciumMg: 99,
        ),
      );
      for (var i = 0; i < 2; i++) {
        await meals.addTemporary(
          date: DateTime.now(),
          mealType: MealType.lunch,
          draft: draft,
          grams: 300,
        );
      }
      final entries = await meals.forDay(DateTime.now());
      expect(entries, hasLength(2));
      expect(entries.first.calories, 500);
      expect(entries.first.proteinG, 30);
      expect(entries.first.sodiumMg, 123.456);
      final food = (await foods.byId(entries.first.foodId))!;
      expect(food.isTemporary, isTrue);
      expect(food.kcalPer100, closeTo(500 / 3, 1e-10));
      expect((await foods.search('饭')).map((f) => f.id), [regular]);
      expect((await foods.byCategory('自定义')).map((f) => f.id), [regular]);
      expect((await foods.categoryCounts()).single.count, 1);
      expect(await foods.recentFoods(), isEmpty);
      await foods.toggleFavorite(food.id);
      expect(await foods.favorites(), isEmpty);
      await meals.update(
        id: entries.first.id,
        mealType: MealType.dinner,
        food: food,
        grams: 150,
      );
      expect(
        (await meals.byId(entries.first.id))!.calories,
        closeTo(250, 1e-10),
      );
    },
  );

  test('per100 calculation, copy skip and preset filtering', () async {
    final today = DateTime.now();
    final id = await meals.addTemporary(
      date: today,
      mealType: MealType.lunch,
      draft: const TemporaryFoodDraft(
        name: '一次',
        nutrition: MacroIntake(calories: 200, proteinG: 10),
      ),
      grams: 150,
    );
    expect((await meals.byId(id))!.calories, 300);
    final copied = await meals.copyDay(from: today, to: today);
    expect(copied.copied, 0);
    expect(copied.skippedTemporary, 1);
    final presets = MealPresetRepository(db, meals);
    await expectLater(
      presets.createFromEntries(
        name: '空预设',
        entries: await meals.forDay(today),
      ),
      throwsArgumentError,
    );
    expect(await presets.listPresets(), isEmpty);
  });

  test(
    'v36 migration retains foods and changes name uniqueness safely',
    () async {
      final upgraded = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (native) {
            native.execute('''CREATE TABLE food_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE, name_en TEXT, category TEXT NOT NULL,
        kcal_per100 REAL NOT NULL, protein_per100 REAL NOT NULL,
        carb_per100 REAL NOT NULL, fat_per100 REAL NOT NULL,
        alcohol_per100 REAL NOT NULL DEFAULT 0,
        fiber_per100 REAL NOT NULL DEFAULT 0,
        sodium_mg_per100 REAL NOT NULL DEFAULT 0,
        sugar_per100 REAL NOT NULL DEFAULT 0,
        saturated_fat_per100 REAL NOT NULL DEFAULT 0,
        calcium_mg_per100 REAL NOT NULL DEFAULT 0,
        is_custom INTEGER NOT NULL DEFAULT 0
      )''');
            native.execute(
              "INSERT INTO food_items(name, category, kcal_per100, protein_per100, carb_per100, fat_per100) VALUES ('旧食物', '自定义', 100, 1, 2, 3)",
            );
            native.execute(
              'CREATE UNIQUE INDEX food_items_name_unique ON food_items(name)',
            );
            native.execute('PRAGMA user_version = 36');
          },
        ),
      );
      addTearDown(upgraded.close);
      final original = (await upgraded.select(upgraded.foodItems).get()).single;
      expect(original.name, '旧食物');
      expect(original.isTemporary, isFalse);
      await upgraded
          .into(upgraded.foodItems)
          .insert(
            original
                .toCompanion(true)
                .copyWith(
                  id: const Value.absent(),
                  isTemporary: const Value(true),
                ),
          );
      expect(await upgraded.select(upgraded.foodItems).get(), hasLength(2));
      await expectLater(
        upgraded
            .into(upgraded.foodItems)
            .insert(
              original.toCompanion(true).copyWith(id: const Value.absent()),
            ),
        throwsA(anything),
      );
    },
  );

  test('failed meal insert rolls back temporary food', () async {
    await db.customStatement(
      "CREATE TRIGGER fail_meal BEFORE INSERT ON meal_entries "
      "BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      meals.addTemporary(
        date: DateTime.now(),
        mealType: MealType.lunch,
        grams: 100,
        draft: const TemporaryFoodDraft(
          name: '回滚',
          nutrition: MacroIntake(calories: 200),
        ),
      ),
      throwsA(anything),
    );
    expect(await db.select(db.foodItems).get(), isEmpty);
    expect(await meals.forDay(DateTime.now()), isEmpty);
  });

  test(
    'calorie-only record hides from reuse, edits and contributes to intake',
    () async {
      final id = await meals.addTemporary(
        date: DateTime.now(),
        mealType: MealType.lunch,
        grams: 0,
        draft: const TemporaryFoodDraft(
          name: '热量',
          input: TemporaryFoodInput.caloriesOnly,
          nutrition: MacroIntake(calories: 500),
        ),
      );
      final entry = (await meals.byId(id))!;
      expect(entry.caloriesOnly, isTrue);
      expect(entry.grams, 0);
      expect(entry.calories, 500);
      expect((await meals.intakeForDay(DateTime.now())).calories, 500);
      final food = (await foods.byId(entry.foodId))!;
      expect(food.isTemporary, isTrue);
      expect(food.kcalPer100, 0);
      expect(await foods.search('热量'), isEmpty);
      expect(await foods.recentFoods(), isEmpty);
      final result = await meals.copyDay(
        from: DateTime.now(),
        to: DateTime.now(),
      );
      expect(result.skippedTemporary, 1);
      await meals.updateCaloriesOnly(
        id: id,
        mealType: MealType.dinner,
        calories: 650,
      );
      final changed = (await meals.byId(id))!;
      expect(changed.mealType, 'dinner');
      expect(changed.calories, 650);
      expect(changed.grams, 0);
      await expectLater(
        meals.updateCaloriesOnly(
          id: id,
          mealType: MealType.dinner,
          calories: double.nan,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'v37 migration defaults old meal entries to weight-based records',
    () async {
      final legacy = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (native) {
            native.execute('''CREATE TABLE meal_entries (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL, meal_type TEXT NOT NULL,
        food_id INTEGER NOT NULL, food_name TEXT NOT NULL,
        grams REAL NOT NULL, calories REAL NOT NULL,
        protein_g REAL NOT NULL, carb_g REAL NOT NULL, fat_g REAL NOT NULL,
        alcohol_g REAL NOT NULL DEFAULT 0, fiber_g REAL NOT NULL DEFAULT 0,
        sodium_mg REAL NOT NULL DEFAULT 0, sugar_g REAL NOT NULL DEFAULT 0,
        saturated_fat_g REAL NOT NULL DEFAULT 0, calcium_mg REAL NOT NULL DEFAULT 0
      )''');
            native.execute(
              "INSERT INTO meal_entries(date, meal_type, food_id, food_name, grams, calories, protein_g, carb_g, fat_g) VALUES(0, 'lunch', 1, '旧记录', 150, 300, 0, 0, 0)",
            );
            native.execute('PRAGMA user_version = 37');
          },
        ),
      );
      addTearDown(legacy.close);
      final entry = (await legacy.select(legacy.mealEntries).get()).single;
      expect(entry.caloriesOnly, isFalse);
      expect(entry.grams, 150);
      expect(entry.calories, 300);
    },
  );

  test('invalid portion or noneditable day leaves no food behind', () async {
    for (final weight in [0.0, -1.0, double.infinity, double.nan]) {
      await expectLater(
        meals.addTemporary(
          date: DateTime.now(),
          mealType: MealType.lunch,
          grams: weight,
          draft: TemporaryFoodDraft(
            name: '错误',
            totalGrams: weight,
            nutrition: const MacroIntake(calories: 500),
          ),
        ),
        throwsArgumentError,
      );
    }
    expect(await db.select(db.foodItems).get(), isEmpty);
    await expectLater(
      meals.addTemporary(
        date: DateTime(2000),
        mealType: MealType.lunch,
        grams: 100,
        draft: const TemporaryFoodDraft(name: '过去', nutrition: MacroIntake()),
      ),
      throwsA(anything),
    );
    expect(await db.select(db.foodItems).get(), isEmpty);
  });
}
