import 'package:flutter/material.dart';
import '../ink/ink_icon.dart';

import '../../domain/calendar_day.dart';
import '../../domain/diet_strategy.dart';
import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';
import 'strategy_labels.dart';

/// Cycle table: date · carb-day type · target kcal + P/C/F, for one
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
    this.restDayDates,
    this.windowStart,
  });

  final CarbCyclePlan plan;
  final DateTime cycleStart;
  final ValueChanged<CarbCycleSchedule>? onScheduleChanged;

  /// When true, the muted weight caption notes that W is read from the profile
  /// (configure flow). Active-plan previews keep the shorter label.
  final bool referenceWeightFromProfile;

  /// Dates marked as 休息日 on/after [cycleStart]. When non-null, the table
  /// rolls with [windowStart] (defaults to today) instead of always starting
  /// at [cycleStart], and each row's type/kcal reflect the actual rest-day
  /// shifted cycle position rather than the raw unshifted template — so the
  /// preview stays in sync instead of staying frozen at the plan's original
  /// start date. Leave null for the pre-save configure preview, which has no
  /// committed plan (and therefore no rest days) to shift against yet.
  final List<DateTime>? restDayDates;

  /// First date shown when [restDayDates] is set. Defaults to today.
  final DateTime? windowStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final days = plan.integerDays();
    final today = CalendarDay.todayLocal();
    final start = CalendarDay.dayOnly(cycleStart);
    final restDays = restDayDates;
    final anchor = restDays == null
        ? start
        : CalendarDay.dayOnly(windowStart ?? today);
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
              child: Text(
                l10n.cycleDayColumn,
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
        for (var i = 0; i < days.length; i++)
          _dayRow(i, days, start, anchor, restDays, today, locale, editable),
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

  /// Row for schedule slot [i], starting from [anchor]. When [restDays] is
  /// set, the displayed calendar date is offset from [anchor] but the actual
  /// macros shown come from the rest-day-shifted cycle slot (not slot [i]
  /// itself) — the tap target still cycles slot [i]'s raw type, matching the
  /// edit affordance shown for that row.
  Widget _dayRow(
    int i,
    List<DayMacroTarget> days,
    DateTime start,
    DateTime anchor,
    List<DateTime>? restDays,
    DateTime today,
    Locale locale,
    bool editable,
  ) {
    final date = anchor.add(Duration(days: i));
    final cycleIndex = restDays == null
        ? i
        : StrategyDates.cycleIndexOf(
            date,
            start,
            days.length,
            restDaysBefore: restDays
                .where((d) => !d.isBefore(start) && d.isBefore(date))
                .length,
          );
    final row = days[cycleIndex];
    // The row's own date is a marked 休息日: the underlying target is still
    // computed from the shifted cycle slot above (so later rows shift
    // correctly), but this row itself shouldn't claim a H/M/L carb type —
    // the day is a rest day, not a diet day.
    final isRestDay = restDays?.contains(date) ?? false;
    return _DayRow(
      key: ValueKey('cycleDay-$i'),
      name: AppDates.md(date, locale),
      isToday: date == today,
      type: row.dayType,
      isRestDay: isRestDay,
      kcal: row.energy.round(),
      proteinG: row.proteinG.round(),
      carbG: row.carbG.round(),
      fatG: row.fatG.round(),
      onTap: editable
          ? () => onScheduleChanged!(plan.schedule.cycleDayType(i))
          : null,
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    super.key,
    required this.name,
    required this.isToday,
    required this.type,
    required this.isRestDay,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.onTap,
  });

  final String name;
  final bool isToday;
  final CarbDayType type;

  /// This row's own date is marked as 休息日 — shown in place of the H/M/L
  /// type below so the table doesn't claim a carb-day type for a day the
  /// user has explicitly taken off.
  final bool isRestDay;
  final int kcal;
  final int proteinG;
  final int carbG;
  final int fatG;
  final VoidCallback? onTap;

  Color _typeColor() => switch (type) {
    CarbDayType.high => AppColors.carb,
    // Mid / train-leaning: cool teal-grey, not competing with brand primary.
    CarbDayType.mid => const Color(0xFF5B7C8A),
    // Low: warm muted grey.
    CarbDayType.low => const Color(0xFF8A7B6B),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final v = AppThemeVisuals.of(context);
    final l10n = context.l10n;
    final typeColor = isRestDay ? scheme.onSurfaceVariant : _typeColor();

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
                    child: Text(
                      isRestDay ? l10n.restDayLabel : type.label(l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w600,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkIcon(
                        InkGlyph.cycle,
                        size: 16,
                        color: typeColor,
                      ),
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
