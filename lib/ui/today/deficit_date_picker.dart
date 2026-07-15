import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/meal_repository.dart';

/// 实际日缺口 = 计划日缺口 + 剩余热量（目标摄入 − 实际摄入）
double actualDailyDeficit({
  required double plannedDeficit,
  required double targetCalories,
  required double intakeCalories,
}) =>
    plannedDeficit + (targetCalories - intakeCalories);

/// 实际日缺口是否达到计划日缺口（用于收官着色）。
bool meetsPlannedDeficit({
  required double plannedDeficit,
  required double targetCalories,
  required double intakeCalories,
}) =>
    actualDailyDeficit(
      plannedDeficit: plannedDeficit,
      targetCalories: targetCalories,
      intakeCalories: intakeCalories,
    ) >=
    plannedDeficit;

/// 自定义月历：有饮食记录的日子才显示实际日缺口；过去日绿/红收官，今天中性色。
Future<DateTime?> showDeficitDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required double plannedDeficit,
  required double targetCalories,
  required MealRepository mealRepository,
  DateTime? calorieStandardSince,
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
      targetCalories: targetCalories,
      mealRepository: mealRepository,
      calorieStandardSince: since,
    ),
  );
}

class _DeficitDatePickerDialog extends StatefulWidget {
  const _DeficitDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.plannedDeficit,
    required this.targetCalories,
    required this.mealRepository,
    this.calorieStandardSince,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final double plannedDeficit;
  final double targetCalories;
  final MealRepository mealRepository;
  final DateTime? calorieStandardSince;


  @override
  State<_DeficitDatePickerDialog> createState() =>
      _DeficitDatePickerDialogState();
}

class _DeficitDatePickerDialogState extends State<_DeficitDatePickerDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;
  Map<DateTime, double> _caloriesByDay = {};
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
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final clampedStart =
        start.isBefore(widget.firstDate) ? widget.firstDate : start;
    final clampedEnd = end.isAfter(widget.lastDate) ? widget.lastDate : end;
    final map = clampedStart.isAfter(clampedEnd)
        ? <DateTime, double>{}
        : await widget.mealRepository.calorieTotalsBetween(
            clampedStart,
            clampedEnd,
          );
    if (!mounted) return;
    setState(() {
      _caloriesByDay = map;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final firstMonth =
        DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    if (next.isBefore(firstMonth) || next.isAfter(lastMonth)) return;
    setState(() => _visibleMonth = next);
    _loadMonth();
  }

  bool _isSelectable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _today;
    final monthLabel = DateFormat('yyyy年M月').format(_visibleMonth);
    final firstOfMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    // Monday-based: weekday 1=Mon … 7=Sun → leading empty cells
    final leading = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    final firstMonth =
        DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    final showPrev = _visibleMonth.isAfter(firstMonth);
    final showNext = _visibleMonth.isBefore(lastMonth);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      title: Row(
        children: [
          IconButton(
            onPressed: showPrev ? () => _shiftMonth(-1) : null,
            icon: const Icon(Icons.chevron_left),
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
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '实际日缺口 = 日缺口 ${widget.plannedDeficit.round()} + 剩余热量',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _LegendSection(
              title: '颜色',
              children: [
                _LegendDot(color: _okGreen, label: '过去 · 达标（≥日缺口）'),
                _LegendDot(color: _badRed, label: '过去 · 未达标（<日缺口）'),
                _LegendDot(
                  color: theme.colorScheme.onSurfaceVariant,
                  label: '今天 · 进行中（不判绿红）',
                ),
              ],
            ),
            if (widget.calorieStandardSince != null) ...[
              const SizedBox(height: 12),
              _LegendSection(
                title: '热量标准变更',
                children: [
                  _LegendLine(
                    leading: Text(
                      '|',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    label: '生效日左侧竖线',
                  ),
                  const _LegendLine(
                    leading: Icon(Icons.circle_outlined, size: 10),
                    label: '生效日之前：有记录只显示中性数字',
                  ),
                  const _LegendLine(
                    leading: Icon(Icons.circle_outlined, size: 10),
                    label: '生效日及之后：过去绿/红，今天中性',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                for (final w in ['一', '二', '三', '四', '五', '六', '日'])
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                    plannedDeficit: widget.plannedDeficit,
                    targetCalories: widget.targetCalories,
                    calorieStandardSince: widget.calorieStandardSince,
                    okColor: _okGreen,
                    badColor: _badRed,
                    onTap: () => setState(() => _selected = date),
                  );
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSelectable(_selected)
              ? () => Navigator.pop(context, _selected)
              : null,
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _LegendSection extends StatelessWidget {
  const _LegendSection({
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
  const _LegendLine({
    required this.leading,
    required this.label,
  });

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Center(child: leading),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
    required this.plannedDeficit,
    required this.targetCalories,
    required this.okColor,
    required this.badColor,
    required this.onTap,
    this.calorieStandardSince,
  });

  final DateTime date;
  final DateTime today;
  final bool selected;
  final bool selectable;
  final double? intake;
  final double plannedDeficit;
  final double targetCalories;
  final DateTime? calorieStandardSince;
  final Color okColor;
  final Color badColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = date.isBefore(today);
    final isToday = date == today;
    final hasLog = intake != null;
    final since = calorieStandardSince;
    final beforeStandard = since != null && date.isBefore(since);
    final showStandardBar = since != null && date == since;
    // Only days with meal logs show deficit; empty days stay uncolored.
    final showDeficit = selectable && hasLog && (isPast || isToday);
    final actual = showDeficit
        ? actualDailyDeficit(
            plannedDeficit: plannedDeficit,
            targetCalories: targetCalories,
            intakeCalories: intake!,
          )
        : null;
    // Finalize green/red only for days on/after the latest calorie standard.
    final useVerdict = actual != null && isPast && !beforeStandard;
    final met = actual != null && actual >= plannedDeficit;

    Color? bg;
    Color fg = theme.colorScheme.onSurface;
    if (!selectable) {
      fg = theme.disabledColor;
    } else if (useVerdict) {
      bg = (met ? okColor : badColor).withValues(alpha: 0.22);
      fg = met ? okColor : badColor;
    } else if (actual != null) {
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (actual != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    '${actual.round()}',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: fg,
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
