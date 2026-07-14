import 'package:drift/drift.dart';

class FoodItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get kcalPer100 => real()();
  RealColumn get proteinPer100 => real()();
  RealColumn get carbPer100 => real()();
  RealColumn get fatPer100 => real()();
}

class WeightLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();
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
