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

  /// Dietary fiber g/100g (营养成分表常见项).
  RealColumn get fiberPer100 => real().withDefault(const Constant(0.0))();

  /// Sodium mg/100g.
  RealColumn get sodiumMgPer100 => real().withDefault(const Constant(0.0))();

  /// Sugars g/100g.
  RealColumn get sugarPer100 => real().withDefault(const Constant(0.0))();

  /// Saturated fat g/100g.
  RealColumn get saturatedFatPer100 =>
      real().withDefault(const Constant(0.0))();

  /// Calcium mg/100g.
  RealColumn get calciumMgPer100 => real().withDefault(const Constant(0.0))();

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

/// A food swiped off the 最近 (Recent) list. [hiddenAtEntryId] snapshots the
/// newest `meal_entries.id` for that food at hide time — logging it again
/// afterward naturally un-hides it (the recents query only excludes a food
/// while no meal entry newer than the hide exists), so "removed" reads as
/// "not recent anymore", not "never show again".
class HiddenRecentFoods extends Table {
  IntColumn get foodId => integer()();
  IntColumn get hiddenAtEntryId => integer()();

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
  RealColumn get fiberG => real().withDefault(const Constant(0.0))();
  RealColumn get sodiumMg => real().withDefault(const Constant(0.0))();
  RealColumn get sugarG => real().withDefault(const Constant(0.0))();
  RealColumn get saturatedFatG => real().withDefault(const Constant(0.0))();
  RealColumn get calciumMg => real().withDefault(const Constant(0.0))();
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

/// Daily step totals synced from HealthKit / Health Connect.
class StepLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get steps => integer()();

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

/// Immutable fat-loss strategy versions. Dates are stored as local
/// `yyyy-MM-dd` text so time-zone / DST changes cannot shift a day.
@DataClassName('DietStrategyPlanRow')
class DietStrategyPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get version => integer()();
  TextColumn get strategy => text()();
  TextColumn get status => text()();
  TextColumn get effectiveFrom => text()();
  TextColumn get endedOn => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get referenceWeightKg => real()();
  RealColumn get estimatedTdee => real()();
  RealColumn get deficitFraction => real()();
  RealColumn get proteinPerKg => real()();
  RealColumn get fatPerKg => real()();
  RealColumn get baseEnergy => real()();

  /// 7-letter H/M/L code (Mon..Sun) for carb cycling.
  TextColumn get schedule => text().nullable()();
  RealColumn get carbAmplitudeG => real().nullable()();
  IntColumn get taperStage => integer().withDefault(const Constant(0))();
  TextColumn get observationStart => text().nullable()();
  IntColumn get observationDays => integer().withDefault(const Constant(14))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  IntColumn get legacyCalories => integer().nullable()();
}

/// Per-day resolved target snapshot (history stays fixed once written).
@DataClassName('DailyNutritionTargetRow')
class DailyNutritionTargets extends Table {
  TextColumn get date => text()();
  IntColumn get planId => integer().nullable()();
  IntColumn get planVersion => integer().nullable()();
  TextColumn get strategy => text().nullable()();
  TextColumn get dayType => text().nullable()();
  RealColumn get calories => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbG => real()();
  RealColumn get fatG => real()();
  RealColumn get estimatedTdee => real().nullable()();
  TextColumn get source => text()();
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}

/// User confirmation that a day's diet log is complete (unknown when absent).
@DataClassName('DayDietConfirmationRow')
class DayDietConfirmations extends Table {
  TextColumn get date => text()();
  BoolColumn get complete => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
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
