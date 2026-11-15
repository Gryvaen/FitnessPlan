import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'daily_meals_page.dart';

class MealPresetDetailPage extends ConsumerStatefulWidget {
  const MealPresetDetailPage({
    super.key,
    required this.presetId,
    this.intoMealType,
  });

  final int presetId;

  /// The meal the preset was opened from; when set, every item is logged
  /// under it instead of under the item's own meal.
  final MealType? intoMealType;

  @override
  ConsumerState<MealPresetDetailPage> createState() =>
      _MealPresetDetailPageState();
}

class _MealPresetDetailPageState extends ConsumerState<MealPresetDetailPage> {
  MealPreset? _preset;
  List<MealPresetItem> _items = [];
  Map<int, FoodItem> _foods = {};
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  int _removedMissing = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(mealPresetRepositoryProvider);
      await ref.read(foodsSeedProvider.future);
      final preset = await repo.presetById(widget.presetId);
      if (preset == null) {
        if (mounted) {
          setState(() {
            _preset = null;
            _loading = false;
          });
        }
        return;
      }
      final removed = await repo.pruneMissingFoods(widget.presetId);
      final items = await repo.itemsFor(widget.presetId);
      final foods = <int, FoodItem>{};
      for (final id in {for (final item in items) item.foodId}) {
        final food = await ref.read(foodRepositoryProvider).byId(id);
        if (food != null) foods[id] = food;
      }
      if (!mounted) return;
      setState(() {
        _preset = preset;
        _items = items;
        _foods = foods;
        _removedMissing += removed;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = '$error';
          _loading = false;
        });
      }
    }
  }

  MacroIntake get _total => _totalFor(null);

  MacroIntake _intakeFor(MealPresetItem item) {
    final food = _foods[item.foodId];
    if (food == null) return const MacroIntake();
    return MacroIntake.fromGrams(
      grams: item.grams,
      kcalPer100: food.kcalPer100,
      proteinPer100: food.proteinPer100,
      carbPer100: food.carbPer100,
      fatPer100: food.fatPer100,
    );
  }

  MacroIntake _totalFor(MealType? type) {
    var sum = const MacroIntake();
    for (final item in _items) {
      if (type != null && item.mealType != type.name) continue;
      sum += _intakeFor(item);
    }
    return sum;
  }

  Future<void> _persist(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      await _load();
    } catch (error) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _rename() async {
    final preset = _preset;
    if (preset == null || _saving) return;
    final l10n = context.l10n;
    final controller = TextEditingController(text: preset.name);
    String? error;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.presetEdit),
          content: TextField(
            key: const ValueKey('preset-name-input'),
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.name, errorText: error),
            onChanged: (_) {
              if (error != null) setDialogState(() => error = null);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => error = l10n.presetNameRequired);
                  return;
                }
                final existing = await ref
                    .read(mealPresetRepositoryProvider)
                    .presetByName(value);
                if (!dialogContext.mounted) return;
                if (existing != null && existing.id != widget.presetId) {
                  setDialogState(() => error = l10n.presetNameExists);
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (!mounted || name == null || name == preset.name) return;
    await _persist(
      () => ref
          .read(mealPresetRepositoryProvider)
          .renamePreset(widget.presetId, name),
    );
  }

  Future<void> _editGrams(MealPresetItem item) async {
    if (_saving) return;
    final l10n = context.l10n;
    List<FoodServing> servings;
    try {
      servings = await ref
          .read(foodRepositoryProvider)
          .listServings(item.foodId);
    } catch (_) {
      servings = const [];
    }
    if (!mounted) return;
    final options = FormOptions.mealGrams();
    var grams = item.grams;
    var useManual = false;
    String? manualError;
    final manual = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.grams),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (servings.isNotEmpty) ...[
                Text(
                  l10n.commonPortions,
                  style: Theme.of(context).textTheme.fieldLabel,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in servings)
                      SoftChip(
                        key: ValueKey('preset-serving-${s.id}'),
                        label: '${s.label} · ${s.grams.round()}g',
                        selected: !useManual && (grams - s.grams).abs() < 0.01,
                        onTap: () => setDialogState(() {
                          grams = s.grams;
                          useManual = false;
                          manual.clear();
                          manualError = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.field),
              ],
              AppDropdown<double>(
                label: l10n.grams,
                value: grams,
                items: ({...options, grams}.toList()..sort()),
                suffixText: 'g',
                itemLabel: formatKg,
                onChanged: (value) => setDialogState(() => grams = value),
              ),
              InkWell(
                key: const ValueKey('preset-manual-toggle'),
                onTap: () => setDialogState(() {
                  useManual = !useManual;
                  if (!useManual) {
                    manual.clear();
                    manualError = null;
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(height: 1)),
                      InkIcon(
                        useManual ? InkGlyph.collapse : InkGlyph.expand,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (useManual)
                TextField(
                  key: const ValueKey('preset-manual-grams'),
                  controller: manual,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.manualGramsToggle,
                    suffixText: 'g',
                    errorText: manualError,
                  ),
                  onChanged: (_) {
                    if (manualError != null) {
                      setDialogState(() => manualError = null);
                    }
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (useManual) {
                  final value = double.tryParse(manual.text.trim());
                  if (value == null || !value.isFinite || value <= 0) {
                    setDialogState(() => manualError = l10n.invalidGramsValue);
                    return;
                  }
                  grams = value;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => manual.dispose());
    if (!mounted || confirmed != true) return;
    await _persist(
      () => ref
          .read(mealPresetRepositoryProvider)
          .updateItem(
            presetId: widget.presetId,
            itemId: item.id,
            grams: grams,
            mealType: MealType.tryParse(item.mealType) ?? MealType.lunch,
          ),
    );
  }

  Future<void> _addFood([MealType? mealType]) async {
    if (_saving) return;
    unfocusForNavigation();
    await context.push(
      mealType == null
          ? '/meal-preset/${widget.presetId}/add'
          : '/meal-preset/${widget.presetId}/add?mealType=${mealType.name}',
    );
    if (mounted) await _load();
  }

  Future<void> _moveItem(MealPresetItem item, MealType mealType) => _persist(
    () => ref
        .read(mealPresetRepositoryProvider)
        .updateItem(
          presetId: widget.presetId,
          itemId: item.id,
          grams: item.grams,
          mealType: mealType,
        ),
  );

  Future<bool> _confirmDeleteItem(MealPresetItem item) async {
    if (_saving) return false;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.confirmDeletePresetFood),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _persist(
        () => ref
            .read(mealPresetRepositoryProvider)
            .deleteItem(presetId: widget.presetId, itemId: item.id),
      );
    }
    return false;
  }

  Future<bool> _confirmDeleteMeal(MealType type) async {
    if (_saving) return false;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearThisMeal),
        content: Text(l10n.confirmClearPresetMeal(type.label(l10n))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _persist(() async {
        await ref
            .read(mealPresetRepositoryProvider)
            .deleteMealType(presetId: widget.presetId, mealType: type);
      });
    }
    return false;
  }

  Future<void> _apply() async {
    if (_items.isEmpty || _saving) return;
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
      final result = await ref
          .read(mealPresetRepositoryProvider)
          .applyPreset(
            presetId: widget.presetId,
            date: day,
            intoMealType: widget.intoMealType,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.presetAppliedResult(
              result.copied,
              result.skippedDuplicate,
              result.skippedMissingFood + _removedMissing,
            ),
          ),
        ),
      );
      unfocusForNavigation();
      final router = GoRouter.of(context);
      router.go('/today');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(dailyMealsPath(day));
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.applyPresetFailed('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _deleteBackground(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    color: Theme.of(context).colorScheme.error,
    child: const InkIcon(InkGlyph.delete, color: Colors.white),
  );

  Widget _itemTile(BuildContext context, MealPresetItem item) {
    final theme = Theme.of(context);
    final name = _foods[item.foodId]?.displayName(context) ?? item.foodName;
    final intake = _intakeFor(item);
    final tile = ListTile(
      key: ValueKey('preset-grams-${item.id}'),
      contentPadding: EdgeInsets.zero,
      title: FoodNameLink(
        name: name,
        foodId: item.foodId,
        carbG: intake.carbG,
        proteinG: intake.proteinG,
        fatG: intake.fatG,
        style: theme.textTheme.bodyLarge,
        onTap: () async {
          await openFoodDetail(context, item.foodId);
          if (mounted) await _load();
        },
      ),
      subtitle: Text(
        '${item.grams.toStringAsFixed(0)} g · '
        'P ${intake.proteinG.toStringAsFixed(0)} · '
        'C ${intake.carbG.toStringAsFixed(0)} · '
        'F ${intake.fatG.toStringAsFixed(0)}',
        style: theme.textTheme.meta,
      ),
      trailing: Text(
        '${intake.calories.round()} kcal',
        style: theme.textTheme.titleSmall,
      ),
      onTap: () => _editGrams(item),
    );
    final dismissible = Dismissible(
      key: ValueKey('preset-item-${item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(context),
      confirmDismiss: (_) => _confirmDeleteItem(item),
      // Own Material so the drop-target highlight doesn't hide the ink.
      child: Material(color: Colors.transparent, child: tile),
    );
    // Long-press to drag this food into a different meal section.
    return LongPressDraggable<MealPresetItem>(
      data: item,
      axis: Axis.vertical,
      feedback: Material(
        elevation: 4,
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              name,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: dismissible),
      child: dismissible,
    );
  }

  Widget _mealSection(BuildContext context, MealType type) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entries = _items.where((item) => item.mealType == type.name).toList();
    final total = _totalFor(type);
    final header = Row(
      children: [
        Expanded(
          child: Text(
            type.label(l10n),
            key: ValueKey('preset-meal-title-${type.name}'),
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (entries.isNotEmpty) ...[
          Text(
            '${total.calories.round()} kcal',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            key: ValueKey('preset-meal-add-${type.name}'),
            tooltip: l10n.addMealNamed(type.label(l10n)),
            visualDensity: VisualDensity.compact,
            onPressed: _saving ? null : () => _addFood(type),
            icon: const InkIcon(InkGlyph.add, size: 18),
          ),
        ],
      ],
    );
    final Widget block;
    if (entries.isEmpty) {
      block = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('preset-meal-add-${type.name}'),
              onPressed: _saving ? null : () => _addFood(type),
              icon: const InkIcon(InkGlyph.add, size: 18),
              label: Text(l10n.addMealNamed(type.label(l10n))),
            ),
          ),
        ],
      );
    } else {
      // Swipe left on the meal block to clear it — the header and the foods
      // under it leave together. Individual foods keep their own swipe.
      block = Dismissible(
        key: ValueKey('preset-meal-${type.name}'),
        direction: DismissDirection.endToStart,
        background: _deleteBackground(context),
        confirmDismiss: (_) => _confirmDeleteMeal(type),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: AppSpacing.compact),
            _PresetMacroRow(
              key: ValueKey('preset-meal-macros-${type.name}'),
              total: total,
            ),
            const SizedBox(height: AppSpacing.compact),
            for (final item in entries) _itemTile(context, item),
          ],
        ),
      );
    }
    // Long-press-drag a food from another meal section drops it here,
    // moving it to this meal type.
    return DragTarget<MealPresetItem>(
      onWillAcceptWithDetails: (details) =>
          !_saving && details.data.mealType != type.name,
      onAcceptWithDetails: (details) => _moveItem(details.data, type),
      builder: (context, candidateData, rejectedData) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.only(bottom: AppSpacing.section),
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: block,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A food edited from this page (or elsewhere) changes the totals.
    ref.listen(foodCatalogChangesProvider, (previous, next) {
      if (previous == null || !previous.hasValue || !next.hasValue) return;
      if (previous.value == next.value) return;
      _load();
    });
    final l10n = context.l10n;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.loadFailed(_loadError!)),
              TextButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    final preset = _preset;
    if (preset == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.presetNotFound)),
      );
    }
    final theme = Theme.of(context);
    final total = _total;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          key: const ValueKey('preset-name'),
          onTap: _rename,
          child: Text(preset.name),
        ),
        actions: [
          IconButton(
            tooltip: l10n.presetAddFood,
            onPressed: _saving ? null : _addFood,
            icon: const InkIcon(InkGlyph.add),
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
          Text(l10n.nutritionResult, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.compact),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${total.calories.round()}',
                style: theme.textTheme.statValue,
              ),
              const SizedBox(width: 6),
              Text('kcal', style: theme.textTheme.statUnit),
            ],
          ),
          const SizedBox(height: AppSpacing.field),
          _PresetMacroRow(total: total),
          const SizedBox(height: AppSpacing.section),
          if (_items.isEmpty) SportEmptyState(title: l10n.presetEmpty),
          for (final type in MealType.values) _mealSection(context, type),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          8,
          AppSpacing.formPage,
          12,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _items.isEmpty || _saving ? null : _apply,
            child: Text(switch (widget.intoMealType) {
              final meal? => l10n.presetAddToMeal(meal.label(l10n)),
              null => l10n.presetAddToday,
            }),
          ),
        ),
      ),
    );
  }
}

class _PresetMacroRow extends StatelessWidget {
  const _PresetMacroRow({super.key, required this.total});
  final MacroIntake total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget nutrient(String label, double grams, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            '${grams.toStringAsFixed(1)} g',
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
    return Row(
      children: [
        nutrient(l10n.protein, total.proteinG, AppColors.protein),
        nutrient(l10n.carbs, total.carbG, AppColors.carb),
        nutrient(l10n.fat, total.fatG, AppColors.fat),
      ],
    );
  }
}
