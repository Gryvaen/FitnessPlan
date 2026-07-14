import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';

class WeightPage extends ConsumerStatefulWidget {
  const WeightPage({super.key});

  @override
  ConsumerState<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends ConsumerState<WeightPage> {
  Future<void> _addWeight() async {
    final profile = ref.read(profileProvider);
    final ctrl = TextEditingController(
      text: profile?.weightKg.toStringAsFixed(1) ?? '70',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录体重'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '体重 (kg)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final w = double.tryParse(ctrl.text);
    if (w == null || w < 30 || w > 300) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效体重')),
      );
      return;
    }
    await ref.read(weightRepositoryProvider).add(
          date: DateTime.now(),
          weightKg: w,
        );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(weightLogsProvider);

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
            return const Center(child: Text('还没有体重记录，点右下角添加'));
          }
          final spots = <FlSpot>[];
          for (var i = 0; i < logs.length; i++) {
            spots.add(FlSpot(i.toDouble(), logs[i].weightKg));
          }
          final minY =
              logs.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 2;
          final maxY =
              logs.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 2;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              SizedBox(
                height: 220,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
                    child: LineChart(
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
                              interval: logs.length > 6
                                  ? (logs.length / 4).ceilToDouble()
                                  : 1,
                              getTitlesWidget: (value, meta) {
                                final i = value.round();
                                if (i < 0 || i >= logs.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  DateFormat('M/d').format(logs[i].date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 3,
                            color: Theme.of(context).colorScheme.primary,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('历史记录', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...logs.reversed.map(
                (log) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${log.weightKg.toStringAsFixed(1)} kg'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(log.date)),
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
