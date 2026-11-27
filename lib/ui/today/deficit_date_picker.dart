import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../data/repositories/day_marker_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../domain/cut_cultivation.dart';
import '../../domain/day_marker.dart';
import '../../domain/deficit.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/goal_period.dart';
import '../../domain/maintain.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../strategy/stepper_row.dart';
import '../strategy/strategy_labels.dart';
import '../theme/app_theme.dart';

/// Loads the per-day target for every local day in an inclusive range.
typedef DailyTargetsLoader =
    Future<Map<DateTime, DailyNutritionTarget>> Function(
      DateTime start,
      DateTime end,
    );

/// Resolves the strategy version governing a calendar day.
typedef DayStrategyLoader = Future<DietStrategyKind?> Function(DateTime day);

/// The lowest 冲碳日 carbs (g/kg) for a calendar day — its carb-cycle plan's
/// high day — or null when unknown.
typedef CarbLoadFloorLoader = Future<double?> Function(DateTime day);

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
  CarbLoadFloorLoader? loadCarbLoadFloor,
  DateTime? calorieStandardSince,

  /// Cut rounds (修行时段). Inside a round every past day keeps its own
  /// green/red verdict even after a later standard change; outside, the
  /// [calorieStandardSince] cut-off still applies.
  List<CutCultivationSegment> cutSegments = const [],

  /// Days a strategy version took effect (see [strategyChangeDays]); each
  /// gets a corner flag, alongside the cut-round start line.
  Set<DateTime> strategyChangeDays = const {},

  /// How far into the future the calendar may be paged for 放纵日/休息日
  /// marking (long-press). Defaults to [lastDate] — pure date *selection*
  /// (tap + Confirm) always stays bounded by [firstDate]/[lastDate].
  DateTime? markUntil,

  /// Goal stretches (减脂 / 维持 / 增肌), marked at their boundaries in the
  /// goal's colour. Empty falls back to the old start line.
  List<GoalPeriod> goalPeriods = const [],

  /// Whether the marker sheet offers the 修为 settings (steps / diet count
  /// toward cultivation, 放纵日 deduction). 修为 only accrues while cutting.
  bool cultivationMarkers = true,

  /// Runs after a day's marker is saved or cleared, before the month
  /// reloads — e.g. to rewrite a past day's frozen target for 冲碳日.
  Future<void> Function(DateTime day)? onMarkerSaved,

  /// A booked goal switch not carried out yet: from its day on the marker
  /// sheet treats days as the new goal's.
  ({FitnessGoal goal, DateTime from})? bookedGoalSwitch,
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
      loadCarbLoadFloor: loadCarbLoadFloor,
      calorieStandardSince: since,
      cutSegments: [
        for (final s in cutSegments)
          CutCultivationSegment(
            start: AppDates.dayOnly(s.start),
            end: s.end == null ? null : AppDates.dayOnly(s.end!),
          ),
      ],
      strategyChangeDays: {
        for (final d in strategyChangeDays) AppDates.dayOnly(d),
      },
      markUntil: markUntil == null
          ? null
          : DateTime(markUntil.year, markUntil.month, markUntil.day),
      cultivationMarkers: cultivationMarkers,
      onMarkerSaved: onMarkerSaved,
      bookedGoalSwitch: bookedGoalSwitch == null
          ? null
          : (
              goal: bookedGoalSwitch.goal,
              from: AppDates.dayOnly(bookedGoalSwitch.from),
            ),
      goalPeriods: [
        for (final p in goalPeriods)
          GoalPeriod(
            goal: p.goal,
            start: AppDates.dayOnly(p.start),
            end: p.end == null ? null : AppDates.dayOnly(p.end!),
          ),
      ],
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
    this.loadCarbLoadFloor,
    this.calorieStandardSince,
    this.cutSegments = const [],
    this.strategyChangeDays = const {},
    this.markUntil,
    this.cultivationMarkers = true,
    this.goalPeriods = const [],
    this.onMarkerSaved,
    this.bookedGoalSwitch,
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
  final CarbLoadFloorLoader? loadCarbLoadFloor;
  final DateTime? calorieStandardSince;
  final List<CutCultivationSegment> cutSegments;
  final Set<DateTime> strategyChangeDays;
  final DateTime? markUntil;
  final bool cultivationMarkers;
  final List<GoalPeriod> goalPeriods;
  final Future<void> Function(DateTime day)? onMarkerSaved;
  final ({FitnessGoal goal, DateTime from})? bookedGoalSwitch;

  @override
  State<_DeficitDatePickerDialog> createState() =>
      _DeficitDatePickerDialogState();
}

class _DeficitDatePickerDialogState extends State<_DeficitDatePickerDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;
  late DateTime _markUntil;

  /// A marker sheet is being opened: a second long-press must not stack
  /// another one while its settings load.
  bool _openingMarkerSheet = false;
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

  /// Bumped per [_loadMonth]; paging months quickly must not let an earlier
  /// month's slower result overwrite the one now showing.
  int _monthRequest = 0;

  Future<void> _loadMonth() async {
    final request = ++_monthRequest;
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
    if (!mounted || request != _monthRequest) return;
    setState(() {
      _caloriesByDay = results[0] as Map<DateTime, double>;
      _targetsByDay = results[1] as Map<DateTime, DailyNutritionTarget>;
      _markersByDay = results[2] as Map<DateTime, DayMarkerType>;
      _loading = false;
    });
  }

  /// 「目标时段」legend: boundary brackets, goal colours, and verdict notes.
  Widget _goalPeriodLegend(BuildContext context) {
    final l10n = context.l10n;
    return _LegendSection(
      key: const ValueKey('goalPeriodLegend'),
      title: l10n.legendGoalPeriod,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final goal in FitnessGoal.values)
              Row(
                key: ValueKey('goalPeriodLegend-${goal.name}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GoalBracket(
                    color: _goalBracketColor(context, goal),
                    goal: goal,
                    isStart: true,
                  ),
                  Flexible(
                    child: Text(
                      goal.label(l10n),
                      style: Theme.of(context).textTheme.meta,
                    ),
                  ),
                  _GoalBracket(
                    color: _goalBracketColor(context, goal),
                    goal: goal,
                    isStart: false,
                  ),
                ],
              ),
          ],
        ),
        if (widget.cutSegments.isNotEmpty)
          _LegendLine(
            leading: const InkIcon(InkGlyph.radioEmpty, size: 10),
            label: l10n.legendCutRoundGreenRed,
          ),
        if (widget.calorieStandardSince != null)
          _LegendLine(
            leading: const InkIcon(InkGlyph.radioEmpty, size: 10),
            label: l10n.legendBeforeNeutral,
          ),
      ],
    );
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
    if (_openingMarkerSheet) return;
    _openingMarkerSheet = true;
    try {
      await _markerSheet(day);
    } finally {
      _openingMarkerSheet = false;
    }
  }

  /// The goal [day] is on: a booked switch from its day on, else the goal
  /// stretch holding it (a switch day already belongs to the new goal, even
  /// though the 修为 round still ends on it). Null when nothing records it.
  FitnessGoal? _goalOn(DateTime day) {
    final booked = widget.bookedGoalSwitch;
    if (booked != null && !day.isBefore(booked.from)) return booked.goal;
    return widget.goalPeriods.where((p) => p.containsDay(day)).lastOrNull?.goal;
  }

  Future<void> _markerSheet(DateTime day) async {
    final existing = await widget.markerRepository.settingsForDay(day);
    final strategy = await widget.loadStrategyForDay(day);
    // Markers follow the goal *that day* is on, as the calendar brackets
    // show it. A cut day offers 休息日 and the 修为 settings, also after a
    // later switch to 维持/增肌; a 维持/增肌 day only offers 放纵日.
    final goal = _goalOn(day);
    final inCut = goal != null
        ? goal == FitnessGoal.cut
        : strategy == DietStrategyKind.carbCycle ||
              (widget.cutSegments.isEmpty
                  ? widget.cultivationMarkers
                  : widget.cutSegments.any((s) => s.containsDay(day)));
    final carbCycle = inCut && strategy == DietStrategyKind.carbCycle;
    // Past cycle positions are frozen, so only today on can still delay.
    final canPauseCycle = carbCycle && !day.isBefore(_today);
    // 冲碳日 follows the stretch: any carb-cycle day, past ones included (a
    // past day's frozen target is rewritten through [onMarkerSaved]).
    final carbLoadFloor = carbCycle
        ? await widget.loadCarbLoadFloor?.call(day)
        : null;
    if (!mounted) return;
    final choice = await showModalBottomSheet<_MarkerChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => _MarkerSettingsSheet(
        existing: existing,
        canPauseCycle: canPauseCycle,
        canCarbLoad: carbCycle,
        carbLoadFloor: math.min(
          carbLoadFloor ?? StrategyRules.highCarbPerKgMin,
          StrategyRules.carbLoadCarbPerKgMax,
        ),
        offersRestDay: inCut,
        showCultivation: inCut,
      ),
    );
    if (!mounted || choice == null) return;
    final type = choice.type;
    if (choice.clear || type == null) {
      await widget.markerRepository.clear(day);
    } else {
      switch (type) {
        case DayMarkerType.cheatMeal:
          await widget.markerRepository.setCheatMeal(
            day,
            pauseCarbCycle: choice.pauseCarbCycle,
            includeSteps: choice.includeSteps,
            includeDiet: choice.includeDiet,
            deductKcal: choice.deductKcal,
            penaltyKcal: choice.penaltyKcal,
          );
        case DayMarkerType.restDay:
          await widget.markerRepository.setRestDay(
            day,
            pauseCarbCycle: choice.pauseCarbCycle,
            includeSteps: choice.includeSteps,
            includeDiet: choice.includeDiet,
          );
        case DayMarkerType.carbLoad:
          await widget.markerRepository.setCarbLoad(
            day,
            carbPerKg: choice.carbPerKg,
            pauseCarbCycle: choice.pauseCarbCycle,
            includeSteps: choice.includeSteps,
            includeDiet: choice.includeDiet,
          );
      }
    }
    await widget.onMarkerSaved?.call(day);
    if (!mounted) return;
    await _loadMonth();
  }

  List<String> _weekdayHeaders(Locale locale) {
    // 2024-01-01 was a Monday.
    final monday = DateTime(2024, 1, 1);
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale.languageCode).format(AppDates.addDays(monday, i)),
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
      // 冲碳日 has a real target, so it reads like an unmarked day.
      DayMarkerType.carbLoad || null =>
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
              style: theme.textTheme.subsectionTitle,
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
              if (widget.goalPeriods.isNotEmpty) ...[
                const SizedBox(height: 12),
                _goalPeriodLegend(context),
              ] else if (widget.cutSegments.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LegendSection(
                  title: l10n.legendCutRound,
                  children: [
                    _LegendLine(
                      leading: Text('|', style: theme.textTheme.titleSmall),
                      label: l10n.legendCutRoundStartLine,
                    ),
                    _LegendLine(
                      leading: const InkIcon(InkGlyph.radioEmpty, size: 10),
                      label: l10n.legendCutRoundGreenRed,
                    ),
                  ],
                ),
              ] else if (widget.calorieStandardSince != null) ...[
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
              if (_targetsByDay.values.any((t) => t.isMaintainDay)) ...[
                const SizedBox(height: 12),
                _LegendSection(
                  title: l10n.legendMaintainDays,
                  children: [
                    _LegendLine(
                      leading: const InkIcon(InkGlyph.radioEmpty, size: 10),
                      label: l10n.legendMaintainBand(
                        (maintainBandFraction * 100).round(),
                      ),
                    ),
                  ],
                ),
              ],
              if (_targetsByDay.values.any((t) => t.isBulkDay)) ...[
                const SizedBox(height: 12),
                _LegendSection(
                  title: l10n.legendBulkDays,
                  children: [
                    _LegendLine(
                      leading: const InkIcon(InkGlyph.radioEmpty, size: 10),
                      label: l10n.legendBulkBand(
                        (bulkBandFraction * 100).round(),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.strategyChangeDays.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LegendSection(
                  title: l10n.legendStrategyChange,
                  children: [
                    _LegendLine(
                      leading: _CornerFlag(
                        color: theme.colorScheme.primary,
                        size: 9,
                      ),
                      label: l10n.legendStrategyChangeFlag,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    const columns = 7;
                    const gap = 4.0;
                    final cellWidth =
                        (constraints.maxWidth - (columns - 1) * gap) / columns;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: gap,
                        crossAxisSpacing: gap,
                        mainAxisExtent: math.max(44.0, cellWidth / 0.72),
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
                          cutSegments: widget.cutSegments,
                          inGoalPeriod: widget.goalPeriods.any(
                            (p) => p.containsDay(date),
                          ),
                          strategyChange: widget.strategyChangeDays.contains(
                            date,
                          ),
                          periodStart: widget.goalPeriods
                              .where((p) => p.start == date)
                              .lastOrNull
                              ?.goal,
                          periodEnd: widget.goalPeriods
                              .where((p) => p.end == date)
                              .firstOrNull
                              ?.goal,
                          hasGoalPeriods: widget.goalPeriods.isNotEmpty,
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
    this.carbPerKg = StrategyRules.defaultCarbLoadCarbPerKg,
  });

  final DayMarkerType? type;
  final bool pauseCarbCycle;
  final bool deductKcal;
  final int penaltyKcal;
  final bool clear;
  final bool includeSteps;
  final bool includeDiet;

  /// 冲碳日 carbs (g/kg); ignored for other types.
  final double carbPerKg;
}

class _MarkerSettingsSheet extends StatefulWidget {
  const _MarkerSettingsSheet({
    required this.existing,
    required this.canPauseCycle,
    required this.canCarbLoad,
    required this.carbLoadFloor,
    this.offersRestDay = true,
    this.showCultivation = true,
  });

  final DayMarkerSettings? existing;

  /// Offer the 修为 settings; off outside fat loss, where 修为 doesn't run.
  final bool showCultivation;

  /// Offer 休息日: a cut day. 维持/增肌 days only get 放纵日 — with no carb
  /// cycle or 修为 a rest day would change nothing.
  final bool offersRestDay;

  /// The 碳循环顺延 switch: a carb-cycle day from today on.
  final bool canPauseCycle;

  /// Offer 冲碳日: any carb-cycle day, past ones included.
  final bool canCarbLoad;

  /// Lowest 冲碳日 carbs (g/kg): the day's high-day carbs.
  final double carbLoadFloor;

  @override
  State<_MarkerSettingsSheet> createState() => _MarkerSettingsSheetState();
}

class _MarkerSettingsSheetState extends State<_MarkerSettingsSheet> {
  DayMarkerType? _type;
  DayMarkerType? _expandedType;
  late double _carbPerKg;
  late bool _deductKcal;
  late TextEditingController _amount;
  final _amountFocus = FocusNode();
  bool _editingAmount = false;
  final _amountErrorTooltip = GlobalKey<TooltipState>();

  bool get _validAmount => (int.tryParse(_amount.text) ?? 0) > 0;
  final _stepsByType = {for (final type in DayMarkerType.values) type: true};
  final _dietByType = {
    for (final type in DayMarkerType.values)
      type: DayMarkerSettings(type: type).includeDiet,
  };
  final _pauseByType = {for (final type in DayMarkerType.values) type: false};

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type;
    // A leftover marker of a type this day no longer offers (a 冲碳日 off the
    // carb cycle, a 休息日 outside cut) starts unselected so 确认 can't
    // silently re-save it.
    if (_type != null && !_offers(_type!)) _type = null;
    if (widget.existing case final settings?) {
      _stepsByType[settings.type] = settings.includeSteps;
      _dietByType[settings.type] = settings.includeDiet;
      _pauseByType[settings.type] = settings.pauseCarbCycle;
      // Where the delay can't be edited (a past day, or no carb cycle), it
      // carries over to whichever type is picked: each type's default would
      // otherwise silently drop it and shift every later cycle day.
      if (!widget.canPauseCycle) {
        for (final type in DayMarkerType.values) {
          _pauseByType[type] = settings.pauseCarbCycle;
        }
      }
    }
    _carbPerKg = math.max(
      widget.existing?.carbLoadCarbPerKg ??
          StrategyRules.defaultCarbLoadCarbPerKg,
      widget.carbLoadFloor,
    );
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

  /// Which marker types this day lists: 放纵日 always (通用日), 休息日 on cut
  /// days, 冲碳日 (专属日) on carb-cycle days.
  bool _offers(DayMarkerType type) => switch (type) {
    DayMarkerType.cheatMeal => true,
    DayMarkerType.restDay => widget.offersRestDay,
    DayMarkerType.carbLoad => widget.canCarbLoad,
  };

  bool get _offersCarbLoad => _offers(DayMarkerType.carbLoad);

  /// A saved 冲碳日 must be cleared before the day can become a 休息日/放纵日:
  /// switching would silently drop its carb-cycle–specific settings. A
  /// leftover one outside the cycle (hidden) doesn't lock anything.
  bool _lockedByCarbLoad(DayMarkerType type) =>
      _offersCarbLoad &&
      type != DayMarkerType.carbLoad &&
      widget.existing?.type == DayMarkerType.carbLoad;

  /// Whether [type] has settings to unfold (none for a 维持/增肌 放纵日).
  bool _hasDetails(DayMarkerType type) =>
      type == DayMarkerType.carbLoad ||
      widget.showCultivation ||
      widget.canPauseCycle;

  void _select(DayMarkerType type) {
    if (_lockedByCarbLoad(type)) return;
    _amountFocus.unfocus();
    setState(() {
      _editingAmount = false;
      if (!_hasDetails(type)) {
        _type = type;
        _expandedType = null;
      } else if (_type == type) {
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
                Text('−', style: theme.textTheme.meta),
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
                          style: theme.textTheme.meta,
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
                          style: theme.textTheme.meta,
                        ),
                ),
                const SizedBox(width: 4),
                Text(
                  'kcal',
                  style: theme.textTheme.meta?.copyWith(
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
    return [
      if (type == DayMarkerType.carbLoad)
        l10n.carbLoadSummary(_carbPerKg.toStringAsFixed(1)),
      if (widget.showCultivation)
        _stepsByType[type]!
            ? l10n.stepsCountedSummary
            : l10n.stepsExcludedSummary,
      if (widget.showCultivation)
        _dietByType[type]! ? l10n.dietCountedSummary : l10n.dietExcludedSummary,
      if (widget.showCultivation && type == DayMarkerType.cheatMeal)
        _dietByType[type]!
            ? l10n.actualDietContributionHint
            : _deductKcal
            ? l10n.deductionSummary(_amount.text)
            : l10n.noDeductionSummary,
      if (widget.canPauseCycle)
        _pauseByType[type]!
            ? l10n.pauseCarbCycleSummary
            : l10n.keepCarbCycleSummary,
    ].join(' · ');
  }

  Widget _option(BuildContext context, DayMarkerType type) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent =
        theme.extension<AppThemeVisuals>()?.accent ?? theme.colorScheme.primary;
    final selected = _type == type;
    final expanded = _expandedType == type;
    final locked = _lockedByCarbLoad(type);
    // Only a carb-cycle day from today on can still be delayed; elsewhere the
    // switch is hidden (a saved delay still carries over, see initState).
    final showPause = widget.canPauseCycle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          key: ValueKey('marker-option-${type.name}'),
          onTap: locked ? null : () => _select(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.compact,
              vertical: AppSpacing.field,
            ),
            child: Row(
              children: [
                InkIcon(
                  type.glyph,
                  color: locked
                      ? theme.disabledColor
                      : selected
                      ? accent
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.field),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label(l10n),
                        style: theme.textTheme.rowTitle?.copyWith(
                          color: locked
                              ? theme.disabledColor
                              : selected
                              ? accent
                              : null,
                        ),
                      ),
                      if (locked)
                        Text(
                          l10n.carbLoadLockedHint,
                          style: theme.textTheme.meta?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else if (selected &&
                          !expanded &&
                          _summary(context, type).isNotEmpty)
                        Text(
                          _summary(context, type),
                          style: theme.textTheme.meta?.copyWith(
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
                  color: locked
                      ? theme.disabledColor
                      : selected
                      ? accent
                      : theme.colorScheme.onSurfaceVariant,
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
                      if (type == DayMarkerType.carbLoad) ...[
                        StepperRow(
                          key: const ValueKey('marker-carb-load-stepper'),
                          label: l10n.carbLoadCarbPerKgLabel,
                          value: _carbPerKg,
                          min: widget.carbLoadFloor,
                          max: StrategyRules.carbLoadCarbPerKgMax,
                          step: 0.1,
                          unit: 'g/kg',
                          onChanged: (v) => setState(() => _carbPerKg = v),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.carbLoadHint,
                            style: theme.textTheme.meta?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      if (widget.showCultivation)
                        SwitchListTile.adaptive(
                          key: ValueKey('marker-steps-${type.name}'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(l10n.stepsCountTowardCultivationLabel),
                          value: _stepsByType[type]!,
                          onChanged: (value) =>
                              setState(() => _stepsByType[type] = value),
                        ),
                      if (widget.showCultivation)
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
                      if (showPause)
                        SwitchListTile.adaptive(
                          key: ValueKey('marker-pause-${type.name}'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(l10n.pauseCarbCycleLabel),
                          value: _pauseByType[type]!,
                          onChanged: (value) =>
                              setState(() => _pauseByType[type] = value),
                        ),
                      if (widget.showCultivation &&
                          type == DayMarkerType.cheatMeal &&
                          !_dietByType[type]!) ...[
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
                                    style: theme.textTheme.rowTitle,
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
                      style: theme.textTheme.sectionTitle,
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
              if (_offers(DayMarkerType.restDay)) ...[
                _option(context, DayMarkerType.restDay),
                Divider(height: 1, color: dividerColor),
              ],
              _option(context, DayMarkerType.cheatMeal),
              if (_offersCarbLoad) ...[
                Divider(height: 1, color: dividerColor),
                _option(context, DayMarkerType.carbLoad),
              ],
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
                              pauseCarbCycle: _pauseByType[_type]!,
                              deductKcal: _deductKcal,
                              penaltyKcal: valid ? amount : 1000,
                              carbPerKg: _carbPerKg,
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
  const _LegendSection({
    super.key,
    required this.title,
    required this.children,
  });

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
  const _LegendDot({super.key, required this.color, required this.label});

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
        Expanded(child: Text(label, style: Theme.of(context).textTheme.meta)),
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
    this.cutSegments = const [],
    this.inGoalPeriod = false,
    this.strategyChange = false,
    this.periodStart,
    this.periodEnd,
    required this.hasGoalPeriods,
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

  /// Cut rounds; a day inside one ignores the [calorieStandardSince] cut-off.
  final List<CutCultivationSegment> cutSegments;

  /// Inside a recorded goal stretch (减脂 / 维持 / 增肌): judged against its
  /// own snapshot, ignoring the [calorieStandardSince] cut-off, which a later
  /// goal switch moves past it.
  final bool inGoalPeriod;

  /// A strategy version took effect on this day (corner flag).
  final bool strategyChange;

  /// Goal whose stretch starts / ends on this day.
  final FitnessGoal? periodStart;
  final FitnessGoal? periodEnd;

  /// Goal history supersedes the legacy cut-round and standard start lines.
  final bool hasGoalPeriods;
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
    final start = periodStart;
    final end = periodEnd;

    Widget bracket(FitnessGoal goal, {required bool isStart}) {
      return Semantics(
        key: ValueKey(isStart ? 'goalPeriodStart' : 'goalPeriodEnd'),
        label:
            '${goal.label(l10n)}, '
            '${isStart ? l10n.legendPeriodStart : l10n.legendPeriodEnd}',
        child: _GoalBracket(
          color: _goalBracketColor(context, goal),
          goal: goal,
          isStart: isStart,
        ),
      );
    }

    final isPast = date.isBefore(today);
    final isToday = date == today;
    final marked = marker != null;
    // 冲碳日 keeps a real target, so it still gets remaining/verdict; the
    // other markers show only their label.
    final verdictMarker = marker == null || marker == DayMarkerType.carbLoad;
    final hasLog = intake != null;
    final since = calorieStandardSince;
    final t = target;
    // A cut round is judged as a whole: each day against its own snapshot
    // target, so a mid-round standard change doesn't blank earlier days.
    final inCutRound = cutSegments.any((s) => s.containsDay(date));
    // 维持 / 增肌 days carry their goal tag, so they keep their verdict even
    // without recorded goal stretches (old installs).
    final goalTagged = (t?.isMaintainDay ?? false) || (t?.isBulkDay ?? false);
    final beforeStandard =
        !inCutRound &&
        !inGoalPeriod &&
        !goalTagged &&
        since != null &&
        date.isBefore(since);
    final showStandardBar =
        !hasGoalPeriods &&
        (cutSegments.isNotEmpty
            ? cutSegments.any((s) => s.start == date)
            : since != null && date == since);
    // Only days with meal logs and a known target show remaining calories;
    // empty days stay uncolored. The cell shows what's left of the day's
    // own target (target − intake); the plan-wide actual deficit — which
    // folds in the planned deficit too — is shown up top for the selected
    // day instead (see [_DeficitDatePickerDialogState.build]). Marked days
    // show a short label instead of the number; 放纵日/休息日 skip the
    // verdict entirely, while 冲碳日 keeps its green/red tint.
    final showRemaining =
        verdictMarker &&
        selectable &&
        hasLog &&
        t != null &&
        (isPast || isToday);
    final remaining = showRemaining ? (t.calories - (intake ?? 0)) : null;
    // Finalize green/red only for days whose target is a real record (not a
    // legacy estimate) and on/after the latest calorie standard. Meeting the
    // planned deficit is equivalent to non-negative remaining calories
    // (actual = plannedDeficit + remaining), so no need for the combined
    // figure here.
    final legacy = t?.isLegacyEstimate ?? false;
    final useVerdict =
        verdictMarker &&
        remaining != null &&
        isPast &&
        !beforeStandard &&
        !legacy;
    // 维持 days must land inside the ±10% band (see [intakeMet]); other days
    // only need to stay under their target.
    final met = remaining != null && intakeMet(t!, intake ?? 0);

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

    final dayNumber = Text(
      '${date.day}',
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
        color: fg,
      ),
    );

    final caption = marker?.shortLabel(l10n) ?? remaining?.round().toString();

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
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                // Keep the corner flag above the date row, even on days
                // without a flag, so every date has the same vertical anchor.
                padding: const EdgeInsets.fromLTRB(1, 9, 1, 2),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          textDirection: TextDirection.ltr,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (start != null)
                              bracket(start, isStart: true)
                            else
                              const SizedBox(width: _GoalBracket.width),
                            dayNumber,
                            if (end != null)
                              bracket(end, isStart: false)
                            else
                              const SizedBox(width: _GoalBracket.width),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                      flex: 2,
                      child: caption == null
                          ? const SizedBox.shrink()
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                caption,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: fg,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              if (strategyChange)
                Positioned(
                  top: 2,
                  left: 2,
                  child: _CornerFlag(color: theme.colorScheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _goalBracketColor(BuildContext context, FitnessGoal goal) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (goal) {
    FitnessGoal.bulk =>
      dark ? const Color(0xFFE0A087) : const Color(0xFF99513A),
    FitnessGoal.cut => dark ? const Color(0xFFA9BDE2) : const Color(0xFF3C5D89),
    FitnessGoal.maintain =>
      dark ? const Color(0xFF90C5B8) : const Color(0xFF2C6D63),
  };
}

class _GoalBracket extends StatelessWidget {
  const _GoalBracket({
    required this.color,
    required this.isStart,
    required this.goal,
  });

  static const width = 8.0;

  final Color color;
  final bool isStart;
  final FitnessGoal goal;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(width, 13),
      painter: _GoalBracketPainter(color, isStart, goal),
    );
  }
}

class _GoalBracketPainter extends CustomPainter {
  const _GoalBracketPainter(this.color, this.isStart, this.goal);

  final Color color;
  final bool isStart;
  final FitnessGoal goal;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height - 1;
    final span = bottom - 1;
    final middle = size.height / 2;
    double x(double offset) => isStart ? offset : size.width - offset;

    final path = Path()..moveTo(x(6.5), 1);
    switch (goal) {
      case FitnessGoal.bulk:
        path
          ..lineTo(x(1.5), 1)
          ..lineTo(x(1.5), bottom)
          ..lineTo(x(6.5), bottom);
      case FitnessGoal.cut:
        final shoulder = span * .28;
        path
          ..cubicTo(x(3), 1, x(4.5), 1 + shoulder / 2, x(4.5), 1 + shoulder)
          ..cubicTo(x(4.5), middle, x(3.5), middle, x(1.5), middle)
          ..cubicTo(x(3.5), middle, x(4.5), middle, x(4.5), bottom - shoulder)
          ..cubicTo(
            x(4.5),
            bottom - shoulder / 2,
            x(3),
            bottom,
            x(6.5),
            bottom,
          );
      case FitnessGoal.maintain:
        path.cubicTo(
          x(0),
          1 + span * .24,
          x(0),
          bottom - span * .24,
          x(6.5),
          bottom,
        );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GoalBracketPainter old) =>
      old.color != color || old.isStart != isStart || old.goal != goal;
}

/// Small right-angled triangle pinned to a day cell's top-left corner: a
/// strategy version took effect that day. Also used as the legend glyph.
class _CornerFlag extends StatelessWidget {
  const _CornerFlag({required this.color, this.size = 7})
    : super(key: const ValueKey('strategyChangeFlag'));

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CornerFlagPainter(color),
    );
  }
}

class _CornerFlagPainter extends CustomPainter {
  const _CornerFlagPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CornerFlagPainter oldDelegate) =>
      oldDelegate.color != color;
}
