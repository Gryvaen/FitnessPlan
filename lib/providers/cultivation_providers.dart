import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/workout_repository.dart';
import '../domain/calendar_day.dart';
import '../domain/cultivation.dart';
import '../domain/deficit.dart';
import '../domain/models.dart';
import 'diet_strategy_providers.dart';
import 'meal_providers.dart';
import 'profile_providers.dart';
import 'step_providers.dart';
import 'weight_providers.dart';
import 'workout_providers.dart';

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

/// 境界进度 = 已确认减重（体重记录首尾差）+ 今日尚未反映到体重记录里的实时
/// 缺口（步数 + 饮食，换算成 kg）。今日缺口为负（吃超了）时不倒扣，只在
/// 净正向时才叠加——真正的倒退只能靠新的体重记录体现。次日该实时部分会
/// 随「今日」滚动重新计算，若未被一次新的体重记录「坐实」，不会累积到
/// 明天；这正是所需的「动态加 kcal」：练气/筑基等境界进度随当天活动实时
/// 变化，而不是只在称重后才跳动。
final cultivationProgressProvider = Provider<CultivationProgress>((ref) {
  final confirmedKg = ref.watch(cultivationKgLostProvider);
  final todayKcal = ref.watch(cultivationTodayKcalProvider);
  final liveKg = todayKcal > 0 ? todayKcal / kKcalPerKg : 0.0;
  return computeCultivationProgress(confirmedKg + liveKg);
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
                  ref.watch(dayWorkoutProvider(stepDay.date)).value ??
                  const DayWorkoutSnapshot(),
            ),
      ];
    });
