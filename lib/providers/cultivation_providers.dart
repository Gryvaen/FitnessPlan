import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/workout_repository.dart';
import '../domain/calendar_day.dart';
import '../domain/cultivation.dart';
import '../domain/deficit.dart';
import '../domain/models.dart';
import 'core_providers.dart';
import 'diet_strategy_providers.dart';
import 'meal_providers.dart';
import 'profile_providers.dart';
import 'step_providers.dart';
import 'weight_providers.dart';

/// 境界修行玩法当前只对选择「减脂」目标的用户开放。
final cultivationEligibleProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  return profile?.goal == FitnessGoal.cut;
});

/// 累计减重（kg）：默认最早一条体重 − 最新一条；若档案上有
/// [UserProfile.calorieStandardSince]（切换目标 / 热量标准生效日），则只从
/// 该日起算，见 [cultivationKgLostFromLogs]。
final cultivationKgLostProvider = Provider<double>((ref) {
  final logs = ref.watch(weightLogsProvider).value ?? const [];
  final since = ref.watch(profileProvider)?.calorieStandardSince;
  return cultivationKgLostFromLogs(
    logs: [
      for (final l in logs) (date: l.date, weightKg: l.weightKg),
    ],
    since: since,
  );
});

/// 境界进度 = 已确认减重（体重记录首尾差）+ 尚未反映到体重记录里的实时
/// 缺口（最近一次称重之后、直到今天，每天的步数 + 饮食缺口累加，换算成
/// kg）。累加值为负（净吃超了）时不倒扣，只在净正向时才叠加——真正的倒退
/// 只能靠新的体重记录体现。一旦有新的体重记录「坐实」，累加窗口从那天起
/// 重新开始；这正是所需的「动态加 kcal」：练气/筑基等境界进度随每天的活动
/// 实时变化并跨天累积，而不是只在称重后才跳动、也不会在未称重的日子里
/// 被清零重算。
final cultivationProgressProvider = Provider<CultivationProgress>((ref) {
  final confirmedKg = ref.watch(cultivationKgLostProvider);
  final liveKcal = ref.watch(cultivationLiveKcalProvider);
  final liveKg = liveKcal > 0 ? liveKcal / kKcalPerKg : 0.0;
  return computeCultivationProgress(confirmedKg + liveKg);
});

/// 自最近一次体重记录（不含当天，若从未记录过体重则视作近 14 天全部）起、
/// 直到今天，每天的步数 + 饮食贡献之和——见 [cultivationProgressProvider]。
/// 与 [cultivationHistoryProvider] 共享同一份近 14 天窗口数据。
final cultivationLiveKcalProvider = Provider<double>((ref) {
  final logs = ref.watch(weightLogsProvider).value ?? const [];
  final history = ref.watch(cultivationHistoryProvider);
  final lastLogDay = logs.isEmpty
      ? null
      : CalendarDay.dayOnly(logs.last.date);
  var sum = 0.0;
  for (final day in history) {
    final d = CalendarDay.dayOnly(day.date);
    if (lastLogDay == null || d.isAfter(lastLogDay)) sum += day.totalKcal;
  }
  return sum;
});

/// 今日步数（独立于「记录」页当前浏览到的日期，恒为本地今天）。
final cultivationStepsTodayProvider = StreamProvider<int>((ref) {
  return ref
      .watch(stepRepositoryProvider)
      .watchStepsForDay(CalendarDay.todayLocal());
});

/// 指定日期的饮食 kcal 贡献，仅当日记录餐次 ≥ 2 类（早/中/晚/加餐任意两类）
/// 时计入；否则记为 0（未认真记录的日子不计）。
///
/// 统一公式：饮食贡献 = 当日 TDEE − 当日摄入（可与日历「实际缺口」在
/// 均衡缺口策略下一致；未选策略时同样按 TDEE − 摄入计，超过 TDEE 为负）。
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

/// 今日饮食 kcal 贡献，恒为本地今天，独立于「记录」页当前浏览到的日期。
final cultivationDietKcalTodayProvider = Provider<double>((ref) {
  return ref.watch(cultivationDietKcalForDayProvider(CalendarDay.todayLocal()));
});

/// 今日为境界修行贡献的 kcal（步数 + 饮食）；饮食一项可能为负（见
/// [cultivationDietKcalForDayProvider]），故本值整体也可能为负。
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

  /// That day's planned/logged training, if any — shown alongside the kcal
  /// breakdown so 修行记录 doubles as a training-plan history, not just steps.
  final DayWorkoutSnapshot workout;

  /// 当日总贡献，可能为负（饮食超过 TDEE 时倒退超过步数贡献）。
  double get totalKcal => stepsKcal + dietKcal;
}

/// Combined day-workout snapshots for the same rolling window
/// [cultivationHistoryProvider] shows — one shared subscription instead of
/// one per day (`dayWorkoutProvider` family) so a single set-log write
/// doesn't fan out into recomputing up to 14 independent streams at once.
final _cultivationWorkoutSnapshotsProvider = StreamProvider.autoDispose<
  Map<DateTime, DayWorkoutSnapshot>
>((ref) {
  final stepDays = ref.watch(recentStepsProvider).value ?? const [];
  return ref
      .watch(workoutRepositoryProvider)
      .watchDayWorkoutsForDays([for (final d in stepDays) d.date]);
});

/// 近 14 天的境界修行 kcal 明细（步数 + 饮食，见
/// [cultivationDietKcalForDayProvider]）与当日训练计划，最新一天在前，与
/// 步数同步窗口一致（见 [recentStepsProvider]）。切换目标后只展示新标准
/// 生效日及之后的记录。
final cultivationHistoryProvider =
    Provider.autoDispose<List<CultivationDayRecord>>((ref) {
      final stepDays = ref.watch(recentStepsProvider).value ?? const [];
      final since = ref.watch(profileProvider)?.calorieStandardSince;
      final sinceDay = since == null
          ? null
          : DateTime(since.year, since.month, since.day);
      final workouts =
          ref.watch(_cultivationWorkoutSnapshotsProvider).value ?? const {};
      return [
        for (final stepDay in stepDays)
          if (sinceDay == null ||
              !DateTime(
                stepDay.date.year,
                stepDay.date.month,
                stepDay.date.day,
              ).isBefore(sinceDay))
            CultivationDayRecord(
              date: stepDay.date,
              stepsKcal: stepsToKcal(stepDay.steps),
              dietKcal: ref.watch(
                cultivationDietKcalForDayProvider(stepDay.date),
              ),
              workout:
                  workouts[CalendarDay.dayOnly(stepDay.date)] ??
                  const DayWorkoutSnapshot(),
            ),
      ];
    });
