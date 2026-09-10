import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
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

  final _pager = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pager.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  String _goalDesc(FitnessGoal g, AppLocalizations l10n) => switch (g) {
    FitnessGoal.cut => l10n.goalCutDesc,
    FitnessGoal.maintain => l10n.goalMaintainDesc,
    FitnessGoal.bulk => l10n.goalBulkDesc,
  };

  Future<void> _showResultAndSave() async {
    setState(() => _saving = true);
    try {
      final targetOptions = FormOptions.cutTargetOptions(_weightKg);
      var target = FormOptions.snapDouble(targetOptions, _targetWeightKg);
      if (target >= _weightKg && targetOptions.isNotEmpty) {
        target = targetOptions.last;
      }

      final profile = await ref
          .read(profileProvider.notifier)
          .save(
            sex: _sex,
            age: _age,
            heightCm: _heightCm.toDouble(),
            weightKg: _weightKg,
            activity: _activity,
            goal: _goal,
            targetWeightKg: _goal == FitnessGoal.cut ? target : null,
            weeklyLossKg: _goal == FitnessGoal.cut ? _weeklyLossKg : null,
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
    final weeksHint = FormOptions.estimatedCutWeeksLabel(
      l10n: l10n,
      goal: _goal,
      weightKg: _weightKg,
      targetWeightKg: _targetWeightKg,
      weeklyLossKg: _weeklyLossKg,
    );
    final targetOptions = FormOptions.cutTargetOptions(_weightKg);
    final targetValue = FormOptions.snapDouble(targetOptions, _targetWeightKg);

    final theme = Theme.of(context);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _goToStep(_step - 1);
      },
      child: Scaffold(
        appBar: _step == 0
            ? null
            : AppBar(
                leading: BackButton(onPressed: () => _goToStep(_step - 1)),
                title: Text(l10n.onboardingStep(_step, 2)),
                centerTitle: false,
              ),
        body: SafeArea(
          child: PageView(
            controller: _pager,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // --------------------------------------------------- 1. welcome
              ListView(
                padding: const EdgeInsets.all(AppSpacing.formPage),
                children: [
                  const SizedBox(height: 24),
                  Text(l10n.appTitle, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(l10n.appTagline, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createProfileHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _Feature(
                    icon: Icons.restaurant_outlined,
                    title: l10n.onboardingFeature1Title,
                    subtitle: l10n.onboardingFeature1Sub,
                  ),
                  _Feature(
                    icon: Icons.fitness_center_outlined,
                    title: l10n.onboardingFeature2Title,
                    subtitle: l10n.onboardingFeature2Sub,
                  ),
                  _Feature(
                    icon: Icons.insights_outlined,
                    title: l10n.onboardingFeature3Title,
                    subtitle: l10n.onboardingFeature3Sub,
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: () => _goToStep(1),
                    child: Text(l10n.onboardingWelcomeCta),
                  ),
                ],
              ),
              // ----------------------------------------------- 2. basic info
              ListView(
                padding: const EdgeInsets.all(AppSpacing.formPage),
                children: [
                  Text(
                    l10n.onboardingBasicTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Text(l10n.sex, style: theme.textTheme.fieldLabel),
                  const SizedBox(height: 4),
                  SportTabs<Sex>(
                    items: {Sex.male: l10n.male, Sex.female: l10n.female},
                    selected: _sex,
                    onSelected: (v) => setState(() => _sex = v),
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
                    value: FormOptions.snapInt(
                      FormOptions.heightsCm(),
                      _heightCm,
                    ),
                    items: FormOptions.heightsCm(),
                    suffixText: 'cm',
                    onChanged: (v) => setState(() => _heightCm = v),
                  ),
                  const SizedBox(height: AppSpacing.field),
                  AppDropdown<double>(
                    label: l10n.currentWeight,
                    value: FormOptions.snapDouble(
                      FormOptions.weightsKg(),
                      _weightKg,
                    ),
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
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.card),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.onboardingDataUseNote,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  FilledButton(
                    onPressed: () => _goToStep(2),
                    child: Text(l10n.onboardingNext),
                  ),
                ],
              ),
              // ----------------------------------------------------- 3. goal
              ListView(
                padding: const EdgeInsets.all(AppSpacing.formPage),
                children: [
                  Text(
                    l10n.onboardingGoalTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  for (final g in FitnessGoal.values)
                    _GoalOption(
                      label: g.label(l10n),
                      description: _goalDesc(g, l10n),
                      selected: _goal == g,
                      onTap: () => setState(() => _goal = g),
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
                    child: Text(
                      _saving ? l10n.calculating : l10n.onboardingFinish,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.card),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = AppThemeVisuals.of(context);
    return Material(
      color: selected ? v.accentSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(color: selected ? v.accent : v.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? v.accent : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.card),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
