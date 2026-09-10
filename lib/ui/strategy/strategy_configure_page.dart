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
import 'carb_cycle_week_view.dart';
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
  CarbCycleSchedule _schedule = CarbCycleSchedule.allMid();
  bool _startToday = false;
  bool _initialised = false;
  bool _saving = false;
  CarbCycleSchedule? _suggested;

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
      if (active.kind == DietStrategyKind.carbCycle &&
          active.schedule != null) {
        _schedule = active.schedule!;
      }
    }
    _syncEnergyFromDeficit();
  }

  double get _weight => double.tryParse(_weightCtrl.text.trim()) ?? 0;
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

  DateTime get _nextCycleStart {
    final today = CalendarDay.todayLocal();
    return widget.kind == DietStrategyKind.carbCycle
        ? StrategyDates.nextCycleStart(today)
        : today.add(const Duration(days: 1));
  }

  DateTime get _effectiveFrom =>
      _startToday ? CalendarDay.todayLocal() : _nextCycleStart;

  DietStrategyPlanDraft _draft({int? legacyCalories}) {
    return DietStrategyPlanDraft(
      kind: widget.kind,
      effectiveFrom: _effectiveFrom,
      referenceWeightKg: _weight,
      estimatedTdee: _tdee,
      baseEnergy: _energy,
      proteinPerKg: _proteinPerKg,
      fatPerKg: _fatPerKg,
      schedule: widget.kind == DietStrategyKind.carbCycle ? _schedule : null,
      carbAmplitudeG: widget.kind == DietStrategyKind.carbCycle
          ? CarbCyclePlanner.defaultAmplitude(_baseline)
          : null,
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

  Future<void> _suggestSchedule() async {
    final today = CalendarDay.todayLocal();
    const weeks = 4;
    final counts = await ref
        .read(workoutRepositoryProvider)
        .trainingWeekdayCounts(
          today.subtract(const Duration(days: weeks * 7 - 1)),
          today,
        );
    if (!mounted) return;
    setState(() {
      _suggested = CarbCyclePlanner.suggestFromTraining(counts, weeks: weeks);
    });
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
    if (widget.kind == DietStrategyKind.carbCycle) {
      cyclePlan = CarbCyclePlanner.compute(
        baseline,
        _schedule,
        amplitudeG: draft.carbAmplitudeG,
      );
      if (cyclePlan.amplitudeNegligible) {
        issues.add(StrategyIssue.amplitudeNegligible);
      }
    }
    final blocking = issues
        .where((i) => i != StrategyIssue.amplitudeNegligible)
        .toList();
    final canApply = blocking.isEmpty && !_saving;
    final effective = _effectiveFrom;
    final today = CalendarDay.todayLocal();

    return AppChromeScaffold(
      appBar: AppBar(title: Text(widget.kind.label(l10n))),
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
            l10n.deficitFractionLabel((_deficit * 100).round()),
            style: theme.textTheme.fieldLabel,
          ),
          Slider(
            value: _deficit.clamp(
              StrategyRules.minDeficitFraction,
              StrategyRules.maxDeficitFraction,
            ),
            min: StrategyRules.minDeficitFraction,
            max: StrategyRules.maxDeficitFraction,
            divisions: 10,
            label: '${(_deficit * 100).round()}%',
            onChanged: (v) => setState(() {
              _deficit = v;
              _syncEnergyFromDeficit();
            }),
          ),
          TextField(
            controller: _energyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.averageTargetEnergy,
              suffixText: 'kcal',
              helperText: baseline.tdee > 0
                  ? l10n.energyBoundsHint(
                      baseline.minEnergy.round(),
                      baseline.maxEnergy.round(),
                    )
                  : null,
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
          // ------------------------------------------------ kind-specific
          if (cyclePlan != null) ...[
            const SizedBox(height: AppSpacing.card),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.weeklySchedule,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _suggestSchedule,
                  icon: const Icon(Icons.fitness_center_outlined, size: 18),
                  label: Text(l10n.suggestFromTraining),
                ),
              ],
            ),
            if (_suggested != null && _suggested!.code != _schedule.code) ...[
              SportSurfaceCard(
                tint: scheme.tertiary,
                padding: const EdgeInsets.all(AppSpacing.section),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.trainingSuggestionBody(
                          _suggested!.count(CarbDayType.high),
                          _suggested!.count(CarbDayType.low),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _schedule = _suggested!;
                      }),
                      child: Text(l10n.applySuggestion),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
            ],
            const SizedBox(height: AppSpacing.compact),
            CarbCycleWeekView(
              key: ValueKey(
                '${_schedule.code}-${baseline.energy.round()}-${baseline.carbG.round()}',
              ),
              plan: cyclePlan,
              onScheduleChanged: (s) => setState(() => _schedule = s),
              initialSelected: (effective.weekday - 1).clamp(0, 6),
            ),
          ],
          if (widget.kind == DietStrategyKind.carbTaper) ...[
            const SizedBox(height: AppSpacing.card),
            Text(l10n.taperLadderTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.compact),
            _TaperLadder(baseline: baseline),
            const SizedBox(height: 6),
            Text(l10n.taperLadderHint, style: theme.textTheme.bodySmall),
          ],
          // ------------------------------------------------ effective date
          const SizedBox(height: AppSpacing.card),
          Text(l10n.effectiveDate, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.compact),
          _EffectiveDateOption(
            label: widget.kind == DietStrategyKind.carbCycle
                ? l10n.startNextCycle(AppDates.md(_nextCycleStart, locale))
                : l10n.startTomorrow(AppDates.md(_nextCycleStart, locale)),
            selected: !_startToday,
            onTap: () => setState(() => _startToday = false),
          ),
          _EffectiveDateOption(
            label: l10n.startToday,
            selected: _startToday,
            onTap: () => setState(() => _startToday = true),
          ),
          if (_startToday &&
              widget.kind == DietStrategyKind.carbCycle &&
              cyclePlan != null) ...[
            const SizedBox(height: AppSpacing.compact),
            Builder(
              builder: (context) {
                final cycleEnd = StrategyDates.cycleStartOf(
                  today,
                ).add(const Duration(days: 6));
                var partial = 0.0;
                for (
                  var d = today;
                  !d.isAfter(cycleEnd);
                  d = d.add(const Duration(days: 1))
                ) {
                  partial += cyclePlan!.forDate(d).energy;
                }
                return Text(
                  l10n.midCycleNotice(
                    AppDates.md(today, locale),
                    AppDates.md(cycleEnd, locale),
                    '${partial.round()}',
                  ),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ],
          // ------------------------------------------------ issues
          if (issues.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.card),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      issue == StrategyIssue.amplitudeNegligible
                          ? Icons.info_outline
                          : Icons.error_outline,
                      size: 18,
                      color: issue == StrategyIssue.amplitudeNegligible
                          ? scheme.onSurfaceVariant
                          : scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.message(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: issue == StrategyIssue.amplitudeNegligible
                              ? scheme.onSurfaceVariant
                              : scheme.error,
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
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double snap(double v) => (v * 10).round() / 10;
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
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
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: s.stage == 0 ? visuals.accentSoft : visuals.card,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: visuals.cardBorder),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    l10n.taperStageLabel(s.stage),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${s.day.energy.round()} kcal · C ${s.day.carbG.toStringAsFixed(0)} g',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (s.stage == 0)
                  Text(l10n.currentStage, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
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
