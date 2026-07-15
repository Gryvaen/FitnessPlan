import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db.dart';

const kDemoMealSeedVersion = 1;
const _metaDemoMealSeedKey = 'demo_meal_seed_version';

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

  Future<MealEntry?> byId(int id) => (_db.select(_db.mealEntries)
        ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

  Future<void> update({
    required int id,
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

  Future<int> _localDemoSeedVersion() async {
    final row = await (_db.select(_db.appMeta)
          ..where((t) => t.key.equals(_metaDemoMealSeedKey)))
        .getSingleOrNull();
    if (row == null) return 0;
    return int.tryParse(row.value) ?? 0;
  }

  Future<void> _setLocalDemoSeedVersion(int version) async {
    await _db.into(_db.appMeta).insertOnConflictUpdate(
          AppMetaCompanion.insert(
            key: _metaDemoMealSeedKey,
            value: '$version',
          ),
        );
  }

  Future<FoodItem> _foodByNameOrInsert({
    required String name,
    required String category,
    required double kcalPer100,
    required double proteinPer100,
    required double carbPer100,
    required double fatPer100,
  }) async {
    final existing = await (_db.select(_db.foodItems)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final id = await _db.into(_db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: name,
            category: category,
            kcalPer100: kcalPer100,
            proteinPer100: proteinPer100,
            carbPer100: carbPer100,
            fatPer100: fatPer100,
          ),
        );
    return (await (_db.select(_db.foodItems)..where((t) => t.id.equals(id)))
        .getSingle());
  }

  /// One-shot sample meals for D-1..D-3 so date history can be demoed.
  Future<void> seedDemoHistoryIfNeeded() async {
    if (await _localDemoSeedVersion() >= kDemoMealSeedVersion) return;

    final rice = await _foodByNameOrInsert(
      name: '米饭(蒸,粳米)',
      category: '谷类及制品',
      kcalPer100: 116,
      proteinPer100: 2.6,
      carbPer100: 25.6,
      fatPer100: 0.3,
    );
    final egg = await _foodByNameOrInsert(
      name: '鸡蛋(红皮)',
      category: '蛋类及制品',
      kcalPer100: 156,
      proteinPer100: 12.8,
      carbPer100: 1.1,
      fatPer100: 10.6,
    );
    final chicken = await _foodByNameOrInsert(
      name: '鸡胸脯肉',
      category: '畜禽肉类',
      kcalPer100: 133,
      proteinPer100: 24.6,
      carbPer100: 2.2,
      fatPer100: 3.1,
    );
    final tofu = await _foodByNameOrInsert(
      name: '豆腐',
      category: '豆类及制品',
      kcalPer100: 81,
      proteinPer100: 8.1,
      carbPer100: 4.2,
      fatPer100: 3.7,
    );
    final banana = await _foodByNameOrInsert(
      name: '香蕉',
      category: '水果类及制品',
      kcalPer100: 93,
      proteinPer100: 1.4,
      carbPer100: 22.8,
      fatPer100: 0.2,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Future<void> log(
      int daysAgo,
      MealType type,
      FoodItem food,
      double grams,
    ) {
      return add(
        date: today.subtract(Duration(days: daysAgo)),
        mealType: type,
        food: food,
        grams: grams,
      );
    }

    // D-1
    await log(1, MealType.breakfast, egg, 100);
    await log(1, MealType.breakfast, banana, 120);
    await log(1, MealType.lunch, rice, 200);
    await log(1, MealType.lunch, chicken, 150);
    await log(1, MealType.dinner, rice, 150);
    await log(1, MealType.dinner, tofu, 200);

    // D-2
    await log(2, MealType.breakfast, banana, 150);
    await log(2, MealType.lunch, rice, 180);
    await log(2, MealType.lunch, egg, 100);
    await log(2, MealType.dinner, chicken, 180);
    await log(2, MealType.snack, banana, 100);

    // D-3
    await log(3, MealType.breakfast, egg, 120);
    await log(3, MealType.lunch, rice, 220);
    await log(3, MealType.lunch, tofu, 180);
    await log(3, MealType.dinner, chicken, 160);
    await log(3, MealType.dinner, rice, 120);

    await _setLocalDemoSeedVersion(kDemoMealSeedVersion);
  }
}
