import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../domain/plateau.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'deficit_date_picker.dart';
import 'today_summary_widgets.dart';

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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final targets = profile.targets;
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final remainCal = targets.calories - intake.calories;
    final remainP = targets.proteinG - intake.proteinG;
    final remainC = targets.carbG - intake.carbG;
    final remainF = targets.fatG - intake.fatG;
    final waterMl = ref.watch(waterMlProvider).value ?? 0;
    final waterGoal = ref.watch(waterGoalProvider);

    String remainMacro(double remain) => remain < 0
        ? '超 ${(-remain).toStringAsFixed(0)} g'
        : '剩 ${remain.toStringAsFixed(0)} g';

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
                  color: scheme.onSurfaceVariant,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log-meal'),
        icon: const Icon(Icons.add),
        label: Text(isSelectedToday ? '记一笔' : '补记'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.listPage,
          8,
          AppSpacing.listPage,
          88,
        ),
        children: [
          if (profile.goal == FitnessGoal.cut && plan.missingCutInputs)
            Card(
              color: scheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.onErrorContainer,
                ),
                title: Text(
                  '减脂计划未完成',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                subtitle: Text(
                  '请到「我的 → 我的档案」填写目标体重与每周降重。',
                  style: theme.textTheme.meta?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () => context.go('/profile/edit'),
                  child: const Text('去填写'),
                ),
              ),
            ),
          if (onPlateau) ...[
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '可能进入平台期',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '近 ${Plateau.days} 天体重几乎没变。可小幅减热量，或先加活动量。',
                      style: theme.textTheme.meta?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.field),
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
                                        '已减 100 kcal，日摄入 '
                                        '${updated.targets.calories} kcal',
                                      ),
                                    ),
                                  );
                                },
                          child: Text(
                            canCutMore ? '减少 100 kcal' : '已达调整上限',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('可先每天多走约 3000 步。'),
                              ),
                            );
                          },
                          child: const Text('多走约 3000 步'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sectionPrefix热量',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (profile.goal == FitnessGoal.cut &&
                      !plan.missingCutInputs &&
                      plan.kgToLose != null &&
                      plan.weeklyLossKg != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '缺口 ${plan.dailyDeficit.round()} kcal · '
                      '摄入 ${plan.targets.calories} kcal'
                      '${plan.goalWeeks != null ? ' · 约 ${plan.goalWeeks} 周' : ''}',
                      style: theme.textTheme.meta,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.field),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CalorieRing(
                        eaten: intake.calories,
                        target: targets.calories.toDouble(),
                        over: remainCal < 0,
                        remainAbs: remainCal.abs(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            MacroMini(
                              label: '蛋白',
                              current: intake.proteinG,
                              target: targets.proteinG,
                              color: AppColors.protein,
                              remainLabel: remainMacro(remainP),
                            ),
                            MacroMini(
                              label: '碳水',
                              current: intake.carbG,
                              target: targets.carbG,
                              color: AppColors.carb,
                              remainLabel: remainMacro(remainC),
                            ),
                            MacroMini(
                              label: '脂肪',
                              current: intake.fatG,
                              target: targets.fatG,
                              color: AppColors.fat,
                              remainLabel: remainMacro(remainF),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (intake.alcoholG > 0) ...[
                    const SizedBox(height: AppSpacing.field),
                    Text(
                      '酒精额外能量 ≈ ${intake.alcoholKcal.round()} kcal'
                      '（${intake.alcoholG.toStringAsFixed(1)} g）',
                      style: theme.textTheme.meta,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('饮水', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '$waterMl / $waterGoal ml',
                              style: theme.textTheme.meta,
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: waterMl <= 0
                              ? null
                              : () => ref
                                  .read(waterRepositoryProvider)
                                  .addMl(day, -250),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 6, 0, 6),
                            child: WaterBottleCap(enabled: waterMl > 0),
                          ),
                        ),
                      ),
                      // Overlap into the cup's left canvas inset so the
                      // cap sits flush against the drawn cup rim.
                      Transform.translate(
                        offset: const Offset(-10, 0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => ref
                                .read(waterRepositoryProvider)
                                .addMl(day, 250),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
                              child: WaterCup(
                                progress:
                                    waterGoal <= 0 ? 0 : waterMl / waterGoal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: waterGoal <= 0
                          ? 0
                          : (waterMl / waterGoal).clamp(0.0, 1.0),
                      minHeight: 10,
                      color: scheme.primary,
                      backgroundColor:
                          scheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '点水杯 +250 · 点瓶盖 −250',
                    style: theme.textTheme.meta,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Text('$sectionPrefix记录', style: theme.textTheme.titleMedium),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: '更多',
                onSelected: (value) async {
                  if (value == 'copy') {
                    final from = day.subtract(const Duration(days: 1));
                    final existing =
                        await ref.read(mealRepositoryProvider).forDay(day);
                    if (existing.isNotEmpty && context.mounted) {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('复制昨日'),
                          content: const Text('当日已有记录，将追加昨日餐食，确定？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('追加'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                    }
                    final result = await ref
                        .read(mealRepositoryProvider)
                        .copyDay(from: from, to: day);
                    if (!context.mounted) return;
                    final skip = result.skippedMissingFood > 0
                        ? '，跳过 ${result.skippedMissingFood} 项'
                        : '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.copied == 0 && result.skippedMissingFood == 0
                              ? '昨日无记录'
                              : '已复制 ${result.copied} 项$skip',
                        ),
                      ),
                    );
                  } else if (value == 'preset') {
                    final meals =
                        await ref.read(mealRepositoryProvider).forDay(day);
                    if (!context.mounted) return;
                    if (meals.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('当日无记录可保存')),
                      );
                      return;
                    }
                    final nameCtrl = TextEditingController(
                      text: isSelectedToday ? '常用套餐' : dayLabel,
                    );
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('存为套餐'),
                        content: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: '名称'),
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
                    if (ok != true) {
                      nameCtrl.dispose();
                      return;
                    }
                    try {
                      await ref
                          .read(mealPresetRepositoryProvider)
                          .createFromEntries(
                            name: nameCtrl.text,
                            entries: meals,
                          );
                      ref.invalidate(mealPresetsProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('套餐已保存')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    } finally {
                      nameCtrl.dispose();
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'copy', child: Text('复制昨日')),
                  PopupMenuItem(value: 'preset', child: Text('存为套餐')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败：$e', style: theme.textTheme.meta),
            data: (meals) {
              if (meals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      isSelectedToday ? '还没有记录，点右下角记一笔' : '当日无记录',
                      style: theme.textTheme.meta,
                    ),
                  ),
                );
              }
              return Column(
                children: meals.map((m) {
                  final type = MealType.values.byName(m.mealType);
                  final tile = ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.foodName, style: theme.textTheme.bodyLarge),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${type.label} · ${m.grams.toStringAsFixed(0)} g',
                          style: theme.textTheme.meta,
                        ),
                        Text(
                          'P ${m.proteinG.toStringAsFixed(0)} · '
                          'C ${m.carbG.toStringAsFixed(0)} · '
                          'F ${m.fatG.toStringAsFixed(0)}',
                          style: theme.textTheme.meta,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '${m.calories.round()}',
                      style: theme.textTheme.titleSmall,
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
                      color: scheme.error,
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
