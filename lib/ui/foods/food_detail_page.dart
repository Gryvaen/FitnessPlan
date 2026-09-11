import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
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
  bool _saving = false;
  double _grams = 100;
  MealType _mealType = MealType.lunch;

  @override
  void initState() {
    super.initState();
    final defaults = ref.read(formMemoryRepositoryProvider).loadMealDefaults();
    _mealType = defaults.mealType;
    _grams = FormOptions.snapDouble(FormOptions.mealGrams(), defaults.grams);
    _reload();
  }

  Future<void> _reload() async {
    final repo = ref.read(foodRepositoryProvider);
    final food = await repo.byId(widget.foodId);
    final servings = food == null
        ? <FoodServing>[]
        : await repo.listServings(widget.foodId);
    if (!mounted) return;
    setState(() {
      _food = food;
      _servings = servings;
      _loading = false;
    });
  }

  void _stepGrams(int dir) {
    final step = _grams < 100 ? 10.0 : 50.0;
    setState(() => _grams = (_grams + dir * step).clamp(5, 3000));
  }

  Future<void> _addToMeal() async {
    final food = _food;
    if (food == null || _saving) return;
    final l10n = context.l10n;
    final day = ref.read(selectedDayProvider);
    if (!AppDates.isLocalToday(day)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pastDayReadOnly)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(mealRepositoryProvider)
          .add(date: day, mealType: _mealType, food: food, grams: _grams);
      ref
          .read(formMemoryRepositoryProvider)
          .saveMealDefaults(mealType: _mealType, grams: _grams);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mealLoggedTo(_mealType.label(l10n)))),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
      }
    }
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
                  value: FormOptions.snapDouble(FormOptions.mealGrams(), grams),
                  items: FormOptions.mealGrams(),
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
      await ref
          .read(foodRepositoryProvider)
          .addServing(
            foodId: widget.foodId,
            label: labelCtrl.text,
            grams: grams,
          );
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
    final intake = MacroIntake.fromGrams(
      grams: _grams,
      kcalPer100: food.kcalPer100,
      proteinPer100: food.proteinPer100,
      carbPer100: food.carbPer100,
      fatPer100: food.fatPer100,
    );

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          AppSpacing.section,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${food.kcalPer100.round()}',
                style: theme.textTheme.statValue,
              ),
              const SizedBox(width: 6),
              Text('kcal / 100g', style: theme.textTheme.statUnit),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            food.category.localizedCategory(l10n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          _MacroRow(
            protein: food.proteinPer100,
            carb: food.carbPer100,
            fat: food.fatPer100,
            unitSuffix: '/ 100g',
          ),
          if (_extraRows(food, l10n).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            Text(l10n.per100g, style: theme.textTheme.titleSmall),
            for (final (label, value) in _extraRows(food, l10n))
              _kv(theme, label, value),
          ],
          const SizedBox(height: AppSpacing.section),
          Text(l10n.servingSize, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.compact),
          _GramsStepper(
            grams: _grams,
            onMinus: () => _stepGrams(-1),
            onPlus: () => _stepGrams(1),
          ),
          if (_servings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.field),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _servings)
                  ActionChip(
                    label: Text('${s.label} · ${s.grams.round()} g'),
                    onPressed: () => setState(() => _grams = s.grams),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          Text(l10n.nutritionResult, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${intake.calories.round()}',
                style: theme.textTheme.statValue,
              ),
              const SizedBox(width: 6),
              Text(
                'kcal · ${_grams.round()} g',
                style: theme.textTheme.statUnit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.field),
          _MacroRow(
            protein: intake.proteinG,
            carb: intake.carbG,
            fat: intake.fatG,
          ),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Text(l10n.commonPortions, style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: _addServing,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.add),
              ),
            ],
          ),
          if (_servings.isEmpty)
            Text(l10n.noPortionsHint, style: theme.textTheme.meta)
          else
            for (final s in _servings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.label),
                subtitle: Text(
                  '${s.grams.round()} g',
                  style: theme.textTheme.meta,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await ref.read(foodRepositoryProvider).deleteServing(s.id);
                    await _reload();
                  },
                ),
              ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          8,
          AppSpacing.formPage,
          12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final t in MealType.values)
                  ChoiceChip(
                    label: Text(t.label(l10n)),
                    selected: _mealType == t,
                    onSelected: (_) => setState(() => _mealType = t),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.compact),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _addToMeal,
                child: Text(l10n.mealAddedTo(_mealType.label(l10n))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _extraRows(FoodItem food, AppLocalizations l10n) => [
    if (food.saturatedFatPer100 > 0)
      (l10n.saturatedFat, '${food.saturatedFatPer100.toStringAsFixed(1)} g'),
    if (food.sugarPer100 > 0)
      (l10n.sugar, '${food.sugarPer100.toStringAsFixed(1)} g'),
    if (food.fiberPer100 > 0)
      (l10n.fiber, '${food.fiberPer100.toStringAsFixed(1)} g'),
    if (food.sodiumMgPer100 > 0)
      (l10n.sodium, '${food.sodiumMgPer100.toStringAsFixed(0)} mg'),
    if (food.calciumMgPer100 > 0)
      (l10n.calcium, '${food.calciumMgPer100.toStringAsFixed(0)} mg'),
    if (food.alcoholPer100 > 0)
      (l10n.alcohol, '${food.alcoholPer100.toStringAsFixed(1)} g'),
  ];

  Widget _kv(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    ),
  );
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.protein,
    required this.carb,
    required this.fat,
    this.unitSuffix,
  });

  final double protein;
  final double carb;
  final double fat;
  final String? unitSuffix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget col(String label, double v, Color c) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            '${v.toStringAsFixed(1)} g',
            style: theme.textTheme.titleSmall?.copyWith(color: c),
          ),
          if (unitSuffix != null)
            Text(
              unitSuffix!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
    return Row(
      children: [
        col(l10n.protein, protein, AppColors.protein),
        col(l10n.carbs, carb, AppColors.carb),
        col(l10n.fat, fat, AppColors.fat),
      ],
    );
  }
}

class _GramsStepper extends StatelessWidget {
  const _GramsStepper({
    required this.grams,
    required this.onMinus,
    required this.onPlus,
  });

  final double grams;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton.outlined(onPressed: onMinus, icon: const Icon(Icons.remove)),
        Expanded(
          child: Text(
            '${grams.round()} g',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ),
        IconButton.outlined(onPressed: onPlus, icon: const Icon(Icons.add)),
      ],
    );
  }
}
