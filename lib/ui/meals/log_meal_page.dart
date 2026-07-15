import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
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
  List<FoodItem> _recent = [];
  List<FoodItem> _favorites = [];
  bool _loadingFoods = true;
  bool _searching = false;
  int _searchVersion = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final memory = ref.read(formMemoryRepositoryProvider).loadMealDefaults();
    if (mounted) {
      setState(() {
        _mealType = memory.mealType;
        _grams = FormOptions.snapDouble(FormOptions.mealGrams, memory.grams);
      });
    }
    try {
      await ref.read(foodsSeedProvider.future);
      final repo = ref.read(foodRepositoryProvider);
      final recent = await repo.recentFoods();
      final favorites = await repo.favorites();
      if (widget.initialFoodId != null) {
        final food = await repo.byId(widget.initialFoodId!);
        if (mounted) setState(() => _selected = food);
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
        SnackBar(content: Text('加载食材失败：$e')),
      );
    }
  }

  Future<void> _persistMealDefaults() {
    return ref.read(formMemoryRepositoryProvider).saveMealDefaults(
          mealType: _mealType,
          grams: _grams,
        );
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
    );
  }

  Future<void> _save() async {
    final food = _selected;
    if (food == null || _grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择食材和克数')),
      );
      return;
    }
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = DateTime(today.year - 1, today.month, today.day);
    if (day.isAfter(today) || day.isBefore(earliest)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只能记录一年内到今天的餐次')),
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
        final label = day == today ? '今日' : DateFormat('M月d日').format(day);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已记入$label')),
        );
        context.pop();
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

  Widget _foodTile(FoodItem f, {String? badge}) {
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('food-${f.id}'),
      title: Text(f.name, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        [
          ?badge,
          f.category,
          '${f.kcalPer100.round()} kcal/100g',
        ].join(' · '),
        style: theme.textTheme.meta,
      ),
      onTap: () => setState(() => _selected = f),
    );
  }

  Widget _browseList() {
    final theme = Theme.of(context);
    final sections = <Widget>[];

    if (_favorites.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('收藏', style: theme.textTheme.titleSmall),
        ),
      );
      for (final f in _favorites) {
        sections.add(_foodTile(f, badge: '收藏'));
      }
    }
    if (_recent.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('最近吃过', style: theme.textTheme.titleSmall),
        ),
      );
      for (final f in _recent) {
        sections.add(_foodTile(f, badge: '最近'));
      }
    }
    if (sections.isEmpty) {
      return Center(
        child: Text('搜索食材开始记账', style: theme.textTheme.meta),
      );
    }
    return ListView(children: sections);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;
    final day = ref.watch(selectedDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayLabel = day == today
        ? '今天'
        : DateFormat('M月d日').format(day);

    return Scaffold(
      appBar: AppBar(title: Text('记一笔 · $dayLabel')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.listPage),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdown<MealType>(
                  label: '餐次',
                  value: _mealType,
                  items: MealType.values,
                  itemLabel: (e) => e.label,
                  onChanged: (v) {
                    setState(() => _mealType = v);
                    _persistMealDefaults();
                  },
                ),
                const SizedBox(height: AppSpacing.field),
                if (_selected != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_selected!.name, style: theme.textTheme.bodyLarge),
                    subtitle: Text(
                      '${_selected!.kcalPer100.round()} kcal / 100g',
                      style: theme.textTheme.meta,
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
                    onChanged: (v) {
                      setState(() => _grams = v);
                      _persistMealDefaults();
                    },
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
                    child: Text(_saving ? '保存中…' : '保存'),
                  ),
                ] else ...[
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '搜索食材',
                      prefixIcon: Icon(Icons.search),
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
                                _query.isEmpty ? '搜索食材' : '没有找到食材',
                                style: theme.textTheme.meta,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (context, i) {
                                final f = _results[i];
                                return _foodTile(f);
                              },
                            ))
                      : _browseList(),
            ),
        ],
      ),
    );
  }
}
