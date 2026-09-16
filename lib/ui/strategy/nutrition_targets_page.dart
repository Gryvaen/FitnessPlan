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
              keepPagesAlive: true,
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
    await ref.read(dietStrategyActionsProvider).cancelPlan();
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
        // ------------------------------------------------ strategy
        SportListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.local_fire_department_outlined,
            color: Color(0xFFF97316),
          ),
          title: Text(l10n.dietStrategy, style: theme.textTheme.titleSmall),
          subtitle: Text(
            active == null
                ? l10n.noStrategyShort
                : '${l10n.strategySelectedShort} · ${active.kind.label(l10n)}',
            style: theme.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: blocking.isEmpty
              ? () => context.push('/profile/nutrition/strategy')
              : null,
        ),
        _StrategyDescription(
          active: active,
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
            leading: const Icon(Icons.stop_outlined),
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
        // TDEE only on the tab that matches the profile goal.
        if (profile.goal == FitnessGoal.cut)
          _TdeeCalcMethodTile(profile: profile, active: active),
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
    required this.locale,
    required this.activeStartsLater,
  });

  final DietStrategyPlan? active;
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
    if (active == null) return const SizedBox.shrink();

    // Summary lives on the parent SportListTile; this block only expands
    // the longer plan details.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    active.kind.description(l10n),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
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
        ),
        if (_expanded) ...[
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
          const SizedBox(height: AppSpacing.field),
        ],
      ],
    );
  }
}

/// 增肌/维持 tab: strategy playbooks are still TBD. TDEE is only shown when
/// this tab matches the profile's current goal (the other two stay hidden).
class _NutritionComingSoon extends ConsumerWidget {
  const _NutritionComingSoon({required this.goal});

  final FitnessGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final showTdee = profile.goal == goal;
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
        if (showTdee) ...[
          const SizedBox(height: AppSpacing.section),
          _TdeeCalcMethodTile(profile: profile, active: null),
        ],
      ],
    );
  }
}

/// Shared "TDEE 计算方法" row: summary always visible; full breakdown opens
/// in a bottom sheet (hidden until the user asks for it).
class _TdeeCalcMethodTile extends ConsumerWidget {
  const _TdeeCalcMethodTile({
    required this.profile,
    required this.active,
  });

  final UserProfile profile;
  final DietStrategyPlan? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    return SportListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.calculate_outlined,
        color: AppThemeVisuals.of(context).accent,
      ),
      title: Text(l10n.tdeeCalcMethod, style: theme.textTheme.titleSmall),
      subtitle: Text(
        active != null
            ? l10n.planBaselineLine(
                active!.referenceWeightKg.toStringAsFixed(1),
                '${active!.estimatedTdee.round()}',
                '${active!.baseEnergy.round()}',
              )
            : l10n.baseTargetLine('${plan.targets.calories}'),
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
                Text(l10n.tdeeCalcMethod, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.field),
                CalorieBreakdown(plan: plan, compact: true),
                const SizedBox(height: AppSpacing.compact),
                Text(l10n.strategyBasisBody, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(l10n.strategyDisclaimer, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
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
