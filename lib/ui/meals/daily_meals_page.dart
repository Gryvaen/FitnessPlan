import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/macro_color.dart';
import '../theme/sport_chrome.dart';

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
                      onPressed: () => context.push(
                        '/log-meal?mealType=${MealType.suggestedFor(DateTime.now()).name}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (final type in MealType.values)
                _MealTypeSection(
                  day: day,
                  type: type,
                  entries: meals
                      .where((m) => m.mealType == type.name)
                      .toList(growable: false),
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
              title: Text(t.label(l10n)),
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

  Future<void> _clearMeal(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
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
    );
    if (ok != true) return;
    await ref.read(mealRepositoryProvider).deleteMealType(day, type);
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
    final presetName = nameCtrl.text;
    // Defer dispose until after the dialog route finishes unmounting.
    WidgetsBinding.instance.addPostFrameCallback((_) => nameCtrl.dispose());
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
    final showMenu = canCopyYesterday || canSaveAsPreset || canClear;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.card),
        Row(
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
                onPressed: () =>
                    context.push('/log-meal?mealType=${type.name}'),
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
                  'clear' => _clearMeal(context, ref),
                  _ => _saveAsPreset(context, ref),
                },
                itemBuilder: (context) => [
                  if (canCopyYesterday)
                    PopupMenuItem(
                      value: 'copy',
                      child: Text(l10n.copyYesterday),
                    ),
                  if (canSaveAsPreset)
                    PopupMenuItem(
                      value: 'preset',
                      child: Text(l10n.saveAsPreset),
                    ),
                  if (canClear)
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(l10n.clearThisMeal),
                    ),
                ],
              ),
          ],
        ),
        if (entries.isEmpty)
          editable
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        context.push('/log-meal?mealType=${type.name}'),
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
      title: Text(
        m.foodName,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: dominantMacroColor(
            carbG: m.carbG,
            proteinG: m.proteinG,
            fatG: m.fatG,
          ),
        ),
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
    return Dismissible(
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
  }
}
