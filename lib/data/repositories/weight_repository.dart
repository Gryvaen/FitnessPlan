import 'package:drift/drift.dart';

import '../db.dart';

class WeightRepository {
  WeightRepository(this._db);

  final AppDatabase _db;

  Stream<List<WeightLog>> watchAll() {
    return (_db.select(_db.weightLogs)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<List<WeightLog>> all() {
    return (_db.select(_db.weightLogs)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<int> add({required DateTime date, required double weightKg}) {
    final day = DateTime(date.year, date.month, date.day);
    return _db.into(_db.weightLogs).insert(
          WeightLogsCompanion.insert(date: day, weightKg: weightKg),
        );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.weightLogs)..where((t) => t.id.equals(id))).go();
}
