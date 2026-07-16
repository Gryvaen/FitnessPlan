import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/calorie_calculator.dart';
import '../../domain/models.dart';
import '../../domain/plateau.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'deficit_date_picker.dart';
import 'today_summary_widgets.dart';
import 'today_workout_card.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final profile = ref.watch(profileProvider);
    final intake = ref.watch(todayIntakeProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final day = ref.watch(selectedDayProvider);
    final weightLogs = ref.watch(weightLogsProvider).value ?? const [];

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final targets = profile.targets;
    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final remainCal = targets.calories - intake.calories;
    final remainP = targets.proteinG - intake.proteinG;
    final remainC = targets.carbG - intake.carbG;
    final remainF = targets.fatG - intake.fatG;
    final waterMl = ref.watch(waterMlProvider).value ?? 0;
    final waterGoal = ref.watch(waterGoalProvider);

    String remainMacro(double remain) => remain < 0
        ? l10n.macroOverG((-remain).toStringAsFixed(0))
        : l10n.macroRemainG(remain.toStringAsFixed(0));

    final onPlateau = profile.goal == FitnessGoal.cut &&
        Plateau.detect(
          weightLogs
              .map((e) => (date: e.date, weightKg: e.weightKg))
              .toList(),
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
    final sectionPrefix =
        isSelectedToday ? l10n.today : l10n.sectionThatDay;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final picked = await showDeficitDatePicker(
              context: context,
              initialDate: day,
              firstDate: earliest,
              lastDate: today,
              plannedDeficit: plan.dailyDeficit,
              targetCalories: targets.calories.toDouble(),
              mealRepository: ref.read(mealRepositoryProvider),
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
          if (profile.goal == FitnessGoal.cut && plan.missingCutInputs)
            Card(
              color: scheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.onErrorContainer,
                ),
                title: Text(
                  l10n.cutPlanIncomplete,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                subtitle: Text(
                  l10n.cutPlanIncompleteHint,
                  style: theme.textTheme.meta?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () => context.go('/profile/edit'),
                  child: Text(l10n.goFillIn),
                ),
              ),
            ),
          if (onPlateau) ...[
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.possiblePlateau,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.plateauHint(Plateau.days),
                      style: theme.textTheme.meta?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
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
                            canCutMore
                                ? l10n.cut100Kcal
                                : l10n.cutAdjCapReached,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.walk3000Snack),
                              ),
                            );
                          },
                          child: Text(l10n.walk3000Btn),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sectionCalories(sectionPrefix),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (profile.goal == FitnessGoal.cut &&
                      !plan.missingCutInputs &&
                      plan.kgToLose != null &&
                      plan.weeklyLossKg != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.deficitIntakeLine(
                        '${plan.dailyDeficit.round()}',
                        '${plan.targets.calories}',
                      )}${plan.goalWeeks != null ? l10n.aboutNWeeks(plan.goalWeeks!) : ''}',
                      style: theme.textTheme.meta,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.field),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CalorieRing(
                        eaten: intake.calories,
                        target: targets.calories.toDouble(),
                        over: remainCal < 0,
                        remainAbs: remainCal.abs(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            MacroMini(
                              label: l10n.proteinShort,
                              current: intake.proteinG,
                              target: targets.proteinG,
                              color: AppColors.protein,
                              remainLabel: remainMacro(remainP),
                            ),
                            MacroMini(
                              label: l10n.carbs,
                              current: intake.carbG,
                              target: targets.carbG,
                              color: AppColors.carb,
                              remainLabel: remainMacro(remainC),
                            ),
                            MacroMini(
                              label: l10n.fat,
                              current: intake.fatG,
                              target: targets.fatG,
                              color: AppColors.fat,
                              remainLabel: remainMacro(remainF),
                            ),
                          ],
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
                      style: theme.textTheme.meta,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.water, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '$waterMl / $waterGoal ml',
                              style: theme.textTheme.meta,
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: !isSelectedToday || waterMl <= 0
                              ? null
                              : () => ref
                                  .read(waterRepositoryProvider)
                                  .addMl(day, -250),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 6, 0, 6),
                            child: WaterCupLid(
                              enabled: isSelectedToday && waterMl > 0,
                            ),
                          ),
                        ),
                      ),
                      // Overlap into the cup's left canvas inset so the
                      // cap sits flush against the drawn cup rim.
                      Transform.translate(
                        offset: const Offset(-10, 0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: !isSelectedToday
                                ? null
                                : () => ref
                                    .read(waterRepositoryProvider)
                                    .addMl(day, 250),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
                              child: WaterCup(
                                progress:
                                    waterGoal <= 0 ? 0 : waterMl / waterGoal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: waterGoal <= 0
                          ? 0
                          : (waterMl / waterGoal).clamp(0.0, 1.0),
                      minHeight: 10,
                      color: scheme.primary,
                      backgroundColor:
                          scheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSelectedToday
                        ? l10n.waterTapHint
                        : l10n.pastDayReadOnly,
                    style: theme.textTheme.meta,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          TodayWorkoutCard(day: day, sectionPrefix: sectionPrefix),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Text(
                l10n.sectionLogs(sectionPrefix),
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              if (isSelectedToday)
                IconButton(
                  tooltip: l10n.logMeal,
                  onPressed: () => context.push('/log-meal'),
                  icon: const Icon(Icons.add),
                ),
              PopupMenuButton<String>(
                tooltip: l10n.more,
                onSelected: (value) async {
                  if (value == 'copy') {
                    if (!isSelectedToday) return;
                    final from = day.subtract(const Duration(days: 1));
                    final existing =
                        await ref.read(mealRepositoryProvider).forDay(day);
                    if (existing.isNotEmpty && context.mounted) {
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
                    if (!context.mounted) return;
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
                    final meals =
                        await ref.read(mealRepositoryProvider).forDay(day);
                    if (!context.mounted) return;
                    if (meals.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.noLogsToSave)),
                      );
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
                          .createFromEntries(
                            name: nameCtrl.text,
                            entries: meals,
                          );
                      ref.invalidate(mealPresetsProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.presetSaved)),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    } finally {
                      nameCtrl.dispose();
                    }
                  }
                },
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
          const SizedBox(height: 8),
          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              l10n.loadFailed('$e'),
              style: theme.textTheme.meta,
            ),
            data: (meals) {
              if (meals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      isSelectedToday
                          ? l10n.emptyMealsToday
                          : l10n.emptyMealsThatDay,
                      style: theme.textTheme.meta,
                    ),
                  ),
                );
              }
              return Column(
                children: meals.map((m) {
                  final type = MealType.values.byName(m.mealType);
                  final tile = ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.foodName, style: theme.textTheme.bodyLarge),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${type.label(l10n)} · ${m.grams.toStringAsFixed(0)} g',
                          style: theme.textTheme.meta,
                        ),
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
                  if (!isSelectedToday) return tile;
                  return Dismissible(
                    key: ValueKey(m.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: scheme.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref.read(mealRepositoryProvider).delete(m.id);
                    },
                    child: tile,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
