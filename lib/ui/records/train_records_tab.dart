import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

/// Training management: exercise catalog, plans, recent set history.
class TrainRecordsTab extends ConsumerWidget {
  const TrainRecordsTab({super.key});

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    var unit = ExerciseUnit.reps;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('自定义动作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '动作名字'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              AppDropdown<ExerciseUnit>(
                label: '次数/秒',
                value: unit,
                items: ExerciseUnit.values,
                itemLabel: (u) => u == ExerciseUnit.reps ? '次数' : '秒',
                onChanged: (v) => setLocal(() => unit = v),
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
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(workoutRepositoryProvider).addCustomExercise(
            name: nameCtrl.text,
            unit: unit,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加失败：$e')),
      );
    } finally {
      nameCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final plansAsync = ref.watch(workoutPlansProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.listPage,
        8,
        AppSpacing.listPage,
        88,
      ),
      children: [
        Row(
          children: [
            Text('动作库', style: theme.textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addExercise(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('自定义'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        exercisesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('加载失败：$e'),
          data: (exercises) {
            if (exercises.isEmpty) {
              return Text('暂无动作', style: theme.textTheme.meta);
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ex in exercises)
                  InputChip(
                    label: Text(
                      '${ex.name} · ${ExerciseUnit.fromStorage(ex.unit).label}',
                    ),
                    onDeleted: ex.isCustom
                        ? () async {
                            try {
                              await ref
                                  .read(workoutRepositoryProvider)
                                  .deleteCustomExercise(ex.id);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        : null,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.section),
        Text('训练计划', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        plansAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('加载失败：$e'),
          data: (plans) {
            if (plans.isEmpty) {
              return Text(
                '还没有计划，点右下角新建',
                style: theme.textTheme.meta,
              );
            }
            return Column(
              children: [
                for (final summary in plans)
                  Dismissible(
                    key: ValueKey(summary.plan.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: theme.colorScheme.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('删除计划'),
                              content: Text('确定删除「${summary.plan.name}」？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          ) ==
                          true;
                    },
                    onDismissed: (_) {
                      ref
                          .read(workoutRepositoryProvider)
                          .deletePlan(summary.plan.id);
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(summary.plan.name),
                        subtitle: Text(
                          summary.items.isEmpty
                              ? '无动作'
                              : summary.items
                                  .map(
                                    (i) =>
                                        '${i.exerciseName} ${i.targetSets}×${i.targetReps}',
                                  )
                                  .join(' · '),
                          style: theme.textTheme.meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => context.push(
                          '/records/plan?id=${summary.plan.id}',
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.section),
        Text('训练历史', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('加载失败：$e'),
          data: (days) {
            if (days.isEmpty) {
              return Text('暂无组次记录', style: theme.textTheme.meta);
            }
            return Column(
              children: [
                for (final day in days)
                  Card(
                    child: ExpansionTile(
                      title: Text(DateFormat('M月d日').format(day.date)),
                      subtitle: Text(
                        '${day.sets.length} 组',
                        style: theme.textTheme.meta,
                      ),
                      children: [
                        for (final set in day.sets)
                          ListTile(
                            dense: true,
                            title: Text(
                              '${set.exerciseName} · 第 ${set.setIndex} 组',
                            ),
                            trailing: Text(
                              set.reps != null
                                  ? '${set.reps} 次'
                                  : '${set.durationSec ?? 0} 秒',
                              style: theme.textTheme.meta,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Quick-add a day workout item dialog (shared with today empty state).
Future<void> showQuickAddDayItemDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime day,
}) async {
  final exercises = await ref.read(exercisesProvider.future);
  if (!context.mounted) return;
  if (exercises.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请先在记录页添加动作')),
    );
    return;
  }

  Exercise? selected = exercises.first;
  var sets = 3;
  var reps = 12;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final isSeconds = selected != null &&
            ExerciseUnit.fromStorage(selected!.unit) == ExerciseUnit.seconds;
        final targetOptions = isSeconds
            ? FormOptions.targetSeconds
            : FormOptions.targetRepsOrSeconds;
        return AlertDialog(
          title: const Text('添加今日动作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<Exercise>(
                label: '动作',
                value: selected!,
                items: exercises,
                itemLabel: (e) => e.name,
                onChanged: (v) => setLocal(() {
                  selected = v;
                  reps = FormOptions.snapInt(
                    ExerciseUnit.fromStorage(v.unit) == ExerciseUnit.seconds
                        ? FormOptions.targetSeconds
                        : FormOptions.targetRepsOrSeconds,
                    reps,
                  );
                }),
              ),
              const SizedBox(height: 12),
              AppDropdown<int>(
                label: '目标组数',
                value: FormOptions.snapInt(FormOptions.targetSets, sets),
                items: FormOptions.targetSets,
                onChanged: (v) => setLocal(() => sets = v),
              ),
              const SizedBox(height: 12),
              AppDropdown<int>(
                label: isSeconds ? '目标秒数' : '目标次数',
                value: FormOptions.snapInt(targetOptions, reps),
                items: targetOptions,
                onChanged: (v) => setLocal(() => reps = v),
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
              child: const Text('添加'),
            ),
          ],
        );
      },
    ),
  );
  if (ok != true || selected == null || !context.mounted) return;
  try {
    await ref.read(workoutRepositoryProvider).addQuickDayItem(
          day: day,
          exerciseId: selected!.id,
          targetSets: sets,
          targetReps: reps,
        );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('添加失败：$e')),
    );
  }
}
