import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/workout_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../records/log_set_sheet.dart';
import '../records/train_records_tab.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/form_options.dart';
import 'today_section_header.dart';

/// Today's planned workout checklist with set logging.
///
/// Collapsible: the header is always shown, the checklist only when
/// [expanded]. The plain "+" opens the existing add-workout flow and never
/// toggles the block.
class TodayWorkoutCard extends ConsumerWidget {
  const TodayWorkoutCard({
    super.key,
    required this.day,
    required this.sectionPrefix,
    this.showDetails = false,
  });

  final DateTime day;
  final String sectionPrefix;
  final bool showDetails;

  String _groupTitle(DayWorkoutGroup group, AppLocalizations l10n) {
    final name = group.workout.planName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.untitledWorkoutGroup;
  }

  Future<void> _pickPlan(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (!AppDates.isLocalToday(day)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pastDayReadOnly)));
      return;
    }
    final plans = await ref.read(workoutRepositoryProvider).listPlanSummaries();
    if (!context.mounted) return;
    if (plans.isEmpty) {
      final go = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.noWorkoutPlanTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.noWorkoutPlanBody),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.tabPlans),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.exercise),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (!context.mounted) return;
      if (go == true) {
        context.go('/records?tab=train&sub=plans');
      } else if (go == false) {
        context.go('/records?tab=train&sub=library');
      }
      return;
    }

    final choice = await showModalBottomSheet<Object>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.quickAddExercise),
                onTap: () => Navigator.pop(ctx, 'quick'),
              ),
              const Divider(height: 1),
              for (final p in plans)
                ListTile(
                  title: Text(p.plan.name),
                  subtitle: Text(
                    p.items
                        .map(
                          (i) =>
                              '${i.exerciseName} ${i.targetSets}×${i.targetReps}',
                        )
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(ctx, p),
                ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'quick') {
      await showQuickAddDayItemDialog(context: context, ref: ref, day: day);
      return;
    }
    if (choice is WorkoutPlanSummary) {
      try {
        await ref
            .read(workoutRepositoryProvider)
            .applyPlanToDay(planId: choice.plan.id, day: day);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
      }
    }
  }

  Future<void> _copyYesterday(
    BuildContext context,
    WidgetRef ref, {
    int? sourceDayWorkoutId,
  }) async {
    final l10n = context.l10n;
    final from = day.subtract(const Duration(days: 1));
    final existing = await ref.read(workoutRepositoryProvider).daySnapshot(day);
    if (!existing.isEmpty) {
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.copyYesterdayWorkout),
          content: Text(l10n.copyYesterdayWorkoutConfirm),
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
    try {
      final result = await ref
          .read(workoutRepositoryProvider)
          .copyDayWorkout(
            from: from,
            to: day,
            sourceDayWorkoutId: sourceDayWorkoutId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.itemsCopied == 0
                ? l10n.yesterdayNoWorkout
                : l10n.copiedWorkoutItems(result.itemsCopied),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
    }
  }

  Future<void> _saveAsPlan(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final snap = await ref.read(workoutRepositoryProvider).daySnapshot(day);
    if (!context.mounted) return;
    if (snap.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noWorkoutToSave)));
      return;
    }
    String? existingName;
    for (final group in snap.groups) {
      final name = group.workout.planName?.trim();
      if (name != null && name.isNotEmpty) {
        existingName = name;
        break;
      }
    }
    final nameCtrl = TextEditingController(
      text: (existingName != null && existingName.isNotEmpty)
          ? existingName
          : AppDates.relativeDayTitle(day, AppDates.todayLocal(), l10n, locale),
    );
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveAsPlan),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.planName,
            hintText: l10n.planNameHint,
          ),
          autofocus: true,
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
    final planName = nameCtrl.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => nameCtrl.dispose());
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(workoutRepositoryProvider)
          .createPlanFromDay(day: day, name: planName);
      ref.invalidate(workoutPlansProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.planSaved)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    }
  }

  Future<void> _removeGroup(
    BuildContext context,
    WidgetRef ref,
    DayWorkoutGroup group,
  ) async {
    final l10n = context.l10n;
    final title = _groupTitle(group, l10n);
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeDayWorkout),
        content: Text(l10n.confirmRemoveDayWorkout(title)),
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
    if (ok != true || !context.mounted) return;
    await ref
        .read(workoutRepositoryProvider)
        .deleteDayWorkout(group.workout.id);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(allWorkoutHistoryProvider);
  }

  Widget _headerRow({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required bool canAdd,
    required bool canCopyYesterday,
    required bool canSaveAsPlan,
    required List<DayWorkoutGroup> yesterdayGroups,
    required String? summary,
  }) {
    return TodaySectionHeader(
      title: l10n.sectionWorkout(sectionPrefix),
      summary: summary,
      addLabel: canAdd ? l10n.addTodayWorkout : null,
      onAdd: canAdd ? () => _pickPlan(context, ref) : null,
      trailing: [
        if (canCopyYesterday && yesterdayGroups.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: l10n.copyYesterday,
            icon: const Icon(Icons.more_horiz),
            onSelected: (id) =>
                _copyYesterday(context, ref, sourceDayWorkoutId: id),
            itemBuilder: (context) => [
              for (final group in yesterdayGroups)
                PopupMenuItem(
                  value: group.workout.id,
                  child: Text(_groupTitle(group, l10n)),
                ),
            ],
          ),
        if (canSaveAsPlan)
          PopupMenuButton<String>(
            tooltip: l10n.more,
            onSelected: (value) async {
              if (value == 'savePlan') {
                await _saveAsPlan(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'savePlan',
                child: Text(l10n.saveAsPlan),
              ),
            ],
          ),
      ],
    );
  }

  Widget _itemTile({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required DayWorkoutItemProgress progress,
    required bool editable,
  }) {
    if (!editable) {
      return _WorkoutItemTile(progress: progress, day: day, editable: false);
    }
    return Dismissible(
      key: ValueKey(progress.item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: AppSpacing.field),
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.deleteWorkoutItem),
                content: Text(
                  l10n.confirmDeleteWorkoutItem(progress.item.exerciseName),
                ),
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
        ref
            .read(workoutRepositoryProvider)
            .deleteDayWorkoutItem(progress.item.id);
        ref.invalidate(workoutHistoryProvider);
        ref.invalidate(allWorkoutHistoryProvider);
      },
      child: _WorkoutItemTile(progress: progress, day: day, editable: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(dayWorkoutProvider(day));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editable = AppDates.isLocalToday(day);
    final yesterdayGroups = editable
        ? (ref
                  .watch(
                    dayWorkoutProvider(day.subtract(const Duration(days: 1))),
                  )
                  .value
                  ?.groups ??
              const <DayWorkoutGroup>[])
        : const <DayWorkoutGroup>[];
    final canCopyYesterday = editable && yesterdayGroups.isNotEmpty;

    return async.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(
            context: context,
            ref: ref,
            l10n: l10n,
            canAdd: editable,
            canCopyYesterday: canCopyYesterday,
            canSaveAsPlan: false,
            yesterdayGroups: yesterdayGroups,
            summary: null,
          ),
          const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (e, _) => Text(l10n.workoutLoadFailed('$e')),
      data: (snapshot) {
        final canSaveAsPlan = !snapshot.isEmpty;
        if (snapshot.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(
                context: context,
                ref: ref,
                l10n: l10n,
                canAdd: editable,
                canCopyYesterday: canCopyYesterday,
                canSaveAsPlan: canSaveAsPlan,
                yesterdayGroups: yesterdayGroups,
                summary: l10n.noWorkoutShort,
              ),
              SportEmptyState(
                icon: Icons.fitness_center,
                title: editable
                    ? l10n.noWorkoutPlannedTitle
                    : l10n.noWorkoutThatDay,
                message: editable
                    ? l10n.noWorkoutPlannedHint
                    : l10n.pastDayReadOnly,
              ),
            ],
          );
        }

        final done = snapshot.doneCount;
        final total = snapshot.items.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerRow(
              context: context,
              ref: ref,
              l10n: l10n,
              canAdd: editable,
              canCopyYesterday: canCopyYesterday,
              canSaveAsPlan: canSaveAsPlan,
              yesterdayGroups: yesterdayGroups,
              summary: '$done/$total',
            ),
            if (!showDetails) ...[
              for (final group in snapshot.groups)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_groupTitle(group, l10n)),
                  subtitle: Text(
                    l10n.workoutProgressHint(
                      group.doneCount,
                      group.items.length,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward, size: 18),
                  onTap: () => showDayWorkoutDetails(context, day),
                ),
              SportProgressBar(
                value: total == 0 ? 0 : done / total,
                minHeight: 4,
              ),
              TextButton(
                onPressed: () => showDayWorkoutDetails(context, day),
                child: Text(
                  editable ? l10n.continueRecording : l10n.viewWorkoutDetails,
                ),
              ),
            ],
            if (showDetails) ...[
              const SizedBox(height: 4),
              for (final group in snapshot.groups)
                _DayWorkoutGroupTile(
                  title: _groupTitle(group, l10n),
                  done: group.doneCount,
                  total: group.items.length,
                  canRemove: editable,
                  onRemove: () => _removeGroup(context, ref, group),
                  children: [
                    for (final progress in group.items)
                      _itemTile(
                        context: context,
                        ref: ref,
                        l10n: l10n,
                        scheme: scheme,
                        progress: progress,
                        editable: editable,
                      ),
                  ],
                ),
              Text(
                l10n.workoutProgressHint(done, total),
                style: theme.textTheme.meta,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DayWorkoutGroupTile extends StatelessWidget {
  const _DayWorkoutGroupTile({
    required this.title,
    required this.done,
    required this.total,
    required this.children,
    required this.canRemove,
    required this.onRemove,
  });
  final String title;
  final int done;
  final int total;
  final List<Widget> children;
  final bool canRemove;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('$done/$total'),
        trailing: canRemove
            ? IconButton(
                tooltip: context.l10n.removeDayWorkout,
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              )
            : null,
      ),
      ...children,
      const Divider(),
    ],
  );
}

Future<void> showDayWorkoutDetails(BuildContext context, DateTime day) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .9,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: TodayWorkoutCard(
              day: day,
              sectionPrefix: AppDates.isLocalToday(day)
                  ? context.l10n.today
                  : context.l10n.sectionThatDay,
              showDetails: true,
            ),
          ),
        ),
      ),
    );

class _WorkoutItemTile extends ConsumerWidget {
  const _WorkoutItemTile({
    required this.progress,
    required this.day,
    required this.editable,
  });

  final DayWorkoutItemProgress progress;
  final DateTime day;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final item = progress.item;
    final unitLabel = progress.unit.label(l10n);
    final theme = Theme.of(context);
    final note = item.note?.trim();
    final weightKg = item.actualWeightKg;
    final progressLine = item.done
        ? l10n.completed
        : l10n.setsProgress(
            progress.completedSets,
            item.targetSets,
            '${item.targetReps}',
            unitLabel,
          );
    final metaStyle = theme.textTheme.meta;
    final weightSpans = weightKg == null
        ? null
        : <InlineSpan>[
            TextSpan(
              text:
                  '${formatKg(FormOptions.fromKg(weightKg, GymWeightUnit.kg))} '
                  '${GymWeightUnit.kg.suffix} ',
            ),
            TextSpan(
              text: '|',
              style: metaStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text:
                  ' ${formatKg(FormOptions.fromKg(weightKg, GymWeightUnit.lbs))} '
                  '${GymWeightUnit.lbs.suffix}',
            ),
          ];

    return SportListTile(
      leading: Checkbox(
        value: item.done,
        onChanged: editable
            ? (v) {
                ref
                    .read(workoutRepositoryProvider)
                    .setItemDone(item.id, v ?? false);
              }
            : null,
      ),
      title: Text(
        item.exerciseName,
        style: item.done
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : theme.textTheme.bodyLarge,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: metaStyle,
              children: [
                TextSpan(text: progressLine),
                if (weightSpans != null) ...[
                  const TextSpan(text: ' · '),
                  ...weightSpans,
                ],
              ],
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note,
              style: metaStyle?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      enabled: editable,
      onTap: !editable
          ? null
          : () async {
              await showLogSetSheet(
                context: context,
                ref: ref,
                day: day,
                exerciseName: item.exerciseName,
                unit: progress.unit,
                dayWorkoutItemId: item.id,
                completedSets: progress.completedSets,
                targetSets: item.targetSets,
                perSetValue: item.targetReps,
                initialActualWeightKg: item.actualWeightKg,
                initialActualWeightUnit: item.actualWeightUnit,
                initialNote: item.note,
              );
              ref.invalidate(workoutHistoryProvider);
              ref.invalidate(allWorkoutHistoryProvider);
            },
    );
  }
}
