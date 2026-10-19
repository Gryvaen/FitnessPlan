import 'package:flutter/material.dart';
import '../ink/ink_icon.dart';

import '../../domain/calendar_day.dart';
import '../../domain/cycle_history.dart';
import '../../domain/day_marker.dart';
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
    this.cycleStartIndex = 0,
    this.anchors = const [],
    this.markers = const {},
  });

  final CarbCyclePlan plan;
  final DateTime cycleStart;
  final int cycleStartIndex;

  /// Positions frozen by the shown plan's past snapshots (see
  /// [resolveCycleDay]); empty for a not-yet-saved configuration.
  final List<CycleAnchor> anchors;
  final ValueChanged<CarbCycleSchedule>? onScheduleChanged;

  /// When true, the muted weight caption notes that W is read from the profile
  /// (configure flow). Active-plan previews keep the shorter label.
  final bool referenceWeightFromProfile;

  /// Dates selected and eligible to pause the cycle. When non-null, the table
  /// rolls with [windowStart] (defaults to today) instead of always starting
  /// at [cycleStart], and each row's type/kcal reflect the actual rest-day
  /// shifted cycle position rather than the raw unshifted template — so the
  /// preview stays in sync instead of staying frozen at the plan's original
  /// start date. Configuration previews pass their proposed effective date
  /// as [windowStart] and the same persisted rest-day choices.
  final List<DateTime>? restDayDates;

  /// First date shown when [restDayDates] is set. Defaults to today.
  final DateTime? windowStart;

  /// Day markers by date: a paused row is labelled by its marker, and a
  /// 冲碳日 row shows its raised macros (see [CarbCyclePlan.carbLoadDay]).
  final Map<DateTime, DayMarkerSettings> markers;

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

  /// One calendar day. Editing acts on the same rotated/paused schedule
  /// slot whose macros are displayed, rather than the row's visual index.
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
    final cycleDay = resolveCycleDay(
      day: date,
      start: start,
      startIndex: cycleStartIndex,
      length: days.length,
      pauses: restDays ?? const [],
      anchors: anchors,
    );
    final cycleIndex = cycleDay.index;
    final marker = markers[date];
    final carbLoadPerKg = marker?.type == DayMarkerType.carbLoad
        ? marker?.carbLoadCarbPerKg ?? StrategyRules.defaultCarbLoadCarbPerKg
        : null;
    final row = carbLoadPerKg != null
        ? plan.carbLoadDay(carbLoadPerKg)
        : days[cycleIndex];
    return _DayRow(
      key: ValueKey('cycleDay-$i'),
      name: AppDates.md(date, locale),
      isToday: date == today,
      type: row.dayType,
      paused: cycleDay.paused,
      marker: carbLoadPerKg != null || cycleDay.paused
          ? marker?.type ?? DayMarkerType.restDay
          : null,
      kcal: row.energy.round(),
      proteinG: row.proteinG.round(),
      carbG: row.carbG.round(),
      fatG: row.fatG.round(),
      onTap: editable && !cycleDay.paused && carbLoadPerKg == null
          ? () => onScheduleChanged!(plan.schedule.cycleDayType(cycleIndex))
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
    required this.paused,
    required this.marker,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.onTap,
  });

  final String name;
  final bool isToday;
  final CarbDayType type;

  /// A paused day stands outside the cycle: labelled by its [marker], its
  /// macros are those of the slot it holds (or the 冲碳日's own).
  final bool paused;

  /// Marker naming this row instead of its carb-day type: set for a paused
  /// day or a 冲碳日.
  final DayMarkerType? marker;
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
    final typeColor = paused ? scheme.onSurfaceVariant : _typeColor();

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
                      marker?.label(l10n) ?? type.label(l10n),
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
