import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/repositories/step_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';

/// Above this many calendar days, the step chart shows one bar per week.
const kStepChartWeeklyAfterDays = 60;

/// How long one chart takes to draw in.
const _kDrawDuration = Duration(milliseconds: 900);

/// Width of the 「N 次 · 完成 X%」 column beside each plan bar.
const _kPlanStatWidth = 112.0;

/// Head start of the step chart over the plan chart.
const _kStagger = Duration(milliseconds: 150);

/// One bar of the step chart: a day, or a week starting on [date].
typedef StepBar = ({DateTime date, double steps});

/// Bars for the step chart plus the daily average over days that have steps.
class StepChartData {
  const StepChartData({
    required this.bars,
    required this.weekly,
    required this.dailyAverage,
  });

  /// Oldest first.
  final List<StepBar> bars;

  /// Each bar is a week's daily average (days with steps only).
  final bool weekly;

  /// Mean of the days with steps; 0 when there are none.
  final double dailyAverage;

  bool get isEmpty => dailyAverage <= 0;
}

/// Lays [days] out on a calendar: every day from the first logged one to
/// [today] gets a bar (0 when nothing was logged). Longer than
/// [kStepChartWeeklyAfterDays] days, bars become Monday-start weeks holding
/// that week's daily average over its days with steps.
StepChartData stepChartData(List<StepDay> days, {DateTime? today}) {
  final byDay = <DateTime, int>{};
  for (final d in days) {
    final day = AppDates.dayOnly(d.date);
    byDay[day] = (byDay[day] ?? 0) + d.steps;
  }
  final active = [
    for (final v in byDay.values)
      if (v > 0) v,
  ];
  final average = active.isEmpty
      ? 0.0
      : active.reduce((a, b) => a + b) / active.length;
  if (byDay.isEmpty) {
    return const StepChartData(bars: [], weekly: false, dailyAverage: 0);
  }
  final first = byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  final lastLogged = byDay.keys.reduce((a, b) => a.isAfter(b) ? a : b);
  final end = today == null ? lastLogged : AppDates.dayOnly(today);
  final last = end.isBefore(lastLogged) ? lastLogged : end;
  final span = AppDates.daysBetween(first, last) + 1;

  if (span <= kStepChartWeeklyAfterDays) {
    return StepChartData(
      bars: [
        for (var i = 0; i < span; i++)
          (
            date: AppDates.addDays(first, i),
            steps: (byDay[AppDates.addDays(first, i)] ?? 0).toDouble(),
          ),
      ],
      weekly: false,
      dailyAverage: average,
    );
  }

  final firstWeek = AppDates.addDays(first, 1 - first.weekday);
  final bars = <StepBar>[];
  for (
    var week = firstWeek;
    !week.isAfter(last);
    week = AppDates.addDays(week, 7)
  ) {
    var sum = 0;
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final v = byDay[AppDates.addDays(week, i)] ?? 0;
      if (v > 0) {
        sum += v;
        count++;
      }
    }
    bars.add((date: week, steps: count == 0 ? 0 : sum / count));
  }
  return StepChartData(bars: bars, weekly: true, dailyAverage: average);
}

/// One plan's row in the plan chart.
class PlanChartRow {
  const PlanChartRow({
    required this.name,
    required this.days,
    required this.done,
    required this.total,
  });

  final String name;

  /// Distinct days the plan was worked.
  final int days;

  /// Items done / planned, summed over those days. [total] is 0 for
  /// free-form training, which has no plan to complete.
  final int done;
  final int total;

  /// 0..1, or null when there was nothing planned to complete.
  double? get completion => total <= 0 ? null : (done / total).clamp(0, 1);
}

/// Groups [days] by plan: how many days each plan was worked and how much
/// of it was completed. Plans without a name, and days logged without any
/// plan, go under [untitled]. Most-trained first, then by name.
List<PlanChartRow> planChartRows(
  List<WorkoutHistoryDay> days, {
  required String untitled,
}) {
  final dayKeys = <String, Set<DateTime>>{};
  final done = <String, int>{};
  final total = <String, int>{};
  for (final day in days) {
    if (!day.hasActivity) continue;
    final date = AppDates.dayOnly(day.date);
    if (day.planSummaries.isEmpty) {
      (dayKeys[untitled] ??= {}).add(date);
      continue;
    }
    for (final s in day.planSummaries) {
      final name = s.planName?.trim();
      final key = (name == null || name.isEmpty) ? untitled : name;
      (dayKeys[key] ??= {}).add(date);
      done[key] = (done[key] ?? 0) + s.doneCount;
      total[key] = (total[key] ?? 0) + s.totalCount;
    }
  }
  final rows = [
    for (final e in dayKeys.entries)
      PlanChartRow(
        name: e.key,
        days: e.value.length,
        done: done[e.key] ?? 0,
        total: total[e.key] ?? 0,
      ),
  ];
  rows.sort((a, b) {
    final byDays = b.days.compareTo(a.days);
    return byDays != 0 ? byDays : a.name.compareTo(b.name);
  });
  return rows;
}

/// Bottom sheet with the step and per-plan charts for one history scope.
/// Both draw in afresh each time the sheet opens.
void showTrainHistoryCharts(
  BuildContext context, {
  required List<StepDay> steps,
  required List<WorkoutHistoryDay> workouts,
  required String stepsTitle,
  required String workoutsTitle,
}) {
  final l10n = context.l10n;
  final stepData = stepChartData(steps, today: AppDates.todayLocal());
  final planRows = planChartRows(workouts, untitled: l10n.untitledWorkoutGroup);
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TrainChartsSheet(
      stepData: stepData,
      planRows: planRows,
      stepsTitle: stepsTitle,
      workoutsTitle: workoutsTitle,
    ),
  );
}

class _TrainChartsSheet extends StatelessWidget {
  const _TrainChartsSheet({
    required this.stepData,
    required this.planRows,
    required this.stepsTitle,
    required this.workoutsTitle,
  });

  final StepChartData stepData;
  final List<PlanChartRow> planRows;
  final String stepsTitle;
  final String workoutsTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final hasSteps = !stepData.isEmpty;
    final hasPlans = planRows.isNotEmpty;
    return SafeArea(
      top: false,
      child: ListView(
        key: const ValueKey('train-charts-sheet'),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          0,
          AppSpacing.formPage,
          AppSpacing.formPage,
        ),
        children: [
          if (!hasSteps && !hasPlans)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(l10n.noSetLogs, style: theme.textTheme.meta),
              ),
            ),
          if (hasSteps) ...[
            _ChartHeader(
              title: stepsTitle,
              caption: [
                '${l10n.dailyAverageCaption} '
                    '${l10n.nSteps(stepData.dailyAverage.round())}',
                if (stepData.weekly) l10n.stepsChartWeekly,
              ].join(' · '),
            ),
            _Draw(
              key: const ValueKey('train-steps-chart'),
              builder: (progress) => SizedBox(
                height: 170,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _StepBarsPainter(
                    data: stepData,
                    color: AppColors.water,
                    inkColor: theme.colorScheme.onSurface,
                    labelStyle: theme.textTheme.labelSmall,
                    locale: Localizations.localeOf(context),
                    progress: progress,
                  ),
                ),
              ),
            ),
          ],
          if (hasPlans) ...[
            if (hasSteps) const SizedBox(height: AppSpacing.section),
            _ChartHeader(
              title: workoutsTitle,
              caption: l10n.trainChartPlanLegend,
            ),
            _Draw(
              key: const ValueKey('train-plan-chart'),
              delay: hasSteps ? _kStagger : Duration.zero,
              builder: (progress) =>
                  _PlanBars(rows: planRows, progress: progress, muted: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.subsectionTitle),
          const SizedBox(height: 2),
          Text(caption, style: theme.textTheme.meta),
        ],
      ),
    );
  }
}

/// Runs 0 → 1 once when built (after [delay]); straight to 1 when the system
/// asks for reduced motion.
class _Draw extends StatelessWidget {
  const _Draw({super.key, required this.builder, this.delay = Duration.zero});

  final Widget Function(double progress) builder;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final total = delay + _kDrawDuration;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate ? total : Duration.zero,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, progress, _) => builder(progress),
    );
  }
}

/// Local 0..1 progress of item [i] of [n] when they start one after another
/// and each takes about [span] items' worth of the overall timeline.
double _staggered(double progress, int i, int n, {double span = 4}) {
  if (n <= 0) return progress;
  final t = progress * (n - 1 + span);
  return ((t - i) / span).clamp(0.0, 1.0);
}

class _StepBarsPainter extends CustomPainter {
  const _StepBarsPainter({
    required this.data,
    required this.color,
    required this.inkColor,
    required this.labelStyle,
    required this.locale,
    required this.progress,
  });

  final StepChartData data;
  final Color color;
  final Color inkColor;
  final TextStyle? labelStyle;
  final Locale locale;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 8.0;
    const bottom = 24.0;
    final plot = Rect.fromLTRB(0, top, size.width, size.height - bottom);
    final bars = data.bars;
    if (bars.isEmpty) return;

    final maxSteps = math.max(
      bars.map((b) => b.steps).reduce(math.max),
      data.dailyAverage,
    );
    final scale = maxSteps <= 0 ? 0.0 : plot.height / (maxSteps * 1.08);

    // Baseline.
    canvas.drawLine(
      plot.bottomLeft,
      plot.bottomRight,
      Paint()
        ..color = inkColor.withValues(alpha: .18)
        ..strokeWidth = 1,
    );

    final slot = plot.width / bars.length;
    final barWidth = math.max(2.0, math.min(18.0, slot * .62));
    final radius = Radius.circular(math.min(4, barWidth / 2));
    for (var i = 0; i < bars.length; i++) {
      final local = Curves.easeOutBack.transform(
        _staggered(progress, i, bars.length),
      );
      final h = bars[i].steps * scale * local;
      if (h <= 0) continue;
      final cx = plot.left + slot * (i + .5);
      final rect = Rect.fromLTRB(
        cx - barWidth / 2,
        plot.bottom - h,
        cx + barWidth / 2,
        plot.bottom,
      );
      final isLast = i == bars.length - 1;
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius),
        Paint()..color = color.withValues(alpha: isLast ? .95 : .72),
      );
    }

    // Average line follows the bars, drawn left to right.
    final avgT = ((progress - .55) / .45).clamp(0.0, 1.0);
    if (data.dailyAverage > 0 && avgT > 0) {
      final y = plot.bottom - data.dailyAverage * scale;
      final paint = Paint()
        ..color = inkColor.withValues(alpha: .5)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final endX = plot.left + plot.width * avgT;
      const dash = 6.0;
      for (var x = plot.left; x < endX; x += dash + 4) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + dash, endX), y),
          paint,
        );
      }
    }

    _paintDateLabels(canvas, plot, slot);
  }

  void _paintDateLabels(Canvas canvas, Rect plot, double slot) {
    final bars = data.bars;
    final indexes = <int>{0, bars.length - 1};
    if (bars.length > 4) indexes.add((bars.length - 1) ~/ 2);
    for (final i in indexes.toList()..sort()) {
      final text = TextPainter(
        text: TextSpan(
          text: AppDates.md(bars[i].date, locale),
          style: labelStyle?.copyWith(color: inkColor.withValues(alpha: .58)),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final cx = plot.left + slot * (i + .5);
      text.paint(
        canvas,
        Offset(
          (cx - text.width / 2).clamp(0.0, plot.right - text.width),
          plot.bottom + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_StepBarsPainter old) =>
      data != old.data ||
      color != old.color ||
      inkColor != old.inkColor ||
      labelStyle != old.labelStyle ||
      locale != old.locale ||
      progress != old.progress;
}

/// One row per plan: the light bar's length is the days trained, its dark
/// part the share of planned items done.
class _PlanBars extends StatelessWidget {
  const _PlanBars({
    required this.rows,
    required this.progress,
    required this.muted,
  });

  final List<PlanChartRow> rows;
  final double progress;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maxDays = rows.map((r) => r.days).reduce(math.max);
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            key: ValueKey('train-plan-row-${rows[i].name}'),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    rows[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 14,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PlanBarPainter(
                        share: rows[i].days / maxDays,
                        completion: rows[i].completion,
                        color: AppColors.protein,
                        progress: Curves.easeOutCubic.transform(
                          _staggered(progress, i, rows.length, span: 2.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Fixed width so every bar shares one scale and start.
                SizedBox(
                  width: _kPlanStatWidth,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      [
                        l10n.cutRoundTimes('${rows[i].days}'),
                        if (rows[i].completion case final c?)
                          l10n.trainChartCompletion((c * 100).round()),
                      ].join(' · '),
                      maxLines: 1,
                      style: theme.textTheme.meta?.copyWith(color: muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanBarPainter extends CustomPainter {
  const _PlanBarPainter({
    required this.share,
    required this.completion,
    required this.color,
    required this.progress,
  });

  /// Bar length as a share of the row, 0..1.
  final double share;

  /// Dark part as a share of the bar; null = the whole bar is light.
  final double? completion;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * share * progress;
    if (width <= 0) return;
    final radius = Radius.circular(size.height / 2);
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, size.height),
      radius,
    );
    canvas.drawRRect(bar, Paint()..color = color.withValues(alpha: .2));
    final c = completion;
    if (c == null || c <= 0) return;
    canvas.save();
    canvas.clipRRect(bar);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width * c, size.height),
      Paint()..color = color.withValues(alpha: .85),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlanBarPainter old) =>
      share != old.share ||
      completion != old.completion ||
      color != old.color ||
      progress != old.progress;
}
