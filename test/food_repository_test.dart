import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/food_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FoodRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FoodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('deleteCustom removes favorite / serving / hidden-recent rows too', () async {
    final id = await repo.createCustom(
      name: '自制沙拉',
      kcalPer100: 50,
      proteinPer100: 2,
      carbPer100: 5,
      fatPer100: 2,
    );

    await repo.toggleFavorite(id);
    await db.into(db.foodServings).insert(
          FoodServingsCompanion.insert(foodId: id, label: '一份', grams: 150),
        );
    await db.into(db.mealEntries).insert(
          MealEntriesCompanion.insert(
            date: DateTime(2026, 1, 1),
            mealType: 'lunch',
            foodId: id,
            foodName: '自制沙拉',
            grams: 150,
            calories: 75,
            proteinG: 3,
            carbG: 7.5,
            fatG: 3,
          ),
        );
    await repo.hideFromRecent(id);

    expect(await repo.isFavorite(id), isTrue);
    expect(await repo.listServings(id), hasLength(1));
    expect(
      await (db.select(db.hiddenRecentFoods)
            ..where((t) => t.foodId.equals(id)))
          .getSingleOrNull(),
      isNotNull,
    );

    await repo.deleteCustom(id);

    expect(await repo.byId(id), isNull);
    expect(await repo.isFavorite(id), isFalse);
    expect(await repo.listServings(id), isEmpty);
    expect(
      await (db.select(db.hiddenRecentFoods)
            ..where((t) => t.foodId.equals(id)))
          .getSingleOrNull(),
      isNull,
    );
  });

  test('lastGramsFor returns the most recently logged grams, or null', () async {
    final id = await db.into(db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: '鸡胸肉',
            category: '禽肉',
            kcalPer100: 110,
            proteinPer100: 23,
            carbPer100: 0,
            fatPer100: 2,
          ),
        );

    expect(await repo.lastGramsFor(id), isNull);

    Future<void> log(double grams) => db.into(db.mealEntries).insert(
          MealEntriesCompanion.insert(
            date: DateTime(2026, 1, 1),
            mealType: 'lunch',
            foodId: id,
            foodName: '鸡胸肉',
            grams: grams,
            calories: 110 * grams / 100,
            proteinG: 23 * grams / 100,
            carbG: 0,
            fatG: 2 * grams / 100,
          ),
        );

    await log(120);
    expect(await repo.lastGramsFor(id), 120);

    await log(85);
    expect(await repo.lastGramsFor(id), 85);
  });
}
