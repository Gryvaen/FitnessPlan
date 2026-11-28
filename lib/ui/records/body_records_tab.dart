import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../ink/ink_icon.dart';
import '../theme/sport_chrome.dart';
import '../widgets/form_options.dart';

class _WeightLogDraft {
  const _WeightLogDraft({required this.weightKg, this.bodyFatPct});

  final double weightKg;
  final double? bodyFatPct;
}

class _SeriesPoint {
  const _SeriesPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

/// Body metrics tab: weight / body-fat charts and history.
class BodyRecordsTab extends ConsumerStatefulWidget {
  const BodyRecordsTab({super.key});

  @override
  ConsumerState<BodyRecordsTab> createState() => BodyRecordsTabState();
}

class BodyRecordsTabState extends ConsumerState<BodyRecordsTab> {
  /// Days shown: 30, or 0 = all. Opens on the last 30 days.
  int _period = 30;

  /// 「30 天」 or 「全部」.
  static String _periodLabel(AppLocalizations l10n, int period) =>
      period == 0 ? l10n.filterAll : l10n.lastNDays(period);

  /// Logs within [period] days (0 = all), oldest first.
  static List<WeightLog> _logsInPeriod(
    List<WeightLog> orderedOldestFirst,
    int period,
  ) {
    if (period == 0) return orderedOldestFirst;
    final cutoff = AppDates.addDays(AppDates.todayLocal(), 1 - period);
    return [
      for (final log in orderedOldestFirst)
        if (!log.date.isBefore(cutoff)) log,
    ];
  }

  /// Weight / body-fat charts for [period], in a bottom sheet. The lines are
  /// drawn afresh each time the sheet opens.
  void _showChartsSheet(
    List<WeightLog> orderedOldestFirst,
    List<WeightLog> logs,
    int period,
  ) {
    final visible = _logsInPeriod(orderedOldestFirst, period);
    final hasBodyFatHistory = logs.any((log) => log.bodyFatPct != null);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _BodyChartsSheet(
        visible: visible,
        hasBodyFatHistory: hasBodyFatHistory,
        periodLabel: _periodLabel(context.l10n, period),
      ),
    );
  }

  /// 「30 天」 and 「全部」 once any weight is logged; just all before that.
  static List<int> _availablePeriods(List<WeightLog> orderedOldestFirst) {
    if (orderedOldestFirst.isEmpty) return const [0];
    return const [30, 0];
  }

  Future<void> addWeight() async {
    final l10n = context.l10n;
    final profile = ref.read(profileProvider);
    final memory = ref.read(formMemoryRepositoryProvider);
    final extras = memory.hasWeightExtrasMemory
        ? memory.loadWeightExtras()
        : null;
    final draft = await showDialog<_WeightLogDraft>(
      context: context,
      builder: (ctx) => _WeightLogDialog(
        initialWeightKg: profile?.weightKg ?? 70,
        initialBodyFatPct: extras?.bodyFatPct,
        onExtrasChanged: (bodyFatPct) {
          memory.saveWeightExtras(
            bodyFatPct: bodyFatPct,
            exerciseMinutes: extras?.exerciseMinutes,
          );
        },
      ),
    );
    if (draft == null || !mounted) return;

    try {
      await ref
          .read(weightRepositoryProvider)
          .add(
            date: DateTime.now(),
            weightKg: draft.weightKg,
            bodyFatPct: draft.bodyFatPct,
          );
      // A weigh-in on or shortly after a 放纵日 is mostly water and glycogen:
      // keep the record, but don't let it move the profile and its targets.
      final skewed = await weighInSkewedByCheatDay(
        ref.read(dayMarkerRepositoryProvider),
        DateTime.now(),
      );
      if (skewed) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.weightSkippedAfterCheat)));
        return;
      }
      final updated = await ref
          .read(profileProvider.notifier)
          .applyLatestWeight(draft.weightKg);
      if (!mounted) return;
      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.weightLoggedSnack('${updated.targets.calories}'),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    }
  }

  Future<void> _confirmDelete(WeightLog log) async {
    if (!AppDates.isLocalToday(log.date)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.pastDayReadOnly)));
      return;
    }
    final l10n = context.l10n;
    final dateStr = DateFormat('yyyy-MM-dd').format(log.date);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.confirmDeleteWeight(dateStr)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final repo = ref.read(weightRepositoryProvider);
      await repo.delete(log.id);
      // The profile (and every target derived from it) followed the deleted
      // log; fall back to the latest remaining one not skewed by a 放纵日.
      final latest = await latestProfileWeighIn(
        repo,
        ref.read(dayMarkerRepositoryProvider),
      );
      if (latest != null &&
          latest.weightKg != ref.read(profileProvider)?.weightKg) {
        await ref
            .read(profileProvider.notifier)
            .applyLatestWeight(latest.weightKg);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleteFailed('$e'))));
    }
  }

  String _logSubtitle(WeightLog log, AppLocalizations l10n) {
    final parts = <String>[DateFormat('yyyy-MM-dd').format(log.date)];
    if (log.bodyFatPct != null) {
      parts.add(l10n.bodyFatPctLine(log.bodyFatPct!.toStringAsFixed(1)));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logsAsync = ref.watch(weightLogsProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          SportLoadError(onRetry: () => ref.invalidate(weightLogsProvider)),
      data: (logs) {
        final ordered = [...logs]..sort((a, b) => a.date.compareTo(b.date));
        final periods = _availablePeriods(ordered);
        final period = periods.contains(_period) ? _period : periods.first;
        final latest = ordered.lastOrNull;
        final previous = ordered.length > 1
            ? ordered[ordered.length - 2]
            : null;
        final theme = Theme.of(context);
        final showPeriodTabs = periods.length > 1;
        final nextPeriod =
            periods[(periods.indexOf(period) + 1) % periods.length];
        final isEmpty = logs.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.listPage,
                  8,
                  20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (latest != null) ...[
                      Text(
                        '${latest.weightKg.toStringAsFixed(2)} kg',
                        style: theme.textTheme.headlineLarge,
                      ),
                      if (previous != null)
                        _deltaRow(context, latest, previous),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                children: [
                  if (showPeriodTabs)
                    HistoryScopeToggle(
                      key: const ValueKey('body-period-toggle'),
                      nextLabel: _periodLabel(l10n, nextPeriod),
                      onPressed: () => setState(() => _period = nextPeriod),
                    ),
                  if (!isEmpty)
                    PlainIconAction(
                      key: const ValueKey('body-charts-open'),
                      iconWidget: const InkIcon(InkGlyph.recordCharts),
                      label: l10n.bodyChartsAction,
                      onPressed: () => _showChartsSheet(ordered, logs, period),
                    ),
                  const Spacer(),
                  PlainIconAction(
                    iconWidget: const InkIcon(InkGlyph.add),
                    label: l10n.fabLogWeight,
                    onPressed: addWeight,
                  ),
                ],
              ),
            ),
            Expanded(
              child: showPeriodTabs
                  ? SwipeTabView(
                      navigation: SwipeTabNavigation.tapOnly,
                      keepPagesAlive: true,
                      index: periods
                          .indexOf(period)
                          .clamp(0, periods.length - 1),
                      onIndexChanged: (i) =>
                          setState(() => _period = periods[i]),
                      children: [
                        for (final p in periods)
                          _periodPanel(
                            context,
                            ordered,
                            logs,
                            p,
                            periodLabel: _periodLabel(l10n, p),
                          ),
                      ],
                    )
                  : _periodPanel(context, ordered, logs, 0),
            ),
          ],
        );
      },
    );
  }

  Widget _deltaRow(BuildContext context, WeightLog latest, WeightLog previous) {
    final delta = latest.weightKg - previous.weightKg;
    final up = delta > 0;
    final flat = delta.abs() < 0.05;
    final scheme = Theme.of(context).colorScheme;
    // Good or bad depends on the goal: losing while cutting, gaining while
    // bulking; maintenance stays neutral either way.
    final goal = ref.watch(profileProvider)?.goal ?? FitnessGoal.cut;
    final good = switch (goal) {
      FitnessGoal.cut => !up,
      FitnessGoal.bulk => up,
      FitnessGoal.maintain => null,
    };
    final color = flat || good == null
        ? scheme.onSurfaceVariant
        : good
        ? AppColors.success
        : AppColors.warning;
    return Row(
      children: [
        InkIcon(
          flat
              ? InkGlyph.remove
              : up
              ? InkGlyph.collapse
              : InkGlyph.expand,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${up ? '+' : ''}${delta.toStringAsFixed(2)} kg · '
            '${context.l10n.sincePreviousRecord}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.meta?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _periodPanel(
    BuildContext context,
    List<WeightLog> ordered,
    List<WeightLog> logs,
    int period, {
    String? periodLabel,
  }) {
    final l10n = context.l10n;
    final visible = _logsInPeriod(ordered, period);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.listPage,
        4,
        AppSpacing.listPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        Text(
          periodLabel == null ? l10n.history : '${l10n.history} · $periodLabel',
          style: Theme.of(context).textTheme.sectionTitle,
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          SportEmptyState(
            title: logs.isEmpty ? l10n.emptyWeightLogs : l10n.noHistory,
            iconWidget: const StampedInkEmptyIcon(
              glyph: InkGlyph.profile,
              seal: '身',
            ),
          ),
        ...visible.reversed.map(
          (log) => SportListTile(
            key: ValueKey(log.id),
            title: Text(
              '${log.weightKg.toStringAsFixed(2)} kg',
              style: Theme.of(context).textTheme.rowTitle,
            ),
            subtitle: Text(
              _logSubtitle(log, l10n),
              style: Theme.of(context).textTheme.meta,
            ),
            trailing: AppDates.isLocalToday(log.date)
                ? IconButton(
                    icon: const InkIcon(InkGlyph.delete),
                    tooltip: l10n.delete,
                    onPressed: () => _confirmDelete(log),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet with the weight / body-fat charts for one period.
class _BodyChartsSheet extends StatelessWidget {
  const _BodyChartsSheet({
    required this.visible,
    required this.hasBodyFatHistory,
    required this.periodLabel,
  });

  /// Logs in the period, oldest first.
  final List<WeightLog> visible;
  final bool hasBodyFatHistory;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weightSeries = [
      for (final log in visible)
        _SeriesPoint(date: log.date, value: log.weightKg),
    ];
    final bodyFatSeries = [
      for (final log in visible)
        if (log.bodyFatPct != null)
          _SeriesPoint(date: log.date, value: log.bodyFatPct!),
    ];
    final empty = weightSeries.isEmpty && bodyFatSeries.isEmpty;
    return SafeArea(
      top: false,
      child: ListView(
        key: const ValueKey('body-charts-sheet'),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          0,
          AppSpacing.formPage,
          AppSpacing.formPage,
        ),
        children: [
          if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  l10n.chartWeightEmpty,
                  style: Theme.of(context).textTheme.meta,
                ),
              ),
            ),
          if (weightSeries.isNotEmpty)
            _SeriesChart(
              title: l10n.chartWeightTitle,
              periodLabel: periodLabel,
              points: weightSeries,
              color: Theme.of(context).colorScheme.primary,
              emptyHint: l10n.chartWeightEmpty,
            ),
          if (hasBodyFatHistory && !empty) ...[
            if (weightSeries.isNotEmpty)
              const SizedBox(height: AppSpacing.section),
            _SeriesChart(
              title: l10n.chartBfTitle,
              periodLabel: periodLabel,
              points: bodyFatSeries,
              color: AppColors.protein,
              emptyHint: l10n.chartBfEmpty,
              // The second stroke starts a beat after the first.
              delay: weightSeries.isNotEmpty ? _kChartStagger : Duration.zero,
            ),
          ],
        ],
      ),
    );
  }
}

/// How long one chart line takes to draw.
const _kChartDrawDuration = Duration(milliseconds: 900);

/// Head start of the weight line over the body-fat line.
const _kChartStagger = Duration(milliseconds: 150);

class _SeriesChart extends StatelessWidget {
  const _SeriesChart({
    required this.title,
    required this.periodLabel,
    required this.points,
    required this.color,
    required this.emptyHint,
    this.delay = Duration.zero,
  });

  /// Chart name without the period; also keys the chart.
  final String title;
  final String periodLabel;
  final List<_SeriesPoint> points;
  final Color color;
  final String emptyHint;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '$title · $periodLabel',
            style: theme.textTheme.subsectionTitle,
          ),
        ),
        const SizedBox(height: 2),
        _chart(context),
      ],
    );
  }

  Widget _chart(BuildContext context) {
    final theme = Theme.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final total = delay + _kChartDrawDuration;
    // Idle for [delay], then draw over [_kChartDrawDuration].
    final start = delay.inMicroseconds / total.inMicroseconds;
    return SizedBox(
      key: ValueKey('ink-series-chart-$title'),
      height: 180,
      child: points.isEmpty
          ? Center(child: Text(emptyHint, style: theme.textTheme.meta))
          : Semantics(
              label: '$title，${points.length}',
              image: true,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('ink-series-draw-$title'),
                tween: Tween(begin: animate ? 0 : 1, end: 1),
                duration: animate ? total : Duration.zero,
                curve: Interval(start, 1, curve: Curves.easeInOutCubic),
                builder: (context, progress, _) => CustomPaint(
                  painter: _InkSeriesPainter(
                    points: points,
                    color: color,
                    inkColor: theme.colorScheme.onSurface,
                    paperColor: AppThemeVisuals.of(context).card,
                    labelStyle: theme.textTheme.labelSmall,
                    locale: Localizations.localeOf(context),
                    progress: progress,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
    );
  }
}

class _InkSeriesPainter extends CustomPainter {
  const _InkSeriesPainter({
    required this.points,
    required this.color,
    required this.inkColor,
    required this.paperColor,
    required this.labelStyle,
    required this.locale,
    this.progress = 1,
  });

  final List<_SeriesPoint> points;
  final Color color;
  final Color inkColor;
  final Color paperColor;
  final TextStyle? labelStyle;
  final Locale locale;

  /// How much of the line is drawn, 0..1, left to right along the curve.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 10.0;
    const right = 10.0;
    const top = 11.0;
    const bottom = 28.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    _paintPaperWash(canvas, plot);

    var minY = points.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    var maxY = points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      final pad = (maxY - minY) * 0.1;
      minY -= pad;
      maxY += pad;
    }

    final offsets = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          points.length == 1
              ? plot.center.dx
              : plot.left + plot.width * i / (points.length - 1),
          plot.bottom -
              plot.height * ((points[i].value - minY) / (maxY - minY)),
        ),
    ];
    final line = _smoothPath(offsets);
    final t = progress.clamp(0.0, 1.0);
    // Pen tip: the part of the line drawn so far and where it ends.
    final drawn = Path();
    var tipX = offsets.first.dx;
    for (final metric in line.computeMetrics()) {
      final length = metric.length * t;
      drawn.addPath(metric.extractPath(0, length), Offset.zero);
      final tangent = metric.getTangentForOffset(length);
      if (tangent != null) tipX = tangent.position.dx;
    }
    if (t >= 1) tipX = offsets.last.dx;

    final wash = Path.from(line)
      ..lineTo(offsets.last.dx, plot.bottom)
      ..lineTo(offsets.first.dx, plot.bottom)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, tipX, size.height));
    canvas.drawPath(
      wash,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .17), color.withValues(alpha: .01)],
        ).createShader(plot),
    );
    canvas.restore();

    if (t > 0) {
      canvas.drawPath(
        drawn,
        Paint()
          ..color = color.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        drawn,
        Paint()
          ..color = color.withValues(alpha: .92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < offsets.length; i++) {
      final p = offsets[i];
      final isLast = i == offsets.length - 1;
      // A dot appears once the pen has reached it.
      if (isLast ? t < 1 : (t <= 0 || p.dx > tipX + .5)) continue;
      canvas.drawCircle(p, isLast ? 5.2 : 3.8, Paint()..color = paperColor);
      canvas.drawCircle(
        p,
        isLast ? 4.1 : 2.8,
        Paint()..color = color.withValues(alpha: isLast ? 1 : .82),
      );
      if (isLast) {
        canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = color.withValues(alpha: .28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    _paintDateLabels(canvas, plot);
  }

  void _paintPaperWash(Canvas canvas, Rect plot) {
    final washPath = Path()
      ..moveTo(plot.left + 2, plot.top)
      ..quadraticBezierTo(
        plot.center.dx,
        plot.top + 2,
        plot.right - 2,
        plot.top,
      )
      ..lineTo(plot.right, plot.bottom - 2)
      ..quadraticBezierTo(
        plot.center.dx,
        plot.bottom,
        plot.left,
        plot.bottom - 1,
      )
      ..close();
    canvas.drawPath(
      washPath,
      Paint()..color = inkColor.withValues(alpha: .025),
    );

    final guidePaint = Paint()
      ..color = inkColor.withValues(alpha: .09)
      ..strokeWidth = .7
      ..strokeCap = StrokeCap.round;
    for (var row = 1; row <= 3; row++) {
      final y = plot.top + plot.height * row / 4;
      const dash = 13.0;
      for (
        var x = plot.left + (row.isOdd ? 5 : 0);
        x < plot.right;
        x += dash + 8
      ) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dash).clamp(plot.left, plot.right), y),
          guidePaint,
        );
      }
    }
  }

  Path _smoothPath(List<Offset> values) {
    final path = Path()..moveTo(values.first.dx, values.first.dy);
    if (values.length == 1) {
      path.lineTo(values.first.dx + .01, values.first.dy);
      return path;
    }
    for (var i = 0; i < values.length - 1; i++) {
      final current = values[i];
      final next = values[i + 1];
      final middleX = (current.dx + next.dx) / 2;
      path.cubicTo(middleX, current.dy, middleX, next.dy, next.dx, next.dy);
    }
    return path;
  }

  void _paintDateLabels(Canvas canvas, Rect plot) {
    final labelIndexes = <int>{0, points.length - 1};
    if (points.length > 2) labelIndexes.add((points.length - 1) ~/ 2);
    if (points.length > 6) {
      labelIndexes
        ..add((points.length - 1) ~/ 4)
        ..add(((points.length - 1) * 3) ~/ 4);
    }
    for (final i in labelIndexes.toList()..sort()) {
      final text = TextPainter(
        text: TextSpan(
          text: DateFormat(
            'M/d',
            locale.toLanguageTag(),
          ).format(points[i].date),
          style: labelStyle?.copyWith(color: inkColor.withValues(alpha: .58)),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + plot.width * i / (points.length - 1);
      text.paint(
        canvas,
        Offset(
          (x - text.width / 2).clamp(0.0, plot.right - text.width),
          plot.bottom + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_InkSeriesPainter oldDelegate) =>
      points != oldDelegate.points ||
      color != oldDelegate.color ||
      inkColor != oldDelegate.inkColor ||
      paperColor != oldDelegate.paperColor ||
      labelStyle != oldDelegate.labelStyle ||
      locale != oldDelegate.locale ||
      progress != oldDelegate.progress;
}

class _WeightLogDialog extends StatefulWidget {
  const _WeightLogDialog({
    required this.initialWeightKg,
    this.initialBodyFatPct,
    required this.onExtrasChanged,
  });

  final double initialWeightKg;
  final double? initialBodyFatPct;
  final void Function(double? bodyFatPct) onExtrasChanged;

  @override
  State<_WeightLogDialog> createState() => _WeightLogDialogState();
}

class _WeightLogDialogState extends State<_WeightLogDialog> {
  late double _weightKg;
  double? _bodyFatPct;
  final _manualCtrl = TextEditingController();
  bool _useManual = false;
  String? _manualError;

  @override
  void initState() {
    super.initState();
    _weightKg = FormOptions.snapDouble(
      FormOptions.weightsKg(),
      widget.initialWeightKg,
    );
    final bodyFat = widget.initialBodyFatPct;
    _bodyFatPct = bodyFat == null
        ? null
        : FormOptions.snapDouble(FormOptions.bodyFatPct(), bodyFat);
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  void _persistExtras() {
    widget.onExtrasChanged(_bodyFatPct);
  }

  void _submit() {
    var weightKg = _weightKg;
    if (_useManual) {
      final parsed = double.tryParse(_manualCtrl.text.trim());
      if (parsed == null || parsed <= 0) {
        setState(() => _manualError = context.l10n.invalidWeightValue);
        return;
      }
      weightKg = (parsed * 100).round() / 100;
    }
    Navigator.pop(
      context,
      _WeightLogDraft(weightKg: weightKg, bodyFatPct: _bodyFatPct),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.logWeightTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDropdown<double>(
              label: l10n.weight,
              value: _weightKg,
              items: FormOptions.weightsKg(),
              suffixText: 'kg',
              itemLabel: formatKg,
              onChanged: (v) => setState(() => _weightKg = v),
            ),
            const SizedBox(height: 12),
            AppOptionalDropdown<double>(
              label: l10n.bodyFatPct,
              value: _bodyFatPct,
              items: FormOptions.bodyFatPct(),
              suffixText: '%',
              itemLabel: (v) => v.toStringAsFixed(1),
              onChanged: (v) {
                setState(() => _bodyFatPct = v);
                _persistExtras();
              },
            ),
            InkWell(
              onTap: () => setState(() {
                _useManual = !_useManual;
                if (!_useManual) {
                  _manualCtrl.clear();
                  _manualError = null;
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Divider(height: 1)),
                    InkIcon(
                      _useManual ? InkGlyph.collapse : InkGlyph.expand,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_useManual)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _manualCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)) {
                        return newValue;
                      }
                      return oldValue;
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.manualWeightToggle,
                    suffixText: 'kg',
                    errorText: _manualError,
                  ),
                  onChanged: (_) {
                    if (_manualError != null) {
                      setState(() => _manualError = null);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
