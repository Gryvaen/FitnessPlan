import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
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

  String? _estimatedWeeksLabel() {
    if (_goal != FitnessGoal.cut) return null;
    if (_targetWeightKg >= _weightKg || _weeklyLossKg <= 0) return null;
    final rate = CalorieCalculator.clampWeeklyLoss(_weeklyLossKg).$1;
    final weeks = ((_weightKg - _targetWeightKg) / rate).ceil();
    return '预计约 $weeks 周（按 ${rate.toStringAsFixed(1)} kg/周）';
  }

  List<double> get _targetOptions {
    final opts = FormOptions.targetWeightsKg(_weightKg);
    if (opts.isEmpty) return FormOptions.weightsKg(min: 30, max: 40);
    return opts;
  }

  Future<void> _showResultAndSave() async {
    setState(() => _saving = true);
    try {
      final targetOptions = _targetOptions;
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

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('每日配额已算出'),
          content: Text(
            '${profile.targets.calories} kcal\n'
            '蛋白 ${profile.targets.proteinG.toStringAsFixed(0)} g · '
            '碳水 ${profile.targets.carbG.toStringAsFixed(0)} g · '
            '脂肪 ${profile.targets.fatG.toStringAsFixed(0)} g\n\n'
            '详细计算过程可在「我的」中查看。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('开始使用'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/today');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeksHint = _estimatedWeeksLabel();
    final targetOptions = _targetOptions;
    final targetValue = FormOptions.snapDouble(targetOptions, _targetWeightKg);

    return Scaffold(
      appBar: AppBar(title: const Text('建立身体档案')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '按身体数据建立减脂能量模型：BMR → TDEE → 周降重 → 三大营养素',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text('性别', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.male, label: Text('男')),
                ButtonSegment(value: Sex.female, label: Text('女')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: '年龄',
              value: FormOptions.snapInt(FormOptions.ages(), _age),
              items: FormOptions.ages(),
              suffixText: '岁',
              onChanged: (v) => setState(() => _age = v),
            ),
            const SizedBox(height: 12),
            AppDropdown<int>(
              label: '身高',
              value: FormOptions.snapInt(FormOptions.heightsCm(), _heightCm),
              items: FormOptions.heightsCm(),
              suffixText: 'cm',
              onChanged: (v) => setState(() => _heightCm = v),
            ),
            const SizedBox(height: 12),
            AppDropdown<double>(
              label: '当前体重',
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
            const SizedBox(height: 16),
            AppDropdown<ActivityLevel>(
              label: '日常活动等级',
              value: _activity,
              items: ActivityLevel.values,
              itemLabel: (e) => e.label,
              onChanged: (v) => setState(() => _activity = v),
            ),
            const SizedBox(height: 16),
            AppDropdown<FitnessGoal>(
              label: '目标',
              value: _goal,
              items: FitnessGoal.values,
              itemLabel: (e) => e.label,
              onChanged: (v) => setState(() => _goal = v),
            ),
            if (_goal == FitnessGoal.cut) ...[
              const SizedBox(height: 16),
              AppDropdown<double>(
                label: '目标体重',
                value: targetValue,
                items: targetOptions,
                suffixText: 'kg',
                itemLabel: formatKg,
                onChanged: (v) => setState(() => _targetWeightKg = v),
              ),
              const SizedBox(height: 12),
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
                onChanged: (v) => setState(() => _weeklyLossKg = v),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _showResultAndSave,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_saving ? '计算中…' : '计算并开始'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
