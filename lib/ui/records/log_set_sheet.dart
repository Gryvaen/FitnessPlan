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

  /// Which unit the value currently in [_weightKg] was last typed in — kept
  /// only to persist as `actualWeightUnit`; both KG and LBS fields are
  /// always shown and edited at once (see [_displayFor]/[_onWeightChanged]).
  late GymWeightUnit _weightUnit;

  /// Canonical, unrounded weight in kg — the single source of truth both
  /// fields are derived from. Deriving both displays fresh from this value
  /// (instead of converting field-to-field) means the KG and LBS fields
  /// never accumulate rounding drift no matter how often you edit either one.
  double? _weightKg;
  late final _noteCtrl = TextEditingController(text: widget.initialNote ?? '');
  var _saving = false;
  var _weightExpanded = false;
  var _noteExpanded = false;

  List<int> get _setOptions {
    final max = widget.targetSets > 10 ? widget.targetSets : 10;
    return [for (var i = 0; i <= max; i++) i];
  }

  List<int> get _valueOptions => widget.unit == ExerciseUnit.seconds
      ? FormOptions.targetSeconds
      : FormOptions.targetRepsOrSeconds;

  List<double> _optionsFor(GymWeightUnit unit) => FormOptions.gymLoadOptions(
    unit,
    include: _weightKg == null ? null : FormOptions.fromKg(_weightKg!, unit),
  );

  double? _displayFor(GymWeightUnit unit) {
    if (_weightKg == null) return null;
    final raw = FormOptions.fromKg(_weightKg!, unit);
    return FormOptions.snapDouble(_optionsFor(unit), raw);
  }

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
    _weightKg = widget.initialActualWeightKg;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onWeightChanged(GymWeightUnit unit, double? v) {
    setState(() {
      _weightKg = v == null ? null : FormOptions.toKg(v, unit);
      _weightUnit = unit;
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final kg = _weightKg;
      await widget.onSave(
        _completedSets,
        _perSetValue,
        kg,
        kg == null ? null : _weightUnit.storageKey,
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
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * .9;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (maxHeight - bottom).clamp(0, maxHeight),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.formPage,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.editTrainingRecord,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.exerciseName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.trainingSetTarget(widget.targetSets),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.completedSets,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StepButton(
                              large: true,
                              tooltip: l10n.decreaseCompletedSets,
                              icon: Icons.remove,
                              onPressed:
                                  !_saving && _completedSets > _setOptions.first
                                  ? () => setState(() => _completedSets--)
                                  : null,
                            ),
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    '$_completedSets',
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    l10n.trainingSetDenominator(
                                      widget.targetSets,
                                    ),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            _StepButton(
                              large: true,
                              tooltip: l10n.increaseCompletedSets,
                              icon: Icons.add,
                              onPressed:
                                  !_saving && _completedSets < _setOptions.last
                                  ? () => setState(() => _completedSets++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (widget.targetSets > 0)
                          ExcludeSemantics(
                            child: widget.targetSets <= 10
                                ? Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < widget.targetSets;
                                        i++
                                      )
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: i < _completedSets
                                                ? scheme.primary
                                                : null,
                                            border: Border.all(
                                              color: i < _completedSets
                                                  ? scheme.primary
                                                  : scheme.outline,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : LinearProgressIndicator(
                                    value: (_completedSets / widget.targetSets)
                                        .clamp(0, 1),
                                  ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.unit == ExerciseUnit.seconds
                                    ? l10n.trainingSecondsPerSet
                                    : l10n.trainingRepsPerSet,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            _StepButton(
                              tooltip: l10n.decreasePerSetValue,
                              icon: Icons.remove,
                              onPressed: !_saving && _perSetValue > 1
                                  ? () => setState(() => _perSetValue--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '$_perSetValue',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _StepButton(
                              tooltip: l10n.increasePerSetValue,
                              icon: Icons.add,
                              onPressed: !_saving && _perSetValue < 999
                                  ? () => setState(() => _perSetValue++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Divider(height: 1),
                        _DisclosureRow(
                          label: l10n.actualWeightLabel,
                          expanded: _weightExpanded,
                          onTap: _saving
                              ? null
                              : () => setState(
                                  () => _weightExpanded = !_weightExpanded,
                                ),
                        ),
                        if (_weightExpanded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AbsorbPointer(
                              absorbing: _saving,
                              child: Row(
                                children: [
                                  for (final unit in GymWeightUnit.values) ...[
                                    if (unit != GymWeightUnit.values.first)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Icon(
                                          Icons.swap_horiz,
                                          size: 20,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    Expanded(
                                      child: AppOptionalDropdown<double>(
                                        label: '',
                                        value: _displayFor(unit),
                                        items: _optionsFor(unit),
                                        suffixText: unit.suffix,
                                        itemLabel: formatKg,
                                        noneLabel: unit.suffix,
                                        onChanged: (v) =>
                                            _onWeightChanged(unit, v),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        const Divider(height: 1),
                        _DisclosureRow(
                          label: l10n.addTrainingNote,
                          expanded: _noteExpanded,
                          onTap: _saving
                              ? null
                              : () => setState(
                                  () => _noteExpanded = !_noteExpanded,
                                ),
                        ),
                        if (_noteExpanded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: _noteCtrl,
                              enabled: !_saving,
                              minLines: 1,
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: l10n.optionalHint,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Text(l10n.saveTrainingRecord),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      expanded: expanded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(expanded ? Icons.remove : Icons.add, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.large = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: large ? 22 : 18),
      style: IconButton.styleFrom(
        foregroundColor: icon == Icons.add ? scheme.primary : scheme.secondary,
        minimumSize: Size.square(large ? 40 : 36),
        maximumSize: Size.square(large ? 40 : 36),
        padding: const EdgeInsets.all(6),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
