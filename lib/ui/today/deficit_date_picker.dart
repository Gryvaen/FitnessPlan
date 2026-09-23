import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/day_marker_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../domain/day_marker.dart';
import '../../domain/deficit.dart';
import '../../domain/diet_plan.dart';
import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';

/// Loads the per-day target for every local day in an inclusive range.
typedef DailyTargetsLoader =
    Future<Map<DateTime, DailyNutritionTarget>> Function(
      DateTime start,
      DateTime end,
    );

/// Custom month calendar: actual daily deficit only on days with meal logs;
/// past days green/red verdict, today neutral.
Future<DateTime?> showDeficitDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required double plannedDeficit,
  required MealRepository mealRepository,
  required DayMarkerRepository markerRepository,
  required DailyTargetsLoader loadTargets,
  DateTime? calorieStandardSince,

  /// How far into the future the calendar may be paged for 放纵餐/休息日
  /// marking (long-press). Defaults to [lastDate] — pure date *selection*
  /// (tap + Confirm) always stays bounded by [firstDate]/[lastDate].
  DateTime? markUntil,
}) {
  DateTime? since;
  if (calorieStandardSince != null) {
    since = DateTime(
      calorieStandardSince.year,
      calorieStandardSince.month,
      calorieStandardSince.day,
    );
  }
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => _DeficitDatePickerDialog(
      initialDate: initialDate,
      firstDate: DateTime(firstDate.year, firstDate.month, firstDate.day),
      lastDate: DateTime(lastDate.year, lastDate.month, lastDate.day),
      plannedDeficit: plannedDeficit,
      mealRepository: mealRepository,
      markerRepository: markerRepository,
      loadTargets: loadTargets,
      calorieStandardSince: since,
      markUntil: markUntil == null
          ? null
          : DateTime(markUntil.year, markUntil.month, markUntil.day),
    ),
  );
}

class _DeficitDatePickerDialog extends StatefulWidget {
  const _DeficitDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.plannedDeficit,
    required this.mealRepository,
    required this.markerRepository,
    required this.loadTargets,
    this.calorieStandardSince,
    this.markUntil,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Today's planned deficit, shown in the formula caption.
  final double plannedDeficit;
  final MealRepository mealRepository;
  final DayMarkerRepository markerRepository;
  final DailyTargetsLoader loadTargets;
  final DateTime? calorieStandardSince;
  final DateTime? markUntil;

  @override
  State<_DeficitDatePickerDialog> createState() =>
      _DeficitDatePickerDialogState();
}

class _DeficitDatePickerDialogState extends State<_DeficitDatePickerDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;
  late DateTime _markUntil;
  Map<DateTime, double> _caloriesByDay = {};
  Map<DateTime, DailyNutritionTarget> _targetsByDay = {};
  Map<DateTime, DayMarkerType> _markersByDay = {};
  bool _loading = true;

  static final _okGreen = const Color(0xFF2A9D8F);
  static final _badRed = const Color(0xFFE76F51);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final init = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _selected = init;
    _visibleMonth = DateTime(init.year, init.month);
    _markUntil = widget.markUntil ?? widget.lastDate;
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final clampedStart = start.isBefore(widget.firstDate)
        ? widget.firstDate
        : start;
    final clampedEnd = end.isAfter(widget.lastDate) ? widget.lastDate : end;
    final empty = clampedStart.isAfter(clampedEnd);

    final markerClampedEnd = end.isAfter(_markUntil) ? _markUntil : end;
    final markersEmpty = clampedStart.isAfter(markerClampedEnd);

    final results = await Future.wait([
      empty
          ? Future.value(<DateTime, double>{})
          : widget.mealRepository.calorieTotalsBetween(
              clampedStart,
              clampedEnd,
            ),
      empty
          ? Future.value(<DateTime, DailyNutritionTarget>{})
          : widget.loadTargets(clampedStart, clampedEnd),
      markersEmpty
          ? Future.value(<DateTime, DayMarkerType>{})
          : widget.markerRepository.markersBetween(
              clampedStart,
              markerClampedEnd,
            ),
    ]);
    if (!mounted) return;
    setState(() {
      _caloriesByDay = results[0] as Map<DateTime, double>;
      _targetsByDay = results[1] as Map<DateTime, DailyNutritionTarget>;
      _markersByDay = results[2] as Map<DateTime, DayMarkerType>;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(_markUntil.year, _markUntil.month);
    if (next.isBefore(firstMonth) || next.isAfter(lastMonth)) return;
    setState(() => _visibleMonth = next);
    _loadMonth();
  }

  bool _isSelectable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);
  }

  bool _isMarkable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(widget.firstDate) && !d.isAfter(_markUntil);
  }

  Future<void> _showMarkerSheet(DateTime day) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const InkIcon(InkGlyph.celebration),
                title: Text(l10n.cheatMealLabel),
                onTap: () => Navigator.pop(ctx, 'cheatMeal'),
              ),
              ListTile(
                leading: const InkIcon(InkGlyph.bedtime),
                title: Text(l10n.restDayLabel),
                onTap: () => Navigator.pop(ctx, 'restDay'),
              ),
              ListTile(
                leading: const InkIcon(InkGlyph.close),
                title: Text(l10n.clearMarkerLabel),
                onTap: () => Navigator.pop(ctx, 'clear'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'cheatMeal':
        await widget.markerRepository.setCheatMeal(day);
        break;
      case 'restDay':
        await widget.markerRepository.setRestDay(day);
        break;
      case 'clear':
        await widget.markerRepository.clear(day);
        break;
    }
    if (!mounted) return;
    await _loadMonth();
  }

  List<String> _weekdayHeaders(Locale locale) {
    // 2024-01-01 was a Monday.
    final monday = DateTime(2024, 1, 1);
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale.languageCode).format(monday.add(Duration(days: i))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final today = _today;
    final monthLabel = AppDates.ym(_visibleMonth, locale);
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    // Monday-based: weekday 1=Mon … 7=Sun → leading empty cells
    final leading = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(_markUntil.year, _markUntil.month);
    final showPrev = _visibleMonth.isAfter(firstMonth);
    final showNext = _visibleMonth.isBefore(lastMonth);
    final weekdayHeaders = _weekdayHeaders(locale);

    // The selected day's real (logged) deficit, shown up top; falls back to
    // the plain formula line until that day actually has a meal log.
    // Fixed planned deficit only applies under 均衡缺口; otherwise the caption
    // shows remaining calories (target − intake) without a "计划缺口" term.
    final selectedTarget = _targetsByDay[_selected];
    final selectedIntake = _caloriesByDay[_selected];
    final dayPlanned =
        selectedTarget?.fixedPlannedDeficit ??
        (selectedTarget == null && widget.plannedDeficit > 0
            ? widget.plannedDeficit
            : null);
    final hasLog =
        selectedIntake != null &&
        selectedTarget != null &&
        !_selected.isAfter(today);
    final selectedActual = !hasLog
        ? null
        : dayPlanned != null
        ? actualDailyDeficit(
            plannedDeficit: dayPlanned,
            targetCalories: selectedTarget.calories,
            intakeCalories: selectedIntake,
          )
        : selectedTarget.calories - selectedIntake;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      title: Row(
        children: [
          IconButton(
            onPressed: showPrev ? () => _shiftMonth(-1) : null,
            icon: const InkIcon(InkGlyph.chevronLeft),
          ),
          Expanded(
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: showNext ? () => _shiftMonth(1) : null,
            icon: const InkIcon(InkGlyph.chevronRight),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedActual == null
                    ? (dayPlanned != null
                          ? l10n.actualDeficitFormula('${dayPlanned.round()}')
                          : l10n.calendarRemainingHint)
                    : dayPlanned != null
                    ? l10n.actualDeficitForDay(
                        AppDates.relativeDayTitle(
                          _selected,
                          today,
                          l10n,
                          locale,
                        ),
                        '${selectedActual.round()}',
                      )
                    : l10n.remainingCaloriesLine('${selectedActual.round()}'),
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _LegendSection(
                title: l10n.legendColors,
                children: [
                  _LegendDot(color: _okGreen, label: l10n.legendPastOk),
                  _LegendDot(color: _badRed, label: l10n.legendPastBad),
                  _LegendDot(
                    color: theme.colorScheme.onSurfaceVariant,
                    label: l10n.todayWord,
                  ),
                ],
              ),
              if (widget.calorieStandardSince != null) ...[
                const SizedBox(height: 12),
                _LegendSection(
                  title: l10n.legendStandardChange,
                  children: [
                    _LegendLine(
                      leading: Text('|', style: theme.textTheme.titleSmall),
                      label: l10n.legendNewStandardLine,
                    ),
                    _LegendLine(
                      leading: const InkIcon(InkGlyph.radioEmpty, size: 10),
                      label: l10n.legendBeforeNeutral,
                    ),
                    _LegendLine(
                      leading: const InkIcon(InkGlyph.radioEmpty, size: 10),
                      label: l10n.legendAfterGreenRed,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final w in weekdayHeaders)
                    Expanded(
                      child: Center(
                        child: Text(w, style: theme.textTheme.labelSmall),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: leading + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < leading) {
                      return const SizedBox.shrink();
                    }
                    final dayNum = index - leading + 1;
                    final date = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      dayNum,
                    );
                    return _DayCell(
                      date: date,
                      today: today,
                      selected: date == _selected,
                      selectable: _isSelectable(date),
                      intake: _caloriesByDay[date],
                      target: _targetsByDay[date],
                      calorieStandardSince: widget.calorieStandardSince,
                      okColor: _okGreen,
                      badColor: _badRed,
                      marker: _markersByDay[date],
                      markable: _isMarkable(date),
                      onTap: () => setState(() => _selected = date),
                      onLongPress: _isMarkable(date)
                          ? () => _showMarkerSheet(date)
                          : null,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSelectable(_selected)
              ? () => Navigator.pop(context, _selected)
              : null,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _LegendSection extends StatelessWidget {
  const _LegendSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _LegendLine(
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      label: label,
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 16, child: Center(child: leading)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.today,
    required this.selected,
    required this.selectable,
    required this.intake,
    required this.target,
    required this.okColor,
    required this.badColor,
    required this.onTap,
    required this.marker,
    required this.markable,
    this.calorieStandardSince,
    this.onLongPress,
  });

  final DateTime date;
  final DateTime today;
  final bool selected;
  final bool selectable;
  final double? intake;

  /// Target that governed this day (null when unknown → no verdict).
  final DailyNutritionTarget? target;
  final DateTime? calorieStandardSince;
  final Color okColor;
  final Color badColor;
  final VoidCallback onTap;

  /// 放纵餐/休息日 marker for this day, if any.
  final DayMarkerType? marker;

  /// Whether long-press marking is allowed for this day.
  final bool markable;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isPast = date.isBefore(today);
    final isToday = date == today;
    final marked = marker != null;
    final hasLog = intake != null;
    final since = calorieStandardSince;
    final t = target;
    final beforeStandard = since != null && date.isBefore(since);
    final showStandardBar = since != null && date == since;
    // Only days with meal logs and a known target show remaining calories;
    // empty days stay uncolored. The cell shows what's left of the day's
    // own target (target − intake); the plan-wide actual deficit — which
    // folds in the planned deficit too — is shown up top for the selected
    // day instead (see [_DeficitDatePickerDialogState.build]). Marked days
    // (放纵餐/休息日) show a short label instead, so verdict/remaining are
    // skipped entirely.
    final showRemaining =
        !marked && selectable && hasLog && t != null && (isPast || isToday);
    final remaining = showRemaining ? (t.calories - (intake ?? 0)) : null;
    // Finalize green/red only for days whose target is a real record (not a
    // legacy estimate) and on/after the latest calorie standard. Meeting the
    // planned deficit is equivalent to non-negative remaining calories
    // (actual = plannedDeficit + remaining), so no need for the combined
    // figure here.
    final legacy = t?.isLegacyEstimate ?? false;
    final useVerdict =
        !marked && remaining != null && isPast && !beforeStandard && !legacy;
    final met = remaining != null && remaining >= 0;

    Color? bg;
    Color fg = theme.colorScheme.onSurface;
    if (!selectable) {
      fg = theme.disabledColor;
    } else if (useVerdict) {
      bg = (met ? okColor : badColor).withValues(alpha: 0.22);
      fg = met ? okColor : badColor;
    } else if (remaining != null) {
      // Today, or past day before standard change: neutral number.
      fg = theme.colorScheme.onSurfaceVariant;
      if (selected && isToday) {
        bg = theme.colorScheme.primary.withValues(alpha: 0.2);
      }
    }

    if (selected && selectable && useVerdict) {
      bg = (met ? okColor : badColor).withValues(alpha: 0.45);
    } else if (selected && selectable && !useVerdict) {
      bg = theme.colorScheme.primary.withValues(alpha: isToday ? 0.35 : 0.45);
    }

    return Material(
      color: bg ?? Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: selectable ? onTap : null,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: showStandardBar
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                )
              : const BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (marked) ...[
                  const SizedBox(height: 1),
                  Text(
                    marker == DayMarkerType.cheatMeal
                        ? l10n.cheatMealShortLabel
                        : l10n.restDayShortLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ] else if (remaining != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    '${remaining.round()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
