import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/food_repository.dart';
import 'package:diet/data/repositories/meal_preset_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/data/repositories/note_repository.dart';
import 'package:diet/data/repositories/water_repository.dart';
import 'package:diet/data/repositories/weight_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FoodRepository foods;
  late MealRepository meals;
  late MealPresetRepository presets;
  late NoteRepository notes;
  late WaterRepository water;
  late WeightRepository weights;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    foods = FoodRepository(db);
    meals = MealRepository(db);
    presets = MealPresetRepository(db, meals);
    notes = NoteRepository(db);
    water = WaterRepository(db, prefs);
    weights = WeightRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'custom foods survive seed sync deletion of non-seed names',
    () async {
      final customId = await foods.createCustom(
        name: '__我的家常菜__',
        kcalPer100: 200,
        proteinPer100: 10,
        carbPer100: 20,
        fatPer100: 5,
      );
      await db
          .into(db.foodItems)
          .insert(
            FoodItemsCompanion.insert(
              name: '__obsolete_seed_like__',
              category: '幽灵',
              kcalPer100: 1,
              proteinPer100: 0,
              carbPer100: 0,
              fatPer100: 0,
              isCustom: const Value(false),
            ),
          );

      await foods.syncSeedFromAsset();

      final custom = await foods.byId(customId);
      expect(custom, isNotNull);
      expect(custom!.isCustom, isTrue);
      expect(custom.name, '__我的家常菜__');

      final ghost = await foods.byName('__obsolete_seed_like__');
      expect(ghost, isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('servings CRUD and meal alcoholG from food', () async {
    final id = await foods.createCustom(
      name: '测试白酒',
      kcalPer100: 350,
      proteinPer100: 0,
      carbPer100: 0,
      fatPer100: 0,
      alcoholPer100: 50,
    );
    await foods.addServing(foodId: id, label: '杯 50ml', grams: 50);
    final servings = await foods.listServings(id);
    expect(servings, hasLength(1));
    expect(servings.first.grams, 50);

    final food = (await foods.byId(id))!;
    final day = CalendarDay.todayLocal();
    await meals.add(
      date: day,
      mealType: MealType.dinner,
      food: food,
      grams: 50,
    );
    final intake = await meals.intakeForDay(day);
    expect(intake.alcoholG, closeTo(25, 0.01));
    expect(intake.alcoholKcal, closeTo(175, 0.1));
    expect(intake.calories, closeTo(175, 0.1));
  });

  test('copyDay appends onto today and rejects past target', () async {
    final id = await foods.createCustom(
      name: '复制用米饭',
      kcalPer100: 100,
      proteinPer100: 2,
      carbPer100: 22,
      fatPer100: 0,
    );
    final food = (await foods.byId(id))!;
    final today = CalendarDay.todayLocal();
    final from = today.subtract(const Duration(days: 1));
    // Seed yesterday via raw insert (past days are not writable via API).
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: from,
            mealType: MealType.lunch.name,
            foodId: food.id,
            foodName: food.name,
            grams: 150,
            calories: 150,
            proteinG: 3,
            carbG: 33,
            fatG: 0,
          ),
        );
    final result = await meals.copyDay(from: from, to: today);
    expect(result.copied, 1);
    expect(result.skippedMissingFood, 0);
    final copied = await meals.forDay(today);
    expect(copied, hasLength(1));
    expect(copied.first.grams, 150);
    expect(copied.first.calories, closeTo(150, 0.01));

    await expectLater(
      meals.copyDay(from: today, to: from),
      throwsA(isA<StateError>()),
    );
  });

  test('meal add rejects past days', () async {
    final id = await foods.createCustom(
      name: '过去日拒写入',
      kcalPer100: 100,
      proteinPer100: 1,
      carbPer100: 1,
      fatPer100: 1,
    );
    final food = (await foods.byId(id))!;
    final yesterday = CalendarDay.todayLocal().subtract(
      const Duration(days: 1),
    );
    await expectLater(
      meals.add(
        date: yesterday,
        mealType: MealType.lunch,
        food: food,
        grams: 100,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('meal preset apply writes meals', () async {
    final id = await foods.createCustom(
      name: '套餐鸡蛋',
      kcalPer100: 140,
      proteinPer100: 13,
      carbPer100: 1,
      fatPer100: 9,
    );
    final food = (await foods.byId(id))!;
    final day = CalendarDay.todayLocal();
    await meals.add(
      date: day,
      mealType: MealType.breakfast,
      food: food,
      grams: 100,
    );
    final entries = await meals.forDay(day);
    final presetId = await presets.createFromEntries(
      name: '早餐套餐',
      entries: entries,
    );
    await meals.clearAll();
    final result = await presets.applyPreset(presetId: presetId, date: day);
    expect(result.copied, 1);
    expect(await meals.forDay(day), hasLength(1));
  });

  test('water logs and goal', () async {
    expect(water.getGoalMl(), kDefaultWaterGoalMl);
    await water.setGoalMl(2250);
    expect(water.getGoalMl(), 2250);

    final day = CalendarDay.todayLocal();
    expect(await water.mlForDay(day), 0);
    await water.addMl(day, 500);
    expect(await water.mlForDay(day), 500);
    await water.addMl(day, 250);
    expect(await water.mlForDay(day), 750);
    await water.addMl(day, -250);
    expect(await water.mlForDay(day), 500);

    final other = day.subtract(const Duration(days: 1));
    expect(await water.mlForDay(other), 0);
    await expectLater(water.addMl(other, 250), throwsA(isA<StateError>()));
  });

  test('past daily records reject update and delete operations', () async {
    final today = CalendarDay.todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));
    final foodId = await foods.createCustom(
      name: '历史守卫测试食材',
      kcalPer100: 100,
      proteinPer100: 1,
      carbPer100: 1,
      fatPer100: 1,
    );
    final food = (await foods.byId(foodId))!;
    final mealId = await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: yesterday,
            mealType: MealType.lunch.name,
            foodId: food.id,
            foodName: food.name,
            grams: 100,
            calories: 100,
            proteinG: 1,
            carbG: 1,
            fatG: 1,
          ),
        );
    final noteId = await db
        .into(db.dailyNotes)
        .insert(
          DailyNotesCompanion.insert(
            date: yesterday,
            content: '历史便签',
            updatedAt: yesterday,
          ),
        );
    final weightId = await db
        .into(db.weightLogs)
        .insert(WeightLogsCompanion.insert(date: yesterday, weightKg: 70));

    await expectLater(
      meals.update(
        id: mealId,
        mealType: MealType.dinner,
        food: food,
        grams: 200,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(meals.delete(mealId), throwsA(isA<StateError>()));
    await expectLater(
      notes.upsert(date: yesterday, content: '修改'),
      throwsA(isA<StateError>()),
    );
    await expectLater(notes.delete(noteId), throwsA(isA<StateError>()));
    await expectLater(
      weights.updateBodyFatForDate(yesterday, 20),
      throwsA(isA<StateError>()),
    );
    await expectLater(weights.delete(weightId), throwsA(isA<StateError>()));

    expect((await meals.byId(mealId))?.grams, 100);
    expect((await notes.byId(noteId))?.content, '历史便签');
    expect((await weights.byId(weightId))?.bodyFatPct, isNull);
  });
}
