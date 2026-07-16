import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../../data/repositories/water_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late Sex _sex;
  late ActivityLevel _activity;
  late FitnessGoal _goal;
  late int _age;
  late int _heightCm;
  late double _weightKg;
  late double _targetWeightKg;
  late double _weeklyLossKg;
  int? _waterGoalMl;
  bool _ready = false;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    if (p != null) {
      _sex = p.sex;
      _activity = p.activity;
      _goal = p.goal;
      _age = FormOptions.snapInt(FormOptions.ages(), p.age);
      _heightCm = FormOptions.snapInt(
        FormOptions.heightsCm(),
        p.heightCm.round(),
      );
      _weightKg = FormOptions.snapDouble(FormOptions.weightsKg(), p.weightKg);
      final fallbackTarget =
          (p.weightKg - 5).clamp(30.0, p.weightKg - 0.5).toDouble();
      final targetOpts = FormOptions.targetWeightsKg(_weightKg);
      _targetWeightKg = FormOptions.snapDouble(
        targetOpts.isEmpty ? FormOptions.weightsKg(min: 30, max: 40) : targetOpts,
        p.targetWeightKg ?? fallbackTarget,
      );
      _weeklyLossKg = FormOptions.snapDouble(
        FormOptions.weeklyLossKg,
        p.weeklyLossKg ?? CalorieCalculator.defaultWeeklyLoss,
      );
      final water = ref.read(waterRepositoryProvider).getGoalMlOrNull();
      _waterGoalMl = water == null
          ? null
          : FormOptions.snapInt(FormOptions.waterGoalMl, water);
      _ready = true;
    }
  }

  void _edit(VoidCallback mutate) {
    setState(() {
      mutate();
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = context.l10n;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.unsavedChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text(l10n.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (action == 'discard') return true;
    if (action == 'save') {
      final ok = await _persist();
      return ok;
    }
    return false;
  }

  Future<bool> _persist() async {
    setState(() => _saving = true);
    try {
      final targetOptions = FormOptions.cutTargetOptions(_weightKg);
      var target = FormOptions.snapDouble(targetOptions, _targetWeightKg);
      if (target >= _weightKg && targetOptions.isNotEmpty) {
        target = targetOptions.last;
      }

      await ref.read(profileProvider.notifier).save(
            sex: _sex,
            age: _age,
            heightCm: _heightCm.toDouble(),
            weightKg: _weightKg,
            activity: _activity,
            goal: _goal,
            targetWeightKg: _goal == FitnessGoal.cut ? target : null,
            weeklyLossKg: _goal == FitnessGoal.cut ? _weeklyLossKg : null,
          );
      if (_waterGoalMl == null) {
        await ref.read(waterGoalProvider.notifier).clearGoal();
      } else {
        await ref.read(waterGoalProvider.notifier).setGoal(_waterGoalMl!);
      }
      if (!mounted) return false;
      setState(() => _dirty = false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveFailed('$e'))),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAndPop() async {
    final ok = await _persist();
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (!_ready || profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = context.l10n;
    final weeksHint = FormOptions.estimatedCutWeeksLabel(
      l10n: l10n,
      goal: _goal,
      weightKg: _weightKg,
      targetWeightKg: _targetWeightKg,
      weeklyLossKg: _weeklyLossKg,
    );
    final targetOptions = FormOptions.cutTargetOptions(_weightKg);
    final targetValue = FormOptions.snapDouble(targetOptions, _targetWeightKg);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allow = await _confirmDiscard();
        if (!allow || !context.mounted) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myProfile),
          actions: [
            TextButton(
              onPressed: _saving || !_dirty ? null : _saveAndPop,
              child: Text(_saving ? l10n.saving : l10n.save),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.formPage),
          children: [
            Text(l10n.sex, style: Theme.of(context).textTheme.fieldLabel),
            const SizedBox(height: 8),
            SegmentedButton<Sex>(
              segments: [
                ButtonSegment(value: Sex.male, label: Text(l10n.male)),
                ButtonSegment(value: Sex.female, label: Text(l10n.female)),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => _edit(() => _sex = s.first),
            ),
            const SizedBox(height: AppSpacing.section),
            AppDropdown<int>(
              label: l10n.age,
              value: FormOptions.snapInt(FormOptions.ages(), _age),
              items: FormOptions.ages(),
              suffixText: l10n.ageUnit,
              onChanged: (v) => _edit(() => _age = v),
            ),
            const SizedBox(height: AppSpacing.field),
            AppDropdown<int>(
              label: l10n.height,
              value: FormOptions.snapInt(FormOptions.heightsCm(), _heightCm),
              items: FormOptions.heightsCm(),
              suffixText: 'cm',
              onChanged: (v) => _edit(() => _heightCm = v),
            ),
            const SizedBox(height: AppSpacing.field),
            AppDropdown<double>(
              label: l10n.currentWeight,
              value: FormOptions.snapDouble(FormOptions.weightsKg(), _weightKg),
              items: FormOptions.weightsKg(),
              suffixText: 'kg',
              itemLabel: formatKg,
              onChanged: (v) => _edit(() {
                _weightKg = v;
                final opts = FormOptions.targetWeightsKg(v);
                if (opts.isNotEmpty && _targetWeightKg >= v) {
                  _targetWeightKg = opts.last;
                }
              }),
            ),
            const SizedBox(height: AppSpacing.section),
            AppDropdown<ActivityLevel>(
              label: l10n.activityLevel,
              value: _activity,
              items: ActivityLevel.values,
              itemLabel: (e) => e.label(l10n),
              onChanged: (v) => _edit(() => _activity = v),
            ),
            const SizedBox(height: AppSpacing.section),
            AppDropdown<FitnessGoal>(
              label: l10n.goal,
              value: _goal,
              items: FitnessGoal.values,
              itemLabel: (e) => e.label(l10n),
              onChanged: (v) => _edit(() => _goal = v),
            ),
            if (_goal == FitnessGoal.cut) ...[
              const SizedBox(height: AppSpacing.section),
              AppDropdown<double>(
                label: l10n.targetWeight,
                value: targetValue,
                items: targetOptions,
                suffixText: 'kg',
                itemLabel: formatKg,
                onChanged: (v) => _edit(() => _targetWeightKg = v),
              ),
              const SizedBox(height: AppSpacing.field),
              AppDropdown<double>(
                label: l10n.weeklyLossTarget,
                value: FormOptions.snapDouble(
                  FormOptions.weeklyLossKg,
                  _weeklyLossKg,
                ),
                items: FormOptions.weeklyLossKg,
                suffixText: 'kg',
                helperText: weeksHint ?? l10n.weeklyLossHint,
                itemLabel: (v) => v.toStringAsFixed(1),
                onChanged: (v) => _edit(() => _weeklyLossKg = v),
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            AppOptionalDropdown<int>(
              label: l10n.dailyWaterGoal,
              value: _waterGoalMl,
              items: FormOptions.waterGoalMl,
              suffixText: 'ml',
              helperText: l10n.waterDefaultHint(kDefaultWaterGoalMl),
              onChanged: (v) => _edit(() => _waterGoalMl = v),
            ),
            const SizedBox(height: AppSpacing.section),
            FilledButton(
              onPressed: _saving || !_dirty ? null : _saveAndPop,
              child: Text(_saving ? l10n.saving : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
