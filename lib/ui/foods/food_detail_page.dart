import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({super.key, required this.foodId});

  final int foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(foodRepositoryProvider).byId(foodId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final food = snap.data;
        if (food == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('食材不存在')),
          );
        }
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(food.name)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              ref.read(selectedDayProvider.notifier).goToToday();
              context.push('/log-meal?foodId=$foodId');
            },
            icon: const Icon(Icons.add),
            label: const Text('记入今日'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.formPage),
            children: [
              Text(food.category, style: theme.textTheme.fieldLabel),
              const SizedBox(height: 8),
              Text('每 100 克', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.section),
              _row(context, '热量', '${food.kcalPer100.round()} kcal'),
              _row(context, '蛋白质', '${food.proteinPer100.toStringAsFixed(1)} g'),
              _row(context, '碳水', '${food.carbPer100.toStringAsFixed(1)} g'),
              _row(context, '脂肪', '${food.fatPer100.toStringAsFixed(1)} g'),
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
