import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../domain/plateau.dart';
import '../../providers/app_providers.dart';
import 'deficit_date_picker.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final intake = ref.watch(todayIntakeProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final day = ref.watch(selectedDayProvider);
    final weightLogs = ref.watch(weightLogsProvider).value ?? const [];

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final targets = profile.targets;
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final remainCal = targets.calories - intake.calories;
    final remainP = targets.proteinG - intake.proteinG;
    final remainC = targets.carbG - intake.carbG;
    final remainF = targets.fatG - intake.fatG;

    final onPlateau = profile.goal == FitnessGoal.cut &&
        Plateau.detect(
          weightLogs
              .map((e) => (date: e.date, weightKg: e.weightKg))
              .toList(),
        );
    final canCutMore =
        profile.calorieAdjustment < CalorieCalculator.maxCalorieAdjustment;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = DateTime(today.year - 1, today.month, today.day);
    final isSelectedToday = day == today;
    final canGoPrev = day.isAfter(earliest);
    final canGoNext = day.isBefore(today);
    final dayLabel = day.year == today.year
        ? DateFormat('M月d日').format(day)
        : DateFormat('yyyy年M月d日').format(day);
    final sectionPrefix = isSelectedToday ? '今日' : '当日';

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final picked = await showDeficitDatePicker(
              context: context,
              initialDate: day,
              firstDate: earliest,
              lastDate: today,
              plannedDeficit: plan.dailyDeficit,
              targetCalories: targets.calories.toDouble(),
              mealRepository: ref.read(mealRepositoryProvider),
              calorieStandardSince: profile.calorieStandardSince,
            );
            if (picked == null) return;
            ref.read(selectedDayProvider.notifier).setDay(picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dayLabel),
                const SizedBox(width: 4),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '前一天',
            onPressed: canGoPrev
                ? () => ref
                    .read(selectedDayProvider.notifier)
                    .shiftDay(-1, earliest: earliest)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: '今天',
            onPressed: isSelectedToday
                ? null
                : () => ref.read(selectedDayProvider.notifier).goToToday(),
            icon: const Icon(Icons.today),
          ),
          IconButton(
            tooltip: '后一天',
            onPressed: canGoNext
                ? () => ref
                    .read(selectedDayProvider.notifier)
                    .shiftDay(1, earliest: earliest)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      floatingActionButton: isSelectedToday
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/log-meal'),
              icon: const Icon(Icons.add),
              label: const Text('记一笔'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          if (profile.goal == FitnessGoal.cut && plan.missingCutInputs)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                title: Text(
                  '还未按减脂速度计算',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '当前仍是临时估算（TDEE×80%）。请到「我的」填写目标体重与每周降重后保存。',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('去填写'),
                ),
              ),
            ),
          if (onPlateau)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '可能进入平台期',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '近 ${Plateau.days} 天体重变化小于 ${Plateau.maxKgChange} kg。'
                      '建议温和调整，而不是大幅减热量。',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: !canCutMore
                              ? null
                              : () async {
                                  final updated = await ref
                                      .read(profileProvider.notifier)
                                      .applyPlateauCalorieCut();
                                  if (!context.mounted || updated == null) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '已减少 100 kcal：日摄入 '
                                        '${updated.targets.calories} kcal'
                                        '（累计调整 −${updated.calorieAdjustment}）',
                                      ),
                                    ),
                                  );
                                },
                          child: Text(
                            canCutMore
                                ? '减少 100 kcal'
                                : '已达调整上限',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '试试每天多走约 3000 步，先从活动量突破平台期。',
                                ),
                              ),
                            );
                          },
                          child: const Text('增加每天约 3000 步'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sectionPrefix热量',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (profile.goal == FitnessGoal.cut &&
                      !plan.missingCutInputs &&
                      plan.kgToLose != null &&
                      plan.weeklyLossKg != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '需减 ${plan.kgToLose!.toStringAsFixed(1)} kg · '
                      '实际约 ${plan.weeklyLossKg!.toStringAsFixed(2)} kg/周'
                      '${plan.goalWeeks != null ? ' · 约 ${plan.goalWeeks} 周' : ''}：'
                      '日缺口 ${plan.dailyDeficit.round()} kcal → 日摄入 '
                      '${plan.targets.calories} kcal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
          Text('$sectionPrefix记录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败：$e'),
            data: (meals) {
              if (meals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      isSelectedToday
                          ? '还没有记录，点右下角记一笔'
                          : '当日无记录',
                    ),
                  ),
                );
              }
              return Column(
                children: meals.map((m) {
                  final type = MealType.values.byName(m.mealType);
                  final tile = ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.foodName),
                    subtitle: Text(
                      '${type.label} · ${m.grams.toStringAsFixed(0)} g · '
                      '蛋白 ${m.proteinG.toStringAsFixed(0)}g · '
                      '碳水 ${m.carbG.toStringAsFixed(0)}g · '
                      '脂肪 ${m.fatG.toStringAsFixed(0)}g',
                    ),
                    trailing: Text(
                      '${m.calories.round()} kcal',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    onTap: () => context.push('/meal/${m.id}'),
                  );
                  if (!isSelectedToday) return tile;
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
                    child: tile,
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
