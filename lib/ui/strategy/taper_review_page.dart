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
  String? _openSection;

  void _toggle(String section) => setState(() {
    _openSection = _openSection == section ? null : section;
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
      final tomorrow = CalendarDay.todayLocal().add(const Duration(days: 1));
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
    final visuals = AppThemeVisuals.of(context);
    final plan = ref.watch(activeDietPlanProvider).value;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '${l10n.currentStage} · ${l10n.taperStageLabel(current.stage)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${current.day.energy.round()} kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: visuals.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          Text(
            'P ${current.day.proteinG.toStringAsFixed(0)} · '
            'C ${current.day.carbG.toStringAsFixed(0)} · '
            'F ${current.day.fatG.toStringAsFixed(0)} g',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            l10n.planActiveSince(
              AppDates.md(plan.effectiveFrom, locale),
              plan.version,
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.card),
          StrategyFoldSection(
            key: const ValueKey('taperStageSection'),
            title: l10n.taperLadderTitle,
            summary: l10n.taperFreeChoiceHint,
            expanded: _openSection == 'stages',
            onTap: () => _toggle('stages'),
            leading: InkGlyph.chart,
            child: _StageLadder(
              baseline: baseline,
              currentStage: plan.taperStage,
              busy: _busy,
              onSelect: (stage) => _switchStage(plan, stage),
            ),
          ),
          StrategyFoldSection(
            key: const ValueKey('taperRulesSection'),
            title: l10n.strategyRulesTitle,
            summary: l10n.taperLadderHint,
            expanded: _openSection == 'rules',
            onTap: () => _toggle('rules'),
            leading: InkGlyph.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.taperRulesBody, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.compact),
                Text(l10n.strategyDisclaimer, style: theme.textTheme.bodySmall),
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
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
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
                      style: theme.textTheme.bodyMedium,
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
        Text(
          l10n.taperFloorLine(StrategyRules.minCarbG.round()),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
