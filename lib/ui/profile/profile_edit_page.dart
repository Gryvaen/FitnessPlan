import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
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

  /// Preserved as-is from the loaded profile — no longer user-editable here
  /// (see the removed 目标体重 field), but kept so an existing value isn't
  /// silently wiped on save; it's purely informational (progress display),
  /// never affects the calculated calorie target.
  double? _targetWeightKg;
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
      _targetWeightKg = p.targetWeightKg;
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
      // 目标体重 is no longer editable here — carry the existing value
      // through as-is (dropping it if it's stopped making sense against a
      // new current weight), never invent or reset one.
      final preservedTarget = _targetWeightKg;
      final target =
          (_goal == FitnessGoal.cut &&
              preservedTarget != null &&
              preservedTarget < _weightKg)
          ? preservedTarget
          : null;

      await ref
          .read(profileProvider.notifier)
          .save(
            sex: _sex,
            age: _age,
            heightCm: _heightCm.toDouble(),
            weightKg: _weightKg,
            activity: _activity,
            goal: _goal,
            targetWeightKg: target,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed('$e'))));
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

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allow = await _confirmDiscard();
        if (!allow || !context.mounted) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.myProfile)),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.formPage,
            AppSpacing.compact,
            AppSpacing.formPage,
            listBottomInset(context, hasFab: false),
          ),
          children: [
            SportSurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    title: l10n.profileSectionBasics,
                    hint: l10n.profileSectionBasicsHint,
                  ),
                  AppDropdown<Sex>(
                    label: l10n.sex,
                    value: _sex,
                    items: Sex.values,
                    itemLabel: (s) => s.label(l10n),
                    helperText: l10n.profileFieldSexHint,
                    onChanged: (v) => _edit(() => _sex = v),
                  ),
                  const SizedBox(height: AppSpacing.field),
                  AppDropdown<int>(
                    label: l10n.age,
                    value: FormOptions.snapInt(FormOptions.ages(), _age),
                    items: FormOptions.ages(),
                    suffixText: l10n.ageUnit,
                    helperText: l10n.profileFieldAgeHint,
                    onChanged: (v) => _edit(() => _age = v),
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
                    helperText: l10n.profileFieldHeightHint,
                    onChanged: (v) => _edit(() => _heightCm = v),
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
                    helperText: l10n.profileFieldWeightHint,
                    onChanged: (v) => _edit(() => _weightKg = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SportSurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    title: l10n.profileSectionGoal,
                    hint: l10n.profileSectionGoalHint,
                  ),
                  AppDropdown<ActivityLevel>(
                    label: l10n.activityLevel,
                    value: _activity,
                    items: ActivityLevel.values,
                    itemLabel: (e) => e.label(l10n),
                    helperText: l10n.profileFieldActivityHint,
                    onChanged: (v) => _edit(() => _activity = v),
                  ),
                  const SizedBox(height: AppSpacing.field),
                  AppDropdown<FitnessGoal>(
                    label: l10n.goal,
                    value: _goal,
                    items: FitnessGoal.values,
                    itemLabel: (e) => e.label(l10n),
                    helperText: l10n.profileFieldGoalHint,
                    onChanged: (v) => _edit(() => _goal = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SportSurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(title: l10n.profileSectionOther),
                  AppOptionalDropdown<int>(
                    label: l10n.dailyWaterGoal,
                    value: _waterGoalMl,
                    items: FormOptions.waterGoalMl,
                    suffixText: 'ml',
                    helperText: l10n.profileFieldWaterHint,
                    onChanged: (v) => _edit(() => _waterGoalMl = v),
                  ),
                ],
              ),
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

/// Section heading + an optional one-line explanation of what the fields
/// below feed into.
class _Section extends StatelessWidget {
  const _Section({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.field),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
