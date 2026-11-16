import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/data/repositories/goal_schedule_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _profile(FitnessGoal goal) => UserProfile(
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 75,
  activity: ActivityLevel.moderate,
  goal: goal,
  targets: const MacroTargets(
    calories: 2400,
    proteinG: 150,
    carbG: 300,
    fatG: 67,
  ),
  tdee: 2400,
  calorieStandardSince: DateTime(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  final today = CalendarDay.todayLocal();
  DateTime daysAgo(int n) => CalendarDay.addDays(today, -n);

  Future<void> setUpWith(FitnessGoal goal) async {
    SharedPreferences.setMockInitialValues({
      'user_profile': jsonEncode(_profile(goal).toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
  }

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<DietStrategyPlan> cutPlanSince(DateTime from) => container
      .read(dietStrategyRepositoryProvider)
      .createPlan(
        DietStrategyPlanDraft(
          kind: DietStrategyKind.balanced,
          effectiveFrom: from,
          referenceWeightKg: 75,
          estimatedTdee: 2400,
          baseEnergy: 2000,
          reason: 'test',
        ),
        // Created back then, so a past start day is allowed.
        now: from,
      );

  Future<void> book(DateTime from) => container
      .read(pendingGoalSwitchProvider.notifier)
      .schedule(PendingGoalSwitch(goal: FitnessGoal.maintain, from: from));

  test('the booking round-trips through prefs and can be cleared', () async {
    await setUpWith(FitnessGoal.cut);
    final tomorrow = CalendarDay.addDays(today, 1);
    await book(tomorrow);
    final loaded = container.read(goalScheduleRepositoryProvider).load();
    expect(loaded?.goal, FitnessGoal.maintain);
    expect(loaded?.from, tomorrow);

    await container.read(pendingGoalSwitchProvider.notifier).clear();
    expect(container.read(goalScheduleRepositoryProvider).load(), isNull);
    expect(container.read(pendingGoalSwitchProvider), isNull);
  });

  test('nothing happens before the booked day', () async {
    await setUpWith(FitnessGoal.cut);
    await cutPlanSince(daysAgo(3));
    await book(CalendarDay.addDays(today, 1));

    expect(await container.read(applyDueGoalSwitchProvider)(), isFalse);
    expect(container.read(profileProvider)!.goal, FitnessGoal.cut);
    expect(container.read(pendingGoalSwitchProvider), isNotNull);
    expect(
      await container.read(dietStrategyRepositoryProvider).activePlan(),
      isNotNull,
    );
  });

  test('carried out late, everything is dated to the booked day', () async {
    await setUpWith(FitnessGoal.cut);
    final from = daysAgo(2); // booked for 2 days ago, app opened only now
    final plan = await cutPlanSince(daysAgo(6));
    await container
        .read(cutCultivationStateProvider.notifier)
        .ensureOpenForCut(preferredStart: daysAgo(6));
    await book(from);

    expect(await container.read(applyDueGoalSwitchProvider)(), isTrue);

    final profile = container.read(profileProvider)!;
    expect(profile.goal, FitnessGoal.maintain);
    expect(profile.calorieStandardSince, from);
    expect(container.read(pendingGoalSwitchProvider), isNull);

    final repo = container.read(dietStrategyRepositoryProvider);
    expect(await repo.activePlan(), isNull);
    final stopped = (await repo.listPlans()).firstWhere((p) => p.id == plan.id);
    expect(stopped.status, DietPlanStatus.stopped);
    expect(stopped.endedOn, from);

    // The cut round ran through the day before the booked day.
    final ledger = container.read(cutCultivationStateProvider);
    expect(ledger.openSegment, isNull);
    expect(ledger.segments.last.end, CalendarDay.addDays(from, -1));

    // Days from the booked day on are maintain days; earlier ones are cut.
    final onFrom = (await repo.targetForDay(from, profile))!;
    expect(onFrom.isMaintainDay, isTrue);
    final before = (await repo.targetForDay(daysAgo(3), profile))!;
    expect(before.planId, plan.id);
  });

  test('a booking carries the rates picked for it', () async {
    await setUpWith(FitnessGoal.cut);
    await container
        .read(pendingGoalSwitchProvider.notifier)
        .schedule(
          PendingGoalSwitch(
            goal: FitnessGoal.maintain,
            from: today,
            proteinPerKg: 1.6,
            fatPerKg: 1.0,
          ),
        );
    // Survives a reload from prefs.
    expect(
      container.read(goalScheduleRepositoryProvider).load()?.proteinPerKg,
      1.6,
    );
    expect(
      container.read(goalScheduleRepositoryProvider).load()?.fatPerKg,
      1.0,
    );
    expect(await container.read(applyDueGoalSwitchProvider)(), isTrue);
    final p = container.read(profileProvider)!;
    expect(p.maintainProteinPerKg, 1.6);
    expect(p.targets.proteinG, closeTo(p.weightKg * 1.6, 0.05));
    expect(p.maintainFatPerKg, 1.0);
    expect(p.targets.fatG, closeTo(p.weightKg * 1.0, 0.05));
  });

  test('a manual goal switch replaces the booking', () async {
    await setUpWith(FitnessGoal.cut);
    await book(CalendarDay.addDays(today, 1));
    final p = container.read(profileProvider)!;
    await container
        .read(profileProvider.notifier)
        .save(
          sex: p.sex,
          age: p.age,
          heightCm: p.heightCm,
          weightKg: p.weightKg,
          activity: p.activity,
          goal: FitnessGoal.bulk,
        );
    expect(container.read(pendingGoalSwitchProvider), isNull);
    expect(container.read(goalScheduleRepositoryProvider).load(), isNull);
  });

  test('a booked 维持 adjustment re-fixes the target on its day', () async {
    await setUpWith(FitnessGoal.maintain);
    final tomorrow = CalendarDay.addDays(today, 1);
    await container
        .read(pendingGoalSwitchProvider.notifier)
        .schedule(
          PendingGoalSwitch(
            goal: FitnessGoal.maintain,
            from: tomorrow,
            proteinPerKg: 1.6,
          ),
        );

    // Not yet due.
    expect(await container.read(applyDueGoalSwitchProvider)(), isFalse);
    expect(container.read(profileProvider)!.targets.proteinG, 150);

    // Due: new rate, re-fixed from the current profile; same start day.
    expect(
      await container.read(applyDueGoalSwitchProvider)(today: tomorrow),
      isTrue,
    );
    final p = container.read(profileProvider)!;
    expect(p.goal, FitnessGoal.maintain);
    expect(p.maintainProteinPerKg, closeTo(1.6, 1e-9));
    expect(p.targets.proteinG, closeTo(75 * 1.6, 0.05));
    expect(p.calorieStandardSince, DateTime(2026, 1, 1));
    expect(container.read(pendingGoalSwitchProvider), isNull);
  });

  test('goal switches work while the cultivation history is watched', () async {
    // Riverpod (debug) rejects a notifier invalidating a provider that
    // depends on it; the history watches the profile, so the switch must
    // not invalidate it while something (e.g. the 修行 page) listens.
    await setUpWith(FitnessGoal.cut);
    final sub = container.listen(cultivationHistoryProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(cultivationHistoryProvider.future);
    Future<void> switchTo(FitnessGoal goal) {
      final p = container.read(profileProvider)!;
      return container
          .read(profileProvider.notifier)
          .save(
            sex: p.sex,
            age: p.age,
            heightCm: p.heightCm,
            weightKg: p.weightKg,
            activity: p.activity,
            goal: goal,
          );
    }

    await switchTo(FitnessGoal.maintain);
    expect(container.read(profileProvider)!.goal, FitnessGoal.maintain);
    await switchTo(FitnessGoal.cut);
    expect(container.read(profileProvider)!.goal, FitnessGoal.cut);
  });

  group('day rollover', () {
    final tomorrow = CalendarDay.addDays(today, 1);
    // Just past midnight into tomorrow.
    final justAfterMidnight = tomorrow.add(const Duration(seconds: 1));

    test('the midnight timer fires just after the next local midnight', () {
      expect(
        untilNextDay(now: DateTime(2026, 11, 16, 23, 59, 30)),
        const Duration(seconds: 31),
      );
      expect(
        untilNextDay(now: DateTime(2026, 11, 16, 12)),
        const Duration(hours: 12, seconds: 1),
      );
      // Month and year ends roll over too.
      expect(
        untilNextDay(now: DateTime(2026, 12, 31, 23)),
        const Duration(hours: 1, seconds: 1),
      );
    });

    test('nothing changes within the same day', () async {
      await setUpWith(FitnessGoal.cut);
      expect(await container.read(dayRolloverProvider)(), isFalse);
      expect(container.read(currentDayProvider), today);
    });

    test('today and the Today page move on; the booked switch runs', () async {
      await setUpWith(FitnessGoal.cut);
      await book(tomorrow);
      expect(container.read(selectedDayProvider), today);

      expect(
        await container.read(dayRolloverProvider)(now: justAfterMidnight),
        isTrue,
      );
      expect(container.read(currentDayProvider), tomorrow);
      // The Today page was on the old today, so it follows.
      expect(container.read(selectedDayProvider), tomorrow);
      // The switch booked for the new day happened, dated to it.
      final profile = container.read(profileProvider)!;
      expect(profile.goal, FitnessGoal.maintain);
      expect(profile.calorieStandardSince, tomorrow);
      expect(container.read(pendingGoalSwitchProvider), isNull);
    });

    test('a day picked on purpose stays selected', () async {
      await setUpWith(FitnessGoal.cut);
      final earlier = daysAgo(3);
      container.read(selectedDayProvider.notifier).setDay(earlier);
      await container.read(dayRolloverProvider)(now: justAfterMidnight);
      expect(container.read(currentDayProvider), tomorrow);
      expect(container.read(selectedDayProvider), earlier);
    });

    test("today's target follows the clock", () async {
      await setUpWith(FitnessGoal.cut);
      final sub = container.listen(todayTargetProvider, (_, _) {});
      addTearDown(sub.close);
      container
          .read(currentDayProvider.notifier)
          .refresh(now: justAfterMidnight);
      // Let the per-day stream deliver.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(todayTargetProvider).value?.date, tomorrow);
    });
  });
}
