import 'package:flutter/material.dart';

import '../ink/ink_icon.dart';

/// Label + −/+ stepper for a 0.1-step multiplier (g/kg), bounded by
/// [min]/[max]. Shared by the strategy configure page and the calendar's
/// 冲碳日 marker sheet.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
    this.modifiedTooltip,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  /// When set, shows a small "auto-adjusted" badge after the label instead
  /// of a text marker; the string is the badge's tooltip.
  final String? modifiedTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double snap(double v) => (v * 10).round() / 10;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (modifiedTooltip case final tooltip?)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: tooltip,
                    triggerMode: TooltipTriggerMode.tap,
                    child: InkIcon(
                      InkGlyph.autoFix,
                      size: 15,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: '−$step',
          onPressed: value - step >= min - 1e-9
              ? () => onChanged(snap(value - step))
              : null,
          icon: const InkIcon(InkGlyph.close),
        ),
        SizedBox(
          width: 72,
          child: Text(
            '${value.toStringAsFixed(1)} $unit',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
        ),
        IconButton(
          tooltip: '+$step',
          onPressed: value + step <= max + 1e-9
              ? () => onChanged(snap(value + step))
              : null,
          icon: const InkIcon(InkGlyph.add),
        ),
      ],
    );
  }
}
