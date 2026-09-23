import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/goal_quotes.dart';
import '../../domain/models.dart';
import '../../domain/plateau.dart';
import '../../data/services/steps_sync_service.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../meals/daily_meals_page.dart';
import '../ink/ink_icon.dart';
import '../shell/swipe_tab_view.dart';
import '../strategy/strategy_labels.dart';
import '../theme/app_theme.dart';
import '../theme/macro_color.dart';
import '../theme/sport_chrome.dart';
import '../tools/workout_reminder_notifications.dart';
import '../widgets/search_field_focus.dart';
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
  @override
  Widget build(BuildContext context) {
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
    // The calorie summary is a flat page section now (no hero card), so its
    // text sits on the ordinary surface colours.
    final onHero = scheme.onSurface;
    final onHeroMuted = scheme.onSurfaceVariant;

    // Single per-date target source; fall back to the profile target only
    // while the first resolution is in flight.
    final dayTarget = targetAsync.value;
    final targets = dayTarget?.toMacroTargets() ?? profile.targets;
    final targetCalories = dayTarget?.calories ?? targets.calories.toDouble();
    final remainCal = targetCalories - intake.calories;

    final onPlateau =
        profile.goal == FitnessGoal.cut &&
        Plateau.detect(
          weightLogs.map((e) => (date: e.date, weightKg: e.weightKg)).toList(),
        );

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

    final plannedDeficit = dayTarget?.fixedPlannedDeficit ?? 0;
    final strategyLabel = dayTarget == null
        ? null
        : targetChipLabel(dayTarget, profile, l10n);
    final canChooseDietStrategy =
        profile.goal == FitnessGoal.cut &&
        dayTarget?.source == TargetSource.profile &&
        dayTarget?.isLegacyEstimate == false;

    Future<void> openDatePicker() async {
      final repo = ref.read(dietStrategyRepositoryProvider);
      final picked = await showDeficitDatePicker(
        context: context,
        initialDate: day,
        firstDate: earliest,
        lastDate: today,
        plannedDeficit: plannedDeficit,
        mealRepository: ref.read(mealRepositoryProvider),
        loadTargets: (start, end) => repo.targetsBetween(start, end, profile),
        calorieStandardSince: profile.calorieStandardSince,
      );
      if (picked == null) return;
      ref.read(selectedDayProvider.notifier).setDay(picked);
    }

    return AppChromeScaffold(
      body: SwipeTabView(
        branchIndex: 0,
        index: 0,
        onIndexChanged: (_) {},
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.listPage,
                4,
                AppSpacing.listPage,
                listBottomInset(context, hasFab: false),
              ),
              children: [
                _TodayHeader(
                  title: AppDates.relativeDayTitleWithDate(
                    day,
                    today,
                    l10n,
                    locale,
                  ),
                  // Each calendar day keeps its own quote (goalQuoteForDay is
                  // a pure function of day + goal, so it's stable whenever
                  // that day is viewed again) — the title already carries
                  // the specific date, so the subtitle no longer needs to
                  // fall back to a plain date for non-today days.
                  dateLabel: goalQuoteForDay(profile.goal, day),
                  canGoPrev: canGoPrev,
                  canGoNext: canGoNext,
                  onPrev: () => ref
                      .read(selectedDayProvider.notifier)
                      .shiftDay(-1, earliest: earliest),
                  onNext: () => ref
                      .read(selectedDayProvider.notifier)
                      .shiftDay(1, earliest: earliest),
                  onCalendar: openDatePicker,
                  onGoToToday: isSelectedToday
                      ? null
                      : () =>
                            ref.read(selectedDayProvider.notifier).goToToday(),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.compact),
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
                            textStyle: theme.textTheme.meta?.copyWith(
                              color: onHeroMuted,
                            ),
                            mutedColor: onHeroMuted,
                          ),
                        ],
                      ),
                      if (strategyLabel != null) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            InkWell(
                              onTap: () => context.go('/profile/nutrition'),
                              borderRadius: BorderRadius.circular(6),
                              child: Text(
                                canChooseDietStrategy
                                    ? l10n.goalCut
                                    : strategyLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onHeroMuted,
                                ),
                              ),
                            ),
                            if (canChooseDietStrategy)
                              Text(
                                '|',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onHeroMuted,
                                ),
                              ),
                            if (canChooseDietStrategy) ...[
                              InkWell(
                                onTap: () =>
                                    context.go('/profile/nutrition/strategy'),
                                borderRadius: BorderRadius.circular(6),
                                child: Text(
                                  l10n.canChooseDietStrategy,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (onPlateau) ...[
                        SizedBox(height: strategyLabel != null ? 2 : 4),
                        Text(
                          l10n.possiblePlateau,
                          style: theme.textTheme.meta?.copyWith(
                            color: onHeroMuted,
                          ),
                        ),
                      ],
                      if (dayTarget?.strategy == DietStrategyKind.carbCycle &&
                          dayTarget?.isLegacyEstimate == false) ...[
                        const SizedBox(height: 2),
                        _WeeklyAverageLabel(
                          planId: dayTarget?.planId,
                          color: onHeroMuted,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.card),
                      // Open composition: remaining, ring, and interactive cup.
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
                            size: 88,
                            strokeWidth: 8,
                            color: scheme.primary,
                            trackColor: visuals.track,
                            centerLabel: l10n.eatenWord,
                            metaColor: onHeroMuted,
                          ),
                          const SizedBox(width: 10),
                          _WaterCup(day: day, canAdd: isSelectedToday),
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
                              icon: InkGlyph.protein,
                              label: l10n.protein,
                              current: intake.proteinG,
                              target: targets.proteinG,
                              unit: 'g',
                              color: scheme.primary,
                              labelColor: onHero,
                              metaColor: onHeroMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MacroColumn(
                              icon: InkGlyph.carbs,
                              label: l10n.carbs,
                              current: intake.carbG,
                              target: targets.carbG,
                              unit: 'g',
                              color: scheme.primary,
                              labelColor: onHero,
                              metaColor: onHeroMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MacroColumn(
                              icon: InkGlyph.fat,
                              label: l10n.fat,
                              current: intake.fatG,
                              target: targets.fatG,
                              unit: 'g',
                              color: scheme.primary,
                              labelColor: onHero,
                              metaColor: onHeroMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _WaterMacroColumn(
                              label: l10n.water,
                              labelColor: onHero,
                              metaColor: onHeroMuted,
                            ),
                          ),
                        ],
                      ),
                      if (intake.alcoholG > 0) ...[
                        const SizedBox(height: AppSpacing.field),
                        Text(
                          l10n.alcoholExtraKcal(
                            '${intake.alcoholKcal.round()}',
                          ),
                          style: theme.textTheme.meta?.copyWith(
                            color: onHeroMuted,
                          ),
                        ),
                      ],
                      if (dayTarget?.isLegacyEstimate == true) ...[
                        const SizedBox(height: AppSpacing.field),
                        Text(
                          l10n.legacyTargetHint,
                          style: theme.textTheme.meta?.copyWith(
                            color: onHeroMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                Divider(height: 1, color: visuals.divider),
                const SizedBox(height: AppSpacing.section),
                SportSectionBand(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    4,
                    AppSpacing.compact,
                    AppSpacing.compact,
                  ),
                  child: TodayWorkoutCard(
                    day: day,
                    sectionPrefix: sectionPrefix,
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                SportSectionBand(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    4,
                    AppSpacing.compact,
                    AppSpacing.compact,
                  ),
                  child: Builder(
                    builder: (context) {
                      final meals = mealsAsync.value ?? const <MealEntry>[];
                      final yesterdayMeals = isSelectedToday
                          ? (ref
                                    .watch(
                                      mealsForDayProvider(
                                        day.subtract(const Duration(days: 1)),
                                      ),
                                    )
                                    .value ??
                                const <MealEntry>[])
                          : const <MealEntry>[];
                      final yesterdayMealTypes = [
                        for (final t in MealType.values)
                          if (yesterdayMeals.any((m) => m.mealType == t.name))
                            t,
                      ];
                      final canCopyYesterday =
                          isSelectedToday && yesterdayMealTypes.isNotEmpty;
                      final canSaveAsPreset = meals.isNotEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TodaySectionHeader(
                            title: l10n.sectionLogs(sectionPrefix),
                            summary: mealsAsync.value == null
                                ? null
                                : l10n.mealsSummary(
                                    meals.length,
                                    '${intake.calories.round()}',
                                  ),
                            addLabel: isSelectedToday ? l10n.logMeal : null,
                            onAdd: isSelectedToday
                                ? () {
                                    unfocusForNavigation();
                                    context.push(
                                      '/log-meal?mealType=${MealType.suggestedFor(DateTime.now()).name}'
                                      '&openDayMealsAfterSearchAdd=1',
                                    );
                                  }
                                : null,
                            trailing: [
                              if (canCopyYesterday)
                                PopupMenuButton<MealType>(
                                  tooltip: l10n.copyYesterday,
                                  icon: const InkIcon(InkGlyph.more),
                                  onSelected: (type) =>
                                      copyMealTypeFromYesterday(
                                        context: context,
                                        ref: ref,
                                        day: day,
                                        mealType: type,
                                      ),
                                  itemBuilder: (context) => [
                                    for (final t in yesterdayMealTypes)
                                      PopupMenuItem(
                                        value: t,
                                        child: Text(
                                          l10n.copyNamed(
                                            l10n.yesterdayNamed(t.label(l10n)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              if (canSaveAsPreset)
                                PopupMenuButton<String>(
                                  tooltip: l10n.more,
                                  icon: const InkIcon(InkGlyph.more),
                                  onSelected: (value) => _onMealMenu(
                                    value,
                                    day,
                                    isSelectedToday,
                                    dayLabel,
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'preset',
                                      child: Text(l10n.saveAsPreset),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          mealsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Text(
                              l10n.loadFailed('$e'),
                              style: theme.textTheme.meta,
                            ),
                            data: (meals) => meals.isEmpty
                                ? SportEmptyState(
                                    icon: Icons.restaurant_outlined,
                                    iconWidget: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        InkIcon(
                                          InkGlyph.mealEmpty,
                                          size: 52,
                                          color: scheme.onSurfaceVariant
                                              .withValues(alpha: .62),
                                          strokeWidth: 1.6,
                                        ),
                                        const Positioned(
                                          right: -8,
                                          bottom: -3,
                                          child: InkSeal('食', size: 19),
                                        ),
                                      ],
                                    ),
                                    title: isSelectedToday
                                        ? l10n.noMealsTitle
                                        : l10n.noMealsThatDay,
                                    message: isSelectedToday
                                        ? l10n.noMealsHint
                                        : l10n.pastDayReadOnly,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _MealGroups(
                                        meals: meals,
                                        onOpen: () =>
                                            context.push(dailyMealsPath(day)),
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () =>
                                              context.push(dailyMealsPath(day)),
                                          child: Text(l10n.viewDayRecords),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
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
      final nameFocus = FocusNode();
      suppressInitialTextFocus(nameFocus);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.saveAsPreset),
          content: TextField(
            controller: nameCtrl,
            focusNode: nameFocus,
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
      final presetName = nameCtrl.text;
      // Defer dispose until after the dialog route finishes unmounting.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameCtrl.dispose();
        nameFocus.dispose();
      });
      if (ok != true) return;
      try {
        await ref
            .read(mealPresetRepositoryProvider)
            .createFromEntries(name: presetName, entries: meals);
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
    final over = remain < 0;
    final fraction = target <= 0 || !target.isFinite || !eaten.isFinite
        ? 0.0
        : eaten / target;
    final valueColor = intakeProgressColor(
      over: over,
      fraction: fraction,
      fallback: onHero,
    );
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
              color: valueColor,
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

/// Compact per-meal-type summary shown on the Today page (one row each:
/// meal name · food list · kcal). The full per-entry list lives on
/// [DailyMealsPage].
class _MealGroups extends StatelessWidget {
  const _MealGroups({required this.meals, required this.onOpen});

  final List<MealEntry> meals;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final groups = <Widget>[];
    for (final type in MealType.values) {
      final group = meals.where((m) => m.mealType == type.name).toList();
      if (group.isEmpty) continue;
      final calories = group.fold<double>(0, (sum, m) => sum + m.calories);
      final accent = switch (type) {
        MealType.breakfast => AppColors.fat,
        MealType.lunch => AppColors.carb,
        MealType.dinner => AppColors.protein,
        MealType.snack => AppColors.water,
      };
      groups.add(
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(type.label(l10n), style: theme.textTheme.titleSmall),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        for (var i = 0; i < group.length; i++) ...[
                          if (i > 0)
                            TextSpan(
                              text: ' · ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          TextSpan(
                            text: group[i].foodName,
                            style: TextStyle(
                              color:
                                  dominantMacroColor(
                                    carbG: group[i].carbG,
                                    proteinG: group[i].proteinG,
                                    fatG: group[i].fatG,
                                  ) ??
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${calories.round()} kcal',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0)
            Divider(height: 1, color: AppThemeVisuals.of(context).divider),
          groups[i],
        ],
      ],
    );
  }
}

class _StepsStatusLabel extends ConsumerWidget {
  const _StepsStatusLabel({required this.textStyle, required this.mutedColor});

  final TextStyle? textStyle;
  final Color mutedColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Watched here (not hoisted into TodayPage.build()) so a steps update
    // only rebuilds this small label, not the whole page.
    final steps = ref.watch(stepsForSelectedDayProvider).value ?? 0;
    // Keep provider alive / kick sync; display uses last known status so
    // resume/retry refresh does not flash a spinner over a known result.
    final sync = ref.watch(stepsSyncProvider);
    final status = ref.watch(stepsSyncStatusProvider);
    final showSpinner = sync.isLoading && status == null;
    final canOpen = status != StepsSyncStatus.unsupported;

    final label = switch (status) {
      StepsSyncStatus.denied => l10n.stepsPermissionNeeded,
      StepsSyncStatus.failed || StepsSyncStatus.empty => l10n.stepsNotSynced,
      _ => l10n.nSteps(steps),
    };
    final iconColor = status == StepsSyncStatus.connected
        ? AppColors.success
        : mutedColor;

    return Tooltip(
      message: canOpen
          ? l10n.stepsStatusRetryHint
          : l10n.stepsStatusUnsupported,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canOpen ? () => _showStepsDetailSheet(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkIcon(InkGlyph.walk, size: 18, color: iconColor),
                const SizedBox(width: 4),
                Text(label, style: textStyle),
                if (showSpinner) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: mutedColor,
                    ),
                  ),
                ],
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

/// The cup + add/undo buttons, isolated in its own [ConsumerWidget] so
/// logging a water serving only rebuilds this small control, not the whole
/// Today page (calorie ring, meal list, workout card, etc.).
class _WaterCup extends ConsumerWidget {
  const _WaterCup({required this.day, required this.canAdd});

  final DateTime day;

  /// Whether today's day is selected — adding water to a past day is
  /// disallowed regardless of the water amount, so this is passed in rather
  /// than watched (it only changes when the selected day itself changes,
  /// which already rebuilds the page).
  final bool canAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final waterMl = ref.watch(waterMlProvider).value ?? 0;
    final waterGoal = ref.watch(waterGoalProvider);
    final canUndo = canAdd && waterMl > 0;
    return WaterCupControl(
      progress: waterGoal <= 0 ? 0 : waterMl / waterGoal,
      height: 92,
      width: 58,
      onAdd: canAdd
          ? () => ref.read(waterRepositoryProvider).addMl(day, kWaterServingMl)
          : null,
      onUndo: canUndo
          ? () => ref.read(waterRepositoryProvider).addMl(day, -kWaterServingMl)
          : null,
      addLabel: l10n.waterAddMl(kWaterServingMl),
      undoLabel: l10n.waterUndoMl(kWaterServingMl),
    );
  }
}

/// Water's entry in the four-column macro row, isolated for the same reason
/// as [_WaterCup].
class _WaterMacroColumn extends ConsumerWidget {
  const _WaterMacroColumn({
    required this.label,
    required this.labelColor,
    required this.metaColor,
  });

  final String label;
  final Color labelColor;
  final Color metaColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterMl = ref.watch(waterMlProvider).value ?? 0;
    final waterGoal = ref.watch(waterGoalProvider);
    return MacroColumn(
      icon: InkGlyph.water,
      label: label,
      current: waterMl.toDouble(),
      target: waterGoal.toDouble(),
      unit: 'ml',
      color: AppColors.water,
      labelColor: labelColor,
      metaColor: metaColor,
      // Over-goal water is fine: show the real value and keep the bar in
      // the water colour.
      capProgress: false,
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
  bool _showBatteryHint = false;

  @override
  void initState() {
    super.initState();
    _refreshBatteryStatus();
  }

  Future<void> _refreshBatteryStatus() async {
    if (!StepServiceNotifier.isAvailable) return;
    final aggressive = await ReminderNotifications.isAggressiveOem();
    final ignoring =
        await ReminderNotifications.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() => _showBatteryHint = aggressive && !ignoring);
  }

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
        InkGlyph.check,
        Colors.green,
      ),
      StepsSyncStatus.empty => (
        l10n.stepsStatusEmpty,
        InkGlyph.info,
        Colors.orange,
      ),
      StepsSyncStatus.denied => (
        l10n.stepsStatusDenied,
        InkGlyph.disconnect,
        Colors.orange,
      ),
      StepsSyncStatus.failed => (
        l10n.stepsStatusFailed,
        InkGlyph.info,
        theme.colorScheme.error,
      ),
      StepsSyncStatus.unsupported => (
        l10n.stepsStatusUnsupported,
        InkGlyph.disconnect,
        theme.colorScheme.onSurfaceVariant,
      ),
      null => (
        l10n.stepsStatusSyncing,
        InkGlyph.sync,
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
                  InkIcon(statusIcon, size: 20, color: statusColor),
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
                              child: InkIcon(InkGlyph.loading, size: 16),
                            )
                          : const InkIcon(InkGlyph.sync),
                      label: Text(l10n.stepsSheetResync),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openSettings,
                      icon: const InkIcon(InkGlyph.settings),
                      label: Text(
                        l10n.stepsSheetOpenSettings,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              if (StepServiceNotifier.isAvailable) ...[
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.stepsServiceTitle),
                  subtitle: Text(
                    l10n.stepsServiceHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  isThreeLine: true,
                  value: ref.watch(stepServiceProvider),
                  onChanged: (v) async {
                    await ref.read(stepServiceProvider.notifier).setEnabled(v);
                    if (v) await _refreshBatteryStatus();
                  },
                ),
                if (ref.watch(stepServiceProvider) && _showBatteryHint)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkIcon(
                          InkGlyph.battery,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.stepsOemHintBody,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  await ReminderNotifications.requestIgnoreBatteryOptimizations();
                                  await _refreshBatteryStatus();
                                },
                                child: Text(l10n.reminderOemHintBatteryButton),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
                              icon: const InkIcon(InkGlyph.copy, size: 16),
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

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({
    required this.title,
    required this.dateLabel,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onCalendar,
    this.onGoToToday,
  });

  final String title;
  final String dateLabel;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onCalendar;

  /// Long-press on the calendar icon jumps straight back to today; null
  /// (long-press disabled) when already viewing today.
  final VoidCallback? onGoToToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final showDate = title != dateLabel;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: AppSpacing.section),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall),
                if (showDate) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          InkIconButton(
            glyph: InkGlyph.chevronLeft,
            tooltip: l10n.prevDay,
            onPressed: canGoPrev ? onPrev : null,
          ),
          IconButton(
            tooltip: l10n.selectDate,
            visualDensity: VisualDensity.compact,
            onPressed: onCalendar,
            onLongPress: onGoToToday == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onGoToToday!();
                  },
            icon: _TodayWeekdayCalendarIcon(
              weekdayLetter: l10n.weekdayLettersMonSun.split(
                ',',
              )[DateTime.now().weekday - 1],
              color: AppThemeVisuals.of(context).accent,
            ),
          ),
          InkIconButton(
            glyph: InkGlyph.chevronRight,
            tooltip: l10n.nextDay,
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// Calendar outline with today's weekday letter drawn in the icon body.
class _TodayWeekdayCalendarIcon extends StatelessWidget {
  const _TodayWeekdayCalendarIcon({
    required this.weekdayLetter,
    required this.color,
  });

  final String weekdayLetter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InkIcon(InkGlyph.calendar, size: 24, color: color),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              weekdayLetter,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
