import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/step_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../today/today_workout_card.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/form_options.dart';
import '../widgets/search_field_focus.dart';
import 'exercise_form_dialog.dart';
import 'exercise_picker.dart';
import 'plan_edit_page.dart';

typedef _TrainHistoryAvailability = ({bool resolved, bool hasHistory});

/// Whether the train-records history sub-tab has anything to show, and
/// whether we actually know that yet (all four underlying streams have
/// produced a first value). [_TrainRecordsTabState] reacts to this via
/// `ref.listen` instead of polling with a `postFrameCallback` — see the
/// comment on that listener for why polling a stale snapshot was buggy.
final _trainHistoryAvailabilityProvider =
    Provider.autoDispose<_TrainHistoryAvailability>((ref) {
      final recentWorkouts = ref.watch(workoutHistoryProvider);
      final allWorkouts = ref.watch(allWorkoutHistoryProvider);
      final recentSteps = ref.watch(recentStepsProvider);
      final allSteps = ref.watch(allStepsProvider);
      final resolved =
          recentWorkouts.hasValue &&
          allWorkouts.hasValue &&
          recentSteps.hasValue &&
          allSteps.hasValue;
      final hasHistory = _TrainRecordsTabState._availableHistoryScopes(
        recentWorkouts: recentWorkouts.value ?? const [],
        allWorkouts: allWorkouts.value ?? const [],
        recentSteps: recentSteps.value ?? const [],
        allSteps: allSteps.value ?? const [],
      ).isNotEmpty;
      return (resolved: resolved, hasHistory: hasHistory);
    });

/// Training management: exercise catalog, plans, recent set history.
class TrainRecordsTab extends ConsumerStatefulWidget {
  const TrainRecordsTab({super.key, this.initialTab});

  /// When set, forces the sub-tab (0=计划, 1=动作库, 2=历史) to this index —
  /// overrides whatever this widget last had selected, since [RecordsPage]
  /// keeps it alive across navigations away and back.
  final int? initialTab;

  @override
  ConsumerState<TrainRecordsTab> createState() => _TrainRecordsTabState();
}

class _TrainRecordsTabState extends ConsumerState<TrainRecordsTab> {
  int _tab = 0;

  /// 0 = recent, 1 = all (under the History sub-tab).
  int _historyScope = 0;
  String _query = '';
  String? _category;
  String? _planCategory;
  bool _exerciseSearchOpen = false;
  bool _categoryMenuOpen = false;
  final _exerciseSearchFocus = FocusNode();
  String _planQuery = '';
  bool _planSearchOpen = false;
  final _planSearchFocus = FocusNode();
  final Object _planSearchGroup = Object();
  final Object _exerciseSearchGroup = Object();
  Offset? _planOutsidePointer;
  Offset? _exerciseOutsidePointer;

  /// Last applied records URI query — kept-alive tab must re-read `sub`
  /// when Today / plan-edit calls `go('/records?tab=train&sub=plans')`.
  String? _appliedRouteKey;

  /// Add/edit dialogs sit outside the library search group. Their buttons
  /// would otherwise count as an outside tap and snap the filter back to 全部.
  var _exerciseDialogDepth = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) _tab = widget.initialTab!;
    suppressInitialTextFocus(_exerciseSearchFocus);
    _exerciseSearchFocus.addListener(_onExerciseSearchFocusChanged);
    suppressInitialTextFocus(_planSearchFocus);
    _planSearchFocus.addListener(_onPlanSearchFocusChanged);
  }

  @override
  void dispose() {
    _exerciseSearchFocus.removeListener(_onExerciseSearchFocusChanged);
    _exerciseSearchFocus.dispose();
    _planSearchFocus.removeListener(_onPlanSearchFocusChanged);
    _planSearchFocus.dispose();
    super.dispose();
  }

  void _onExerciseSearchFocusChanged() {
    if (_exerciseSearchFocus.hasFocus || _categoryMenuOpen) return;
    if (_query.isNotEmpty || _category != null || !_exerciseSearchOpen) return;
    setState(() => _exerciseSearchOpen = false);
  }

  void _onPlanSearchFocusChanged() {
    if (_planSearchFocus.hasFocus || _categoryMenuOpen || !_planSearchOpen) {
      return;
    }
    if (_planQuery.isNotEmpty || _planCategory != null) return;
    setState(() => _planSearchOpen = false);
  }

  void _onSearchOutsideDown(PointerDownEvent event, {required bool plan}) {
    if (plan) {
      _planOutsidePointer = event.position;
    } else {
      _exerciseOutsidePointer = event.position;
    }
  }

  void _onSearchOutsideUp(PointerUpEvent event, {required bool plan}) {
    final down = plan ? _planOutsidePointer : _exerciseOutsidePointer;
    if (plan) {
      _planOutsidePointer = null;
    } else {
      _exerciseOutsidePointer = null;
    }
    if (down == null || (event.position - down).distance > kTouchSlop) return;
    if (plan) {
      _discardPlanSearch();
    } else {
      _discardExerciseSearch();
    }
  }

  /// The field can stay focused after its panel is swiped off-screen
  /// (pages are kept alive), which leaves the keyboard up.
  void _dropSearchFocus(FocusNode focus) {
    focus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focus.hasFocus) focus.unfocus();
    });
  }

  /// 点记录页里搜索框和结果行以外的位置：收起搜索，并丢掉关键字和分类。
  void _discardPlanSearch() {
    if (_categoryMenuOpen) return;
    _dropSearchFocus(_planSearchFocus);
    if (!_planSearchOpen && _planQuery.isEmpty && _planCategory == null) {
      return;
    }
    setState(() {
      _planSearchOpen = false;
      _planQuery = '';
      _planCategory = null;
    });
  }

  void _beginExerciseDialog() {
    _exerciseDialogDepth++;
  }

  void _endExerciseDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_exerciseDialogDepth > 0) _exerciseDialogDepth--;
    });
  }

  /// 点动作列表或标题行的空白处：收起搜索，并丢掉关键字和分类筛选。
  void _discardExerciseSearch() {
    if (_categoryMenuOpen || _exerciseDialogDepth > 0) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _dropSearchFocus(_exerciseSearchFocus);
    if (!_exerciseSearchOpen && _query.isEmpty && _category == null) return;
    setState(() {
      _exerciseSearchOpen = false;
      _query = '';
      _category = null;
    });
  }

  Future<void> _openCategoryMenu(
    BuildContext buttonContext, {
    required void Function(String? category) apply,
  }) async {
    final button = buttonContext.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()!
            as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final l10n = buttonContext.l10n;
    _categoryMenuOpen = true;
    final selected = await showMenu<String>(
      context: buttonContext,
      position: position,
      items: [
        PopupMenuItem(value: '', child: Text(l10n.filterAll)),
        for (final c in kExerciseCategoryOrder)
          PopupMenuItem(
            value: c,
            child: Text(c.localizedExerciseCategory(l10n)),
          ),
      ],
    );
    _categoryMenuOpen = false;
    if (!mounted) return;
    setState(() {
      if (selected != null) apply(selected.isEmpty ? null : selected);
    });
  }

  @override
  void didUpdateWidget(covariant TrainRecordsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.initialTab;
    if (target != null && target != _tab) {
      setState(() => _tab = target);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSubFromRoute();
  }

  static int? _trainTabFromSub(String? sub) => switch (sub) {
    'plans' => 0,
    'library' => 1,
    'history' => 2,
    _ => null,
  };

  static String _subName(int tab) => switch (tab) {
    1 => 'library',
    2 => 'history',
    _ => 'plans',
  };

  /// Progressive history scopes: hidden by default → 「最近」 once any recent
  /// step/workout activity exists → 「全部」 on the 14th calendar day after the
  /// first logged day (first day counts as day 1).
  static List<int> _availableHistoryScopes({
    required List<WorkoutHistoryDay> recentWorkouts,
    required List<WorkoutHistoryDay> allWorkouts,
    required List<StepDay> recentSteps,
    required List<StepDay> allSteps,
  }) {
    final hasRecent =
        recentWorkouts.any((d) => d.hasActivity) ||
        recentSteps.any((d) => d.steps > 0);
    DateTime? first;
    for (final d in allWorkouts) {
      final day = AppDates.dayOnly(d.date);
      if (first == null || day.isBefore(first)) first = day;
    }
    for (final d in allSteps) {
      final day = AppDates.dayOnly(d.date);
      if (first == null || day.isBefore(first)) first = day;
    }
    final showAll =
        first != null && AppDates.todayLocal().difference(first).inDays >= 13;
    return [if (hasRecent) 0, if (showAll) 1];
  }

  void _ensureHistoryScopeAvailable(List<int> scopes) {
    // Nothing to sync to when there's no history yet (e.g. a fresh
    // install) — `showHistory` is false in that case so this state is
    // unused anyway. Without this guard, `next` would fall back to 0,
    // which never satisfies `scopes.contains(_historyScope)` on an empty
    // list, so this would reschedule and call `setState` on every single
    // frame forever.
    if (scopes.isEmpty || scopes.contains(_historyScope)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scopes.contains(_historyScope)) return;
      final next = scopes.first;
      setState(() => _historyScope = next);
      if (next == 1) {
        ref.read(stepsSyncServiceProvider).syncRecent(limitDays: 90);
      }
    });
  }

  /// Bounces away from the history sub-tab once we *know* (not guess) there's
  /// nothing to show there. `ref.listen` only fires this on an actual value
  /// change, gated on `resolved` so it never acts on the streams' transient
  /// loading state — a cold deep-link straight to the history sub-tab used
  /// to race a `postFrameCallback`-based "one frame passed, still empty?"
  /// check against those same streams still resolving, which could bounce
  /// the user back to 计划 even though their history was about to show up.
  void _onTrainHistoryAvailabilityChanged(
    _TrainHistoryAvailability? previous,
    _TrainHistoryAvailability next,
  ) {
    if (next.resolved && !next.hasHistory && _tab == 2) _selectTab(0);
  }

  void _syncSubFromRoute() {
    final state = GoRouterState.of(context);
    if (state.matchedLocation != '/records') return;
    final tab = state.uri.queryParameters['tab'];
    // Only react while the train segment is the route target.
    if (tab != null && tab.isNotEmpty && tab != 'train') return;

    final key = '${state.matchedLocation}?${state.uri.query}';
    if (key == _appliedRouteKey) return;
    _appliedRouteKey = key;

    final trainTab = _trainTabFromSub(state.uri.queryParameters['sub']);
    if (trainTab != null && trainTab != _tab) {
      setState(() => _tab = trainTab);
    }
  }

  void _selectTab(int v) {
    if (v == _tab) return;
    if (_tab == 0) _dropSearchFocus(_planSearchFocus);
    if (_tab == 1) _dropSearchFocus(_exerciseSearchFocus);
    setState(() => _tab = v);
    final path = '/records?tab=train&sub=${_subName(v)}';
    _appliedRouteKey = '/records?tab=train&sub=${_subName(v)}';
    context.go(path);
  }

  int _dayExerciseCount(WorkoutHistoryDay day) {
    return {
      for (final item in day.completedItems) item.exerciseName,
      for (final set in day.sets) set.exerciseName,
    }.length;
  }

  /// "plan · done/total" per plan worked that day, or a plain exercise
  /// count when the day has no linked plan (e.g. free-form logging).
  String _dayProgressLabel(WorkoutHistoryDay day, AppLocalizations l10n) {
    if (!day.hasActivity) return l10n.historyEmptyDay;
    if (day.planSummaries.isEmpty) {
      return l10n.nExercises(_dayExerciseCount(day));
    }
    return day.planSummaries
        .map(
          (s) => l10n.planProgress(
            (s.planName?.trim().isNotEmpty ?? false)
                ? s.planName!.trim()
                : l10n.untitledWorkoutGroup,
            s.doneCount,
            s.totalCount,
          ),
        )
        .join(' · ');
  }

  void _showStepHistory(
    BuildContext context,
    List<StepDay> days,
    Locale locale, {
    required String title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          // Builder (not children:) so a long "全部" history only inflates
          // the rows actually visible in the sheet, not every logged day.
          itemCount: days.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            }
            final day = days[index - 1];
            return SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: const MenuIconBadge(
                color: AppColors.water,
                child: InkIcon(InkGlyph.walk, color: AppColors.water),
              ),
              title: Text(AppDates.md(day.date, locale)),
              trailing: Text(context.l10n.nSteps(day.steps)),
            );
          },
        ),
      ),
    );
  }

  void _showWorkoutHistory(
    BuildContext context,
    List<WorkoutHistoryDay> days,
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
        child: _WorkoutHistorySheet(
          days: days,
          locale: locale,
          title: title,
          labelFor: (day) => _dayProgressLabel(day, l10n),
        ),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final memory = ref.read(formMemoryRepositoryProvider);
    _beginExerciseDialog();
    final ExerciseFormData? form;
    try {
      form = await showExerciseFormDialog(
        context: context,
        defaultCategory: _category ?? memory.loadExerciseCategory(),
      );
    } finally {
      _endExerciseDialog();
    }
    if (form == null || !context.mounted) return;
    try {
      await ref
          .read(workoutRepositoryProvider)
          .addCustomExercise(
            name: form.name,
            unit: form.unit,
            category: form.category,
          );
      await memory.saveExerciseCategory(form.category);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
    }
  }

  Future<void> _editExercise(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final l10n = context.l10n;
    _beginExerciseDialog();
    final ExerciseFormData? form;
    try {
      form = await showExerciseFormDialog(context: context, exercise: exercise);
    } finally {
      _endExerciseDialog();
    }
    if (form == null || !context.mounted) return;
    try {
      await ref
          .read(workoutRepositoryProvider)
          .updateExercise(
            id: exercise.id,
            name: form.name,
            unit: form.unit,
            category: form.category,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    }
  }

  Future<void> _deletePlan(WorkoutPlanSummary plan) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlan),
        content: Text(l10n.confirmDeletePlan(plan.plan.name)),
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
    if (ok != true || !mounted) return;
    try {
      await ref.read(workoutRepositoryProvider).deletePlan(plan.plan.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recentWorkouts = ref.watch(workoutHistoryProvider).value ?? const [];
    final allWorkouts = ref.watch(allWorkoutHistoryProvider).value ?? const [];
    final recentSteps = ref.watch(recentStepsProvider).value ?? const [];
    final allSteps = ref.watch(allStepsProvider).value ?? const [];
    final historyScopes = _availableHistoryScopes(
      recentWorkouts: recentWorkouts,
      allWorkouts: allWorkouts,
      recentSteps: recentSteps,
      allSteps: allSteps,
    );
    final showHistory = historyScopes.isNotEmpty;
    _ensureHistoryScopeAvailable(historyScopes);
    // No `fireImmediately: true` here: that would call
    // `_onTrainHistoryAvailabilityChanged` synchronously inside this very
    // build() on first attach, and it can call `setState` via `_selectTab`
    // — "setState during build". The `tab` substitution right below already
    // renders correctly on the very first frame regardless (falls back to
    // 计划 whenever `!showHistory`), so this only needs to react to *later*
    // transitions, which `ref.listen` fires safely outside the build phase.
    ref.listen<_TrainHistoryAvailability>(
      _trainHistoryAvailabilityProvider,
      _onTrainHistoryAvailabilityChanged,
    );
    final tab = (!showHistory && _tab == 2) ? 0 : _tab;
    final scope = historyScopes.contains(_historyScope)
        ? _historyScope
        : (historyScopes.isEmpty ? 0 : historyScopes.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: SportTabs<int>(
            items: {
              0: l10n.tabPlans,
              1: l10n.exerciseLibrary,
              if (showHistory) 2: l10n.tabHistory,
            },
            selected: tab,
            onSelected: _selectTab,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SwipeTabView(
            keepPagesAlive: true,
            index: tab,
            onIndexChanged: (i) {
              if (!showHistory && i == 2) return;
              _selectTab(i);
            },
            children: [
              _plansPanel(context, showHistory: showHistory),
              _exercisesPanel(context),
              if (showHistory) _historyPanel(context, historyScopes, scope),
            ],
          ),
        ),
      ],
    );
  }

  Widget _plansPanel(BuildContext context, {required bool showHistory}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categoryById = {
      for (final exercise
          in ref.watch(exercisesProvider).asData?.value ?? const <Exercise>[])
        exercise.id: exercise.category,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _discardPlanSearch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              children: [
                if (!_planSearchOpen)
                  IconButton(
                    key: const ValueKey('plan-search'),
                    tooltip: l10n.planName,
                    onPressed: () => setState(() => _planSearchOpen = true),
                    icon: const InkIcon(InkGlyph.search),
                  )
                else
                  Expanded(
                    child: TapRegion(
                      groupId: _planSearchGroup,
                      onTapOutside: (event) =>
                          _onSearchOutsideDown(event, plan: true),
                      onTapUpOutside: (event) =>
                          _onSearchOutsideUp(event, plan: true),
                      child: TextField(
                        focusNode: _planSearchFocus,
                        decoration: InputDecoration(
                          hintText: l10n.planName,
                          prefixIcon: Builder(
                            builder: (buttonContext) => IconButton(
                              key: const ValueKey('plan-category-filter'),
                              tooltip: l10n.categories,
                              onPressed: () => _openCategoryMenu(
                                buttonContext,
                                apply: (category) {
                                  _planCategory = category;
                                  if (!_planSearchFocus.hasFocus &&
                                      _planQuery.isEmpty &&
                                      _planCategory == null) {
                                    _planSearchOpen = false;
                                  }
                                },
                              ),
                              icon: InkIcon(
                                InkGlyph.folder,
                                color: _planCategory == null
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _planQuery = v.trim().toLowerCase()),
                      ),
                    ),
                  ),
                if (!_planSearchOpen) const Spacer(),
                PlainIconAction(
                  iconWidget: const InkIcon(InkGlyph.add),
                  label: l10n.fabNewPlan,
                  onPressed: () => showPlanEditSheet(context: context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                listBottomInset(context, hasFab: false),
              ),
              children: [
                ref
                    .watch(workoutPlansProvider)
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => SportLoadError(
                        onRetry: () => ref.invalidate(workoutPlansProvider),
                      ),
                      data: (plans) {
                        if (plans.isEmpty) {
                          return SportEmptyState(
                            title: l10n.emptyPlans,
                            iconWidget: const StampedInkEmptyIcon(
                              glyph: InkGlyph.training,
                              seal: '炼',
                            ),
                          );
                        }
                        final visible = plans.where((plan) {
                          final nameOk =
                              _planQuery.isEmpty ||
                              plan.plan.name.toLowerCase().contains(_planQuery);
                          if (!nameOk) return false;
                          final category = _planCategory;
                          if (category == null) return true;
                          return plan.matchesExerciseCategory(
                            category,
                            categoryById,
                          );
                        }).toList();
                        if (visible.isEmpty) {
                          return SportEmptyState(
                            title: l10n.noMatchingPlans,
                            iconWidget: const StampedInkEmptyIcon(
                              glyph: InkGlyph.training,
                              seal: '炼',
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final plan in visible)
                              TapRegion(
                                groupId: _planSearchGroup,
                                child: SportListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(plan.plan.name),
                                  subtitle: Text(
                                    l10n.nExercises(plan.items.length),
                                  ),
                                  trailing: IconButton(
                                    tooltip: l10n.delete,
                                    icon: const InkIcon(InkGlyph.delete),
                                    onPressed: () => _deletePlan(plan),
                                  ),
                                  onTap: () => showPlanEditSheet(
                                    context: context,
                                    planId: plan.plan.id,
                                  ),
                                ),
                              ),
                            if (showHistory)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => _selectTab(2),
                                  child: Text(l10n.viewWorkoutHistory),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyPanel(BuildContext context, List<int> scopes, int scope) {
    final l10n = context.l10n;
    final showScopeTabs = scopes.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showScopeTabs)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SportTabs<int>(
              items: {
                for (final s in scopes)
                  s: s == 0 ? l10n.tabRecent : l10n.filterAll,
              },
              selected: scope,
              onSelected: _setHistoryScope,
            ),
          ),
        if (showScopeTabs) const SizedBox(height: 8),
        Expanded(
          child: showScopeTabs
              ? SwipeTabView(
                  keepPagesAlive: true,
                  index: scopes.indexOf(scope).clamp(0, scopes.length - 1),
                  onIndexChanged: (i) => _setHistoryScope(scopes[i]),
                  children: [
                    for (final s in scopes)
                      _historyScopeList(context, all: s == 1),
                  ],
                )
              : _historyScopeList(context, all: scope == 1),
        ),
      ],
    );
  }

  void _setHistoryScope(int v) {
    setState(() => _historyScope = v);
    if (v == 1) {
      // Pull a wider sensor window so "全部步数" can show more days.
      ref.read(stepsSyncServiceProvider).syncRecent(limitDays: 90);
    }
  }

  Widget _historyScopeList(BuildContext context, {required bool all}) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final stepsAsync = ref.watch(all ? allStepsProvider : recentStepsProvider);
    final workoutsAsync = ref.watch(
      all ? allWorkoutHistoryProvider : workoutHistoryProvider,
    );
    final stepsTitle = all ? l10n.allSteps : l10n.recentSteps;
    final workoutsTitle = all ? l10n.allWorkouts : l10n.workoutHistory;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        stepsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (days) {
            // Recent: 14 calendar days (zeros allowed). All: only days with data.
            final visible = all
                ? [
                    for (final d in days)
                      if (d.steps > 0) d,
                  ]
                : days;
            if (visible.isEmpty) return const SizedBox.shrink();
            final latest = visible.first;
            return SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: const MenuIconBadge(
                color: AppColors.water,
                child: InkIcon(InkGlyph.walk, color: AppColors.water),
              ),
              title: Text(stepsTitle),
              subtitle: Text(AppDates.md(latest.date, locale)),
              trailing: Text(l10n.nSteps(latest.steps)),
              onTap: () =>
                  _showStepHistory(context, visible, locale, title: stepsTitle),
            );
          },
        ),
        workoutsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => SportLoadError(
            onRetry: () {
              if (all) {
                ref.invalidate(allWorkoutHistoryProvider);
              } else {
                ref.invalidate(workoutHistoryProvider);
              }
            },
          ),
          data: (days) {
            // Recent always has 14 calendar rows (empty days show「无」).
            // All only lists days that actually have activity.
            if (all && days.isEmpty) {
              return SportEmptyState(
                title: l10n.noSetLogs,
                iconWidget: const StampedInkEmptyIcon(
                  glyph: InkGlyph.training,
                  seal: '炼',
                ),
              );
            }
            if (days.isEmpty) return const SizedBox.shrink();
            final latest = days.first;
            return SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: const MenuIconBadge(
                color: AppColors.protein,
                child: InkIcon(InkGlyph.training, color: AppColors.protein),
              ),
              title: Text(workoutsTitle),
              // Progress sits under the date. A long multi-plan label in
              // `trailing` sizes to the full tile width and ListTile then
              // throws every frame ("Trailing widget consumes the entire
              // tile width").
              subtitle: Text(
                '${AppDates.md(latest.date, locale)}\n${_dayProgressLabel(latest, l10n)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _showWorkoutHistory(
                context,
                days,
                locale,
                title: workoutsTitle,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _exercisesPanel(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _discardExerciseSearch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              children: [
                if (!_exerciseSearchOpen)
                  IconButton(
                    key: const ValueKey('exercise-library-search'),
                    tooltip: l10n.exerciseName,
                    onPressed: () => setState(() => _exerciseSearchOpen = true),
                    icon: const InkIcon(InkGlyph.search),
                  )
                else
                  Expanded(
                    child: TapRegion(
                      groupId: _exerciseSearchGroup,
                      onTapOutside: (event) =>
                          _onSearchOutsideDown(event, plan: false),
                      onTapUpOutside: (event) =>
                          _onSearchOutsideUp(event, plan: false),
                      child: TextField(
                        focusNode: _exerciseSearchFocus,
                        decoration: InputDecoration(
                          hintText: l10n.exerciseName,
                          prefixIcon: Builder(
                            builder: (buttonContext) => IconButton(
                              key: const ValueKey('exercise-category-filter'),
                              tooltip: l10n.categories,
                              onPressed: () => _openCategoryMenu(
                                buttonContext,
                                apply: (category) {
                                  _category = category;
                                  if (!_exerciseSearchFocus.hasFocus &&
                                      _query.isEmpty &&
                                      _category == null) {
                                    _exerciseSearchOpen = false;
                                  }
                                },
                              ),
                              icon: InkIcon(
                                InkGlyph.folder,
                                color: _category == null
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                      ),
                    ),
                  ),
                if (!_exerciseSearchOpen) const Spacer(),
                PlainIconAction(
                  iconWidget: const InkIcon(InkGlyph.add),
                  label: l10n.addExercise,
                  onPressed: () => _addExercise(context, ref),
                ),
              ],
            ),
          ),
          Expanded(
            // CustomScrollView + SliverList.builder (rather than a plain
            // ListView wrapping a Column of every match) so filtering while
            // typing only builds the rows actually on screen.
            child: CustomScrollView(
              slivers: [
                ref
                    .watch(exercisesProvider)
                    .when(
                      loading: () => const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: LinearProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: SportLoadError(
                            onRetry: () => ref.invalidate(exercisesProvider),
                          ),
                        ),
                      ),
                      data: (exercises) {
                        final visible = exercises
                            .where(
                              (e) =>
                                  (_category == null ||
                                      e.category == _category) &&
                                  e.name.toLowerCase().contains(_query),
                            )
                            .toList();
                        if (visible.isEmpty) {
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverToBoxAdapter(
                              child: SportEmptyState(
                                title: l10n.noExercises,
                                iconWidget: const StampedInkEmptyIcon(
                                  glyph: InkGlyph.training,
                                  seal: '炼',
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            listBottomInset(context, hasFab: false),
                          ),
                          sliver: SliverList.builder(
                            itemCount: visible.length,
                            itemBuilder: (context, index) =>
                                _exerciseRow(context, visible[index]),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseRow(BuildContext context, Exercise ex) {
    final l10n = context.l10n;
    return TapRegion(
      groupId: _exerciseSearchGroup,
      child: SportListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(ex.name),
        subtitle: Text(
          '${ex.category.localizedExerciseCategory(l10n)} · ${ExerciseUnit.fromStorage(ex.unit).label(l10n, category: ex.category)}',
        ),
        onTap: () => _editExercise(context, ref, ex),
        trailing: ex.isCustom
            ? IconButton(
                tooltip: l10n.delete,
                icon: const InkIcon(InkGlyph.delete),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.delete),
                      content: Text(ex.name),
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
                  try {
                    await ref
                        .read(workoutRepositoryProvider)
                        .deleteCustomExercise(ex.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              )
            : const InkIcon(InkGlyph.chevronRight),
      ),
    );
  }
}

/// One history day. The plan progress is a wrapping line under the date.
///
/// A [ListTile] trailing (or an unbounded subtitle) sizes a long
/// "计划 · 完成数" label to the full row width, then asserts every frame and
/// freezes the sheet.
class _HistoryDayRow extends StatelessWidget {
  const _HistoryDayRow({
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
                color: AppColors.protein,
                child: InkIcon(InkGlyph.training, color: AppColors.protein),
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

/// Workout-history list. After a day is opened, every other day that shares
/// one of that day's exercises is marked. Cardio, anaerobic, and core do
/// not count.
class _WorkoutHistorySheet extends StatefulWidget {
  const _WorkoutHistorySheet({
    required this.days,
    required this.locale,
    required this.title,
    required this.labelFor,
  });

  final List<WorkoutHistoryDay> days;
  final Locale locale;
  final String title;
  final String Function(WorkoutHistoryDay day) labelFor;

  @override
  State<_WorkoutHistorySheet> createState() => _WorkoutHistorySheetState();
}

class _WorkoutHistorySheetState extends State<_WorkoutHistorySheet> {
  Set<int> _highlightExerciseIds = const {};

  bool _sharesHighlight(WorkoutHistoryDay day) {
    if (_highlightExerciseIds.isEmpty) return false;
    return day.highlightExerciseIds.any(_highlightExerciseIds.contains);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
    );
    return SafeArea(
      child: ListView.builder(
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
          final highlighted = _sharesHighlight(day);
          return _HistoryDayRow(
            dateLabel: AppDates.md(day.date, widget.locale),
            detailLabel: widget.labelFor(day),
            detailStyle: highlighted
                ? highlightStyle
                : theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            onTap: !day.hasActivity
                ? null
                : () async {
                    await showDayWorkoutDetails(context, day.date);
                    if (!mounted) return;
                    setState(() {
                      _highlightExerciseIds = day.highlightExerciseIds;
                    });
                  },
          );
        },
      ),
    );
  }
}

/// Quick-add a day workout item dialog (shared with today empty state).
///
/// Always presents on the root navigator so the dialog stays visible on the
/// current shell tab (StatefulShellRoute keeps inactive branch navigators).
Future<void> showQuickAddDayItemDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime day,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);

  List<Exercise> exercises;
  try {
    exercises = await ref.read(workoutRepositoryProvider).listExercises();
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
    return;
  }
  if (!context.mounted) return;
  if (exercises.isEmpty) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.addExercisesFirst)));
    return;
  }

  final initial = exercises.first;
  Exercise? selected = initial;
  final memory = ref.read(formMemoryRepositoryProvider).loadWorkoutTargets();
  final initialUnit = ExerciseUnit.fromStorage(initial.unit);
  var sets = FormOptions.snapInt(FormOptions.targetSets, memory.sets);
  var reps = FormOptions.snapInt(
    FormOptions.exerciseTargetOptions(initialUnit, category: initial.category),
    memory.valueFor(initialUnit, category: initial.category),
  );
  final initialLast = await ref
      .read(workoutRepositoryProvider)
      .lastExerciseTargets(initial.id);
  if (!context.mounted) return;
  if (initialLast != null) {
    sets = FormOptions.snapInt(FormOptions.targetSets, initialLast.sets);
    reps = FormOptions.snapInt(
      FormOptions.exerciseTargetOptions(
        initialUnit,
        category: initial.category,
      ),
      initialLast.reps,
    );
  }

  // Let any prior route (empty-plan dialog / bottom sheet) finish popping
  // before pushing onto the root overlay.
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return;

  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final unit = selected == null
            ? ExerciseUnit.reps
            : ExerciseUnit.fromStorage(selected!.unit);
        final category = selected?.category;
        final targetOptions = FormOptions.exerciseTargetOptions(
          unit,
          category: category,
        );
        return AlertDialog(
          title: Text(l10n.addTodayExercise),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExercisePicker(
                  label: l10n.exercise,
                  displayText: selected!.name,
                  selectedId: selected!.id,
                  exercises: exercises,
                  onChanged: (v) async {
                    final last = await ref
                        .read(workoutRepositoryProvider)
                        .lastExerciseTargets(v.id);
                    if (!ctx.mounted) return;
                    final remembered = ref
                        .read(formMemoryRepositoryProvider)
                        .loadWorkoutTargets();
                    setLocal(() {
                      selected = v;
                      final pickedUnit = ExerciseUnit.fromStorage(v.unit);
                      final options = FormOptions.exerciseTargetOptions(
                        pickedUnit,
                        category: v.category,
                      );
                      sets = FormOptions.snapInt(
                        FormOptions.targetSets,
                        last?.sets ?? remembered.sets,
                      );
                      reps = FormOptions.snapInt(
                        options,
                        last?.reps ??
                            remembered.valueFor(
                              pickedUnit,
                              category: v.category,
                            ),
                      );
                    });
                  },
                ),
                const SizedBox(height: 12),
                AppDropdown<int>(
                  label: l10n.targetSets,
                  value: FormOptions.snapInt(FormOptions.targetSets, sets),
                  items: FormOptions.targetSets,
                  onChanged: (v) {
                    setLocal(() => sets = v);
                    ref
                        .read(formMemoryRepositoryProvider)
                        .saveWorkoutTargets(
                          sets: v,
                          value: reps,
                          unit: unit,
                          category: category,
                        );
                  },
                ),
                const SizedBox(height: 12),
                AppDropdown<int>(
                  label: unit.targetLabel(l10n, category: category),
                  value: FormOptions.snapInt(targetOptions, reps),
                  items: targetOptions,
                  onChanged: (v) {
                    setLocal(() => reps = v);
                    ref
                        .read(formMemoryRepositoryProvider)
                        .saveWorkoutTargets(
                          sets: sets,
                          value: v,
                          unit: unit,
                          category: category,
                        );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.add),
            ),
          ],
        );
      },
    ),
  );
  if (ok != true || selected == null || !context.mounted) return;
  try {
    await ref
        .read(workoutRepositoryProvider)
        .addQuickDayItem(
          day: day,
          exerciseId: selected!.id,
          targetSets: sets,
          targetReps: reps,
        );
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(l10n.addFailed('$e'))));
  }
}
