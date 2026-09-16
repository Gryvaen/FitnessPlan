import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/cultivation_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../domain/calendar_day.dart';
import '../domain/cultivation.dart';
import '../domain/cut_cultivation.dart';
import '../domain/deficit.dart';
import '../domain/models.dart';
import 'core_providers.dart';
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

  /// Leaving cut: bank open-segment kcal and close the stretch.
  Future<void> freezeLeavingCut(double openSegmentKcal) async {
    final today = CalendarDay.todayLocal();
    state = await ref
        .read(cultivationRepositoryProvider)
        .freezeOpenSegment(openSegmentKcal: openSegmentKcal, endDay: today);
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

/// 今日步数（独立于「记录」页当前浏览到的日期，恒为本地今天）。
final cultivationStepsTodayProvider = StreamProvider<int>((ref) {
  return ref
      .watch(stepRepositoryProvider)
      .watchStepsForDay(CalendarDay.todayLocal());
});

/// 指定日期的饮食 kcal 贡献，仅当日记录餐次 ≥ 2 类时计入。
final cultivationDietKcalForDayProvider = Provider.autoDispose
    .family<double, DateTime>((ref, day) {
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
  return ref.watch(cultivationDietKcalForDayProvider(CalendarDay.todayLocal()));
});

final cultivationTodayKcalProvider = Provider<double>((ref) {
  final steps = ref.watch(cultivationStepsTodayProvider).value ?? 0;
  final dietKcal = ref.watch(cultivationDietKcalTodayProvider);
  return stepsToKcal(steps) + dietKcal;
});

class CultivationDayRecord {
  const CultivationDayRecord({
    required this.date,
    required this.stepsKcal,
    required this.dietKcal,
    required this.workout,
  });

  final DateTime date;
  final double stepsKcal;
  final double dietKcal;
  final DayWorkoutSnapshot workout;

  double get totalKcal => stepsKcal + dietKcal;
}

/// One cut stretch's daily rows for the history screen.
class CultivationHistorySection {
  const CultivationHistorySection({
    required this.segment,
    required this.days,
  });

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
        ]),
      )
      .map((_) => ++n);
});

Future<List<CultivationDayRecord>> _buildCultivationDays({
  required Ref ref,
  required Set<DateTime> allowedDays,
}) async {
  if (allowedDays.isEmpty) return const [];

  final today = CalendarDay.todayLocal();
  final stepRepo = ref.read(stepRepositoryProvider);
  final mealRepo = ref.read(mealRepositoryProvider);
  final strategyRepo = ref.read(dietStrategyRepositoryProvider);
  final workoutRepo = ref.read(workoutRepositoryProvider);
  final profile = ref.read(profileProvider);

  final oldest = allowedDays.reduce((a, b) => a.isBefore(b) ? a : b);
  final newest = allowedDays.reduce((a, b) => a.isAfter(b) ? a : b);

  final stepDays = await stepRepo.allLoggedDays();
  final mealDays = await mealRepo.mealDaySummaries(since: oldest);
  final stepsByDay = <DateTime, int>{
    for (final d in stepDays)
      if (allowedDays.contains(d.date)) d.date: d.steps,
  };

  final dates = <DateTime>{
    ...allowedDays.where(
      (d) =>
          stepsByDay.containsKey(d) ||
          mealDays.containsKey(d) ||
          d == today,
    ),
  };

  if (dates.isEmpty) return const [];

  final ordered = dates.toList()..sort((a, b) => b.compareTo(a));
  final targets = await strategyRepo.targetsBetween(oldest, newest, profile);
  final workouts = await workoutRepo.watchDayWorkoutsForDays(ordered).first;

  final out = <CultivationDayRecord>[];
  for (final day in ordered) {
    if (!allowedDays.contains(day)) continue;

    final steps = day == today
        ? (ref.read(cultivationStepsTodayProvider).value ??
              stepsByDay[day] ??
              0)
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
    if (!hasSteps && !hasDietLog && !hasWorkout) continue;

    out.add(
      CultivationDayRecord(
        date: day,
        stepsKcal: stepsKcal,
        dietKcal: dietKcal,
        workout: workout,
      ),
    );
  }
  return out;
}

Set<DateTime> _daysInSegment(CutCultivationSegment segment) {
  final today = CalendarDay.todayLocal();
  final start = CalendarDay.dayOnly(segment.start);
  final end = CalendarDay.dayOnly(segment.end ?? today);
  if (end.isBefore(start)) return {};
  final out = <DateTime>{};
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    out.add(CalendarDay.dayOnly(d));
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
            .ensureOpenForCut(
              preferredStart: profile?.calorieStandardSince,
            );
      }

      final state = ref.read(cutCultivationStateProvider);
      if (state.segments.isEmpty) return const [];

      final sections = <CultivationHistorySection>[];
      for (final segment in state.segments.reversed) {
        final days = await _buildCultivationDays(
          ref: ref,
          allowedDays: _daysInSegment(segment),
        );
        sections.add(
          CultivationHistorySection(segment: segment, days: days),
        );
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
