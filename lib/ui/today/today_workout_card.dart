import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/workout_repository.dart';
import '../../domain/calendar_day.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../records/log_set_sheet.dart';
import '../ink/ink_icon.dart';
import '../records/train_records_tab.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/form_options.dart';
import '../widgets/search_field_focus.dart';
import 'today_section_header.dart';

/// Today's planned workout checklist with set logging.
///
/// Collapsible: the header is always shown, the checklist only when
/// [expanded]. The plain "+" opens the existing add-workout flow and never
/// toggles the block.
class TodayWorkoutCard extends ConsumerStatefulWidget {
  const TodayWorkoutCard({
    super.key,
    required this.day,
    required this.sectionPrefix,
    this.showDetails = false,
  });

  final DateTime day;
  final String sectionPrefix;
  final bool showDetails;

  @override
  ConsumerState<TodayWorkoutCard> createState() => _TodayWorkoutCardState();
}

class _TodayWorkoutCardState extends ConsumerState<TodayWorkoutCard> {
  // Optimistic local ordering: dragging a group/item updates these
  // immediately (before the async DB write round-trips through the
  // watchDayWorkout stream), so ReorderableListView animates smoothly
  // instead of snapping/flickering once the new snapshot arrives. The
  // stream's own order is only used as a fallback for ids we haven't
  // reordered locally yet (new items, or on first load).
  List<int>? _groupOrder;
  final Map<int, List<int>> _itemOrder = {};

  @override
  void didUpdateWidget(covariant TodayWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) {
      _groupOrder = null;
      _itemOrder.clear();
    }
  }

  List<DayWorkoutGroup> _orderedGroups(List<DayWorkoutGroup> groups) {
    final order = _groupOrder;
    if (order == null) return groups;
    final byId = {for (final g in groups) g.workout.id: g};
    final result = <DayWorkoutGroup>[];
    for (final id in order) {
      final g = byId.remove(id);
      if (g != null) result.add(g);
    }
    result.addAll(byId.values);
    return result;
  }

  List<DayWorkoutItemProgress> _orderedItems(
    int dayWorkoutId,
    List<DayWorkoutItemProgress> items,
  ) {
    final order = _itemOrder[dayWorkoutId];
    if (order == null) return items;
    final byId = {for (final p in items) p.item.id: p};
    final result = <DayWorkoutItemProgress>[];
    for (final id in order) {
      final p = byId.remove(id);
      if (p != null) result.add(p);
    }
    result.addAll(byId.values);
    return result;
  }

  String _groupTitle(DayWorkoutGroup group, AppLocalizations l10n) {
    final name = group.workout.planName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.untitledWorkoutGroup;
  }

  Future<void> _pickPlan(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (!AppDates.isLocalToday(widget.day)) {
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
                leading: const InkIcon(InkGlyph.add),
                title: Text(l10n.quickAddExercise),
                onTap: () => Navigator.pop(ctx, 'quick'),
              ),
              ListTile(
                leading: const InkIcon(InkGlyph.playlistAdd),
                title: Text(l10n.quickAddPlan),
                onTap: () => Navigator.pop(ctx, 'quickPlan'),
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
      await showQuickAddDayItemDialog(
        context: context,
        ref: ref,
        day: widget.day,
      );
      return;
    }
    if (choice == 'quickPlan') {
      final router = GoRouter.of(context);
      // Details sheet is itself a root modal; dismiss it before the plan editor
      // so it isn't still covering Today when the user comes back.
      if (widget.showDetails) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await router.push('/records/plan');
      return;
    }
    if (choice is WorkoutPlanSummary) {
      try {
        await ref
            .read(workoutRepositoryProvider)
            .applyPlanToDay(planId: choice.plan.id, day: widget.day);
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
    final from = widget.day.subtract(const Duration(days: 1));
    final existing = await ref
        .read(workoutRepositoryProvider)
        .daySnapshot(widget.day);
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
            to: widget.day,
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
    final snap = await ref
        .read(workoutRepositoryProvider)
        .daySnapshot(widget.day);
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
          : AppDates.relativeDayTitle(
              widget.day,
              AppDates.todayLocal(),
              l10n,
              locale,
            ),
    );
    final nameFocus = FocusNode();
    suppressInitialTextFocus(nameFocus);
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveAsPlan),
        content: TextField(
          controller: nameCtrl,
          focusNode: nameFocus,
          decoration: InputDecoration(
            labelText: l10n.planName,
            hintText: l10n.planNameHint,
          ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameCtrl.dispose();
      nameFocus.dispose();
    });
    final planName = nameCtrl.text;
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(workoutRepositoryProvider)
          .createPlanFromDay(day: widget.day, name: planName);
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

  Future<bool> _confirmRemoveGroup(
    BuildContext context,
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
    return ok == true;
  }

  Future<void> _removeGroup(WidgetRef ref, DayWorkoutGroup group) async {
    await ref
        .read(workoutRepositoryProvider)
        .deleteDayWorkout(group.workout.id);
    _itemOrder.remove(group.workout.id);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(allWorkoutHistoryProvider);
  }

  void _editGroupPlan(BuildContext context, DayWorkoutGroup group) {
    final planId = group.workout.planId;
    if (planId == null) return;
    Navigator.of(context, rootNavigator: true).pop(
      _EditDayWorkoutPlan(planId: planId, day: CalendarDay.dayOnly(widget.day)),
    );
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
      title: l10n.sectionWorkout(widget.sectionPrefix),
      summary: summary,
      addLabel: canAdd ? l10n.addTodayWorkout : null,
      onAdd: canAdd ? () => _pickPlan(context, ref) : null,
      trailing: [
        if (canCopyYesterday && yesterdayGroups.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: l10n.copyYesterday,
            icon: const InkIcon(InkGlyph.more),
            onSelected: (id) =>
                _copyYesterday(context, ref, sourceDayWorkoutId: id),
            itemBuilder: (context) => [
              for (final group in yesterdayGroups)
                PopupMenuItem(
                  value: group.workout.id,
                  child: Text(
                    l10n.copyNamed(
                      l10n.yesterdayNamed(_groupTitle(group, l10n)),
                    ),
                  ),
                ),
            ],
          ),
        if (canSaveAsPlan)
          PopupMenuButton<String>(
            tooltip: l10n.more,
            icon: const InkIcon(InkGlyph.moreVertical),
            onSelected: (value) async {
              if (value == 'savePlan') {
                await _saveAsPlan(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'savePlan', child: Text(l10n.saveAsPlan)),
            ],
          ),
      ],
    );
  }

  Widget _groupTile({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required DayWorkoutGroup group,
    required bool editable,
  }) {
    return Dismissible(
      key: ValueKey('day-workout-group-${group.workout.id}'),
      direction: editable ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: scheme.error,
        child: const InkIcon(InkGlyph.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmRemoveGroup(context, group),
      onDismissed: (_) => _removeGroup(ref, group),
      child: _DayWorkoutGroupTile(
        title: _groupTitle(group, l10n),
        done: group.doneCount,
        total: group.items.length,
        onTap: group.workout.planId == null
            ? null
            : () => _editGroupPlan(context, group),
        children: [
          _itemsList(
            context: context,
            ref: ref,
            l10n: l10n,
            scheme: scheme,
            group: group,
            editable: editable,
          ),
        ],
      ),
    );
  }

  /// Renders today's workout groups (plans); when [editable] and there's more
  /// than one, wraps them in a drag-to-reorder list so the plan order itself
  /// can be resequenced (independent of the per-plan exercise reordering in
  /// [_itemsList]). The displayed order always goes through [_orderedGroups]
  /// so a drag is reflected immediately, without waiting for the underlying
  /// stream to re-emit.
  Widget _groupsList({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required List<DayWorkoutGroup> groups,
    required bool editable,
  }) {
    final ordered = _orderedGroups(groups);
    if (!editable || ordered.length < 2) {
      return Column(
        children: [
          for (final group in ordered)
            _groupTile(
              context: context,
              ref: ref,
              l10n: l10n,
              scheme: scheme,
              group: group,
              editable: editable,
            ),
        ],
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: ordered.length,
      onReorderItem: (oldIndex, newIndex) async {
        final previousOrder = _groupOrder;
        final ids = [for (final g in ordered) g.workout.id];
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        setState(() => _groupOrder = ids);
        try {
          await ref
              .read(workoutRepositoryProvider)
              .reorderDayWorkoutGroups(
                day: widget.day,
                orderedDayWorkoutIds: ids,
              );
        } catch (_) {
          if (mounted) setState(() => _groupOrder = previousOrder);
        }
      },
      itemBuilder: (context, i) {
        final group = ordered[i];
        return Row(
          key: ValueKey('day-workout-group-row-${group.workout.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: InkIcon(
                  InkGlyph.dragHandle,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: _groupTile(
                context: context,
                ref: ref,
                l10n: l10n,
                scheme: scheme,
                group: group,
                editable: editable,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Renders a group's items; when [editable] and there's more than one,
  /// wraps them in a drag-to-reorder list so today's plan can be resequenced.
  /// Like [_groupsList], the displayed order goes through [_orderedItems] so
  /// dragging feels immediate instead of waiting on the stream round-trip.
  Widget _itemsList({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required DayWorkoutGroup group,
    required bool editable,
  }) {
    final dayWorkoutId = group.workout.id;
    final ordered = _orderedItems(dayWorkoutId, group.items);
    if (!editable || ordered.length < 2) {
      return Column(
        children: [
          for (final progress in ordered)
            _itemTile(
              context: context,
              ref: ref,
              l10n: l10n,
              scheme: scheme,
              progress: progress,
              editable: editable,
            ),
        ],
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: ordered.length,
      onReorderItem: (oldIndex, newIndex) async {
        final previousOrder = _itemOrder[dayWorkoutId];
        final ids = [for (final p in ordered) p.item.id];
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        setState(() => _itemOrder[dayWorkoutId] = ids);
        try {
          await ref
              .read(workoutRepositoryProvider)
              .reorderDayWorkoutItems(
                dayWorkoutId: dayWorkoutId,
                orderedItemIds: ids,
              );
        } catch (_) {
          if (mounted) {
            setState(() {
              if (previousOrder == null) {
                _itemOrder.remove(dayWorkoutId);
              } else {
                _itemOrder[dayWorkoutId] = previousOrder;
              }
            });
          }
        }
      },
      itemBuilder: (context, i) {
        final progress = ordered[i];
        return Row(
          key: ValueKey('day-workout-item-${progress.item.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: InkIcon(
                  InkGlyph.dragHandle,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: _itemTile(
                context: context,
                ref: ref,
                l10n: l10n,
                scheme: scheme,
                progress: progress,
                editable: editable,
              ),
            ),
          ],
        );
      },
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
      return _WorkoutItemTile(
        progress: progress,
        day: widget.day,
        editable: false,
      );
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
        child: const InkIcon(InkGlyph.delete, color: Colors.white),
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
      child: _WorkoutItemTile(
        progress: progress,
        day: widget.day,
        editable: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(dayWorkoutProvider(widget.day));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final editable = AppDates.isLocalToday(widget.day);
    final yesterdayGroups = editable
        ? (ref
                  .watch(
                    dayWorkoutProvider(
                      widget.day.subtract(const Duration(days: 1)),
                    ),
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
                iconWidget: const StampedInkEmptyIcon(
                  glyph: InkGlyph.training,
                  seal: '炼',
                ),
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
        final orderedGroups = _orderedGroups(snapshot.groups);

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
            if (!widget.showDetails) ...[
              for (var i = 0; i < orderedGroups.length; i++) ...[
                if (i > 0) Divider(height: 1, color: visuals.divider),
                InkWell(
                  onTap: () => showDayWorkoutDetails(context, widget.day),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 28,
                          decoration: BoxDecoration(
                            color: visuals.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _groupTitle(orderedGroups[i], l10n),
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                l10n.workoutProgressHint(
                                  orderedGroups[i].doneCount,
                                  orderedGroups[i].items.length,
                                ),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const InkIcon(InkGlyph.arrowForward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
              InkBrushProgressBar(value: total == 0 ? 0 : done / total),
              TextButton(
                onPressed: () => showDayWorkoutDetails(context, widget.day),
                child: Text(
                  editable ? l10n.continueRecording : l10n.viewWorkoutDetails,
                ),
              ),
            ],
            if (widget.showDetails) ...[
              const SizedBox(height: 4),
              _groupsList(
                context: context,
                ref: ref,
                l10n: l10n,
                scheme: scheme,
                groups: snapshot.groups,
                editable: editable,
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
    required this.onTap,
  });
  final String title;
  final int done;
  final int total;
  final List<Widget> children;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('$done/$total'),
        trailing: onTap == null
            ? null
            : const InkIcon(InkGlyph.chevronRight, size: 20),
        onTap: onTap,
      ),
      ...children,
      const Divider(),
    ],
  );
}

sealed class _DayWorkoutDetailsAction {
  const _DayWorkoutDetailsAction();
}

class _EditDayWorkoutPlan extends _DayWorkoutDetailsAction {
  const _EditDayWorkoutPlan({required this.planId, required this.day});

  final int planId;
  final DateTime day;

  String get path => Uri(
    path: '/records/plan',
    queryParameters: {'id': '$planId', 'syncDay': day.toIso8601String()},
  ).toString();
}

Future<void> showDayWorkoutDetails(BuildContext context, DateTime day) async {
  while (true) {
    if (!context.mounted) return;
    final action = await showModalBottomSheet<_DayWorkoutDetailsAction>(
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

    if (action is! _EditDayWorkoutPlan || !context.mounted) return;
    await context.push<void>(action.path);
  }
}

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
    final unitLabel = progress.unit.label(l10n, category: progress.category);
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
      leading: _InkDoneToggle(
        value: item.done,
        onChanged: editable
            ? (v) {
                ref.read(workoutRepositoryProvider).setItemDone(item.id, v);
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
                TextSpan(
                  text: progressLine,
                  style: item.done
                      ? metaStyle?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                ),
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
                category: progress.category,
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

class _InkDoneToggle extends StatelessWidget {
  const _InkDoneToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      checked: value,
      enabled: onChanged != null,
      button: true,
      child: InkResponse(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: InkIcon(
              value ? InkGlyph.check : InkGlyph.radioEmpty,
              size: 30,
              color: onChanged == null
                  ? scheme.onSurface.withValues(alpha: .32)
                  : value
                  ? AppColors.success
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
