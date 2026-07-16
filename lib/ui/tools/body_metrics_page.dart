import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/body_metrics.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class BodyMetricsPage extends ConsumerStatefulWidget {
  const BodyMetricsPage({super.key});

  @override
  ConsumerState<BodyMetricsPage> createState() => _BodyMetricsPageState();
}

class _BodyMetricsPageState extends ConsumerState<BodyMetricsPage> {
  late Sex _sex;
  late double _heightCm;
  late double _weightKg;
  late double _waistCm;

  static final _waists = FormOptions.circumferencesCm(min: 50, max: 150);

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider)!;
    _sex = p.sex;
    _heightCm = FormOptions.snapDouble(
      FormOptions.heightsCm().map((e) => e.toDouble()).toList(),
      p.heightCm,
    );
    _weightKg = FormOptions.snapDouble(FormOptions.weightsKg(), p.weightKg);
    _waistCm = FormOptions.snapDouble(_waists, _sex == Sex.male ? 85 : 70);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heights =
        FormOptions.heightsCm().map((e) => e.toDouble()).toList();
    final bmi = BodyMetrics.bmi(weightKg: _weightKg, heightCm: _heightCm);
    final category = BodyMetrics.bmiCategory(bmi);
    final ideal = BodyMetrics.idealWeightDevine(
      sex: _sex,
      heightCm: _heightCm,
    );
    final whtr = BodyMetrics.waistToHeightRatio(
      waistCm: _waistCm,
      heightCm: _heightCm,
    );
    final whtrHigh = whtr > BodyMetrics.whtrReference;

    return Scaffold(
      appBar: AppBar(title: const Text('身体指标')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            '仅本地估算，不会改写档案。腰围仅用于腰高比。',
            style: theme.textTheme.meta,
          ),
          const SizedBox(height: AppSpacing.section),
          AppDropdown<Sex>(
            label: '性别',
            value: _sex,
            items: Sex.values,
            itemLabel: (s) => s == Sex.male ? '男' : '女',
            onChanged: (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: '身高',
            value: _heightCm,
            items: heights,
            suffixText: 'cm',
            itemLabel: (v) => v.round().toString(),
            onChanged: (v) => setState(() => _heightCm = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: '体重',
            value: _weightKg,
            items: FormOptions.weightsKg(),
            suffixText: 'kg',
            itemLabel: (v) => v.toStringAsFixed(1),
            onChanged: (v) => setState(() => _weightKg = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: '腰围',
            value: _waistCm,
            items: _waists,
            suffixText: 'cm',
            onChanged: (v) => setState(() => _waistCm = v),
          ),
          const SizedBox(height: AppSpacing.section),
          _ResultCard(
            title: 'BMI',
            value: bmi.toStringAsFixed(1),
            unit: category.label,
          ),
          const SizedBox(height: AppSpacing.field),
          _ResultCard(
            title: '理想体重（Devine）',
            value: ideal.toStringAsFixed(1),
            unit: 'kg',
          ),
          const SizedBox(height: AppSpacing.field),
          _ResultCard(
            title: '腰高比',
            value: whtr.toStringAsFixed(2),
            unit: whtrHigh
                ? '高于参考线 ${BodyMetrics.whtrReference}'
                : '参考线 ${BodyMetrics.whtrReference}',
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: theme.textTheme.statValue),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(unit, style: theme.textTheme.statUnit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
