import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/form_options.dart';

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
      alcoholPer100: 0,
      isCustom: false,
    );

    setState(() {
      _entry = entry;
      _food = food;
      _mealType = MealType.values.byName(entry.mealType);
      _grams = FormOptions.snapDouble(FormOptions.mealGrams, entry.grams);
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
    );
  }

  Future<void> _persist() async {
    final food = _food;
    final entry = _entry;
    if (food == null || entry == null || _saving) return;
    if (!AppDates.isLocalToday(entry.date)) return;
    setState(() => _saving = true);
    try {
      await ref.read(mealRepositoryProvider).update(
            id: widget.entryId,
            mealType: _mealType,
            food: food,
            grams: _grams,
          );
      final updated =
          await ref.read(mealRepositoryProvider).byId(widget.entryId);
      if (mounted && updated != null) {
        setState(() => _entry = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$e'))),
        );
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

  Future<void> _delete() async {
    final entry = _entry;
    if (entry == null) return;
    if (!AppDates.isLocalToday(entry.date)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pastDayReadOnly)),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleted)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteFailed('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
        title: Text(food.name),
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
              icon: const Icon(Icons.delete_outline),
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
                    value: FormOptions.snapDouble(FormOptions.mealGrams, _grams),
                    items: FormOptions.mealGrams,
                    suffixText: 'g',
                    itemLabel: formatKg,
                    onChanged: _onGramsChanged,
                  ),
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
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
