import 'package:drift/drift.dart';

import '../db.dart';

class WeightRepository {
  WeightRepository(this._db);

  final AppDatabase _db;

  Stream<List<WeightLog>> watchAll() {
    return (_db.select(
      _db.weightLogs,
    )..orderBy([(t) => OrderingTerm.asc(t.date)])).watch();
  }

  Future<List<WeightLog>> all() {
    return (_db.select(
      _db.weightLogs,
    )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();
  }

  /// A day has one effective weight. Re-recording it updates that value.
  Future<int> add({
    required DateTime date,
    required double weightKg,
    double? bodyFatPct,
    int? exerciseMinutes,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final existing = await (_db.select(
      _db.weightLogs,
    )..where((t) => t.date.equals(day))).getSingleOrNull();
    final companion = WeightLogsCompanion(
      weightKg: Value(weightKg),
      bodyFatPct: Value(bodyFatPct),
      exerciseMinutes: Value(exerciseMinutes),
    );
    if (existing != null) {
      await (_db.update(_db.weightLogs)..where((t) => t.id.equals(existing.id)))
          .write(companion);
      return existing.id;
    }
    return _db.into(_db.weightLogs).insert(
          WeightLogsCompanion.insert(
            date: day,
            weightKg: weightKg,
            bodyFatPct: Value(bodyFatPct),
            exerciseMinutes: Value(exerciseMinutes),
          ),
        );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.weightLogs)..where((t) => t.id.equals(id))).go();
}
