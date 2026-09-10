import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/diet_strategy.dart';
import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';
import 'strategy_labels.dart';

/// Seven-day carb-cycle table: weekday · carb-day type pill · target kcal.
/// When [onScheduleChanged] is set, tapping a row cycles H → M → L.
class CarbCycleWeekView extends StatelessWidget {
  const CarbCycleWeekView({
    super.key,
    required this.plan,
    this.onScheduleChanged,
    this.initialSelected,
  });

  final CarbCyclePlan plan;
  final ValueChanged<CarbCycleSchedule>? onScheduleChanged;
  final int? initialSelected;

  static const _cycle = [CarbDayType.high, CarbDayType.mid, CarbDayType.low];

  List<String> _weekdayShort(Locale locale) {
    final monday = DateTime(2024, 1, 1);
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale.toString()).format(monday.add(Duration(days: i))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = plan.integerDays();
    final names = _weekdayShort(locale);
    final editable = onScheduleChanged != null;
    final todayIndex = DateTime.now().weekday - 1;

    final counts = {
      for (final t in CarbDayType.values)
        t: days.where((d) => d.dayType == t).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                l10n.weekdayColumn,
                style: theme.textTheme.labelSmall,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(l10n.carbDayType, style: theme.textTheme.labelSmall),
            ),
            Expanded(
              flex: 3,
              child: Text(
                l10n.targetKcalColumn,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < 7; i++)
          _DayRow(
            name: names[i],
            isToday: i == todayIndex,
            type: days[i].dayType,
            kcal: days[i].energy.round(),
            onTap: editable
                ? () {
                    final next =
                        _cycle[(_cycle.indexOf(days[i].dayType) + 1) %
                            _cycle.length];
                    onScheduleChanged!(plan.schedule.withDay(i, next));
                  }
                : null,
          ),
        if (editable) ...[
          const SizedBox(height: 6),
          Text(l10n.carbCycleEditHint, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.section),
        Text(l10n.weeklySummary, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.compact),
        Row(
          children: [
            _SummaryCell(
              value: '${plan.weeklyEnergy.round()}',
              label: l10n.weekTotalKcalLabel,
            ),
            _SummaryCell(
              value: '${plan.weeklyAverage.round()}',
              label: l10n.dailyAvgKcalLabel,
            ),
            _SummaryCell(
              value:
                  '${counts[CarbDayType.high]}/'
                  '${counts[CarbDayType.mid]}/'
                  '${counts[CarbDayType.low]}',
              label: l10n.hmlDayCountLabel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.compact),
        Text(
          l10n.carbAmplitudeLine(plan.effectiveAmplitudeG.toStringAsFixed(0)),
          style: theme.textTheme.bodySmall,
        ),
        if (plan.shrunk)
          Text(
            l10n.carbAmplitudeShrunk(
              plan.requestedAmplitudeG.toStringAsFixed(0),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.name,
    required this.isToday,
    required this.type,
    required this.kcal,
    required this.onTap,
  });

  final String name;
  final bool isToday;
  final CarbDayType type;
  final int kcal;
  final VoidCallback? onTap;

  Color _pillColor(AppThemeVisuals v, ColorScheme scheme) => switch (type) {
    CarbDayType.high => AppColors.carb,
    CarbDayType.mid => v.accent,
    CarbDayType.low => scheme.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final v = AppThemeVisuals.of(context);
    final l10n = context.l10n;
    final pill = _pillColor(v, scheme);

    return Material(
      color: Colors.transparent,
      shape: Border(bottom: BorderSide(color: v.divider)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: pill.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      type.label(l10n),
                      style: theme.textTheme.labelMedium?.copyWith(color: pill),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '$kcal',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.autorenew, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleMedium),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
