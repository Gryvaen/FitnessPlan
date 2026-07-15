import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../db.dart';

/// Bump when [assets/food_seed.json] content changes meaningfully.
const kFoodSeedVersion = 2;

const _metaSeedVersionKey = 'food_seed_version';

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

  /// Sync foods from asset: insert new names, update macros for existing names.
  Future<void> syncSeedFromAsset() async {
    if (await _localSeedVersion() >= kFoodSeedVersion) return;

    final raw = await rootBundle.loadString('assets/food_seed.json');
    final list = jsonDecode(raw) as List<dynamic>;

    await _db.batch((batch) {
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final name = m['name'] as String;
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

    await _setLocalSeedVersion(kFoodSeedVersion);
  }

  /// Kept for callers that still use the old name.
  Future<void> seedFromAssetIfNeeded() => syncSeedFromAsset();

  /// Empty [query] returns all foods (name-ordered). Keyword results use [limit] if set.
  Future<List<FoodItem>> search(String query, {int? limit}) {
    final q = query.trim();
    final select = _db.select(_db.foodItems)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (q.isNotEmpty) {
      select.where((t) => t.name.like('%$q%'));
    }
    if (limit != null) {
      select.limit(limit);
    }
    return select.get();
  }

  Future<List<FoodItem>> byCategory(String category) {
    return (_db.select(_db.foodItems)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<String>> categories() async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT category FROM food_items ORDER BY category',
        )
        .get();
    return rows.map((r) => r.read<String>('category')).toList();
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
}

class FoodCategoryCount {
  const FoodCategoryCount({required this.category, required this.count});

  final String category;
  final int count;
}
