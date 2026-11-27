import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/step_repository.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/ui/records/train_history_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 27);
  DateTime ago(int n) => DateTime(today.year, today.month, today.day - n);

  group('stepChartData', () {
    test('lays days out on the calendar with zero bars for gaps', () {
      final data = stepChartData([
        StepDay(date: ago(3), steps: 6000),
        StepDay(date: ago(1), steps: 0),
        StepDay(date: today, steps: 8000),
      ], today: today);
      expect(data.weekly, isFalse);
      expect(data.bars.map((b) => b.date), [ago(3), ago(2), ago(1), today]);
      expect(data.bars.map((b) => b.steps), [6000, 0, 0, 8000]);
      // Average only counts days that have steps.
      expect(data.dailyAverage, 7000);
    });

    test('runs up to today even when today has no record yet', () {
      final data = stepChartData([
        StepDay(date: ago(2), steps: 5000),
      ], today: today);
      expect(data.bars.last.date, today);
      expect(data.bars, hasLength(3));
    });

    test('switches to Monday weeks of daily averages past 60 days', () {
      final first = ago(kStepChartWeeklyAfterDays + 10);
      final data = stepChartData([
        StepDay(date: first, steps: 4000),
        StepDay(
          date: DateTime(first.year, first.month, first.day + 1),
          steps: 6000,
        ),
        StepDay(date: today, steps: 9000),
      ], today: today);
      expect(data.weekly, isTrue);
      for (final bar in data.bars) {
        expect(bar.date.weekday, DateTime.monday);
      }
      expect(data.bars.last.steps, 9000);
      // The first week averages only its two logged days.
      final firstWeek = data.bars.firstWhere((b) => b.steps > 0);
      expect(firstWeek.steps, 5000);
      expect(data.dailyAverage, closeTo((4000 + 6000 + 9000) / 3, 0.01));
    });

    test('is empty when nothing was walked', () {
      final data = stepChartData([
        StepDay(date: today, steps: 0),
      ], today: today);
      expect(data.isEmpty, isTrue);
    });
  });

  group('planChartRows', () {
    WorkoutHistoryDay planDay(DateTime date, List<(String?, int, int)> plans) =>
        WorkoutHistoryDay(
          date: date,
          sets: const [],
          planSummaries: [
            for (final (name, done, total) in plans)
              WorkoutHistoryPlanSummary(
                planId: null,
                planName: name,
                doneCount: done,
                totalCount: total,
              ),
          ],
        );

    test('counts days per plan and sums completion, most trained first', () {
      final rows = planChartRows([
        planDay(ago(4), [('推日', 4, 5)]),
        planDay(ago(3), [('腿日', 3, 6)]),
        planDay(ago(2), [('推日', 5, 5), ('腿日', 3, 6)]),
        planDay(today, [('推日', 3, 5)]),
      ], untitled: '其他');
      expect(rows.map((r) => r.name), ['推日', '腿日']);
      expect(rows[0].days, 3);
      expect(rows[0].completion, closeTo(12 / 15, 1e-9));
      expect(rows[1].days, 2);
      expect(rows[1].completion, closeTo(.5, 1e-9));
    });

    test('unnamed plans and plan-less days go under the untitled row', () {
      final freeForm = WorkoutHistoryDay(
        date: ago(1),
        sets: [
          WorkoutSetLog(
            id: 1,
            date: ago(1),
            exerciseId: 1,
            exerciseName: '深蹲',
            setIndex: 0,
          ),
        ],
      );
      final rows = planChartRows([
        planDay(ago(2), [('  ', 2, 4)]),
        freeForm,
        WorkoutHistoryDay(date: today, sets: const []), // no activity
      ], untitled: '其他');
      expect(rows, hasLength(1));
      expect(rows.single.name, '其他');
      expect(rows.single.days, 2);
      expect(rows.single.completion, closeTo(.5, 1e-9));
    });

    test('free-form only training has no completion share', () {
      final rows = planChartRows([
        WorkoutHistoryDay(
          date: today,
          sets: [
            WorkoutSetLog(
              id: 1,
              date: today,
              exerciseId: 1,
              exerciseName: '深蹲',
              setIndex: 0,
            ),
          ],
        ),
      ], untitled: '其他');
      expect(rows.single.completion, isNull);
    });
  });
}
