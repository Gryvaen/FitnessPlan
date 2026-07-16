import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/body_metrics.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class BodyFatPage extends ConsumerStatefulWidget {
  const BodyFatPage({super.key});

  @override
  ConsumerState<BodyFatPage> createState() => _BodyFatPageState();
}

class _BodyFatPageState extends ConsumerState<BodyFatPage> {
  late Sex _sex;
  late double _heightCm;
  late double _neckCm;
  late double _waistCm;
  late double _hipCm;
  bool _saving = false;

  static final _necks = FormOptions.circumferencesCm(min: 25, max: 55);
  static final _waists = FormOptions.circumferencesCm(min: 50, max: 150);
  static final _hips = FormOptions.circumferencesCm(min: 70, max: 160);

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider)!;
    _sex = p.sex;
    _heightCm = FormOptions.snapDouble(
      FormOptions.heightsCm().map((e) => e.toDouble()).toList(),
      p.heightCm,
    );
    _neckCm = FormOptions.snapDouble(_necks, _sex == Sex.male ? 38 : 32);
    _waistCm = FormOptions.snapDouble(_waists, _sex == Sex.male ? 85 : 70);
    _hipCm = FormOptions.snapDouble(_hips, 95);
  }

  double? get _pct => BodyMetrics.bodyFatNavyPct(
        sex: _sex,
        heightCm: _heightCm,
        neckCm: _neckCm,
        waistCm: _waistCm,
        hipCm: _sex == Sex.female ? _hipCm : null,
      );

  Future<void> _writeToTodayWeight() async {
    final pct = _pct;
    if (pct == null) return;
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final ok = await ref
          .read(weightRepositoryProvider)
          .updateBodyFatForDate(now, double.parse(pct.toStringAsFixed(1)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? l10n.bfWrittenSnack(pct.toStringAsFixed(1))
                : l10n.bfNoWeightLog,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pct = _pct;
    final heights =
        FormOptions.heightsCm().map((e) => e.toDouble()).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolBodyFat)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            l10n.bfDisclaimer,
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
            label: l10n.neck,
            value: _neckCm,
            items: _necks,
            suffixText: 'cm',
            onChanged: (v) => setState(() => _neckCm = v),
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: _sex == Sex.male ? l10n.abdomenWaist : l10n.waist,
            value: _waistCm,
            items: _waists,
            suffixText: 'cm',
            onChanged: (v) => setState(() => _waistCm = v),
          ),
          if (_sex == Sex.female) ...[
            const SizedBox(height: AppSpacing.field),
            AppDropdown<double>(
              label: l10n.hip,
              value: _hipCm,
              items: _hips,
              suffixText: 'cm',
              onChanged: (v) => setState(() => _hipCm = v),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.estimatedBf, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (pct == null)
                    Text(
                      l10n.bfCircumferenceError,
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          pct.toStringAsFixed(1),
                          style: theme.textTheme.statValue,
                        ),
                        const SizedBox(width: 6),
                        Text('%', style: theme.textTheme.statUnit),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: pct == null || _saving ? null : _writeToTodayWeight,
            child: Text(_saving ? l10n.writing : l10n.writeBfToWeight),
          ),
        ],
      ),
    );
  }
}
