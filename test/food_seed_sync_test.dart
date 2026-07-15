import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_plan/data/db.dart';
import 'package:fitness_plan/data/repositories/food_repository.dart';
import 'package:fitness_plan/data/tables.dart';

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

  test('empty search returns all rows; keyword search works', () async {
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
    expect(await repo.search(''), hasLength(3));
    final hits = await repo.search('豆腐');
    expect(hits, hasLength(1));
    expect(hits.first.name, '豆腐');
  });

  test('search respects limit', () async {
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
    expect((await repo.search('鸡', limit: 100)).length, 100);
  });

  test('syncSeedFromAsset upserts by name', () async {
    final raw = await File('assets/food_seed.json').readAsString();
    final list = jsonDecode(raw) as List<dynamic>;
    expect(list.length, greaterThan(1500));

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

    await repo.syncSeedFromAsset();

    expect(await foodCount(), list.length);

    final row = await (db.select(db.foodItems)
          ..where((t) => t.name.equals(firstName)))
        .getSingle();
    expect(row.category, isNot('旧分类'));
    expect(row.kcalPer100, (first['kcal'] as num).toDouble());

    await repo.syncSeedFromAsset();
    expect(await foodCount(), list.length);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
