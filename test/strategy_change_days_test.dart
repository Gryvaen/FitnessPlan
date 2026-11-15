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
  final today = DateTime(2026, 11, 14);
  final d1 = DateTime(2026, 10, 1);
  final d2 = DateTime(2026, 10, 20);

  test('each version that took effect marks its first day', () {
    final days = strategyChangeDays([
      _plan(1, d1, endedOn: d2),
      _plan(2, d2, status: DietPlanStatus.active),
    ], today: today);
    expect(days, {d1, d2});
  });

  test('a scheduled future switch is not marked yet', () {
    final future = DateTime(2026, 11, 20);
    final days = strategyChangeDays([
      _plan(1, d1, endedOn: future),
      _plan(2, future, status: DietPlanStatus.active),
    ], today: today);
    expect(days, {d1});
  });

  test('a version replaced before it started is skipped', () {
    final days = strategyChangeDays([
      _plan(1, d1, endedOn: d2),
      // Scheduled for d2 but superseded on the same day: zero length.
      _plan(2, d2, endedOn: d2),
      _plan(3, DateTime(2026, 10, 25), status: DietPlanStatus.active),
    ], today: today);
    expect(days, {d1, DateTime(2026, 10, 25)});
  });

  test('several versions saved on one day collapse into one', () {
    final days = strategyChangeDays([
      _plan(1, d1, endedOn: d2),
      _plan(2, d2, endedOn: DateTime(2026, 10, 21)),
      _plan(3, DateTime(2026, 10, 21), status: DietPlanStatus.active),
    ], today: today);
    expect(days, {d1, d2, DateTime(2026, 10, 21)});
    final sameDay = strategyChangeDays([
      _plan(1, today, endedOn: today),
      _plan(2, today, status: DietPlanStatus.active),
    ], today: today);
    expect(sameDay, {today});
  });

  test('stopping a strategy adds no day', () {
    final days = strategyChangeDays([
      _plan(1, d1, endedOn: d2, status: DietPlanStatus.stopped),
    ], today: today);
    expect(days, {d1});
  });

  test('time-of-day components are dropped', () {
    final days = strategyChangeDays([
      _plan(1, DateTime(2026, 10, 1, 13, 30), status: DietPlanStatus.active),
    ], today: DateTime(2026, 11, 14, 8));
    expect(days, {d1});
  });
}
