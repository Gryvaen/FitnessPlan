import 'package:drift/drift.dart';

class FoodItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get kcalPer100 => real()();
  RealColumn get proteinPer100 => real()();
  RealColumn get carbPer100 => real()();
  RealColumn get fatPer100 => real()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}

class FavoriteFoods extends Table {
  IntColumn get foodId => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {foodId};
}

class WeightLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bodyFatPct => real().nullable()();
  /// Daily exercise minutes for this log date (not per-session).
  IntColumn get exerciseMinutes => integer().nullable()();
}

class MealEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()();
  IntColumn get foodId => integer()();
  TextColumn get foodName => text()();
  RealColumn get grams => real()();
  RealColumn get calories => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbG => real()();
  RealColumn get fatG => real()();
}

class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
