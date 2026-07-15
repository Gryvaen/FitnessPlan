import 'package:flutter/material.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';

/// Shared transparent calorie formula breakdown.
class CalorieBreakdown extends StatelessWidget {
  const CalorieBreakdown({
    super.key,
    required this.plan,
    this.compact = false,
  });

  final CaloriePlan plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[
      _sectionTitle(theme, '1. 基础代谢 BMR（Mifflin-St Jeor）'),
      Text(plan.bmrFormulaLabel, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 4),
      Text(plan.bmrSubstituted, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 12),
      _sectionTitle(theme, '2. 每日总消耗 TDEE'),
      Text(
        'TDEE = BMR × 活动系数 '
        '${plan.bmr.toStringAsFixed(1)} × ${plan.activityFactor} '
        '= ${plan.tdee.toStringAsFixed(1)} kcal',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      _sectionTitle(theme, '3. 目标与每日摄入'),
      ..._goalLines(theme),
      const SizedBox(height: 12),
      _sectionTitle(theme, '4. 三大营养素'),
      Text(
        '热量 ${plan.targets.calories} kcal · '
        '蛋白 ${plan.targets.proteinG.toStringAsFixed(0)} g · '
        '碳水 ${plan.targets.carbG.toStringAsFixed(0)} g · '
        '脂肪 ${plan.targets.fatG.toStringAsFixed(0)} g',
        style: theme.textTheme.bodyMedium,
      ),
      Text(
        '蛋白按 ${plan.proteinPerKg} g/kg，脂肪按 0.8 g/kg，剩余给碳水。',
        style: theme.textTheme.bodySmall,
      ),
      if (plan.calorieAdjustment > 0) ...[
        const SizedBox(height: 4),
        Text(
          '含平台期调整 −${plan.calorieAdjustment} kcal',
          style: theme.textTheme.bodySmall,
        ),
      ],
    ];

    if (plan.notes.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(_sectionTitle(theme, '说明'));
      for (final note in plan.notes) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: plan.safetyApplied || plan.missingCutInputs
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<Widget> _goalLines(ThemeData theme) {
    switch (plan.goal) {
      case FitnessGoal.maintain:
        return [
          Text('目标：维持', style: theme.textTheme.bodyMedium),
          Text(
            '每日应吃 ≈ TDEE = ${plan.targets.calories} kcal',
            style: theme.textTheme.bodyMedium,
          ),
        ];
      case FitnessGoal.bulk:
        return [
          Text('目标：增肌', style: theme.textTheme.bodyMedium),
          Text(
            '每日应吃 = TDEE × 1.1 = ${plan.targets.calories} kcal',
            style: theme.textTheme.bodyMedium,
          ),
        ];
      case FitnessGoal.cut:
        final lines = <Widget>[
          Text('目标：减脂', style: theme.textTheme.bodyMedium),
        ];
        if (plan.kgToLose != null &&
            plan.targetWeightKg != null &&
            plan.weeklyLossKg != null) {
          lines.addAll([
            Text(
              '当前 ${plan.weightKg.toStringAsFixed(1)} kg → '
              '目标 ${plan.targetWeightKg!.toStringAsFixed(1)} kg'
              '（需减 ${plan.kgToLose!.toStringAsFixed(1)} kg）',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '实际约 ${plan.weeklyLossKg!.toStringAsFixed(2)} kg/周'
              '${plan.goalWeeks != null ? ' · 预计约 ${plan.goalWeeks} 周' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '日缺口 ${plan.dailyDeficit.round()} kcal'
              '${plan.requestedDeficit != null && plan.safetyApplied && (plan.requestedDeficit! - plan.dailyDeficit).abs() > 1 ? '（目标约 ${plan.requestedDeficit!.round()} kcal，已按日缺口上限收窄）' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '每日应吃 = TDEE − 日缺口'
              '${plan.calorieAdjustment > 0 ? ' − 平台期 ${plan.calorieAdjustment}' : ''} '
              '= ${plan.targets.calories} kcal',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ]);
        } else {
          lines.add(
            Text(
              '每日应吃 ≈ TDEE × 80% = ${plan.targets.calories} kcal'
              '（日缺口约 ${plan.dailyDeficit.round()} kcal）',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        return lines;
    }
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 2 : 4),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
