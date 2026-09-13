import 'package:flutter/material.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';

/// Shared transparent calorie formula breakdown.
class CalorieBreakdown extends StatelessWidget {
  const CalorieBreakdown({
    super.key,
    required this.plan,
    this.compact = false,
    this.showTargetAndMacros = true,
  });

  final CaloriePlan plan;
  final bool compact;

  /// Whether to render the "目标摄入" (target intake) and "三大营养素"
  /// (macros) sections. The About sheet hides these, keeping only BMR/TDEE
  /// and the notes (7700 kcal ≈ 1 kg fat).
  final bool showTargetAndMacros;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final children = <Widget>[
      _sectionTitle(theme, l10n.bmrSection),
      Text(plan.bmrFormula(l10n), style: theme.textTheme.bodyMedium),
      const SizedBox(height: 4),
      Text(plan.bmrSubstituted, style: theme.textTheme.meta),
      const SizedBox(height: AppSpacing.field),
      _sectionTitle(theme, l10n.tdeeSection),
      Text(
        'BMR × ${plan.activityFactor} = ${plan.tdee.toStringAsFixed(0)} kcal',
        style: theme.textTheme.bodyMedium,
      ),
      if (showTargetAndMacros) ...[
        const SizedBox(height: AppSpacing.field),
        _sectionTitle(theme, l10n.targetIntakeSection),
        ..._goalLines(theme, l10n),
        const SizedBox(height: AppSpacing.field),
        _sectionTitle(theme, l10n.macrosSection),
        Text(
          '${plan.targets.calories} kcal · '
          'P ${plan.targets.proteinG.toStringAsFixed(0)} · '
          'C ${plan.targets.carbG.toStringAsFixed(0)} · '
          'F ${plan.targets.fatG.toStringAsFixed(0)}',
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          l10n.macroRule(plan.proteinPerKg.toString()),
          style: theme.textTheme.meta,
        ),
        if (plan.calorieAdjustment > 0) ...[
          const SizedBox(height: 4),
          Text(
            l10n.includesPlateauAdj('${plan.calorieAdjustment}'),
            style: theme.textTheme.meta,
          ),
        ],
      ],
    ];

    if (plan.notes.isNotEmpty) {
      children.add(const SizedBox(height: AppSpacing.field));
      children.add(_sectionTitle(theme, l10n.notesSection));
      for (final note in plan.notes) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              note.localize(l10n),
              style: theme.textTheme.meta?.copyWith(
                color: plan.missingCutInputs ? theme.colorScheme.error : null,
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

  List<Widget> _goalLines(ThemeData theme, AppLocalizations l10n) {
    switch (plan.goal) {
      case FitnessGoal.maintain:
        return [
          Text(
            l10n.maintainLine('${plan.targets.calories}'),
            style: theme.textTheme.bodyMedium,
          ),
        ];
      case FitnessGoal.bulk:
        return [
          Text(
            l10n.bulkLine('${plan.targets.calories}'),
            style: theme.textTheme.bodyMedium,
          ),
        ];
      case FitnessGoal.cut:
        // No fixed deficit here — a fat-loss deficit only ever comes from an
        // active diet-strategy plan, so `cut` always eats at TDEE until one
        // exists. Target weight (if set) is shown purely as progress info.
        final lines = <Widget>[
          Text(plan.goal.label(l10n), style: theme.textTheme.bodyMedium),
        ];
        if (plan.kgToLose != null && plan.targetWeightKg != null) {
          lines.add(
            Text(
              '${plan.weightKg.toStringAsFixed(1)} → '
              '${plan.targetWeightKg!.toStringAsFixed(1)} kg'
              '${l10n.needLose(plan.kgToLose!.toStringAsFixed(1))}',
              style: theme.textTheme.meta,
            ),
          );
        }
        lines.add(
          Text(
            l10n.cutDefaultsToTdeeLine('${plan.targets.calories}'),
            style: theme.textTheme.bodyMedium,
          ),
        );
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
