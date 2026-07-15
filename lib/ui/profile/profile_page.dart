import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_breakdown.dart';
import '../widgets/form_options.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
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
  String? _statusHint;
  int _saveToken = 0;
  Timer? _hintTimer;

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

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _showSavedHint() {
    _hintTimer?.cancel();
    setState(() => _statusHint = '已自动保存');
    _hintTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _statusHint = null);
    });
  }

  Future<void> _persist() async {
    final token = ++_saveToken;
    setState(() {
      _saving = true;
      _statusHint = '保存中…';
    });
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
            weeklyLossKg:
                _goal == FitnessGoal.cut ? _weeklyLossKg : null,
          );
      if (!mounted || token != _saveToken) return;
      _showSavedHint();
    } catch (e) {
      if (!mounted || token != _saveToken) return;
      setState(() => _statusHint = '保存失败');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      if (mounted && token == _saveToken) {
        setState(() => _saving = false);
      }
    }
  }

  void _update(VoidCallback mutate) {
    setState(mutate);
    unawaited(_persist());
  }

  Future<void> _exportBackup() async {
    try {
      final file = await ref.read(backupRepositoryProvider).exportToFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'FitnessPlan 备份',
          text: '健身饮食本地备份',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入备份'),
        content: const Text(
          '导入会覆盖当前的饮食、体重与收藏数据，并尝试恢复档案。确定继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = file?.path;
    if (path == null) return;

    try {
      final raw = await File(path).readAsString();
      await ref.read(backupRepositoryProvider).importFromJson(raw);
      ref.read(profileProvider.notifier).reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份已导入')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    }
  }

  Future<void> _clearData() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text('可只清空饮食/体重/收藏，或连同身体档案一起清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'logs'),
            child: const Text('仅记录'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: const Text('全部清空'),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    try {
      await ref.read(backupRepositoryProvider).clearUserData(
            includeProfile: choice == 'all',
          );
      if (choice == 'all') {
        await ref.read(profileProvider.notifier).clear();
      } else {
        ref.read(profileProvider.notifier).reload();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清空')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清空失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (!_ready || profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final weeksHint = FormOptions.estimatedCutWeeksLabel(
      goal: _goal,
      weightKg: _weightKg,
      targetWeightKg: _targetWeightKg,
      weeklyLossKg: _weeklyLossKg,
    );
    final targetOptions = FormOptions.cutTargetOptions(_weightKg);
    final targetValue = FormOptions.snapDouble(targetOptions, _targetWeightKg);
    final hint = _saving ? '保存中…' : _statusHint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的档案'),
        actions: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  hint,
                  style: Theme.of(context).textTheme.meta,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前每日配额',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${profile.targets.calories}',
                        style: Theme.of(context).textTheme.statValue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'kcal',
                        style: Theme.of(context).textTheme.statUnit?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'P ${profile.targets.proteinG.toStringAsFixed(0)} · '
                    'C ${profile.targets.carbG.toStringAsFixed(0)} · '
                    'F ${profile.targets.fatG.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.meta,
                  ),
                  if (profile.goal == FitnessGoal.cut &&
                      profile.dailyDeficit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '缺口 ${profile.dailyDeficit!.round()} kcal'
                      '${profile.weeklyLossKg != null ? ' · ${profile.weeklyLossKg!.toStringAsFixed(1)} kg/周' : ''}'
                      '${profile.goalWeeks != null ? ' · 约 ${profile.goalWeeks} 周' : ''}',
                      style: Theme.of(context).textTheme.meta,
                    ),
                  ],
                  if (profile.calorieAdjustment > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '平台期 −${profile.calorieAdjustment} kcal',
                      style: Theme.of(context).textTheme.meta,
                    ),
                  ],
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      '计算方法',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    children: [CalorieBreakdown(plan: plan, compact: true)],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Text('性别', style: Theme.of(context).textTheme.fieldLabel),
          const SizedBox(height: 8),
          SegmentedButton<Sex>(
            segments: const [
              ButtonSegment(value: Sex.male, label: Text('男')),
              ButtonSegment(value: Sex.female, label: Text('女')),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => _update(() => _sex = s.first),
          ),
          const SizedBox(height: AppSpacing.section),
          AppDropdown<int>(
            label: '年龄',
            value: FormOptions.snapInt(FormOptions.ages(), _age),
            items: FormOptions.ages(),
            suffixText: '岁',
            onChanged: (v) => _update(() => _age = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<int>(
            label: '身高',
            value: FormOptions.snapInt(FormOptions.heightsCm(), _heightCm),
            items: FormOptions.heightsCm(),
            suffixText: 'cm',
            onChanged: (v) => _update(() => _heightCm = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: '当前体重',
            value: FormOptions.snapDouble(FormOptions.weightsKg(), _weightKg),
            items: FormOptions.weightsKg(),
            suffixText: 'kg',
            itemLabel: formatKg,
            onChanged: (v) => _update(() {
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
            onChanged: (v) => _update(() => _activity = v),
          ),
          const SizedBox(height: AppSpacing.section),
          AppDropdown<FitnessGoal>(
            label: '目标',
            value: _goal,
            items: FitnessGoal.values,
            itemLabel: (e) => e.label,
            onChanged: (v) => _update(() => _goal = v),
          ),
          if (_goal == FitnessGoal.cut) ...[
            const SizedBox(height: AppSpacing.section),
            AppDropdown<double>(
              label: '目标体重',
              value: targetValue,
              items: targetOptions,
              suffixText: 'kg',
              itemLabel: formatKg,
              onChanged: (v) => _update(() => _targetWeightKg = v),
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
              onChanged: (v) => _update(() => _weeklyLossKg = v),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          Text('数据备份', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '纯本地存储。建议定期导出 JSON 备份，换机时再导入。',
            style: Theme.of(context).textTheme.meta,
          ),
          const SizedBox(height: AppSpacing.field),
          OutlinedButton.icon(
            onPressed: _exportBackup,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('导出备份'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _importBackup,
            icon: const Icon(Icons.download_outlined),
            label: const Text('导入备份'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _clearData,
            icon: const Icon(Icons.delete_outline),
            label: const Text('清空数据'),
          ),
        ],
      ),
    );
  }
}
