import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../../domain/strategy_eligibility.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/calorie_breakdown.dart';
import 'carb_cycle_view.dart';
import 'strategy_labels.dart';

/// Tab / swipe order for the three goals on this page.
const _goalOrder = [FitnessGoal.bulk, FitnessGoal.cut, FitnessGoal.maintain];

/// Profile → Nutrition targets: split into the three profile goals (增肌/
/// 减脂/维持) as tabs, swipeable like the rest of the app's tab groups. 减脂
/// keeps the full existing strategy flow; 增肌/维持 don't have a designed
/// strategy yet, so they show a placeholder in the same visual language
/// until one is built.
class NutritionTargetsPage extends ConsumerStatefulWidget {
  const NutritionTargetsPage({super.key});

  @override
  ConsumerState<NutritionTargetsPage> createState() =>
      _NutritionTargetsPageState();
}

class _NutritionTargetsPageState extends ConsumerState<NutritionTargetsPage> {
  late FitnessGoal _tab;

  @override
  void initState() {
    super.initState();
    _tab = ref.read(profileProvider)?.goal ?? FitnessGoal.cut;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppChromeScaffold(
      appBar: AppBar(title: Text(l10n.nutritionTargets)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoalTabRow(
            selected: _tab,
            items: {
              FitnessGoal.bulk: l10n.goalBulk,
              FitnessGoal.cut: l10n.goalCut,
              FitnessGoal.maintain: l10n.goalMaintain,
            },
            onSelected: (v) => setState(() => _tab = v),
          ),
          Expanded(
            child: SwipeTabView(
              index: _goalOrder.indexOf(_tab),
              onIndexChanged: (i) => setState(() => _tab = _goalOrder[i]),
              children: [
                for (final g in _goalOrder)
                  g == FitnessGoal.cut
                      ? const _CutNutritionTargets()
                      : _NutritionComingSoon(goal: g),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width goal tab row (增肌/减脂/维持 split evenly across the line) —
/// same underline-tab visuals as [SportTabs], but each segment is [Expanded]
/// instead of sized to its label, since there are exactly three fixed goals
/// here (unlike SportTabs' other, variable-length usages elsewhere).
class _GoalTabRow extends StatelessWidget {
  const _GoalTabRow({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final Map<FitnessGoal, String> items;
  final FitnessGoal selected;
  final ValueChanged<FitnessGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        AppSpacing.compact,
        AppSpacing.formPage,
        0,
      ),
      child: Row(
        children: [
          for (final entry in items.entries)
            Expanded(
              child: Semantics(
                selected: entry.key == selected,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(entry.key),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 3,
                          color: entry.key == selected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: entry.key == selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
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

/// 减脂 tab: the full, unchanged today's-target / strategy / calc-basis flow
/// (previously the entire page body).
class _CutNutritionTargets extends ConsumerWidget {
  const _CutNutritionTargets();

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
    final profile = ref.watch(profileProvider);
    final active = ref.watch(activeDietPlanProvider).value;
    final blocking = StrategyEligibility.check(profile);

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final today = AppDates.todayLocal();
    final activeStartsLater =
        active != null && active.effectiveFrom.isAfter(today);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        AppSpacing.compact,
        AppSpacing.formPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        // ------------------------------------------------ strategy card
        SportSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.dietStrategy,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: blocking.isEmpty
                        ? () => context.push('/profile/nutrition/strategy')
                        : null,
                    child: Text(
                      active == null
                          ? l10n.chooseStrategy
                          : l10n.changeStrategy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.field),
              _StrategyDescription(
                active: active,
                profile: profile,
                locale: locale,
                activeStartsLater: activeStartsLater,
              ),
              if (active?.kind == DietStrategyKind.carbCycle)
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(l10n.adjustSchedule),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/profile/nutrition/strategy/configure?kind=carbCycle',
                  ),
                ),
              if (active?.kind == DietStrategyKind.carbTaper)
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(l10n.taperReview),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/nutrition/taper'),
                ),
              if (active != null)
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: Text(
                    activeStartsLater
                        ? l10n.cancelScheduledStrategy
                        : l10n.stopStrategy,
                  ),
                  onTap: () => _stop(context, ref, pending: activeStartsLater),
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
          leading: Icon(
            Icons.calculate_outlined,
            color: scheme.onSurfaceVariant,
          ),
          title: Text(l10n.tdeeCalcMethod, style: theme.textTheme.titleSmall),
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
                    Text(
                      l10n.tdeeCalcMethod,
                      style: theme.textTheme.titleMedium,
                    ),
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
    );
  }
}

/// Collapsed by default — shows only 已选择/未选择 (plus the strategy kind
/// once one is picked); tap to reveal the full description (eligibility
/// copy, or the active plan's dates/baseline/carb-cycle week / taper
/// summary).
class _StrategyDescription extends StatefulWidget {
  const _StrategyDescription({
    required this.active,
    required this.profile,
    required this.locale,
    required this.activeStartsLater,
  });

  final DietStrategyPlan? active;
  final UserProfile profile;
  final Locale locale;
  final bool activeStartsLater;

  @override
  State<_StrategyDescription> createState() => _StrategyDescriptionState();
}

class _StrategyDescriptionState extends State<_StrategyDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = widget.active;
    final summary = active == null
        ? l10n.noStrategyShort
        : '${l10n.strategySelectedShort} · ${active.kind.label(l10n)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.field),
          if (active == null)
            Text(
              widget.profile.goal == FitnessGoal.cut
                  ? l10n.noStrategyYet
                  : l10n.strategyOnlyForCut,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            Text(active.kind.label(l10n), style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              widget.activeStartsLater
                  ? l10n.planStartsOn(
                      AppDates.md(active.effectiveFrom, widget.locale),
                    )
                  : l10n.planActiveSince(
                      AppDates.md(active.effectiveFrom, widget.locale),
                      active.version,
                    ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              active.kind == DietStrategyKind.carbCycle
                  ? l10n.carbCyclePlanSummaryLine(
                      active.referenceWeightKg.toStringAsFixed(1),
                      '${active.schedule?.cycleLengthDays ?? 0}',
                      '${active.baseEnergy.round()}',
                    )
                  : l10n.planBaselineLine(
                      active.referenceWeightKg.toStringAsFixed(1),
                      '${active.estimatedTdee.round()}',
                      '${active.baseEnergy.round()}',
                    ),
              style: theme.textTheme.bodySmall,
            ),
            if (active.kind == DietStrategyKind.carbCycle &&
                active.carbCyclePlan != null) ...[
              const SizedBox(height: AppSpacing.section),
              CarbCycleView(
                key: ValueKey('active-${active.id}'),
                plan: active.carbCyclePlan!,
                cycleStart: active.effectiveFrom,
              ),
            ],
            if (active.kind == DietStrategyKind.carbTaper) ...[
              const SizedBox(height: AppSpacing.compact),
              _TaperSummary(plan: active),
            ],
          ],
        ],
      ],
    );
  }
}

/// 增肌/维持 tab placeholder: no strategy has been designed for these goals
/// yet — shown in the page's normal card-list language (not the 修仙-style
/// full-bleed art) so it reads as "part of this page", not a different app.
class _NutritionComingSoon extends StatelessWidget {
  const _NutritionComingSoon({required this.goal});

  final FitnessGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        AppSpacing.compact,
        AppSpacing.formPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        SportEmptyState(
          icon: Icons.construction_outlined,
          title: l10n.nutritionComingSoonTitle(goal.label(l10n)),
          message: l10n.nutritionComingSoonBody,
        ),
      ],
    );
  }
}

class _TaperSummary extends StatelessWidget {
  const _TaperSummary({required this.plan});

  final DietStrategyPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stage = CarbTaperStage.of(plan.baseline, plan.taperStage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.taperStageLabel(stage.stage)} · '
          '${stage.day.energy.round()} kcal · C ${stage.day.carbG.toStringAsFixed(0)} g',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
