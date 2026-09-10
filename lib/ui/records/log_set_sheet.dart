import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

/// Edit today's item progress: completed sets + per-set reps/seconds.
Future<bool> showLogSetSheet({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime day,
  required String exerciseName,
  required ExerciseUnit unit,
  required int dayWorkoutItemId,
  required int completedSets,
  required int targetSets,
  required int perSetValue,
}) async {
  final l10n = context.l10n;
  if (!AppDates.isLocalToday(day)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.pastDayReadOnly)));
    return false;
  }
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _EditProgressSheet(
      exerciseName: exerciseName,
      unit: unit,
      initialCompletedSets: completedSets,
      targetSets: targetSets,
      initialPerSetValue: perSetValue,
      onSave: (sets, value) async {
        await ref
            .read(workoutRepositoryProvider)
            .updateDayItemProgress(
              dayWorkoutItemId: dayWorkoutItemId,
              day: day,
              completedSets: sets,
              perSetValue: value,
              unit: unit,
            );
        await ref.read(remindersProvider.notifier).syncSchedule();
        if (!ctx.mounted) return;
        Navigator.pop(ctx, true);
      },
    ),
  );
  return result == true;
}

class _EditProgressSheet extends StatefulWidget {
  const _EditProgressSheet({
    required this.exerciseName,
    required this.unit,
    required this.initialCompletedSets,
    required this.targetSets,
    required this.initialPerSetValue,
    required this.onSave,
  });

  final String exerciseName;
  final ExerciseUnit unit;
  final int initialCompletedSets;
  final int targetSets;
  final int initialPerSetValue;
  final Future<void> Function(int completedSets, int perSetValue) onSave;

  @override
  State<_EditProgressSheet> createState() => _EditProgressSheetState();
}

class _EditProgressSheetState extends State<_EditProgressSheet> {
  late int _completedSets;
  late int _perSetValue;
  var _saving = false;

  List<int> get _setOptions {
    final max = widget.targetSets > 10 ? widget.targetSets : 10;
    return [for (var i = 0; i <= max; i++) i];
  }

  List<int> get _valueOptions => widget.unit == ExerciseUnit.seconds
      ? FormOptions.targetSeconds
      : FormOptions.targetRepsOrSeconds;

  @override
  void initState() {
    super.initState();
    _completedSets = FormOptions.snapInt(
      _setOptions,
      widget.initialCompletedSets.clamp(0, _setOptions.last),
    );
    _perSetValue = FormOptions.snapInt(
      _valueOptions,
      widget.initialPerSetValue,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_completedSets, _perSetValue);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final valueLabel = widget.unit == ExerciseUnit.seconds
        ? l10n.durationSeconds
        : l10n.repsCount;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        AppSpacing.section,
        AppSpacing.formPage,
        AppSpacing.formPage + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.exerciseName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.editSetsHint(widget.targetSets, valueLabel),
            style: theme.textTheme.meta,
          ),
          const SizedBox(height: AppSpacing.section),
          _StepperField(
            label: l10n.completedSets,
            value: _completedSets,
            onMinus: _completedSets > _setOptions.first
                ? () => setState(() => _completedSets--)
                : null,
            onPlus: _completedSets < _setOptions.last
                ? () => setState(() => _completedSets++)
                : null,
          ),
          const SizedBox(height: AppSpacing.field),
          _StepperField(
            label: valueLabel,
            value: _perSetValue,
            onMinus: () =>
                setState(() => _perSetValue = (_perSetValue - 1).clamp(0, 999)),
            onPlus: () =>
                setState(() => _perSetValue = (_perSetValue + 1).clamp(0, 999)),
          ),
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(l10n.saveThisSet),
          ),
        ],
      ),
    );
  }
}

/// A labelled `− value +` stepper row for the log-set sheet.
class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            IconButton.outlined(
              onPressed: onMinus,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            IconButton.outlined(onPressed: onPlus, icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}
