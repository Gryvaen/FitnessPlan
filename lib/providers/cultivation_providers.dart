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
