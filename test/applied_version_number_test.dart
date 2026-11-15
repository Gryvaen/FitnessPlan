import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

DietStrategyPlan _plan(
  int version,
  DateTime from, {
  DateTime? endedOn,
  DietPlanStatus status = DietPlanStatus.superseded,
}) => DietStrategyPlan(
  id: version,
  version: version,
  kind: DietStrategyKind.balanced,
  status: status,
  effectiveFrom: from,
  endedOn: endedOn,
  createdAt: from,
  referenceWeightKg: 70,
  estimatedTdee: 2500,
  deficitFraction: 0.2,
  proteinPerKg: 2,
  fatPerKg: 0.8,
  baseEnergy: 2000,
  schedule: null,
  carbCycleRates: null,
  taperStage: 0,
  observationStart: null,
  observationDays: 14,
  reason: '',
  legacyCalories: null,
);

void main() {
  final d1 = DateTime(2026, 10, 1);
  final d2 = DateTime(2026, 10, 10);
  final d3 = DateTime(2026, 10, 20);

  test('versions that each governed days count 1, 2, 3', () {
    final plans = [
      _plan(1, d1, endedOn: d2),
      _plan(2, d2, endedOn: d3),
      _plan(3, d3, status: DietPlanStatus.active),
    ];
    expect([for (final p in plans) appliedVersionNumber(p, plans)], [1, 2, 3]);
  });

  test('re-applying on the same day keeps the number', () {
    final plans = [
      _plan(1, d1, endedOn: d1),
      _plan(2, d1, endedOn: d1),
      _plan(3, d1, status: DietPlanStatus.active),
    ];
    expect(appliedVersionNumber(plans.last, plans), 1);
  });

  test('a scheduled switch counts as the next number, and replacing it '
      'before it starts keeps that number', () {
    final first = _plan(1, d1, endedOn: d3);
    final scheduled = _plan(2, d3, status: DietPlanStatus.active);
    expect(appliedVersionNumber(scheduled, [first, scheduled]), 2);

    final replaced = _plan(2, d3, endedOn: d3);
    final again = _plan(3, d3, status: DietPlanStatus.active);
    final plans = [first, replaced, again];
    expect(appliedVersionNumber(again, plans), 2);
  });

  test('a stopped version that ran still counts; a same-day stop does not', () {
    final ran = _plan(1, d1, endedOn: d2, status: DietPlanStatus.stopped);
    final instant = _plan(2, d2, endedOn: d2, status: DietPlanStatus.stopped);
    final next = _plan(3, d3, status: DietPlanStatus.active);
    final plans = [ran, instant, next];
    expect(appliedVersionNumber(ran, plans), 1);
    expect(appliedVersionNumber(next, plans), 2);
  });

  test('a plan missing from a lagging list still counts itself', () {
    final first = _plan(1, d1, endedOn: d2);
    final fresh = _plan(2, d2, status: DietPlanStatus.active);
    expect(appliedVersionNumber(fresh, [first]), 2);
    expect(appliedVersionNumber(fresh, const []), 1);
  });

  test('spansAnyDay ignores time of day', () {
    expect(
      _plan(
        1,
        DateTime(2026, 10, 1, 9),
        endedOn: DateTime(2026, 10, 1, 20),
      ).spansAnyDay,
      isFalse,
    );
    expect(_plan(1, d1, endedOn: d2).spansAnyDay, isTrue);
    expect(_plan(1, d1).spansAnyDay, isTrue);
  });
}
