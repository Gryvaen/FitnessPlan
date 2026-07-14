import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers/app_providers.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final intake = ref.watch(todayIntakeProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final day = ref.watch(selectedDayProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final targets = profile.targets;
    final remainCal = targets.calories - intake.calories;
    final remainP = targets.proteinG - intake.proteinG;
    final remainC = targets.carbG - intake.carbG;
    final remainF = targets.fatG - intake.fatG;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('M月d日').format(day)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log-meal'),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日热量',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _MacroBar(
                    label: '热量',
                    current: intake.calories,
                    target: targets.calories.toDouble(),
                    unit: 'kcal',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '剩余 ${remainCal.round()} kcal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: remainCal < 0
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                  const Divider(height: 28),
                  _MacroBar(
                    label: '蛋白',
                    current: intake.proteinG,
                    target: targets.proteinG,
                    unit: 'g',
                    color: const Color(0xFFD62828),
                  ),
                  Text('剩余 ${remainP.toStringAsFixed(0)} g',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  _MacroBar(
                    label: '碳水',
                    current: intake.carbG,
                    target: targets.carbG,
                    unit: 'g',
                    color: const Color(0xFF457B9D),
                  ),
                  Text('剩余 ${remainC.toStringAsFixed(0)} g',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  _MacroBar(
                    label: '脂肪',
                    current: intake.fatG,
                    target: targets.fatG,
                    unit: 'g',
                    color: const Color(0xFFE9C46A),
                  ),
                  Text('剩余 ${remainF.toStringAsFixed(0)} g',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('今日记录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败：$e'),
            data: (meals) {
              if (meals.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('还没有记录，点右下角记一笔')),
                );
              }
              return Column(
                children: meals.map((m) {
                  final type = MealType.values.byName(m.mealType);
                  return Dismissible(
                    key: ValueKey(m.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Theme.of(context).colorScheme.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref.read(mealRepositoryProvider).delete(m.id);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.foodName),
                      subtitle: Text(
                        '${type.label} · ${m.grams.toStringAsFixed(0)} g',
                      ),
                      trailing: Text(
                        '${m.calories.round()} kcal',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${current.round()} / ${target.round()} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            minHeight: 8,
            color: progress > 1
                ? Theme.of(context).colorScheme.error
                : color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
