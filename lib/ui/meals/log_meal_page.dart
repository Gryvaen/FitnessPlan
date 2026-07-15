import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../widgets/form_options.dart';

class LogMealPage extends ConsumerStatefulWidget {
  const LogMealPage({super.key, this.initialFoodId});

  final int? initialFoodId;

  @override
  ConsumerState<LogMealPage> createState() => _LogMealPageState();
}

class _LogMealPageState extends ConsumerState<LogMealPage> {
  FoodItem? _selected;
  MealType _mealType = MealType.lunch;
  double _grams = 100;
  bool _saving = false;
  List<FoodItem> _results = [];
  bool _loadingFoods = true;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await ref.read(foodsSeedProvider.future);
    if (widget.initialFoodId != null) {
      final food = await ref
          .read(foodRepositoryProvider)
          .byId(widget.initialFoodId!);
      if (mounted) setState(() => _selected = food);
    }
    await _search('');
  }

  Future<void> _search(String q) async {
    final version = ++_searchVersion;
    if (!mounted) return;
    setState(() {
      _loadingFoods = true;
    });
    final list = await ref.read(foodRepositoryProvider).search(q);
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
    );
  }

  Future<void> _save() async {
    final food = _selected;
    if (food == null || _grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择食材并选择克数')));
      return;
    }
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day != today) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只能给今天记餐')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(mealRepositoryProvider).add(
            date: day,
            mealType: _mealType,
            food: food,
            grams: _grams,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已记入今日')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdown<MealType>(
                  label: '餐次',
                  value: _mealType,
                  items: MealType.values,
                  itemLabel: (e) => e.label,
                  onChanged: (v) => setState(() => _mealType = v),
                ),
                const SizedBox(height: 12),
                if (_selected != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_selected!.name),
                    subtitle: Text(
                      '${_selected!.kcalPer100.round()} kcal / 100g',
                    ),
                    trailing: TextButton(
                      onPressed: () => setState(() => _selected = null),
                      child: const Text('更换'),
                    ),
                  ),
                  AppDropdown<double>(
                    label: '克数',
                    value: FormOptions.snapDouble(
                      FormOptions.mealGrams,
                      _grams,
                    ),
                    items: FormOptions.mealGrams,
                    suffixText: 'g',
                    itemLabel: formatKg,
                    onChanged: (v) => setState(() => _grams = v),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '约 ${preview.calories.round()} kcal · '
                      '蛋白 ${preview.proteinG.toStringAsFixed(1)}g · '
                      '碳水 ${preview.carbG.toStringAsFixed(1)}g · '
                      '脂肪 ${preview.fatG.toStringAsFixed(1)}g',
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '保存中…' : '保存'),
                  ),
                ] else ...[
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '输入食材名称搜索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
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
                  : _results.isEmpty
                      ? const Center(child: Text('没有找到食材'))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final f = _results[i];
                            return ListTile(
                              title: Text(f.name),
                              subtitle: Text(
                                '${f.category} · ${f.kcalPer100.round()} kcal/100g',
                              ),
                              onTap: () => setState(() => _selected = f),
                            );
                          },
                        ),
            ),
        ],
      ),
    );
  }
}
