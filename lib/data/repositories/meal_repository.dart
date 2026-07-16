import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db.dart';

class CopyDayResult {
  const CopyDayResult({
    required this.copied,
    required this.skippedMissingFood,
  });

  final int copied;
  final int skippedMissingFood;
}

class MealRepository {
  MealRepository(this._db);

  final AppDatabase _db;

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
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
    );
  }

  Future<int> add({
    required DateTime date,
    required MealType mealType,
    required FoodItem food,
    required double grams,
  }) {
    final intake = _intakeFor(food, grams);
    return _db.into(_db.mealEntries).insert(
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
          ),
        );
  }

  Future<MealEntry?> byId(int id) => (_db.select(_db.mealEntries)
        ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

  Future<void> update({
    required int id,
    required MealType mealType,
    required FoodItem food,
    required double grams,
  }) {
    final intake = _intakeFor(food, grams);
    return (_db.update(_db.mealEntries)..where((t) => t.id.equals(id))).write(
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
          ),
        );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.mealEntries)..where((t) => t.id.equals(id))).go();

  /// Appends [from] day's meals onto [to]. Recalculates macros from current food rows.
  Future<CopyDayResult> copyDay({
    required DateTime from,
    required DateTime to,
    MealType? mealType,
  }) async {
    final source = await forDay(from);
    final filtered = mealType == null
        ? source
        : source.where((e) => e.mealType == mealType.name).toList();
    var copied = 0;
    var skipped = 0;
    for (final entry in filtered.reversed) {
      final food = await (_db.select(_db.foodItems)
            ..where((t) => t.id.equals(entry.foodId)))
          .getSingleOrNull();
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
    final rows = await (_db.select(_db.mealEntries)
          ..where((t) => t.date.isBetweenValues(s, e)))
        .get();
    final map = <DateTime, double>{};
    for (final r in rows) {
      final key = _dayStart(r.date);
      map[key] = (map[key] ?? 0) + r.calories;
    }
    return map;
  }

  Future<void> clearAll() => _db.delete(_db.mealEntries).go();
}
