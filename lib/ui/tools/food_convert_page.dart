import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/macro_color.dart';
import '../theme/sport_chrome.dart';
import '../widgets/food_name_link.dart';
import '../widgets/form_options.dart';
import '../widgets/search_field_focus.dart';

/// One food + portion the user has added to the converter's running list.
class _ConvertEntry {
  _ConvertEntry(this.food, {this.grams = 100}) : key = UniqueKey();

  _ConvertEntry._(this.key, this.food, this.grams);

  final Key key;
  final FoodItem food;
  final double grams;

  /// Keeps [key] so a portion edit does not remount the Dismissible row.
  _ConvertEntry copyWith({double? grams}) =>
      _ConvertEntry._(key, food, grams ?? this.grams);

  MacroIntake get intake => MacroIntake.fromGrams(
    grams: grams,
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

class FoodConvertPage extends ConsumerStatefulWidget {
  const FoodConvertPage({super.key});

  @override
  ConsumerState<FoodConvertPage> createState() => _FoodConvertPageState();
}

class _FoodConvertPageState extends ConsumerState<FoodConvertPage> {
  final List<_ConvertEntry> _entries = [];
  List<FoodItem> _results = [];
  bool _loading = false;
  int _searchVersion = 0;
  String _query = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    suppressInitialSearchFocus(_searchFocus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Keeps the search field from reclaiming focus when a route/sheet that was
  /// opened on top of it is dismissed (Flutter restores the prior focus).
  Future<T> _withoutSearchFocus<T>(Future<T> Function() action) {
    return withoutSearchFocus(focus: _searchFocus, action: action);
  }

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

  /// Opens the portion sheet for [food] and, if confirmed, appends it.
  /// The search field is cleared and stays unfocused until the user taps it.
  Future<void> _pickFood(FoodItem food) async {
    await _withoutSearchFocus(() async {
      _searchController.clear();
      setState(() {
        _query = '';
        _results = [];
      });
      final servings = await ref
          .read(foodRepositoryProvider)
          .listServings(food.id);
      if (!mounted) return;
      final result = await showModalBottomSheet<_PortionSheetResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PortionSheet(
          food: food,
          grams: 100,
          servings: servings,
          allowRemove: false,
        ),
      );
      if (result == null || result.remove || !mounted) return;
      setState(() => _entries.add(_ConvertEntry(food, grams: result.grams)));
    });
  }

  Future<void> _openFoodDetail(int foodId) async {
    await _withoutSearchFocus(() => openFoodDetail(context, foodId));
  }

  void _clearEntries() => setState(_entries.clear);

  Future<void> _editPortion(int index) async {
    final entry = _entries[index];
    final servings = await ref
        .read(foodRepositoryProvider)
        .listServings(entry.food.id);
    if (!mounted) return;
    final result = await showModalBottomSheet<_PortionSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PortionSheet(
        food: entry.food,
        grams: entry.grams,
        servings: servings,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.remove) {
        _entries.removeAt(index);
      } else {
        _entries[index] = entry.copyWith(grams: result.grams);
      }
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

  MacroIntake get _totalIntake =>
      _entries.fold(const MacroIntake(), (sum, e) => sum + e.intake);

  double get _totalGrams => _entries.fold(0.0, (s, e) => s + e.grams);

  /// Secondary nutrients as compact "label value" pills — a `Wrap` of these
  /// reads far faster than one text line per nutrient.
  List<Widget> _nutrientChips(AppLocalizations l10n, MacroIntake intake) => [
    if (intake.saturatedFatG > 0.05)
      _NutrientChip(
        label: l10n.saturatedFat,
        value: '${intake.saturatedFatG.toStringAsFixed(1)} g',
      ),
    if (intake.sugarG > 0.05)
      _NutrientChip(
        label: l10n.sugar,
        value: '${intake.sugarG.toStringAsFixed(1)} g',
      ),
    if (intake.fiberG > 0.05)
      _NutrientChip(
        label: l10n.fiber,
        value: '${intake.fiberG.toStringAsFixed(1)} g',
      ),
    if (intake.sodiumMg > 0.5)
      _NutrientChip(
        label: l10n.sodium,
        value: '${intake.sodiumMg.toStringAsFixed(0)} mg',
      ),
    if (intake.calciumMg > 0.5)
      _NutrientChip(
        label: l10n.calcium,
        value: '${intake.calciumMg.toStringAsFixed(0)} mg',
      ),
    if (intake.alcoholG > 0.05)
      _NutrientChip(
        label: l10n.alcohol,
        value:
            '${intake.alcoholG.toStringAsFixed(1)} g · '
            '${intake.alcoholKcal.round()} kcal',
      ),
  ];

  Widget _foodTile(
    FoodItem food, {
    bool favorite = false,
    bool pickOnTap = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = dominantMacroColor(
      carbG: food.carbPer100,
      proteinG: food.proteinPer100,
      fatG: food.fatPer100,
    );
    final isFav =
        favorite || (ref.watch(foodFavoriteProvider(food.id)).value ?? false);
    return SportListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: accent ?? scheme.onSurfaceVariant.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
      ),
      title: FoodNameLink(
        name: food.name,
        foodId: food.id,
        carbG: food.carbPer100,
        proteinG: food.proteinPer100,
        fatG: food.fatPer100,
        onTap: () => _openFoodDetail(food.id),
      ),
      subtitle: Text(
        '${food.kcalPer100.round()} kcal / 100g',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlainIconAction(
            icon: isFav ? Icons.star : Icons.star_border,
            label: isFav ? l10n.unfavorite : l10n.favorites,
            color: AppColors.favorite,
            size: 20,
            onPressed: () => _toggleFavorite(food.id),
          ),
          if (!pickOnTap)
            PlainIconAction(
              icon: Icons.add,
              label: l10n.add,
              size: 22,
              onPressed: () => _pickFood(food),
            ),
        ],
      ),
      onTap: pickOnTap
          ? () => _pickFood(food)
          : () => _openFoodDetail(food.id),
    );
  }

  /// A food already on the list: portion + kcal + macros at a glance;
  /// tap name for detail, tap the rest to change portion, swipe left to remove.
  Widget _entryTile(int index) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = _entries[index];
    final intake = entry.intake;
    final accent = dominantMacroColor(
      carbG: entry.food.carbPer100,
      proteinG: entry.food.proteinPer100,
      fatG: entry.food.fatPer100,
    );
    return Dismissible(
      key: entry.key,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: scheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _entries.removeWhere((e) => e.key == entry.key));
      },
      child: SportListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accent ?? scheme.onSurfaceVariant.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
        title: FoodNameLink(
          name: entry.food.name,
          foodId: entry.food.id,
          carbG: entry.food.carbPer100,
          proteinG: entry.food.proteinPer100,
          fatG: entry.food.fatPer100,
          onTap: () => _openFoodDetail(entry.food.id),
        ),
        subtitle: Text(
          '${entry.grams.round()} g · ${intake.calories.round()} kcal · '
          'P ${intake.proteinG.toStringAsFixed(1)} · '
          'C ${intake.carbG.toStringAsFixed(1)} · '
          'F ${intake.fatG.toStringAsFixed(1)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        onTap: () => _editPortion(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final total = _totalIntake;
    final favorites =
        ref.watch(favoriteFoodsProvider).value ?? const <FoodItem>[];

    return AppChromeScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.listPage,
          0,
          AppSpacing.listPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          PageTitle(
            title: l10n.toolFoodConvert,
            subtitle: l10n.toolFoodConvertSub,
            padding: const EdgeInsets.only(bottom: AppSpacing.section),
          ),
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              labelText: l10n.searchFood,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _search,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_query.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.field),
            if (_results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.foodNotFoundShort,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._results.take(20).map((f) => _foodTile(f, pickOnTap: false)),
          ],
          if (_query.isEmpty) ...[
            if (_entries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.addedFoodsTitle(_entries.length),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearEntries,
                    child: Text(l10n.clearAllFoods),
                  ),
                ],
              ),
              ...List.generate(_entries.length, _entryTile),
              const SizedBox(height: AppSpacing.section),
              Text(l10n.convertResult, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${total.calories.round()}',
                    style: theme.textTheme.statValue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'kcal · ${_totalGrams.round()} g',
                    style: theme.textTheme.statUnit,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.field),
              _MacroRow(
                protein: total.proteinG,
                carb: total.carbG,
                fat: total.fatG,
                alcoholKcal: total.alcoholKcal,
              ),
              if (_nutrientChips(l10n, total) case final chips
                  when chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.field),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
              const SizedBox(height: AppSpacing.section),
            ],
            if (favorites.isNotEmpty) ...[
              if (_entries.isEmpty) const SizedBox(height: AppSpacing.section),
              Text(l10n.favorites, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.compact),
              ...favorites.map(
                (f) => _foodTile(f, favorite: true, pickOnTap: false),
              ),
            ],
            if (_entries.isEmpty && favorites.isEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              Text(
                l10n.foodConvertHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// What [_PortionSheet] was dismissed with: a confirmed gram amount, or a
/// request to remove the entry entirely.
class _PortionSheetResult {
  const _PortionSheetResult.grams(this.grams) : remove = false;
  const _PortionSheetResult.remove() : grams = 0, remove = true;

  final double grams;
  final bool remove;
}

/// Bottom sheet for choosing or adjusting one entry's portion — food-
/// specific common servings (when present) and the full gram picker, with a
/// live kcal preview so the effect of each tap is visible immediately.
class _PortionSheet extends StatefulWidget {
  const _PortionSheet({
    required this.food,
    required this.grams,
    required this.servings,
    this.allowRemove = true,
  });

  final FoodItem food;
  final double grams;
  final List<FoodServing> servings;
  final bool allowRemove;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late double _grams = widget.grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final food = widget.food;
    final gramsOpts = FormOptions.mealGrams();
    final kcal = food.kcalPer100 * _grams / 100;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        0,
        AppSpacing.formPage,
        AppSpacing.formPage + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FoodNameLink(
            name: food.name,
            foodId: food.id,
            carbG: food.carbPer100,
            proteinG: food.proteinPer100,
            fatG: food.fatPer100,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${kcal.round()} kcal · ${_grams.round()} g',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (widget.servings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            Text(l10n.commonPortions, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in widget.servings)
                  SoftChip(
                    label: '${s.label} · ${s.grams.round()}g',
                    selected: (_grams - s.grams).abs() < 0.01,
                    color: (_grams - s.grams).abs() < 0.01
                        ? null
                        : scheme.surfaceContainerHighest,
                    foreground: (_grams - s.grams).abs() < 0.01
                        ? null
                        : scheme.onSurfaceVariant,
                    onTap: () => setState(() => _grams = s.grams),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.section),
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
          const SizedBox(height: AppSpacing.section),
          if (widget.allowRemove)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      const _PortionSheetResult.remove(),
                    ),
                    child: Text(l10n.remove),
                  ),
                ),
                const SizedBox(width: AppSpacing.field),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _PortionSheetResult.grams(_grams),
                    ),
                    child: Text(l10n.done),
                  ),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _PortionSheetResult.grams(_grams),
              ),
              child: Text(l10n.done),
            ),
        ],
      ),
    );
  }
}

/// Compact "label value" pill for a secondary nutrient (fiber, sugar, ...).
class _NutrientChip extends StatelessWidget {
  const _NutrientChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Protein / carb / fat: a slim kcal-share bar (fat's 9 kcal/g would
/// otherwise look under-weighted next to carb/protein's 4 if the bar were
/// sized by grams) plus each macro's grams and % of total calories.
class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.protein,
    required this.carb,
    required this.fat,
    required this.alcoholKcal,
  });

  final double protein;
  final double carb;
  final double fat;
  final double alcoholKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final proteinKcal = protein * 4;
    final carbKcal = carb * 4;
    final fatKcal = fat * 9;
    final totalKcal = proteinKcal + carbKcal + fatKcal + alcoholKcal;
    int pct(double kcal) =>
        totalKcal > 0 ? (kcal / totalKcal * 100).round() : 0;
    int share(double kcal) =>
        totalKcal > 0 ? (kcal * 1000 / totalKcal).round().clamp(1, 1000) : 0;

    Widget col(String label, double v, Color c, double kcal) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            '${v.toStringAsFixed(1)} g',
            style: theme.textTheme.titleSmall?.copyWith(color: c),
          ),
          if (totalKcal > 0)
            Text(
              '${pct(kcal)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalKcal > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (proteinKcal > 0)
                    Expanded(
                      flex: share(proteinKcal),
                      child: const ColoredBox(color: AppColors.protein),
                    ),
                  if (carbKcal > 0)
                    Expanded(
                      flex: share(carbKcal),
                      child: const ColoredBox(color: AppColors.carb),
                    ),
                  if (fatKcal > 0)
                    Expanded(
                      flex: share(fatKcal),
                      child: const ColoredBox(color: AppColors.fat),
                    ),
                  if (alcoholKcal > 0)
                    Expanded(
                      flex: share(alcoholKcal),
                      child: ColoredBox(color: scheme.outlineVariant),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.compact),
        ],
        Row(
          children: [
            col(l10n.protein, protein, AppColors.protein, proteinKcal),
            col(l10n.carbs, carb, AppColors.carb, carbKcal),
            col(l10n.fat, fat, AppColors.fat, fatKcal),
          ],
        ),
      ],
    );
  }
}
