import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class FoodDetailPage extends ConsumerStatefulWidget {
  const FoodDetailPage({super.key, required this.foodId});

  final int foodId;

  @override
  ConsumerState<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends ConsumerState<FoodDetailPage> {
  FoodItem? _food;
  List<FoodServing> _servings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final repo = ref.read(foodRepositoryProvider);
    final food = await repo.byId(widget.foodId);
    final servings =
        food == null ? <FoodServing>[] : await repo.listServings(widget.foodId);
    if (!mounted) return;
    setState(() {
      _food = food;
      _servings = servings;
      _loading = false;
    });
  }

  Future<void> _addServing() async {
    final labelCtrl = TextEditingController();
    double grams = 100;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加常用份量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '如：一碗 / 瓶 500ml',
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setLocal) {
                return AppDropdown<double>(
                  label: '克数',
                  value: FormOptions.snapDouble(FormOptions.mealGrams, grams),
                  items: FormOptions.mealGrams,
                  suffixText: 'g',
                  itemLabel: formatKg,
                  onChanged: (v) => setLocal(() => grams = v),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(foodRepositoryProvider).addServing(
            foodId: widget.foodId,
            label: labelCtrl.text,
            grams: grams,
          );
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      labelCtrl.dispose();
    }
  }

  Future<void> _deleteFood() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除自定义食材'),
        content: const Text('确定删除？历史记账仍会保留名称。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(foodRepositoryProvider).deleteCustom(widget.foodId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favAsync = ref.watch(foodFavoriteProvider(widget.foodId));
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final food = _food;
    if (food == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('食材不存在')),
      );
    }
    final theme = Theme.of(context);
    final isFav = favAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(food.name),
        actions: [
          if (food.isCustom) ...[
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/foods/custom?id=${food.id}');
                await _reload();
              },
            ),
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteFood,
            ),
          ],
          IconButton(
            tooltip: isFav ? '取消收藏' : '收藏',
            icon: Icon(isFav ? Icons.star : Icons.star_border),
            onPressed: () async {
              try {
                await ref
                    .read(foodRepositoryProvider)
                    .toggleFavorite(widget.foodId);
                ref.invalidate(foodFavoriteProvider(widget.foodId));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失败：$e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log-meal?foodId=${widget.foodId}'),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
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
          if (food.alcoholPer100 > 0)
            _row(context, '酒精', '${food.alcoholPer100.toStringAsFixed(1)} g'),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Text('常用份量', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _addServing,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
              ),
            ],
          ),
          if (_servings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('暂无，记账时可快速选用', style: theme.textTheme.meta),
            )
          else
            for (final s in _servings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.label),
                subtitle: Text('${s.grams.round()} g', style: theme.textTheme.meta),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await ref.read(foodRepositoryProvider).deleteServing(s.id);
                    await _reload();
                  },
                ),
              ),
          const SizedBox(height: 72),
        ],
      ),
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
