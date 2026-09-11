import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';

/// 1 kcal = 4.184 kJ (thermochemical calorie, as used for food energy).
const double kKcalToKj = 4.184;

/// Bidirectional kcal ⇄ kJ converter: editing either field updates the other.
class EnergyUnitConvertPage extends StatefulWidget {
  const EnergyUnitConvertPage({super.key});

  @override
  State<EnergyUnitConvertPage> createState() => _EnergyUnitConvertPageState();
}

class _EnergyUnitConvertPageState extends State<EnergyUnitConvertPage> {
  final _kcal = TextEditingController(text: '100');
  final _kj = TextEditingController();
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _kj.text = _fmt(100 * kKcalToKj);
  }

  @override
  void dispose() {
    _kcal.dispose();
    _kj.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  void _onKcalChanged(String text) {
    if (_updating) return;
    final v = double.tryParse(text.trim());
    _updating = true;
    _kj.text = v == null ? '' : _fmt(v * kKcalToKj);
    _updating = false;
  }

  void _onKjChanged(String text) {
    if (_updating) return;
    final v = double.tryParse(text.trim());
    _updating = true;
    _kcal.text = v == null ? '' : _fmt(v / kKcalToKj);
    _updating = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolEnergyConvert)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            l10n.toolEnergyConvertSub,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          _unitField(context, _kcal, 'kcal', _onKcalChanged),
          const SizedBox(height: AppSpacing.field),
          Center(
            child: Icon(
              Icons.swap_vert,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.field),
          _unitField(context, _kj, 'kJ', _onKjChanged),
          const SizedBox(height: AppSpacing.section),
          Text(
            '1 kcal = ${kKcalToKj.toStringAsFixed(3)} kJ',
            style: theme.textTheme.meta,
          ),
        ],
      ),
    );
  }

  Widget _unitField(
    BuildContext context,
    TextEditingController c,
    String suffix,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: suffix,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: Theme.of(context).textTheme.headlineSmall,
      onChanged: onChanged,
    );
  }
}
