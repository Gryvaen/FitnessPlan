/// 实际日缺口 = 计划日缺口 + 剩余热量（目标摄入 − 实际摄入）
double actualDailyDeficit({
  required double plannedDeficit,
  required double targetCalories,
  required double intakeCalories,
}) =>
    plannedDeficit + (targetCalories - intakeCalories);
