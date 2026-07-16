import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../db.dart';

class WeightRepository {
  WeightRepository(this._db);

  final AppDatabase _db;

  Stream<List<WeightLog>> watchAll() {
    return (_db.select(
      _db.weightLogs,
    )..orderBy([(t) => OrderingTerm.asc(t.date)])).watch();
  }

  /// A day has one effective weight. Re-recording it updates that value.
  Future<int> add({
    required DateTime date,
    required double weightKg,
    double? bodyFatPct,
    int? exerciseMinutes,
  }) async {
    CalendarDay.ensureEditableDay(date);
    final day = CalendarDay.dayOnly(date);
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

  Future<WeightLog?> getByDate(DateTime date) async {
    final day = CalendarDay.dayOnly(date);
    return (_db.select(_db.weightLogs)
          ..where((t) => t.date.equals(day)))
        .getSingleOrNull();
  }

  Future<WeightLog?> byId(int id) {
    return (_db.select(_db.weightLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Updates [bodyFatPct] on an existing day log. Returns false if none.
  Future<bool> updateBodyFatForDate(DateTime date, double bodyFatPct) async {
    CalendarDay.ensureEditableDay(date);
    final existing = await getByDate(date);
    if (existing == null) return false;
    await (_db.update(_db.weightLogs)..where((t) => t.id.equals(existing.id)))
        .write(WeightLogsCompanion(bodyFatPct: Value(bodyFatPct)));
    return true;
  }

  Future<void> delete(int id) async {
    final existing = await byId(id);
    if (existing == null) return;
    CalendarDay.ensureEditableDay(existing.date);
    await (_db.delete(_db.weightLogs)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() => _db.delete(_db.weightLogs).go();
}
