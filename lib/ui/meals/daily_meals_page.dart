import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/food_name_link.dart';
import '../widgets/search_field_focus.dart';

/// Route to the full daily food-log page (board 01.04).
String dailyMealsPath(DateTime day) {
  final key = DateFormat('yyyy-MM-dd').format(AppDates.dayOnly(day));
  return '/day-meals?date=$key';
}

/// Full per-day food log: every meal type with its entries (or an "add"
/// affordance when a type has none). History dates are read-only and use
/// their stored records.
class DailyMealsPage extends ConsumerWidget {
  const DailyMealsPage({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final day = AppDates.dayOnly(date);
    final editable = AppDates.isLocalToday(day);
    final today = AppDates.todayLocal();
    final earliest = DateTime(today.year - 1, today.month, today.day);
    final mealsAsync = ref.watch(mealsForDayProvider(day));
    final yesterday = day.subtract(const Duration(days: 1));
    final yesterdayMeals = editable
        ? ref.watch(mealsForDayProvider(yesterday)).value ?? const []
        : const <MealEntry>[];

    void go(DateTime d) => context.pushReplacement(dailyMealsPath(d));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.prevDay,
              visualDensity: VisualDensity.compact,
              onPressed: day.isAfter(earliest)
                  ? () => go(day.subtract(const Duration(days: 1)))
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(AppDates.mdWithWeekday(day, locale)),
            IconButton(
              tooltip: l10n.nextDay,
              visualDensity: VisualDensity.compact,
              onPressed: day.isBefore(today)
                  ? () => go(day.add(const Duration(days: 1)))
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SportLoadError(
          onRetry: () => ref.invalidate(mealsForDayProvider(day)),
        ),
        data: (meals) {
          final total = meals.fold<double>(0, (s, m) => s + m.calories);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.listPage,
              8,
              AppSpacing.listPage,
              listBottomInset(context, hasFab: false),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mealsRecordSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${total.round()} kcal',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (editable && yesterdayMeals.isNotEmpty)
                    IconButton(
                      tooltip: l10n.copyYesterday,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.content_copy, size: 18),
                      onPressed: () =>
                          copyYesterdayMealType(context, ref, day, yesterdayMeals),
                    ),
                  if (editable)
                    PlainIconAction(
                      icon: Icons.add,
                      label: l10n.logMeal,
                      onPressed: () {
                        unfocusForNavigation();
                        context.push(
                          '/log-meal?mealType=${MealType.suggestedFor(DateTime.now()).name}'
                          '&openDayMealsAfterSearchAdd=0',
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (final type in MealType.values)
                _MealTypeSection(
                  day: day,
                  type: type,
                  entries: meals.where((m) => m.mealType == type.name).toList()
                    ..sort((a, b) => a.calories.compareTo(b.calories)),
                  editable: editable,
                  canCopyYesterday: editable &&
                      yesterdayMeals.any((m) => m.mealType == type.name),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Lets the user pick one of yesterday's logged meal types and copy just
/// that one onto [day] — a shortcut for the same [MealRepository.copyDay]
/// call already offered per-section, without opening each section's menu.
Future<void> copyYesterdayMealType(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
  List<MealEntry> yesterdayMeals,
) async {
  final l10n = context.l10n;
  final available = [
    for (final t in MealType.values)
      if (yesterdayMeals.any((m) => m.mealType == t.name)) t,
  ];
  if (available.isEmpty) return;
  final chosen = await showModalBottomSheet<MealType>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in available)
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: Text(l10n.yesterdayNamed(t.label(l10n))),
              onTap: () => Navigator.pop(ctx, t),
            ),
        ],
      ),
    ),
  );
  if (chosen == null || !context.mounted) return;
  await copyMealTypeFromYesterday(
    context: context,
    ref: ref,
    day: day,
    mealType: chosen,
  );
}

/// Copies a single [mealType] from yesterday onto [day].
Future<void> copyMealTypeFromYesterday({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime day,
  required MealType mealType,
}) async {
  final l10n = context.l10n;
  final from = day.subtract(const Duration(days: 1));
  final existingToday = await ref.read(mealRepositoryProvider).forDay(day);
  final hasToday = existingToday.any((m) => m.mealType == mealType.name);
  if (hasToday) {
    if (!context.mounted) return;
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
  if (!context.mounted) return;
  final result = await ref
      .read(mealRepositoryProvider)
      .copyDay(from: from, to: day, mealType: mealType);
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
}

class _MealTypeSection extends ConsumerWidget {
  const _MealTypeSection({
    required this.day,
    required this.type,
    required this.entries,
    required this.editable,
    required this.canCopyYesterday,
  });

  final DateTime day;
  final MealType type;
  final List<MealEntry> entries;
  final bool editable;
  final bool canCopyYesterday;

  Future<void> _copyYesterday(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final from = day.subtract(const Duration(days: 1));
    if (entries.isNotEmpty) {
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
    if (!context.mounted) return;
    final result = await ref
        .read(mealRepositoryProvider)
        .copyDay(from: from, to: day, mealType: type);
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
  }

  Future<bool> _confirmClearMeal(BuildContext context) async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.clearThisMeal),
            content: Text(l10n.confirmClearMeal(type.label(l10n))),
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
  }

  Future<void> _saveAsPreset(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noLogsToSave)));
      return;
    }
    final nameCtrl = TextEditingController(text: type.label(l10n));
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
          .createFromEntries(name: presetName, entries: entries);
      ref.invalidate(mealPresetsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.presetSaved)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final kcal = entries.fold<double>(0, (s, m) => s + m.calories);
    final canSaveAsPreset = entries.isNotEmpty;
    final canClear = editable && entries.isNotEmpty;
    final showMenu = canCopyYesterday || canSaveAsPreset;

    final headerRow = Row(
      children: [
        Expanded(
          child: Text(type.label(l10n), style: theme.textTheme.titleSmall),
        ),
        Text(
          entries.isEmpty ? l10n.mealNotLogged : '${kcal.round()} kcal',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (editable && entries.isNotEmpty)
          IconButton(
            tooltip: l10n.addMealNamed(type.label(l10n)),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              unfocusForNavigation();
              context.push(
                '/log-meal?mealType=${type.name}&openDayMealsAfterSearchAdd=0',
              );
            },
          ),
        if (showMenu)
          PopupMenuButton<String>(
            tooltip: l10n.more,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_horiz,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (value) => switch (value) {
              'copy' => _copyYesterday(context, ref),
              _ => _saveAsPreset(context, ref),
            },
            itemBuilder: (context) => [
              if (canCopyYesterday)
                PopupMenuItem(
                  value: 'copy',
                  child: Text(
                    l10n.copyNamed(l10n.yesterdayNamed(type.label(l10n))),
                  ),
                ),
              if (canSaveAsPreset)
                PopupMenuItem(
                  value: 'preset',
                  child: Text(l10n.saveAsPreset),
                ),
            ],
          ),
      ],
    );

    // Swipe left on the meal-type header to clear it — replaces the old
    // "清空这一餐" menu entry with the same swipe-to-delete affordance used
    // for individual entries below.
    final header = canClear
        ? Dismissible(
            key: ValueKey('meal-header-${type.name}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: theme.colorScheme.error,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) => _confirmClearMeal(context),
            onDismissed: (_) =>
                ref.read(mealRepositoryProvider).deleteMealType(day, type),
            child: headerRow,
          )
        : headerRow;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.card),
        header,
        if (entries.isEmpty)
          editable
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      unfocusForNavigation();
                      context.push(
                        '/log-meal?mealType=${type.name}'
                        '&openDayMealsAfterSearchAdd=0',
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addMealNamed(type.label(l10n))),
                  ),
                )
              : const Divider()
        else
          for (final m in entries)
            _MealEntryTile(entry: m, canDismiss: editable),
      ],
    );

    if (!editable) return content;

    // Long-press-drag a food from another meal section drops it here,
    // moving it to this meal type.
    return DragTarget<MealEntry>(
      onWillAcceptWithDetails: (details) => details.data.mealType != type.name,
      onAcceptWithDetails: (details) => ref
          .read(mealRepositoryProvider)
          .moveMealType(id: details.data.id, mealType: type),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: highlighted
                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: content,
        );
      },
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
      contentPadding: EdgeInsets.zero,
      title: FoodNameLink(
        name: m.foodName,
        foodId: m.foodId,
        carbG: m.carbG,
        proteinG: m.proteinG,
        fatG: m.fatG,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        '${m.grams.toStringAsFixed(0)} g · '
        'P ${m.proteinG.toStringAsFixed(0)} · '
        'C ${m.carbG.toStringAsFixed(0)} · '
        'F ${m.fatG.toStringAsFixed(0)}',
        style: theme.textTheme.meta,
      ),
      trailing: Text(
        '${m.calories.round()} kcal',
        style: theme.textTheme.titleSmall,
      ),
      onTap: () => context.push('/meal/${m.id}'),
    );
    if (!canDismiss) return tile;
    final dismissible = Dismissible(
      key: ValueKey(m.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: scheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async =>
          await showDialog<bool>(
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
          true,
      onDismissed: (_) => ref.read(mealRepositoryProvider).delete(m.id),
      child: tile,
    );
    // Long-press to drag this food into a different meal section.
    return LongPressDraggable<MealEntry>(
      data: m,
      axis: Axis.vertical,
      feedback: Material(
        elevation: 4,
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              m.foodName,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: dismissible),
      child: dismissible,
    );
  }
}
