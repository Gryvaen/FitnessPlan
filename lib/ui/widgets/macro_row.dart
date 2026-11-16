import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';

/// Three columns of protein / carbs / fat grams in their macro colors, with
/// an optional unit suffix line (e.g. "/ 100g") under each figure.
class MacroRow extends StatelessWidget {
  const MacroRow({
    super.key,
    required this.protein,
    required this.carb,
    required this.fat,
    this.unitSuffix,
  });

  final double protein;
  final double carb;
  final double fat;
  final String? unitSuffix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget col(String label, double v, Color c) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.meta),
          const SizedBox(height: 2),
          Text(
            '${v.toStringAsFixed(1)} g',
            style: theme.textTheme.statFigure?.copyWith(color: c),
          ),
          if (unitSuffix != null)
            Text(
              unitSuffix!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
    return Row(
      children: [
        col(l10n.protein, protein, AppColors.protein),
        col(l10n.carbs, carb, AppColors.carb),
        col(l10n.fat, fat, AppColors.fat),
      ],
    );
  }
}
