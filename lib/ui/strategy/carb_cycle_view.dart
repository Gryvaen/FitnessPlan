import 'package:flutter/material.dart';

import '../../domain/calendar_day.dart';
import '../../domain/diet_strategy.dart';
import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';
import 'strategy_labels.dart';

/// Cycle table: date · carb-day type pill · target kcal + P/C/F, for one
/// full cycle starting at [cycleStart]. Each day's type is hand-assigned by
/// the user (see [CarbCycleSchedule.cycleDayType]) — when
/// [onScheduleChanged] is set, tapping a row cycles its type.
class CarbCycleView extends StatelessWidget {
  const CarbCycleView({
    super.key,
    required this.plan,
    required this.cycleStart,
    this.onScheduleChanged,
    this.referenceWeightFromProfile = false,
  });

  final CarbCyclePlan plan;
  final DateTime cycleStart;
  final ValueChanged<CarbCycleSchedule>? onScheduleChanged;

  /// When true, the muted weight caption notes that W is read from the profile
  /// (configure flow). Active-plan previews keep the shorter label.
  final bool referenceWeightFromProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final days = plan.integerDays();
    final today = CalendarDay.todayLocal();
    final start = CalendarDay.dayOnly(cycleStart);
    final editable = onScheduleChanged != null;

    final counts = {
      for (final t in CarbDayType.values) t: plan.schedule.count(t),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(l10n.cycleDayColumn, style: theme.textTheme.labelSmall),
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
        for (var i = 0; i < days.length; i++)
          _DayRow(
            key: ValueKey('cycleDay-$i'),
            name: AppDates.md(start.add(Duration(days: i)), locale),
            isToday: start.add(Duration(days: i)) == today,
            type: days[i].dayType,
            kcal: days[i].energy.round(),
            proteinG: days[i].proteinG.round(),
            carbG: days[i].carbG.round(),
            fatG: days[i].fatG.round(),
            onTap: editable
                ? () => onScheduleChanged!(plan.schedule.cycleDayType(i))
                : null,
          ),
        if (editable) ...[
          const SizedBox(height: 6),
          Text(l10n.carbCycleEditHint, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.section),
        Text(l10n.cycleSummary, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.compact),
        Row(
          children: [
            _SummaryCell(
              value: '${plan.days.length}',
              label: l10n.cycleLengthLabel,
            ),
            _SummaryCell(
              value: '${plan.cycleAverageEnergy.round()}',
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
          referenceWeightFromProfile
              ? l10n.referenceWeightFromProfile(
                  plan.referenceWeightKg.toStringAsFixed(1),
                )
              : '${l10n.referenceWeightKg} '
                  '${plan.referenceWeightKg.toStringAsFixed(1)} kg',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    super.key,
    required this.name,
    required this.isToday,
    required this.type,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.onTap,
  });

  final String name;
  final bool isToday;
  final CarbDayType type;
  final int kcal;
  final int proteinG;
  final int carbG;
  final int fatG;
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: pill,
                          ),
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
              const SizedBox(height: 2),
              Text(
                'P ${proteinG}g · C ${carbG}g · F ${fatG}g',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
