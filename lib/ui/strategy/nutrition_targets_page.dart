import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../../domain/strategy_eligibility.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/calorie_breakdown.dart';
import 'carb_cycle_week_view.dart';
import 'strategy_labels.dart';

/// Profile → Nutrition targets: today's target, the active strategy and
/// the calculation basis. Entry point for the fat-loss strategy flow.
class NutritionTargetsPage extends ConsumerWidget {
  const NutritionTargetsPage({super.key});

  Future<void> _stop(
    BuildContext context,
    WidgetRef ref, {
    required bool pending,
  }) async {
    final l10n = context.l10n;
    final title = pending ? l10n.cancelScheduledStrategy : l10n.stopStrategy;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          pending ? l10n.cancelScheduledStrategyBody : l10n.stopStrategyBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(title),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(dietStrategyRepositoryProvider).stopActivePlan();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pending ? l10n.scheduledStrategyCancelled : l10n.strategyStopped,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final profile = ref.watch(profileProvider);
    final todayTarget = ref.watch(todayTargetProvider).value;
    final active = ref.watch(activeDietPlanProvider).value;
    final blocking = StrategyEligibility.check(profile);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final today = AppDates.todayLocal();
    final activeStartsLater =
        active != null && active.effectiveFrom.isAfter(today);

    return AppChromeScaffold(
      appBar: AppBar(
        title: Text(l10n.nutritionTargets),
        actions: [
          if (blocking.isEmpty)
            TextButton(
              onPressed: () => context.push('/profile/nutrition/strategy'),
              child: Text(l10n.adjustStrategy),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          // ------------------------------------------------ today's target
          SportHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.todaysTarget,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: visuals.onHero,
                      ),
                    ),
                    if (todayTarget != null)
                      SoftChip(
                        label: targetChipLabel(todayTarget, profile, l10n),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${todayTarget?.caloriesRounded ?? profile.targets.calories}',
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
                const SizedBox(height: 6),
                Text(
                  'P ${(todayTarget?.proteinG ?? profile.targets.proteinG).toStringAsFixed(0)} · '
                  'C ${(todayTarget?.carbG ?? profile.targets.carbG).toStringAsFixed(0)} · '
                  'F ${(todayTarget?.fatG ?? profile.targets.fatG).toStringAsFixed(0)} g',
                  style: theme.textTheme.meta?.copyWith(
                    color: visuals.onHeroMuted,
                  ),
                ),
                if (todayTarget?.plannedDeficit != null &&
                    todayTarget!.plannedDeficit! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.dailyDeficitLine(
                      '${todayTarget.plannedDeficit!.round()}',
                    ),
                    style: theme.textTheme.meta?.copyWith(
                      color: visuals.onHeroMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          // ------------------------------------------------ strategy card
          SportSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dietStrategy, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                if (active == null) ...[
                  Text(
                    profile.goal == FitnessGoal.cut
                        ? l10n.noStrategyYet
                        : l10n.strategyOnlyForCut,
                    style: theme.textTheme.bodyMedium,
                  ),
                ] else ...[
                  Text(
                    active.kind.label(l10n),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeStartsLater
                        ? l10n.planStartsOn(
                            AppDates.md(active.effectiveFrom, locale),
                          )
                        : l10n.planActiveSince(
                            AppDates.md(active.effectiveFrom, locale),
                            active.version,
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.planBaselineLine(
                      active.referenceWeightKg.toStringAsFixed(1),
                      '${active.estimatedTdee.round()}',
                      '${active.baseEnergy.round()}',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (active.kind == DietStrategyKind.carbCycle &&
                      active.carbCyclePlan != null) ...[
                    const SizedBox(height: AppSpacing.section),
                    CarbCycleWeekView(
                      key: ValueKey('active-${active.id}'),
                      plan: active.carbCyclePlan!,
                    ),
                  ],
                  if (active.kind == DietStrategyKind.carbTaper) ...[
                    const SizedBox(height: AppSpacing.compact),
                    _TaperSummary(plan: active),
                  ],
                ],
                const SizedBox(height: AppSpacing.card),
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    active == null ? l10n.chooseStrategy : l10n.changeStrategy,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: blocking.isEmpty
                      ? () => context.push('/profile/nutrition/strategy')
                      : null,
                ),
                if (active?.kind == DietStrategyKind.carbCycle)
                  SportListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adjustSchedule),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/profile/nutrition/strategy/configure?kind=carbCycle',
                    ),
                  ),
                if (active?.kind == DietStrategyKind.carbTaper)
                  SportListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.taperReview),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/nutrition/taper'),
                  ),
                if (active != null)
                  SportListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      activeStartsLater
                          ? l10n.cancelScheduledStrategy
                          : l10n.stopStrategy,
                    ),
                    onTap: () =>
                        _stop(context, ref, pending: activeStartsLater),
                  ),
                if (blocking.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.compact),
                  for (final i in blocking)
                    Text(
                      i.message(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          // ------------------------------------------------ basis
          SportListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calcMethod, style: theme.textTheme.titleSmall),
            subtitle: Text(
              active != null
                  ? l10n.planBaselineLine(
                      active.referenceWeightKg.toStringAsFixed(1),
                      '${active.estimatedTdee.round()}',
                      '${active.baseEnergy.round()}',
                    )
                  : l10n.baseTargetLine('${profile.targets.calories}'),
              style: theme.textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.formPage),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.calcMethod, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.field),
                      CalorieBreakdown(plan: plan, compact: true),
                      const SizedBox(height: AppSpacing.compact),
                      Text(
                        l10n.strategyBasisBody,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.strategyDisclaimer,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaperSummary extends ConsumerWidget {
  const _TaperSummary({required this.plan});

  final DietStrategyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stage = CarbTaperStage.of(plan.baseline, plan.taperStage);
    final review = ref.watch(taperReviewProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.taperStageLabel(stage.stage)} · '
          '${stage.day.energy.round()} kcal · C ${stage.day.carbG.toStringAsFixed(0)} g',
          style: theme.textTheme.bodyMedium,
        ),
        if (review != null)
          Text(review.status.label(l10n), style: theme.textTheme.bodySmall),
      ],
    );
  }
}
