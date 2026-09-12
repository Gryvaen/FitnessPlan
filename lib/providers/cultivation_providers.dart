import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/workout_repository.dart';
import '../domain/calendar_day.dart';
import '../domain/cultivation.dart';
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

/// 累计减重（kg）：最早一条体重记录 − 最新一条体重记录，不足两条记为 0。
/// 不足以产生净减重（增重）时也记为 0，境界修行只按"瘦下来的部分"计。
final cultivationKgLostProvider = Provider<double>((ref) {
  final logs = ref.watch(weightLogsProvider).value ?? const [];
  if (logs.length < 2) return 0;
  final lost = logs.first.weightKg - logs.last.weightKg;
  return lost < 0 ? 0 : lost;
});

final cultivationProgressProvider = Provider<CultivationProgress>((ref) {
  return computeCultivationProgress(ref.watch(cultivationKgLostProvider));
});

/// 今日步数（独立于「记录」页当前浏览到的日期，恒为本地今天）。
final cultivationStepsTodayProvider = StreamProvider<int>((ref) {
  return ref
      .watch(stepRepositoryProvider)
      .watchStepsForDay(CalendarDay.todayLocal());
});

/// 指定日期的饮食 kcal 贡献，仅当日记录餐次 ≥ 2 类（早/中/晚/加餐任意两类）
/// 时计入；否则记为 0（未认真记录的日子不计）。由三部分叠加，可能为负：
///
/// 1. 固定代谢缺口 = 当日 TDEE − 当日目标热量（与「记录」日历上显示的每日
///    缺口算法一致）——只要当天处于减脂目标下，就按计划产生这部分缺口。
/// 2. 额外结余 = 目标热量 − 实际摄入，仅当吃得比目标更少时为正（吃得比目标
///    多、但仍未超过 TDEE 时不额外加分，也不扣分）。
/// 3. 超标倒退 = 实际摄入 − TDEE，当实际摄入超过 TDEE（当日代谢总量）时，
///    这部分作为倒退从修为中扣除。
final cultivationDietKcalForDayProvider = Provider.autoDispose
    .family<double, DateTime>((ref, day) {
      final meals = ref.watch(mealsForDayProvider(day)).value ?? const [];
      final loggedTypes = meals.map((e) => e.mealType).toSet();
      if (loggedTypes.length < 2) return 0;

      final target = ref.watch(dailyTargetProvider(day)).value;
      final tdee = target?.estimatedTdee;
      if (target == null || tdee == null) return 0;

      final intake = meals.fold<double>(0, (sum, e) => sum + e.calories);
      final plannedDeficit = tdee - target.calories;
      final extraSurplus = target.calories - intake;
      final bonus = extraSurplus > 0 ? extraSurplus : 0.0;
      final overTdee = intake - tdee;
      final penalty = overTdee > 0 ? overTdee : 0.0;
      return plannedDeficit + bonus - penalty;
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

  /// 当日总贡献，可能为负（饮食超过 TDEE 的倒退超过了步数 + 代谢缺口）。
  double get totalKcal => stepsKcal + dietKcal;
}

/// 近 14 天的境界修行 kcal 明细（步数 + 饮食，见
/// [cultivationDietKcalForDayProvider]）与当日训练计划，最新一天在前，与
/// 步数同步窗口一致（见 [recentStepsProvider]）。
final cultivationHistoryProvider =
    Provider.autoDispose<List<CultivationDayRecord>>((ref) {
      final stepDays = ref.watch(recentStepsProvider).value ?? const [];
      return [
        for (final stepDay in stepDays)
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
