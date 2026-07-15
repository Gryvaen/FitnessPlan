import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../data/repositories/food_repository.dart';
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
    final searching = ref.watch(_foodQueryProvider).trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('食材库')),
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
              decoration: const InputDecoration(
                hintText: '搜索食材',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => ref.read(_foodQueryProvider.notifier).set(v),
            ),
          ),
          Expanded(
            child: searching ? const _FoodSearchList() : const _CategoryList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(_categoryCountsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(child: Text('暂无分类', style: theme.textTheme.meta));
        }
        return ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = categories[i];
            return ListTile(
              title: Text(c.category, style: theme.textTheme.bodyLarge),
              subtitle: Text('${c.count} 种', style: theme.textTheme.meta),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                Uri(
                  path: '/foods/category',
                  queryParameters: {'name': c.category},
                ).toString(),
              ),
            );
          },
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
    final async = ref.watch(_foodSearchProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (foods) {
        if (foods.isEmpty) {
          return Center(child: Text('没有找到食材', style: theme.textTheme.meta));
        }
        return ListView.separated(
          itemCount: foods.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final f = foods[i];
            return ListTile(
              title: Text(f.name, style: theme.textTheme.bodyLarge),
              subtitle: Text(
                '${f.category} · ${f.kcalPer100.round()} kcal/100g',
                style: theme.textTheme.meta,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/foods/${f.id}'),
            );
          },
        );
      },
    );
  }
}
