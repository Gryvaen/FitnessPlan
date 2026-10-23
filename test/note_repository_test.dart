import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/note_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'record and plan persist independently; clearing either preserves the other',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = NoteRepository(db);
      final day = DateTime.now();
      await repo.saveOrClear(date: day, content: '记录');
      await repo.saveOrClear(date: day, content: '1. 计划', mode: 'plan');
      expect((await repo.getByDate(day))!.content, '记录');
      expect((await repo.getByDate(day, mode: 'plan'))!.content, '1. 计划');
      await repo.saveOrClear(date: day, content: '记录更新');
      expect((await repo.getByDate(day, mode: 'plan'))!.content, '1. 计划');
      await repo.saveOrClear(date: day, content: '');
      expect(await repo.getByDate(day), isNull);
      expect((await repo.getByDate(day, mode: 'plan'))!.content, '1. 计划');
      await repo.saveOrClear(date: day, content: '新记录');
      await repo.saveOrClear(date: day, content: '', mode: 'plan');
      expect((await repo.getByDate(day))!.content, '新记录');
      expect(await repo.getByDate(day, mode: 'plan'), isNull);
    },
  );

  for (final mode in ['record', 'plan']) {
    test('v35 migration retains $mode and permits a second mode', () async {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (native) {
            native.execute('''CREATE TABLE daily_notes (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL UNIQUE, content TEXT NOT NULL,
        updated_at INTEGER NOT NULL, mode TEXT NOT NULL DEFAULT 'record'
      )''');
            native.execute(
              'INSERT INTO daily_notes (date, content, updated_at, mode) VALUES (?, ?, ?, ?)',
              [
                day.millisecondsSinceEpoch ~/ 1000,
                '原有内容',
                now.millisecondsSinceEpoch ~/ 1000,
                mode,
              ],
            );
            native.execute('PRAGMA user_version = 35');
          },
        ),
      );
      addTearDown(db.close);
      final repo = NoteRepository(db);
      expect((await repo.getByDate(day, mode: mode))!.content, '原有内容');
      final other = mode == 'record' ? 'plan' : 'record';
      await repo.saveOrClear(date: day, content: '独立内容', mode: other);
      expect((await repo.getByDate(day, mode: mode))!.content, '原有内容');
      expect((await repo.getByDate(day, mode: other))!.content, '独立内容');
    });
  }
}
