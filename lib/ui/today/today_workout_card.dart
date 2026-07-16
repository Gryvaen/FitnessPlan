import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/workout_repository.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../records/log_set_sheet.dart';
import '../records/train_records_tab.dart';
import '../theme/app_theme.dart';

/// Today's planned workout checklist with set logging.
class TodayWorkoutCard extends ConsumerWidget {
  const TodayWorkoutCard({
    super.key,
    required this.day,
    required this.sectionPrefix,
  });

  final DateTime day;
  final String sectionPrefix;

  Future<void> _pickPlan(BuildContext context, WidgetRef ref) async {
    final plans = await ref.read(workoutRepositoryProvider).listPlanSummaries();
    if (!context.mounted) return;
    if (plans.isEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('还没有训练计划'),
          content: const Text('先去「记录 → 训练」新建计划，或直接添加一个动作。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('添加动作'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('去记录'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (go == true) {
        context.go('/records?tab=train');
      } else if (go == false) {
        await showQuickAddDayItemDialog(context: context, ref: ref, day: day);
      }
      return;
    }

    final choice = await showModalBottomSheet<Object>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('快速添加动作'),
              onTap: () => Navigator.pop(ctx, 'quick'),
            ),
            const Divider(height: 1),
            for (final p in plans)
              ListTile(
                title: Text(p.plan.name),
                subtitle: Text(
                  p.items
                      .map((i) => '${i.exerciseName} ${i.targetSets}×${i.targetReps}')
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'quick') {
      await showQuickAddDayItemDialog(context: context, ref: ref, day: day);
      return;
    }
    if (choice is WorkoutPlanSummary) {
      final existing =
          await ref.read(workoutRepositoryProvider).dayWorkoutFor(day);
      if (existing != null && context.mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('替换今日训练'),
            content: const Text('当天已有训练待办，将替换为该计划，确定？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('替换'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      await ref.read(workoutRepositoryProvider).applyPlanToDay(
            planId: choice.plan.id,
            day: day,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayWorkoutProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: async.when(
          loading: () => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('训练加载失败：$e'),
          data: (snapshot) {
            if (snapshot.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$sectionPrefix训练', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '还没有训练待办',
                    style: theme.textTheme.meta,
                  ),
                  const SizedBox(height: AppSpacing.field),
                  OutlinedButton.icon(
                    onPressed: () => _pickPlan(context, ref),
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('添加今日训练'),
                  ),
                ],
              );
            }

            final done = snapshot.doneCount;
            final total = snapshot.items.length;
            final planName = snapshot.workout?.planName;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$sectionPrefix训练',
                            style: theme.textTheme.titleMedium,
                          ),
                          if (planName != null && planName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(planName, style: theme.textTheme.meta),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '添加',
                      onPressed: () => _pickPlan(context, ref),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final progress in snapshot.items)
                  Dismissible(
                    key: ValueKey(progress.item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: scheme.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref
                          .read(workoutRepositoryProvider)
                          .deleteDayWorkoutItem(progress.item.id);
                      ref.invalidate(workoutHistoryProvider);
                    },
                    child: _WorkoutItemTile(
                      progress: progress,
                      day: day,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '进度 $done/$total · 点条目修改组数与次数/秒 · 左滑删除',
                  style: theme.textTheme.meta,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkoutItemTile extends ConsumerWidget {
  const _WorkoutItemTile({
    required this.progress,
    required this.day,
  });

  final DayWorkoutItemProgress progress;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = progress.item;
    final unitLabel =
        progress.unit == ExerciseUnit.seconds ? '秒' : '次';
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: item.done,
        onChanged: (v) {
          ref
              .read(workoutRepositoryProvider)
              .setItemDone(item.id, v ?? false);
        },
      ),
      title: Text(
        item.exerciseName,
        style: item.done
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        item.done
            ? '已完成'
            : '${progress.completedSets}/${item.targetSets} 组 · 目标 ${item.targetReps} $unitLabel',
        style: theme.textTheme.meta,
      ),
      onTap: () async {
        await showLogSetSheet(
          context: context,
          ref: ref,
          day: day,
          exerciseName: item.exerciseName,
          unit: progress.unit,
          dayWorkoutItemId: item.id,
          completedSets: progress.completedSets,
          targetSets: item.targetSets,
          perSetValue: item.targetReps,
        );
        ref.invalidate(workoutHistoryProvider);
      },
    );
  }
}
