import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/cycle_history.dart';
import '../../domain/day_marker.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../../domain/strategy_eligibility.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/calorie_breakdown.dart';
import 'carb_cycle_view.dart';
import 'maintain_sections.dart';
import 'strategy_labels.dart';
import 'strategy_target_card.dart';

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
                  switch (g) {
                    FitnessGoal.cut => const _CutTab(),
                    FitnessGoal.maintain => const _MaintainTab(),
                    FitnessGoal.bulk => _NutritionComingSoon(goal: g),
                  },
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
    final activeAsync = ref.watch(activeDietPlanProvider);
    final active = activeAsync.value;
    final blocking = StrategyEligibility.check(profile);

    // Don't flash the "no strategy" empty state while the plan loads.
    if (profile == null || !activeAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final today = AppDates.todayLocal();
    final activeStartsLater =
        active != null && active.effectiveFrom.isAfter(today);
    final isCarbCycle = active?.kind == DietStrategyKind.carbCycle;
    final restDayDates = isCarbCycle
        ? ref.watch(restDayDatesProvider).value ?? const <DateTime>[]
        : const <DateTime>[];
    final cycleAnchors = isCarbCycle
        ? cycleAnchorsOf(
            ref.watch(cycleSnapshotsProvider).value ?? const [],
            active!.id,
          )
        : const <CycleAnchor>[];
    final todayTarget = ref.watch(todayTargetProvider).value;
    final plans = ref.watch(dietPlansProvider).value ?? const [];
    final todayMarker = isCarbCycle
        ? ref.watch(dayMarkerProvider(today)).value
        : null;

    final blockingNotes = [
      for (final i in blocking)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.compact),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkIcon(InkGlyph.info, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: Text(
                  i.message(l10n),
                  style: theme.textTheme.meta?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
    // TDEE doesn't depend on the goal, so the row shows on every goal's
    // strategy tab, active or not.
    final tdeeTile = _TdeeCalcMethodTile(profile: profile);
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.formPage,
      AppSpacing.compact,
      AppSpacing.formPage,
      listBottomInset(context, hasFab: false),
    );

    if (active == null) {
      return ListView(
        padding: padding,
        children: [
          SportEmptyState(
            key: const ValueKey('noStrategyEmpty'),
            iconWidget: InkIcon(
              InkGlyph.target,
              size: 40,
              color: AppThemeVisuals.of(context).accent,
            ),
            title: l10n.noStrategyForGoal(FitnessGoal.cut.label(l10n)),
            message: l10n.noStrategyYet,
            actionLabel: l10n.chooseStrategy,
            onAction: blocking.isEmpty
                ? () => context.push('/profile/nutrition/strategy')
                : null,
          ),
          ...blockingNotes,
          const SizedBox(height: AppSpacing.section),
          tdeeTile,
        ],
      );
    }

    final card = _overviewCard(
      context,
      active: active,
      plans: plans,
      startsLater: activeStartsLater,
      today: today,
      todayTarget: todayTarget,
      todayMarker: todayMarker,
      locale: locale,
    );
    final basisDeficit = active.kind != DietStrategyKind.carbCycle;

    return ListView(
      padding: padding,
      children: [
        card,
        ...blockingNotes,
        if (active.kind == DietStrategyKind.carbTaper) ...[
          const SizedBox(height: AppSpacing.compact),
          StrategyActionRow(
            icon: InkGlyph.factCheck,
            label: l10n.taperReview,
            onTap: () => context.push('/profile/nutrition/taper'),
          ),
        ],
        if (isCarbCycle && active.carbCyclePlan != null) ...[
          StrategySectionHeader(
            title: l10n.cycleSchedule,
            hint: l10n.cycleLengthDaysOption(
              active.schedule?.cycleLengthDays ?? 0,
            ),
          ),
          KeyedSubtree(
            key: const ValueKey('activeCyclePreview'),
            child: CarbCycleView(
              key: ValueKey('active-${active.id}'),
              plan: active.carbCyclePlan!,
              cycleStart: active.effectiveFrom,
              cycleStartIndex: active.cycleStartIndex,
              restDayDates: restDayDates,
              anchors: cycleAnchors,
              markers: ref.watch(upcomingDayMarkersProvider).value ?? const {},
              windowStart: activeStartsLater ? active.effectiveFrom : today,
            ),
          ),
          const SizedBox(height: AppSpacing.compact),
          StrategyActionRow(
            icon: InkGlyph.calendar,
            label: l10n.adjustSchedule,
            onTap: () => context.push(
              '/profile/nutrition/strategy/configure?kind=carbCycle',
            ),
          ),
        ],
        StrategySectionHeader(
          title: l10n.strategySavedBasis,
          hint: active.kind.description(l10n),
        ),
        StrategyFactRow(
          label: l10n.referenceWeightKg,
          value: active.referenceWeightKg.toStringAsFixed(1),
          unit: 'kg',
        ),
        StrategyFactRow(
          label: l10n.estimatedTdee,
          value: '${active.estimatedTdee.round()}',
          unit: 'kcal',
        ),
        StrategyFactRow(
          label: l10n.averageTargetEnergy,
          value: '${active.baseEnergy.round()}',
          unit: 'kcal',
        ),
        if (basisDeficit)
          StrategyFactRow(
            label: l10n.deficitFractionLabel,
            value: l10n.deficitFractionPercent(
              (active.deficitFraction * 100).round(),
            ),
          ),
        tdeeTile,
        StrategySectionHeader(title: l10n.strategyManageTitle),
        // Straight to the active strategy's configure page (it loads the
        // current parameters), skipping the picker.
        StrategyActionRow(
          key: const ValueKey('adjustStrategyAction'),
          icon: InkGlyph.edit,
          label: l10n.adjustStrategy,
          onTap: blocking.isEmpty
              ? () => context.push(
                  '/profile/nutrition/strategy/configure?kind=${active.kind.name}',
                )
              : null,
        ),
        StrategyActionRow(
          icon: InkGlyph.swapHorizontal,
          label: l10n.changeStrategy,
          onTap: blocking.isEmpty
              ? () => context.push('/profile/nutrition/strategy')
              : null,
        ),
        StrategyActionRow(
          key: const ValueKey('stopStrategyAction'),
          icon: InkGlyph.stop,
          label: activeStartsLater
              ? l10n.cancelScheduledStrategy
              : l10n.stopStrategy,
          destructive: true,
          showChevron: false,
          onTap: () => _stop(context, ref, pending: activeStartsLater),
        ),
      ],
    );
  }

  /// Today's governing target (or the first day of a scheduled plan) as the
  /// page's one hero card.
  Widget _overviewCard(
    BuildContext context, {
    required DietStrategyPlan active,
    required List<DietStrategyPlan> plans,
    required bool startsLater,
    required DateTime today,
    required DailyNutritionTarget? todayTarget,
    required DayMarkerType? todayMarker,
    required Locale locale,
  }) {
    final l10n = context.l10n;
    final day = startsLater ? active.effectiveFrom : today;
    // Prefer the resolved snapshot (it knows rest-day pauses and 冲碳日);
    // fall back to the plan's own formula for a scheduled first day.
    final snapshot =
        !startsLater &&
            todayTarget != null &&
            todayTarget.source == TargetSource.strategy &&
            todayTarget.planId == active.id
        ? todayTarget
        : null;
    final planDay = active.targetFor(day);
    final kcal = snapshot?.calories ?? planDay.energy;
    final p = snapshot?.proteinG ?? planDay.proteinG;
    final c = snapshot?.carbG ?? planDay.carbG;
    final f = snapshot?.fatG ?? planDay.fatG;

    String? dayLabel;
    switch (active.kind) {
      case DietStrategyKind.balanced:
        dayLabel = null;
      case DietStrategyKind.carbCycle:
        if (snapshot != null && snapshot.isCarbLoad) {
          dayLabel = l10n.carbLoadLabel;
        } else if (snapshot?.cyclePaused == true) {
          dayLabel = (todayMarker ?? DayMarkerType.restDay).label(l10n);
        } else {
          dayLabel = (snapshot?.dayType ?? planDay.dayType).label(l10n);
        }
      case DietStrategyKind.carbTaper:
        dayLabel = l10n.taperStageLabel(active.taperStage);
    }
    final caption = startsLater
        ? l10n.firstDayCaption(AppDates.md(day, locale))
        : dayLabel == null
        ? l10n.todayWord
        : l10n.todayDayTypeCaption(dayLabel);

    return StrategyTargetCard(
      key: const ValueKey('strategyOverviewCard'),
      title: l10n.strategyCardTitle(
        active.kind.label(l10n),
        appliedVersionNumber(active, plans),
      ),
      status: startsLater
          ? l10n.strategyStatusScheduled
          : l10n.strategyStatusActive,
      kcal: kcal,
      kcalCaption: caption,
      proteinG: p,
      carbG: c,
      fatG: f,
      footnote: l10n.strategyAvgSinceLine(
        '${active.baseEnergy.round()}',
        AppDates.md(active.effectiveFrom, locale),
      ),
    );
  }
}

/// 减脂 tab. On another goal there is no active fat-loss strategy, so it
/// shows the same "no strategy" state; applying one switches the goal to cut.
class _CutTab extends StatelessWidget {
  const _CutTab();

  @override
  Widget build(BuildContext context) => const _CutNutritionTargets();
}

/// 维持 tab, on the cut tab's path: "no strategy" → pick 均衡维持 (the only
/// one) → configure → apply, which switches the goal to maintain. While the
/// goal is maintain that strategy is in force and the tab shows it.
class _MaintainTab extends ConsumerWidget {
  const _MaintainTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final pending = ref.watch(pendingGoalSwitchProvider);
    if (profile.goal != FitnessGoal.maintain &&
        pending?.goal == FitnessGoal.maintain) {
      return MaintainScheduledView(
        profile: profile,
        from: pending!.from,
        tdeeTile: _TdeeCalcMethodTile(profile: profile),
      );
    }
    if (profile.goal != FitnessGoal.maintain) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          SportEmptyState(
            key: const ValueKey('noMaintainStrategyEmpty'),
            iconWidget: InkIcon(
              InkGlyph.target,
              size: 40,
              color: AppThemeVisuals.of(context).accent,
            ),
            title: context.l10n.noStrategyForGoal(
              FitnessGoal.maintain.label(context.l10n),
            ),
            message: context.l10n.noStrategyYet,
            actionLabel: context.l10n.chooseStrategy,
            onAction: () => context.push('/profile/nutrition/maintain'),
          ),
          const SizedBox(height: AppSpacing.section),
          _TdeeCalcMethodTile(profile: profile),
        ],
      );
    }
    return MaintainTargetsView(
      profile: profile,
      tdeeTile: _TdeeCalcMethodTile(profile: profile),
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
          iconWidget: const InkIcon(InkGlyph.construction),
          title: l10n.nutritionComingSoonTitle(goal.label(l10n)),
          message: l10n.nutritionComingSoonBody,
        ),
        if (showTdee) ...[
          const SizedBox(height: AppSpacing.section),
          _TdeeCalcMethodTile(profile: profile),
        ],
      ],
    );
  }
}

/// Shared "TDEE 计算方法" row: summary always visible; full breakdown opens
/// in a bottom sheet (hidden until the user asks for it).
class _TdeeCalcMethodTile extends ConsumerWidget {
  const _TdeeCalcMethodTile({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    return SportListTile(
      contentPadding: EdgeInsets.zero,
      leading: InkIcon(
        InkGlyph.calculator,
        color: AppThemeVisuals.of(context).accent,
      ),
      title: Text(l10n.tdeeCalcMethod, style: theme.textTheme.rowTitle),
      subtitle: Text(
        '${l10n.currentWeight} ${profile.weightKg.toStringAsFixed(1)} kg · '
        '${l10n.estimatedTdee} ${plan.tdee.round()} kcal',
        style: theme.textTheme.meta,
      ),
      trailing: const InkIcon(InkGlyph.chevronRight),
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
                Text(l10n.tdeeCalcMethod, style: theme.textTheme.sectionTitle),
                const SizedBox(height: AppSpacing.field),
                CalorieBreakdown(plan: plan, compact: true),
                const SizedBox(height: AppSpacing.compact),
                Text(l10n.strategyBasisBody, style: theme.textTheme.meta),
                const SizedBox(height: 6),
                Text(l10n.strategyDisclaimer, style: theme.textTheme.meta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
