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
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'carb_cycle_view.dart';
import 'stepper_row.dart';
import 'strategy_fold_section.dart';
import 'strategy_labels.dart';

enum _ConfigSection { profile, target, schedule, low, high, taper, effective }

bool _sameTargetNumber(double a, double b) =>
    a.isFinite && b.isFinite && (a - b).abs() < 1e-6;

bool _sameCycleRates(CarbCycleRates? a, CarbCycleRates? b) {
  if (a == null || b == null) return a == b;
  return _sameTargetNumber(a.lowProteinPerKg, b.lowProteinPerKg) &&
      _sameTargetNumber(a.lowCarbPerKg, b.lowCarbPerKg) &&
      _sameTargetNumber(a.lowFatPerKg, b.lowFatPerKg) &&
      _sameTargetNumber(a.highProteinPerKg, b.highProteinPerKg) &&
      _sameTargetNumber(a.highCarbPerKg, b.highCarbPerKg) &&
      _sameTargetNumber(a.highFatPerKg, b.highFatPerKg);
}

/// Effective date and version metadata do not change the nutrition target.
bool _matchesAppliedTarget(
  DietStrategyPlan active,
  DietStrategyPlanDraft draft,
) {
  if (active.kind != draft.kind ||
      !_sameTargetNumber(active.referenceWeightKg, draft.referenceWeightKg) ||
      !_sameTargetNumber(active.estimatedTdee, draft.estimatedTdee) ||
      !_sameTargetNumber(active.baseEnergy, draft.baseEnergy)) {
    return false;
  }
  switch (draft.kind) {
    case DietStrategyKind.balanced:
      return _sameTargetNumber(active.proteinPerKg, draft.proteinPerKg) &&
          _sameTargetNumber(active.fatPerKg, draft.fatPerKg);
    case DietStrategyKind.carbCycle:
      return active.schedule?.code == draft.schedule?.code &&
          _sameCycleRates(active.carbCycleRates, draft.carbCycleRates);
    case DietStrategyKind.carbTaper:
      return active.taperStage == draft.taperStage &&
          _sameTargetNumber(active.proteinPerKg, draft.proteinPerKg) &&
          _sameTargetNumber(active.fatPerKg, draft.fatPerKg);
  }
}

({String target, int kcal})? _lowEnergyPreview(
  AppLocalizations l10n,
  DietStrategyKind kind,
  StrategyBaseline baseline,
  CarbCyclePlan? cyclePlan,
) {
  if (cyclePlan != null) {
    final lowest = cyclePlan.days.reduce(
      (a, b) => a.energy <= b.energy ? a : b,
    );
    if (lowest.energy >= StrategyRules.lowEnergyNoticeKcal) return null;
    return (target: lowest.dayType.label(l10n), kcal: lowest.energy.round());
  }
  if (kind == DietStrategyKind.carbTaper) {
    CarbTaperStage? lowest;
    for (var stage = 0; stage < 12; stage++) {
      final candidate = CarbTaperStage.of(baseline, stage);
      if (!candidate.feasible) break;
      lowest = candidate;
    }
    if (lowest == null ||
        lowest.day.energy >= StrategyRules.lowEnergyNoticeKcal) {
      return null;
    }
    return (
      target: l10n.taperStageLabel(lowest.stage),
      kcal: lowest.day.energy.round(),
    );
  }
  if (baseline.energy >= StrategyRules.lowEnergyNoticeKcal) return null;
  return (target: kind.label(l10n), kcal: baseline.energy.round());
}

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
  _ConfigSection? _openSection;

  void _toggleSection(_ConfigSection section) => setState(() {
    _openSection = _openSection == section ? null : section;
  });

  Widget _section(
    _ConfigSection section, {
    required String title,
    required String summary,
    required Widget child,
    InkGlyph? icon,
  }) => StrategyFoldSection(
    key: ValueKey('strategy-section-${section.name}'),
    title: title,
    summary: summary,
    expanded: _openSection == section,
    onTap: () => _toggleSection(section),
    leading: icon,
    child: child,
  );

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

  DateTime get _effectiveFrom =>
      _startToday ? CalendarDay.todayLocal() : _tomorrow;

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
    if (_saving) return;
    final l10n = context.l10n;
    final profile = ref.read(profileProvider);
    setState(() => _saving = true);
    try {
      final draft = _draft(legacyCalories: profile?.targets.calories);
      final current = await ref
          .read(dietStrategyRepositoryProvider)
          .activePlan();
      if (current != null && _matchesAppliedTarget(current, draft)) return;
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
    final active = activeAsync.value;

    if (activeAsync.isLoading && !_initialised) {
      return AppChromeScaffold(
        appBar: AppBar(title: Text(widget.kind.label(l10n))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _initFrom(active);

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
    final effective = _effectiveFrom;
    final matchesAppliedTarget =
        active != null && _matchesAppliedTarget(active, draft);
    final hasPendingTarget = active != null && !matchesAppliedTarget;
    final canApply =
        issues.isEmpty &&
        !_saving &&
        !matchesAppliedTarget &&
        !activeAsync.isLoading;
    final lowEnergy = issues.isEmpty
        ? _lowEnergyPreview(l10n, widget.kind, baseline, cyclePlan)
        : null;

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
          Text(l10n.dailyBaselineTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.compact),
          Text(
            cyclePlan != null
                ? l10n.carbCyclePlanSummaryLine(
                    _weight.toStringAsFixed(1),
                    '$_cycleLengthDays',
                    '${cyclePlan.cycleAverageEnergy.round()}',
                  )
                : '${baseline.energy.round()} kcal · '
                      'P ${baseline.proteinG.toStringAsFixed(0)} · '
                      'C ${baseline.carbG.isFinite ? baseline.carbG.toStringAsFixed(0) : '–'} · '
                      'F ${baseline.fatG.toStringAsFixed(0)} g',
            key: const ValueKey('strategyTopSummary'),
            style: theme.textTheme.bodyLarge,
          ),
          if (active != null) ...[
            const SizedBox(height: AppSpacing.card),
            Text(l10n.strategySavedBasis, style: theme.textTheme.titleSmall),
            Text(
              '${active.kind.label(l10n)} · '
              '${l10n.planBaselineLine(active.referenceWeightKg.toStringAsFixed(1), '${active.estimatedTdee.round()}', '${active.baseEnergy.round()}')}',
              style: theme.textTheme.bodySmall,
            ),
            if (hasPendingTarget) ...[
              const SizedBox(height: AppSpacing.compact),
              Text(
                l10n.strategyProposedBasis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                '${l10n.currentWeight} ${_weight.toStringAsFixed(1)} kg · '
                '${l10n.estimatedTdee} ${_tdee.round()} kcal · '
                '${l10n.averageTargetEnergy} '
                '${(cyclePlan?.cycleAverageEnergy ?? baseline.energy).round()} kcal',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
          if (issues.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.field),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkIcon(InkGlyph.error, size: 18, color: scheme.error),
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
          if (lowEnergy != null) ...[
            const SizedBox(height: AppSpacing.field),
            Row(
              key: const ValueKey('strategyLowEnergyNotice'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkIcon(
                  InkGlyph.info,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.lowEnergyNotice(lowEnergy.target, lowEnergy.kcal),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.card),
          FilledButton(
            onPressed: canApply ? _apply : null,
            child: Text(
              matchesAppliedTarget
                  ? active.effectiveFrom.isAfter(CalendarDay.todayLocal())
                        ? l10n.strategyAlreadyScheduled
                        : l10n.strategyAlreadyApplied
                  : l10n.applyStrategyFrom(AppDates.md(effective, locale)),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          _section(
            _ConfigSection.profile,
            title: l10n.strategyCurrentProfile,
            summary:
                '${_weight > 0 ? _weight.toStringAsFixed(1) : '–'} kg · '
                '${_tdee > 0 ? _tdee.round().toString() : '–'} kcal',
            icon: InkGlyph.profile,
            child: Column(
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
          ),
          if (_isCarbCycle) ...[
            _section(
              _ConfigSection.schedule,
              title: l10n.cycleSchedule,
              summary:
                  '${l10n.cycleLengthDaysOption(_cycleLengthDays)} · '
                  '${_schedule.count(CarbDayType.high)}/'
                  '${_schedule.count(CarbDayType.mid)}/'
                  '${_schedule.count(CarbDayType.low)}',
              icon: InkGlyph.cycle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cycleLengthLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Wrap(
                    spacing: AppSpacing.compact,
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
                  const SizedBox(height: AppSpacing.card),
                  CarbCycleView(
                    key: ValueKey(
                      '${_schedule.code}-${_carbCycleRates.lowCarbPerKg}-'
                      '${_carbCycleRates.highCarbPerKg}-${_weight.round()}',
                    ),
                    plan: cyclePlan!,
                    cycleStart: effective,
                    cycleStartIndex: DietStrategyRepository.continuationIndex(
                      plans: ref.watch(dietPlansProvider).value ?? const [],
                      snapshots:
                          ref.watch(cycleSnapshotsProvider).value ?? const [],
                      restDays:
                          ref.watch(restDayDatesProvider).value ?? const [],
                      effectiveFrom: effective,
                      schedule: _schedule,
                    ),
                    restDayDates:
                        ref.watch(restDayDatesProvider).value ?? const [],
                    markers:
                        ref.watch(upcomingDayMarkersProvider).value ?? const {},
                    windowStart: effective,
                    onScheduleChanged: (s) => setState(() => _schedule = s),
                    referenceWeightFromProfile: true,
                  ),
                ],
              ),
            ),
            _section(
              _ConfigSection.low,
              title: l10n.lowCarbDayRatesTitle,
              summary:
                  'P ${_lowProteinPerKg.toStringAsFixed(1)} · '
                  'C ${_lowCarbPerKg.toStringAsFixed(1)} · '
                  'F ${_lowFatPerKg.toStringAsFixed(1)} g/kg',
              icon: InkGlyph.carbs,
              child: Column(
                children: [
                  StepperRow(
                    label: l10n.proteinPerKgLabel,
                    value: _lowProteinPerKg,
                    min: StrategyRules.lowProteinPerKgMin,
                    max: StrategyRules.lowProteinPerKgMax,
                    step: 0.1,
                    unit: 'g/kg',
                    onChanged: (v) => setState(() => _lowProteinPerKg = v),
                  ),
                  StepperRow(
                    label: l10n.carbPerKgLabel,
                    value: _lowCarbPerKg,
                    min: StrategyRules.lowCarbPerKgMin,
                    max: StrategyRules.lowCarbPerKgMax,
                    step: 0.1,
                    unit: 'g/kg',
                    onChanged: (v) => setState(() => _lowCarbPerKg = v),
                  ),
                  StepperRow(
                    label: l10n.fatPerKgLabel,
                    value: _lowFatPerKg,
                    min: StrategyRules.lowFatPerKgMin,
                    max: StrategyRules.lowFatPerKgMax,
                    step: 0.1,
                    unit: 'g/kg',
                    onChanged: (v) => setState(() => _lowFatPerKg = v),
                  ),
                ],
              ),
            ),
            _section(
              _ConfigSection.high,
              title: l10n.highCarbDayRatesTitle,
              summary:
                  'P ${_highProteinPerKg.toStringAsFixed(1)} · '
                  'C ${(_effectiveHighCarbPerKg(cyclePlan) ?? _highCarbPerKg).toStringAsFixed(1)} · '
                  'F ${_highFatPerKg.toStringAsFixed(1)} g/kg',
              icon: InkGlyph.carbs,
              child: Column(
                children: [
                  StepperRow(
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
                      final adjusted = _effectiveHighCarbPerKg(cyclePlan);
                      final shown = adjusted ?? _highCarbPerKg;
                      return StepperRow(
                        label: l10n.carbPerKgLabel,
                        modifiedTooltip: adjusted != null
                            ? l10n.carbCycleAdjustedTooltip
                            : null,
                        value: shown,
                        min: StrategyRules.highCarbPerKgMin,
                        max: StrategyRules.highCarbPerKgMax,
                        step: 0.1,
                        unit: 'g/kg',
                        onChanged: (v) => setState(() {
                          _highCarbPerKg = (_highCarbPerKg + (v - shown)).clamp(
                            StrategyRules.highCarbPerKgMin,
                            StrategyRules.highCarbPerKgMax,
                          );
                        }),
                      );
                    },
                  ),
                  StepperRow(
                    label: l10n.fatPerKgLabel,
                    value: _highFatPerKg,
                    min: StrategyRules.highFatPerKgMin,
                    max: StrategyRules.highFatPerKgMax,
                    step: 0.1,
                    unit: 'g/kg',
                    onChanged: (v) => setState(() => _highFatPerKg = v),
                  ),
                ],
              ),
            ),
          ] else
            _section(
              _ConfigSection.target,
              title: l10n.strategyGoalRates,
              summary:
                  '${l10n.deficitFractionPercent((_deficit * 100).round())} · '
                  '${_energy.round()} kcal',
              icon: InkGlyph.target,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.deficitFractionLabel} · '
                    '${l10n.deficitFractionPercent((_deficit * 100).round())}',
                    style: theme.textTheme.fieldLabel,
                  ),
                  if (baseline.tdee > 0) _buildDeficitSlider(baseline.tdee),
                  _ReadOnlyMetric(
                    key: const ValueKey('strategyAverageTargetEnergy'),
                    label: l10n.averageTargetEnergy,
                    value: _energy > 0 ? _energy.round().toString() : '–',
                    unit: 'kcal',
                  ),
                  StepperRow(
                    label: l10n.proteinPerKgLabel,
                    value: _proteinPerKg,
                    min: 1.4,
                    max: 2.2,
                    step: 0.1,
                    unit: 'g/kg',
                    onChanged: (v) => setState(() => _proteinPerKg = v),
                  ),
                  StepperRow(
                    label: l10n.fatPerKgLabel,
                    value: _fatPerKg,
                    min: 0.6,
                    max: 1.0,
                    step: 0.1,
                    unit: 'g/kg',
                    onChanged: (v) => setState(() => _fatPerKg = v),
                  ),
                  Text(
                    l10n.dailyDeficitLine('${baseline.dailyDeficit.round()}'),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (widget.kind == DietStrategyKind.carbTaper)
            _section(
              _ConfigSection.taper,
              title: l10n.taperLadderTitle,
              summary:
                  '${l10n.taperStageLabel(0)} · '
                  '${baseline.energy.round()} kcal',
              icon: InkGlyph.chart,
              child: _TaperLadder(baseline: baseline),
            ),
          _section(
            _ConfigSection.effective,
            title: l10n.effectiveDate,
            summary: _startToday
                ? l10n.startToday
                : l10n.startTomorrow(AppDates.md(_tomorrow, locale)),
            icon: InkGlyph.calendar,
            child: Column(
              children: [
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
              ],
            ),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(unit, style: theme.textTheme.bodySmall),
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
            InkIcon(
              selected ? InkGlyph.radioChecked : InkGlyph.radioEmpty,
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

/// Stage ladder preview for the carb taper: stage 0 plus every feasible
/// candidate before the carbohydrate minimum. Purely informational.
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
        StrategyIssue.carbBelowMinimum.message(l10n),
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
          l10n.taperFloorLine(StrategyRules.minCarbG.round()),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
