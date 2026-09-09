import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/calorie_calculator.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../../domain/plateau.dart';
import '../../data/services/steps_sync_service.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../strategy/strategy_labels.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'deficit_date_picker.dart';
import 'today_section_header.dart';
import 'today_summary_widgets.dart';
import 'today_workout_card.dart';

/// One water serving per cup / lid tap (ml).
const int kWaterServingMl = 250;

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  // Both blocks start collapsed and are independent of each other; they
  // reset whenever the selected day changes.
  bool _workoutExpanded = false;
  bool _mealsExpanded = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(selectedDayProvider, (prev, next) {
      if (prev != next && (_workoutExpanded || _mealsExpanded)) {
        setState(() {
          _workoutExpanded = false;
          _mealsExpanded = false;
        });
      }
    });

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final profile = ref.watch(profileProvider);
    final intake = ref.watch(todayIntakeProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final day = ref.watch(selectedDayProvider);
    final weightLogs = ref.watch(weightLogsProvider).value ?? const [];
    final targetAsync = ref.watch(selectedDayTargetProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final onHero = visuals.onHero;
    final onHeroMuted = visuals.onHeroMuted;
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);

    // Single per-date target source; fall back to the profile target only
    // while the first resolution is in flight.
    final dayTarget = targetAsync.value;
    final targets = dayTarget?.toMacroTargets() ?? profile.targets;
    final targetCalories = dayTarget?.calories ?? targets.calories.toDouble();
    final remainCal = targetCalories - intake.calories;
    final waterMl = ref.watch(waterMlProvider).value ?? 0;
    final waterGoal = ref.watch(waterGoalProvider);
    final steps = ref.watch(stepsForSelectedDayProvider).value ?? 0;
    final dietComplete = ref.watch(dayDietCompleteProvider(day)).value;

    final onPlateau =
        profile.goal == FitnessGoal.cut &&
        dayTarget?.source != TargetSource.strategy &&
        Plateau.detect(
          weightLogs.map((e) => (date: e.date, weightKg: e.weightKg)).toList(),
        );
    final canCutMore =
        profile.calorieAdjustment < CalorieCalculator.maxCalorieAdjustment;

    final now = DateTime.now();
    final today = AppDates.todayLocal(now);
    final earliest = DateTime(today.year - 1, today.month, today.day);
    final isSelectedToday = AppDates.isLocalToday(day, now);
    final canGoPrev = day.isAfter(earliest);
    final canGoNext = day.isBefore(today);
    final dayLabel = day.year == today.year
        ? AppDates.md(day, locale)
        : AppDates.ymd(day, locale);
    final sectionPrefix = isSelectedToday ? l10n.today : l10n.sectionThatDay;

    final plannedDeficit = dayTarget?.plannedDeficit ?? plan.dailyDeficit;
    final strategyLabel = dayTarget == null
        ? null
        : targetChipLabel(dayTarget, profile, l10n);

    final canAddWater = isSelectedToday;
    final canUndoWater = isSelectedToday && waterMl > 0;

    return AppChromeScaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final repo = ref.read(dietStrategyRepositoryProvider);
            final picked = await showDeficitDatePicker(
              context: context,
              initialDate: day,
              firstDate: earliest,
              lastDate: today,
              plannedDeficit: plannedDeficit,
              mealRepository: ref.read(mealRepositoryProvider),
              loadTargets: (start, end) =>
                  repo.targetsBetween(start, end, profile),
              calorieStandardSince: profile.calorieStandardSince,
            );
            if (picked == null) return;
            ref.read(selectedDayProvider.notifier).setDay(picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dayLabel),
                const SizedBox(width: 4),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.prevDay,
            onPressed: canGoPrev
                ? () => ref
                      .read(selectedDayProvider.notifier)
                      .shiftDay(-1, earliest: earliest)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: l10n.todayWord,
            onPressed: isSelectedToday
                ? null
                : () => ref.read(selectedDayProvider.notifier).goToToday(),
            icon: const Icon(Icons.today),
          ),
          IconButton(
            tooltip: l10n.nextDay,
            onPressed: canGoNext
                ? () => ref
                      .read(selectedDayProvider.notifier)
                      .shiftDay(1, earliest: earliest)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.listPage,
          8,
          AppSpacing.listPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          if (profile.goal == FitnessGoal.cut && plan.missingCutInputs) ...[
            SportSurfaceCard(
              tint: scheme.error,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.error,
                  ),
                  title: Text(
                    l10n.cutPlanIncomplete,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    l10n.cutPlanIncompleteHint,
                    style: theme.textTheme.meta,
                  ),
                  trailing: TextButton(
                    onPressed: () => context.go('/profile/edit'),
                    child: Text(l10n.goFillIn),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
          ],
          if (onPlateau) ...[
            SportSurfaceCard(
              tint: scheme.tertiary,
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.possiblePlateau, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    l10n.plateauHint(Plateau.days),
                    style: theme.textTheme.meta,
                  ),
                  const SizedBox(height: AppSpacing.field),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: !canCutMore
                            ? null
                            : () async {
                                final updated = await ref
                                    .read(profileProvider.notifier)
                                    .applyPlateauCalorieCut();
                                if (!context.mounted || updated == null) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.cut100Applied(
                                        '${updated.targets.calories}',
                                      ),
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          canCutMore ? l10n.cut100Kcal : l10n.cutAdjCapReached,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.walk3000Snack)),
                          );
                        },
                        child: Text(l10n.walk3000Btn),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
          ],
          SportHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.sectionCalories(sectionPrefix),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onHero,
                        ),
                      ),
                    ),
                    _StepsStatusLabel(
                      stepsLabel: l10n.nSteps(steps),
                      textStyle: theme.textTheme.meta?.copyWith(
                        color: onHeroMuted,
                      ),
                      mutedColor: onHeroMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (strategyLabel != null)
                      SoftChip(
                        label: strategyLabel,
                        icon: dayTarget?.source == TargetSource.strategy
                            ? Icons.auto_graph
                            : Icons.flag_outlined,
                        onTap: () => context.go('/profile/nutrition'),
                      ),
                    if (profile.goal == FitnessGoal.cut &&
                        plannedDeficit > 0 &&
                        plannedDeficit.isFinite)
                      Text(
                        l10n.dailyDeficitLine('${plannedDeficit.round()}'),
                        style: theme.textTheme.meta?.copyWith(
                          color: onHeroMuted,
                        ),
                      ),
                    if (dayTarget?.strategy == DietStrategyKind.carbCycle &&
                        dayTarget?.isLegacyEstimate == false)
                      _WeeklyAverageLabel(
                        planId: dayTarget?.planId,
                        color: onHeroMuted,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.card),
                // Upper row: remaining (left) · ring (centre) · cup (right).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _RemainingBlock(
                        remain: remainCal,
                        eaten: intake.calories,
                        target: targetCalories,
                        onHero: onHero,
                        onHeroMuted: onHeroMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CalorieRing(
                      eaten: intake.calories,
                      target: targetCalories,
                      over: remainCal < 0,
                      size: 108,
                      color: visuals.accent,
                      trackColor: visuals.track,
                      centerLabel: l10n.eatenWord,
                      labelColor: onHero,
                      metaColor: onHeroMuted,
                    ),
                    const SizedBox(width: 12),
                    WaterCupControl(
                      progress: waterGoal <= 0 ? 0 : waterMl / waterGoal,
                      height: 108,
                      width: 68,
                      onAdd: canAddWater
                          ? () => ref
                                .read(waterRepositoryProvider)
                                .addMl(day, kWaterServingMl)
                          : null,
                      onUndo: canUndoWater
                          ? () => ref
                                .read(waterRepositoryProvider)
                                .addMl(day, -kWaterServingMl)
                          : null,
                      addLabel: l10n.waterAddMl(kWaterServingMl),
                      undoLabel: l10n.waterUndoMl(kWaterServingMl),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.card),
                Divider(color: onHero.withValues(alpha: 0.10), height: 1),
                const SizedBox(height: AppSpacing.section),
                // Lower row: strictly four columns.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MacroColumn(
                        label: l10n.protein,
                        current: intake.proteinG,
                        target: targets.proteinG,
                        unit: 'g',
                        color: AppColors.protein,
                        labelColor: onHero,
                        metaColor: onHeroMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MacroColumn(
                        label: l10n.carbs,
                        current: intake.carbG,
                        target: targets.carbG,
                        unit: 'g',
                        color: AppColors.carb,
                        labelColor: onHero,
                        metaColor: onHeroMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MacroColumn(
                        label: l10n.fat,
                        current: intake.fatG,
                        target: targets.fatG,
                        unit: 'g',
                        color: AppColors.fat,
                        labelColor: onHero,
                        metaColor: onHeroMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MacroColumn(
                        label: l10n.water,
                        current: waterMl.toDouble(),
                        target: waterGoal.toDouble(),
                        unit: 'ml',
                        color: AppColors.water,
                        labelColor: onHero,
                        metaColor: onHeroMuted,
                        // Over-goal water is fine: show the real value and
                        // keep the bar in the water colour.
                        capProgress: false,
                      ),
                    ),
                  ],
                ),
                if (intake.alcoholG > 0) ...[
                  const SizedBox(height: AppSpacing.field),
                  Text(
                    l10n.alcoholExtraKcal('${intake.alcoholKcal.round()}'),
                    style: theme.textTheme.meta?.copyWith(color: onHeroMuted),
                  ),
                ],
                if (dayTarget?.isLegacyEstimate == true) ...[
                  const SizedBox(height: AppSpacing.field),
                  Text(
                    l10n.legacyTargetHint,
                    style: theme.textTheme.meta?.copyWith(color: onHeroMuted),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  isSelectedToday ? l10n.waterTapHint : l10n.pastDayReadOnly,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onHeroMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          SportSectionBand(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.card,
              4,
              AppSpacing.compact,
              AppSpacing.compact,
            ),
            child: TodayWorkoutCard(
              day: day,
              sectionPrefix: sectionPrefix,
              expanded: _workoutExpanded,
              onToggle: () =>
                  setState(() => _workoutExpanded = !_workoutExpanded),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          SportSectionBand(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.card,
              4,
              AppSpacing.compact,
              AppSpacing.compact,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TodaySectionHeader(
                  title: l10n.sectionLogs(sectionPrefix),
                  summary: mealsAsync.value == null
                      ? null
                      : l10n.mealsSummary(
                          mealsAsync.value!.length,
                          '${intake.calories.round()}',
                        ),
                  expanded: _mealsExpanded,
                  onToggle: () =>
                      setState(() => _mealsExpanded = !_mealsExpanded),
                  expandLabel: l10n.expandSection,
                  collapseLabel: l10n.collapseSection,
                  addLabel: isSelectedToday ? l10n.logMeal : null,
                  onAdd: isSelectedToday
                      ? () => context.push('/log-meal')
                      : null,
                  trailing: [
                    PopupMenuButton<String>(
                      tooltip: l10n.more,
                      onSelected: (value) =>
                          _onMealMenu(value, day, isSelectedToday, dayLabel),
                      itemBuilder: (context) => [
                        if (isSelectedToday)
                          PopupMenuItem(
                            value: 'copy',
                            child: Text(l10n.copyYesterday),
                          ),
                        PopupMenuItem(
                          value: 'preset',
                          child: Text(l10n.saveAsPreset),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_mealsExpanded) ...[
                  if (isSelectedToday)
                    _DietCompleteRow(
                      value: dietComplete,
                      onChanged: (v) => ref
                          .read(dietStrategyRepositoryProvider)
                          .setDayComplete(day, v),
                    ),
                  const SizedBox(height: 4),
                  mealsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      l10n.loadFailed('$e'),
                      style: theme.textTheme.meta,
                    ),
                    data: (meals) => _MealGroups(
                      meals: meals,
                      isSelectedToday: isSelectedToday,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMealMenu(
    String value,
    DateTime day,
    bool isSelectedToday,
    String dayLabel,
  ) async {
    final l10n = context.l10n;
    if (value == 'copy') {
      if (!isSelectedToday) return;
      final from = day.subtract(const Duration(days: 1));
      final existing = await ref.read(mealRepositoryProvider).forDay(day);
      if (existing.isNotEmpty && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.copyYesterday),
            content: Text(l10n.copyYesterdayConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.append),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      final result = await ref
          .read(mealRepositoryProvider)
          .copyDay(from: from, to: day);
      if (!mounted) return;
      final skip = result.skippedMissingFood > 0
          ? l10n.skippedItems(result.skippedMissingFood)
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.copied == 0 && result.skippedMissingFood == 0
                ? l10n.yesterdayNoLogs
                : l10n.copiedItems(result.copied, skip),
          ),
        ),
      );
    } else if (value == 'preset') {
      final meals = await ref.read(mealRepositoryProvider).forDay(day);
      if (!mounted) return;
      if (meals.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noLogsToSave)));
        return;
      }
      final nameCtrl = TextEditingController(
        text: isSelectedToday ? l10n.mealPresets : dayLabel,
      );
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.saveAsPreset),
          content: TextField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: l10n.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
      if (ok != true) {
        nameCtrl.dispose();
        return;
      }
      try {
        await ref
            .read(mealPresetRepositoryProvider)
            .createFromEntries(name: nameCtrl.text, entries: meals);
        ref.invalidate(mealPresetsProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.presetSaved)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      } finally {
        nameCtrl.dispose();
      }
    }
  }
}

/// Left block of the hero upper row: remaining kcal + eaten/target.
class _RemainingBlock extends StatelessWidget {
  const _RemainingBlock({
    required this.remain,
    required this.eaten,
    required this.target,
    required this.onHero,
    required this.onHeroMuted,
  });

  final double remain;
  final double eaten;
  final double target;
  final Color onHero;
  final Color onHeroMuted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final over = remain < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          over ? l10n.overWord : l10n.remainingWord,
          style: theme.textTheme.labelMedium?.copyWith(color: onHeroMuted),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${remain.abs().round()}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.05,
              color: over ? scheme.error : onHero,
            ),
          ),
        ),
        Text(
          'kcal',
          style: theme.textTheme.labelMedium?.copyWith(color: onHeroMuted),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.eatenOfTarget('${eaten.round()}', '${target.round()}'),
          maxLines: 2,
          style: theme.textTheme.labelSmall?.copyWith(color: onHeroMuted),
        ),
      ],
    );
  }
}

/// Secondary "weekly average" info for carb-cycle days.
class _WeeklyAverageLabel extends ConsumerWidget {
  const _WeeklyAverageLabel({required this.planId, required this.color});

  final int? planId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(dietPlansProvider).value;
    if (plans == null || planId == null) return const SizedBox.shrink();
    DietStrategyPlan? plan;
    for (final p in plans) {
      if (p.id == planId) plan = p;
    }
    if (plan == null) return const SizedBox.shrink();
    return Text(
      context.l10n.weeklyAvgLine('${plan.weeklyAverage.round()}'),
      style: Theme.of(context).textTheme.meta?.copyWith(color: color),
    );
  }
}

/// Explicit per-day "my food log is complete" confirmation (today only).
class _DietCompleteRow extends StatelessWidget {
  const _DietCompleteRow({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.compact),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dietCompleteToggle,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(l10n.dietCompleteHint, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value ?? false, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MealGroups extends StatelessWidget {
  const _MealGroups({required this.meals, required this.isSelectedToday});

  final List<MealEntry> meals;
  final bool isSelectedToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (meals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            isSelectedToday ? l10n.emptyMealsToday : l10n.emptyMealsThatDay,
            style: theme.textTheme.meta,
          ),
        ),
      );
    }
    final groups = <Widget>[];
    for (final type in MealType.values) {
      final group = meals.where((m) => m.mealType == type.name).toList();
      if (group.isEmpty) continue;
      final calories = group.fold<double>(0, (sum, m) => sum + m.calories);
      groups.add(
        _MealTypeGroupTile(
          title: type.label(l10n),
          subtitle: '${group.length} · ${calories.round()}',
          children: [
            for (final m in group)
              _MealEntryTile(entry: m, canDismiss: isSelectedToday),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.compact),
      child: Column(children: groups),
    );
  }
}

class _MealTypeGroupTile extends StatefulWidget {
  const _MealTypeGroupTile({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  State<_MealTypeGroupTile> createState() => _MealTypeGroupTileState();
}

class _MealTypeGroupTileState extends State<_MealTypeGroupTile> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: false,
      onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
      title: Text(widget.title, style: theme.textTheme.titleSmall),
      subtitle: Text(widget.subtitle, style: theme.textTheme.meta),
      trailing: AnimatedRotation(
        turns: _expanded ? 0.5 : 0,
        duration: kThemeAnimationDuration,
        child: Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
      ),
      children: widget.children,
    );
  }
}

class _MealEntryTile extends ConsumerWidget {
  const _MealEntryTile({required this.entry, required this.canDismiss});

  final MealEntry entry;
  final bool canDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final m = entry;

    final tile = SportListTile(
      title: Text(m.foodName, style: theme.textTheme.bodyLarge),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${m.grams.toStringAsFixed(0)} g', style: theme.textTheme.meta),
          Text(
            'P ${m.proteinG.toStringAsFixed(0)} · '
            'C ${m.carbG.toStringAsFixed(0)} · '
            'F ${m.fatG.toStringAsFixed(0)}',
            style: theme.textTheme.meta,
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Text(
        '${m.calories.round()}',
        style: theme.textTheme.titleSmall,
      ),
      onTap: () => context.push('/meal/${m.id}'),
    );
    if (!canDismiss) return tile;
    return Dismissible(
      key: ValueKey(m.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: AppSpacing.compact),
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.deleteRecord),
                content: Text(l10n.confirmDeleteMeal),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ==
            true;
      },
      onDismissed: (_) {
        ref.read(mealRepositoryProvider).delete(m.id);
      },
      child: tile,
    );
  }
}

class _StepsStatusLabel extends ConsumerWidget {
  const _StepsStatusLabel({
    required this.stepsLabel,
    required this.textStyle,
    required this.mutedColor,
  });

  final String stepsLabel;
  final TextStyle? textStyle;
  final Color mutedColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Keep provider alive / kick sync; display uses last known status so
    // resume/retry refresh does not flash a spinner over a known result.
    final sync = ref.watch(stepsSyncProvider);
    final status = ref.watch(stepsSyncStatusProvider);
    final showSpinner = sync.isLoading && status == null;

    final (:icon, :color, :tooltip) = switch (status) {
      StepsSyncStatus.connected => (
        icon: Icons.check_circle_outline,
        color: AppThemeVisuals.of(context).accent,
        tooltip: l10n.stepsStatusConnected,
      ),
      StepsSyncStatus.empty => (
        icon: Icons.info_outline,
        color: AppColors.fat,
        tooltip: l10n.stepsStatusEmpty,
      ),
      StepsSyncStatus.denied => (
        icon: Icons.link_off,
        color: AppColors.fat,
        tooltip: l10n.stepsStatusDenied,
      ),
      StepsSyncStatus.unsupported => (
        icon: Icons.phonelink_off,
        color: mutedColor,
        tooltip: l10n.stepsStatusUnsupported,
      ),
      StepsSyncStatus.failed => (
        icon: Icons.error_outline,
        color: scheme.error,
        tooltip: l10n.stepsStatusFailed,
      ),
      null => (
        icon: Icons.sync,
        color: mutedColor,
        tooltip: l10n.stepsStatusSyncing,
      ),
    };

    final canOpen = status != StepsSyncStatus.unsupported;

    return Tooltip(
      message: canOpen ? '$tooltip\n${l10n.stepsStatusRetryHint}' : tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canOpen ? () => _showStepsDetailSheet(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stepsLabel, style: textStyle),
                const SizedBox(width: 4),
                if (showSpinner)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: mutedColor,
                    ),
                  )
                else
                  Icon(icon, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStepsDetailSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _StepsDetailSheet(),
    );
  }
}

class _StepsDetailSheet extends ConsumerStatefulWidget {
  const _StepsDetailSheet();

  @override
  ConsumerState<_StepsDetailSheet> createState() => _StepsDetailSheetState();
}

class _StepsDetailSheetState extends ConsumerState<_StepsDetailSheet> {
  bool _syncing = false;
  Future<Map<String, Object?>>? _diagnostics;

  Future<void> _resync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await ref.read(stepsSyncStatusProvider.notifier).resync();
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
          _diagnostics = null;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    await ref.read(stepsSyncServiceProvider).openHealthConnectSettings();
  }

  void _copyDiagnostics(Map<String, Object?> data) {
    final text = data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.copiedClipboard)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = ref.watch(stepsSyncStatusProvider);
    final steps = ref.watch(stepsForSelectedDayProvider).value ?? 0;

    final (statusText, statusIcon, statusColor) = switch (status) {
      StepsSyncStatus.connected => (
        l10n.stepsStatusConnected,
        Icons.check_circle_outline,
        Colors.green,
      ),
      StepsSyncStatus.empty => (
        l10n.stepsStatusEmpty,
        Icons.info_outline,
        Colors.orange,
      ),
      StepsSyncStatus.denied => (
        l10n.stepsStatusDenied,
        Icons.link_off,
        Colors.orange,
      ),
      StepsSyncStatus.failed => (
        l10n.stepsStatusFailed,
        Icons.error_outline,
        theme.colorScheme.error,
      ),
      StepsSyncStatus.unsupported => (
        l10n.stepsStatusUnsupported,
        Icons.phonelink_off,
        theme.colorScheme.onSurfaceVariant,
      ),
      null => (
        l10n.stepsStatusSyncing,
        Icons.sync,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    final hint = switch (status) {
      StepsSyncStatus.empty => l10n.stepsSheetEmptyHint,
      StepsSyncStatus.denied => l10n.stepsSheetDeniedHint,
      _ => null,
    };

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.stepsSheetTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(l10n.nSteps(steps), style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(statusIcon, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(statusText, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(hint, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.stepsSheetSourceHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _syncing ? null : _resync,
                      icon: _syncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(l10n.stepsSheetResync),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                        l10n.stepsSheetOpenSettings,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  l10n.stepsSheetDiagnostics,
                  style: theme.textTheme.titleSmall,
                ),
                onExpansionChanged: (open) {
                  if (open && _diagnostics == null) {
                    setState(() {
                      _diagnostics = ref
                          .read(stepsSyncServiceProvider)
                          .diagnostics();
                    });
                  }
                },
                children: [
                  FutureBuilder<Map<String, Object?>>(
                    future: _diagnostics,
                    builder: (context, snap) {
                      final data = snap.data;
                      if (data == null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(l10n.stepsSheetDiagnosticsLoading),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            data.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _copyDiagnostics(data),
                              icon: const Icon(Icons.copy, size: 16),
                              label: Text(l10n.copy),
                            ),
                          ),
                        ],
                      );
                    },
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
