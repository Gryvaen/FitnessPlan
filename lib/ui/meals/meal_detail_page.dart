import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
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
    );
  }

  Future<void> _persist() async {
    final food = _food;
    final entry = _entry;
    if (food == null || entry == null || _saving) return;
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
          SnackBar(content: Text('保存失败：$e')),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条记录？'),
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
      await ref.read(mealRepositoryProvider).delete(widget.entryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_notFound || _entry == null || _food == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('记录不存在')),
      );
    }

    final entry = _entry!;
    final food = _food!;
    final preview = _preview;
    final theme = Theme.of(context);

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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Text(
            DateFormat('M月d日').format(entry.date),
            style: theme.textTheme.fieldLabel,
          ),
          const SizedBox(height: 4),
          Text(
            '${food.kcalPer100.round()} kcal / 100g',
            style: theme.textTheme.meta,
          ),
          const SizedBox(height: AppSpacing.section),
          AppDropdown<MealType>(
            label: '餐次',
            value: _mealType,
            items: MealType.values,
            itemLabel: (e) => e.label,
            onChanged: _onMealTypeChanged,
          ),
          const SizedBox(height: AppSpacing.field),
          AppDropdown<double>(
            label: '克数',
            value: FormOptions.snapDouble(FormOptions.mealGrams, _grams),
            items: FormOptions.mealGrams,
            suffixText: 'g',
            itemLabel: formatKg,
            onChanged: _onGramsChanged,
          ),
          const SizedBox(height: 28),
          Text('营养摄入', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.section),
          _MacroRow(
            label: '热量',
            value: '${preview.calories.round()} kcal',
            color: theme.colorScheme.primary,
          ),
          _MacroRow(
            label: '蛋白质',
            value: '${preview.proteinG.toStringAsFixed(1)} g',
            color: AppColors.protein,
          ),
          _MacroRow(
            label: '碳水',
            value: '${preview.carbG.toStringAsFixed(1)} g',
            color: AppColors.carb,
          ),
          _MacroRow(
            label: '脂肪',
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
