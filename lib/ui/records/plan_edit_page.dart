import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';
import '../widgets/search_field_focus.dart';
import 'exercise_form_dialog.dart';
import 'exercise_picker.dart';

class PlanEditPage extends ConsumerStatefulWidget {
  const PlanEditPage({super.key, this.planId, this.syncDay});

  final int? planId;
  final DateTime? syncDay;

  @override
  ConsumerState<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanRow {
  _PlanRow({
    this.exerciseId,
    this.missingExerciseName,
    this.targetSets = 3,
    this.targetReps = 12,
  });

  int? exerciseId;
  String? missingExerciseName;
  int targetSets;
  int targetReps;
}

Exercise? _exerciseById(int? id, List<Exercise> exercises) {
  if (id == null) return null;
  for (final e in exercises) {
    if (e.id == id) return e;
  }
  return null;
}

/// Builds a draft row from either a saved plan item or a live day-workout
/// item — both share the same exerciseId/exerciseName/targetSets/targetReps
/// shape, so [_loadExisting] can source rows from whichever reflects the
/// "current" arrangement for that entry point.
_PlanRow _rowFromItem(
  int exerciseId,
  String exerciseName,
  int targetSets,
  int targetReps,
  Map<int, Exercise> byId,
  Map<String, Exercise> byName,
) {
  final resolved = byId[exerciseId] ?? byName[exerciseName];
  return _PlanRow(
    exerciseId: resolved?.id ?? exerciseId,
    missingExerciseName: resolved == null ? exerciseName : null,
    targetSets: targetSets,
    targetReps: targetReps,
  );
}

class _PlanEditPageState extends ConsumerState<PlanEditPage> {
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _rows = <_PlanRow>[_PlanRow()];
  var _loading = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    suppressInitialTextFocus(_nameFocus);
    if (widget.planId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final plans = await repo.listPlanSummaries();
      WorkoutPlanSummary? match;
      for (final p in plans) {
        if (p.plan.id == widget.planId) {
          match = p;
          break;
        }
      }
      if (match == null || !mounted) return;
      _nameCtrl.text = match.plan.name;
      final exercises = await repo.listExercises();
      final byId = {for (final e in exercises) e.id: e};
      final byName = {for (final e in exercises) e.name: e};

      // Entered via "today's specific arrangement" (its day-workout group
      // tile) → show what's actually scheduled for that day right now
      // (including ad-hoc quick-added/removed items), not the saved
      // template, so editing here can't silently wipe those out on save.
      final dayItems = widget.syncDay == null
          ? const <DayWorkoutItem>[]
          : await repo.dayItemsForPlanOnDay(
              planId: widget.planId!,
              day: widget.syncDay!,
            );
      if (!mounted) return;

      _rows
        ..clear()
        ..addAll(
          dayItems.isNotEmpty
              ? [
                  for (final item in dayItems)
                    _rowFromItem(
                      item.exerciseId,
                      item.exerciseName,
                      item.targetSets,
                      item.targetReps,
                      byId,
                      byName,
                    ),
                ]
              : [
                  for (final item in match.items)
                    _rowFromItem(
                      item.exerciseId,
                      item.exerciseName,
                      item.targetSets,
                      item.targetReps,
                      byId,
                      byName,
                    ),
                ],
        );
      if (_rows.isEmpty) _rows.add(_PlanRow());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.loadFailed('$e'))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _addExerciseToLibrary() async {
    final l10n = context.l10n;
    final form = await showExerciseFormDialog(context: context);
    if (form == null || !mounted) return;
    try {
      final id = await ref
          .read(workoutRepositoryProvider)
          .addCustomExercise(
            name: form.name,
            unit: form.unit,
            category: form.category,
          );
      if (!mounted) return;
      // Also drop it straight into the plan being edited — into the first
      // still-empty row if there is one, otherwise as a new row — instead of
      // only adding it to the library and leaving the user to hunt it down
      // in the exercise picker.
      setState(() {
        _PlanRow? emptyRow;
        for (final row in _rows) {
          if (row.exerciseId == null && row.missingExerciseName == null) {
            emptyRow = row;
            break;
          }
        }
        if (emptyRow != null) {
          emptyRow.exerciseId = id;
        } else {
          _rows.add(_PlanRow()..exerciseId = id);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.planNameRequired)));
      return;
    }
    // Flip the guard flag before the first await (disables the Save button
    // immediately) so a rapid double-tap can't both pass the `_saving`
    // check above and race into two `createPlan` calls.
    setState(() => _saving = true);
    try {
      final exercises = await ref
          .read(workoutRepositoryProvider)
          .listExercises();
      if (!mounted) return;
      final items = <PlanDraftItem>[];
      for (final row in _rows) {
        final ex = _exerciseById(row.exerciseId, exercises);
        if (ex == null) continue;
        items.add(
          PlanDraftItem(
            exerciseId: ex.id,
            exerciseName: ex.name,
            targetSets: row.targetSets,
            targetReps: row.targetReps,
          ),
        );
      }
      if (items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.selectOneExercise)));
        return;
      }

      final repo = ref.read(workoutRepositoryProvider);
      if (widget.planId == null) {
        await repo.createPlan(name: name, items: items);
      } else {
        await repo.updatePlan(
          planId: widget.planId!,
          name: name,
          items: items,
          // Opened without an explicit syncDay (e.g. from the 计划 tab) still
          // needs to sync today's arrangement when this plan has already
          // been "开始记录"-ed today — _syncPlanToDay is a no-op if it
          // hasn't, so defaulting to today here is safe either way.
          syncDay: widget.syncDay ?? AppDates.todayLocal(),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercisesAsync = ref.watch(exercisesProvider);
    final theme = Theme.of(context);
    final hasExercises = exercisesAsync.maybeWhen(
      data: (exercises) => exercises.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planId == null ? l10n.newPlan : l10n.editPlan),
        actions: [
          IconButton(
            tooltip: l10n.addExercise,
            onPressed: _saving ? null : _addExerciseToLibrary,
            icon: const Icon(Icons.add),
          ),
          if (hasExercises)
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.loadFailed('$e'))),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return _PlanNoExercisesEmpty(
                    onOpenLibrary: () {
                      // Prefer a single go() — pop()+go() in the same frame
                      // races go_router's page sync under StatefulShellRoute.
                      context.go('/records?tab=train&sub=library');
                    },
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.formPage),
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      decoration: InputDecoration(
                        labelText: l10n.planName,
                        hintText: l10n.planNameHint,
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _nameCtrl,
                          builder: (context, value, _) => value.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _nameCtrl.clear(),
                                ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Text(l10n.exercise, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _rows.length,
                      onReorderItem: (fromIndex, toIndex) => setState(() {
                        final row = _rows.removeAt(fromIndex);
                        _rows.insert(toIndex, row);
                      }),
                      itemBuilder: (context, i) => Padding(
                        key: ObjectKey(_rows[i]),
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: SizedBox(
                                width: 44,
                                height: 56,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${i + 1}'.padLeft(2, '0'),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(
                                      Icons.drag_handle,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _PlanRowSection(
                                row: _rows[i],
                                exercises: exercises,
                                canRemove: _rows.length > 1,
                                onChanged: () => setState(() {}),
                                onRemove: () =>
                                    setState(() => _rows.removeAt(i)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _rows.add(_PlanRow())),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addExercise),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Empty library state for plan editing: prompt + CTA to exercise library.
class _PlanNoExercisesEmpty extends StatelessWidget {
  const _PlanNoExercisesEmpty({required this.onOpenLibrary});

  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.formPage,
          vertical: 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(height: AppSpacing.section),
            Text(
              l10n.addExercisesFirstShort,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(
              l10n.addExercisesFirst,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            FilledButton.icon(
              onPressed: onOpenLibrary,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.goToExerciseLibrary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRowSection extends StatelessWidget {
  const _PlanRowSection({
    required this.row,
    required this.exercises,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _PlanRow row;
  final List<Exercise> exercises;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  void _setExercise(Exercise exercise) {
    row.exerciseId = exercise.id;
    row.missingExerciseName = null;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _exerciseById(row.exerciseId, exercises);
    final unit = ExerciseUnit.fromStorage(
      selected?.unit ?? ExerciseUnit.reps.name,
    );
    final category = selected?.category;
    final targetLabel = unit.targetLabel(l10n, category: category);
    final targetOptions = FormOptions.exerciseTargetOptions(
      unit,
      category: category,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ExercisePicker(
                label: l10n.exercise,
                displayText:
                    selected?.name ??
                    row.missingExerciseName ??
                    l10n.selectOneExercise,
                selectedId: selected?.id,
                exercises: exercises,
                onChanged: _setExercise,
              ),
            ),
            if (canRemove)
              IconButton(
                tooltip: l10n.remove,
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppDropdown<int>(
          label: l10n.targetSets,
          value: FormOptions.snapInt(FormOptions.targetSets, row.targetSets),
          items: FormOptions.targetSets,
          onChanged: (v) {
            row.targetSets = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        AppDropdown<int>(
          label: targetLabel,
          value: FormOptions.snapInt(targetOptions, row.targetReps),
          items: targetOptions,
          onChanged: (v) {
            row.targetReps = v;
            onChanged();
          },
        ),
      ],
    );
  }
}

