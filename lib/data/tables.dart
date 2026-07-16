import 'package:drift/drift.dart';

class FoodItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get kcalPer100 => real()();
  RealColumn get proteinPer100 => real()();
  RealColumn get carbPer100 => real()();
  RealColumn get fatPer100 => real()();
  /// Estimated alcohol g/100g (mainly beverages with residual energy).
  RealColumn get alcoholPer100 => real().withDefault(const Constant(0.0))();
  /// User-created foods survive seed sync deletion.
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}

class FoodServings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodId => integer()();
  TextColumn get label => text()();
  /// Stored as grams; ml labels use ≈1 ml = 1 g.
  RealColumn get grams => real()();
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
  RealColumn get alcoholG => real().withDefault(const Constant(0.0))();
}

class MealPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class MealPresetItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get presetId => integer()();
  IntColumn get foodId => integer()();
  TextColumn get foodName => text()();
  RealColumn get grams => real()();
  TextColumn get mealType => text()();
}

class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get ml => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Catalog of exercises (`unit`: reps | seconds).
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  /// English category key: chest, back, legs, core, core_timed, cardio,
  /// shoulders_arms, custom, other.
  TextColumn get category => text().withDefault(const Constant('other'))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}

class WorkoutPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class WorkoutPlanItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer()();
  IntColumn get exerciseId => integer()();
  TextColumn get exerciseName => text()();
  IntColumn get targetSets => integer()();
  /// Target reps, or target seconds when the exercise unit is seconds.
  IntColumn get targetReps => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class DayWorkouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get planId => integer().nullable()();
  TextColumn get planName => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

class DayWorkoutItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayWorkoutId => integer()();
  IntColumn get exerciseId => integer()();
  TextColumn get exerciseName => text()();
  IntColumn get targetSets => integer()();
  IntColumn get targetReps => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
}

class WorkoutSetLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get exerciseId => integer()();
  TextColumn get exerciseName => text()();
  IntColumn get setIndex => integer()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSec => integer().nullable()();
  IntColumn get dayWorkoutItemId => integer().nullable()();
}

/// One daily journal note per calendar day.
class DailyNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get content => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}
