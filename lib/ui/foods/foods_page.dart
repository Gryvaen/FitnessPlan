import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/food_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

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

final _foodSearchProvider =
    FutureProvider.autoDispose<List<FoodItem>>((ref) async {
  await ref.watch(foodsSeedProvider.future);
  final q = ref.watch(_foodQueryProvider).trim();
  if (q.isEmpty) return const [];
  return ref.watch(foodRepositoryProvider).search(q);
});

class FoodsPage extends ConsumerWidget {
  const FoodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final searching = ref.watch(_foodQueryProvider).trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.foodLibrary),
        actions: [
          IconButton(
            tooltip: l10n.favorites,
            icon: const Icon(Icons.star_outline),
            onPressed: () => context.push('/foods/favorites'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/foods/custom'),
        icon: const Icon(Icons.add),
        label: Text(l10n.custom),
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
          Expanded(
            child: searching ? const _FoodSearchList() : const _FoodBrowse(),
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
                ListTile(
                  title: Text(
                    c.category.localizedCategory(l10n),
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(l10n.nKinds(c.count), style: theme.textTheme.meta),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    Uri(
                      path: '/foods/category',
                      queryParameters: {'name': c.category},
                    ).toString(),
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
          return Center(child: Text(l10n.noFoodFound, style: theme.textTheme.meta));
        }
        return ListView.builder(
          itemCount: foods.length,
          itemBuilder: (context, i) {
            final f = foods[i];
            return ListTile(
              key: ValueKey(f.id),
              title: Text(f.name, style: theme.textTheme.bodyLarge),
              subtitle: Text(
                '${f.category.localizedCategory(l10n)} · ${f.kcalPer100.round()} kcal/100g',
                style: theme.textTheme.meta,
              ),
              onTap: () => context.push('/foods/${f.id}'),
            );
          },
        );
      },
    );
  }
}
