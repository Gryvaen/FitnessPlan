import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/macro_color.dart';
import '../theme/sport_chrome.dart';
import '../widgets/form_options.dart';
import '../widgets/search_field_focus.dart';

/// Uses the food-picking controls from 记一笔, but saves to a preset only.
class PresetFoodAddPage extends ConsumerStatefulWidget {
  const PresetFoodAddPage({super.key, required this.presetId});
  final int presetId;

  @override
  ConsumerState<PresetFoodAddPage> createState() => _PresetFoodAddPageState();
}

class _PresetFoodAddPageState extends ConsumerState<PresetFoodAddPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  FoodItem? _selected;
  MealType _mealType = MealType.lunch;
  double _grams = 100;
  List<FoodItem> _recent = [];
  List<FoodItem> _favorites = [];
  List<FoodItem> _results = [];
  List<FoodServing> _servings = [];
  bool _loading = true;
  bool _saving = false;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    suppressInitialSearchFocus(_searchFocus);
    _mealType = ref
        .read(formMemoryRepositoryProvider)
        .loadMealDefaults()
        .mealType;
    _loadFoods();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    try {
      await ref.read(foodsSeedProvider.future);
      final repo = ref.read(foodRepositoryProvider);
      final recent = await repo.recentFoods();
      final favorites = await repo.favorites();
      if (!mounted) return;
      setState(() {
        _recent = recent;
        _favorites = favorites;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loadFoodsFailed('$error'))),
      );
    }
  }

  Future<void> _selectFood(FoodItem food) async {
    _searchFocus.unfocus();
    final repo = ref.read(foodRepositoryProvider);
    final servings = await repo.listServings(food.id);
    final lastGrams = await repo.lastGramsFor(food.id);
    if (!mounted) return;
    setState(() {
      _selected = food;
      _servings = servings;
      _grams = lastGrams ?? 100;
    });
  }

  Future<void> _searchFoods(String value) async {
    final version = ++_searchVersion;
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    try {
      final results = await ref.read(foodRepositoryProvider).search(query);
      if (!mounted || version != _searchVersion) return;
      setState(() => _results = results);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loadFailed('$error'))),
        );
      }
    }
  }

  Future<void> _createCustomFood() async {
    final id = await context.push<int>('/custom-food?returnFoodId=1');
    if (!mounted || id == null) return;
    final food = await ref.read(foodRepositoryProvider).byId(id);
    if (food == null || !mounted) return;
    await _selectFood(food);
    await _loadFoods();
  }

  MacroIntake? get _preview {
    final food = _selected;
    if (food == null || _grams <= 0) return null;
    return MacroIntake.fromGrams(
      grams: _grams,
      kcalPer100: food.kcalPer100,
      proteinPer100: food.proteinPer100,
      carbPer100: food.carbPer100,
      fatPer100: food.fatPer100,
    );
  }

  Future<void> _save() async {
    final food = _selected;
    if (food == null || _saving) return;
    if (!_grams.isFinite || _grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidGramsValue)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(mealPresetRepositoryProvider)
          .addItem(
            presetId: widget.presetId,
            foodId: food.id,
            grams: _grams,
            mealType: _mealType,
          );
      ref.invalidate(mealPresetsProvider);
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _foodTile(FoodItem food) {
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('preset-picker-food-${food.id}'),
      title: Text(
        food.displayName(context),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: dominantMacroColor(
            carbG: food.carbPer100,
            proteinG: food.proteinPer100,
            fatG: food.fatPer100,
          ),
        ),
      ),
      subtitle: Text(
        '${food.category.localizedCategory(context.l10n)} · '
        '${food.kcalPer100.round()} kcal/100g',
        style: theme.textTheme.meta,
      ),
      onTap: () => _selectFood(food),
    );
  }

  Widget _browseFoods() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (_search.text.trim().isNotEmpty) {
      return _results.isEmpty
          ? Center(child: Text(l10n.noFoodFound))
          : ListView(children: [for (final food in _results) _foodTile(food)]);
    }
    if (_recent.isEmpty && _favorites.isEmpty) {
      return Center(child: Text(l10n.searchToLog, style: theme.textTheme.meta));
    }
    return ListView(
      children: [
        if (_favorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.favorites, style: theme.textTheme.titleSmall),
          ),
          for (final food in _favorites) _foodTile(food),
        ],
        if (_recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(l10n.recentlyEaten, style: theme.textTheme.titleSmall),
          ),
          for (final food in _recent) _foodTile(food),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preview = _preview;
    return PopScope(
      canPop: _selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selected != null) {
          setState(() {
            _selected = null;
            _servings = [];
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.presetAddFood),
          actions: [
            IconButton(
              tooltip: l10n.addCustomFood,
              onPressed: _createCustomFood,
              icon: const InkIcon(InkGlyph.autoFix, size: 29),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.listPage),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropdown<MealType>(
                    label: l10n.mealType,
                    value: _mealType,
                    items: MealType.values,
                    itemLabel: (type) => type.label(l10n),
                    onChanged: (type) => setState(() => _mealType = type),
                  ),
                  const SizedBox(height: AppSpacing.field),
                  if (_selected == null)
                    TextField(
                      controller: _search,
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        hintText: l10n.searchFood,
                        prefixIcon: const InkIcon(InkGlyph.search),
                      ),
                      onChanged: _searchFoods,
                    )
                  else ...[
                    ListTile(
                      key: const ValueKey('preset-selected-food'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(_selected!.displayName(context)),
                      subtitle: Text(
                        '${_selected!.kcalPer100.round()} kcal / 100g',
                        style: theme.textTheme.meta,
                      ),
                    ),
                    if (_servings.isNotEmpty) ...[
                      Text(
                        l10n.commonPortions,
                        style: theme.textTheme.fieldLabel,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final serving in _servings)
                            SoftChip(
                              label:
                                  '${serving.label} · ${serving.grams.round()}g',
                              selected: (_grams - serving.grams).abs() < 0.01,
                              onTap: () =>
                                  setState(() => _grams = serving.grams),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.field),
                    ],
                    AppDropdown<double>(
                      label: l10n.grams,
                      value: FormOptions.snapDouble(
                        FormOptions.mealGrams(),
                        _grams,
                      ),
                      items: FormOptions.mealGrams(),
                      suffixText: 'g',
                      itemLabel: formatKg,
                      onChanged: (value) => setState(() => _grams = value),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: AppSpacing.field),
                      Text(
                        '${preview.calories.round()} kcal · '
                        'P ${preview.proteinG.toStringAsFixed(1)} · '
                        'C ${preview.carbG.toStringAsFixed(1)} · '
                        'F ${preview.fatG.toStringAsFixed(1)}',
                        style: theme.textTheme.meta,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? l10n.saving : l10n.save),
                    ),
                  ],
                ],
              ),
            ),
            if (_selected == null)
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _browseFoods(),
              ),
          ],
        ),
      ),
    );
  }
}
