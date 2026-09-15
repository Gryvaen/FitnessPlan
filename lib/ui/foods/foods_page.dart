import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/food_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/food_name_link.dart';
import '../widgets/search_field_focus.dart';
import 'food_category_art.dart';

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
      await ref.watch(foodsSeedProvider.future);
      return ref.watch(foodRepositoryProvider).categoryCounts();
    });

final _foodSearchProvider = FutureProvider.autoDispose<List<FoodItem>>((
  ref,
) async {
  await ref.watch(foodsSeedProvider.future);
  final q = ref.watch(_foodQueryProvider).trim();
  if (q.isEmpty) return const [];
  return ref.watch(foodRepositoryProvider).search(q);
});

final _recentFoodsProvider = FutureProvider.autoDispose<List<FoodItem>>((
  ref,
) async {
  ref.watch(todayMealsProvider);
  await ref.watch(foodsSeedProvider.future);
  return ref.watch(foodRepositoryProvider).recentFoods();
});

enum _FoodsTab { recent, favorites, categories }

class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  var _tab = _FoodsTab.categories;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _pickedInitialTab = false;

  @override
  void initState() {
    super.initState();
    suppressInitialSearchFocus(_searchFocus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setQuery(String v) => ref.read(_foodQueryProvider.notifier).set(v);

  List<_FoodsTab> _visibleTabs({
    required bool hasRecent,
    required bool hasFavorites,
  }) {
    return [
      if (hasRecent) _FoodsTab.recent,
      if (hasFavorites) _FoodsTab.favorites,
      _FoodsTab.categories,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = ref.watch(_foodQueryProvider).trim().isNotEmpty;
    final recentAsync = ref.watch(_recentFoodsProvider);
    final favAsync = ref.watch(favoriteFoodsProvider);
    final hasRecent = recentAsync.maybeWhen(
      data: (v) => v.isNotEmpty,
      orElse: () => false,
    );
    final hasFavorites = favAsync.maybeWhen(
      data: (v) => v.isNotEmpty,
      orElse: () => false,
    );
    final visible = _visibleTabs(
      hasRecent: hasRecent,
      hasFavorites: hasFavorites,
    );

    var effectiveTab = visible.contains(_tab) ? _tab : visible.last;
    if (!_pickedInitialTab && recentAsync.hasValue && favAsync.hasValue) {
      effectiveTab = visible.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pickedInitialTab) return;
        setState(() {
          _pickedInitialTab = true;
          _tab = visible.first;
        });
      });
    } else if (effectiveTab != _tab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: l10n.searchFood,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searching
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchFocus.unfocus();
                            _searchController.clear();
                            _setQuery('');
                          },
                        )
                      : null,
                ),
                onChanged: _setQuery,
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
                        _FoodsTab.favorites => l10n.favorites,
                        _FoodsTab.categories => l10n.categories,
                      },
                  },
                  selected: effectiveTab,
                  onSelected: (v) {
                    unfocusForNavigation();
                    _searchFocus.unfocus();
                    setState(() => _tab = v);
                  },
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
                        key: ValueKey(
                          visible.map((t) => t.name).join('-'),
                        ),
                        branchIndex: 1,
                        keepPagesAlive: true,
                        index: tabIndex,
                        onIndexChanged: (i) {
                          unfocusForNavigation();
                          _searchFocus.unfocus();
                          setState(() => _tab = visible[i]);
                        },
                        children: [
                          for (final t in visible)
                            KeyedSubtree(
                              key: ValueKey(t),
                              child: switch (t) {
                              _FoodsTab.recent => _FoodListView(
                                watch: (ref) =>
                                    ref.watch(_recentFoodsProvider),
                                emptyIcon: Icons.history,
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
                                              food.name,
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
                                  ref.invalidate(_recentFoodsProvider);
                                },
                              ),
                              _FoodsTab.favorites => _FoodListView(
                                watch: (ref) =>
                                    ref.watch(favoriteFoodsProvider),
                                emptyIcon: Icons.star_outline,
                                emptyTitle: l10n.noFavorites,
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
                                          title: Text(l10n.removeFavorite),
                                          content: Text(
                                            l10n.confirmRemoveFavorite(
                                              food.name,
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
                                              child: Text(l10n.remove),
                                            ),
                                          ],
                                        ),
                                      ) ==
                                      true;
                                  if (!confirmed) return;
                                  await ref
                                      .read(foodRepositoryProvider)
                                      .toggleFavorite(food.id);
                                },
                              ),
                              _FoodsTab.categories =>
                                const _FoodCategoryList(),
                            },
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (searching)
                    _FoodSearchList(
                      openDetail: (context, foodId) => withoutSearchFocus(
                        focus: _searchFocus,
                        action: () => openFoodDetail(context, foodId),
                      ),
                      onClearQuery: () {
                        _searchFocus.unfocus();
                        _searchController.clear();
                        _setQuery('');
                      },
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
    required this.emptyIcon,
    required this.emptyTitle,
    required this.openDetail,
    this.onLongPress,
  });

  final AsyncValue<List<FoodItem>> Function(WidgetRef ref) watch;
  final IconData emptyIcon;
  final String emptyTitle;
  final Future<void> Function(BuildContext context, int foodId) openDetail;
  final Future<void> Function(BuildContext context, WidgetRef ref, FoodItem food)?
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
            child: SportEmptyState(icon: emptyIcon, title: emptyTitle),
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
        name: food.name,
        foodId: food.id,
        carbG: food.carbPer100,
        proteinG: food.proteinPer100,
        fatG: food.fatPer100,
        style: theme.textTheme.bodyLarge,
        onTap: () => openDetail(context, food.id),
      ),
      subtitle: Text(
        food.category.localizedCategory(l10n),
        style: theme.textTheme.meta,
      ),
      trailing: Text(
        '${food.kcalPer100.round()} kcal/100g',
        style: theme.textTheme.bodySmall,
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
    return ref
        .watch(_categoryCountsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.loadFailed('$e')),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.invalidate(foodsSeedProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return SingleChildScrollView(
                child: SportEmptyState(
                  icon: Icons.category_outlined,
                  title: l10n.noCategories,
                ),
              );
            }
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
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      l10n.nKinds(c.count),
                      style: theme.textTheme.meta,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      Uri(
                        path: '/foods/category',
                        queryParameters: {'name': c.category},
                      ).toString(),
                    ),
                  ),
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const FoodCategoryAvatar(category: '自定义'),
                  title: Text(l10n.custom, style: theme.textTheme.bodyLarge),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/foods/custom'),
                ),
              ],
            );
          },
        );
  }
}

class _FoodSearchList extends ConsumerWidget {
  const _FoodSearchList({
    required this.onClearQuery,
    required this.openDetail,
  });

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
                  icon: Icons.search_off,
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
              itemBuilder: (context, i) => _FoodRow(
                food: foods[i],
                openDetail: openDetail,
              ),
            );
          },
        );
  }
}
