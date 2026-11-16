import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/cultivation_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../data/services/steps_sync_service.dart';
import '../domain/calendar_day.dart';
import '../domain/cultivation.dart';
import '../domain/cut_cultivation.dart';
import '../domain/cut_round_stats.dart';
import '../domain/day_marker.dart';
import '../domain/deficit.dart';
import '../domain/models.dart';
import 'core_providers.dart';
import 'day_clock_providers.dart';
import 'day_marker_providers.dart';
import 'diet_strategy_providers.dart';
import 'meal_providers.dart';
import 'profile_providers.dart';
import 'step_providers.dart';

final cultivationRepositoryProvider = Provider<CultivationRepository>((ref) {
  return CultivationRepository(ref.watch(sharedPreferencesProvider));
});

/// Persisted cut ledger (frozen kcal + segments). Reloaded after goal switches.
final cutCultivationStateProvider =
    NotifierProvider<CutCultivationStateNotifier, CutCultivationState>(
      CutCultivationStateNotifier.new,
    );

class CutCultivationStateNotifier extends Notifier<CutCultivationState> {
  @override
  CutCultivationState build() {
    return ref.read(cultivationRepositoryProvider).load();
  }

  void reload() {
    state = ref.read(cultivationRepositoryProvider).load();
  }

  /// Leaving cut: bank open-segment kcal and close the stretch on [endDay]
  /// (default today; a booked switch closes it the day before its date).
  Future<void> freezeLeavingCut(
    double openSegmentKcal, {
    DateTime? endDay,
  }) async {
    state = await ref
        .read(cultivationRepositoryProvider)
        .freezeOpenSegment(
          openSegmentKcal: openSegmentKcal,
          endDay: endDay ?? CalendarDay.todayLocal(),
        );
  }

  /// Entering cut: open a new stretch (continues from [frozenKcal]).
  Future<void> resumeEnteringCut({DateTime? preferredStart}) async {
    state = await ref
        .read(cultivationRepositoryProvider)
        .openSegment(preferredStart: preferredStart);
  }

  /// Already on cut but ledger empty / no open segment (upgrade path).
  Future<void> ensureOpenForCut({DateTime? preferredStart}) async {
    state = await ref
        .read(cultivationRepositoryProvider)
        .ensureOpenSegment(preferredStart: preferredStart);
  }
}

/// 境界修行玩法当前只对选择「减脂」目标的用户开放。
final cultivationEligibleProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  return profile?.goal == FitnessGoal.cut;
});

/// DB row for local today (re-subscribes after each sync so the calendar day
/// does not stay stuck on yesterday if the provider outlives midnight).
final _storedStepsTodayProvider = StreamProvider<int>((ref) {
  ref.watch(stepsSyncProvider);
  return ref
      .watch(stepRepositoryProvider)
      .watchStepsForDay(ref.watch(currentDayProvider));
});

/// 今日步数（恒为本地今天）。未成功同步（权限/失败/空读）时按 0，避免把
/// 库里残留的昨日总量当成今日修行贡献。按当日标记的步数开关决定是否计入。
final cultivationStepsTodayProvider = Provider<int>((ref) {
  final today = ref.watch(currentDayProvider);
  final marker = ref.watch(dayMarkerSettingsProvider(today)).value;
  if (!(marker?.includeSteps ?? true)) {
    return 0;
  }
  final status = ref.watch(stepsSyncStatusProvider);
  if (status != StepsSyncStatus.connected) return 0;
  return ref.watch(_storedStepsTodayProvider).value ?? 0;
});

/// 指定日期的饮食 kcal 贡献，仅当日记录餐次 ≥ 2 类时计入。由当日标记的饮食开关控制。
final cultivationDietKcalForDayProvider = Provider.autoDispose
    .family<double, DateTime>((ref, day) {
      final marker = ref.watch(dayMarkerSettingsProvider(day)).value;
      if (!(marker?.includeDiet ?? true)) {
        return 0;
      }

      final meals = ref.watch(mealsForDayProvider(day)).value ?? const [];
      final loggedTypes = meals.map((e) => e.mealType).toSet();
      if (loggedTypes.length < 2) return 0;

      final target = ref.watch(dailyTargetProvider(day)).value;
      final tdee = target?.estimatedTdee;
      if (target == null || tdee == null) return 0;

      final intake = meals.fold<double>(0, (sum, e) => sum + e.calories);
      return cultivationDietContribution(tdee: tdee, intakeCalories: intake);
    });

final cultivationDietKcalTodayProvider = Provider<double>((ref) {
  return ref.watch(
    cultivationDietKcalForDayProvider(ref.watch(currentDayProvider)),
  );
});

final cultivationCheatPenaltyTodayProvider = Provider<double>((ref) {
  final marker = ref
      .watch(dayMarkerSettingsProvider(ref.watch(currentDayProvider)))
      .value;
  return marker?.penaltyKcal ?? 0;
});

final cultivationTodayKcalProvider = Provider<double>((ref) {
  final steps = ref.watch(cultivationStepsTodayProvider);
  final dietKcal = ref.watch(cultivationDietKcalTodayProvider);
  return stepsToKcal(steps) +
      dietKcal +
      ref.watch(cultivationCheatPenaltyTodayProvider);
});

class CultivationDayRecord {
  const CultivationDayRecord({
    required this.date,
    required this.stepsKcal,
    required this.dietKcal,
    required this.workout,
    this.cheatPenaltyKcal = 0,
  });

  final DateTime date;
  final double stepsKcal;
  final double dietKcal;
  final double cheatPenaltyKcal;
  final DayWorkoutSnapshot workout;

  double get totalKcal => stepsKcal + dietKcal + cheatPenaltyKcal;
}

/// One cut stretch's daily rows for the history screen.
class CultivationHistorySection {
  const CultivationHistorySection({required this.segment, required this.days});

  final CutCultivationSegment segment;
  final List<CultivationDayRecord> days;

  bool get isCurrent => segment.isOpen;

  double get totalKcal => days.fold(0.0, (s, d) => s + d.totalKcal);
}

final _cultivationDbTickProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(databaseProvider);
  var n = 0;
  return db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          db.stepLogs,
          db.mealEntries,
          db.dayWorkouts,
          db.dayWorkoutItems,
          db.workoutSetLogs,
          db.dailyNutritionTargets,
          db.dietStrategyPlans,
          db.dayMarkers,
        ]),
      )
      .map((_) => ++n);
});

Future<List<CultivationDayRecord>> _buildCultivationDays({
  required Ref ref,
  required Set<DateTime> allowedDays,
  UserProfile? profileForResolution,
}) async {
  if (allowedDays.isEmpty) return const [];

  final today = CalendarDay.todayLocal();
  final stepRepo = ref.read(stepRepositoryProvider);
  final mealRepo = ref.read(mealRepositoryProvider);
  final strategyRepo = ref.read(dietStrategyRepositoryProvider);
  final workoutRepo = ref.read(workoutRepositoryProvider);
  final profile = profileForResolution ?? ref.read(profileProvider);

  final oldest = allowedDays.reduce((a, b) => a.isBefore(b) ? a : b);
  final newest = allowedDays.reduce((a, b) => a.isAfter(b) ? a : b);

  final stepDays = await stepRepo.allLoggedDays();
  final mealDays = await mealRepo.mealDaySummaries(since: oldest);
  final markers = await ref
      .read(dayMarkerRepositoryProvider)
      .settingsBetween(oldest, newest);
  final stepsByDay = <DateTime, int>{
    for (final d in stepDays)
      if (allowedDays.contains(d.date)) d.date: d.steps,
  };

  final dates = <DateTime>{
    ...allowedDays.where(
      (d) =>
          stepsByDay.containsKey(d) ||
          mealDays.containsKey(d) ||
          markers[d]?.type == DayMarkerType.cheatMeal ||
          d == today,
    ),
  };

  if (dates.isEmpty) return const [];

  final ordered = dates.toList()..sort((a, b) => b.compareTo(a));
  final targets = await strategyRepo.targetsBetween(oldest, newest, profile);
  final workouts = <DateTime, DayWorkoutSnapshot>{};
  for (final day in ordered) {
    workouts[day] = await workoutRepo.daySnapshot(day);
  }

  final out = <CultivationDayRecord>[];
  for (final day in ordered) {
    if (!allowedDays.contains(day)) continue;

    final steps = day == today
        ? ref.read(cultivationStepsTodayProvider)
        : (stepsByDay[day] ?? 0);
    final stepsKcal = stepsToKcal(steps);

    final meal = mealDays[day];
    var dietKcal = 0.0;
    if (meal != null && meal.mealTypes.length >= 2) {
      final tdee = targets[day]?.estimatedTdee;
      if (tdee != null) {
        dietKcal = cultivationDietContribution(
          tdee: tdee,
          intakeCalories: meal.calories,
        );
      }
    }

    final workout = workouts[day] ?? const DayWorkoutSnapshot();
    final hasWorkout = !workout.isEmpty;
    final hasSteps = steps > 0;
    final hasDietLog = meal != null && meal.mealTypes.length >= 2;
    final marker = markers[day];
    // A cheat marker alone creates a row, even when its deduction is disabled;
    // rest days retain their activity-based visibility.
    if (!hasSteps &&
        !hasDietLog &&
        !hasWorkout &&
        marker?.type != DayMarkerType.cheatMeal) {
      continue;
    }
    final zeroedStepsKcal = (marker?.includeSteps ?? true) ? stepsKcal : 0.0;
    final zeroedDietKcal = (marker?.includeDiet ?? true) ? dietKcal : 0.0;

    out.add(
      CultivationDayRecord(
        date: day,
        stepsKcal: zeroedStepsKcal,
        dietKcal: zeroedDietKcal,
        cheatPenaltyKcal: marker?.penaltyKcal ?? 0,
        workout: workout,
      ),
    );
  }
  return out;
}

/// Computes the open cut segment before a profile goal switch. This path
/// avoids watching profileProvider from inside ProfileNotifier.save.
///
/// [through] caps the counted days (a booked switch counts up to the day
/// before its date); default today.
Future<double> openCultivationKcalBeforeGoalSwitch(
  Ref ref,
  UserProfile currentProfile, {
  DateTime? through,
}) async {
  final ledger = ref.read(cutCultivationStateProvider);
  final segment = ledger.openSegment;
  if (segment == null) return 0;
  final days = await _buildCultivationDays(
    ref: ref,
    allowedDays: _daysInSegment(segment, through: through),
    profileForResolution: currentProfile,
  );
  return days.fold<double>(0.0, (sum, day) => sum + day.totalKcal);
}

Set<DateTime> _daysInSegment(
  CutCultivationSegment segment, {
  DateTime? through,
}) {
  final start = CalendarDay.dayOnly(segment.start);
  final end = CalendarDay.dayOnly(
    segment.end ?? through ?? CalendarDay.todayLocal(),
  );
  if (end.isBefore(start)) return {};
  final out = <DateTime>{};
  for (var d = start; !d.isAfter(end); d = CalendarDay.addDays(d, 1)) {
    out.add(d);
  }
  return out;
}

/// 按减脂时段分区的修行记录（新时段在前）。不含增肌/维持日子。
final cultivationHistoryProvider =
    FutureProvider.autoDispose<List<CultivationHistorySection>>((ref) async {
      ref.watch(_cultivationDbTickProvider);
      ref.watch(cultivationStepsTodayProvider);
      ref.watch(profileProvider);

      final ledger = ref.watch(cutCultivationStateProvider);
      final profile = ref.read(profileProvider);

      // Migrate: on cut with no open segment → open one.
      if (profile?.goal == FitnessGoal.cut && ledger.openSegment == null) {
        await ref
            .read(cutCultivationStateProvider.notifier)
            .ensureOpenForCut(preferredStart: profile?.calorieStandardSince);
      }

      final state = ref.read(cutCultivationStateProvider);
      if (state.segments.isEmpty) return const [];

      final sections = <CultivationHistorySection>[];
      for (final segment in state.segments.reversed) {
        final days = await _buildCultivationDays(
          ref: ref,
          allowedDays: _daysInSegment(segment),
        );
        sections.add(CultivationHistorySection(segment: segment, days: days));
      }
      return sections;
    });

/// Open-segment kcal only (for freeze banking).
final cultivationOpenSegmentKcalProvider = Provider<double>((ref) {
  final sections = ref.watch(cultivationHistoryProvider).value;
  if (sections == null) return 0;
  for (final section in sections) {
    if (section.isCurrent) return section.totalKcal;
  }
  return 0;
});

/// 境界进度 = 已冻结 kcal + 当前未关闭减脂时段的实时 kcal。
final cultivationProgressProvider = Provider<CultivationProgress>((ref) {
  final ledger = ref.watch(cutCultivationStateProvider);
  final openKcal = ref.watch(cultivationOpenSegmentKcalProvider);
  final totalKcal = ledger.frozenKcal + openKcal;
  return computeCultivationProgress(totalKcal / kKcalPerKg);
});

/// One cut round's totals (see [cutRoundStatsProvider]).
class CutRoundStats {
  const CutRoundStats({
    required this.dayCount,
    required this.steps,
    required this.training,
    this.weight,
    this.weightExcluded = 0,
    this.dietMetDays = 0,
    this.dietMissedDays = 0,
  });

  /// Days from the round's start through its end (or today), inclusive.
  final int dayCount;

  /// Raw logged steps — day markers don't zero anything here.
  final int steps;
  final TrainingTally training;

  /// Start / end weight: the first / last 3 weigh-ins averaged, post-cheat
  /// ones dropped (see [roundWeightTrend]); null when none are left.
  final RoundWeightTrend? weight;

  /// Weigh-ins dropped for falling on or within 3 days after a 放纵日.
  final int weightExcluded;

  /// Past days judged within / over target (see [dietDayMet]).
  final int dietMetDays;
  final int dietMissedDays;

  int get avgSteps => dayCount <= 0 ? 0 : (steps / dayCount).round();
}

/// Like [_cultivationDbTickProvider], plus weight logs — kept separate so a
/// weigh-in doesn't rebuild the heavier cultivation history.
final _cutRoundTickProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(databaseProvider);
  var n = 0;
  return db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          db.stepLogs,
          db.mealEntries,
          db.dayWorkouts,
          db.dayWorkoutItems,
          db.workoutSetLogs,
          db.dailyNutritionTargets,
          db.dietStrategyPlans,
          db.dayMarkers,
          db.weightLogs,
        ]),
      )
      .map((_) => ++n);
});

/// Totals for the cut round spanning `[start, end]`; an open round (`end`
/// null) runs through today.
final cutRoundStatsProvider = FutureProvider.autoDispose
    .family<CutRoundStats, ({DateTime start, DateTime? end})>((
      ref,
      range,
    ) async {
      ref.watch(_cutRoundTickProvider);
      final profile = ref.watch(profileProvider);
      final today = ref.watch(currentDayProvider);
      final start = CalendarDay.dayOnly(range.start);
      final end = CalendarDay.dayOnly(range.end ?? today);
      if (end.isBefore(start)) {
        return const CutRoundStats(
          dayCount: 0,
          steps: 0,
          training: TrainingTally(),
        );
      }

      final steps = await ref
          .read(stepRepositoryProvider)
          .totalStepsBetween(start, end);
      final training = await ref
          .read(workoutRepositoryProvider)
          .trainingTallyBetween(start, end);
      final weighIns = await ref
          .read(weightRepositoryProvider)
          .logsBetween(start, end);
      // 放纵日 shortly before the round still inflate its first weigh-ins.
      final markersForWeight = await ref
          .read(dayMarkerRepositoryProvider)
          .markersBetween(CalendarDay.addDays(start, -3), end);
      final weight = roundWeightTrend(
        logs: [for (final w in weighIns) (day: w.date, kg: w.weightKg)],
        cheatDays: {
          for (final e in markersForWeight.entries)
            if (e.value == DayMarkerType.cheatMeal) e.key,
        },
      );

      // Only finished days get a verdict.
      final yesterday = CalendarDay.addDays(today, -1);
      final judgedEnd = end.isAfter(yesterday) ? yesterday : end;
      var met = 0;
      var missed = 0;
      if (!judgedEnd.isBefore(start)) {
        final targets = await ref
            .read(dietStrategyRepositoryProvider)
            .targetsBetween(start, judgedEnd, profile);
        final intake = await ref
            .read(mealRepositoryProvider)
            .calorieTotalsBetween(start, judgedEnd);
        final markers = await ref
            .read(dayMarkerRepositoryProvider)
            .markersBetween(start, judgedEnd);
        for (
          var d = start;
          !d.isAfter(judgedEnd);
          d = CalendarDay.addDays(d, 1)
        ) {
          switch (dietDayMet(
            target: targets[d],
            intake: intake[d],
            marker: markers[d],
          )) {
            case true:
              met++;
            case false:
              missed++;
            case null:
              break;
          }
        }
      }

      return CutRoundStats(
        dayCount: CalendarDay.daysBetween(start, end) + 1,
        steps: steps,
        training: training,
        weight: weight.trend,
        weightExcluded: weight.excluded,
        dietMetDays: met,
        dietMissedDays: missed,
      );
    });

/// The cut round in progress, if any.
final currentCutRoundProvider = Provider<CutCultivationSegment?>(
  (ref) => ref.watch(cutCultivationStateProvider).openSegment,
);
