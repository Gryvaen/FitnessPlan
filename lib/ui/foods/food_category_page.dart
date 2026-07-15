import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../providers/app_providers.dart';

final _categoryFoodsProvider = FutureProvider.autoDispose
    .family<List<FoodItem>, String>((ref, category) async {
  await ref.watch(foodsSeedProvider.future);
  return ref.watch(foodRepositoryProvider).byCategory(category);
});

class FoodCategoryPage extends ConsumerWidget {
  const FoodCategoryPage({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodsAsync = ref.watch(_categoryFoodsProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: foodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (foods) {
          if (foods.isEmpty) {
            return const Center(child: Text('该分类暂无食材'));
          }
          return ListView.separated(
            itemCount: foods.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = foods[i];
              return ListTile(
                title: Text(f.name),
                subtitle: Text('${f.kcalPer100.round()} kcal / 100g'),
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
