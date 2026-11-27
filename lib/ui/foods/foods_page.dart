import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/food_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../shell/swipe_tab_view.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/macro_color.dart';
import '../theme/sport_chrome.dart';
import '../widgets/expanding_search.dart';
import '../widgets/food_name_link.dart';
import '../widgets/search_field_focus.dart';
import 'food_category_art.dart';
import 'food_history_tab.dart';
import 'nutrient_reference_sheet.dart';

final _foodQueryProvider = NotifierProvider<_QueryNotifier, String>(
  _QueryNotifier.new,
);

class _QueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

final _categoryCountsProvider =
    FutureProvider.autoDispose<List<FoodCategoryCount>>((ref) async {
      ref.watch(foodCatalogChangesProvider);
      await ref.watch(foodsSeedProvider.future);
      return ref.watch(foodRepositoryProvider).categoryCounts();
    });

final _foodSearchProvider = FutureProvider.autoDispose<List<FoodItem>>((
  ref,
) async {
  ref.watch(foodCatalogChangesProvider);
  await ref.watch(foodsSeedProvider.future);
  final q = ref.watch(_foodQueryProvider).trim();
  if (q.isEmpty) return const [];
  return ref.watch(foodRepositoryProvider).search(q);
});

enum _FoodsTab { recent, categories, history }

class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  var _tab = _FoodsTab.categories;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  /// The search box rests as its icon; tapping it slides the box open
  /// without focusing it. It stays open while there is a keyword.
  bool _searchOpen = false;
  bool _pickedInitialTab = false;
  var _ignoredMissingHistory = false;

  @override
  void initState() {
    super.initState();
    suppressInitialSearchFocus(_searchFocus);
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setQuery(String v) => ref.read(_foodQueryProvider.notifier).set(v);

  bool get _hasQuery => ref.read(_foodQueryProvider).trim().isNotEmpty;

  /// Folds the box back to its icon once it is idle: unfocused, no keyword.
  void _foldIdleSearch() {
    if (!_searchOpen || _searchFocus.hasFocus || _hasQuery) return;
    setState(() => _searchOpen = false);
  }

  void _onSearchFocusChanged() {
    if (!_searchFocus.hasFocus) _foldIdleSearch();
  }

  /// Clears the keyword and folds the box.
  void _clearSearch() {
    _searchFocus.unfocus();
    _searchController.clear();
    _setQuery('');
    setState(() => _searchOpen = false);
  }

  bool _routeWantsHistory() {
    if (GoRouter.maybeOf(context) == null) return false;
    final state = GoRouterState.of(context);
    if (state.matchedLocation != '/foods') return false;
    return state.uri.queryParameters['tab'] == 'history';
  }

  void _selectFoodsTab(_FoodsTab tab) {
    unfocusForNavigation();
    _searchFocus.unfocus();
    _foldIdleSearch();
    if (tab != _tab) setState(() => _tab = tab);
    if (GoRouter.maybeOf(context) == null) return;
    final state = GoRouterState.of(context);
    if (state.matchedLocation != '/foods') return;
    final wantsHistory = tab == _FoodsTab.history;
    final hasHistoryQuery = state.uri.queryParameters['tab'] == 'history';
    if (wantsHistory == hasHistoryQuery) return;
    context.go(wantsHistory ? '/foods?tab=history' : '/foods');
  }

  List<_FoodsTab> _visibleTabs({
    required bool hasRecent,
    required bool showHistory,
  }) {
    return [
      if (hasRecent) _FoodsTab.recent,
      _FoodsTab.categories,
      if (showHistory) _FoodsTab.history,
    ];
  }

  Widget _buildSearch(BuildContext context, bool searching) {
    final l10n = context.l10n;
    // Tapping anywhere else folds an open-but-empty box.
    return TapRegion(
      onTapOutside: (_) {
        if (_hasQuery) return;
        _searchFocus.unfocus();
        _foldIdleSearch();
      },
      child: ExpandingSearch(
        expanded: _searchOpen || searching,
        openKey: const ValueKey('food-search-open'),
        tooltip: l10n.searchFood,
        onExpand: () => setState(() => _searchOpen = true),
        child: UnfocusOnKeyboardHide(
          focusNode: _searchFocus,
          child: TextField(
            key: const ValueKey('food-search'),
            controller: _searchController,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: l10n.searchFood,
              prefixIcon: InkIcon(
                InkGlyph.search,
                color: foodUtilityIconColor(context),
              ),
              suffixIcon: searching
                  ? IconButton(
                      icon: InkIcon(
                        InkGlyph.close,
                        color: foodUtilityIconColor(context),
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
            onChanged: _setQuery,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = ref.watch(_foodQueryProvider).trim().isNotEmpty;
    final recentAsync = ref.watch(recentFoodsProvider);
    final hasRecent = recentAsync.maybeWhen(
      data: (v) => v.isNotEmpty,
      orElse: () => false,
    );
    final recentHistory = ref.watch(mealHistoryProvider);
    final allHistory = ref.watch(allMealHistoryProvider);
    final historyResolved = recentHistory.hasValue && allHistory.hasValue;
    final showHistory = mealHistoryScopes(
      recent: recentHistory.value ?? const [],
      all: allHistory.value ?? const [],
    ).isNotEmpty;
    final routeWantsHistory = _routeWantsHistory();
    final visible = _visibleTabs(
      hasRecent: hasRecent,
      showHistory: showHistory,
    );

    var effectiveTab = visible.contains(_tab) ? _tab : visible.last;
    if (routeWantsHistory && showHistory && _tab != _FoodsTab.history) {
      effectiveTab = _FoodsTab.history;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _tab == _FoodsTab.history) return;
        setState(() {
          _pickedInitialTab = true;
          _tab = _FoodsTab.history;
        });
      });
    } else if (routeWantsHistory &&
        historyResolved &&
        !showHistory &&
        !_ignoredMissingHistory) {
      _ignoredMissingHistory = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || GoRouter.maybeOf(context) == null) return;
        final state = GoRouterState.of(context);
        if (state.matchedLocation != '/foods' ||
            state.uri.queryParameters['tab'] != 'history') {
          return;
        }
        context.go('/foods');
      });
    } else if (!_pickedInitialTab &&
        recentAsync.hasValue &&
        !routeWantsHistory) {
      effectiveTab = visible.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pickedInitialTab) return;
        setState(() {
          _pickedInitialTab = true;
          _tab = visible.first;
        });
      });
    } else if (effectiveTab != _tab &&
        !(routeWantsHistory && !historyResolved)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || visible.contains(_tab)) return;
        setState(() => _tab = effectiveTab);
      });
    }

    final tabIndex = visible.indexOf(effectiveTab).clamp(0, visible.length - 1);

    return AppChromeScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageTitle(
              title: l10n.foods,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.listPage,
                8,
                AppSpacing.listPage,
                AppSpacing.compact,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listPage,
              ),
              child: Stack(
                children: [
                  // 「每日营养参考」sits right of the resting search icon; the
                  // box slides over it as it opens, so it fades out then.
                  Positioned(
                    left: ExpandingSearch.collapsedWidth,
                    top: 0,
                    bottom: 0,
                    child: _NutrientRefButton(hidden: _searchOpen || searching),
                  ),
                  _buildSearch(context, searching),
                ],
              ),
            ),
            if (!searching && visible.length > 1) ...[
              const SizedBox(height: AppSpacing.compact),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.listPage,
                ),
                child: SportTabs<_FoodsTab>(
                  items: {
                    for (final t in visible)
                      t: switch (t) {
                        _FoodsTab.recent => l10n.tabRecent,
                        _FoodsTab.categories => l10n.categories,
                        _FoodsTab.history => l10n.tabHistory,
                      },
                  },
                  selected: effectiveTab,
                  onSelected: _selectFoodsTab,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.compact),
            Expanded(
              child: Stack(
                children: [
                  // Keep tab panels mounted while searching so returning to
                  // 最近/收藏/分类 does not reload or reset scroll.
                  Offstage(
                    offstage: searching,
                    child: TickerMode(
                      enabled: !searching,
                      child: SwipeTabView(
                        key: ValueKey(visible.map((t) => t.name).join('-')),
                        branchIndex: 1,
                        keepPagesAlive: true,
                        index: tabIndex,
                        onIndexChanged: (i) => _selectFoodsTab(visible[i]),
                        children: [
                          for (final t in visible)
                            KeyedSubtree(
                              key: ValueKey(t),
                              child: switch (t) {
                                _FoodsTab.recent => _FoodListView(
                                  // 按名字颜色排：红 → 蓝 → 黄，同色按时间。
                                  watch: (ref) => ref
                                      .watch(recentFoodsProvider)
                                      .whenData(sortFoodsByDominantMacro),
                                  emptyGlyph: InkGlyph.loading,
                                  emptyTitle: l10n.noRecentFoods,
                                  openDetail: (context, foodId) =>
                                      withoutSearchFocus(
                                        focus: _searchFocus,
                                        action: () =>
                                            openFoodDetail(context, foodId),
                                      ),
                                  onLongPress: (context, ref, food) async {
                                    final confirmed =
                                        await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(l10n.removeFromRecent),
                                            content: Text(
                                              l10n.confirmRemoveFromRecent(
                                                food.displayName(context),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: Text(l10n.cancel),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: Text(l10n.delete),
                                              ),
                                            ],
                                          ),
                                        ) ==
                                        true;
                                    if (!confirmed) return;
                                    await ref
                                        .read(foodRepositoryProvider)
                                        .hideFromRecent(food.id);
                                  },
                                ),
                                _FoodsTab.categories =>
                                  const _FoodCategoryList(),
                                _FoodsTab.history => const FoodHistoryTab(),
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (searching)
                    SwipeTabView(
                      navigation: SwipeTabNavigation.shell,
                      index: 0,
                      onIndexChanged: (_) {},
                      children: [
                        _FoodSearchList(
                          openDetail: (context, foodId) => withoutSearchFocus(
                            focus: _searchFocus,
                            action: () => openFoodDetail(context, foodId),
                          ),
                          onClearQuery: _clearSearch,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple food list (recent / favorites) with a shared empty state.
/// [onLongPress], when given, lets a row be long-pressed for a row-specific
/// action (remove from recent / unfavorite) — the caller owns any confirm
/// dialog and the actual mutation.
class _FoodListView extends ConsumerWidget {
  const _FoodListView({
    required this.watch,
    required this.emptyGlyph,
    required this.emptyTitle,
    required this.openDetail,
    this.onLongPress,
  });

  final AsyncValue<List<FoodItem>> Function(WidgetRef ref) watch;
  final InkGlyph emptyGlyph;
  final String emptyTitle;
  final Future<void> Function(BuildContext context, int foodId) openDetail;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    FoodItem food,
  )?
  onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return watch(ref).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.loadFailed('$e'))),
      data: (foods) {
        if (foods.isEmpty) {
          return SingleChildScrollView(
            child: SportEmptyState(
              iconWidget: InkIcon(
                emptyGlyph,
                size: 48,
                color: foodUtilityIconColor(context),
              ),
              title: emptyTitle,
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.listPage,
            0,
            AppSpacing.listPage,
            listBottomInset(context, hasFab: false),
          ),
          itemCount: foods.length,
          itemBuilder: (context, i) => _FoodRow(
            food: foods[i],
            openDetail: openDetail,
            onLongPress: onLongPress == null
                ? null
                : () => onLongPress!(context, ref, foods[i]),
          ),
        );
      },
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.food,
    required this.openDetail,
    this.onLongPress,
  });

  final FoodItem food;
  final Future<void> Function(BuildContext context, int foodId) openDetail;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tile = SportListTile(
      contentPadding: EdgeInsets.zero,
      title: FoodNameLink(
        name: food.displayName(context),
        foodId: food.id,
        carbG: food.carbPer100,
        proteinG: food.proteinPer100,
        fatG: food.fatPer100,
        style: theme.textTheme.rowTitle,
        onTap: () => openDetail(context, food.id),
      ),
      subtitle: Text(
        food.category.localizedCategory(l10n),
        style: theme.textTheme.meta,
      ),
      trailing: Text(
        '${food.kcalPer100.round()} kcal/100g',
        style: theme.textTheme.meta,
      ),
      onTap: () => openDetail(context, food.id),
    );
    if (onLongPress == null) {
      return KeyedSubtree(key: ValueKey(food.id), child: tile);
    }
    return GestureDetector(
      key: ValueKey(food.id),
      onLongPress: onLongPress,
      child: tile,
    );
  }
}

class _FoodCategoryList extends ConsumerWidget {
  const _FoodCategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final favoriteCount = ref.watch(favoriteFoodsProvider).value?.length ?? 0;
    final presetCount = ref.watch(mealPresetsProvider).value?.length ?? 0;
    final shortcuts = [
      SportListTile(
        key: const ValueKey('category-favorites'),
        contentPadding: EdgeInsets.zero,
        leading: const FoodCategoryAvatar(category: '收藏'),
        title: Text(l10n.favorites, style: theme.textTheme.rowTitle),
        subtitle: Text(
          l10n.collectionItems(favoriteCount),
          style: theme.textTheme.meta,
        ),
        trailing: InkIcon(
          InkGlyph.chevronRight,
          color: foodUtilityIconColor(context),
        ),
        onTap: () => context.push('/foods/favorites'),
      ),
      SportListTile(
        key: const ValueKey('category-presets'),
        contentPadding: EdgeInsets.zero,
        leading: const FoodCategoryAvatar(category: '套餐'),
        title: Text(l10n.presetsTab, style: theme.textTheme.rowTitle),
        subtitle: Text(
          l10n.collectionItems(presetCount),
          style: theme.textTheme.meta,
        ),
        trailing: InkIcon(
          InkGlyph.chevronRight,
          color: foodUtilityIconColor(context),
        ),
        onTap: () => context.push('/foods/presets'),
      ),
    ];
    return ref
        .watch(_categoryCountsProvider)
        .when(
          loading: () => ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.listPage,
            ),
            children: [
              ...shortcuts,
              const Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.listPage,
            ),
            children: [
              ...shortcuts,
              Text(l10n.loadFailed('$e')),
              FilledButton(
                onPressed: () => ref.invalidate(foodsSeedProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
          data: (categories) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.listPage,
                0,
                AppSpacing.listPage,
                listBottomInset(context, hasFab: false),
              ),
              children: [
                for (final c in categories)
                  SportListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: FoodCategoryAvatar(category: c.category),
                    title: Text(
                      c.category.localizedCategory(l10n),
                      style: theme.textTheme.rowTitle,
                    ),
                    subtitle: Text(
                      l10n.nKinds(c.count),
                      style: theme.textTheme.meta,
                    ),
                    trailing: InkIcon(
                      InkGlyph.chevronRight,
                      color: foodUtilityIconColor(context),
                    ),
                    onTap: () => context.push(
                      Uri(
                        path: '/foods/category',
                        queryParameters: {'name': c.category},
                      ).toString(),
                    ),
                  ),
                ...shortcuts,
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const FoodCategoryAvatar(category: '自定义'),
                  title: Text(l10n.custom, style: theme.textTheme.rowTitle),
                  trailing: InkIcon(
                    InkGlyph.chevronRight,
                    color: foodUtilityIconColor(context),
                  ),
                  onTap: () => context.push('/foods/custom'),
                ),
              ],
            );
          },
        );
  }
}

class _FoodSearchList extends ConsumerWidget {
  const _FoodSearchList({required this.onClearQuery, required this.openDetail});

  final VoidCallback onClearQuery;
  final Future<void> Function(BuildContext context, int foodId) openDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ref
        .watch(_foodSearchProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.loadFailed('$e'))),
          data: (foods) {
            if (foods.isEmpty) {
              return SingleChildScrollView(
                child: SportEmptyState(
                  iconWidget: InkIcon(
                    InkGlyph.search,
                    size: 48,
                    color: foodUtilityIconColor(context),
                  ),
                  title: l10n.noFoodFound,
                  actionLabel: l10n.editKeywords,
                  onAction: onClearQuery,
                  secondaryLabel: l10n.createFood,
                  onSecondary: () => context.push('/foods/custom'),
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.listPage,
                0,
                AppSpacing.listPage,
                listBottomInset(context, hasFab: false),
              ),
              itemCount: foods.length,
              itemBuilder: (context, i) =>
                  _FoodRow(food: foods[i], openDetail: openDetail),
            );
          },
        );
  }
}

/// The 「每日营养参考」 icon beside the resting search icon. Fades out (and
/// stops taking taps or focus) while the search box is open over it.
class _NutrientRefButton extends StatelessWidget {
  const _NutrientRefButton({required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedOpacity(
      opacity: hidden ? 0 : 1,
      duration: still ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        ignoring: hidden,
        child: ExcludeFocus(
          excluding: hidden,
          child: Center(
            // Same 48dp box the search box's prefix icon is forced to (its
            // min constraints), so both ink glyphs read at the same weight.
            child: IconButton(
              key: const ValueKey('food-nutrient-ref'),
              tooltip: context.l10n.nutrientRef,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: ExpandingSearch.collapsedWidth,
                height: ExpandingSearch.collapsedWidth,
              ),
              icon: InkIcon(
                InkGlyph.factCheck,
                size: ExpandingSearch.collapsedWidth,
                color: foodUtilityIconColor(context),
              ),
              onPressed: () => showNutrientReferenceSheet(context),
            ),
          ),
        ),
      ),
    );
  }
}
