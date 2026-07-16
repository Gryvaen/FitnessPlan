import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/body_metrics.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
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
    final l10n = context.l10n;
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
    final inchesOver5ft = (heightIn - 60).clamp(0.0, double.infinity);
    final ref = BodyMetrics.whtrReference.toString();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolBodyMetrics)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            l10n.metricsLocalOnly,
            style: theme.textTheme.meta,
          ),
          const SizedBox(height: AppSpacing.section),
          AppDropdown<Sex>(
            label: l10n.sex,
            value: _sex,
            items: Sex.values,
            itemLabel: (s) => s.label(l10n),
            onChanged: (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: l10n.height,
            value: _heightCm,
            items: heights,
            suffixText: 'cm',
            itemLabel: (v) => v.round().toString(),
            onChanged: (v) => setState(() => _heightCm = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: l10n.weight,
            value: _weightKg,
            items: FormOptions.weightsKg(),
            suffixText: 'kg',
            itemLabel: (v) => v.toStringAsFixed(1),
            onChanged: (v) => setState(() => _weightKg = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: l10n.bodyFat,
            value: _bodyFatPct,
            items: _bodyFats,
            suffixText: '%',
            itemLabel: (v) => v.toStringAsFixed(1),
            onChanged: (v) => setState(() => _bodyFatPct = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: l10n.waist,
            value: _waistCm,
            items: _waists,
            suffixText: 'cm',
            onChanged: (v) => setState(() => _waistCm = v),
          ),
          const SizedBox(height: AppSpacing.section),
          _ResultCard(
            title: 'BMI',
            value: bmi.toStringAsFixed(1),
            unit: category.label(l10n),
            formula: l10n.bmiFormula(
              _weightKg.toStringAsFixed(1),
              heightM.toStringAsFixed(2),
              bmi.toStringAsFixed(1),
            ),
          ),
          const SizedBox(height: AppSpacing.field),
          _ResultCard(
            title: l10n.idealWeightDevine,
            value: ideal.toStringAsFixed(1),
            unit: 'kg',
            formula: l10n.idealWeightFormula(
              _sex.label(l10n),
              '${_heightCm.round()}',
              heightIn.toStringAsFixed(1),
              '$baseIdeal',
              inchesOver5ft.toStringAsFixed(1),
              ideal.toStringAsFixed(1),
            ),
          ),
          const SizedBox(height: AppSpacing.field),
          _ResultCard(
            title: l10n.whtr,
            value: whtr.toStringAsFixed(2),
            unit: whtrHigh
                ? l10n.whtrAboveRef(ref)
                : l10n.whtrRef(ref),
            formula: l10n.whtrFormula(
                  _waistCm.toStringAsFixed(1),
                  '${_heightCm.round()}',
                  whtr.toStringAsFixed(2),
                  ref,
                ) +
                (whtrHigh ? l10n.whtrAboveNow : ''),
          ),
          const SizedBox(height: AppSpacing.field),
          if (ffm == null || ffmi == null || normFfmi == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Text(
                  l10n.ffmiNeedBf,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            _ResultCard(
              title: l10n.leanMass,
              value: ffm.toStringAsFixed(1),
              unit: 'kg',
              formula: l10n.leanMassFormula(
                _weightKg.toStringAsFixed(1),
                _bodyFatPct.toStringAsFixed(1),
                ffm.toStringAsFixed(1),
              ),
            ),
            const SizedBox(height: AppSpacing.field),
            _ResultCard(
              title: 'FFMI',
              value: ffmi.toStringAsFixed(1),
              unit: BodyMetrics.ffmiBand(ffmi).label(l10n),
              formula: l10n.ffmiFormula(
                ffm.toStringAsFixed(1),
                heightM.toStringAsFixed(2),
                ffmi.toStringAsFixed(1),
              ),
            ),
            const SizedBox(height: AppSpacing.field),
            _ResultCard(
              title: l10n.normalizedFfmi,
              value: normFfmi.toStringAsFixed(1),
              unit: l10n.normalizedFfmiUnit,
              formula: l10n.normalizedFfmiFormula(
                ffmi.toStringAsFixed(1),
                heightM.toStringAsFixed(2),
                normFfmi.toStringAsFixed(1),
              ),
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
