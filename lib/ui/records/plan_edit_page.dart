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

class PlanEditPage extends ConsumerStatefulWidget {
  const PlanEditPage({super.key, this.planId});

  final int? planId;

  @override
  ConsumerState<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanRow {
  _PlanRow({
    this.exercise,
    this.targetSets = 3,
    this.targetReps = 12,
  });

  Exercise? exercise;
  int targetSets;
  int targetReps;
}

class _PlanEditPageState extends ConsumerState<PlanEditPage> {
  final _nameCtrl = TextEditingController();
  final _rows = <_PlanRow>[_PlanRow()];
  var _loading = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
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
      _rows
        ..clear()
        ..addAll([
          for (final item in match.items)
            _PlanRow(
              exercise: byId[item.exerciseId],
              targetSets: item.targetSets,
              targetReps: item.targetReps,
            ),
        ]);
      if (_rows.isEmpty) _rows.add(_PlanRow());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.planNameRequired)),
      );
      return;
    }
    final items = <PlanDraftItem>[];
    for (final row in _rows) {
      final ex = row.exercise;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectOneExercise)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      if (widget.planId == null) {
        await repo.createPlan(name: name, items: items);
      } else {
        await repo.updatePlan(
          planId: widget.planId!,
          name: name,
          items: items,
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercisesAsync = ref.watch(exercisesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planId == null ? l10n.newPlan : l10n.editPlan),
        actions: [
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
                  return Center(child: Text(l10n.addExercisesFirstShort));
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.formPage),
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.planName,
                        hintText: l10n.planNameHint,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Text(l10n.exercise, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _rows.length; i++) ...[
                      _PlanRowCard(
                        row: _rows[i],
                        exercises: exercises,
                        canRemove: _rows.length > 1,
                        onChanged: () => setState(() {}),
                        onRemove: () => setState(() => _rows.removeAt(i)),
                      ),
                      const SizedBox(height: AppSpacing.field),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _rows.add(_PlanRow(exercise: exercises.first)),
                      ),
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

class _PlanRowCard extends StatelessWidget {
  const _PlanRowCard({
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

  Exercise _selectedExercise() {
    final current = row.exercise;
    if (current != null) {
      for (final e in exercises) {
        if (e.id == current.id) return e;
      }
    }
    return exercises.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selectedExercise();
    if (row.exercise == null || row.exercise!.id != selected.id) {
      row.exercise = selected;
    }
    final unit = ExerciseUnit.fromStorage(selected.unit);
    final isSeconds = unit == ExerciseUnit.seconds;
    final targetLabel = isSeconds ? l10n.targetSeconds : l10n.targetReps;
    final targetOptions =
        isSeconds ? FormOptions.targetSeconds : FormOptions.targetRepsOrSeconds;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppDropdown<Exercise>(
                    label: l10n.exercise,
                    value: selected,
                    items: exercises,
                    itemLabel: (e) => e.name,
                    onChanged: (v) {
                      row.exercise = v;
                      onChanged();
                    },
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
            Row(
              children: [
                Expanded(
                  child: AppDropdown<int>(
                    label: l10n.targetSets,
                    value: FormOptions.snapInt(
                      FormOptions.targetSets,
                      row.targetSets,
                    ),
                    items: FormOptions.targetSets,
                    onChanged: (v) {
                      row.targetSets = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<int>(
                    label: targetLabel,
                    value: FormOptions.snapInt(targetOptions, row.targetReps),
                    items: targetOptions,
                    onChanged: (v) {
                      row.targetReps = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
