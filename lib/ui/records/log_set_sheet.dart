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
  double? initialActualWeightKg,
  String? initialActualWeightUnit,
  String? initialNote,
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
    showDragHandle: true,
    builder: (ctx) => _EditProgressSheet(
      exerciseName: exerciseName,
      unit: unit,
      initialCompletedSets: completedSets,
      targetSets: targetSets,
      initialPerSetValue: perSetValue,
      initialActualWeightKg: initialActualWeightKg,
      initialActualWeightUnit: initialActualWeightUnit,
      initialNote: initialNote,
      onSave: (sets, value, actualWeightKg, actualWeightUnit, note) async {
        await ref
            .read(workoutRepositoryProvider)
            .updateDayItemProgress(
              dayWorkoutItemId: dayWorkoutItemId,
              day: day,
              completedSets: sets,
              perSetValue: value,
              unit: unit,
              actualWeightKg: actualWeightKg,
              actualWeightUnit: actualWeightUnit,
              note: note,
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
    this.initialActualWeightKg,
    this.initialActualWeightUnit,
    this.initialNote,
    required this.onSave,
  });

  final String exerciseName;
  final ExerciseUnit unit;
  final int initialCompletedSets;
  final int targetSets;
  final int initialPerSetValue;
  final double? initialActualWeightKg;
  final String? initialActualWeightUnit;
  final String? initialNote;
  final Future<void> Function(
    int completedSets,
    int perSetValue,
    double? actualWeightKg,
    String? actualWeightUnit,
    String? note,
  )
  onSave;

  @override
  State<_EditProgressSheet> createState() => _EditProgressSheetState();
}

class _EditProgressSheetState extends State<_EditProgressSheet> {
  late int _completedSets;
  late int _perSetValue;
  late GymWeightUnit _weightUnit;
  late double? _displayWeight;
  late final _noteCtrl = TextEditingController(text: widget.initialNote ?? '');
  var _saving = false;

  List<int> get _setOptions {
    final max = widget.targetSets > 10 ? widget.targetSets : 10;
    return [for (var i = 0; i <= max; i++) i];
  }

  List<int> get _valueOptions => widget.unit == ExerciseUnit.seconds
      ? FormOptions.targetSeconds
      : FormOptions.targetRepsOrSeconds;

  List<double> get _weightOptions =>
      FormOptions.gymLoadOptions(_weightUnit, include: _displayWeight);

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
    _weightUnit = GymWeightUnit.parse(widget.initialActualWeightUnit);
    final kg = widget.initialActualWeightKg;
    if (kg == null) {
      _displayWeight = null;
    } else {
      final converted = FormOptions.fromKg(kg, _weightUnit);
      _displayWeight = FormOptions.snapDouble(
        FormOptions.gymLoadOptions(_weightUnit, include: converted),
        converted,
      );
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _setWeightUnit(GymWeightUnit next) {
    if (next == _weightUnit) return;
    final current = _displayWeight;
    setState(() {
      if (current != null) {
        final asKg = FormOptions.toKg(current, _weightUnit);
        final converted = FormOptions.fromKg(asKg, next);
        _displayWeight = FormOptions.snapDouble(
          FormOptions.gymLoadOptions(next, include: converted),
          converted,
        );
      }
      _weightUnit = next;
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final kg = _displayWeight == null
          ? null
          : FormOptions.toKg(_displayWeight!, _weightUnit);
      await widget.onSave(
        _completedSets,
        _perSetValue,
        kg,
        _displayWeight == null ? null : _weightUnit.storageKey,
        _noteCtrl.text,
      );
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

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        0,
        AppSpacing.formPage,
        AppSpacing.formPage + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.exerciseName, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.editSetsHint(widget.targetSets, valueLabel),
              style: theme.textTheme.meta,
            ),
            const SizedBox(height: AppSpacing.section),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StepperField(
                    label: l10n.completedSets,
                    value: _completedSets,
                    onMinus: _completedSets > _setOptions.first
                        ? () => setState(() => _completedSets--)
                        : null,
                    onPlus: _completedSets < _setOptions.last
                        ? () => setState(() => _completedSets++)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.field),
                Expanded(
                  child: _StepperField(
                    label: valueLabel,
                    value: _perSetValue,
                    onMinus: () => setState(
                      () => _perSetValue = (_perSetValue - 1).clamp(0, 999),
                    ),
                    onPlus: () => setState(
                      () => _perSetValue = (_perSetValue + 1).clamp(0, 999),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _SectionLabel(
              label: l10n.actualWeightLabel,
              trailing: SegmentedButton<GymWeightUnit>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(value: GymWeightUnit.kg, label: Text('KG')),
                  ButtonSegment(value: GymWeightUnit.lbs, label: Text('LBS')),
                ],
                selected: {_weightUnit},
                onSelectionChanged: (s) => _setWeightUnit(s.first),
              ),
            ),
            const SizedBox(height: AppSpacing.compact),
            AppOptionalDropdown<double>(
              label: '',
              value: _displayWeight,
              items: _weightOptions,
              suffixText: _weightUnit.suffix,
              itemLabel: formatKg,
              noneLabel: l10n.leaveBlank,
              onChanged: (v) => setState(() => _displayWeight = v),
            ),
            const SizedBox(height: AppSpacing.section),
            _SectionLabel(label: l10n.exerciseNoteLabel),
            const SizedBox(height: AppSpacing.compact),
            TextField(
              controller: _noteCtrl,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.section),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(l10n.saveThisSet),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Compact labelled stepper that matches the shared picker field surface.
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
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _StepButton(icon: Icons.remove, onPressed: onMinus),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StepButton(icon: Icons.add, onPressed: onPlus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
