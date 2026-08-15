import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/workout_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../records/log_set_sheet.dart';
import '../records/train_records_tab.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

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
    final l10n = context.l10n;
    if (!AppDates.isLocalToday(day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pastDayReadOnly)),
      );
      return;
    }
    final plans = await ref.read(workoutRepositoryProvider).listPlanSummaries();
    if (!context.mounted) return;
    if (plans.isEmpty) {
      final go = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.noWorkoutPlanTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.noWorkoutPlanBody),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.goRecords),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.quickAddExercise),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.quickAddExercise),
                onTap: () => Navigator.pop(ctx, 'quick'),
              ),
              const Divider(height: 1),
              for (final p in plans)
                ListTile(
                  title: Text(p.plan.name),
                  subtitle: Text(
                    p.items
                        .map(
                          (i) =>
                              '${i.exerciseName} ${i.targetSets}×${i.targetReps}',
                        )
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(ctx, p),
                ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'quick') {
      await showQuickAddDayItemDialog(context: context, ref: ref, day: day);
      return;
    }
    if (choice is WorkoutPlanSummary) {
      final snap =
          await ref.read(workoutRepositoryProvider).daySnapshot(day);
      if (!snap.isEmpty && context.mounted) {
        final ok = await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.replaceTodayWorkout),
            content: Text(l10n.replaceTodayWorkoutBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.replace),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      try {
        await ref.read(workoutRepositoryProvider).applyPlanToDay(
              planId: choice.plan.id,
              day: day,
            );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addFailed('$e'))),
        );
      }
    }
  }

  Future<void> _saveAsPlan(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final snap = await ref.read(workoutRepositoryProvider).daySnapshot(day);
    if (!context.mounted) return;
    if (snap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noWorkoutToSave)),
      );
      return;
    }
    final existingName = snap.workout?.planName?.trim();
    final nameCtrl = TextEditingController(
      text: (existingName != null && existingName.isNotEmpty)
          ? existingName
          : AppDates.relativeDayTitle(
              day,
              AppDates.todayLocal(),
              l10n,
              locale,
            ),
    );
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveAsPlan),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.planName,
            hintText: l10n.planNameHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final planName = nameCtrl.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => nameCtrl.dispose());
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(workoutRepositoryProvider).createPlanFromDay(
            day: day,
            name: planName,
          );
      ref.invalidate(workoutPlansProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.planSaved)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed('$e'))),
      );
    }
  }

  Widget _headerRow({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required bool canAdd,
    required bool canSaveAsPlan,
    required Widget title,
  }) {
    return Row(
      children: [
        Expanded(
          child: SportSectionTitle(child: title),
        ),
        if (canAdd)
          IconButton(
            tooltip: l10n.addTodayWorkout,
            onPressed: () => _pickPlan(context, ref),
            icon: const Icon(Icons.add),
          ),
        if (canSaveAsPlan)
          PopupMenuButton<String>(
            tooltip: l10n.more,
            onSelected: (value) async {
              if (value == 'savePlan') {
                await _saveAsPlan(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'savePlan',
                child: Text(l10n.saveAsPlan),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(todayWorkoutProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editable = AppDates.isLocalToday(day);

    return async.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(l10n.workoutLoadFailed('$e')),
      data: (snapshot) {
        if (snapshot.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(
                context: context,
                ref: ref,
                l10n: l10n,
                canAdd: editable,
                canSaveAsPlan: editable,
                title: Text(
                  l10n.sectionWorkout(sectionPrefix),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    editable ? l10n.noWorkoutTodo : l10n.pastDayReadOnly,
                    style: theme.textTheme.meta,
                  ),
                ),
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
            _headerRow(
              context: context,
              ref: ref,
              l10n: l10n,
              canAdd: editable,
              canSaveAsPlan: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sectionWorkout(sectionPrefix),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (planName != null && planName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(planName, style: theme.textTheme.meta),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final progress in snapshot.items)
              if (editable)
                Dismissible(
                  key: ValueKey(progress.item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.only(bottom: AppSpacing.field),
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: scheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.deleteWorkoutItem),
                            content: Text(
                              l10n.confirmDeleteWorkoutItem(
                                progress.item.exerciseName,
                              ),
                            ),
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
                        ) ==
                        true;
                  },
                  onDismissed: (_) {
                    ref
                        .read(workoutRepositoryProvider)
                        .deleteDayWorkoutItem(progress.item.id);
                    ref.invalidate(workoutHistoryProvider);
                  },
                  child: _WorkoutItemTile(
                    progress: progress,
                    day: day,
                    editable: true,
                  ),
                )
              else
                _WorkoutItemTile(
                  progress: progress,
                  day: day,
                  editable: false,
                ),
            Text(
              l10n.workoutProgressHint(done, total),
              style: theme.textTheme.meta,
            ),
          ],
        );
      },
    );
  }
}

class _WorkoutItemTile extends ConsumerWidget {
  const _WorkoutItemTile({
    required this.progress,
    required this.day,
    required this.editable,
  });

  final DayWorkoutItemProgress progress;
  final DateTime day;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final item = progress.item;
    final unitLabel = progress.unit.label(l10n);
    final theme = Theme.of(context);

    return SportListTile(
      leading: Checkbox(
        value: item.done,
        onChanged: editable
            ? (v) {
                ref
                    .read(workoutRepositoryProvider)
                    .setItemDone(item.id, v ?? false);
              }
            : null,
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
            ? l10n.completed
            : l10n.setsProgress(
                progress.completedSets,
                item.targetSets,
                '${item.targetReps}',
                unitLabel,
              ),
        style: theme.textTheme.meta,
      ),
      enabled: editable,
      onTap: !editable
          ? null
          : () async {
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
