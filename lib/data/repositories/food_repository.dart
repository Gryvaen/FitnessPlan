import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../db.dart';

/// Bump when [assets/food_seed.json] content changes meaningfully,
/// or when sync policy changes (e.g. obsolete-row deletion).
const kFoodSeedVersion = 7;

const kFoodSearchLimit = 80;

const _metaSeedVersionKey = 'food_seed_version';

/// Top-level for [compute].
List<Map<String, dynamic>> parseFoodSeedJson(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return [
    for (final e in list) Map<String, dynamic>.from(e as Map),
  ];
}

String escapeLikePattern(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

class FoodRepository {
  FoodRepository(this._db);

  final AppDatabase _db;

  Future<int> _localSeedVersion() async {
    final row = await (_db.select(_db.appMeta)
          ..where((t) => t.key.equals(_metaSeedVersionKey)))
        .getSingleOrNull();
    if (row == null) return 0;
    return int.tryParse(row.value) ?? 0;
  }

  Future<void> _setLocalSeedVersion(int version) async {
    await _db.into(_db.appMeta).insertOnConflictUpdate(
          AppMetaCompanion.insert(
            key: _metaSeedVersionKey,
            value: '$version',
          ),
        );
  }

  /// Sync foods from asset: upsert by name, delete rows no longer in seed.
  Future<void> syncSeedFromAsset() async {
    if (await _localSeedVersion() >= kFoodSeedVersion) return;

    final raw = await rootBundle.loadString('assets/food_seed.json');
    final list = await compute(parseFoodSeedJson, raw);
    final seedNames = <String>{};

    await _db.batch((batch) {
      for (final m in list) {
        final name = m['name'] as String;
        seedNames.add(name);
        final category = m['category'] as String;
        final kcal = (m['kcal'] as num).toDouble();
        final protein = (m['protein'] as num).toDouble();
        final carb = (m['carb'] as num).toDouble();
        final fat = (m['fat'] as num).toDouble();
        batch.insert(
          _db.foodItems,
          FoodItemsCompanion.insert(
            name: name,
            category: category,
            kcalPer100: kcal,
            proteinPer100: protein,
            carbPer100: carb,
            fatPer100: fat,
          ),
          onConflict: DoUpdate(
            (_) => FoodItemsCompanion(
              category: Value(category),
              kcalPer100: Value(kcal),
              proteinPer100: Value(protein),
              carbPer100: Value(carb),
              fatPer100: Value(fat),
            ),
            target: [_db.foodItems.name],
          ),
        );
      }
    });

    // Remove foods dropped from the seed (meal rows keep denormalized names).
    final obsolete = await (_db.select(_db.foodItems)
          ..where((t) => t.name.isNotIn(seedNames.toList())))
        .get();
    if (obsolete.isNotEmpty) {
      final ids = obsolete.map((e) => e.id).toList();
      await (_db.delete(_db.favoriteFoods)
            ..where((t) => t.foodId.isIn(ids)))
          .go();
      await (_db.delete(_db.foodItems)..where((t) => t.id.isIn(ids))).go();
    }

    await _setLocalSeedVersion(kFoodSeedVersion);
  }

  /// Empty [query] returns []. Keyword results are limited (default [kFoodSearchLimit]).
  Future<List<FoodItem>> search(String query, {int limit = kFoodSearchLimit}) {
    final q = query.trim();
    if (q.isEmpty) return Future.value(const []);
    final pattern = '%${escapeLikePattern(q)}%';
    final select = _db.select(_db.foodItems)
      ..where((t) => t.name.like(pattern, escapeChar: r'\'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    return select.get();
  }

  Future<List<FoodItem>> byCategory(
    String category, {
    int? limit,
    int offset = 0,
  }) {
    final select = _db.select(_db.foodItems)
      ..where((t) => t.category.equals(category))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (limit != null) {
      select.limit(limit, offset: offset);
    }
    return select.get();
  }

  Future<List<FoodCategoryCount>> categoryCounts() async {
    final rows = await _db
        .customSelect(
          'SELECT category, COUNT(*) AS cnt FROM food_items '
          'GROUP BY category ORDER BY category',
        )
        .get();
    return rows
        .map(
          (r) => FoodCategoryCount(
            category: r.read<String>('category'),
            count: r.read<int>('cnt'),
          ),
        )
        .toList();
  }

  Future<FoodItem?> byId(int id) {
    return (_db.select(_db.foodItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<FoodItem>> _byIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(_db.foodItems)
          ..where((t) => t.id.isIn(ids)))
        .get();
    final byId = {for (final r in rows) r.id: r};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  /// Recently logged foods (most recent first), de-duplicated by food id.
  Future<List<FoodItem>> recentFoods({int limit = 20}) async {
    final rows = await _db.customSelect(
      '''
SELECT food_id FROM meal_entries
GROUP BY food_id
ORDER BY MAX(id) DESC
LIMIT ?
''',
      variables: [Variable.withInt(limit)],
      readsFrom: {_db.mealEntries},
    ).get();
    final ids = rows.map((r) => r.read<int>('food_id')).toList();
    return _byIds(ids);
  }

  Stream<List<FoodItem>> watchFavorites() {
    final query = _db.select(_db.foodItems).join([
      innerJoin(
        _db.favoriteFoods,
        _db.favoriteFoods.foodId.equalsExp(_db.foodItems.id),
      ),
    ])
      ..orderBy([OrderingTerm.desc(_db.favoriteFoods.createdAt)]);
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(_db.foodItems)).toList(),
        );
  }

  Future<List<FoodItem>> favorites() async {
    final query = _db.select(_db.foodItems).join([
      innerJoin(
        _db.favoriteFoods,
        _db.favoriteFoods.foodId.equalsExp(_db.foodItems.id),
      ),
    ])
      ..orderBy([OrderingTerm.desc(_db.favoriteFoods.createdAt)]);
    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.foodItems)).toList();
  }

  Future<bool> isFavorite(int foodId) async {
    final row = await (_db.select(_db.favoriteFoods)
          ..where((t) => t.foodId.equals(foodId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> _setFavorite(int foodId, bool favorite) async {
    if (favorite) {
      await _db.into(_db.favoriteFoods).insertOnConflictUpdate(
            FavoriteFoodsCompanion.insert(
              foodId: Value(foodId),
              createdAt: DateTime.now(),
            ),
          );
    } else {
      await (_db.delete(_db.favoriteFoods)
            ..where((t) => t.foodId.equals(foodId)))
          .go();
    }
  }

  Future<void> toggleFavorite(int foodId) async {
    final fav = await isFavorite(foodId);
    await _setFavorite(foodId, !fav);
  }

  Future<void> clearFavorites() => _db.delete(_db.favoriteFoods).go();
}

class FoodCategoryCount {
  const FoodCategoryCount({required this.category, required this.count});

  final String category;
  final int count;
}
