import 'package:flutter/material.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../theme/app_theme.dart';

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
      _sectionTitle(theme, '1. 基础代谢 BMR'),
      Text(plan.bmrFormulaLabel, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 4),
      Text(plan.bmrSubstituted, style: theme.textTheme.meta),
      const SizedBox(height: AppSpacing.field),
      _sectionTitle(theme, '2. 每日总消耗 TDEE'),
      Text(
        'BMR × ${plan.activityFactor} = ${plan.tdee.toStringAsFixed(0)} kcal',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.field),
      _sectionTitle(theme, '3. 目标摄入'),
      ..._goalLines(theme),
      const SizedBox(height: AppSpacing.field),
      _sectionTitle(theme, '4. 三大营养素'),
      Text(
        '${plan.targets.calories} kcal · '
        'P ${plan.targets.proteinG.toStringAsFixed(0)} · '
        'C ${plan.targets.carbG.toStringAsFixed(0)} · '
        'F ${plan.targets.fatG.toStringAsFixed(0)}',
        style: theme.textTheme.bodyMedium,
      ),
      Text(
        '蛋白 ${plan.proteinPerKg} g/kg · 脂肪 0.8 g/kg · 其余为碳水',
        style: theme.textTheme.meta,
      ),
      if (plan.calorieAdjustment > 0) ...[
        const SizedBox(height: 4),
        Text(
          '含平台期调整 −${plan.calorieAdjustment} kcal',
          style: theme.textTheme.meta,
        ),
      ],
    ];

    if (plan.notes.isNotEmpty) {
      children.add(const SizedBox(height: AppSpacing.field));
      children.add(_sectionTitle(theme, '说明'));
      for (final note in plan.notes) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              note,
              style: theme.textTheme.meta?.copyWith(
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
          Text(
            '维持：≈ TDEE = ${plan.targets.calories} kcal',
            style: theme.textTheme.bodyMedium,
          ),
        ];
      case FitnessGoal.bulk:
        return [
          Text(
            '增肌：TDEE × 1.1 = ${plan.targets.calories} kcal',
            style: theme.textTheme.bodyMedium,
          ),
        ];
      case FitnessGoal.cut:
        final lines = <Widget>[
          Text('减脂', style: theme.textTheme.bodyMedium),
        ];
        if (plan.kgToLose != null &&
            plan.targetWeightKg != null &&
            plan.weeklyLossKg != null) {
          lines.addAll([
            Text(
              '${plan.weightKg.toStringAsFixed(1)} → '
              '${plan.targetWeightKg!.toStringAsFixed(1)} kg'
              '（需减 ${plan.kgToLose!.toStringAsFixed(1)}）',
              style: theme.textTheme.meta,
            ),
            Text(
              '${plan.weeklyLossKg!.toStringAsFixed(2)} kg/周'
              '${plan.goalWeeks != null ? ' · 约 ${plan.goalWeeks} 周' : ''}',
              style: theme.textTheme.meta,
            ),
            Text(
              '日缺口 ${plan.dailyDeficit.round()} kcal'
              '${plan.requestedDeficit != null && plan.safetyApplied && (plan.requestedDeficit! - plan.dailyDeficit).abs() > 1 ? '（已收窄）' : ''}',
              style: theme.textTheme.meta,
            ),
            Text(
              '应吃 ${plan.targets.calories} kcal',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ]);
        } else {
          lines.add(
            Text(
              '临时估算：TDEE × 80% = ${plan.targets.calories} kcal',
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
      child: Text(text, style: theme.textTheme.titleSmall),
    );
  }
}
