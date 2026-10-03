import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/meal_repository.dart';
import '../../domain/calendar_day.dart';
import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../meals/daily_meals_page.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

/// 0 = last 14 calendar days, 1 = every day that has a meal.
///
/// 「最近」appears once any of those 14 days has a meal. 「全部」appears on the
/// 14th calendar day after the first logged meal (that day counts as day 1).
List<int> mealHistoryScopes({
  required List<MealHistoryDay> recent,
  required List<MealHistoryDay> all,
}) {
  final hasRecent = recent.any((day) => day.hasActivity);
  final first = all.isEmpty ? null : all.last.date;
  final showAll =
      first != null &&
      AppDates.todayLocal().difference(AppDates.dayOnly(first)).inDays >= 13;
  return [if (hasRecent) 0, if (showAll) 1];
}

String mealHistoryLabel(MealHistoryDay day, AppLocalizations l10n) {
  if (!day.hasActivity) return l10n.historyEmptyDay;
  final meals = day.mealTypes.map((type) => type.label(l10n)).join(' · ');
  return '$meals · ${day.calories.round()} kcal';
}

/// Diet history for the foods page. Matches the train-records history:
/// a recent/all scope, one summary row, then a day list that groups days
/// by their carb-cycle type when a cut-goal carb-cycle plan is selected.
class FoodHistoryTab extends ConsumerStatefulWidget {
  const FoodHistoryTab({super.key});

  @override
  ConsumerState<FoodHistoryTab> createState() => _FoodHistoryTabState();
}

class _FoodHistoryTabState extends ConsumerState<FoodHistoryTab> {
  /// 0 = recent, 1 = all.
  int _scope = 0;

  void _ensureScope(List<int> scopes) {
    if (scopes.isEmpty || scopes.contains(_scope)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scopes.contains(_scope)) return;
      setState(() => _scope = scopes.first);
    });
  }

  void _setScope(int scope) => setState(() => _scope = scope);

  void _showDays(
    BuildContext context,
    List<MealHistoryDay> days,
    Locale locale, {
    required String title,
  }) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .9,
        child: _MealHistorySheet(
          days: days,
          locale: locale,
          title: title,
          labelFor: (day) => mealHistoryLabel(day, l10n),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recent = ref.watch(mealHistoryProvider).value ?? const [];
    final all = ref.watch(allMealHistoryProvider).value ?? const [];
    final scopes = mealHistoryScopes(recent: recent, all: all);
    _ensureScope(scopes);
    final scope = scopes.contains(_scope)
        ? _scope
        : (scopes.isEmpty ? 0 : scopes.first);
    final showScopeTabs = scopes.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showScopeTabs)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.listPage,
            ),
            child: Wrap(
              spacing: 8,
              children: [
                for (final s in scopes)
                  ChoiceChip(
                    label: Text(s == 0 ? l10n.tabRecent : l10n.filterAll),
                    selected: scope == s,
                    onSelected: (_) => _setScope(s),
                  ),
              ],
            ),
          ),
        if (showScopeTabs) const SizedBox(height: 8),
        Expanded(
          child: showScopeTabs
              ? SwipeTabView(
                  navigation: SwipeTabNavigation.tapOnly,
                  keepPagesAlive: true,
                  index: scopes.indexOf(scope).clamp(0, scopes.length - 1),
                  onIndexChanged: (i) => _setScope(scopes[i]),
                  children: [
                    for (final s in scopes)
                      _MealHistoryScopeList(
                        all: s == 1,
                        onOpen: (days, title) => _showDays(
                          context,
                          days,
                          Localizations.localeOf(context),
                          title: title,
                        ),
                      ),
                  ],
                )
              : _MealHistoryScopeList(
                  all: scope == 1,
                  onOpen: (days, title) => _showDays(
                    context,
                    days,
                    Localizations.localeOf(context),
                    title: title,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MealHistoryScopeList extends ConsumerWidget {
  const _MealHistoryScopeList({required this.all, required this.onOpen});

  final bool all;
  final void Function(List<MealHistoryDay> days, String title) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final async = ref.watch(all ? allMealHistoryProvider : mealHistoryProvider);
    final title = all ? l10n.allMeals : l10n.recentMeals;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.listPage,
        12,
        AppSpacing.listPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => SportLoadError(
            onRetry: () => ref.invalidate(
              all ? allMealHistoryProvider : mealHistoryProvider,
            ),
          ),
          data: (days) {
            if (all && days.isEmpty) {
              return SportEmptyState(
                title: l10n.noMealsTitle,
                iconWidget: const StampedInkEmptyIcon(
                  glyph: InkGlyph.mealEmpty,
                  seal: '食',
                ),
              );
            }
            if (days.isEmpty) return const SizedBox.shrink();
            final latest = days.first;
            return SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: const MenuIconBadge(
                color: AppColors.carb,
                child: InkIcon(InkGlyph.food, color: AppColors.carb),
              ),
              title: Text(title),
              subtitle: Text(
                '${AppDates.md(latest.date, locale)}\n${mealHistoryLabel(latest, l10n)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onOpen(days, title),
            );
          },
        ),
      ],
    );
  }
}

/// Only a resolved carb-cycle target can supply a history highlight group.
CarbDayType? mealHistoryCarbDayType({
  required FitnessGoal? goal,
  required DietStrategyKind? selectedStrategy,
  required DailyNutritionTarget? target,
}) {
  if (goal != FitnessGoal.cut ||
      selectedStrategy != DietStrategyKind.carbCycle ||
      target?.strategy != DietStrategyKind.carbCycle) {
    return null;
  }
  return target?.dayType;
}

bool mealHistoryHighlightsDay({
  required FitnessGoal? goal,
  required DietStrategyKind? selectedStrategy,
  required DailyNutritionTarget? selectedTarget,
  required DailyNutritionTarget? dayTarget,
}) {
  final selectedType = mealHistoryCarbDayType(
    goal: goal,
    selectedStrategy: selectedStrategy,
    target: selectedTarget,
  );
  return selectedType != null &&
      mealHistoryCarbDayType(
            goal: goal,
            selectedStrategy: selectedStrategy,
            target: dayTarget,
          ) ==
          selectedType;
}

class _MealHistorySheet extends ConsumerStatefulWidget {
  const _MealHistorySheet({
    required this.days,
    required this.locale,
    required this.title,
    required this.labelFor,
  });

  final List<MealHistoryDay> days;
  final Locale locale;
  final String title;
  final String Function(MealHistoryDay day) labelFor;

  @override
  ConsumerState<_MealHistorySheet> createState() => _MealHistorySheetState();
}

class _MealHistorySheetState extends ConsumerState<_MealHistorySheet> {
  DateTime? _selectedDay;
  late Future<Map<DateTime, DailyNutritionTarget>> _targets;

  @override
  void initState() {
    super.initState();
    _targets = _loadTargets();
  }

  Future<Map<DateTime, DailyNutritionTarget>> _loadTargets() {
    if (widget.days.isEmpty) return Future.value(const {});
    final dates = widget.days.map((day) => day.date).toList()..sort();
    return ref
        .read(dietStrategyRepositoryProvider)
        .targetsBetween(dates.first, dates.last, ref.read(profileProvider));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
    );
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final goal = ref.watch(profileProvider)?.goal;
    final selectedStrategy = ref.watch(activeDietPlanProvider).value?.kind;
    return SafeArea(
      child: FutureBuilder<Map<DateTime, DailyNutritionTarget>>(
        future: _targets,
        builder: (context, snapshot) {
          final targets =
              snapshot.data ?? const <DateTime, DailyNutritionTarget>{};
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: widget.days.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                );
              }
              final day = widget.days[index - 1];
              final highlighted = mealHistoryHighlightsDay(
                goal: goal,
                selectedStrategy: selectedStrategy,
                selectedTarget: _selectedDay == null
                    ? null
                    : targets[_selectedDay],
                dayTarget: targets[CalendarDay.dayOnly(day.date)],
              );
              return _MealHistoryDayRow(
                dateLabel: AppDates.md(day.date, widget.locale),
                detailLabel: widget.labelFor(day),
                detailStyle: highlighted ? highlightStyle : muted,
                onTap: !day.hasActivity
                    ? null
                    : () async {
                        setState(
                          () => _selectedDay = CalendarDay.dayOnly(day.date),
                        );
                        await context.push(dailyMealsPath(day.date));
                        if (!mounted) return;
                        setState(() => _targets = _loadTargets());
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class _MealHistoryDayRow extends StatelessWidget {
  const _MealHistoryDayRow({
    required this.dateLabel,
    required this.detailLabel,
    required this.detailStyle,
    required this.onTap,
  });

  final String dateLabel;
  final String detailLabel;
  final TextStyle? detailStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = AppThemeVisuals.of(context).divider;
    return Material(
      color: Colors.transparent,
      shape: Border(bottom: BorderSide(color: divider)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MenuIconBadge(
                color: AppColors.carb,
                child: InkIcon(InkGlyph.food, color: AppColors.carb),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateLabel, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(detailLabel, style: detailStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
