import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';

/// Shared discrete option lists for profile / weight / meal forms.
class FormOptions {
  const FormOptions._();

  static List<int> ages({int min = 12, int max = 80}) => [
    for (var i = min; i <= max; i++) i,
  ];

  static List<int> heightsCm({int min = 140, int max = 210}) => [
    for (var i = min; i <= max; i++) i,
  ];

  static List<double> weightsKg({
    double min = 30,
    double max = 200,
    double step = 0.25,
  }) {
    final out = <double>[];
    for (var v = min; v <= max + 1e-9; v += step) {
      out.add(_round2(v));
    }
    return out;
  }

  /// Target weights strictly below [currentKg].
  static List<double> targetWeightsKg(double currentKg) {
    final max = _round2(((currentKg - 0.25) * 4).floor() / 4);
    if (max < 30) return const [];
    return weightsKg(min: 30, max: max.clamp(30, 200));
  }

  /// Options for cut target picker; never empty for the dropdown.
  static List<double> cutTargetOptions(double currentKg) {
    final opts = targetWeightsKg(currentKg);
    if (opts.isEmpty) return weightsKg(min: 30, max: 40);
    return opts;
  }

  static String? estimatedCutWeeksLabel({
    required AppLocalizations l10n,
    required FitnessGoal goal,
    required double weightKg,
    required double targetWeightKg,
    required double weeklyLossKg,
  }) {
    if (goal != FitnessGoal.cut) return null;
    if (targetWeightKg >= weightKg || weeklyLossKg <= 0) return null;
    final rate = CalorieCalculator.clampWeeklyLoss(weeklyLossKg).$1;
    final weeks = ((weightKg - targetWeightKg) / rate).ceil();
    return l10n.estimatedWeeksAtRate(weeks, rate.toStringAsFixed(1));
  }

  static const weeklyLossKg = <double>[0.3, 0.4, 0.5, 0.6, 0.7, 0.8];

  static List<double> bodyFatPct({
    double min = 5,
    double max = 45,
    double step = 0.5,
  }) {
    final out = <double>[];
    for (var v = min; v <= max + 1e-9; v += step) {
      out.add(_round1(v));
    }
    return out;
  }

  /// Circumference options in cm (neck / waist / hip).
  static List<double> circumferencesCm({
    double min = 20,
    double max = 160,
    double step = 0.5,
  }) {
    final out = <double>[];
    for (var v = min; v <= max + 1e-9; v += step) {
      out.add(_round1(v));
    }
    return out;
  }

  static const exerciseMinutes = <int>[
    15,
    20,
    30,
    40,
    45,
    60,
    75,
    90,
    105,
    120,
    150,
    180,
    240,
  ];

  static const targetSets = <int>[1, 2, 3, 4, 5, 6, 8, 10];

  /// Daily water goal options (ml), 500–5000 step 250.
  static const waterGoalMl = <int>[
    500,
    750,
    1000,
    1250,
    1500,
    1750,
    2000,
    2250,
    2500,
    2750,
    3000,
    3250,
    3500,
    3750,
    4000,
    4250,
    4500,
    4750,
    5000,
  ];

  static const targetRepsOrSeconds = <int>[
    5,
    6,
    8,
    10,
    12,
    15,
    20,
    25,
    30,
    40,
    45,
    60,
    90,
    120,
  ];

  /// Duration options for timed exercises (plank, etc.), up to 10 minutes.
  static const targetSeconds = <int>[
    5,
    10,
    15,
    20,
    30,
    45,
    60,
    90,
    120,
    150,
    180,
    240,
    300,
    360,
    420,
    480,
    540,
    600,
  ];

  /// Meal portion options; consecutive values differ by at most [step] (default 5g).
  static List<double> mealGrams({
    double min = 5,
    double max = 500,
    double step = 5,
  }) {
    final out = <double>[];
    for (var v = min; v <= max + 1e-9; v += step) {
      out.add(v);
    }
    return out;
  }

  static int snapInt(List<int> options, int value) {
    if (options.isEmpty) return value;
    return options.reduce(
      (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
    );
  }

  static double snapDouble(List<double> options, double value) {
    if (options.isEmpty) return value;
    return options.reduce(
      (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
    );
  }

  static double _round1(double v) => (v * 10).round() / 10;
  static double _round2(double v) => (v * 100).round() / 100;
}

String formatKg(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final fixed = v.toStringAsFixed(2);
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

Future<T?> _showCupertinoWheelPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required T selected,
  required String Function(T value) itemLabel,
}) async {
  if (items.isEmpty) return null;
  var index = items.indexOf(selected);
  if (index < 0) index = 0;

  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => _CupertinoWheelSheet<T>(
      title: title,
      items: items,
      initialIndex: index,
      itemLabel: itemLabel,
    ),
  );
}

class _CupertinoWheelSheet<T> extends StatefulWidget {
  const _CupertinoWheelSheet({
    required this.title,
    required this.items,
    required this.initialIndex,
    required this.itemLabel,
  });

  final String title;
  final List<T> items;
  final int initialIndex;
  final String Function(T value) itemLabel;

  @override
  State<_CupertinoWheelSheet<T>> createState() =>
      _CupertinoWheelSheetState<T>();
}

class _CupertinoWheelSheetState<T> extends State<_CupertinoWheelSheet<T>> {
  late final FixedExtentScrollController _controller;
  late T _pending;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
    _pending = widget.items[widget.initialIndex];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bg = CupertinoDynamicColor.resolve(
      CupertinoColors.systemBackground,
      context,
    );
    final labelColor = CupertinoDynamicColor.resolve(
      CupertinoColors.label,
      context,
    );

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: TextDecoration.none,
                        color: labelColor,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(context, _pending),
                    child: Text(
                      l10n.done,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: CupertinoColors.separator),
            Expanded(
              child: CupertinoPicker(
                scrollController: _controller,
                itemExtent: 40,
                magnification: 1.12,
                useMagnifier: true,
                squeeze: 1.05,
                onSelectedItemChanged: (i) {
                  _pending = widget.items[i];
                },
                children: [
                  for (final item in widget.items)
                    Center(
                      child: Text(
                        widget.itemLabel(item),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          decoration: TextDecoration.none,
                          color: labelColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style form row that opens a Cupertino wheel picker.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.suffixText,
    this.helperText,
    this.itemLabel,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String? suffixText;
  final String? helperText;
  final String Function(T value)? itemLabel;

  String _labelOf(T v) {
    final base = itemLabel?.call(v) ?? '$v';
    return suffixText == null ? base : '$base $suffixText';
  }

  Future<void> _open(BuildContext context) async {
    if (items.isEmpty) return;
    final selected = items.contains(value) ? value : items.first;
    final picked = await _showCupertinoWheelPicker<T>(
      context: context,
      title: label,
      items: items,
      selected: selected,
      itemLabel: _labelOf,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final selected = items.contains(value) ? value : items.first;
    return _PickerField(
      label: label,
      displayText: _labelOf(selected),
      helperText: helperText,
      onTap: () => _open(context),
    );
  }
}

/// Optional value picker: includes a leading "leave blank" option.
class AppOptionalDropdown<T extends Object> extends StatelessWidget {
  const AppOptionalDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.suffixText,
    this.helperText,
    this.itemLabel,
    this.noneLabel,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? suffixText;
  final String? helperText;
  final String Function(T value)? itemLabel;
  final String? noneLabel;

  String _labelOfValue(T v) {
    final base = itemLabel?.call(v) ?? '$v';
    return suffixText == null ? base : '$base $suffixText';
  }

  @override
  Widget build(BuildContext context) {
    final none = noneLabel ?? context.l10n.leaveBlank;
    String display() {
      if (value == null || !items.contains(value)) return none;
      return _labelOfValue(value as T);
    }

    return _PickerField(
      label: label,
      displayText: display(),
      helperText: helperText,
      onTap: () async {
        final options = <_OptionalEntry<T>>[
          _OptionalEntry<T>.none(),
          for (final item in items) _OptionalEntry<T>.value(item),
        ];
        final current = value != null && items.contains(value)
            ? _OptionalEntry<T>.value(value as T)
            : _OptionalEntry<T>.none();
        final picked = await _showCupertinoWheelPicker<_OptionalEntry<T>>(
          context: context,
          title: label,
          items: options,
          selected: current,
          itemLabel: (e) => e.isNone ? none : _labelOfValue(e.value as T),
        );
        if (picked == null) return; // cancelled
        onChanged(picked.isNone ? null : picked.value);
      },
    );
  }
}

class _OptionalEntry<T extends Object> {
  const _OptionalEntry.none() : value = null, isNone = true;
  const _OptionalEntry.value(this.value) : isNone = false;

  final T? value;
  final bool isNone;

  @override
  bool operator ==(Object other) =>
      other is _OptionalEntry<T> &&
      isNone == other.isNone &&
      value == other.value;

  @override
  int get hashCode => Object.hash(isNone, value);
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.displayText,
    required this.onTap,
    this.helperText,
  });

  final String label;
  final String displayText;
  final VoidCallback onTap;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 5,
                    child: Text(
                      displayText,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_up_chevron_down,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(helperText!, style: theme.textTheme.meta),
          ),
        ],
      ],
    );
  }
}
