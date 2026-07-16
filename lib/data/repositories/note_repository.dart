import 'package:drift/drift.dart';

import '../db.dart';

class NoteRepository {
  NoteRepository(this._db);

  final AppDatabase _db;

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  Stream<List<DailyNote>> watchAll() {
    return (_db.select(_db.dailyNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<DailyNote?> getByDate(DateTime day) {
    final start = _dayStart(day);
    return (_db.select(_db.dailyNotes)..where((t) => t.date.equals(start)))
        .getSingleOrNull();
  }

  Future<int> upsert({
    required DateTime date,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) throw ArgumentError('便签内容不能为空');

    final day = _dayStart(date);
    final now = DateTime.now();
    final existing = await getByDate(day);
    if (existing != null) {
      await (_db.update(_db.dailyNotes)..where((t) => t.id.equals(existing.id)))
          .write(
            DailyNotesCompanion(
              content: Value(trimmed),
              updatedAt: Value(now),
            ),
          );
      return existing.id;
    }
    return _db.into(_db.dailyNotes).insert(
          DailyNotesCompanion.insert(
            date: day,
            content: trimmed,
            updatedAt: now,
          ),
        );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.dailyNotes)..where((t) => t.id.equals(id))).go();

  Future<void> deleteByDate(DateTime day) async {
    final start = _dayStart(day);
    await (_db.delete(_db.dailyNotes)..where((t) => t.date.equals(start))).go();
  }

  /// Saves trimmed content, or deletes the day note when content is empty.
  Future<void> saveOrClear({
    required DateTime date,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      await deleteByDate(date);
      return;
    }
    await upsert(date: date, content: trimmed);
  }

  Future<void> clearAll() => _db.delete(_db.dailyNotes).go();
}
