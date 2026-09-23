import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/food_name_link.dart';
import '../widgets/form_options.dart';
import '../widgets/search_field_focus.dart';

class MealDetailPage extends ConsumerStatefulWidget {
  const MealDetailPage({super.key, required this.entryId});

  final int entryId;

  @override
  ConsumerState<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends ConsumerState<MealDetailPage> {
  bool _loading = true;
  bool _notFound = false;
  bool _saving = false;

  MealEntry? _entry;
  FoodItem? _food;
  List<FoodServing> _servings = [];
  MealType _mealType = MealType.lunch;
  double _grams = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entry = await ref.read(mealRepositoryProvider).byId(widget.entryId);
    if (!mounted) return;
    if (entry == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    var food = await ref.read(foodRepositoryProvider).byId(entry.foodId);
    food ??= FoodItem(
      id: entry.foodId,
      name: entry.foodName,
      category: '',
      kcalPer100: entry.grams > 0 ? entry.calories / entry.grams * 100 : 0,
      proteinPer100: entry.grams > 0 ? entry.proteinG / entry.grams * 100 : 0,
      carbPer100: entry.grams > 0 ? entry.carbG / entry.grams * 100 : 0,
      fatPer100: entry.grams > 0 ? entry.fatG / entry.grams * 100 : 0,
      alcoholPer100: entry.grams > 0 ? entry.alcoholG / entry.grams * 100 : 0,
      fiberPer100: entry.grams > 0 ? entry.fiberG / entry.grams * 100 : 0,
      sodiumMgPer100: entry.grams > 0 ? entry.sodiumMg / entry.grams * 100 : 0,
      sugarPer100: entry.grams > 0 ? entry.sugarG / entry.grams * 100 : 0,
      saturatedFatPer100: entry.grams > 0
          ? entry.saturatedFatG / entry.grams * 100
          : 0,
      calciumMgPer100: entry.grams > 0
          ? entry.calciumMg / entry.grams * 100
          : 0,
      isCustom: false,
    );
    final servings = await ref
        .read(foodRepositoryProvider)
        .listServings(food.id);

    if (!mounted) return;
    setState(() {
      _entry = entry;
      _food = food;
      _servings = servings;
      _mealType = MealType.values.byName(entry.mealType);
      _grams = FormOptions.snapDouble(FormOptions.mealGrams(), entry.grams);
      _loading = false;
    });
  }

  MacroIntake get _preview {
    final food = _food!;
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

  Future<void> _persist() async {
    final food = _food;
    final entry = _entry;
    if (food == null || entry == null || _saving) return;
    if (!AppDates.isLocalToday(entry.date)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(mealRepositoryProvider)
          .update(
            id: widget.entryId,
            mealType: _mealType,
            food: food,
            grams: _grams,
          );
      final updated = await ref
          .read(mealRepositoryProvider)
          .byId(widget.entryId);
      if (mounted && updated != null) {
        setState(() => _entry = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onMealTypeChanged(MealType value) async {
    if (value == _mealType) return;
    setState(() => _mealType = value);
    await _persist();
  }

  Future<void> _onGramsChanged(double value) async {
    if (value == _grams) return;
    setState(() => _grams = value);
    await _persist();
  }

  Future<void> _editServing(FoodServing serving) async {
    final l10n = context.l10n;
    final labelCtrl = TextEditingController(text: serving.label);
    final labelFocus = FocusNode();
    suppressInitialTextFocus(labelFocus);
    var grams = serving.grams;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editCommonPortion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              focusNode: labelFocus,
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final label = labelCtrl.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      labelCtrl.dispose();
      labelFocus.dispose();
    });
    if (ok != true || !mounted) return;

    final wasSelected = (_grams - serving.grams).abs() < 0.01;
    try {
      await ref
          .read(foodRepositoryProvider)
          .updateServing(id: serving.id, label: label, grams: grams);
      if (!mounted) return;
      final food = _food;
      if (food != null) {
        final servings = await ref
            .read(foodRepositoryProvider)
            .listServings(food.id);
        if (!mounted) return;
        setState(() => _servings = servings);
      }
      if (wasSelected) await _onGramsChanged(grams);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
      }
    }
  }

  Future<void> _openFoodDetail() async {
    final food = _food;
    if (food == null) return;
    await openFoodDetail(context, food.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _delete() async {
    final entry = _entry;
    if (entry == null) return;
    if (!AppDates.isLocalToday(entry.date)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.pastDayReadOnly)));
      return;
    }

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.confirmDeleteMeal),
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
      await ref.read(mealRepositoryProvider).delete(widget.entryId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleted)));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleteFailed('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_notFound || _entry == null || _food == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.recordNotFound)),
      );
    }

    final entry = _entry!;
    final food = _food!;
    final preview = _preview;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final editable = AppDates.isLocalToday(entry.date);

    return Scaffold(
      appBar: AppBar(
        title: FoodNameLink(
          name: food.name,
          foodId: food.id,
          carbG: food.carbPer100,
          proteinG: food.proteinPer100,
          fatG: food.fatPer100,
          onTap: _openFoodDetail,
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (editable)
            IconButton(
              icon: const InkIcon(InkGlyph.delete),
              tooltip: l10n.delete,
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            AppDates.md(entry.date, locale),
            style: theme.textTheme.fieldLabel,
          ),
          if (!editable) ...[
            const SizedBox(height: 4),
            Text(l10n.pastDayReadOnly, style: theme.textTheme.meta),
          ],
          const SizedBox(height: 4),
          Text(
            '${food.kcalPer100.round()} kcal / 100g',
            style: theme.textTheme.meta,
          ),
          const SizedBox(height: AppSpacing.section),
          IgnorePointer(
            ignoring: !editable,
            child: Opacity(
              opacity: editable ? 1 : 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdown<MealType>(
                    label: l10n.mealType,
                    value: _mealType,
                    items: MealType.values,
                    itemLabel: (e) => e.label(l10n),
                    onChanged: _onMealTypeChanged,
                  ),
                  const SizedBox(height: AppSpacing.field),
                  AppDropdown<double>(
                    label: l10n.grams,
                    value: FormOptions.snapDouble(
                      FormOptions.mealGrams(),
                      _grams,
                    ),
                    items: FormOptions.mealGrams(),
                    suffixText: 'g',
                    itemLabel: formatKg,
                    onChanged: _onGramsChanged,
                  ),
                  if (_servings.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.field),
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
                            onTap: () => _onGramsChanged(s.grams),
                            onLongPress: () => _editServing(s),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.nutritionIntake, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.section),
          _MacroRow(
            label: l10n.calories,
            value: '${preview.calories.round()} kcal',
            color: theme.colorScheme.primary,
          ),
          _MacroRow(
            label: l10n.protein,
            value: '${preview.proteinG.toStringAsFixed(1)} g',
            color: AppColors.protein,
          ),
          _MacroRow(
            label: l10n.carbs,
            value: '${preview.carbG.toStringAsFixed(1)} g',
            color: AppColors.carb,
          ),
          _MacroRow(
            label: l10n.fat,
            value: '${preview.fatG.toStringAsFixed(1)} g',
            color: AppColors.fat,
          ),
          if (preview.saturatedFatG > 0)
            _MacroRow(
              label: l10n.saturatedFat,
              value: '${preview.saturatedFatG.toStringAsFixed(1)} g',
              color: AppColors.fat,
            ),
          if (preview.sugarG > 0)
            _MacroRow(
              label: l10n.sugar,
              value: '${preview.sugarG.toStringAsFixed(1)} g',
              color: AppColors.carb,
            ),
          if (preview.fiberG > 0)
            _MacroRow(
              label: l10n.fiber,
              value: '${preview.fiberG.toStringAsFixed(1)} g',
              color: AppColors.carb,
            ),
          if (preview.sodiumMg > 0)
            _MacroRow(
              label: l10n.sodium,
              value: '${preview.sodiumMg.toStringAsFixed(0)} mg',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          if (preview.calciumMg > 0)
            _MacroRow(
              label: l10n.calcium,
              value: '${preview.calciumMg.toStringAsFixed(0)} mg',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          if (preview.alcoholG > 0)
            _MacroRow(
              label: l10n.alcohol,
              value: '${preview.alcoholG.toStringAsFixed(1)} g',
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
