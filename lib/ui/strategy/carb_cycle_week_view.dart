import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/diet_strategy.dart';
import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';
import 'strategy_labels.dart';

/// Seven-day carb-cycle view: tappable weekday chips (optionally editable),
/// details for the selected day and the weekly budget line.
class CarbCycleWeekView extends StatefulWidget {
  const CarbCycleWeekView({
    super.key,
    required this.plan,
    this.onScheduleChanged,
    this.initialSelected,
  });

  final CarbCyclePlan plan;

  /// When non-null the chips cycle H → M → L on tap.
  final ValueChanged<CarbCycleSchedule>? onScheduleChanged;

  /// Weekday index 0..6 to select initially (defaults to today).
  final int? initialSelected;

  @override
  State<CarbCycleWeekView> createState() => _CarbCycleWeekViewState();
}

class _CarbCycleWeekViewState extends State<CarbCycleWeekView> {
  late int _selected =
      widget.initialSelected ?? (DateTime.now().weekday - 1).clamp(0, 6);

  static const _cycle = [CarbDayType.high, CarbDayType.mid, CarbDayType.low];

  List<String> _weekdayShort(Locale locale) {
    final monday = DateTime(2024, 1, 1);
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale.toString()).format(monday.add(Duration(days: i))),
    ];
  }

  Color _typeColor(CarbDayType t, AppThemeVisuals v, ColorScheme scheme) =>
      switch (t) {
        CarbDayType.high => AppColors.carb,
        CarbDayType.mid => v.accent,
        CarbDayType.low => scheme.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final plan = widget.plan;
    final days = plan.integerDays();
    final names = _weekdayShort(locale);
    final editable = widget.onScheduleChanged != null;
    final sel = days[_selected];
    final todayIndex = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              Expanded(
                child: _DayChip(
                  name: names[i],
                  type: days[i].dayType,
                  typeLabel: days[i].dayType.shortLabel(l10n),
                  kcal: days[i].energy.round(),
                  color: _typeColor(days[i].dayType, visuals, scheme),
                  selected: i == _selected,
                  isToday: i == todayIndex,
                  onTap: () {
                    if (i == _selected && editable) {
                      final next =
                          _cycle[(_cycle.indexOf(days[i].dayType) + 1) %
                              _cycle.length];
                      widget.onScheduleChanged!(plan.schedule.withDay(i, next));
                    } else {
                      setState(() => _selected = i);
                    }
                  },
                ),
              ),
              if (i != 6) const SizedBox(width: 4),
            ],
          ],
        ),
        if (editable) ...[
          const SizedBox(height: 6),
          Text(l10n.carbCycleEditHint, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.section),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.section),
          decoration: BoxDecoration(
            color: visuals.accentSoft.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${names[_selected]} · ${sel.dayType.label(l10n)}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${sel.energy.round()} kcal · '
                'P ${sel.proteinG.toStringAsFixed(0)} · '
                'C ${sel.carbG.toStringAsFixed(0)} · '
                'F ${sel.fatG.toStringAsFixed(0)} g',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.compact),
        Text(
          l10n.weeklyBudgetLine(
            '${plan.weeklyEnergy.round()}',
            '${plan.weeklyAverage.round()}',
          ),
          style: theme.textTheme.bodySmall,
        ),
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

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.kcal,
    required this.color,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final String name;
  final CarbDayType type;
  final String typeLabel;
  final int kcal;
  final Color color;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$name $typeLabel $kcal kcal',
      child: Material(
        color: selected ? visuals.accentSoft : visuals.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(
            color: selected ? visuals.accent : visuals.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    typeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('$kcal', style: theme.textTheme.labelSmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
