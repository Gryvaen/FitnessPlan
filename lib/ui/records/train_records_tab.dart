import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/step_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../today/today_workout_card.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/form_options.dart';

/// Training management: exercise catalog, plans, recent set history.
class TrainRecordsTab extends ConsumerStatefulWidget {
  const TrainRecordsTab({super.key, this.initialTab});

  /// When set, forces the sub-tab (0=计划, 1=历史, 2=动作库) to this index —
  /// overrides whatever this widget last had selected, since [RecordsPage]
  /// keeps it alive across navigations away and back.
  final int? initialTab;

  @override
  ConsumerState<TrainRecordsTab> createState() => _TrainRecordsTabState();
}

class _TrainRecordsTabState extends ConsumerState<TrainRecordsTab> {
  int _tab = 0;
  /// 0 = recent, 1 = all (under the History sub-tab).
  int _historyScope = 0;
  int? _planId;
  String _query = '';
  String? _category;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) _tab = widget.initialTab!;
  }

  @override
  void didUpdateWidget(covariant TrainRecordsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.initialTab;
    if (target != null && target != oldWidget.initialTab) {
      setState(() => _tab = target);
    }
  }

  int _dayExerciseCount(WorkoutHistoryDay day) {
    return {
      for (final item in day.completedItems) item.exerciseName,
      for (final set in day.sets) set.exerciseName,
    }.length;
  }

  /// "plan · done/total" per plan worked that day, or a plain exercise
  /// count when the day has no linked plan (e.g. free-form logging).
  String _dayProgressLabel(WorkoutHistoryDay day, AppLocalizations l10n) {
    if (!day.hasActivity) return l10n.historyEmptyDay;
    if (day.planSummaries.isEmpty) {
      return l10n.nExercises(_dayExerciseCount(day));
    }
    return day.planSummaries
        .map(
          (s) => l10n.planProgress(
            (s.planName?.trim().isNotEmpty ?? false)
                ? s.planName!.trim()
                : l10n.untitledWorkoutGroup,
            s.doneCount,
            s.totalCount,
          ),
        )
        .join(' · ');
  }

  void _showStepHistory(
    BuildContext context,
    List<StepDay> days,
    Locale locale, {
    required String title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final day in days)
              SportListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_walk),
                title: Text(AppDates.md(day.date, locale)),
                trailing: Text(context.l10n.nSteps(day.steps)),
              ),
          ],
        ),
      ),
    );
  }

  void _showWorkoutHistory(
    BuildContext context,
    List<WorkoutHistoryDay> days,
    Locale locale, {
    required String title,
  }) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final day in days)
              SportListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center),
                title: Text(AppDates.md(day.date, locale)),
                trailing: Text(_dayProgressLabel(day, l10n)),
                onTap: !day.hasActivity
                    ? null
                    : () => showDayWorkoutDetails(sheetContext, day.date),
              ),
          ],
        ),
      ),
    );
  }

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
      await ref
          .read(workoutRepositoryProvider)
          .addCustomExercise(
            name: form.name,
            unit: form.unit,
            category: form.category,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
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
      await ref
          .read(workoutRepositoryProvider)
          .updateExercise(
            id: exercise.id,
            name: form.name,
            unit: form.unit,
            category: form.category,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    }
  }

  Future<void> _start(WorkoutPlanSummary plan) async {
    if (_starting) return;
    setState(() => _starting = true);
    final day = AppDates.todayLocal();
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final snapshot = await repo.daySnapshot(day);
      if (!snapshot.groups.any((g) => g.workout.planId == plan.plan.id)) {
        await repo.applyPlanToDay(planId: plan.plan.id, day: day);
      }
      if (!mounted) return;
      await showDayWorkoutDetails(context, day);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.addFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _deletePlan(WorkoutPlanSummary plan) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlan),
        content: Text(l10n.confirmDeletePlan(plan.plan.name)),
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
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(workoutRepositoryProvider).deletePlan(plan.plan.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SportTabs<int>(
                  items: {
                    0: l10n.tabPlans,
                    1: l10n.tabHistory,
                    2: l10n.exerciseLibrary,
                  },
                  selected: _tab,
                  onSelected: (v) => setState(() => _tab = v),
                ),
              ),
              if (_tab != 1)
                PlainIconAction(
                  icon: Icons.add,
                  label: _tab == 0 ? l10n.fabNewPlan : l10n.addExercise,
                  onPressed: () => _tab == 0
                      ? context.push('/records/plan')
                      : _addExercise(context, ref),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SwipeTabView(
            index: _tab,
            onIndexChanged: (v) => setState(() => _tab = v),
            children: [
              _plansPanel(context),
              _historyPanel(context),
              _exercisesPanel(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _plansPanel(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        ref
            .watch(workoutPlansProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => SportLoadError(
                onRetry: () => ref.invalidate(workoutPlansProvider),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return SportEmptyState(
                    title: l10n.emptyPlans,
                    icon: Icons.fitness_center,
                  );
                }
                final plan =
                    plans.where((p) => p.plan.id == _planId).firstOrNull ??
                    plans.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.currentPlan, style: theme.textTheme.bodySmall),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.plan.name,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: l10n.more,
                          onSelected: (v) {
                            if (v == 'edit') {
                              context.push('/records/plan?id=${plan.plan.id}');
                            }
                            if (v == 'delete') _deletePlan(plan);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.edit),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      l10n.planSummary(
                        plan.items.length,
                        plan.items.fold<int>(0, (sum, i) => sum + i.targetSets),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _starting || plan.items.isEmpty
                          ? null
                          : () => _start(plan),
                      child: Text(l10n.startRecording),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.exerciseSchedule,
                      style: theme.textTheme.titleMedium,
                    ),
                    for (var i = 0; i < plan.items.length; i++)
                      SportListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(
                          '${i + 1}'.padLeft(2, '0'),
                          style: theme.textTheme.bodySmall,
                        ),
                        title: Text(plan.items[i].exerciseName),
                        subtitle: Text(
                          '${plan.items[i].targetSets} × ${plan.items[i].targetReps}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/records/plan?id=${plan.plan.id}'),
                      ),
                    if (plans.length > 1) ...[
                      const SizedBox(height: 24),
                      Text(l10n.otherPlans, style: theme.textTheme.titleMedium),
                    ],
                    for (final other in plans.where(
                      (p) => p.plan.id != plan.plan.id,
                    ))
                      SportListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(other.plan.name),
                        subtitle: Text(l10n.nExercises(other.items.length)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setState(() => _planId = other.plan.id),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _tab = 1),
                        child: Text(l10n.viewWorkoutHistory),
                      ),
                    ),
                  ],
                );
              },
            ),
      ],
    );
  }

  Widget _historyPanel(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SportTabs<int>(
            items: {
              0: l10n.tabRecent,
              1: l10n.filterAll,
            },
            selected: _historyScope,
            onSelected: (v) => _setHistoryScope(v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SwipeTabView(
            index: _historyScope,
            onIndexChanged: _setHistoryScope,
            children: [
              _historyScopeList(context, all: false),
              _historyScopeList(context, all: true),
            ],
          ),
        ),
      ],
    );
  }

  void _setHistoryScope(int v) {
    setState(() => _historyScope = v);
    if (v == 1) {
      // Pull a wider sensor window so "全部步数" can show more days.
      ref.read(stepsSyncServiceProvider).syncRecent(limitDays: 90);
    }
  }

  Widget _historyScopeList(BuildContext context, {required bool all}) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final stepsAsync = ref.watch(all ? allStepsProvider : recentStepsProvider);
    final workoutsAsync = ref.watch(
      all ? allWorkoutHistoryProvider : workoutHistoryProvider,
    );
    final stepsTitle = all ? l10n.allSteps : l10n.recentSteps;
    final workoutsTitle = all ? l10n.allWorkouts : l10n.workoutHistory;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        stepsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (days) {
            // Recent: 14 calendar days (zeros allowed). All: only days with data.
            final visible = all
                ? [for (final d in days) if (d.steps > 0) d]
                : days;
            if (visible.isEmpty) return const SizedBox.shrink();
            final latest = visible.first;
            return SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.directions_walk),
              title: Text(stepsTitle),
              subtitle: Text(AppDates.md(latest.date, locale)),
              trailing: Text(l10n.nSteps(latest.steps)),
              onTap: () => _showStepHistory(
                context,
                visible,
                locale,
                title: stepsTitle,
              ),
            );
          },
        ),
        workoutsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => SportLoadError(
            onRetry: () {
              if (all) {
                ref.invalidate(allWorkoutHistoryProvider);
              } else {
                ref.invalidate(workoutHistoryProvider);
              }
            },
          ),
          data: (days) {
            // Recent always has 14 calendar rows (empty days show「无」).
            // All only lists days that actually have activity.
            if (all && days.isEmpty) {
              return SportEmptyState(
                title: l10n.noSetLogs,
                icon: Icons.fitness_center,
              );
            }
            if (days.isEmpty) return const SizedBox.shrink();
            final latest = days.first;
            return SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fitness_center),
              title: Text(workoutsTitle),
              subtitle: Text(AppDates.md(latest.date, locale)),
              trailing: Text(_dayProgressLabel(latest, l10n)),
              onTap: () => _showWorkoutHistory(
                context,
                days,
                locale,
                title: workoutsTitle,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _exercisesPanel(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: l10n.exerciseName,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.filterAll),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final c in kExerciseCategoryOrder)
              ChoiceChip(
                label: Text(c.localizedExerciseCategory(l10n)),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        ref
            .watch(exercisesProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => SportLoadError(
                onRetry: () => ref.invalidate(exercisesProvider),
              ),
              data: (exercises) {
                final visible = exercises
                    .where(
                      (e) =>
                          (_category == null || e.category == _category) &&
                          e.name.toLowerCase().contains(_query),
                    )
                    .toList();
                if (visible.isEmpty) {
                  return SportEmptyState(
                    title: l10n.noExercises,
                    icon: Icons.fitness_center,
                  );
                }
                return Column(
                  children: [
                    for (final ex in visible)
                      SportListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(ex.name),
                        subtitle: Text(
                          '${ex.category.localizedExerciseCategory(l10n)} · ${ExerciseUnit.fromStorage(ex.unit).label(l10n)}',
                        ),
                        onTap: () => _editExercise(context, ref, ex),
                        trailing: ex.isCustom
                            ? IconButton(
                                tooltip: l10n.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.delete),
                                      content: Text(ex.name),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(l10n.cancel),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(l10n.delete),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true || !context.mounted) return;
                                  try {
                                    await ref
                                        .read(workoutRepositoryProvider)
                                        .deleteCustomExercise(ex.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    }
                                  }
                                },
                              )
                            : const Icon(Icons.chevron_right),
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
        final isSeconds =
            selected != null &&
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
    await ref
        .read(workoutRepositoryProvider)
        .addQuickDayItem(
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

class _ExerciseFormDialog extends StatefulWidget {
  const _ExerciseFormDialog({this.exercise, this.defaultCategory = 'chest'});

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
    _selectedCategory =
        exercise != null && kExerciseCategoryOrder.contains(exercise.category)
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
