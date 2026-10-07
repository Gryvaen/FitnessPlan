import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/calendar_day.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../records/log_set_sheet.dart';
import '../ink/ink_icon.dart';
import '../records/plan_edit_page.dart';
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
  final Map<int, GlobalKey> _planGroupKeys = {};

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

  Widget _historyLink(BuildContext context) {
    if (widget.showDetails) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          unfocusForNavigation();
          context.go('/records?tab=train&sub=history');
        },
        child: Text(context.l10n.viewHistoryRecords),
      ),
    );
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
      isScrollControlled: true,
      builder: (ctx) => _TodayPlanPickerSheet(plans: plans),
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
      await showPlanEditSheet(context: context);
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
            result.itemsCopied == 0 && result.groupsSkippedDuplicate > 0
                ? l10n.nothingNewToAppend
                : result.itemsCopied == 0
                ? l10n.yesterdayNoWorkout
                : '${l10n.copiedWorkoutItems(result.itemsCopied)}'
                      '${result.groupsSkippedDuplicate > 0 ? l10n.skippedDuplicatePlans(result.groupsSkippedDuplicate) : ''}',
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

  bool _isOtherGroup(DayWorkoutGroup group) {
    final name = group.workout.planName?.trim();
    return name == null || name.isEmpty;
  }

  GlobalKey _planGroupKey(int dayWorkoutId) {
    return _planGroupKeys.putIfAbsent(dayWorkoutId, GlobalKey.new);
  }

  DayWorkoutGroup? _groupAt(List<DayWorkoutGroup> groups, Offset pointer) {
    for (final group in groups) {
      final box =
          _planGroupKey(group.workout.id).currentContext?.findRenderObject()
              as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(pointer)) return group;
    }
    return null;
  }

  Future<void> _moveItemIntoPlan(
    BuildContext context,
    WidgetRef ref,
    DayWorkoutItemProgress progress,
    DayWorkoutGroup target,
  ) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(workoutRepositoryProvider)
          .moveDayWorkoutItemIntoPlan(
            dayWorkoutItemId: progress.item.id,
            targetDayWorkoutId: target.workout.id,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
    }
  }

  Future<void> _moveItemToOther(
    BuildContext context,
    WidgetRef ref,
    DayWorkoutItemProgress progress,
  ) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(workoutRepositoryProvider)
          .moveDayWorkoutItemToOther(progress.item.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
    }
  }

  Future<void> _persistItemOrder(int dayWorkoutId, List<int> ids) async {
    final previousOrder = _itemOrder[dayWorkoutId];
    setState(() => _itemOrder[dayWorkoutId] = List<int>.from(ids));
    try {
      await ref
          .read(workoutRepositoryProvider)
          .reorderDayWorkoutItems(
            dayWorkoutId: dayWorkoutId,
            orderedItemIds: ids,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (previousOrder == null) {
          _itemOrder.remove(dayWorkoutId);
        } else {
          _itemOrder[dayWorkoutId] = previousOrder;
        }
      });
    }
  }

  Future<void> _removeGroup(WidgetRef ref, DayWorkoutGroup group) async {
    await ref
        .read(workoutRepositoryProvider)
        .deleteDayWorkout(group.workout.id);
    _itemOrder.remove(group.workout.id);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(allWorkoutHistoryProvider);
  }

  Future<void> _editGroupPlan(
    BuildContext context,
    DayWorkoutGroup group,
  ) async {
    final planId = group.workout.planId;
    if (planId == null) return;
    await showPlanEditSheet(
      context: context,
      planId: planId,
      syncDay: CalendarDay.dayOnly(widget.day),
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
    required List<DayWorkoutGroup> groups,
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
        groupKey: _planGroupKey(group.workout.id),
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
            onReleaseOutside: editable
                ? (progress, pointer) {
                    final hit = _groupAt(groups, pointer);
                    if (hit != null && hit.workout.id == group.workout.id) {
                      return false;
                    }
                    if (hit != null) {
                      _moveItemIntoPlan(context, ref, progress, hit);
                      return true;
                    }
                    if (_isOtherGroup(group)) return false;
                    _moveItemToOther(context, ref, progress);
                    return true;
                  }
                : null,
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
              groups: ordered,
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
                groups: ordered,
                editable: editable,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Exercise rows for one group. Editable groups always show a drag handle.
  /// Releasing inside the list only reorders that group. Releasing on another
  /// group moves the exercise there. Releasing outside every group files it
  /// under 「其他」.
  Widget _itemsList({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required DayWorkoutGroup group,
    required bool editable,
    required bool Function(DayWorkoutItemProgress progress, Offset pointer)?
    onReleaseOutside,
  }) {
    final dayWorkoutId = group.workout.id;
    final ordered = _orderedItems(dayWorkoutId, group.items);
    if (!editable || ordered.isEmpty) {
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
    return _ExerciseReorderList(
      items: ordered,
      scheme: scheme,
      onReorder: (ids) => _persistItemOrder(dayWorkoutId, ids),
      onReleaseOutside: onReleaseOutside,
      tileBuilder: (progress) => _itemTile(
        context: context,
        ref: ref,
        l10n: l10n,
        scheme: scheme,
        progress: progress,
        editable: editable,
      ),
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
          _historyLink(context),
        ],
      ),
      error: (e, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(l10n.workoutLoadFailed('$e')), _historyLink(context)],
      ),
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
              _historyLink(context),
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
              _historyLink(context),
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

/// Same drag handle and lifted-row proxy as a normal reorder list.
///
/// Releasing inside the list saves the new order. Releasing outside asks
/// [onReleaseOutside] whether the exercise moved to another group; that
/// callback skips the in-list reorder when it returns true. The proxy itself
/// stays inside the list; the pointer does not.
class _ExerciseReorderList extends StatefulWidget {
  const _ExerciseReorderList({
    required this.items,
    required this.scheme,
    required this.onReorder,
    required this.onReleaseOutside,
    required this.tileBuilder,
  });

  final List<DayWorkoutItemProgress> items;
  final ColorScheme scheme;
  final Future<void> Function(List<int> orderedIds) onReorder;
  final bool Function(DayWorkoutItemProgress progress, Offset pointer)?
  onReleaseOutside;
  final Widget Function(DayWorkoutItemProgress progress) tileBuilder;

  @override
  State<_ExerciseReorderList> createState() => _ExerciseReorderListState();
}

class _ExerciseReorderListState extends State<_ExerciseReorderList> {
  static const _moveOutSlop = 8.0;

  final _listKey = GlobalKey();
  Offset? _pointer;
  int? _dragIndex;
  var _tracking = false;
  var _movedOut = false;

  void _onPointer(PointerEvent event) {
    _pointer = event.position;
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _stopTracking();
    }
  }

  void _startTracking(int index) {
    _dragIndex = index;
    _pointer = null;
    _movedOut = false;
    if (_tracking) return;
    _tracking = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  void _stopTracking() {
    if (!_tracking) return;
    _tracking = false;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
  }

  bool _pointerLeftList() {
    final pointer = _pointer;
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (pointer == null || box == null || !box.attached || !box.hasSize) {
      return false;
    }
    final rect = (box.localToGlobal(Offset.zero) & box.size).inflate(
      _moveOutSlop,
    );
    return !rect.contains(pointer);
  }

  void _finishDrag() {
    final index = _dragIndex;
    final pointer = _pointer;
    final left = _pointerLeftList();
    _stopTracking();
    if (index == null || index < 0 || index >= widget.items.length) return;
    if (!left || pointer == null) return;
    final moved =
        widget.onReleaseOutside?.call(widget.items[index], pointer) ?? false;
    if (moved) _movedOut = true;
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return ReorderableListView.builder(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderStart: _startTracking,
      onReorderEnd: (_) => _finishDrag(),
      onReorderItem: (oldIndex, newIndex) async {
        if (!mounted || _movedOut) return;
        final ids = [for (final progress in items) progress.item.id];
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        await widget.onReorder(ids);
      },
      itemBuilder: (context, i) {
        final progress = items[i];
        return Row(
          key: ValueKey('day-workout-item-${progress.item.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              key: ValueKey('day-workout-item-handle-${progress.item.id}'),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: InkIcon(
                  InkGlyph.dragHandle,
                  size: 20,
                  color: widget.scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: widget.tileBuilder(progress)),
          ],
        );
      },
    );
  }
}

class _DayWorkoutGroupTile extends StatelessWidget {
  const _DayWorkoutGroupTile({
    required this.groupKey,
    required this.title,
    required this.done,
    required this.total,
    required this.children,
    required this.onTap,
  });
  final Key? groupKey;
  final String title;
  final int done;
  final int total;
  final List<Widget> children;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(
    key: groupKey,
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

Future<void> showDayWorkoutDetails(BuildContext context, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .9,
      child: _DayWorkoutDetailsSheet(initialDay: day),
    ),
  );
}

class _DayWorkoutDetailsSheet extends StatefulWidget {
  const _DayWorkoutDetailsSheet({required this.initialDay});

  final DateTime initialDay;

  @override
  State<_DayWorkoutDetailsSheet> createState() =>
      _DayWorkoutDetailsSheetState();
}

class _DayWorkoutDetailsSheetState extends State<_DayWorkoutDetailsSheet> {
  late DateTime _day = AppDates.dayOnly(widget.initialDay);
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _shiftDay(int delta) {
    setState(() => _day = DateTime(_day.year, _day.month, _day.day + delta));
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = AppDates.todayLocal();
    final earliest = DateTime(today.year - 1, today.month, today.day);
    final locale = Localizations.localeOf(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.listPage,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.prevDay,
                  visualDensity: VisualDensity.compact,
                  onPressed: _day.isAfter(earliest)
                      ? () => _shiftDay(-1)
                      : null,
                  icon: const InkIcon(InkGlyph.chevronLeft),
                ),
                Expanded(
                  child: _DayTitle(
                    label: AppDates.mdWithWeekday(_day, locale),
                    backToTodayTooltip: _day.isBefore(today)
                        ? l10n.backToToday
                        : null,
                    onBackToToday: _day.isBefore(today)
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() => _day = today);
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(0);
                            }
                          }
                        : null,
                  ),
                ),
                if (_day.isBefore(today))
                  IconButton(
                    tooltip: l10n.nextDay,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _shiftDay(1),
                    icon: const InkIcon(InkGlyph.chevronRight),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: TodayWorkoutCard(
                day: _day,
                sectionPrefix: AppDates.isLocalToday(_day)
                    ? l10n.today
                    : l10n.sectionThatDay,
                showDetails: true,
              ),
            ),
          ),
        ],
      ),
    );
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
                exerciseId: item.exerciseId,
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

/// Plan list from today's workout "+". Plans sit under the library categories
/// of their exercises (same section headers as the exercise picker). A plan
/// with no resolvable category is omitted here; the plan list still shows it.
class _TodayPlanPickerSheet extends ConsumerWidget {
  const _TodayPlanPickerSheet({required this.plans});

  final List<WorkoutPlanSummary> plans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categoryById = {
      for (final exercise
          in ref.watch(exercisesProvider).asData?.value ?? const <Exercise>[])
        exercise.id: exercise.category,
    };
    final byCategory = <String, List<WorkoutPlanSummary>>{};
    for (final plan in plans) {
      final categories = <String>{
        for (final item in plan.items)
          if (categoryById[item.exerciseId] case final String category)
            if (plan.matchesExerciseCategory(category, categoryById)) category,
      };
      for (final category in categories) {
        byCategory.putIfAbsent(category, () => []).add(plan);
      }
    }
    final orderedCategories = [
      for (final category in kExerciseCategoryOrder)
        if (byCategory[category]?.isNotEmpty ?? false) category,
      for (final category in byCategory.keys)
        if (!kExerciseCategoryOrder.contains(category) &&
            byCategory[category]!.isNotEmpty)
          category,
    ];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: ListView(
          controller: scrollController,
          children: [
            ListTile(
              leading: const InkIcon(InkGlyph.add),
              title: Text(l10n.quickAddExercise),
              onTap: () => Navigator.pop(context, 'quick'),
            ),
            ListTile(
              leading: const InkIcon(InkGlyph.playlistAdd),
              title: Text(l10n.quickAddPlan),
              onTap: () => Navigator.pop(context, 'quickPlan'),
            ),
            const Divider(height: 1),
            for (final category in orderedCategories) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  category.localizedExerciseCategory(l10n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              for (final plan in byCategory[category]!)
                _planTile(context, plan),
            ],
          ],
        ),
      ),
    );
  }

  Widget _planTile(BuildContext context, WorkoutPlanSummary plan) {
    return ListTile(
      title: Text(plan.plan.name),
      subtitle: Text(
        plan.items
            .map(
              (item) =>
                  '${item.exerciseName} ${item.targetSets}×${item.targetReps}',
            )
            .join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.pop(context, plan),
    );
  }
}

class _DayTitle extends StatelessWidget {
  const _DayTitle({
    required this.label,
    required this.backToTodayTooltip,
    required this.onBackToToday,
  });

  final String label;
  final String? backToTodayTooltip;
  final VoidCallback? onBackToToday;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium,
    );
    if (onBackToToday == null) return text;
    return Tooltip(
      message: backToTodayTooltip ?? '',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onBackToToday,
        child: text,
      ),
    );
  }
}
