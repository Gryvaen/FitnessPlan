import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

class FoodConvertPage extends ConsumerStatefulWidget {
  const FoodConvertPage({super.key});

  @override
  ConsumerState<FoodConvertPage> createState() => _FoodConvertPageState();
}

class _FoodConvertPageState extends ConsumerState<FoodConvertPage> {
  FoodItem? _selected;
  double _grams = 100;
  List<FoodItem> _results = [];
  bool _loading = false;
  int _searchVersion = 0;
  String _query = '';

  static const _quickGrams = <double>[50, 100, 150, 200];

  Future<void> _search(String q) async {
    final version = ++_searchVersion;
    final trimmed = q.trim();
    setState(() {
      _query = trimmed;
      _loading = trimmed.isNotEmpty;
      if (trimmed.isEmpty) _results = [];
    });
    if (trimmed.isEmpty) return;
    final list = await ref.read(foodRepositoryProvider).search(trimmed);
    if (!mounted || version != _searchVersion) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selected = food;
      _query = '';
      _results = [];
    });
  }

  Future<void> _toggleFavorite(int foodId) async {
    try {
      await ref.read(foodRepositoryProvider).toggleFavorite(foodId);
      ref.invalidate(foodFavoriteProvider(foodId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.operationFailed('$e'))),
      );
    }
  }

  MacroIntake? get _intake {
    final food = _selected;
    if (food == null || _grams <= 0) return null;
    return MacroIntake.fromGrams(
      grams: _grams,
      kcalPer100: food.kcalPer100,
      proteinPer100: food.proteinPer100,
      carbPer100: food.carbPer100,
      fatPer100: food.fatPer100,
      alcoholPer100: food.alcoholPer100,
    );
  }

  Widget _foodTile(FoodItem food, {String? badge}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: badge == null
          ? null
          : Icon(
              Icons.star,
              color: theme.colorScheme.primary,
              size: 20,
            ),
      title: Text(food.name),
      subtitle: Text(
        '${food.kcalPer100.round()} kcal / 100g',
        style: theme.textTheme.meta,
      ),
      onTap: () => _selectFood(food),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final intake = _intake;
    final gramsOpts = FormOptions.mealGrams;
    final favorites =
        ref.watch(favoriteFoodsProvider).value ?? const <FoodItem>[];
    final isFav = _selected == null
        ? false
        : ref.watch(foodFavoriteProvider(_selected!.id)).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolFoodConvert)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: l10n.searchFood,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: _search,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_query.isNotEmpty && _selected == null) ...[
            const SizedBox(height: AppSpacing.field),
            if (_results.isEmpty)
              Text(l10n.foodNotFoundShort, style: theme.textTheme.meta)
            else
              ..._results.take(20).map((f) => _foodTile(f)),
          ],
          if (_selected != null) ...[
            const SizedBox(height: AppSpacing.section),
            Card(
              child: ListTile(
                title: Text(_selected!.name),
                subtitle: Text(
                  '${_selected!.kcalPer100.round()} kcal · '
                  'P ${_selected!.proteinPer100.toStringAsFixed(1)} · '
                  'C ${_selected!.carbPer100.toStringAsFixed(1)} · '
                  'F ${_selected!.fatPer100.toStringAsFixed(1)} / 100g',
                  style: theme.textTheme.meta,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: isFav ? l10n.unfavorite : l10n.favorites,
                      icon: Icon(isFav ? Icons.star : Icons.star_border),
                      onPressed: () => _toggleFavorite(_selected!.id),
                    ),
                    IconButton(
                      tooltip: l10n.clearSelection,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selected = null),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.field),
            AppDropdown<double>(
              label: l10n.portion,
              value: FormOptions.snapDouble(gramsOpts, _grams),
              items: gramsOpts,
              suffixText: 'g',
              itemLabel: (v) => v == v.roundToDouble()
                  ? v.toStringAsFixed(0)
                  : v.toStringAsFixed(1),
              onChanged: (v) => setState(() => _grams = v),
            ),
            const SizedBox(height: AppSpacing.field),
            Wrap(
              spacing: 8,
              children: [
                for (final g in _quickGrams)
                  ChoiceChip(
                    label: Text('${g.round()} g'),
                    selected: _grams == g,
                    onSelected: (_) => setState(() => _grams = g),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            if (intake != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.convertResult, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${intake.calories.round()} kcal',
                        style: theme.textTheme.statValue,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.protein} ${intake.proteinG.toStringAsFixed(1)} g',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${l10n.carbs} ${intake.carbG.toStringAsFixed(1)} g',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${l10n.fat} ${intake.fatG.toStringAsFixed(1)} g',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (intake.alcoholG > 0.05)
                        Text(
                          l10n.alcoholWithKcal(
                            intake.alcoholG.toStringAsFixed(1),
                            '${intake.alcoholKcal.round()}',
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
          ] else if (_query.isEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            if (favorites.isEmpty)
              Text(
                l10n.foodConvertHint,
                style: theme.textTheme.meta,
              )
            else ...[
              Text(l10n.favorites, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.field),
              ...favorites.map((f) => _foodTile(f, badge: l10n.badgeFavorite)),
            ],
          ],
        ],
      ),
    );
  }
}
