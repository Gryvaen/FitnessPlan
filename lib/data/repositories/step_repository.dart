import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../db.dart';

class StepDay {
  const StepDay({required this.date, required this.steps});

  final DateTime date;
  final int steps;
}

class StepRepository {
  StepRepository(this._db);

  final AppDatabase _db;

  DateTime _dayStart(DateTime d) => CalendarDay.dayOnly(d);

  Future<int> stepsForDay(DateTime day) async {
    final key = _dayStart(day);
    final row = await (_db.select(_db.stepLogs)
          ..where((t) => t.date.equals(key)))
        .getSingleOrNull();
    return row?.steps ?? 0;
  }

  Stream<int> watchStepsForDay(DateTime day) {
    final key = _dayStart(day);
    return (_db.select(_db.stepLogs)..where((t) => t.date.equals(key)))
        .watch()
        .map((rows) => rows.isEmpty ? 0 : rows.first.steps);
  }

  /// Upsert daily steps. Allows historical days (system health backfill).
  Future<void> setStepsForDay(DateTime day, int steps) async {
    final key = _dayStart(day);
    final value = steps < 0 ? 0 : steps;
    final existing = await (_db.select(_db.stepLogs)
          ..where((t) => t.date.equals(key)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.stepLogs).insert(
            StepLogsCompanion.insert(date: key, steps: value),
          );
    } else {
      await (_db.update(_db.stepLogs)..where((t) => t.id.equals(existing.id)))
          .write(StepLogsCompanion(steps: Value(value)));
    }
  }

  /// Continuous local calendar days ending today (newest first), missing → 0.
  Future<List<StepDay>> recentDays({int limitDays = 14}) async {
    final today = CalendarDay.todayLocal();
    final oldest = today.subtract(Duration(days: limitDays - 1));
    final rows = await (_db.select(_db.stepLogs)
          ..where((t) => t.date.isBiggerOrEqualValue(oldest))
          ..where((t) => t.date.isSmallerOrEqualValue(today)))
        .get();
    final byDay = <DateTime, int>{
      for (final row in rows) _dayStart(row.date): row.steps,
    };
    final out = <StepDay>[];
    for (var i = 0; i < limitDays; i++) {
      final date = CalendarDay.dayOnly(today.subtract(Duration(days: i)));
      out.add(StepDay(date: date, steps: byDay[date] ?? 0));
    }
    return out;
  }

  Stream<List<StepDay>> watchRecentDays({int limitDays = 14}) {
    return _db.select(_db.stepLogs).watch().asyncMap(
          (_) => recentDays(limitDays: limitDays),
        );
  }

  Future<void> clearAll() => _db.delete(_db.stepLogs).go();
}
