import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';

/// A 冲碳日 marked or cleared on a past carb-cycle day rewrites that day's
/// frozen target (`DietStrategyRepository.syncPastCarbLoadTarget`).
void main() {
  late AppDatabase db;
  late DietStrategyRepository repo;
  late DayMarkerRepository markers;
  final today = CalendarDay.todayLocal();
  final yesterday = CalendarDay.addDays(today, -1);
  final rates = CarbCycleRates.defaults();
  final schedule = CarbCycleSchedule.tryParse('HMLL')!;
  final cyclePlan = CarbCyclePlanner.compute(
    referenceWeightKg: 75,
    rates: rates,
    schedule: schedule,
  );
  final profile = UserProfile(
    sex: Sex.male,
    age: 30,
    heightCm: 178,
    weightKg: 75,
    activity: ActivityLevel.moderate,
    goal: FitnessGoal.cut,
    targets: const MacroTargets(
      calories: 2137,
      proteinG: 150,
      carbG: 240,
      fatG: 60,
    ),
    tdee: 2687,
  );

  DietStrategyPlanDraft draft(DietStrategyKind kind) => DietStrategyPlanDraft(
    kind: kind,
    effectiveFrom: yesterday,
    referenceWeightKg: 75,
    estimatedTdee: 2400,
    baseEnergy: kind == DietStrategyKind.carbCycle
        ? cyclePlan.cycleAverageEnergy
        : 2000,
    schedule: kind == DietStrategyKind.carbCycle ? schedule : null,
    carbCycleRates: kind == DietStrategyKind.carbCycle ? rates : null,
  );

  /// Freezes yesterday's target the way opening the app that day would.
  Future<DailyNutritionTarget> freezeYesterday() async {
    await repo.targetForDay(yesterday, profile, now: yesterday);
    return (await repo.snapshotFor(yesterday))!;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DietStrategyRepository(db);
    markers = DayMarkerRepository(db);
  });
  tearDown(() => db.close());

  test(
    'marking a past day rewrites its frozen target, clearing restores it',
    () async {
      await repo.createPlan(draft(DietStrategyKind.carbCycle), now: yesterday);
      final before = await freezeYesterday();
      expect(before.isCarbLoad, isFalse);
      expect(before.calories, closeTo(cyclePlan.dayAt(0).energy, 1e-6));

      await markers.setCarbLoad(yesterday, carbPerKg: 6);
      await repo.syncPastCarbLoadTarget(yesterday);
      final loaded = (await repo.snapshotFor(yesterday))!;
      final high = cyclePlan.dayFor(CarbDayType.high)!;
      expect(loaded.isCarbLoad, isTrue);
      expect(loaded.reason, 'carbLoad:6.0');
      expect(loaded.carbG, closeTo(75 * 6, 1e-6));
      expect(loaded.proteinG, closeTo(high.proteinG, 1e-6));
      expect(loaded.fatG, closeTo(high.fatG, 1e-6));
      expect(loaded.dayType, CarbDayType.high);
      expect(loaded.cycleIndex, before.cycleIndex);
      expect(loaded.cyclePaused, before.cyclePaused);
      expect((await repo.targetForDay(yesterday, profile))!.isCarbLoad, isTrue);

      await markers.clear(yesterday);
      await repo.syncPastCarbLoadTarget(yesterday);
      final restored = (await repo.snapshotFor(yesterday))!;
      expect(restored.isCarbLoad, isFalse);
      expect(restored.calories, closeTo(before.calories, 1e-6));
      expect(restored.carbG, closeTo(before.carbG, 1e-6));
      expect(restored.dayType, before.dayType);
      expect(restored.cycleIndex, before.cycleIndex);
    },
  );

  test('a rest day on a past day leaves the frozen target alone', () async {
    await repo.createPlan(draft(DietStrategyKind.carbCycle), now: yesterday);
    final before = await freezeYesterday();
    await markers.setRestDay(yesterday);
    await repo.syncPastCarbLoadTarget(yesterday);
    final after = (await repo.snapshotFor(yesterday))!;
    expect(after.calories, before.calories);
    expect(after.reason, before.reason);
  });

  test('manual overrides are never rewritten', () async {
    await repo.createPlan(draft(DietStrategyKind.carbCycle), now: yesterday);
    await repo.setOverride(
      yesterday,
      const DayMacroTarget(
        energy: 1800,
        proteinG: 150,
        carbG: 150,
        fatG: 66.7,
        dayType: CarbDayType.low,
      ),
      now: yesterday,
    );
    await markers.setCarbLoad(yesterday, carbPerKg: 6);
    await repo.syncPastCarbLoadTarget(yesterday);
    final snap = (await repo.snapshotFor(yesterday))!;
    expect(snap.source, TargetSource.override);
    expect(snap.calories, 1800);
  });

  test('non-carb-cycle snapshots are never rewritten', () async {
    await repo.createPlan(draft(DietStrategyKind.balanced), now: yesterday);
    final before = await freezeYesterday();
    await markers.setCarbLoad(yesterday, carbPerKg: 6);
    await repo.syncPastCarbLoadTarget(yesterday);
    final after = (await repo.snapshotFor(yesterday))!;
    expect(after.isCarbLoad, isFalse);
    expect(after.calories, before.calories);
  });

  test('today is left to the regular recomputation', () async {
    await repo.createPlan(draft(DietStrategyKind.carbCycle), now: yesterday);
    await repo.targetForDay(today, profile);
    await markers.setCarbLoad(today, carbPerKg: 6);
    await repo.syncPastCarbLoadTarget(today);
    expect((await repo.snapshotFor(today))!.isCarbLoad, isFalse);
  });
}
