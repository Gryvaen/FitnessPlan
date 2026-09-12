import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../db.dart';

/// Bump when [assets/food_seed.json] content changes meaningfully,
/// or when sync policy changes (e.g. obsolete-row deletion).
const kFoodSeedVersion = 9;

const kFoodSearchLimit = 80;

const kCustomFoodCategory = '自定义';

const _metaSeedVersionKey = 'food_seed_version';

/// Top-level for [compute].
List<Map<String, dynamic>> parseFoodSeedJson(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return [for (final e in list) Map<String, dynamic>.from(e as Map)];
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
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_metaSeedVersionKey))).getSingleOrNull();
    if (row == null) return 0;
    return int.tryParse(row.value) ?? 0;
  }

  Future<void> _setLocalSeedVersion(int version) async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(key: _metaSeedVersionKey, value: '$version'),
        );
  }

  /// Sync foods from asset: upsert by name, delete non-custom rows no longer in seed.
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
        final alcohol = (m['alcohol'] as num?)?.toDouble() ?? 0.0;
        final fiber = (m['fiber'] as num?)?.toDouble() ?? 0.0;
        final sodiumMg =
            (m['sodium_mg'] as num?)?.toDouble() ??
            (m['sodium'] as num?)?.toDouble() ??
            0.0;
        final sugar = (m['sugar'] as num?)?.toDouble() ?? 0.0;
        final saturatedFat = (m['saturated_fat'] as num?)?.toDouble() ?? 0.0;
        final calciumMg =
            (m['calcium_mg'] as num?)?.toDouble() ??
            (m['calcium'] as num?)?.toDouble() ??
            0.0;
        batch.insert(
          _db.foodItems,
          FoodItemsCompanion.insert(
            name: name,
            category: category,
            kcalPer100: kcal,
            proteinPer100: protein,
            carbPer100: carb,
            fatPer100: fat,
            alcoholPer100: Value(alcohol),
            fiberPer100: Value(fiber),
            sodiumMgPer100: Value(sodiumMg),
            sugarPer100: Value(sugar),
            saturatedFatPer100: Value(saturatedFat),
            calciumMgPer100: Value(calciumMg),
            isCustom: const Value(false),
          ),
          onConflict: DoUpdate(
            (_) => FoodItemsCompanion(
              category: Value(category),
              kcalPer100: Value(kcal),
              proteinPer100: Value(protein),
              carbPer100: Value(carb),
              fatPer100: Value(fat),
              alcoholPer100: Value(alcohol),
              fiberPer100: Value(fiber),
              sodiumMgPer100: Value(sodiumMg),
              sugarPer100: Value(sugar),
              saturatedFatPer100: Value(saturatedFat),
              calciumMgPer100: Value(calciumMg),
              // Never flip a custom row back to seed via name collision handling
              // after insert — conflict target is name; customs use unique names.
              isCustom: const Value(false),
            ),
            target: [_db.foodItems.name],
          ),
        );
      }
    });

    // Remove seed foods dropped from the asset; keep user customs.
    final obsolete =
        await (_db.select(_db.foodItems)..where(
              (t) =>
                  t.name.isNotIn(seedNames.toList()) & t.isCustom.equals(false),
            ))
            .get();
    if (obsolete.isNotEmpty) {
      final ids = obsolete.map((e) => e.id).toList();
      await (_db.delete(
        _db.favoriteFoods,
      )..where((t) => t.foodId.isIn(ids))).go();
      await (_db.delete(
        _db.foodServings,
      )..where((t) => t.foodId.isIn(ids))).go();
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
    return (_db.select(
      _db.foodItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<FoodItem?> byName(String name) {
    return (_db.select(
      _db.foodItems,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  Future<List<FoodItem>> _byIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _db.foodItems,
    )..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final r in rows) r.id: r};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Recently logged foods (most recent first), de-duplicated by food id.
  /// Excludes anything swiped off the list via [hideFromRecent] — unless
  /// it's been logged again since, which naturally un-hides it.
  Future<List<FoodItem>> recentFoods({int limit = 20}) async {
    final rows = await _db
        .customSelect(
          '''
SELECT meal_entries.food_id AS food_id FROM meal_entries
LEFT JOIN hidden_recent_foods
  ON hidden_recent_foods.food_id = meal_entries.food_id
GROUP BY meal_entries.food_id
HAVING hidden_recent_foods.food_id IS NULL
    OR MAX(meal_entries.id) > hidden_recent_foods.hidden_at_entry_id
ORDER BY MAX(meal_entries.id) DESC
LIMIT ?
''',
          variables: [Variable.withInt(limit)],
          readsFrom: {_db.mealEntries, _db.hiddenRecentFoods},
        )
        .get();
    final ids = rows.map((r) => r.read<int>('food_id')).toList();
    return _byIds(ids);
  }

  /// Swipes [foodId] off the 最近 (Recent) list without touching its past
  /// meal entries or (if favorited) its favorite status.
  Future<void> hideFromRecent(int foodId) async {
    final latest =
        await (_db.selectOnly(_db.mealEntries)
              ..addColumns([_db.mealEntries.id.max()])
              ..where(_db.mealEntries.foodId.equals(foodId)))
            .getSingleOrNull();
    final latestId = latest?.read(_db.mealEntries.id.max()) ?? 0;
    await _db
        .into(_db.hiddenRecentFoods)
        .insertOnConflictUpdate(
          HiddenRecentFoodsCompanion.insert(
            foodId: Value(foodId),
            hiddenAtEntryId: latestId,
          ),
        );
  }

  Future<int> createCustom({
    required String name,
    required double kcalPer100,
    required double proteinPer100,
    required double carbPer100,
    required double fatPer100,
    double alcoholPer100 = 0,
    double fiberPer100 = 0,
    double sodiumMgPer100 = 0,
    double sugarPer100 = 0,
    double saturatedFatPer100 = 0,
    double calciumMgPer100 = 0,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('名称不能为空');
    }
    final existing = await byName(trimmed);
    if (existing != null) {
      throw StateError('已存在同名食材，请换一个名称');
    }
    return _db
        .into(_db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: trimmed,
            category: kCustomFoodCategory,
            kcalPer100: kcalPer100,
            proteinPer100: proteinPer100,
            carbPer100: carbPer100,
            fatPer100: fatPer100,
            alcoholPer100: Value(alcoholPer100),
            fiberPer100: Value(fiberPer100),
            sodiumMgPer100: Value(sodiumMgPer100),
            sugarPer100: Value(sugarPer100),
            saturatedFatPer100: Value(saturatedFatPer100),
            calciumMgPer100: Value(calciumMgPer100),
            isCustom: const Value(true),
          ),
        );
  }

  Future<void> updateCustom({
    required int id,
    required String name,
    required double kcalPer100,
    required double proteinPer100,
    required double carbPer100,
    required double fatPer100,
    double alcoholPer100 = 0,
    double fiberPer100 = 0,
    double sodiumMgPer100 = 0,
    double sugarPer100 = 0,
    double saturatedFatPer100 = 0,
    double calciumMgPer100 = 0,
  }) async {
    final food = await byId(id);
    if (food == null || !food.isCustom) {
      throw StateError('只能编辑自定义食材');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('名称不能为空');
    }
    final clash = await byName(trimmed);
    if (clash != null && clash.id != id) {
      throw StateError('已存在同名食材，请换一个名称');
    }
    await (_db.update(_db.foodItems)..where((t) => t.id.equals(id))).write(
      FoodItemsCompanion(
        name: Value(trimmed),
        category: const Value(kCustomFoodCategory),
        kcalPer100: Value(kcalPer100),
        proteinPer100: Value(proteinPer100),
        carbPer100: Value(carbPer100),
        fatPer100: Value(fatPer100),
        alcoholPer100: Value(alcoholPer100),
        fiberPer100: Value(fiberPer100),
        sodiumMgPer100: Value(sodiumMgPer100),
        sugarPer100: Value(sugarPer100),
        saturatedFatPer100: Value(saturatedFatPer100),
        calciumMgPer100: Value(calciumMgPer100),
        isCustom: const Value(true),
      ),
    );
  }

  Future<void> deleteCustom(int id) async {
    final food = await byId(id);
    if (food == null || !food.isCustom) {
      throw StateError('只能删除自定义食材');
    }
    await (_db.delete(
      _db.favoriteFoods,
    )..where((t) => t.foodId.equals(id))).go();
    await (_db.delete(
      _db.foodServings,
    )..where((t) => t.foodId.equals(id))).go();
    await (_db.delete(_db.foodItems)..where((t) => t.id.equals(id))).go();
  }

  Future<List<FoodServing>> listServings(int foodId) {
    return (_db.select(_db.foodServings)
          ..where((t) => t.foodId.equals(foodId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<int> addServing({
    required int foodId,
    required String label,
    required double grams,
  }) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) throw ArgumentError('份量名称不能为空');
    if (grams <= 0) throw ArgumentError('克数须大于 0');
    return _db
        .into(_db.foodServings)
        .insert(
          FoodServingsCompanion.insert(
            foodId: foodId,
            label: trimmed,
            grams: grams,
          ),
        );
  }

  Future<void> deleteServing(int id) =>
      (_db.delete(_db.foodServings)..where((t) => t.id.equals(id))).go();

  Stream<List<FoodItem>> watchFavorites() {
    final query = _db.select(_db.foodItems).join([
      innerJoin(
        _db.favoriteFoods,
        _db.favoriteFoods.foodId.equalsExp(_db.foodItems.id),
      ),
    ])..orderBy([OrderingTerm.desc(_db.favoriteFoods.createdAt)]);
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
    ])..orderBy([OrderingTerm.desc(_db.favoriteFoods.createdAt)]);
    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.foodItems)).toList();
  }

  Future<bool> isFavorite(int foodId) async {
    final row = await (_db.select(
      _db.favoriteFoods,
    )..where((t) => t.foodId.equals(foodId))).getSingleOrNull();
    return row != null;
  }

  Future<void> _setFavorite(int foodId, bool favorite) async {
    if (favorite) {
      await _db
          .into(_db.favoriteFoods)
          .insertOnConflictUpdate(
            FavoriteFoodsCompanion.insert(
              foodId: Value(foodId),
              createdAt: DateTime.now(),
            ),
          );
    } else {
      await (_db.delete(
        _db.favoriteFoods,
      )..where((t) => t.foodId.equals(foodId))).go();
    }
  }

  Future<void> toggleFavorite(int foodId) async {
    final fav = await isFavorite(foodId);
    await _setFavorite(foodId, !fav);
  }

  Future<void> clearFavorites() => _db.delete(_db.favoriteFoods).go();

  Future<void> clearHiddenRecentFoods() =>
      _db.delete(_db.hiddenRecentFoods).go();
}

class FoodCategoryCount {
  const FoodCategoryCount({required this.category, required this.count});

  final String category;
  final int count;
}
