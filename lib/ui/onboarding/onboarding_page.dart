import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../providers/app_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.sedentary;
  FitnessGoal _goal = FitnessGoal.cut;
  final _ageCtrl = TextEditingController(text: '28');
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');
  bool _saving = false;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _showResultAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final profile = await ref.read(profileProvider.notifier).save(
            sex: _sex,
            age: int.parse(_ageCtrl.text),
            heightCm: double.parse(_heightCtrl.text),
            weightKg: double.parse(_weightCtrl.text),
            activity: _activity,
            goal: _goal,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('每日配额已算出'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('热量：${profile.targets.calories} kcal'),
              Text('蛋白：${profile.targets.proteinG.toStringAsFixed(0)} g'),
              Text('碳水：${profile.targets.carbG.toStringAsFixed(0)} g'),
              Text('脂肪：${profile.targets.fatG.toStringAsFixed(0)} g'),
            ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('建立身体档案')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '根据你的身体数据计算每日热量与三大营养素',
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
              TextFormField(
                controller: _ageCtrl,
                decoration: const InputDecoration(
                  labelText: '年龄',
                  border: OutlineInputBorder(),
                  suffixText: '岁',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 10 || n > 100) return '请输入有效年龄';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightCtrl,
                decoration: const InputDecoration(
                  labelText: '身高',
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 100 || n > 250) return '请输入有效身高';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightCtrl,
                decoration: const InputDecoration(
                  labelText: '体重',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 30 || n > 300) return '请输入有效体重';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityLevel>(
                initialValue: _activity,
                decoration: const InputDecoration(
                  labelText: '活动量',
                  border: OutlineInputBorder(),
                ),
                items: ActivityLevel.values
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _activity = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FitnessGoal>(
                initialValue: _goal,
                decoration: const InputDecoration(
                  labelText: '目标',
                  border: OutlineInputBorder(),
                ),
                items: FitnessGoal.values
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _goal = v!),
              ),
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
      ),
    );
  }
}
