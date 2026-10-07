import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../../domain/models.dart';
import '../db.dart';
import 'meal_repository.dart';

class MealPresetDraftItem {
  const MealPresetDraftItem({
    required this.foodId,
    required this.grams,
    required this.mealType,
  });

  final int foodId;
  final double grams;
  final MealType mealType;
}

class MealPresetRepository {
  MealPresetRepository(this._db, this._meals);

  final AppDatabase _db;
  final MealRepository _meals;

  Future<List<MealPreset>> listPresets() {
    return (_db.select(
      _db.mealPresets,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<MealPreset?> presetByName(String name) {
    final trimmed = name.trim();
    return (_db.select(
      _db.mealPresets,
    )..where((t) => t.name.equals(trimmed))).getSingleOrNull();
  }

  Future<MealPreset?> presetById(int id) => (_db.select(
    _db.mealPresets,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<MealPresetItem>> itemsFor(int presetId) {
    return (_db.select(_db.mealPresetItems)
          ..where((t) => t.presetId.equals(presetId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<void> renamePreset(int presetId, String name) =>
      _db.transaction(() async {
        final trimmed = name.trim();
        if (trimmed.isEmpty) throw ArgumentError('套餐名称不能为空');
        if (await presetById(presetId) == null) throw StateError('套餐不存在');
        final named = await presetByName(trimmed);
        if (named != null && named.id != presetId) {
          throw StateError('套餐名称已存在');
        }
        await (_db.update(_db.mealPresets)..where((t) => t.id.equals(presetId)))
            .write(MealPresetsCompanion(name: Value(trimmed)));
      });

  Future<int> addItem({
    required int presetId,
    required int foodId,
    required double grams,
    required MealType mealType,
  }) => _db.transaction(() async {
    if (!grams.isFinite || grams <= 0) throw ArgumentError('食材克数必须大于 0');
    if (await presetById(presetId) == null) throw StateError('套餐不存在');
    final food = await (_db.select(
      _db.foodItems,
    )..where((t) => t.id.equals(foodId))).getSingleOrNull();
    if (food == null) throw StateError('食材不存在');
    return _db
        .into(_db.mealPresetItems)
        .insert(
          MealPresetItemsCompanion.insert(
            presetId: presetId,
            foodId: foodId,
            foodName: food.name,
            grams: grams,
            mealType: mealType.name,
          ),
        );
  });

  Future<void> updateItem({
    required int presetId,
    required int itemId,
    required double grams,
    required MealType mealType,
  }) async {
    if (!grams.isFinite || grams <= 0) throw ArgumentError('食材克数必须大于 0');
    final changed =
        await (_db.update(_db.mealPresetItems)
              ..where((t) => t.id.equals(itemId) & t.presetId.equals(presetId)))
            .write(
              MealPresetItemsCompanion(
                grams: Value(grams),
                mealType: Value(mealType.name),
              ),
            );
    if (changed == 0) throw StateError('套餐食材不存在');
  }

  Future<void> deleteItem({required int presetId, required int itemId}) async {
    final changed = await (_db.delete(
      _db.mealPresetItems,
    )..where((t) => t.id.equals(itemId) & t.presetId.equals(presetId))).go();
    if (changed == 0) throw StateError('套餐食材不存在');
  }

  Future<int> deleteMealType({
    required int presetId,
    required MealType mealType,
  }) =>
      (_db.delete(_db.mealPresetItems)..where(
            (t) =>
                t.presetId.equals(presetId) & t.mealType.equals(mealType.name),
          ))
          .go();

  /// Removes references to deleted foods and returns the number removed.
  Future<int> pruneMissingFoods(int presetId) => _db.transaction(() async {
    final items = await itemsFor(presetId);
    if (items.isEmpty) return 0;
    final ids = {for (final item in items) item.foodId}.toList();
    final foods = await (_db.select(
      _db.foodItems,
    )..where((t) => t.id.isIn(ids))).get();
    final present = {for (final food in foods) food.id};
    final missing = [
      for (final item in items)
        if (!present.contains(item.foodId)) item.id,
    ];
    if (missing.isEmpty) return 0;
    await (_db.delete(
      _db.mealPresetItems,
    )..where((t) => t.id.isIn(missing))).go();
    return missing.length;
  });

  /// Replaces the contents of one preset without changing its identity.
  Future<void> updatePreset({
    required int presetId,
    required String name,
    required List<MealPresetDraftItem> items,
  }) => _db.transaction(() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('套餐名称不能为空');
    if (items.isEmpty) throw ArgumentError('套餐至少需要一项食材');
    if (items.any((item) => !item.grams.isFinite || item.grams <= 0)) {
      throw ArgumentError('食材克数必须大于 0');
    }
    if (await presetById(presetId) == null) throw StateError('套餐不存在');
    final named = await presetByName(trimmed);
    if (named != null && named.id != presetId) {
      throw StateError('套餐名称已存在');
    }
    final ids = {for (final item in items) item.foodId}.toList();
    final foods = await (_db.select(
      _db.foodItems,
    )..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final food in foods) food.id: food};
    if (byId.length != ids.length) throw StateError('套餐中有已删除的食材');
    await (_db.update(_db.mealPresets)..where((t) => t.id.equals(presetId)))
        .write(MealPresetsCompanion(name: Value(trimmed)));
    await (_db.delete(
      _db.mealPresetItems,
    )..where((t) => t.presetId.equals(presetId))).go();
    for (final item in items) {
      await _db
          .into(_db.mealPresetItems)
          .insert(
            MealPresetItemsCompanion.insert(
              presetId: presetId,
              foodId: item.foodId,
              foodName: byId[item.foodId]!.name,
              grams: item.grams,
              mealType: item.mealType.name,
            ),
          );
    }
  });

  Future<int> createFromEntries({
    required String name,
    required List<MealEntry> entries,
    bool replaceExisting = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('套餐名称不能为空');
    if (entries.isEmpty) throw ArgumentError('没有可保存的记录');

    return _db.transaction(() async {
      if (replaceExisting) {
        final existing = await (_db.select(
          _db.mealPresets,
        )..where((t) => t.name.equals(trimmed))).getSingleOrNull();
        if (existing != null) {
          await (_db.delete(
            _db.mealPresetItems,
          )..where((t) => t.presetId.equals(existing.id))).go();
          await (_db.delete(
            _db.mealPresets,
          )..where((t) => t.id.equals(existing.id))).go();
        }
      }
      final presetId = await _db
          .into(_db.mealPresets)
          .insert(
            MealPresetsCompanion.insert(
              name: trimmed,
              createdAt: DateTime.now(),
            ),
          );
      for (final e in entries) {
        await _db
            .into(_db.mealPresetItems)
            .insert(
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
    CalendarDay.ensureEditableDay(date);
    final items = await itemsFor(presetId);
    var copied = 0;
    var skipped = 0;
    var skippedDuplicate = 0;
    if (items.isEmpty) {
      return CopyDayResult(copied: copied, skippedMissingFood: skipped);
    }

    // One batched lookup instead of one SELECT per item.
    final foodIds = {for (final i in items) i.foodId}.toList();
    final foods = await (_db.select(
      _db.foodItems,
    )..where((t) => t.id.isIn(foodIds))).get();
    final foodById = {for (final f in foods) f.id: f};

    // Transaction (matching createFromEntries above) so the app being
    // killed or a write failing mid-loop can't leave only some of the
    // preset's items logged for the day.
    await _db.transaction(() async {
      final existing = await _meals.forDay(date);
      final namesByType = <String, Set<String>>{};
      for (final entry in existing) {
        namesByType
            .putIfAbsent(entry.mealType, () => <String>{})
            .add(entry.foodName.trim());
      }
      for (final item in items) {
        final food = foodById[item.foodId];
        if (food == null) {
          skipped++;
          continue;
        }
        final names = namesByType.putIfAbsent(item.mealType, () => <String>{});
        if (!names.add(food.name.trim())) {
          skippedDuplicate++;
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
    });
    return CopyDayResult(
      copied: copied,
      skippedMissingFood: skipped,
      skippedDuplicate: skippedDuplicate,
    );
  }

  Future<void> deletePreset(int id) async {
    await (_db.delete(
      _db.mealPresetItems,
    )..where((t) => t.presetId.equals(id))).go();
    await (_db.delete(_db.mealPresets)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.mealPresetItems).go();
    await _db.delete(_db.mealPresets).go();
  }
}
