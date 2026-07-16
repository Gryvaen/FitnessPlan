import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_breakdown.dart';

/// 「我的」入口页：只读配额摘要 + 进入「我的档案」编辑。
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text(
          '将清除所有饮食、体重、收藏与身体档案，相当于重新使用本程序。确定继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Future.wait([
        ref.read(mealRepositoryProvider).clearAll(),
        ref.read(weightRepositoryProvider).clearAll(),
        ref.read(foodRepositoryProvider).clearFavorites(),
        ref.read(formMemoryRepositoryProvider).clear(),
        ref.read(mealPresetRepositoryProvider).clearAll(),
        ref.read(waterRepositoryProvider).clearAll(),
      ]);
      await ref.read(profileProvider.notifier).clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清空失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            onPressed: _clearData,
            tooltip: '清空数据',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前每日配额', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${profile.targets.calories}',
                        style: theme.textTheme.statValue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'kcal',
                        style: theme.textTheme.statUnit?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'P ${profile.targets.proteinG.toStringAsFixed(0)} · '
                    'C ${profile.targets.carbG.toStringAsFixed(0)} · '
                    'F ${profile.targets.fatG.toStringAsFixed(0)}',
                    style: theme.textTheme.meta,
                  ),
                  if (profile.goal == FitnessGoal.cut &&
                      profile.dailyDeficit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '缺口 ${profile.dailyDeficit!.round()} kcal'
                      '${profile.weeklyLossKg != null ? ' · ${profile.weeklyLossKg!.toStringAsFixed(1)} kg/周' : ''}'
                      '${profile.goalWeeks != null ? ' · 约 ${profile.goalWeeks} 周' : ''}',
                      style: theme.textTheme.meta,
                    ),
                  ],
                  if (profile.calorieAdjustment > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '平台期 −${profile.calorieAdjustment} kcal',
                      style: theme.textTheme.meta,
                    ),
                  ],
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      '计算方法',
                      style: theme.textTheme.titleSmall,
                    ),
                    children: [CalorieBreakdown(plan: plan, compact: true)],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('我的档案'),
              subtitle: Text(
                '${profile.sex == Sex.male ? '男' : '女'} · ${profile.age} 岁 · '
                '${profile.heightCm.round()} cm · '
                '${profile.weightKg.toStringAsFixed(1)} kg · '
                '${profile.goal.label}',
                style: theme.textTheme.meta,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/edit'),
            ),
          ),
          const SizedBox(height: AppSpacing.field),
          Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: const Text('每日饮水目标'),
              subtitle: Text(
                '${ref.watch(waterGoalProvider)} ml',
                style: theme.textTheme.meta,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                var goal = ref.read(waterGoalProvider);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setLocal) => AlertDialog(
                      title: const Text('饮水目标'),
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: goal <= 500
                                ? null
                                : () => setLocal(() => goal -= 250),
                            icon: const Icon(Icons.remove),
                          ),
                          Text('$goal ml', style: theme.textTheme.titleLarge),
                          IconButton(
                            onPressed: goal >= 5000
                                ? null
                                : () => setLocal(() => goal += 250),
                            icon: const Icon(Icons.add),
                          ),
                        ],
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
                  ),
                );
                if (ok == true) {
                  await ref.read(waterGoalProvider.notifier).setGoal(goal);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
