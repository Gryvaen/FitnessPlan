import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

class FoodFavoritesPage extends ConsumerWidget {
  const FoodFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favoritesAsync = ref.watch(favoriteFoodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败：$e'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(favoriteFoodsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Text('暂无收藏', style: theme.textTheme.meta),
            );
          }
          return ListView.separated(
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = favorites[i];
              return ListTile(
                key: ValueKey('fav-${f.id}'),
                leading: const Icon(Icons.star),
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
      ),
    );
  }
}
