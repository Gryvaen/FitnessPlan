import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
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
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('身体档案有未保存的修改，要如何处理？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('丢弃'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('保存'),
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
      if (!mounted) return false;
      setState(() => _dirty = false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
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

    final weeksHint = FormOptions.estimatedCutWeeksLabel(
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
          title: const Text('我的档案'),
          actions: [
            TextButton(
              onPressed: _saving || !_dirty ? null : _saveAndPop,
              child: Text(_saving ? '保存中…' : '保存'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.formPage),
          children: [
            Text('性别', style: Theme.of(context).textTheme.fieldLabel),
            const SizedBox(height: 8),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.male, label: Text('男')),
                ButtonSegment(value: Sex.female, label: Text('女')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => _edit(() => _sex = s.first),
            ),
            const SizedBox(height: AppSpacing.section),
            AppDropdown<int>(
              label: '年龄',
              value: FormOptions.snapInt(FormOptions.ages(), _age),
              items: FormOptions.ages(),
              suffixText: '岁',
              onChanged: (v) => _edit(() => _age = v),
            ),
            const SizedBox(height: AppSpacing.field),
            AppDropdown<int>(
              label: '身高',
              value: FormOptions.snapInt(FormOptions.heightsCm(), _heightCm),
              items: FormOptions.heightsCm(),
              suffixText: 'cm',
              onChanged: (v) => _edit(() => _heightCm = v),
            ),
            const SizedBox(height: AppSpacing.field),
            AppDropdown<double>(
              label: '当前体重',
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
              label: '日常活动等级',
              value: _activity,
              items: ActivityLevel.values,
              itemLabel: (e) => e.label,
              onChanged: (v) => _edit(() => _activity = v),
            ),
            const SizedBox(height: AppSpacing.section),
            AppDropdown<FitnessGoal>(
              label: '目标',
              value: _goal,
              items: FitnessGoal.values,
              itemLabel: (e) => e.label,
              onChanged: (v) => _edit(() => _goal = v),
            ),
            if (_goal == FitnessGoal.cut) ...[
              const SizedBox(height: AppSpacing.section),
              AppDropdown<double>(
                label: '目标体重',
                value: targetValue,
                items: targetOptions,
                suffixText: 'kg',
                itemLabel: formatKg,
                onChanged: (v) => _edit(() => _targetWeightKg = v),
              ),
              const SizedBox(height: AppSpacing.field),
              AppDropdown<double>(
                label: '每周目标降重',
                value: FormOptions.snapDouble(
                  FormOptions.weeklyLossKg,
                  _weeklyLossKg,
                ),
                items: FormOptions.weeklyLossKg,
                suffixText: 'kg',
                helperText: weeksHint ?? '推荐 0.3–0.8 kg/周',
                itemLabel: (v) => v.toStringAsFixed(1),
                onChanged: (v) => _edit(() => _weeklyLossKg = v),
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            FilledButton(
              onPressed: _saving || !_dirty ? null : _saveAndPop,
              child: Text(_saving ? '保存中…' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}
