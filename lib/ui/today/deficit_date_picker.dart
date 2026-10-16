import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/day_marker_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../domain/day_marker.dart';
import '../../domain/deficit.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';

/// Loads the per-day target for every local day in an inclusive range.
typedef DailyTargetsLoader =
    Future<Map<DateTime, DailyNutritionTarget>> Function(
      DateTime start,
      DateTime end,
    );

/// Resolves the strategy version governing a calendar day.
typedef DayStrategyLoader = Future<DietStrategyKind?> Function(DateTime day);

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
  required DayStrategyLoader loadStrategyForDay,
  DateTime? calorieStandardSince,

  /// How far into the future the calendar may be paged for 放纵日/休息日
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
      loadStrategyForDay: loadStrategyForDay,
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
    required this.loadStrategyForDay,
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
  final DayStrategyLoader loadStrategyForDay;
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
    final existing = await widget.markerRepository.settingsForDay(day);
    final strategy = await widget.loadStrategyForDay(day);
    if (!mounted) return;
    final choice = await showModalBottomSheet<_MarkerChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => _MarkerSettingsSheet(
        existing: existing,
        hasCarbCycle: strategy == DietStrategyKind.carbCycle,
        canPauseCycle:
            strategy == DietStrategyKind.carbCycle &&
            (!day.isBefore(_today) || existing?.pauseCarbCycle == true),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice.clear) {
      await widget.markerRepository.clear(day);
    } else if (choice.type == DayMarkerType.cheatMeal) {
      await widget.markerRepository.setCheatMeal(
        day,
        includeSteps: choice.includeSteps,
        includeDiet: choice.includeDiet,
        deductKcal: choice.deductKcal,
        penaltyKcal: choice.penaltyKcal,
      );
    } else {
      await widget.markerRepository.setRestDay(
        day,
        pauseCarbCycle: choice.pauseCarbCycle,
        includeSteps: choice.includeSteps,
        includeDiet: choice.includeDiet,
      );
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
    final selectedMarker = _markersByDay[_selected];
    final headerText = switch (selectedMarker) {
      DayMarkerType.cheatMeal => l10n.cheatMealShortLabel,
      DayMarkerType.restDay => l10n.restDayShortLabel,
      null =>
        selectedActual == null
            ? (dayPlanned != null
                  ? l10n.actualDeficitFormula('${dayPlanned.round()}')
                  : l10n.calendarRemainingHint)
            : dayPlanned != null
            ? l10n.actualDeficitForDay(
                AppDates.relativeDayTitle(_selected, today, l10n, locale),
                '${selectedActual.round()}',
              )
            : l10n.remainingCaloriesLine('${selectedActual.round()}'),
    };

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
                headerText,
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
                      key: ValueKey(
                        'deficitDay-${date.year}-${date.month}-${date.day}',
                      ),
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

class _MarkerChoice {
  const _MarkerChoice({
    required this.type,
    this.pauseCarbCycle = false,
    this.deductKcal = true,
    this.penaltyKcal = 1000,
    this.clear = false,
    this.includeSteps = true,
    this.includeDiet = false,
  });

  final DayMarkerType? type;
  final bool pauseCarbCycle;
  final bool deductKcal;
  final int penaltyKcal;
  final bool clear;
  final bool includeSteps;
  final bool includeDiet;
}

class _MarkerSettingsSheet extends StatefulWidget {
  const _MarkerSettingsSheet({
    required this.existing,
    required this.hasCarbCycle,
    required this.canPauseCycle,
  });

  final DayMarkerSettings? existing;
  final bool hasCarbCycle;
  final bool canPauseCycle;

  @override
  State<_MarkerSettingsSheet> createState() => _MarkerSettingsSheetState();
}

class _MarkerSettingsSheetState extends State<_MarkerSettingsSheet> {
  DayMarkerType? _type;
  DayMarkerType? _expandedType;
  late bool _pauseCycle;
  late bool _deductKcal;
  late TextEditingController _amount;
  final _amountFocus = FocusNode();
  bool _editingAmount = false;
  final _amountErrorTooltip = GlobalKey<TooltipState>();

  bool get _validAmount => (int.tryParse(_amount.text) ?? 0) > 0;
  final _stepsByType = {for (final type in DayMarkerType.values) type: true};
  final _dietByType = {
    DayMarkerType.cheatMeal: false,
    DayMarkerType.restDay: true,
  };

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type;
    if (widget.existing case final settings?) {
      _stepsByType[settings.type] = settings.includeSteps;
      _dietByType[settings.type] = settings.includeDiet;
    }
    _pauseCycle = widget.existing?.pauseCarbCycle ?? false;
    _deductKcal = widget.existing?.cheatPenaltyEnabled ?? true;
    _amount = TextEditingController(
      text: '${widget.existing?.cheatPenaltyKcal ?? 1000}',
    );
    _amount.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
    if (_editingAmount && !_validAmount) {
      _showAmountError();
    } else {
      Tooltip.dismissAllToolTips();
    }
  }

  void _showAmountError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editingAmount && !_validAmount) {
        _amountErrorTooltip.currentState?.ensureTooltipVisible();
      }
    });
  }

  void _select(DayMarkerType type) {
    _amountFocus.unfocus();
    setState(() {
      _editingAmount = false;
      if (_type == type) {
        _expandedType = _expandedType == type ? null : type;
      } else {
        _type = type;
        _expandedType = type;
      }
    });
  }

  void _setDeduction(bool value) {
    _amountFocus.unfocus();
    setState(() {
      _deductKcal = value;
      _editingAmount = false;
    });
  }

  void _startAmountEditing() {
    _amount.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amount.text.length,
    );
    setState(() => _editingAmount = true);
  }

  void _finishAmountEditing() {
    if (!_validAmount) {
      _amountFocus.requestFocus();
      _showAmountError();
      return;
    }
    _amountFocus.unfocus();
    Tooltip.dismissAllToolTips();
    setState(() => _editingAmount = false);
  }

  Widget _amountEditor(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final invalid = _editingAmount && !_validAmount;
    final color = invalid ? theme.colorScheme.error : accent;
    return SizedBox(
      key: const ValueKey('marker-penalty-toggle'),
      width: 112,
      height: 40,
      child: Tooltip(
        key: _amountErrorTooltip,
        message: l10n.positiveKcalRequired,
        excludeFromSemantics: true,
        triggerMode: TooltipTriggerMode.manual,
        preferBelow: false,
        child: Semantics(
          label: invalid
              ? l10n.positiveKcalRequired
              : l10n.deductionAmountLabel,
          liveRegion: invalid,
          button: !_editingAmount,
          child: InkWell(
            onTap: _editingAmount ? null : _startAmountEditing,
            child: Row(
              children: [
                Text('−', style: theme.textTheme.bodySmall),
                const SizedBox(width: 4),
                Expanded(
                  child: _editingAmount
                      ? TextField(
                          key: const ValueKey('marker-penalty-amount'),
                          controller: _amount,
                          focusNode: _amountFocus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () {},
                          onSubmitted: (_) => _finishAmountEditing(),
                          onTapOutside: (_) => _finishAmountEditing(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: const UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: color),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: color),
                            ),
                          ),
                        )
                      : Text(
                          _amount.text,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                ),
                const SizedBox(width: 4),
                Text(
                  'kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summary(BuildContext context, DayMarkerType type) {
    final l10n = context.l10n;
    final rule = type == DayMarkerType.restDay
        ? (_pauseCycle ? l10n.pauseCarbCycleSummary : l10n.keepCarbCycleSummary)
        : (_dietByType[type]!
              ? l10n.actualDietContributionHint
              : _deductKcal
              ? l10n.deductionSummary(_amount.text)
              : l10n.noDeductionSummary);
    return [
      _stepsByType[type]!
          ? l10n.stepsCountedSummary
          : l10n.stepsExcludedSummary,
      _dietByType[type]! ? l10n.dietCountedSummary : l10n.dietExcludedSummary,
      if (type == DayMarkerType.cheatMeal || widget.hasCarbCycle) rule,
    ].join(' · ');
  }

  Widget _option(BuildContext context, DayMarkerType type) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent =
        theme.extension<AppThemeVisuals>()?.accent ?? theme.colorScheme.primary;
    final selected = _type == type;
    final expanded = _expandedType == type;
    final rest = type == DayMarkerType.restDay;
    final label = rest ? l10n.restDayLabel : l10n.cheatMealLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          key: ValueKey('marker-option-${type.name}'),
          onTap: () => _select(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.compact,
              vertical: AppSpacing.field,
            ),
            child: Row(
              children: [
                InkIcon(
                  rest ? InkGlyph.bedtime : InkGlyph.celebration,
                  color: selected ? accent : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.field),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: selected ? accent : null,
                        ),
                      ),
                      if (selected && !expanded)
                        Text(
                          _summary(context, type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                InkIcon(
                  expanded
                      ? InkGlyph.collapse
                      : selected
                      ? InkGlyph.radioChecked
                      : InkGlyph.radioEmpty,
                  size: 20,
                  color: selected ? accent : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    44,
                    0,
                    AppSpacing.compact,
                    AppSpacing.field,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        key: ValueKey('marker-steps-${type.name}'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(l10n.stepsCountTowardCultivationLabel),
                        value: _stepsByType[type]!,
                        onChanged: (value) =>
                            setState(() => _stepsByType[type] = value),
                      ),
                      SwitchListTile.adaptive(
                        key: ValueKey('marker-diet-${type.name}'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(l10n.dietCountTowardCultivationLabel),
                        value: _dietByType[type]!,
                        onChanged: (value) {
                          _amountFocus.unfocus();
                          setState(() {
                            _dietByType[type] = value;
                            _editingAmount = false;
                          });
                        },
                      ),
                      if (rest) ...[
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(l10n.pauseCarbCycleLabel),
                          value: _pauseCycle,
                          onChanged: widget.canPauseCycle
                              ? (value) => setState(() => _pauseCycle = value)
                              : null,
                        ),
                      ] else if (!_dietByType[type]!) ...[
                        Row(
                          key: const ValueKey('marker-deduction-row'),
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _setDeduction(!_deductKcal),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    l10n.deductCultivationKcalLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ),
                            if (_deductKcal) _amountEditor(context, accent),
                            Semantics(
                              label: l10n.deductCultivationKcalLabel,
                              child: Switch.adaptive(
                                value: _deductKcal,
                                onChanged: _setDeduction,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amount.removeListener(_refresh);
    _amount.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dividerColor =
        theme.extension<AppThemeVisuals>()?.divider ??
        theme.colorScheme.outlineVariant;
    final amount = int.tryParse(_amount.text);
    final valid = amount != null && amount > 0;
    final canSave =
        _type != null &&
        (_type != DayMarkerType.cheatMeal ||
            _dietByType[_type]! ||
            !_deductKcal ||
            valid);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.card,
          AppSpacing.formPage,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.card,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dayMarkerSettingsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (widget.existing != null)
                    TextButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        const _MarkerChoice(type: null, clear: true),
                      ),
                      icon: const InkIcon(InkGlyph.delete, size: 18),
                      label: Text(l10n.clearMarkerLabel),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.field),
              _option(context, DayMarkerType.restDay),
              Divider(height: 1, color: dividerColor),
              _option(context, DayMarkerType.cheatMeal),
              const SizedBox(height: AppSpacing.card),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.compact),
                  FilledButton(
                    onPressed: canSave
                        ? () => Navigator.pop(
                            context,
                            _MarkerChoice(
                              type: _type,
                              includeSteps: _stepsByType[_type]!,
                              includeDiet: _dietByType[_type]!,
                              pauseCarbCycle: _pauseCycle,
                              deductKcal: _deductKcal,
                              penaltyKcal: valid ? amount : 1000,
                            ),
                          )
                        : null,
                    child: Text(l10n.confirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    super.key,
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

  /// 放纵日/休息日 marker for this day, if any.
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
    // (放纵日/休息日) show a short label instead, so verdict/remaining are
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
