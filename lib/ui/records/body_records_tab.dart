import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class _WeightLogDraft {
  const _WeightLogDraft({
    required this.weightKg,
    this.bodyFatPct,
  });

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
  Future<void> addWeight() async {
    final l10n = context.l10n;
    final profile = ref.read(profileProvider);
    final memory = ref.read(formMemoryRepositoryProvider);
    final extras =
        memory.hasWeightExtrasMemory ? memory.loadWeightExtras() : null;
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
      await ref.read(weightRepositoryProvider).add(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed('$e'))),
      );
    }
  }

  Future<void> _confirmDelete(WeightLog log) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteFailed('$e'))),
      );
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
    final scheme = Theme.of(context).colorScheme;

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.loadFailed('$e'))),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Text(
              l10n.emptyWeightLogs,
              style: Theme.of(context).textTheme.meta,
            ),
          );
        }

        final weightSeries = [
          for (final log in logs)
            _SeriesPoint(date: log.date, value: log.weightKg),
        ];
        final bodyFatSeries = [
          for (final log in logs)
            if (log.bodyFatPct != null)
              _SeriesPoint(date: log.date, value: log.bodyFatPct!),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.listPage,
            8,
            AppSpacing.listPage,
            88,
          ),
          children: [
            _SeriesChartCard(
              title: l10n.chartWeightTitle,
              points: weightSeries,
              color: scheme.primary,
              emptyHint: l10n.chartWeightEmpty,
            ),
            const SizedBox(height: AppSpacing.field),
            _SeriesChartCard(
              title: l10n.chartBfTitle,
              points: bodyFatSeries,
              color: AppColors.protein,
              emptyHint: l10n.chartBfEmpty,
            ),
            const SizedBox(height: AppSpacing.section),
            Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...logs.reversed.map(
              (log) => ListTile(
                key: ValueKey(log.id),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${log.weightKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(
                  _logSubtitle(log, l10n),
                  style: Theme.of(context).textTheme.meta,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => _confirmDelete(log),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SeriesChartCard extends StatelessWidget {
  const _SeriesChartCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
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
        ),
      ),
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
      _WeightLogDraft(
        weightKg: _weightKg,
        bodyFatPct: _bodyFatPct,
      ),
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
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
