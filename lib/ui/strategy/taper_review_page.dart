import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/diet_strategy_repository.dart';
import '../../domain/calendar_day.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'strategy_labels.dart';

/// Carb-taper review: current stage, observation progress, data
/// completeness and the hold / step-down decision. Nothing changes without
/// an explicit confirmation here.
class TaperReviewPage extends ConsumerStatefulWidget {
  const TaperReviewPage({super.key});

  @override
  ConsumerState<TaperReviewPage> createState() => _TaperReviewPageState();
}

class _TaperReviewPageState extends ConsumerState<TaperReviewPage> {
  bool _busy = false;

  /// New version from tomorrow with [stage]; observation restarts.
  Future<void> _confirmStage(
    DietStrategyPlan plan,
    int stage,
    String reason,
  ) async {
    final l10n = context.l10n;
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
        reason: reason,
        legacyCalories: plan.legacyCalories,
      );
      await ref.read(dietStrategyRepositoryProvider).createPlan(draft);
      ref.invalidate(taperReviewProvider);
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

  Future<void> _ask(
    DietStrategyPlan plan,
    int stage,
    String title,
    String body,
    String reason,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    if (ok == true) await _confirmStage(plan, stage, reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final plan = ref.watch(activeDietPlanProvider).value;
    final reviewAsync = ref.watch(taperReviewProvider);

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
    final next = CarbTaperPlanner.nextStage(baseline, plan.taperStage);
    final review = reviewAsync.value;

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
          SportHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.currentStage} · ${l10n.taperStageLabel(current.stage)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: visuals.onHero,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${current.day.energy.round()}',
                      style: theme.textTheme.statValue?.copyWith(
                        color: visuals.onHero,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'kcal',
                      style: theme.textTheme.statUnit?.copyWith(
                        color: visuals.onHeroMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'P ${current.day.proteinG.toStringAsFixed(0)} · '
                  'C ${current.day.carbG.toStringAsFixed(0)} · '
                  'F ${current.day.fatG.toStringAsFixed(0)} g',
                  style: theme.textTheme.meta?.copyWith(
                    color: visuals.onHeroMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.planActiveSince(
                    AppDates.md(plan.effectiveFrom, locale),
                    plan.version,
                  ),
                  style: theme.textTheme.meta?.copyWith(
                    color: visuals.onHeroMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          if (review == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            SportSurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.observation, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.compact),
                  SportProgressBar(
                    value: review.daysRequired <= 0
                        ? 1
                        : review.daysObserved / review.daysRequired,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.observationProgress(
                      review.daysObserved.clamp(0, review.daysRequired),
                      review.daysRequired,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    l10n.nextReviewDate(
                      AppDates.md(review.nextReviewDate, locale),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Divider(height: 20),
                  _DataRow(
                    label: l10n.weighInDays,
                    value:
                        '${review.weightDays} / ${StrategyRules.reviewWindowDays}',
                    ok:
                        review.weightDays >=
                            StrategyRules.reviewMinWeightDays &&
                        review.earlyWeightDays >=
                            StrategyRules.reviewMinWeightDaysPerHalf &&
                        review.lateWeightDays >=
                            StrategyRules.reviewMinWeightDaysPerHalf,
                    hint: l10n.weighInDaysHint(
                      StrategyRules.reviewMinWeightDays,
                      StrategyRules.reviewMinWeightDaysPerHalf,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DataRow(
                    label: l10n.completeDietDays,
                    value:
                        '${review.completeDietDays} / ${StrategyRules.reviewWindowDays}',
                    ok:
                        review.completeDietDays >=
                        StrategyRules.reviewMinCompleteDietDays,
                    hint: l10n.completeDietDaysHint(
                      StrategyRules.reviewMinCompleteDietDays,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DataRow(
                    label: l10n.weeklyRate,
                    value: review.weeklyRate == null
                        ? '–'
                        : '${(review.weeklyRate! * 100).toStringAsFixed(2)}%',
                    ok: review.weeklyRate != null,
                    hint: l10n.weeklyRateHint(
                      (StrategyRules.weeklyLossLowerBound * 100)
                          .toStringAsFixed(2),
                      (StrategyRules.weeklyLossUpperBound * 100)
                          .toStringAsFixed(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SportSurfaceCard(
              tint: switch (review.status) {
                TaperReviewStatus.stepDownCandidate => visuals.accent,
                TaperReviewStatus.rateTooHigh => scheme.error,
                _ => null,
              },
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.suggestion, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    review.status.label(l10n),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusBody(review, next, l10n),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (review.canStepDown && next != null)
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _ask(
                                  plan,
                                  next.stage,
                                  l10n.confirmNextStage,
                                  l10n.confirmNextStageBody(
                                    next.day.energy.round(),
                                    next.day.carbG.toStringAsFixed(0),
                                  ),
                                  'stepDownConfirmed',
                                ),
                          child: Text(l10n.enterStage(next.stage)),
                        ),
                      if (review.status == TaperReviewStatus.hold ||
                          review.status ==
                              TaperReviewStatus.stepDownCandidate ||
                          review.status == TaperReviewStatus.floorReached)
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _ask(
                                  plan,
                                  plan.taperStage,
                                  l10n.keepStage,
                                  l10n.keepStageBody,
                                  'holdConfirmed',
                                ),
                          child: Text(l10n.keepStage),
                        ),
                      if (review.status == TaperReviewStatus.rateTooHigh &&
                          plan.taperStage > 0)
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _ask(
                                  plan,
                                  plan.taperStage - 1,
                                  l10n.backOneStage,
                                  l10n.backOneStageBody,
                                  'stepUpConfirmed',
                                ),
                          child: Text(l10n.backOneStage),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          Text(l10n.taperRulesBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(l10n.strategyDisclaimer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _statusBody(
    TaperReviewResult r,
    CarbTaperStage? next,
    AppLocalizations l10n,
  ) {
    switch (r.status) {
      case TaperReviewStatus.observing:
        return l10n.taperObservingBody(r.daysRequired - r.daysObserved);
      case TaperReviewStatus.insufficientWeightData:
        return l10n.taperInsufficientWeightBody;
      case TaperReviewStatus.insufficientDietData:
        return l10n.taperInsufficientDietBody;
      case TaperReviewStatus.hold:
        return l10n.taperHoldBody;
      case TaperReviewStatus.stepDownCandidate:
        return next == null
            ? l10n.taperFloorBody
            : l10n.taperStepDownBody(
                next.day.energy.round(),
                next.day.carbG.toStringAsFixed(0),
              );
      case TaperReviewStatus.floorReached:
        return l10n.taperFloorBody;
      case TaperReviewStatus.rateTooHigh:
        return l10n.taperTooFastBody;
    }
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
    required this.ok,
    required this.hint,
  });

  final String label;
  final String value;
  final bool ok;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? visuals.accent : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(hint, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
