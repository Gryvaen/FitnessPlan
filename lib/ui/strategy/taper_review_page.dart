import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/diet_strategy_repository.dart';
import '../../domain/calendar_day.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'strategy_fold_section.dart';
import 'strategy_labels.dart';
import 'strategy_target_card.dart';

/// Carb-taper stage control: every reachable stage's kcal/carbs, tap any of
/// them to switch. No observation window, no automatic review — the app
/// only calculates the numbers; when (or whether) to move stages is
/// entirely the user's call.
class TaperReviewPage extends ConsumerStatefulWidget {
  const TaperReviewPage({super.key});

  @override
  ConsumerState<TaperReviewPage> createState() => _TaperReviewPageState();
}

class _TaperReviewPageState extends ConsumerState<TaperReviewPage> {
  bool _busy = false;

  /// Sections open independently; several can be expanded at once.
  final Set<String> _openSections = {};

  void _toggle(String section) => setState(() {
    if (!_openSections.remove(section)) _openSections.add(section);
  });

  Future<void> _switchStage(DietStrategyPlan plan, int stage) async {
    final l10n = context.l10n;
    final target = CarbTaperStage.of(plan.baseline, stage);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enterStage(stage)),
        content: Text(
          l10n.confirmNextStageBody(
            target.day.energy.round(),
            target.day.carbG.toStringAsFixed(0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final tomorrow = CalendarDay.addDays(CalendarDay.todayLocal(), 1);
      final draft = DietStrategyPlanDraft(
        kind: DietStrategyKind.carbTaper,
        effectiveFrom: tomorrow,
        referenceWeightKg: plan.referenceWeightKg,
        estimatedTdee: plan.estimatedTdee,
        baseEnergy: plan.baseEnergy,
        proteinPerKg: plan.proteinPerKg,
        fatPerKg: plan.fatPerKg,
        taperStage: stage,
        observationStart: tomorrow,
        observationDays: StrategyRules.taperObservationDays,
        reason: 'manualStageChange',
        legacyCalories: plan.legacyCalories,
      );
      await ref.read(dietStrategyActionsProvider).applyPlan(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.taperStageConfirmed(stage))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final plan = ref.watch(activeDietPlanProvider).value;
    final plans = ref.watch(dietPlansProvider).value ?? const [];

    if (plan == null || plan.kind != DietStrategyKind.carbTaper) {
      return AppChromeScaffold(
        appBar: AppBar(title: Text(l10n.taperReview)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.formPage),
            child: Text(l10n.taperNotActive, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final baseline = plan.baseline;
    final current = CarbTaperStage.of(baseline, plan.taperStage);

    return AppChromeScaffold(
      appBar: AppBar(title: Text(l10n.taperReview)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          StrategyTargetCard(
            key: const ValueKey('taperOverviewCard'),
            title:
                '${plan.kind.label(l10n)} · '
                '${l10n.taperStageLabel(current.stage)}',
            status: l10n.strategyStatusActive,
            kcal: current.day.energy,
            kcalCaption: l10n.currentStage,
            proteinG: current.day.proteinG,
            carbG: current.day.carbG,
            fatG: current.day.fatG,
            footnote: l10n.planActiveSince(
              AppDates.md(plan.effectiveFrom, locale),
              appliedVersionNumber(plan, plans),
            ),
          ),
          StrategySectionHeader(
            key: const ValueKey('taperStageSection'),
            title: l10n.taperLadderTitle,
            hint: l10n.taperFreeChoiceHint,
          ),
          _StageLadder(
            baseline: baseline,
            currentStage: plan.taperStage,
            busy: _busy,
            onSelect: (stage) => _switchStage(plan, stage),
          ),
          const SizedBox(height: AppSpacing.section),
          StrategyFoldSection(
            key: const ValueKey('taperRulesSection'),
            title: l10n.strategyRulesTitle,
            summary: l10n.taperLadderHint,
            expanded: _openSections.contains('rules'),
            onTap: () => _toggle('rules'),
            leading: InkGlyph.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.taperRulesBody, style: theme.textTheme.meta),
                const SizedBox(height: AppSpacing.compact),
                Text(l10n.strategyDisclaimer, style: theme.textTheme.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every reachable stage before the carbohydrate minimum; tap one (other than the current
/// stage) to switch to it.
class _StageLadder extends StatelessWidget {
  const _StageLadder({
    required this.baseline,
    required this.currentStage,
    required this.busy,
    required this.onSelect,
  });

  final StrategyBaseline baseline;
  final int currentStage;
  final bool busy;
  final ValueChanged<int> onSelect;

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
        style: theme.textTheme.meta?.copyWith(color: theme.colorScheme.error),
      );
    }
    return Column(
      children: [
        for (final s in stages) ...[
          InkWell(
            key: ValueKey('taper-stage-${s.stage}'),
            onTap: busy || s.stage == currentStage
                ? null
                : () => onSelect(s.stage),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(right: AppSpacing.field),
                    decoration: BoxDecoration(
                      color: s.stage == currentStage
                          ? visuals.accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      l10n.taperStageLabel(s.stage),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: s.stage == currentStage ? visuals.accent : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${s.day.energy.round()} kcal · '
                      'C ${s.day.carbG.toStringAsFixed(0)} g',
                      style: theme.textTheme.rowTitle,
                    ),
                  ),
                  if (s.stage == currentStage)
                    InkIcon(
                      InkGlyph.radioChecked,
                      size: 18,
                      color: visuals.accent,
                    )
                  else
                    const InkIcon(InkGlyph.chevronRight, size: 18),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: visuals.divider),
        ],
        const SizedBox(height: AppSpacing.compact),
        Text(
          l10n.taperFloorLine(StrategyRules.minCarbG.round()),
          style: theme.textTheme.meta?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
