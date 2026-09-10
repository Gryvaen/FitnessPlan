import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/food_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

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

class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});
  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = ref.watch(_foodQueryProvider).trim().isNotEmpty;

    return AppChromeScaffold(
      appBar: AppBar(
        title: Text(l10n.foodLibrary),
        actions: [
          IconButton(
            tooltip: l10n.favorites,
            icon: const Icon(Icons.star_outline),
            onPressed: () => context.push('/foods/favorites'),
          ),
          IconButton(
            tooltip: l10n.custom,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/foods/custom'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.listPage,
              8,
              AppSpacing.listPage,
              8,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchFood,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => ref.read(_foodQueryProvider.notifier).set(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SportTabs<int>(
              items: {0: l10n.tabRecent, 1: l10n.favorites, 2: l10n.categories},
              selected: _tab,
              onSelected: (v) => setState(() => _tab = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: searching
                ? const _FoodSearchList()
                : _tab == 2
                ? const _FoodBrowse()
                : _FoodCollection(favorites: _tab == 1),
          ),
        ],
      ),
    );
  }
}

class _FoodBrowse extends ConsumerWidget {
  const _FoodBrowse();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(_categoryCountsProvider);

    return categoriesAsync.when(
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
        return ListView(
          padding: EdgeInsets.only(
            bottom: listBottomInset(context, hasFab: false),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(l10n.categories, style: theme.textTheme.titleSmall),
            ),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(l10n.noCategories, style: theme.textTheme.meta),
                ),
              )
            else
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.listPage,
                  ),
                  child: SportListTile(
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
                ),
          ],
        );
      },
    );
  }
}

class _FoodSearchList extends ConsumerWidget {
  const _FoodSearchList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final async = ref.watch(_foodSearchProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.loadFailed('$e'))),
      data: (foods) {
        if (foods.isEmpty) {
          return SingleChildScrollView(
            child: SportEmptyState(
              title: l10n.noFoodFound,
              icon: Icons.search,
              actionLabel: l10n.custom,
              onAction: () => context.push('/foods/custom'),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(
            bottom: listBottomInset(context, hasFab: false),
          ),
          itemCount: foods.length,
          itemBuilder: (context, i) {
            final f = foods[i];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listPage,
              ),
              child: SportListTile(
                key: ValueKey(f.id),
                title: Text(f.name, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  '${f.category.localizedCategory(l10n)} · ${f.kcalPer100.round()} kcal/100g',
                  style: theme.textTheme.meta,
                ),
                onTap: () => context.push('/foods/${f.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _FoodCollection extends ConsumerWidget {
  const _FoodCollection({required this.favorites});
  final bool favorites;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = favorites
        ? ref.watch(favoriteFoodsProvider)
        : ref.watch(_recentFoodsProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => SportLoadError(
        onRetry: () {
          if (favorites) {
            ref.invalidate(favoriteFoodsProvider);
          } else {
            ref.invalidate(_recentFoodsProvider);
          }
        },
      ),
      data: (foods) => foods.isEmpty
          ? (favorites
                ? SportEmptyState(
                    title: context.l10n.noFavorites,
                    icon: Icons.star_outline,
                  )
                : const _FoodBrowse())
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                listBottomInset(context, hasFab: false),
              ),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    favorites ? Icons.star_outline : Icons.restaurant_outlined,
                  ),
                  title: Text(food.name),
                  subtitle: Text(food.category.localizedCategory(context.l10n)),
                  trailing: Text(
                    '${food.kcalPer100.round()} kcal/100g',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => context.push('/foods/${food.id}'),
                );
              },
            ),
    );
  }
}
