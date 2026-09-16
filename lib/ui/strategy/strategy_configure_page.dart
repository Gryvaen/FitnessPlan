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

  void _initFrom(DietStrategyPlan? active) {
    if (_initialised) return;
    _initialised = true;
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
  }

  double get _weight => ref.read(profileProvider)?.weightKg ?? 0;
  double get _tdee => ref.read(profileProvider)?.tdee ?? 0;
  double get _energy => _tdee * (1 - _deficit);

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
      estimatedTdee: _tdee,
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

  /// Deficit slider in kcal within the selectable band.
  Widget _buildDeficitSlider(double tdee) {
    const minFrac = StrategyRules.minDeficitFraction;
    const maxFrac = StrategyRules.maxDeficitFraction;
    final minKcal = tdee * minFrac;
    final maxKcal = tdee * maxFrac;
    final deficitKcal = (tdee * _deficit).clamp(minKcal, maxKcal);
    return Slider(
      value: deficitKcal,
      min: minKcal,
      max: maxKcal,
      divisions: 10,
      label: '${deficitKcal.round()} kcal',
      onChanged: (v) => setState(() {
        _deficit = v / tdee;
      }),
    );
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final profile = ref.read(profileProvider);
    setState(() => _saving = true);
    try {
      final draft = _draft(legacyCalories: profile?.targets.calories);
      await ref.read(dietStrategyActionsProvider).applyPlan(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.strategyApplied)));
      context.go('/profile');
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
        leading: BackButton(onPressed: () => context.pop()),
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
          Text(l10n.strategyParameters, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.section),
          Column(
            children: [
              _ReadOnlyMetric(
                key: const ValueKey('strategyReferenceWeight'),
                label: l10n.referenceWeightKg,
                value: _weight > 0 ? _weight.toStringAsFixed(1) : '–',
                unit: 'kg',
              ),
              _ReadOnlyMetric(
                key: const ValueKey('strategyEstimatedTdee'),
                label: l10n.estimatedTdee,
                value: _tdee > 0 ? _tdee.round().toString() : '–',
                unit: 'kcal',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.field),
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
            Text(
              '${l10n.deficitFractionLabel} | '
              '${l10n.deficitFractionPercent((_deficit * 100).round())}',
              style: theme.textTheme.fieldLabel,
            ),
            if (baseline.tdee > 0) _buildDeficitSlider(baseline.tdee),
            const SizedBox(height: AppSpacing.field),
            _ReadOnlyMetric(
              key: const ValueKey('strategyAverageTargetEnergy'),
              label: l10n.averageTargetEnergy,
              value: _energy > 0 ? _energy.round().toString() : '–',
              unit: 'kcal',
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

class _ReadOnlyMetric extends StatelessWidget {
  const _ReadOnlyMetric({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      readOnly: true,
      label: label,
      value: '$value $unit',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.field),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
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
