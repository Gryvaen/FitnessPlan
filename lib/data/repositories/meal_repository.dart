import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db.dart';

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

  Future<int> add({
    required DateTime date,
    required MealType mealType,
    required FoodItem food,
    required double grams,
  }) {
    final intake = MacroIntake.fromGrams(
      grams: grams,
      kcalPer100: food.kcalPer100,
      proteinPer100: food.proteinPer100,
      carbPer100: food.carbPer100,
      fatPer100: food.fatPer100,
    );
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
          ),
        );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.mealEntries)..where((t) => t.id.equals(id))).go();

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
          ),
    );
  }
}
