import 'dart:io';

import 'package:drift/drift.dart'
    show QueryExecutor, QueryExecutorUser, OpeningDetails;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/day_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DayMarkerRepository repo;
  final today = CalendarDay.todayLocal();
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DayMarkerRepository(db);
  });

  tearDown(() => db.close());

  test('unset day has no marker', () async {
    expect(await repo.markerForDay(today), isNull);
  });

  test('setCheatMeal works for past, today and future', () async {
    await repo.setCheatMeal(yesterday);
    await repo.setCheatMeal(today);
    await repo.setCheatMeal(tomorrow);
    expect(await repo.markerForDay(yesterday), DayMarkerType.cheatMeal);
    expect(await repo.markerForDay(today), DayMarkerType.cheatMeal);
    expect(await repo.markerForDay(tomorrow), DayMarkerType.cheatMeal);
  });

  test('setRestDay allows past, today and future', () async {
    await repo.setRestDay(yesterday);
    expect(await repo.markerForDay(yesterday), DayMarkerType.restDay);
    await repo.setRestDay(today);
    expect(await repo.markerForDay(today), DayMarkerType.restDay);
    await repo.setRestDay(tomorrow);
    expect(await repo.markerForDay(tomorrow), DayMarkerType.restDay);
  });

  test(
    'setting a new type overwrites the previous marker (mutually exclusive)',
    () async {
      await repo.setCheatMeal(today);
      expect(await repo.markerForDay(today), DayMarkerType.cheatMeal);
      await repo.setRestDay(today);
      expect(await repo.markerForDay(today), DayMarkerType.restDay);
    },
  );

  test('clear removes the marker', () async {
    await repo.setCheatMeal(today);
    await repo.clear(today);
    expect(await repo.markerForDay(today), isNull);
  });

  test('clearAll removes every marker', () async {
    await repo.setCheatMeal(yesterday);
    await repo.setRestDay(today);
    await repo.clearAll();
    expect(await repo.markerForDay(yesterday), isNull);
    expect(await repo.markerForDay(today), isNull);
  });

  test(
    'markersBetween returns only markers within the inclusive range',
    () async {
      await repo.setCheatMeal(yesterday);
      await repo.setRestDay(today);
      await repo.setRestDay(tomorrow);
      final map = await repo.markersBetween(today, tomorrow);
      expect(map.length, 2);
      expect(map[today], DayMarkerType.restDay);
      expect(map[tomorrow], DayMarkerType.restDay);
      expect(map.containsKey(yesterday), isFalse);
    },
  );

  test('markersBetween with end before start returns empty', () async {
    await repo.setCheatMeal(today);
    expect(await repo.markersBetween(tomorrow, today), isEmpty);
  });

  test('restDayDates returns every rest day regardless of range', () async {
    await repo.setCheatMeal(yesterday);
    await repo.setRestDay(today, pauseCarbCycle: true);
    await repo.setRestDay(tomorrow, pauseCarbCycle: true);
    final dates = await repo.restDayDates();
    expect(dates.toSet(), {today, tomorrow});
  });

  test(
    'restDayDates excludes a rest day backfilled onto an already-past date',
    () async {
      // Marked "now" (today), but for a date that was already in the past —
      // a historical record only, must not count toward progression.
      await repo.setRestDay(yesterday, pauseCarbCycle: true, now: today);
      expect(await repo.markerForDay(yesterday), DayMarkerType.restDay);
      expect(await repo.restDayDates(), isEmpty);
    },
  );

  test(
    'restDayDates includes a past rest day marked contemporaneously',
    () async {
      // Marked on its own day (was today-or-future at marking time), and has
      // since become "past" — still counts toward progression.
      await repo.setRestDay(yesterday, pauseCarbCycle: true, now: yesterday);
      final dates = await repo.restDayDates();
      expect(dates, [yesterday]);
    },
  );

  test('new markers default to the editable settings', () async {
    await repo.setRestDay(today);
    expect(await repo.restDayDates(), isEmpty);
    expect((await repo.settingsForDay(today))!.excludeContributions, isFalse);
    await repo.setCheatMeal(tomorrow);
    final cheat = (await repo.settingsForDay(tomorrow))!;
    expect(cheat.penaltyKcal, -1000);
    expect(cheat.excludeContributions, isFalse);
  });

  test('rest-day edits retain original progression eligibility', () async {
    await repo.setRestDay(yesterday, pauseCarbCycle: true, now: yesterday);
    await repo.setRestDay(yesterday, pauseCarbCycle: false, now: today);
    expect(await repo.restDayDates(), isEmpty);
    await repo.setRestDay(yesterday, pauseCarbCycle: true, now: today);
    expect(await repo.restDayDates(), [yesterday]);
  });

  test('penalty amount and disabled state persist across reads', () async {
    await repo.setCheatMeal(today, deductKcal: false, penaltyKcal: 650);
    final stored = (await repo.settingsForDay(today))!;
    expect(stored.cheatPenaltyKcal, 650);
    expect(stored.penaltyKcal, 0);
    await repo.setCheatMeal(today, penaltyKcal: stored.cheatPenaltyKcal);
    expect((await repo.settingsForDay(today))!.penaltyKcal, -650);
  });

  test('legacy rows keep their original defaults until edited', () async {
    await db
        .into(db.dayMarkers)
        .insert(
          DayMarkersCompanion.insert(
            date:
                '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
            type: DayMarkerType.restDay.name,
            updatedAt: today,
          ),
        );
    final old = (await repo.settingsForDay(today))!;
    expect(old.pauseCarbCycle, isTrue);
    expect(old.excludeContributions, isTrue);
    await repo.setRestDay(today, pauseCarbCycle: false);
    final edited = (await repo.settingsForDay(today))!;
    expect(edited.pauseCarbCycle, isFalse);
    expect(edited.excludeContributions, isFalse);
  });

  test('v29 marker rows migrate with legacy behavior intact', () async {
    final dir = await Directory.systemTemp.createTemp('marker-v29-');
    final file = File('${dir.path}/markers.sqlite');
    final seed = AppDatabase.forTesting(NativeDatabase(file));
    await seed.select(seed.dayMarkers).get();
    await seed.close();
    final oldDb = NativeDatabase(file);
    await oldDb.ensureOpen(_V29User());
    await oldDb.runCustom('DROP TABLE day_markers');
    await oldDb.runCustom('''
CREATE TABLE day_markers (
  date TEXT NOT NULL PRIMARY KEY,
  type TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)''');
    await oldDb.runCustom(
      "INSERT INTO day_markers VALUES ('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}', 'restDay', ${today.millisecondsSinceEpoch ~/ 1000})",
    );
    await oldDb.runCustom('PRAGMA user_version = 29');
    await oldDb.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(() async {
      await migrated.close();
      await dir.delete(recursive: true);
    });
    final old = (await DayMarkerRepository(migrated).settingsForDay(today))!;
    expect(old.pauseCarbCycle, isTrue);
    expect(old.excludeContributions, isTrue);
    expect(old.penaltyKcal, 0);
  });

  test('watchMarkerForDay emits updates', () async {
    final stream = repo.watchMarkerForDay(today);
    final emissions = <DayMarkerType?>[];
    final sub = stream.listen(emissions.add);
    await Future<void>.delayed(Duration.zero);
    await repo.setCheatMeal(today);
    await Future<void>.delayed(Duration.zero);
    await repo.clear(today);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(emissions, [null, DayMarkerType.cheatMeal, null]);
  });
}

class _V29User extends QueryExecutorUser {
  @override
  int get schemaVersion => 29;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
