import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/models.dart';

Future<FoodItem> _food(AppDatabase db, String name) async {
  final id = await db
      .into(db.foodItems)
      .insert(
        FoodItemsCompanion.insert(
          name: name,
          category: '自定义',
          kcalPer100: 100,
          proteinPer100: 10,
          carbPer100: 10,
          fatPer100: 2,
        ),
      );
  return (db.select(db.foodItems)..where((t) => t.id.equals(id))).getSingle();
}

void main() {
  test('logged foods carry their time; a meal takes its earliest', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MealRepository(db);
    final today = CalendarDay.todayLocal();
    final rice = await _food(db, '米饭');
    final egg = await _food(db, '鸡蛋');
    // Today at fixed clock times, so ensureEditableDay accepts them.
    final early = today.add(const Duration(hours: 8, minutes: 5));
    final late = today.add(const Duration(hours: 8, minutes: 40));

    final eggId = await repo.add(
      date: today,
      mealType: MealType.breakfast,
      food: egg,
      grams: 50,
      now: late,
    );
    await repo.add(
      date: today,
      mealType: MealType.breakfast,
      food: rice,
      grams: 150,
      now: early,
    );

    var breakfast = await repo.forDay(today);
    expect(breakfast.map((e) => e.loggedAt), containsAll([early, late]));
    expect(mealLoggedAt(breakfast), early);

    // Editing or moving a food keeps the moment it was logged.
    await repo.update(
      id: eggId,
      mealType: MealType.breakfast,
      food: egg,
      grams: 60,
    );
    await repo.moveMealType(id: eggId, mealType: MealType.lunch);
    final moved = (await repo.byId(eggId))!;
    expect(moved.loggedAt, late);
    breakfast = (await repo.forDay(
      today,
    )).where((e) => e.mealType == MealType.breakfast.name).toList();
    expect(mealLoggedAt(breakfast), early);
    expect(mealLoggedAt([moved]), late);
  });

  test('mealLoggedAt ignores entries without a time', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MealRepository(db);
    final today = CalendarDay.todayLocal();
    final rice = await _food(db, '米饭');
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: today,
            mealType: MealType.lunch.name,
            foodId: rice.id,
            foodName: rice.name,
            grams: 100,
            calories: 100,
            proteinG: 10,
            carbG: 10,
            fatG: 2,
          ),
        );
    expect(mealLoggedAt(await repo.forDay(today)), isNull);
    final at = today.add(const Duration(hours: 12, minutes: 30));
    await repo.add(
      date: today,
      mealType: MealType.lunch,
      food: rice,
      grams: 80,
      now: at,
    );
    expect(mealLoggedAt(await repo.forDay(today)), at);
  });

  test('v38 rows migrate with no time', () async {
    final dir = await Directory.systemTemp.createTemp('logged-time-v38-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');
    final seed = AppDatabase.forTesting(NativeDatabase(file));
    final rice = await _food(seed, '米饭');
    await seed
        .into(seed.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: DateTime(2026, 1, 1),
            mealType: MealType.lunch.name,
            foodId: rice.id,
            foodName: rice.name,
            grams: 100,
            calories: 100,
            proteinG: 10,
            carbG: 10,
            fatG: 2,
          ),
        );
    await seed.close();

    final oldDb = NativeDatabase(file);
    await oldDb.ensureOpen(_V38User());
    await oldDb.runCustom('ALTER TABLE meal_entries DROP COLUMN logged_at');
    await oldDb.runCustom(
      'ALTER TABLE day_workout_items DROP COLUMN performed_at',
    );
    await oldDb.runCustom('PRAGMA user_version = 38');
    await oldDb.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    final rows = await migrated.select(migrated.mealEntries).get();
    expect(rows.single.loggedAt, isNull);
    Future<List<String>> columns(String table) async => [
      for (final row
          in await migrated.customSelect('PRAGMA table_info("$table")').get())
        row.read<String>('name'),
    ];
    expect(await columns('meal_entries'), contains('logged_at'));
    expect(await columns('day_workout_items'), contains('performed_at'));
  });
}

class _V38User extends QueryExecutorUser {
  @override
  int get schemaVersion => 38;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
