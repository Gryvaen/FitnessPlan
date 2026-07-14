import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../db.dart';

class FoodRepository {
  FoodRepository(this._db);

  final AppDatabase _db;

  Future<bool> isEmpty() async {
    final count = await _db.foodItems.count().getSingle();
    return count == 0;
  }

  Future<void> seedFromAssetIfNeeded() async {
    if (!await isEmpty()) return;
    final raw = await rootBundle.loadString('assets/food_seed.json');
    final list = jsonDecode(raw) as List<dynamic>;
    await _db.batch((batch) {
      batch.insertAll(
        _db.foodItems,
        list.map((e) {
          final m = e as Map<String, dynamic>;
          return FoodItemsCompanion.insert(
            name: m['name'] as String,
            category: m['category'] as String,
            kcalPer100: (m['kcal'] as num).toDouble(),
            proteinPer100: (m['protein'] as num).toDouble(),
            carbPer100: (m['carb'] as num).toDouble(),
            fatPer100: (m['fat'] as num).toDouble(),
          );
        }).toList(),
      );
    });
  }

  Future<List<FoodItem>> search(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      return (_db.select(_db.foodItems)
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();
    }
    return (_db.select(_db.foodItems)
          ..where((t) => t.name.like('%$q%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
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

  Future<FoodItem?> byId(int id) {
    return (_db.select(_db.foodItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
