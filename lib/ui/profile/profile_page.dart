import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../providers/app_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late Sex _sex;
  late ActivityLevel _activity;
  late FitnessGoal _goal;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    if (p != null) {
      _sex = p.sex;
      _activity = p.activity;
      _goal = p.goal;
      _ageCtrl = TextEditingController(text: '${p.age}');
      _heightCtrl = TextEditingController(text: p.heightCm.toStringAsFixed(0));
      _weightCtrl = TextEditingController(text: p.weightKg.toStringAsFixed(1));
      _ready = true;
    }
  }

  @override
  void dispose() {
    if (_ready) {
      _ageCtrl.dispose();
      _heightCtrl.dispose();
      _weightCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已更新：${profile.targets.calories} kcal · '
            '蛋白 ${profile.targets.proteinG.toStringAsFixed(0)}g',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (!_ready || profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('我的档案')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前每日配额',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('${profile.targets.calories} kcal'),
                    Text(
                      '蛋白 ${profile.targets.proteinG.toStringAsFixed(0)}g · '
                      '碳水 ${profile.targets.carbG.toStringAsFixed(0)}g · '
                      '脂肪 ${profile.targets.fatG.toStringAsFixed(0)}g',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
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
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => setState(() => _goal = v!),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_saving ? '保存中…' : '保存并重算配额'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
