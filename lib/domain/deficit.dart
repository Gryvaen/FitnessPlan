/// 实际日缺口 = 计划日缺口 + 剩余热量（目标摄入 − 实际摄入）。
///
/// 计划日缺口仅在均衡缺口策略下作为「固定缺口」使用；传入 0 时本式退化为
/// 剩余热量（目标 − 摄入）。当 plannedDeficit = TDEE − target 时，结果 ≡ TDEE − 摄入。
double actualDailyDeficit({
  required double plannedDeficit,
  required double targetCalories,
  required double intakeCalories,
}) => plannedDeficit + (targetCalories - intakeCalories);

/// 修仙境界饮食贡献：TDEE − 当日摄入（可正可负）。
double cultivationDietContribution({
  required double tdee,
  required double intakeCalories,
}) => tdee - intakeCalories;
