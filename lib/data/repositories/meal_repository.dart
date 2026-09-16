import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../../domain/models.dart';
import '../db.dart';

class CopyDayResult {
  const CopyDayResult({required this.copied, required this.skippedMissingFood});

  final int copied;
  final int skippedMissingFood;
}

class MealRepository {
  MealRepository(this._db);

  final AppDatabase _db;

  DateTime _dayStart(DateTime d) => CalendarDay.dayOnly(d);
  DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Stream<List<MealEntry>> watchForDay(DateTime day) {
    final start = _dayStart(day);
    final end = _dayEnd(day);
    return (_db.select(_db.mealEntries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm.asc(t.mealType),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Future<List<MealEntry>> forDay(DateTime day) {
    final start = _dayStart(day);
    final end = _dayEnd(day);
    return (_db.select(_db.mealEntries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  MacroIntake _intakeFor(FoodItem food, double grams) {
    return MacroIntake.fromGrams(
      grams: grams,
      kcalPer100: food.kcalPer100,
      proteinPer100: food.proteinPer100,
      carbPer100: food.carbPer100,
      fatPer100: food.fatPer100,
      alcoholPer100: food.alcoholPer100,
      fiberPer100: food.fiberPer100,
      sodiumMgPer100: food.sodiumMgPer100,
      sugarPer100: food.sugarPer100,
      saturatedFatPer100: food.saturatedFatPer100,
      calciumMgPer100: food.calciumMgPer100,
    );
  }

  Future<int> add({
    required DateTime date,
    required MealType mealType,
    required FoodItem food,
    required double grams,
  }) async {
    CalendarDay.ensureEditableDay(date);
    final intake = _intakeFor(food, grams);
    return _db
        .into(_db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: _dayStart(date),
            mealType: mealType.name,
            foodId: food.id,
            foodName: food.name,
            grams: grams,
            calories: intake.calories,
            proteinG: intake.proteinG,
            carbG: intake.carbG,
            fatG: intake.fatG,
            alcoholG: Value(intake.alcoholG),
            fiberG: Value(intake.fiberG),
            sodiumMg: Value(intake.sodiumMg),
            sugarG: Value(intake.sugarG),
            saturatedFatG: Value(intake.saturatedFatG),
            calciumMg: Value(intake.calciumMg),
          ),
        );
  }

  Future<MealEntry?> byId(int id) => (_db.select(
    _db.mealEntries,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> update({
    required int id,
    required MealType mealType,
    required FoodItem food,
    required double grams,
  }) async {
    final existing = await byId(id);
    if (existing == null) return;
    CalendarDay.ensureEditableDay(existing.date);
    final intake = _intakeFor(food, grams);
    await (_db.update(_db.mealEntries)..where((t) => t.id.equals(id))).write(
      MealEntriesCompanion(
        mealType: Value(mealType.name),
        foodId: Value(food.id),
        foodName: Value(food.name),
        grams: Value(grams),
        calories: Value(intake.calories),
        proteinG: Value(intake.proteinG),
        carbG: Value(intake.carbG),
        fatG: Value(intake.fatG),
        alcoholG: Value(intake.alcoholG),
        fiberG: Value(intake.fiberG),
        sodiumMg: Value(intake.sodiumMg),
        sugarG: Value(intake.sugarG),
        saturatedFatG: Value(intake.saturatedFatG),
        calciumMg: Value(intake.calciumMg),
      ),
    );
  }

  /// Moves an existing entry to a different meal type (e.g. drag-and-drop
  /// between sections), keeping its food/grams/macros unchanged.
  Future<void> moveMealType({required int id, required MealType mealType}) async {
    final existing = await byId(id);
    if (existing == null) return;
    CalendarDay.ensureEditableDay(existing.date);
    await (_db.update(_db.mealEntries)..where((t) => t.id.equals(id))).write(
      MealEntriesCompanion(mealType: Value(mealType.name)),
    );
  }

  Future<void> delete(int id) async {
    final existing = await byId(id);
    if (existing == null) return;
    CalendarDay.ensureEditableDay(existing.date);
    await (_db.delete(_db.mealEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Quick "clear this meal": deletes every entry of [mealType] on [day].
  Future<int> deleteMealType(DateTime day, MealType mealType) async {
    CalendarDay.ensureEditableDay(day);
    final start = _dayStart(day);
    final end = _dayEnd(day);
    return (_db.delete(_db.mealEntries)..where(
          (t) =>
              t.date.isBetweenValues(start, end) &
              t.mealType.equals(mealType.name),
        ))
        .go();
  }

  /// Appends [from] day's meals onto [to]. Recalculates macros from current food rows.
  /// [to] must be today; [from] may be any past day.
  Future<CopyDayResult> copyDay({
    required DateTime from,
    required DateTime to,
    MealType? mealType,
  }) async {
    CalendarDay.ensureEditableDay(to);
    final source = await forDay(from);
    final filtered = mealType == null
        ? source
        : source.where((e) => e.mealType == mealType.name).toList();
    if (filtered.isEmpty) {
      return const CopyDayResult(copied: 0, skippedMissingFood: 0);
    }

    // One batched lookup instead of one SELECT per entry.
    final foodIds = {for (final e in filtered) e.foodId}.toList();
    final foods = await (_db.select(
      _db.foodItems,
    )..where((t) => t.id.isIn(foodIds))).get();
    final foodById = {for (final f in foods) f.id: f};

    var copied = 0;
    var skipped = 0;
    // Transaction (matching applyPreset) so a crash mid-copy can't leave
    // only some of the day's entries copied.
    await _db.transaction(() async {
      for (final entry in filtered.reversed) {
        final food = foodById[entry.foodId];
        if (food == null) {
          skipped++;
          continue;
        }
        await add(
          date: to,
          mealType: MealType.values.byName(entry.mealType),
          food: food,
          grams: entry.grams,
        );
        copied++;
      }
    });
    return CopyDayResult(copied: copied, skippedMissingFood: skipped);
  }

  Future<MacroIntake> intakeForDay(DateTime day) async {
    final entries = await forDay(day);
    return entries.fold<MacroIntake>(
      const MacroIntake(),
      (sum, e) =>
          sum +
          MacroIntake(
            calories: e.calories,
            proteinG: e.proteinG,
            carbG: e.carbG,
            fatG: e.fatG,
            alcoholG: e.alcoholG,
            fiberG: e.fiberG,
            sodiumMg: e.sodiumMg,
            sugarG: e.sugarG,
            saturatedFatG: e.saturatedFatG,
            calciumMg: e.calciumMg,
          ),
    );
  }

  /// Sum of logged calories per local calendar day in [[start], [end]] (inclusive).
  Future<Map<DateTime, double>> calorieTotalsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final s = _dayStart(start);
    final e = _dayEnd(end);
    final rows = await (_db.select(
      _db.mealEntries,
    )..where((t) => t.date.isBetweenValues(s, e))).get();
    final map = <DateTime, double>{};
    for (final r in rows) {
      final key = _dayStart(r.date);
      map[key] = (map[key] ?? 0) + r.calories;
    }
    return map;
  }

  Future<void> clearAll() => _db.delete(_db.mealEntries).go();
}
