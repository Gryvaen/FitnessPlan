import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/goal_period.dart';
import 'package:diet/domain/maintain_balance.dart';
import 'package:diet/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int day) => DateTime(2026, 10, day);

void main() {
  group('mergeGoalPeriodsIntoSegments', () {
    test('adds closed stretches of the goal that overlap nothing', () {
      final r = mergeGoalPeriodsIntoSegments(
        [CutCultivationSegment(start: d(20))],
        [
          GoalPeriod(goal: FitnessGoal.maintain, start: d(1), end: d(5)),
          GoalPeriod(goal: FitnessGoal.cut, start: d(6), end: d(9)),
          GoalPeriod(goal: FitnessGoal.maintain, start: d(10), end: d(19)),
          GoalPeriod(goal: FitnessGoal.maintain, start: d(20)),
        ],
        FitnessGoal.maintain,
      );
      expect(r.addedClosed.map((s) => (s.start, s.end)), [
        (d(1), d(5)),
        (d(10), d(19)),
      ]);
      expect(r.segments.map((s) => s.start), [d(1), d(10), d(20)]);
      expect(r.segments.last.isOpen, isTrue);
    });

    test('overlapping stretches are skipped — the ledger wins', () {
      final r = mergeGoalPeriodsIntoSegments(
        [CutCultivationSegment(start: d(3), end: d(8))],
        [GoalPeriod(goal: FitnessGoal.cut, start: d(1), end: d(5))],
        FitnessGoal.cut,
      );
      expect(r.addedClosed, isEmpty);
      expect(r.segments, hasLength(1));
      expect(r.segments.single.start, d(3));
    });

    test('open stretch moves the open segment back, not past a closed one', () {
      var r = mergeGoalPeriodsIntoSegments(
        [CutCultivationSegment(start: d(20))],
        [GoalPeriod(goal: FitnessGoal.cut, start: d(12))],
        FitnessGoal.cut,
      );
      expect(r.segments.single.start, d(12));
      expect(r.segments.single.isOpen, isTrue);

      r = mergeGoalPeriodsIntoSegments(
        [
          CutCultivationSegment(start: d(1), end: d(14)),
          CutCultivationSegment(start: d(20)),
        ],
        [GoalPeriod(goal: FitnessGoal.cut, start: d(10))],
        FitnessGoal.cut,
      );
      expect(r.segments.last.start, d(15));
    });

    test('an open stretch of another goal changes nothing', () {
      final r = mergeGoalPeriodsIntoSegments(
        [CutCultivationSegment(start: d(20))],
        [GoalPeriod(goal: FitnessGoal.bulk, start: d(1))],
        FitnessGoal.cut,
      );
      expect(r.segments.single.start, d(20));
      expect(r.addedClosed, isEmpty);
    });
  });

  final periods = [
    GoalPeriod(goal: FitnessGoal.maintain, start: d(1), end: d(5)),
    GoalPeriod(goal: FitnessGoal.cut, start: d(6), end: d(9)),
  ];

  test('maintain import runs once and survives json', () {
    final first = importMaintainGoalPeriods(
      const MaintainCultivationState(),
      periods,
    );
    expect(first.addedClosed, hasLength(1));
    expect(first.state.goalPeriodsImported, isTrue);
    final again = importMaintainGoalPeriods(first.state, periods);
    expect(again.addedClosed, isEmpty);
    expect(identical(again.state, first.state), isTrue);
    final back = MaintainCultivationState.fromJson(first.state.toJson());
    expect(back.goalPeriodsImported, isTrue);
    expect(
      MaintainCultivationState.fromJson(const {}).goalPeriodsImported,
      isFalse,
    );
  });

  test('cut import runs once and survives json', () {
    final first = importCutGoalPeriods(const CutCultivationState(), periods);
    expect(first.addedClosed.single.start, d(6));
    expect(first.state.goalPeriodsImported, isTrue);
    final again = importCutGoalPeriods(first.state, periods);
    expect(again.addedClosed, isEmpty);
    expect(
      CutCultivationState.fromJson(first.state.toJson()).goalPeriodsImported,
      isTrue,
    );
    expect(
      CutCultivationState.fromJson(const {}).goalPeriodsImported,
      isFalse,
    );
  });
}
