import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.sedentary;
  FitnessGoal _goal = FitnessGoal.cut;
  int _age = 23;
  int _heightCm = 183;
  double _weightKg = 70;
  double _targetWeightKg = 65;
  double _weeklyLossKg = CalorieCalculator.defaultWeeklyLoss;
  bool _saving = false;

  Future<void> _showResultAndSave() async {
    setState(() => _saving = true);
    try {
      final targetOptions = FormOptions.cutTargetOptions(_weightKg);
      var target = FormOptions.snapDouble(targetOptions, _targetWeightKg);
      if (target >= _weightKg && targetOptions.isNotEmpty) {
        target = targetOptions.last;
      }

      final profile = await ref.read(profileProvider.notifier).save(
            sex: _sex,
            age: _age,
            heightCm: _heightCm.toDouble(),
            weightKg: _weightKg,
            activity: _activity,
            goal: _goal,
            targetWeightKg: _goal == FitnessGoal.cut ? target : null,
            weeklyLossKg:
                _goal == FitnessGoal.cut ? _weeklyLossKg : null,
          );
      if (!mounted) return;

      final l10n = context.l10n;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.quotaReadyTitle),
          content: Text(
            l10n.quotaReadyBody(
              '${profile.targets.calories}',
              profile.targets.proteinG.toStringAsFixed(0),
              profile.targets.carbG.toStringAsFixed(0),
              profile.targets.fatG.toStringAsFixed(0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.startUsing),
            ),
          ],
        ),
      );
      if (mounted) context.go('/today');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createProfileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.formPage),
          children: [
            Text(
              l10n.createProfileHint,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(l10n.sex, style: Theme.of(context).textTheme.fieldLabel),
            const SizedBox(height: 8),
            SegmentedButton<Sex>(
              segments: [
                ButtonSegment(value: Sex.male, label: Text(l10n.male)),
                ButtonSegment(value: Sex.female, label: Text(l10n.female)),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: AppSpacing.section),
            AppDropdown<int>(
              label: l10n.age,
              value: FormOptions.snapInt(FormOptions.ages(), _age),
              items: FormOptions.ages(),
              suffixText: l10n.ageUnit,
              onChanged: (v) => setState(() => _age = v),
            ),
            const SizedBox(height: AppSpacing.field),
            AppDropdown<int>(
              label: l10n.height,
              value: FormOptions.snapInt(FormOptions.heightsCm(), _heightCm),
              items: FormOptions.heightsCm(),
              suffixText: 'cm',
              onChanged: (v) => setState(() => _heightCm = v),
            ),
            const SizedBox(height: AppSpacing.field),
            AppDropdown<double>(
              label: l10n.currentWeight,
              value: FormOptions.snapDouble(FormOptions.weightsKg(), _weightKg),
              items: FormOptions.weightsKg(),
              suffixText: 'kg',
              itemLabel: formatKg,
              onChanged: (v) => setState(() {
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
              onChanged: (v) => setState(() => _activity = v),
            ),
            const SizedBox(height: AppSpacing.section),
            AppDropdown<FitnessGoal>(
              label: l10n.goal,
              value: _goal,
              items: FitnessGoal.values,
              itemLabel: (e) => e.label(l10n),
              onChanged: (v) => setState(() => _goal = v),
            ),
            if (_goal == FitnessGoal.cut) ...[
              const SizedBox(height: AppSpacing.section),
              AppDropdown<double>(
                label: l10n.targetWeight,
                value: targetValue,
                items: targetOptions,
                suffixText: 'kg',
                itemLabel: formatKg,
                onChanged: (v) => setState(() => _targetWeightKg = v),
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
                onChanged: (v) => setState(() => _weeklyLossKg = v),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _showResultAndSave,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_saving ? l10n.calculating : l10n.calculateAndStart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
