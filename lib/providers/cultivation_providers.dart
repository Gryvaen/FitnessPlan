import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calendar_day.dart';
import '../domain/cultivation.dart';
import '../domain/models.dart';
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

/// 指定日期的饮食盈余 kcal：目标热量 − 实际摄入，仅当日记录餐次 ≥ 2 类（早/
/// 中/晚/加餐任意两类）时计入，且只计正值（吃得比目标少，才有"盈余"贡献修为）。
final cultivationDietSurplusForDayProvider = Provider.autoDispose
    .family<double, DateTime>((ref, day) {
      final meals = ref.watch(mealsForDayProvider(day)).value ?? const [];
      final loggedTypes = meals.map((e) => e.mealType).toSet();
      if (loggedTypes.length < 2) return 0;

      final target = ref.watch(dailyTargetProvider(day)).value;
      if (target == null) return 0;

      final intake = meals.fold<double>(0, (sum, e) => sum + e.calories);
      final surplus = target.calories - intake;
      return surplus < 0 ? 0 : surplus;
    });

/// 今日饮食盈余 kcal，恒为本地今天，独立于「记录」页当前浏览到的日期。
final cultivationDietSurplusTodayProvider = Provider<double>((ref) {
  return ref.watch(
    cultivationDietSurplusForDayProvider(CalendarDay.todayLocal()),
  );
});

/// 今日为境界修行贡献的 kcal（步数 + 饮食盈余）。
final cultivationTodayKcalProvider = Provider<double>((ref) {
  final steps = ref.watch(cultivationStepsTodayProvider).value ?? 0;
  final dietSurplus = ref.watch(cultivationDietSurplusTodayProvider);
  return stepsToKcal(steps) + dietSurplus;
});

class CultivationDayRecord {
  const CultivationDayRecord({
    required this.date,
    required this.stepsKcal,
    required this.dietKcal,
  });

  final DateTime date;
  final double stepsKcal;
  final double dietKcal;

  double get totalKcal => stepsKcal + dietKcal;
}

/// 近 14 天的境界修行 kcal 明细（步数 + 饮食盈余），最新一天在前，与步数同步
/// 窗口一致（见 [recentStepsProvider]）。
final cultivationHistoryProvider =
    Provider.autoDispose<List<CultivationDayRecord>>((ref) {
      final stepDays = ref.watch(recentStepsProvider).value ?? const [];
      return [
        for (final stepDay in stepDays)
          CultivationDayRecord(
            date: stepDay.date,
            stepsKcal: stepsToKcal(stepDay.steps),
            dietKcal: ref.watch(
              cultivationDietSurplusForDayProvider(stepDay.date),
            ),
          ),
      ];
    });
