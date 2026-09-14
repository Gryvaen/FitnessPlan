import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/diet_strategy_repository.dart';
import '../../domain/calendar_day.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/strategy_eligibility.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'carb_cycle_view.dart';
import 'strategy_labels.dart';

/// Parameter editor + preview + apply for one strategy kind.
///
/// Creates a new immutable plan version; it never edits stored versions.
class StrategyConfigurePage extends ConsumerStatefulWidget {
  const StrategyConfigurePage({super.key, required this.kind});

  final DietStrategyKind kind;

  @override
  ConsumerState<StrategyConfigurePage> createState() =>
      _StrategyConfigurePageState();
}

class _StrategyConfigurePageState extends ConsumerState<StrategyConfigurePage> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _tdeeCtrl;
  late final TextEditingController _energyCtrl;

  double _deficit = StrategyRules.defaultDeficitFraction;
  double _proteinPerKg = StrategyRules.defaultProteinPerKg;
  double _fatPerKg = StrategyRules.defaultFatPerKg;

  int _cycleLengthDays = StrategyRules.defaultCycleLengthDays;
  CarbCycleSchedule _schedule = CarbCycleSchedule.defaultFor(
    StrategyRules.defaultCycleLengthDays,
  );
  double _lowProteinPerKg = StrategyRules.defaultLowProteinPerKg;
  double _lowCarbPerKg = StrategyRules.defaultLowCarbPerKg;
  double _lowFatPerKg = StrategyRules.defaultLowFatPerKg;
  double _highProteinPerKg = StrategyRules.defaultHighProteinPerKg;
  double _highCarbPerKg = StrategyRules.defaultHighCarbPerKg;
  double _highFatPerKg = StrategyRules.defaultHighFatPerKg;

  bool _startToday = false;
  bool _initialised = false;
  bool _saving = false;

  CarbCycleRates get _carbCycleRates => CarbCycleRates(
    lowProteinPerKg: _lowProteinPerKg,
    lowCarbPerKg: _lowCarbPerKg,
    lowFatPerKg: _lowFatPerKg,
    highProteinPerKg: _highProteinPerKg,
    highCarbPerKg: _highCarbPerKg,
    highFatPerKg: _highFatPerKg,
  );

  /// Effective high-day carb rate after the mid-day compensation in
  /// [CarbCyclePlanner.compute], or null when it doesn't differ from the
  /// raw [_highCarbPerKg] the user set (no mid days, or no high day).
  double? _effectiveHighCarbPerKg(CarbCyclePlan? plan) {
    if (plan == null || _weight <= 0) return null;
    final high = plan.dayFor(CarbDayType.high);
    if (high == null) return null;
    final effective = high.carbG / _weight;
    if ((effective - _highCarbPerKg).abs() < 0.005) return null;
    return effective;
  }

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController();
    _tdeeCtrl = TextEditingController();
    _energyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _tdeeCtrl.dispose();
    _energyCtrl.dispose();
    super.dispose();
  }

  void _initFrom(DietStrategyPlan? active) {
    if (_initialised) return;
    _initialised = true;
    final profile = ref.read(profileProvider);
    final w = active?.referenceWeightKg ?? profile?.weightKg ?? 0;
    final t = active?.estimatedTdee ?? profile?.tdee ?? 0;
    _weightCtrl.text = w > 0 ? w.toStringAsFixed(1) : '';
    _tdeeCtrl.text = t > 0 ? t.round().toString() : '';
    if (active != null) {
      _deficit = active.deficitFraction.clamp(
        StrategyRules.minDeficitFraction,
        StrategyRules.maxDeficitFraction,
      );
      _proteinPerKg = active.proteinPerKg;
      _fatPerKg = active.fatPerKg;
      if (active.kind == DietStrategyKind.carbCycle) {
        final s = active.schedule;
        if (s != null) {
          _cycleLengthDays = s.cycleLengthDays;
          _schedule = s;
        }
        final r = active.carbCycleRates;
        if (r != null) {
          _lowProteinPerKg = r.lowProteinPerKg;
          _lowCarbPerKg = r.lowCarbPerKg;
          _lowFatPerKg = r.lowFatPerKg;
          _highProteinPerKg = r.highProteinPerKg;
          _highCarbPerKg = r.highCarbPerKg;
          _highFatPerKg = r.highFatPerKg;
        }
      }
    }
    _syncEnergyFromDeficit();
  }

  /// Carb cycling always reads the reference weight straight from the
  /// profile (no manual override); other strategies use the editable field.
  double get _weight => _isCarbCycle
      ? (ref.read(profileProvider)?.weightKg ?? 0)
      : double.tryParse(_weightCtrl.text.trim()) ?? 0;
  double get _tdee => double.tryParse(_tdeeCtrl.text.trim()) ?? 0;
  double get _energy => double.tryParse(_energyCtrl.text.trim()) ?? 0;

  void _syncEnergyFromDeficit() {
    final t = _tdee;
    if (t > 0) {
      _energyCtrl.text = (t * (1 - _deficit)).round().toString();
    }
  }

  void _onEnergyEdited(String raw) {
    final e = double.tryParse(raw.trim());
    final t = _tdee;
    if (e == null || t <= 0) return;
    final d = 1 - e / t;
    setState(() {
      _deficit = d.clamp(
        StrategyRules.minDeficitFraction - 0.05,
        StrategyRules.maxDeficitFraction + 0.05,
      );
    });
  }

  StrategyBaseline get _baseline => StrategyBaseline.fromTargetEnergy(
    referenceWeightKg: _weight,
    tdee: _tdee,
    targetEnergy: _energy,
    proteinPerKg: _proteinPerKg,
    fatPerKg: _fatPerKg,
  );

  DateTime get _tomorrow =>
      CalendarDay.todayLocal().add(const Duration(days: 1));

  DateTime get _effectiveFrom => _startToday ? CalendarDay.todayLocal() : _tomorrow;

  bool get _isCarbCycle => widget.kind == DietStrategyKind.carbCycle;

  DietStrategyPlanDraft _draft({int? legacyCalories}) {
    final isCarbCycle = _isCarbCycle;
    return DietStrategyPlanDraft(
      kind: widget.kind,
      effectiveFrom: _effectiveFrom,
      referenceWeightKg: _weight,
      estimatedTdee: isCarbCycle
          ? (ref.read(profileProvider)?.tdee ?? 0)
          : _tdee,
      baseEnergy: isCarbCycle
          ? CarbCyclePlanner.compute(
              referenceWeightKg: _weight,
              rates: _carbCycleRates,
              schedule: _schedule,
            ).cycleAverageEnergy
          : _energy,
      proteinPerKg: isCarbCycle
          ? StrategyRules.defaultProteinPerKg
          : _proteinPerKg,
      fatPerKg: isCarbCycle ? StrategyRules.defaultFatPerKg : _fatPerKg,
      schedule: isCarbCycle ? _schedule : null,
      carbCycleRates: isCarbCycle ? _carbCycleRates : null,
      taperStage: 0,
      observationStart: widget.kind == DietStrategyKind.carbTaper
          ? _effectiveFrom
          : null,
      observationDays: widget.kind == DietStrategyKind.carbTaper
          ? _taperObservationDays()
          : StrategyRules.taperObservationDays,
      reason: _startToday ? 'created;startToday' : 'created',
      legacyCalories: legacyCalories,
    );
  }

  /// Longer observation when switching from carb cycling (large carb shift).
  int _taperObservationDays() {
    final active = ref.read(activeDietPlanProvider).value;
    return active?.kind == DietStrategyKind.carbCycle
        ? StrategyRules.taperObservationDaysAfterCarbShift
        : StrategyRules.taperObservationDays;
  }

  /// Deficit slider in kcal within the selectable band; percent tracks the
  /// thumb horizontally so it stays under the current value.
  Widget _buildDeficitSlider(
    AppLocalizations l10n,
    ThemeData theme,
    double tdee,
  ) {
    // Interior of the 10%–20% band. Endpoints are excluded so whole-kcal
    // rounding does not push the stored fraction just outside
    // [minDeficitFraction, maxDeficitFraction].
    const minFrac = 0.11;
    const maxFrac = 0.19;
    final minKcal = tdee * minFrac;
    final maxKcal = tdee * maxFrac;
    final deficitKcal = (tdee * _deficit).clamp(minKcal, maxKcal);
    final trackT = maxKcal > minKcal
        ? ((deficitKcal - minKcal) / (maxKcal - minKcal)).clamp(0.0, 1.0)
        : 0.0;
    final percentText = l10n.deficitFractionPercent((_deficit * 100).round());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(
          value: deficitKcal,
          min: minKcal,
          max: maxKcal,
          divisions: 8,
          label: '${deficitKcal.round()} kcal',
          onChanged: (v) => setState(() {
            _deficit = v / tdee;
            _syncEnergyFromDeficit();
          }),
        ),
        Builder(
          builder: (context) {
            // Match Material Slider track insets (half overlay width).
            final overlay = SliderTheme.of(context).overlayShape ??
                const RoundSliderOverlayShape();
            final pad = overlay.getPreferredSize(true, false).width / 2;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Align(
                alignment: Alignment(2 * trackT - 1, 0),
                child: Text(percentText, style: theme.textTheme.bodySmall),
              ),
            );
          },
        ),
        Text(
          l10n.energyBoundsHint(minKcal.round(), maxKcal.round()),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final profile = ref.read(profileProvider);
    setState(() => _saving = true);
    try {
      final draft = _draft(legacyCalories: profile?.targets.calories);
      await ref.read(dietStrategyRepositoryProvider).createPlan(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.strategyApplied)));
      context.go('/profile/nutrition');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profile = ref.watch(profileProvider);
    final activeAsync = ref.watch(activeDietPlanProvider);

    if (activeAsync.isLoading && !_initialised) {
      return AppChromeScaffold(
        appBar: AppBar(title: Text(widget.kind.label(l10n))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _initFrom(activeAsync.value);

    final eligibility = StrategyEligibility.check(profile);
    final baseline = _baseline;
    final draft = _draft();
    final issues = <StrategyIssue>{...eligibility, ...draft.validate()};
    CarbCyclePlan? cyclePlan;
    if (_isCarbCycle) {
      cyclePlan = CarbCyclePlanner.compute(
        referenceWeightKg: _weight,
        rates: _carbCycleRates,
        schedule: _schedule,
      );
    }
    final canApply = issues.isEmpty && !_saving;
    final effective = _effectiveFrom;

    return AppChromeScaffold(
      appBar: AppBar(
        title: Text(widget.kind.label(l10n)),
        // 策略配置是从 Me 进入的独立操作流，退出时直接回到 Me，
        // 不再要求用户依次返回「策略选择」和「营养目标」页面。
        leading: BackButton(onPressed: () => context.go('/profile')),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          Text(
            widget.kind.description(l10n),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.card),
          // ------------------------------------------------ parameters
          if (!_isCarbCycle) ...[
            Text(l10n.strategyParameters, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.section),
          ],
          if (_isCarbCycle) ...[
            Text(
              l10n.cycleLengthLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final n in StrategyRules.cycleLengthDaysOptions)
                  ChoiceChip(
                    label: Text(l10n.cycleLengthDaysOption(n)),
                    selected: _cycleLengthDays == n,
                    onSelected: (_) => setState(() {
                      _cycleLengthDays = n;
                      _schedule = CarbCycleSchedule.defaultFor(n);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(l10n.lowCarbDayRatesTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _StepperRow(
              label: l10n.proteinPerKgLabel,
              value: _lowProteinPerKg,
              min: StrategyRules.lowProteinPerKgMin,
              max: StrategyRules.lowProteinPerKgMax,
              step: 0.1,
              unit: 'g/kg',
              onChanged: (v) => setState(() => _lowProteinPerKg = v),
            ),
            _StepperRow(
              label: l10n.carbPerKgLabel,
              value: _lowCarbPerKg,
              min: StrategyRules.lowCarbPerKgMin,
              max: StrategyRules.lowCarbPerKgMax,
              step: 0.1,
              unit: 'g/kg',
              onChanged: (v) => setState(() => _lowCarbPerKg = v),
            ),
            _StepperRow(
              label: l10n.fatPerKgLabel,
              value: _lowFatPerKg,
              min: StrategyRules.lowFatPerKgMin,
              max: StrategyRules.lowFatPerKgMax,
              step: 0.1,
              unit: 'g/kg',
              onChanged: (v) => setState(() => _lowFatPerKg = v),
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(
              l10n.highCarbDayRatesTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            _StepperRow(
              label: l10n.proteinPerKgLabel,
              value: _highProteinPerKg,
              min: StrategyRules.highProteinPerKgMin,
              max: StrategyRules.highProteinPerKgMax,
              step: 0.1,
              unit: 'g/kg',
              onChanged: (v) => setState(() => _highProteinPerKg = v),
            ),
            Builder(
              builder: (context) {
                final effective = _effectiveHighCarbPerKg(cyclePlan);
                final shown = effective ?? _highCarbPerKg;
                return _StepperRow(
                  label: l10n.carbPerKgLabel,
                  modifiedTooltip: effective != null
                      ? l10n.carbCycleAdjustedTooltip
                      : null,
                  value: shown,
                  min: StrategyRules.highCarbPerKgMin,
                  max: StrategyRules.highCarbPerKgMax,
                  step: 0.1,
                  unit: 'g/kg',
                  // The stepper moves whatever it's showing (the
                  // compensated rate) by ±step; apply that same delta to
                  // the underlying user-set rate so repeated taps don't
                  // compound the mid-day compensation.
                  onChanged: (v) => setState(() {
                    _highCarbPerKg = (_highCarbPerKg + (v - shown)).clamp(
                      StrategyRules.highCarbPerKgMin,
                      StrategyRules.highCarbPerKgMax,
                    );
                  }),
                );
              },
            ),
            _StepperRow(
              label: l10n.fatPerKgLabel,
              value: _highFatPerKg,
              min: StrategyRules.highFatPerKgMin,
              max: StrategyRules.highFatPerKgMax,
              step: 0.1,
              unit: 'g/kg',
              onChanged: (v) => setState(() => _highFatPerKg = v),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.referenceWeightKg,
                      suffixText: 'kg',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.field),
                Expanded(
                  child: TextField(
                    controller: _tdeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.estimatedTdee,
                      suffixText: 'kcal',
                    ),
                    onChanged: (_) => setState(_syncEnergyFromDeficit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.field),
            Text(
              l10n.deficitFractionLabel,
              style: theme.textTheme.fieldLabel,
            ),
            if (baseline.tdee > 0)
              _buildDeficitSlider(l10n, theme, baseline.tdee),
            TextField(
              controller: _energyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.averageTargetEnergy,
                suffixText: 'kcal',
              ),
              onChanged: _onEnergyEdited,
            ),
            const SizedBox(height: AppSpacing.field),
            _StepperRow(
              label: l10n.proteinPerKgLabel,
              value: _proteinPerKg,
              min: 1.4,
              max: 2.2,
              step: 0.1,
              unit: 'g/kg',
              onChanged: (v) => setState(() => _proteinPerKg = v),
            ),
            _StepperRow(
              label: l10n.fatPerKgLabel,
              value: _fatPerKg,
              min: 0.6,
              max: 1.0,
              step: 0.1,
              unit: 'g/kg',
              onChanged: (v) => setState(() => _fatPerKg = v),
            ),
            const SizedBox(height: AppSpacing.section),
            // ------------------------------------------------ baseline
            Text(l10n.dailyBaselineTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              '${baseline.energy.round()} kcal · '
              'P ${baseline.proteinG.toStringAsFixed(0)} · '
              'C ${baseline.carbG.isFinite ? baseline.carbG.toStringAsFixed(0) : '–'} · '
              'F ${baseline.fatG.toStringAsFixed(0)} g',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dailyDeficitLine('${baseline.dailyDeficit.round()}'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          // ------------------------------------------------ kind-specific
          if (cyclePlan != null) ...[
            const SizedBox(height: AppSpacing.card),
            Text(l10n.cycleSchedule, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.compact),
            CarbCycleView(
              key: ValueKey(
                '${_schedule.code}-${_carbCycleRates.lowCarbPerKg}-'
                '${_carbCycleRates.highCarbPerKg}-${_weight.round()}',
              ),
              plan: cyclePlan,
              cycleStart: effective,
              onScheduleChanged: (s) => setState(() => _schedule = s),
              referenceWeightFromProfile: true,
            ),
          ],
          if (widget.kind == DietStrategyKind.carbTaper) ...[
            const SizedBox(height: AppSpacing.card),
            Text(l10n.taperLadderTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.compact),
            _TaperLadder(baseline: baseline),
          ],
          // ------------------------------------------------ effective date
          const SizedBox(height: AppSpacing.card),
          Text(l10n.effectiveDate, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.compact),
          _EffectiveDateOption(
            label: l10n.startTomorrow(AppDates.md(_tomorrow, locale)),
            selected: !_startToday,
            onTap: () => setState(() => _startToday = false),
          ),
          _EffectiveDateOption(
            label: l10n.startToday,
            selected: _startToday,
            onTap: () => setState(() => _startToday = true),
          ),
          // ------------------------------------------------ issues
          if (issues.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.card),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 18, color: scheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.message(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.card),
          FilledButton(
            onPressed: canApply ? _apply : null,
            child: Text(l10n.applyStrategyFrom(AppDates.md(effective, locale))),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(l10n.strategyDisclaimer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// A radio-style row for the binary "effective date" choice.
class _EffectiveDateOption extends StatelessWidget {
  const _EffectiveDateOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
    this.modifiedTooltip,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  /// When set, shows a small "auto-adjusted" badge after the label instead
  /// of a text marker; the string is the badge's tooltip.
  final String? modifiedTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double snap(double v) => (v * 10).round() / 10;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (modifiedTooltip case final tooltip?)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: tooltip,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      Icons.auto_fix_high,
                      size: 15,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: '−$step',
          onPressed: value - step >= min - 1e-9
              ? () => onChanged(snap(value - step))
              : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 72,
          child: Text(
            '${value.toStringAsFixed(1)} $unit',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
        ),
        IconButton(
          tooltip: '+$step',
          onPressed: value + step <= max + 1e-9
              ? () => onChanged(snap(value + step))
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Stage ladder preview for the carb taper: stage 0 plus every feasible
/// candidate down to the floor. Purely informational.
class _TaperLadder extends StatelessWidget {
  const _TaperLadder({required this.baseline});

  final StrategyBaseline baseline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    final stages = <CarbTaperStage>[];
    for (var j = 0; j < 12; j++) {
      final s = CarbTaperStage.of(baseline, j);
      if (!s.feasible) break;
      stages.add(s);
    }
    if (stages.isEmpty) {
      return Text(
        StrategyIssue.energyBelowFloor.message(l10n),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    return Column(
      children: [
        for (final s in stages)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: visuals.divider)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    l10n.taperStageLabel(s.stage),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: s.stage == 0 ? visuals.accent : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${s.day.energy.round()} kcal · C ${s.day.carbG.toStringAsFixed(0)} g',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (s.stage == 0)
                  Text(
                    l10n.currentStage,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: visuals.accent,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.compact),
        Text(
          l10n.taperFloorLine(
            baseline.minEnergy.round(),
            StrategyRules.minCarbG.round(),
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
