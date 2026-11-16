import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/goal_history_repository.dart';
import 'package:diet/data/repositories/goal_schedule_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/goal_period.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _profile(FitnessGoal goal, {DateTime? since}) => UserProfile(
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
  bmr: 1700,
  tdee: 2400,
  calorieStandardSince: since,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final d = DateTime(2026, 10, 10);
  DateTime day(int offset) => CalendarDay.addDays(d, offset);

  group('switchGoalPeriods', () {
    test('a switch ends the open stretch the day before', () {
      final out = switchGoalPeriods(
        [GoalPeriod(goal: FitnessGoal.cut, start: day(-20))],
        FitnessGoal.maintain,
        d,
      );
      expect(out, hasLength(2));
      expect(out[0].goal, FitnessGoal.cut);
      expect(out[0].end, day(-1));
      expect(out[1].goal, FitnessGoal.maintain);
      expect(out[1].start, d);
      expect(out[1].isOpen, isTrue);
    });

    test('a second switch the same day replaces the first', () {
      var out = switchGoalPeriods(
        [GoalPeriod(goal: FitnessGoal.cut, start: day(-20))],
        FitnessGoal.maintain,
        d,
      );
      out = switchGoalPeriods(out, FitnessGoal.bulk, d);
      expect(out.map((p) => p.goal), [FitnessGoal.cut, FitnessGoal.bulk]);
      expect(out[0].end, day(-1));
      expect(out[1].start, d);
    });

    test('switching back the same day carries the stretch on', () {
      var out = switchGoalPeriods(
        [GoalPeriod(goal: FitnessGoal.cut, start: day(-20))],
        FitnessGoal.maintain,
        d,
      );
      out = switchGoalPeriods(out, FitnessGoal.cut, d);
      expect(out, hasLength(1));
      expect(out.single.goal, FitnessGoal.cut);
      expect(out.single.start, day(-20));
      expect(out.single.isOpen, isTrue);
    });

    test('staying on the same goal changes nothing', () {
      final periods = [GoalPeriod(goal: FitnessGoal.cut, start: day(-20))];
      expect(
        identical(switchGoalPeriods(periods, FitnessGoal.cut, d), periods),
        isTrue,
      );
    });

    test('the first goal opens a stretch', () {
      final out = switchGoalPeriods(const [], FitnessGoal.cut, d);
      expect(out.single.start, d);
      expect(out.single.goal, FitnessGoal.cut);
    });
  });

  group('backfillGoalPeriods', () {
    test('every cut round becomes a cut stretch; gaps stay empty', () {
      final out = backfillGoalPeriods([
        CutCultivationSegment(start: day(-60), end: day(-40)),
        CutCultivationSegment(start: day(-20)),
      ], _profile(FitnessGoal.cut));
      expect(out, hasLength(2));
      expect(out.every((p) => p.goal == FitnessGoal.cut), isTrue);
      expect(out[0].end, day(-40));
      expect(out[1].isOpen, isTrue);
    });

    test('after the last round the current goal runs from its switch day', () {
      final out = backfillGoalPeriods([
        CutCultivationSegment(start: day(-30), end: day(-5)),
      ], _profile(FitnessGoal.maintain, since: day(-5)));
      expect(out.map((p) => p.goal), [FitnessGoal.cut, FitnessGoal.maintain]);
      // The switch day belongs to the new goal.
      expect(out[0].end, day(-6));
      expect(out[1].start, day(-5));
      expect(out[1].isOpen, isTrue);
    });

    test('a booked switch (round closed the day before) keeps the round', () {
      final out = backfillGoalPeriods([
        CutCultivationSegment(start: day(-30), end: day(-6)),
      ], _profile(FitnessGoal.bulk, since: day(-5)));
      expect(out[0].end, day(-6));
      expect(out[1].goal, FitnessGoal.bulk);
      expect(out[1].start, day(-5));
    });

    test('never cut: the current goal from its switch day, if known', () {
      expect(
        backfillGoalPeriods(
          const [],
          _profile(FitnessGoal.bulk, since: day(-3)),
        ).single.start,
        day(-3),
      );
      expect(backfillGoalPeriods(const [], _profile(FitnessGoal.bulk)), []);
      expect(backfillGoalPeriods(const [], null), []);
    });
  });

  group('storage and profile saves', () {
    late AppDatabase db;
    late ProviderContainer container;
    final today = CalendarDay.todayLocal();

    Future<void> setUpWith(
      FitnessGoal goal, {
      List<GoalPeriod>? stored,
      DateTime? since,
    }) async {
      SharedPreferences.setMockInitialValues({
        'user_profile': jsonEncode(_profile(goal, since: since).toJson()),
        if (stored != null)
          GoalHistoryRepository.key: jsonEncode([
            for (final p in stored) p.toJson(),
          ]),
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

    Future<void> saveGoal(FitnessGoal goal, {DateTime? effectiveFrom}) {
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
            effectiveFrom: effectiveFrom,
          );
    }

    test('stretches round-trip through prefs', () async {
      await setUpWith(
        FitnessGoal.cut,
        stored: [
          GoalPeriod(goal: FitnessGoal.cut, start: day(-9), end: day(-1)),
          GoalPeriod(goal: FitnessGoal.maintain, start: d),
        ],
      );
      final loaded = container.read(goalPeriodsProvider);
      expect(loaded.map((p) => p.goal), [
        FitnessGoal.cut,
        FitnessGoal.maintain,
      ]);
      expect(loaded[0].end, day(-1));
      expect(loaded[1].isOpen, isTrue);
    });

    test('a goal switch on the profile records a stretch from today', () async {
      await setUpWith(
        FitnessGoal.cut,
        stored: [
          GoalPeriod(
            goal: FitnessGoal.cut,
            start: CalendarDay.addDays(today, -10),
          ),
        ],
      );
      await saveGoal(FitnessGoal.bulk);
      final periods = container.read(goalPeriodsProvider);
      expect(periods.map((p) => p.goal), [FitnessGoal.cut, FitnessGoal.bulk]);
      expect(periods[0].end, CalendarDay.addDays(today, -1));
      expect(periods[1].start, today);
      expect(
        container.read(goalHistoryRepositoryProvider).load(backfill: () => []),
        hasLength(2),
      );

      // Saving again on the same goal records nothing new.
      await saveGoal(FitnessGoal.bulk);
      expect(container.read(goalPeriodsProvider), hasLength(2));
    });

    test('a booked switch carried out late starts on the booked day', () async {
      final booked = CalendarDay.addDays(today, -2);
      await setUpWith(
        FitnessGoal.cut,
        stored: [
          GoalPeriod(
            goal: FitnessGoal.cut,
            start: CalendarDay.addDays(today, -10),
          ),
        ],
      );
      await container
          .read(pendingGoalSwitchProvider.notifier)
          .schedule(
            PendingGoalSwitch(goal: FitnessGoal.maintain, from: booked),
          );
      expect(await container.read(applyDueGoalSwitchProvider)(), isTrue);
      final periods = container.read(goalPeriodsProvider);
      expect(periods.last.goal, FitnessGoal.maintain);
      expect(periods.last.start, booked);
      expect(periods.first.end, CalendarDay.addDays(booked, -1));
    });

    test('the backfill runs before a switch changes anything', () async {
      // An older install: a closed cut round, then maintenance since its
      // end, and no stored stretches. Switching back to cut must keep the
      // maintenance stretch in between.
      await setUpWith(
        FitnessGoal.maintain,
        since: CalendarDay.addDays(today, -10),
      );
      await container
          .read(cultivationRepositoryProvider)
          .save(
            CutCultivationState(
              segments: [
                CutCultivationSegment(
                  start: CalendarDay.addDays(today, -40),
                  end: CalendarDay.addDays(today, -10),
                ),
              ],
            ),
          );
      container.read(cutCultivationStateProvider.notifier).reload();
      await saveGoal(FitnessGoal.cut);
      final periods = container.read(goalPeriodsProvider);
      expect(periods.map((p) => p.goal), [
        FitnessGoal.cut,
        FitnessGoal.maintain,
        FitnessGoal.cut,
      ]);
      expect(periods[1].start, CalendarDay.addDays(today, -10));
      expect(periods[1].end, CalendarDay.addDays(today, -1));
      expect(periods[2].start, today);
    });

    test('without a stored record the rounds are backfilled once', () async {
      await setUpWith(FitnessGoal.maintain, since: day(-5));
      await container
          .read(cultivationRepositoryProvider)
          .save(
            CutCultivationState(
              segments: [CutCultivationSegment(start: day(-30), end: day(-5))],
            ),
          );
      container.read(cutCultivationStateProvider.notifier).reload();
      final periods = container.read(goalPeriodsProvider);
      expect(periods.map((p) => p.goal), [
        FitnessGoal.cut,
        FitnessGoal.maintain,
      ]);
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString(GoalHistoryRepository.key), isNotNull);
    });

    test('clearing user data drops the record', () async {
      await setUpWith(
        FitnessGoal.cut,
        stored: [GoalPeriod(goal: FitnessGoal.cut, start: day(-9))],
      );
      expect(container.read(goalPeriodsProvider), hasLength(1));
      await clearUserData(container.read);
      expect(container.read(goalPeriodsProvider), isEmpty);
    });
  });
}
