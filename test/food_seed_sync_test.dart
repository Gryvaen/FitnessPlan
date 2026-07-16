import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/food_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FoodRepository repo;

  Future<int> foodCount() => db.foodItems.count().getSingle();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FoodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('empty search returns []; keyword search works', () async {
    for (final name in ['豆腐', '米饭', '鸡蛋']) {
      await db.into(db.foodItems).insert(
            FoodItemsCompanion.insert(
              name: name,
              category: '测试',
              kcalPer100: 80,
              proteinPer100: 8,
              carbPer100: 3,
              fatPer100: 4,
            ),
          );
    }
    expect(await repo.search(''), isEmpty);
    final hits = await repo.search('豆腐');
    expect(hits, hasLength(1));
    expect(hits.first.name, '豆腐');
  });

  test('search escapes LIKE wildcards and respects limit', () async {
    await db.into(db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: '100%纯牛奶',
            category: '乳品',
            kcalPer100: 60,
            proteinPer100: 3,
            carbPer100: 5,
            fatPer100: 3,
          ),
        );
    for (var i = 0; i < 150; i++) {
      await db.into(db.foodItems).insert(
            FoodItemsCompanion.insert(
              name: '鸡测试$i',
              category: '禽肉',
              kcalPer100: 100,
              proteinPer100: 20,
              carbPer100: 0,
              fatPer100: 5,
            ),
          );
    }
    expect(await repo.search('%'), hasLength(1));
    expect((await repo.search('鸡', limit: 100)).length, 100);
  });

  test('escapeLikePattern escapes special chars', () {
    expect(escapeLikePattern(r'a%b_c\d'), r'a\%b\_c\\d');
  });

  test('favorites and recent foods', () async {
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
    await repo.toggleFavorite(id);
    expect(await repo.isFavorite(id), isTrue);
    expect(await repo.favorites(), hasLength(1));

    await db.into(db.mealEntries).insert(
          MealEntriesCompanion.insert(
            date: DateTime(2026, 1, 1),
            mealType: 'lunch',
            foodId: id,
            foodName: '鸡胸肉',
            grams: 100,
            calories: 110,
            proteinG: 23,
            carbG: 0,
            fatG: 2,
          ),
        );
    final recent = await repo.recentFoods();
    expect(recent.map((e) => e.id), contains(id));
  });

  test('syncSeedFromAsset upserts by name and removes obsolete', () async {
    final raw = await File('assets/food_seed.json').readAsString();
    final list = jsonDecode(raw) as List<dynamic>;
    expect(list.length, greaterThan(3000));
    final han = RegExp(r'[\u4e00-\u9fff]');
    for (final item in list) {
      final name = (item as Map<String, dynamic>)['name'] as String;
      expect(han.hasMatch(name), isTrue, reason: 'non-Han name: $name');
    }

    final first = list.first as Map<String, dynamic>;
    final firstName = first['name'] as String;

    await db.into(db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: firstName,
            category: '旧分类',
            kcalPer100: 1,
            proteinPer100: 1,
            carbPer100: 1,
            fatPer100: 1,
          ),
        );
    await db.into(db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: '__obsolete_food__',
            category: '幽灵',
            kcalPer100: 1,
            proteinPer100: 1,
            carbPer100: 1,
            fatPer100: 1,
          ),
        );

    await repo.syncSeedFromAsset();

    expect(await foodCount(), list.length);

    final row = await (db.select(db.foodItems)
          ..where((t) => t.name.equals(firstName)))
        .getSingle();
    expect(row.category, isNot('旧分类'));
    expect(row.kcalPer100, (first['kcal'] as num).toDouble());
    expect(
      row.alcoholPer100,
      (first['alcohol'] as num?)?.toDouble() ?? 0.0,
    );

    final ghost = await (db.select(db.foodItems)
          ..where((t) => t.name.equals('__obsolete_food__')))
        .getSingleOrNull();
    expect(ghost, isNull);

    final alcoholic = list.cast<Map<String, dynamic>>().firstWhere(
          (m) => ((m['alcohol'] as num?)?.toDouble() ?? 0) > 0,
          orElse: () => <String, dynamic>{},
        );
    expect(alcoholic, isNotEmpty, reason: 'seed should include alcohol estimates');
    final alcoholName = alcoholic['name'] as String;
    final alcoholRow = await (db.select(db.foodItems)
          ..where((t) => t.name.equals(alcoholName)))
        .getSingle();
    expect(alcoholRow.alcoholPer100, (alcoholic['alcohol'] as num).toDouble());
    expect(alcoholRow.alcoholPer100, greaterThan(0));

    await repo.syncSeedFromAsset();
    expect(await foodCount(), list.length);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
