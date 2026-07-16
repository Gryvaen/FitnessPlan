import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db.dart';
import 'meal_repository.dart';

class MealPresetRepository {
  MealPresetRepository(this._db, this._meals);

  final AppDatabase _db;
  final MealRepository _meals;

  Future<List<MealPreset>> listPresets() {
    return (_db.select(_db.mealPresets)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<MealPresetItem>> itemsFor(int presetId) {
    return (_db.select(_db.mealPresetItems)
          ..where((t) => t.presetId.equals(presetId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<int> createFromEntries({
    required String name,
    required List<MealEntry> entries,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('套餐名称不能为空');
    if (entries.isEmpty) throw ArgumentError('没有可保存的记录');

    return _db.transaction(() async {
      final presetId = await _db.into(_db.mealPresets).insert(
            MealPresetsCompanion.insert(
              name: trimmed,
              createdAt: DateTime.now(),
            ),
          );
      for (final e in entries) {
        await _db.into(_db.mealPresetItems).insert(
              MealPresetItemsCompanion.insert(
                presetId: presetId,
                foodId: e.foodId,
                foodName: e.foodName,
                grams: e.grams,
                mealType: e.mealType,
              ),
            );
      }
      return presetId;
    });
  }

  Future<CopyDayResult> applyPreset({
    required int presetId,
    required DateTime date,
  }) async {
    final items = await itemsFor(presetId);
    var copied = 0;
    var skipped = 0;
    for (final item in items) {
      final food = await (_db.select(_db.foodItems)
            ..where((t) => t.id.equals(item.foodId)))
          .getSingleOrNull();
      if (food == null) {
        skipped++;
        continue;
      }
      await _meals.add(
        date: date,
        mealType: MealType.values.byName(item.mealType),
        food: food,
        grams: item.grams,
      );
      copied++;
    }
    return CopyDayResult(copied: copied, skippedMissingFood: skipped);
  }

  Future<void> deletePreset(int id) async {
    await (_db.delete(_db.mealPresetItems)..where((t) => t.presetId.equals(id)))
        .go();
    await (_db.delete(_db.mealPresets)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.mealPresetItems).go();
    await _db.delete(_db.mealPresets).go();
  }
}
