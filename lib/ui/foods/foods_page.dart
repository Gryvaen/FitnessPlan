import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/food_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
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
  var _tab = _FoodsTab.recent;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String v) => ref.read(_foodQueryProvider.notifier).set(v);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = ref.watch(_foodQueryProvider).trim().isNotEmpty;

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
                decoration: InputDecoration(
                  hintText: l10n.searchFood,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searching
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _setQuery('');
                          },
                        )
                      : null,
                ),
                onChanged: _setQuery,
              ),
            ),
            if (!searching) ...[
              const SizedBox(height: AppSpacing.compact),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.listPage,
                ),
                child: SportTabs<_FoodsTab>(
                  items: {
                    _FoodsTab.recent: l10n.tabRecent,
                    _FoodsTab.favorites: l10n.favorites,
                    _FoodsTab.categories: l10n.categories,
                  },
                  selected: _tab,
                  onSelected: (v) => setState(() => _tab = v),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.compact),
            Expanded(
              child: switch ((searching, _tab)) {
                (true, _) => _FoodSearchList(
                  onClearQuery: () {
                    _searchController.clear();
                    _setQuery('');
                  },
                ),
                (false, _FoodsTab.categories) => const _FoodCategoryList(),
                (false, _FoodsTab.favorites) => _FoodListView(
                  watch: (ref) => ref.watch(favoriteFoodsProvider),
                  emptyIcon: Icons.star_outline,
                  emptyTitle: l10n.noFavorites,
                ),
                (false, _FoodsTab.recent) => _FoodListView(
                  watch: (ref) => ref.watch(_recentFoodsProvider),
                  emptyIcon: Icons.history,
                  emptyTitle: l10n.noRecentFoods,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple food list (recent / favorites) with a shared empty state.
class _FoodListView extends ConsumerWidget {
  const _FoodListView({
    required this.watch,
    required this.emptyIcon,
    required this.emptyTitle,
  });

  final AsyncValue<List<FoodItem>> Function(WidgetRef ref) watch;
  final IconData emptyIcon;
  final String emptyTitle;

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
          itemBuilder: (context, i) => _FoodRow(food: foods[i]),
        );
      },
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food});

  final FoodItem food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SportListTile(
      key: ValueKey(food.id),
      contentPadding: EdgeInsets.zero,
      title: Text(food.name, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        food.category.localizedCategory(l10n),
        style: theme.textTheme.meta,
      ),
      trailing: Text(
        '${food.kcalPer100.round()} kcal/100g',
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => context.push('/foods/${food.id}'),
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
  const _FoodSearchList({required this.onClearQuery});

  final VoidCallback onClearQuery;

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
              itemBuilder: (context, i) => _FoodRow(food: foods[i]),
            );
          },
        );
  }
}
