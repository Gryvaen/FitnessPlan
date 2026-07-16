import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
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
    final l10n = context.l10n;
    final labelCtrl = TextEditingController();
    double grams = 100;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addCommonPortion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.portionNameHint,
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setLocal) {
                return AppDropdown<double>(
                  label: l10n.grams,
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
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.add),
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
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCustomFood),
        content: Text(l10n.deleteCustomFoodBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
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
    final l10n = context.l10n;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final food = _food;
    if (food == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.foodNotFound)),
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
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/foods/custom?id=${food.id}');
                await _reload();
              },
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteFood,
            ),
          ],
          IconButton(
            tooltip: isFav ? l10n.unfavorite : l10n.favorites,
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
                    SnackBar(content: Text(l10n.operationFailed('$e'))),
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
        label: Text(l10n.logMeal),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            food.category.localizedCategory(l10n),
            style: theme.textTheme.fieldLabel,
          ),
          const SizedBox(height: 8),
          Text(l10n.per100g, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.section),
          _row(context, l10n.calories, '${food.kcalPer100.round()} kcal'),
          _row(context, l10n.protein, '${food.proteinPer100.toStringAsFixed(1)} g'),
          _row(context, l10n.carbs, '${food.carbPer100.toStringAsFixed(1)} g'),
          _row(context, l10n.fat, '${food.fatPer100.toStringAsFixed(1)} g'),
          if (food.alcoholPer100 > 0)
            _row(context, l10n.alcohol, '${food.alcoholPer100.toStringAsFixed(1)} g'),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Text(l10n.commonPortions, style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _addServing,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.add),
              ),
            ],
          ),
          if (_servings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.noPortionsHint, style: theme.textTheme.meta),
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
