import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../providers/app_providers.dart';

final _foodQueryProvider = NotifierProvider<_QueryNotifier, String>(
  _QueryNotifier.new,
);

class _QueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

final _foodListProvider = FutureProvider.autoDispose<List<FoodItem>>((ref) {
  final q = ref.watch(_foodQueryProvider);
  return ref.watch(foodRepositoryProvider).search(q);
});

class FoodsPage extends ConsumerWidget {
  const FoodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodsAsync = ref.watch(_foodListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('食材库')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索食材，如 鸡胸、米饭',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => ref.read(_foodQueryProvider.notifier).set(v),
            ),
          ),
          Expanded(
            child: foodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (foods) {
                if (foods.isEmpty) {
                  return const Center(child: Text('没有找到食材'));
                }
                return ListView.separated(
                  itemCount: foods.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final f = foods[i];
                    return ListTile(
                      title: Text(f.name),
                      subtitle: Text(
                        '${f.category} · ${f.kcalPer100.round()} kcal / 100g',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/foods/${f.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
