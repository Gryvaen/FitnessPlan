import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class _WeightLogDraft {
  const _WeightLogDraft({
    required this.weightKg,
    this.bodyFatPct,
    this.exerciseMinutes,
  });

  final double weightKg;
  final double? bodyFatPct;
  final int? exerciseMinutes;
}

class _SeriesPoint {
  const _SeriesPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class WeightPage extends ConsumerStatefulWidget {
  const WeightPage({super.key});

  @override
  ConsumerState<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends ConsumerState<WeightPage> {
  Future<void> _addWeight() async {
    final profile = ref.read(profileProvider);
    final draft = await showDialog<_WeightLogDraft>(
      context: context,
      builder: (ctx) => _WeightLogDialog(
        initialWeightKg: profile?.weightKg ?? 70,
      ),
    );
    if (draft == null || !mounted) return;

    await ref.read(weightRepositoryProvider).add(
          date: DateTime.now(),
          weightKg: draft.weightKg,
          bodyFatPct: draft.bodyFatPct,
          exerciseMinutes: draft.exerciseMinutes,
        );
    final updated = await ref
        .read(profileProvider.notifier)
        .applyLatestWeight(draft.weightKg);
    if (!mounted) return;
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已记体重，日摄入 ${updated.targets.calories} kcal',
          ),
        ),
      );
    }
  }

  String _logSubtitle(WeightLog log) {
    final parts = <String>[DateFormat('yyyy-MM-dd').format(log.date)];
    if (log.bodyFatPct != null) {
      parts.add('体脂 ${log.bodyFatPct!.toStringAsFixed(1)}%');
    }
    if (log.exerciseMinutes != null) {
      parts.add('运动 ${log.exerciseMinutes} 分钟');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(weightLogsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('体重')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWeight,
        child: const Icon(Icons.add),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                '还没有记录，点右下角添加',
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
          final exerciseSeries = [
            for (final log in logs)
              if (log.exerciseMinutes != null)
                _SeriesPoint(
                  date: log.date,
                  value: log.exerciseMinutes!.toDouble(),
                ),
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
                title: '体重 (kg)',
                points: weightSeries,
                color: scheme.primary,
                emptyHint: '暂无体重数据',
              ),
              const SizedBox(height: AppSpacing.field),
              _SeriesChartCard(
                title: '体脂率 (%)',
                points: bodyFatSeries,
                color: AppColors.protein,
                emptyHint: '暂无体脂记录',
              ),
              const SizedBox(height: AppSpacing.field),
              _SeriesChartCard(
                title: '运动 (分钟)',
                points: exerciseSeries,
                color: AppColors.carb,
                emptyHint: '暂无运动记录',
              ),
              const SizedBox(height: AppSpacing.section),
              Text('历史记录', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...logs.reversed.map(
                (log) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${log.weightKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    _logSubtitle(log),
                    style: Theme.of(context).textTheme.meta,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(weightRepositoryProvider).delete(log.id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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

/// Owns dialog state; fields use dropdowns (no TextEditingController).
class _WeightLogDialog extends StatefulWidget {
  const _WeightLogDialog({required this.initialWeightKg});

  final double initialWeightKg;

  @override
  State<_WeightLogDialog> createState() => _WeightLogDialogState();
}

class _WeightLogDialogState extends State<_WeightLogDialog> {
  late double _weightKg;
  double? _bodyFatPct;
  int? _exerciseMinutes;

  @override
  void initState() {
    super.initState();
    _weightKg = FormOptions.snapDouble(
      FormOptions.weightsKg(),
      widget.initialWeightKg,
    );
  }

  void _submit() {
    Navigator.pop(
      context,
      _WeightLogDraft(
        weightKg: _weightKg,
        bodyFatPct: _bodyFatPct,
        exerciseMinutes: _exerciseMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('记录体重'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDropdown<double>(
              label: '体重',
              value: _weightKg,
              items: FormOptions.weightsKg(),
              suffixText: 'kg',
              itemLabel: formatKg,
              onChanged: (v) => setState(() => _weightKg = v),
            ),
            const SizedBox(height: 12),
            AppOptionalDropdown<double>(
              label: '体脂率',
              value: _bodyFatPct,
              items: FormOptions.bodyFatPct(),
              suffixText: '%',
              itemLabel: (v) => v.toStringAsFixed(1),
              onChanged: (v) => setState(() => _bodyFatPct = v),
            ),
            const SizedBox(height: 12),
            AppOptionalDropdown<int>(
              label: '今日运动时间',
              value: _exerciseMinutes,
              items: FormOptions.exerciseMinutes,
              suffixText: '分钟',
              helperText: '当天累计运动时长',
              onChanged: (v) => setState(() => _exerciseMinutes = v),
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
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
