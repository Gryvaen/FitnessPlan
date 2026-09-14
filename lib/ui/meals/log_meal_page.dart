import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/food_name_link.dart';
import '../widgets/form_options.dart';

class LogMealPage extends ConsumerStatefulWidget {
  const LogMealPage({super.key, this.initialFoodId, this.initialMealType});

  final int? initialFoodId;
  final MealType? initialMealType;

  @override
  ConsumerState<LogMealPage> createState() => _LogMealPageState();
}

class _LogMealPageState extends ConsumerState<LogMealPage> {
  FoodItem? _selected;
  MealType _mealType = MealType.lunch;
  double _grams = 100;
  bool _saving = false;
  List<FoodItem> _results = [];
  List<FoodItem> _recent = [];
  List<FoodItem> _favorites = [];
  List<FoodServing> _servings = [];
  bool _loadingFoods = true;
  bool _searching = false;
  int _searchVersion = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final day = ref.read(selectedDayProvider);
      if (!AppDates.isLocalToday(day)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.pastDayReadOnly)));
        context.pop();
        return;
      }
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final memory = ref.read(formMemoryRepositoryProvider).loadMealDefaults();
    if (mounted) {
      setState(() {
        _mealType = widget.initialMealType ?? memory.mealType;
        _grams = FormOptions.snapDouble(FormOptions.mealGrams(), memory.grams);
      });
    }
    try {
      await ref.read(foodsSeedProvider.future);
      final repo = ref.read(foodRepositoryProvider);
      final recent = await repo.recentFoods();
      final favorites = await repo.favorites();
      if (widget.initialFoodId != null) {
        final food = await repo.byId(widget.initialFoodId!);
        if (mounted && food != null) await _selectFood(food);
      }
      if (!mounted) return;
      setState(() {
        _recent = recent;
        _favorites = favorites;
        _loadingFoods = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFoods = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loadFoodsFailed('$e'))),
      );
    }
  }

  Future<void> _selectFood(FoodItem food) async {
    final servings = await ref
        .read(foodRepositoryProvider)
        .listServings(food.id);
    if (!mounted) return;
    setState(() {
      _selected = food;
      _servings = servings;
    });
  }

  Future<void> _persistMealDefaults() {
    return ref
        .read(formMemoryRepositoryProvider)
        .saveMealDefaults(mealType: _mealType, grams: _grams);
  }

  Future<void> _openCustomFood() async {
    // Must stay on a root route: /log-meal is outside the shell, and pushing
    // /foods/custom would remount StatefulShellRoute (duplicate page key).
    final id = await context.push<int>('/custom-food?returnId=1');
    if (id == null || !mounted) return;
    final food = await ref.read(foodRepositoryProvider).byId(id);
    if (!mounted || food == null) return;
    await _selectFood(food);
  }

  Future<void> _refreshFavorites() async {
    final favorites = await ref.read(foodRepositoryProvider).favorites();
    if (mounted) setState(() => _favorites = favorites);
  }

  Future<void> _toggleFavorite(int foodId) async {
    try {
      await ref.read(foodRepositoryProvider).toggleFavorite(foodId);
      ref.invalidate(foodFavoriteProvider(foodId));
      await _refreshFavorites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.operationFailed('$e'))),
      );
    }
  }

  Future<void> _openFoodDetail(FoodItem food) async {
    await openFoodDetail(context, food.id);
    if (!mounted) return;
    final updated = await ref.read(foodRepositoryProvider).byId(food.id);
    if (!mounted || updated == null) return;
    await _selectFood(updated);
    await _refreshFavorites();
  }

  Future<void> _search(String q) async {
    final version = ++_searchVersion;
    final trimmed = q.trim();
    if (!mounted) return;
    setState(() {
      _query = trimmed;
      _searching = trimmed.isNotEmpty;
      if (trimmed.isEmpty) {
        _results = [];
        _loadingFoods = false;
      } else {
        _loadingFoods = true;
      }
    });
    if (trimmed.isEmpty) return;
    final list = await ref.read(foodRepositoryProvider).search(trimmed);
    if (!mounted || version != _searchVersion) return;
    setState(() {
      _results = list;
      _loadingFoods = false;
    });
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
      alcoholPer100: food.alcoholPer100,
      fiberPer100: food.fiberPer100,
      sodiumMgPer100: food.sodiumMgPer100,
      sugarPer100: food.sugarPer100,
      saturatedFatPer100: food.saturatedFatPer100,
      calciumMgPer100: food.calciumMgPer100,
    );
  }

  Future<void> _applyPreset(MealPreset preset) async {
    final day = ref.read(selectedDayProvider);
    final l10n = context.l10n;
    if (!AppDates.isLocalToday(day)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pastDayReadOnly)));
      return;
    }
    try {
      final result = await ref
          .read(mealPresetRepositoryProvider)
          .applyPreset(presetId: preset.id, date: day);
      if (!mounted) return;
      final skip = result.skippedMissingFood > 0
          ? l10n.skippedMissingFoods(result.skippedMissingFood)
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appliedPresetItems(result.copied, skip))),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.applyPresetFailed('$e'))));
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final food = _selected;
    if (food == null || _grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectFoodAndGrams)));
      return;
    }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.loggedInto(l10n.today))));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _foodTile(FoodItem f, {String? badge}) {
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('food-${f.id}'),
      title: FoodNameLink(
        name: f.name,
        foodId: f.id,
        carbG: f.carbPer100,
        proteinG: f.proteinPer100,
        fatG: f.fatPer100,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        [?badge, f.category, '${f.kcalPer100.round()} kcal/100g'].join(' · '),
        style: theme.textTheme.meta,
      ),
      onTap: () => _selectFood(f),
    );
  }

  Widget _searchFoodTile(FoodItem f) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isFav = ref.watch(foodFavoriteProvider(f.id)).value ?? false;
    return ListTile(
      key: ValueKey('search-food-${f.id}'),
      title: FoodNameLink(
        name: f.name,
        foodId: f.id,
        carbG: f.carbPer100,
        proteinG: f.proteinPer100,
        fatG: f.fatPer100,
        style: theme.textTheme.bodyLarge,
        onTap: () => _openFoodDetail(f),
      ),
      subtitle: Text(
        [f.category, '${f.kcalPer100.round()} kcal/100g'].join(' · '),
        style: theme.textTheme.meta,
      ),
      trailing: PlainIconAction(
        icon: isFav ? Icons.star : Icons.star_border,
        label: isFav ? l10n.unfavorite : l10n.favorites,
        color: AppColors.favorite,
        size: 20,
        onPressed: () => _toggleFavorite(f.id),
      ),
      onTap: () => _openFoodDetail(f),
    );
  }

  Widget _browseList() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final presetsAsync = ref.watch(mealPresetsProvider);
    final sections = <Widget>[];

    presetsAsync.whenData((presets) {
      if (presets.isEmpty) return;
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(l10n.mealPresets, style: theme.textTheme.titleSmall),
        ),
      );
      for (final p in presets) {
        sections.add(
          ListTile(
            leading: const Icon(Icons.restaurant_menu_outlined),
            title: Text(p.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(mealPresetRepositoryProvider).deletePreset(p.id);
                ref.invalidate(mealPresetsProvider);
              },
            ),
            onTap: () => _applyPreset(p),
          ),
        );
      }
    });

    if (_favorites.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(l10n.favorites, style: theme.textTheme.titleSmall),
        ),
      );
      for (final f in _favorites) {
        sections.add(_foodTile(f, badge: l10n.badgeFavorite));
      }
    }
    if (_recent.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(l10n.recentlyEaten, style: theme.textTheme.titleSmall),
        ),
      );
      for (final f in _recent) {
        sections.add(_foodTile(f, badge: l10n.badgeRecent));
      }
    }
    if (sections.isEmpty) {
      return Center(child: Text(l10n.searchToLog, style: theme.textTheme.meta));
    }
    return ListView(children: sections);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final preview = _preview;
    final day = ref.watch(selectedDayProvider);
    final dayLabel = AppDates.isLocalToday(day)
        ? l10n.todayWord
        : AppDates.md(day, locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logMealTitle(dayLabel)),
        actions: [
          IconButton(
            tooltip: l10n.addCustomFood,
            icon: const Icon(Icons.edit, color: Color(0xFFC4A035)),
            onPressed: _openCustomFood,
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
                  itemLabel: (e) => e.label(l10n),
                  onChanged: (v) {
                    setState(() => _mealType = v);
                    _persistMealDefaults();
                  },
                ),
                const SizedBox(height: AppSpacing.field),
                if (_selected != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: FoodNameLink(
                      name: _selected!.name,
                      foodId: _selected!.id,
                      carbG: _selected!.carbPer100,
                      proteinG: _selected!.proteinPer100,
                      fatG: _selected!.fatPer100,
                      style: theme.textTheme.bodyLarge,
                      onTap: () => _openFoodDetail(_selected!),
                    ),
                    subtitle: Text(
                      '${_selected!.kcalPer100.round()} kcal / 100g',
                      style: theme.textTheme.meta,
                    ),
                    trailing: TextButton(
                      onPressed: () => setState(() {
                        _selected = null;
                        _servings = [];
                      }),
                      child: Text(l10n.change),
                    ),
                    onTap: () => _openFoodDetail(_selected!),
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
                        for (final s in _servings)
                          SoftChip(
                            label: '${s.label} · ${s.grams.round()}g',
                            selected: (_grams - s.grams).abs() < 0.01,
                            color: (_grams - s.grams).abs() < 0.01
                                ? null
                                : theme.colorScheme.surfaceContainerHighest,
                            foreground: (_grams - s.grams).abs() < 0.01
                                ? null
                                : theme.colorScheme.onSurfaceVariant,
                            onTap: () {
                              setState(() => _grams = s.grams);
                              _persistMealDefaults();
                            },
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
                    onChanged: (v) {
                      setState(() => _grams = v);
                      _persistMealDefaults();
                    },
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: AppSpacing.field),
                    Text(
                      [
                        '${preview.calories.round()} kcal',
                        'P ${preview.proteinG.toStringAsFixed(1)}',
                        'C ${preview.carbG.toStringAsFixed(1)}',
                        'F ${preview.fatG.toStringAsFixed(1)}',
                        if (preview.saturatedFatG > 0)
                          '${l10n.saturatedFat} ${preview.saturatedFatG.toStringAsFixed(1)}',
                        if (preview.sugarG > 0)
                          '${l10n.sugar} ${preview.sugarG.toStringAsFixed(1)}',
                        if (preview.fiberG > 0)
                          '${l10n.fiber} ${preview.fiberG.toStringAsFixed(1)}',
                        if (preview.sodiumMg > 0)
                          '${l10n.sodium} ${preview.sodiumMg.toStringAsFixed(0)}mg',
                        if (preview.calciumMg > 0)
                          '${l10n.calcium} ${preview.calciumMg.toStringAsFixed(0)}mg',
                        if (preview.alcoholG > 0)
                          '${l10n.alcohol} ${preview.alcoholG.toStringAsFixed(1)}',
                      ].join(' · '),
                      style: theme.textTheme.meta,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.section),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? l10n.saving : l10n.save),
                  ),
                ] else ...[
                  TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchFood,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _search,
                  ),
                ],
              ],
            ),
          ),
          if (_selected == null)
            Expanded(
              child: _loadingFoods
                  ? const Center(child: CircularProgressIndicator())
                  : _searching
                  ? (_results.isEmpty
                        ? Center(
                            child: Text(
                              _query.isEmpty
                                  ? l10n.searchFood
                                  : l10n.noFoodFound,
                              style: theme.textTheme.meta,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final f = _results[i];
                              return _searchFoodTile(f);
                            },
                          ))
                  : _browseList(),
            ),
        ],
      ),
    );
  }
}
