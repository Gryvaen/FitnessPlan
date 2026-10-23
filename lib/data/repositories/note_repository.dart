import 'package:drift/drift.dart';

import '../../domain/calendar_day.dart';
import '../db.dart';

class NoteRepository {
  NoteRepository(this._db);

  final AppDatabase _db;

  DateTime _dayStart(DateTime d) => CalendarDay.dayOnly(d);

  Stream<List<DailyNote>> watchAll() {
    return (_db.select(
      _db.dailyNotes,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  Future<DailyNote?> getByDate(DateTime day, {String mode = 'record'}) {
    final start = _dayStart(day);
    return (_db.select(_db.dailyNotes)
          ..where((t) => t.date.equals(start) & t.mode.equals(mode)))
        .getSingleOrNull();
  }

  Future<DailyNote?> byId(int id) {
    return (_db.select(
      _db.dailyNotes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> upsert({
    required DateTime date,
    required String content,
    String mode = 'record',
  }) async {
    CalendarDay.ensureEditableDay(date);
    final trimmed = content.trim();
    if (trimmed.isEmpty) throw ArgumentError('便签内容不能为空');

    final day = _dayStart(date);
    final now = DateTime.now();
    final existing = await getByDate(day, mode: mode);
    if (existing != null) {
      await (_db.update(
        _db.dailyNotes,
      )..where((t) => t.id.equals(existing.id))).write(
        DailyNotesCompanion(
          content: Value(trimmed),
          mode: Value(mode),
          updatedAt: Value(now),
        ),
      );
      return existing.id;
    }
    return _db
        .into(_db.dailyNotes)
        .insert(
          DailyNotesCompanion.insert(
            date: day,
            content: trimmed,
            updatedAt: now,
            mode: Value(mode),
          ),
        );
  }

  Future<void> delete(int id) async {
    final existing = await byId(id);
    if (existing == null) return;
    CalendarDay.ensureEditableDay(existing.date);
    await (_db.delete(_db.dailyNotes)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteByDate(DateTime day, {String mode = 'record'}) async {
    CalendarDay.ensureEditableDay(day);
    final start = _dayStart(day);
    await (_db.delete(
      _db.dailyNotes,
    )..where((t) => t.date.equals(start) & t.mode.equals(mode))).go();
  }

  /// Saves trimmed content, or deletes the day note when content is empty.
  Future<void> saveOrClear({
    required DateTime date,
    required String content,
    String mode = 'record',
  }) async {
    CalendarDay.ensureEditableDay(date);
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      await deleteByDate(date, mode: mode);
      return;
    }
    await upsert(date: date, content: trimmed, mode: mode);
  }

  Future<void> clearAll() => _db.delete(_db.dailyNotes).go();
}
