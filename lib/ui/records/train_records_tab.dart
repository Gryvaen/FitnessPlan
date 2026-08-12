import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/form_options.dart';

/// Training management: exercise catalog, plans, recent set history.
class TrainRecordsTab extends ConsumerWidget {
  const TrainRecordsTab({super.key});

  Future<_ExerciseFormData?> _showExerciseFormDialog({
    required BuildContext context,
    Exercise? exercise,
    String defaultCategory = 'chest',
  }) {
    return showDialog<_ExerciseFormData>(
      context: context,
      builder: (ctx) => _ExerciseFormDialog(
        exercise: exercise,
        defaultCategory: defaultCategory,
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final form = await _showExerciseFormDialog(context: context);
    if (form == null || !context.mounted) return;
    try {
      await ref.read(workoutRepositoryProvider).addCustomExercise(
            name: form.name,
            unit: form.unit,
            category: form.category,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addFailed('$e'))),
      );
    }
  }

  Future<void> _editExercise(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final l10n = context.l10n;
    final form = await _showExerciseFormDialog(
      context: context,
      exercise: exercise,
    );
    if (form == null || !context.mounted) return;
    try {
      await ref.read(workoutRepositoryProvider).updateExercise(
            id: exercise.id,
            name: form.name,
            unit: form.unit,
            category: form.category,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed('$e'))),
      );
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
        _SectionExpansionTile(
          title: Text(
            l10n.exerciseLibrary,
            style: theme.textTheme.titleMedium,
          ),
          addTooltip: l10n.addExercise,
          onAdd: () => _addExercise(context, ref),
          children: [
            exercisesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(l10n.loadFailed('$e')),
              data: (exercises) {
                final grouped = <String, List<Exercise>>{};
                for (final ex in exercises) {
                  final key = kExerciseCategoryOrder.contains(ex.category)
                      ? ex.category
                      : 'core';
                  grouped.putIfAbsent(key, () => []).add(ex);
                }
                return Column(
                  children: [
                    for (final key in kExerciseCategoryOrder)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        initiallyExpanded: false,
                        title: Text(
                          '${key.localizedExerciseCategory(l10n)} · ${grouped[key]?.length ?? 0}',
                          style: theme.textTheme.titleSmall,
                        ),
                        children: [
                          if ((grouped[key]?.isEmpty ?? true))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.noExercises,
                                style: theme.textTheme.meta,
                              ),
                            )
                          else
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
                                    onPressed: () =>
                                        _editExercise(context, ref, ex),
                                    onDeleted: ex.isCustom
                                        ? () async {
                                            try {
                                              await ref
                                                  .read(
                                                    workoutRepositoryProvider,
                                                  )
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
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        _SectionExpansionTile(
          title: Text(
            l10n.workoutPlans,
            style: theme.textTheme.titleMedium,
          ),
          addTooltip: l10n.fabNewPlan,
          onAdd: () => context.push('/records/plan'),
          children: [
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
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
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
                        child: SportListTile(
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
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: false,
          title: Text(
            l10n.workoutHistory,
            style: theme.textTheme.titleMedium,
          ),
          children: [
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
                        initiallyExpanded: false,
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

class _SectionExpansionTile extends StatefulWidget {
  const _SectionExpansionTile({
    required this.title,
    required this.children,
    this.onAdd,
    this.addTooltip,
  });

  final Widget title;
  final List<Widget> children;
  final VoidCallback? onAdd;
  final String? addTooltip;

  @override
  State<_SectionExpansionTile> createState() => _SectionExpansionTileState();
}

class _SectionExpansionTileState extends State<_SectionExpansionTile> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: false,
      onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
      title: widget.title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onAdd != null)
            IconButton(
              tooltip: widget.addTooltip,
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
            ),
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: kThemeAnimationDuration,
            child: Icon(
              Icons.expand_more,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      children: widget.children,
    );
  }
}

class _ExerciseFormDialog extends StatefulWidget {
  const _ExerciseFormDialog({
    this.exercise,
    this.defaultCategory = 'chest',
  });

  final Exercise? exercise;
  final String defaultCategory;

  @override
  State<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<_ExerciseFormDialog> {
  late final TextEditingController _nameCtrl;
  late ExerciseUnit _unit;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _nameCtrl = TextEditingController(text: exercise?.name ?? '');
    _unit = exercise != null
        ? ExerciseUnit.fromStorage(exercise.unit)
        : ExerciseUnit.reps;
    _selectedCategory = exercise != null &&
            kExerciseCategoryOrder.contains(exercise.category)
        ? exercise.category
        : widget.defaultCategory;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.exercise != null;
    return AlertDialog(
      title: Text(isEdit ? l10n.edit : l10n.addExercise),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.exerciseName),
              autofocus: !isEdit,
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: l10n.categories,
              value: _selectedCategory,
              items: kExerciseCategoryOrder,
              itemLabel: (c) => c.localizedExerciseCategory(l10n),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 12),
            AppDropdown<ExerciseUnit>(
              label: l10n.repsOrSeconds,
              value: _unit,
              items: ExerciseUnit.values,
              itemLabel: (u) =>
                  u == ExerciseUnit.reps ? l10n.repsCount : l10n.seconds,
              onChanged: (v) => setState(() => _unit = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ExerciseFormData(
              name: _nameCtrl.text,
              unit: _unit,
              category: _selectedCategory,
            ),
          ),
          child: Text(isEdit ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}

class _ExerciseFormData {
  const _ExerciseFormData({
    required this.name,
    required this.unit,
    required this.category,
  });

  final String name;
  final ExerciseUnit unit;
  final String category;
}
