import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
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
  int _period = 7;

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
      await ref.read(weightRepositoryProvider).delete(log.id);
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

  static const _periods = [7, 30, 0];

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
        final latest = ordered.lastOrNull;
        final previous = ordered.length > 1
            ? ordered[ordered.length - 2]
            : null;
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.listPage, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (latest != null) ...[
                    Text(
                      '${latest.weightKg.toStringAsFixed(1)} kg',
                      style: theme.textTheme.headlineLarge,
                    ),
                    if (previous != null) _deltaRow(context, latest, previous),
                    const SizedBox(height: 12),
                  ],
                  SportTabs<int>(
                    items: {
                      7: l10n.lastNDays(7),
                      30: l10n.lastNDays(30),
                      0: l10n.filterAll,
                    },
                    selected: _period,
                    onSelected: (v) => setState(() => _period = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SwipeTabView(
                index: _periods.indexOf(_period),
                onIndexChanged: (i) => setState(() => _period = _periods[i]),
                children: [
                  for (final p in _periods)
                    _periodPanel(context, ordered, logs, p),
                ],
              ),
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
    return Row(
      children: [
        Icon(
          flat
              ? Icons.remove
              : up
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          size: 14,
          color: flat
              ? scheme.onSurfaceVariant
              : up
              ? scheme.error
              : scheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '${up ? '+' : ''}${delta.toStringAsFixed(1)} kg · '
          '${context.l10n.sincePreviousRecord}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _periodPanel(
    BuildContext context,
    List<WeightLog> ordered,
    List<WeightLog> logs,
    int period,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cutoff = AppDates.todayLocal().subtract(Duration(days: period - 1));
    final visible = ordered
        .where((log) => period == 0 || !log.date.isBefore(cutoff))
        .toList();
    final weightSeries = [
      for (final log in visible)
        _SeriesPoint(date: log.date, value: log.weightKg),
    ];
    final bodyFatSeries = [
      for (final log in visible)
        if (log.bodyFatPct != null)
          _SeriesPoint(date: log.date, value: log.bodyFatPct!),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.listPage,
        12,
        AppSpacing.listPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        _SeriesChart(
          title: l10n.chartWeightTitle,
          points: weightSeries,
          color: scheme.primary,
          emptyHint: l10n.chartWeightEmpty,
        ),
        const SizedBox(height: AppSpacing.field),
        _SeriesChart(
          title: l10n.chartBfTitle,
          points: bodyFatSeries,
          color: AppColors.protein,
          emptyHint: l10n.chartBfEmpty,
        ),
        const SizedBox(height: AppSpacing.section),
        Row(
          children: [
            Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              tooltip: l10n.fabLogWeight,
              onPressed: addWeight,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (logs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.emptyWeightLogs,
                style: Theme.of(context).textTheme.meta,
              ),
            ),
          ),
        ...visible.reversed.map(
          (log) => SportListTile(
            key: ValueKey(log.id),
            title: Text(
              '${log.weightKg.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              _logSubtitle(log, l10n),
              style: Theme.of(context).textTheme.meta,
            ),
            trailing: AppDates.isLocalToday(log.date)
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
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

class _SeriesChart extends StatelessWidget {
  const _SeriesChart({
    required this.title,
    required this.points,
    required this.color,
    required this.emptyHint,
  });

  final String title;
  final List<_SeriesPoint> points;
  final Color color;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: points.isEmpty
              ? Center(
                  child: Text(
                    emptyHint,
                    style: Theme.of(context).textTheme.meta,
                  ),
                )
              : _buildChart(context),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];

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

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: points.length > 6
                  ? (points.length / 4).ceilToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DateFormat('M/d').format(points[i].date),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            color: color,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
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

  void _persistExtras() {
    widget.onExtrasChanged(_bodyFatPct);
  }

  void _submit() {
    Navigator.pop(
      context,
      _WeightLogDraft(weightKg: _weightKg, bodyFatPct: _bodyFatPct),
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
