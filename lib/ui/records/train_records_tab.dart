import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

/// Training management: exercise catalog, plans, recent set history.
class TrainRecordsTab extends ConsumerWidget {
  const TrainRecordsTab({super.key});

  Future<void> _addExercise(
    BuildContext context,
    WidgetRef ref, {
    String category = 'custom',
  }) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    var unit = ExerciseUnit.reps;
    var selectedCategory = category;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.addExercise),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.exerciseName),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: l10n.categories,
                value: selectedCategory,
                items: kExerciseCategoryOrder,
                itemLabel: (c) => c.localizedExerciseCategory(l10n),
                onChanged: (v) => setLocal(() => selectedCategory = v),
              ),
              const SizedBox(height: 12),
              AppDropdown<ExerciseUnit>(
                label: l10n.repsOrSeconds,
                value: unit,
                items: ExerciseUnit.values,
                itemLabel: (u) =>
                    u == ExerciseUnit.reps ? l10n.repsCount : l10n.seconds,
                onChanged: (v) => setLocal(() => unit = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.add),
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
            category: selectedCategory,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addFailed('$e'))),
      );
    } finally {
      nameCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final exercisesAsync = ref.watch(exercisesProvider);
    final plansAsync = ref.watch(workoutPlansProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.listPage,
        8,
        AppSpacing.listPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.exerciseLibrary,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l10n.addExercise,
              onPressed: () => _addExercise(context, ref),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 4),
        exercisesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.loadFailed('$e')),
          data: (exercises) {
            if (exercises.isEmpty) {
              return Text(l10n.noExercises, style: theme.textTheme.meta);
            }
            final grouped = <String, List<Exercise>>{};
            for (final ex in exercises) {
              grouped.putIfAbsent(ex.category, () => []).add(ex);
            }
            final orderedKeys = [
              for (final key in kExerciseCategoryOrder)
                if (grouped.containsKey(key)) key,
              for (final key in grouped.keys)
                if (!kExerciseCategoryOrder.contains(key)) key,
            ];
            return Column(
              children: [
                for (final key in orderedKeys)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    initiallyExpanded: false,
                    title: Text(
                      '${key.localizedExerciseCategory(l10n)} · ${grouped[key]!.length}',
                      style: theme.textTheme.titleSmall,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final ex in grouped[key]!)
                              InputChip(
                                label: Text(
                                  '${ex.name} · ${ExerciseUnit.fromStorage(ex.unit).label(l10n)}',
                                ),
                                onDeleted: ex.isCustom
                                    ? () async {
                                        try {
                                          await ref
                                              .read(workoutRepositoryProvider)
                                              .deleteCustomExercise(ex.id);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text('$e')),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.section),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.workoutPlans,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l10n.fabNewPlan,
              onPressed: () => context.push('/records/plan'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        plansAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.loadFailed('$e')),
          data: (plans) {
            if (plans.isEmpty) {
              return Text(
                l10n.emptyPlans,
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
                              title: Text(l10n.deletePlan),
                              content: Text(
                                l10n.confirmDeletePlan(summary.plan.name),
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
                          .deletePlan(summary.plan.id);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(summary.plan.name),
                      subtitle: Text(
                        summary.items.isEmpty
                            ? l10n.noExercisesInPlan
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
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.section),
        Text(l10n.workoutHistory, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.loadFailed('$e')),
          data: (days) {
            if (days.isEmpty) {
              return Text(l10n.noSetLogs, style: theme.textTheme.meta);
            }
            return Column(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.6),
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(AppDates.md(days[i].date, locale)),
                    subtitle: Text(
                      l10n.nSets(days[i].sets.length),
                      style: theme.textTheme.meta,
                    ),
                    children: [
                      for (final set in days[i].sets)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.setLine(set.exerciseName, set.setIndex),
                          ),
                          trailing: Text(
                            set.reps != null
                                ? l10n.nReps(set.reps!)
                                : l10n.nSeconds(set.durationSec ?? 0),
                            style: theme.textTheme.meta,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Quick-add a day workout item dialog (shared with today empty state).
///
/// Always presents on the root navigator so the dialog stays visible on the
/// current shell tab (StatefulShellRoute keeps inactive branch navigators).
Future<void> showQuickAddDayItemDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime day,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);

  List<Exercise> exercises;
  try {
    exercises = await ref.read(workoutRepositoryProvider).listExercises();
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
    return;
  }
  if (!context.mounted) return;
  if (exercises.isEmpty) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.addExercisesFirst)));
    return;
  }

  Exercise? selected = exercises.first;
  var sets = 3;
  var reps = 12;

  // Let any prior route (empty-plan dialog / bottom sheet) finish popping
  // before pushing onto the root overlay.
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return;

  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final isSeconds = selected != null &&
            ExerciseUnit.fromStorage(selected!.unit) == ExerciseUnit.seconds;
        final targetOptions = isSeconds
            ? FormOptions.targetSeconds
            : FormOptions.targetRepsOrSeconds;
        return AlertDialog(
          title: Text(l10n.addTodayExercise),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdown<Exercise>(
                  label: l10n.exercise,
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
                  label: l10n.targetSets,
                  value: FormOptions.snapInt(FormOptions.targetSets, sets),
                  items: FormOptions.targetSets,
                  onChanged: (v) => setLocal(() => sets = v),
                ),
                const SizedBox(height: 12),
                AppDropdown<int>(
                  label: isSeconds ? l10n.targetSeconds : l10n.targetReps,
                  value: FormOptions.snapInt(targetOptions, reps),
                  items: targetOptions,
                  onChanged: (v) => setLocal(() => reps = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.add),
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
    messenger?.showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
  }
}
