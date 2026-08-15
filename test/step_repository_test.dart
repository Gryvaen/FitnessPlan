import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/step_repository.dart';
import 'package:diet/domain/calendar_day.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late StepRepository steps;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    steps = StepRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('stepsForDay returns 0 when no row', () async {
    final day = CalendarDay.todayLocal();
    expect(await steps.stepsForDay(day), 0);
  });

  test('setStepsForDay upserts and allows historical days', () async {
    final today = CalendarDay.todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));

    await steps.setStepsForDay(today, 1200);
    await steps.setStepsForDay(yesterday, 800);
    expect(await steps.stepsForDay(today), 1200);
    expect(await steps.stepsForDay(yesterday), 800);

    await steps.setStepsForDay(today, 1500);
    expect(await steps.stepsForDay(today), 1500);
  });

  test('recentDays returns continuous 14 days with missing as 0', () async {
    final today = CalendarDay.todayLocal();
    await steps.setStepsForDay(today, 3000);
    await steps.setStepsForDay(
      today.subtract(const Duration(days: 2)),
      1000,
    );

    final recent = await steps.recentDays(limitDays: 14);
    expect(recent, hasLength(14));
    expect(recent.first.date, today);
    expect(recent.first.steps, 3000);
    expect(recent[1].steps, 0);
    expect(recent[2].steps, 1000);
    expect(recent.last.date, today.subtract(const Duration(days: 13)));
    expect(recent.last.steps, 0);
  });

  test('schema 14 creates step_logs table', () async {
    await steps.setStepsForDay(CalendarDay.todayLocal(), 42);
    final row = await (db.select(db.stepLogs)).getSingle();
    expect(row.steps, 42);
  });
}
