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
  late double _bodyFatPct;

  static final _waists = FormOptions.circumferencesCm(min: 50, max: 150);
  static final _bodyFats = FormOptions.bodyFatPct();

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
    _bodyFatPct = FormOptions.snapDouble(
      _bodyFats,
      _defaultBodyFatPct(),
    );
  }

  double _defaultBodyFatPct() {
    final logs = ref.read(weightLogsProvider).value;
    if (logs != null) {
      for (var i = logs.length - 1; i >= 0; i--) {
        final pct = logs[i].bodyFatPct;
        if (pct != null && pct > 0 && pct < 100) return pct;
      }
    }
    return _sex == Sex.male ? 15.0 : 25.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heights =
        FormOptions.heightsCm().map((e) => e.toDouble()).toList();
    final heightM = _heightCm / 100;
    final heightIn = _heightCm / 2.54;
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

    final ffm = BodyMetrics.fatFreeMassKg(
      weightKg: _weightKg,
      bodyFatPct: _bodyFatPct,
    );
    final ffmi = BodyMetrics.ffmi(
      weightKg: _weightKg,
      heightCm: _heightCm,
      bodyFatPct: _bodyFatPct,
    );
    final normFfmi = BodyMetrics.normalizedFfmi(
      weightKg: _weightKg,
      heightCm: _heightCm,
      bodyFatPct: _bodyFatPct,
    );

    final baseIdeal = _sex == Sex.male ? 50.0 : 45.5;
    final sexLabel = _sex == Sex.male ? '男' : '女';
    final inchesOver5ft = (heightIn - 60).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('身体指标')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            '仅本地估算，不会改写档案。点击每项可展开查看计算公式。',
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
            label: '体脂',
            value: _bodyFatPct,
            items: _bodyFats,
            suffixText: '%',
            itemLabel: (v) => v.toStringAsFixed(1),
            onChanged: (v) => setState(() => _bodyFatPct = v),
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
            formula: 'BMI = 体重(kg) ÷ 身高(m)²\n'
                '= ${_weightKg.toStringAsFixed(1)} ÷ '
                '${heightM.toStringAsFixed(2)}²\n'
                '= ${bmi.toStringAsFixed(1)}\n\n'
                '分级（WHO）：\n'
                '偏瘦 < 18.5 · 正常 18.5–24.9\n'
                '超重 25–29.9 · 肥胖 ≥ 30',
          ),
          const SizedBox(height: AppSpacing.field),
          _ResultCard(
            title: '理想体重（Devine）',
            value: ideal.toStringAsFixed(1),
            unit: 'kg',
            formula: 'Devine 公式（$sexLabel）\n'
                '身高 = ${_heightCm.round()} cm '
                '≈ ${heightIn.toStringAsFixed(1)} in\n'
                '理想体重 = $baseIdeal + 2.3 × (身高英寸 − 60)\n'
                '= $baseIdeal + 2.3 × ${inchesOver5ft.toStringAsFixed(1)}\n'
                '= ${ideal.toStringAsFixed(1)} kg\n\n'
                '身高不足 5 英尺（152.4 cm）时按基数 '
                '$baseIdeal kg 计。',
          ),
          const SizedBox(height: AppSpacing.field),
          _ResultCard(
            title: '腰高比',
            value: whtr.toStringAsFixed(2),
            unit: whtrHigh
                ? '高于参考线 ${BodyMetrics.whtrReference}'
                : '参考线 ${BodyMetrics.whtrReference}',
            formula: '腰高比 = 腰围(cm) ÷ 身高(cm)\n'
                '= ${_waistCm.toStringAsFixed(1)} ÷ ${_heightCm.round()}\n'
                '= ${whtr.toStringAsFixed(2)}\n\n'
                '一般越低越好(合理范围内)\n'
                '≤ ${BodyMetrics.whtrReference}：较健康参考线；'
                '明显高于此值：腹部脂肪偏多风险往往更高。\n'
                '${whtrHigh ? '\n\n当前高于参考线。' : ''}',
          ),
          const SizedBox(height: AppSpacing.field),
          if (ffm == null || ffmi == null || normFfmi == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Text(
                  'FFMI：请填写有效体脂（0–100% 之间）。',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            _ResultCard(
              title: '去脂体重',
              value: ffm.toStringAsFixed(1),
              unit: 'kg',
              formula: '去脂体重 FFM = 体重 × (1 − 体脂%)\n'
                  '= ${_weightKg.toStringAsFixed(1)} × '
                  '(1 − ${_bodyFatPct.toStringAsFixed(1)}%)\n'
                  '= ${ffm.toStringAsFixed(1)} kg',
            ),
            const SizedBox(height: AppSpacing.field),
            _ResultCard(
              title: 'FFMI',
              value: ffmi.toStringAsFixed(1),
              unit: BodyMetrics.ffmiBand(ffmi).label,
              formula: 'FFMI = 去脂体重(kg) ÷ 身高(m)²\n'
                  '= ${ffm.toStringAsFixed(1)} ÷ '
                  '${heightM.toStringAsFixed(2)}²\n'
                  '= ${ffmi.toStringAsFixed(1)}\n\n'
                  '成年男性粗读参考：\n'
                  '<19 普通人附近 · 19–21 经常训练\n'
                  '22–23 较高水平 · ≥24 高水平参考\n'
                  '女性通常低约 3–5；非硬性标准。',
            ),
            const SizedBox(height: AppSpacing.field),
            _ResultCard(
              title: '归一化 FFMI',
              value: normFfmi.toStringAsFixed(1),
              unit: '按 1.8 m 校正',
              formula: '归一化 FFMI = FFMI + 6.1 × (1.8 − 身高m)\n'
                  '= ${ffmi.toStringAsFixed(1)} + 6.1 × '
                  '(1.8 − ${heightM.toStringAsFixed(2)})\n'
                  '= ${normFfmi.toStringAsFixed(1)}\n\n'
                  '用于校正身高偏离 1.8 m 时的可比性。',
            ),
          ],
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
    required this.formula,
  });

  final String title;
  final String value;
  final String unit;
  final String formula;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.card,
          vertical: 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          0,
          AppSpacing.card,
          AppSpacing.card,
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
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
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              formula,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
