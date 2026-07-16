import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db.dart';

const kDefaultWaterGoalMl = 2000;
const _waterGoalKey = 'water_goal_ml';

class WaterRepository {
  WaterRepository(this._db, this._prefs);

  final AppDatabase _db;
  final SharedPreferences _prefs;

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  int getGoalMl() => _prefs.getInt(_waterGoalKey) ?? kDefaultWaterGoalMl;

  Future<void> setGoalMl(int ml) async {
    final clamped = ml.clamp(500, 5000);
    await _prefs.setInt(_waterGoalKey, clamped);
  }

  Future<int> mlForDay(DateTime day) async {
    final key = _dayStart(day);
    final row = await (_db.select(_db.waterLogs)
          ..where((t) => t.date.equals(key)))
        .getSingleOrNull();
    return row?.ml ?? 0;
  }

  Stream<int> watchMlForDay(DateTime day) {
    final key = _dayStart(day);
    return (_db.select(_db.waterLogs)..where((t) => t.date.equals(key)))
        .watch()
        .map((rows) => rows.isEmpty ? 0 : rows.first.ml);
  }

  Future<void> setMlForDay(DateTime day, int ml) async {
    final key = _dayStart(day);
    final value = ml < 0 ? 0 : ml;
    final existing = await (_db.select(_db.waterLogs)
          ..where((t) => t.date.equals(key)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.waterLogs).insert(
            WaterLogsCompanion.insert(date: key, ml: value),
          );
    } else {
      await (_db.update(_db.waterLogs)..where((t) => t.id.equals(existing.id)))
          .write(WaterLogsCompanion(ml: Value(value)));
    }
  }

  Future<int> addMl(DateTime day, int delta) async {
    final current = await mlForDay(day);
    final next = (current + delta).clamp(0, 20000);
    await setMlForDay(day, next);
    return next;
  }

  Future<void> clearAll() => _db.delete(_db.waterLogs).go();
}
