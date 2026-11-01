import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/energy_units.dart';
import '../../domain/models.dart';
import '../../domain/temporary_food_draft.dart';
import '../meals/daily_meals_page.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../widgets/food_name_link.dart';
import '../widgets/search_field_focus.dart';

/// Create or edit a user-defined food (per 100g macros).
class CustomFoodEditPage extends ConsumerStatefulWidget {
  const CustomFoodEditPage({
    super.key,
    this.foodId,
    this.openDetailOnCreate = false,
    this.returnFoodIdOnCreate = false,
    this.initialMealType,
    this.openDayMealsAfterAdd = true,
    this.fromMeal = false,
  });

  final int? foodId;

  /// When true (e.g. opened from 记一笔), open food detail after create so the
  /// user can log it there; pops `true` if they added a meal, else `false`/
  /// null — never auto-selects the grams sheet on 记一笔.
  final bool openDetailOnCreate;

  /// Returns the newly created food ID to a caller that will use it elsewhere.
  final bool returnFoodIdOnCreate;

  /// Forwarded to food detail so "add to breakfast/…" matches 记一笔.
  final MealType? initialMealType;

  /// Forwarded to food detail: after logging, open 饮食记录 (unless false).
  final bool openDayMealsAfterAdd;

  /// True when reached from one meal's add button: only then can the user
  /// log a temporary food / calories straight into [initialMealType].
  final bool fromMeal;

  @override
  ConsumerState<CustomFoodEditPage> createState() => _CustomFoodEditPageState();
}

enum _FoodMode { normal, temporaryFood, temporaryCalories }

class _CustomFoodEditPageState extends ConsumerState<CustomFoodEditPage> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _kcal = TextEditingController();
  final _kj = TextEditingController();
  bool _updatingEnergy = false;
  final _protein = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();
  final _alcohol = TextEditingController();
  final _fiber = TextEditingController();
  final _sodium = TextEditingController();
  final _sugar = TextEditingController();
  final _saturatedFat = TextEditingController();
  final _calcium = TextEditingController();
  final _weight = TextEditingController();
  _FoodMode _mode = _FoodMode.normal;
  bool get _temporary => _mode != _FoodMode.normal;
  bool get _caloriesOnly => _mode == _FoodMode.temporaryCalories;
  final Map<_FoodMode, List<String>> _drafts = {};
  final Map<_FoodMode, Map<TextEditingController, (String, double)>>
  _draftPrecision = {};

  bool _optionalExpanded = false;

  final Map<TextEditingController, (String, double)> _precise = {};

  List<TextEditingController> get _nutrients => [
    _kcal,
    _protein,
    _carb,
    _fat,
    _alcohol,
    _fiber,
    _sodium,
    _sugar,
    _saturatedFat,
    _calcium,
  ];

  double? get _validWeight {
    final v = double.tryParse(_weight.text.trim());
    return v != null && v.isFinite && v > 0 ? v : null;
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  List<TextEditingController> get _draftFields => [..._nutrients, _kj];

  String _modeLabel(_FoodMode mode) => switch (mode) {
    _FoodMode.normal => context.l10n.normalFoodMode,
    _FoodMode.temporaryFood => context.l10n.temporaryFood,
    _FoodMode.temporaryCalories => context.l10n.temporaryCaloriesMode,
  };

  void _cycleMode() {
    if (_loading || !_canUseTemporaryModes) return;
    _drafts[_mode] = _draftFields.map((c) => c.text).toList();
    _draftPrecision[_mode] = Map.of(_precise);
    final next = _FoodMode.values[(_mode.index + 1) % _FoodMode.values.length];
    final restored = _drafts[next];
    for (var i = 0; i < _draftFields.length; i++) {
      _draftFields[i].text = restored?[i] ?? '';
    }
    _precise
      ..clear()
      ..addAll(_draftPrecision[next] ?? {});
    setState(() => _mode = next);
  }

  MacroIntake get _nutrition => MacroIntake(
    calories: _parse(_kcal),
    proteinG: _parse(_protein),
    carbG: _parse(_carb),
    fatG: _parse(_fat),
    alcoholG: _parse(_alcohol),
    fiberG: _parse(_fiber),
    sodiumMg: _parse(_sodium),
    sugarG: _parse(_sugar),
    saturatedFatG: _parse(_saturatedFat),
    calciumMg: _parse(_calcium),
  );

  Future<void> _saveTemporary() async {
    if (_loading || !_canUseTemporaryModes) return;
    final l10n = context.l10n;
    if (!_caloriesOnly && _validWeight == null) {
      _message(l10n.invalidFoodWeight);
      return;
    }
    final fields = _caloriesOnly ? [_kcal] : _nutrients;
    if (_name.text.trim().isEmpty ||
        _kcal.text.trim().isEmpty ||
        fields.any(
          (c) =>
              c.text.trim().isNotEmpty &&
              (double.tryParse(c.text.trim()) == null ||
                  !_parse(c).isFinite ||
                  _parse(c) < 0),
        )) {
      _message(l10n.invalidFoodNutrition);
      return;
    }
    final draft = TemporaryFoodDraft(
      name: _name.text.trim(),
      input: _caloriesOnly
          ? TemporaryFoodInput.caloriesOnly
          : TemporaryFoodInput.per100g,
      nutrition: _caloriesOnly
          ? MacroIntake(calories: _parse(_kcal))
          : _nutrition,
    );
    final day = ref.read(selectedDayProvider);
    setState(() => _loading = true);
    try {
      await ref
          .read(mealRepositoryProvider)
          .addTemporary(
            date: day,
            mealType: widget.initialMealType!,
            draft: draft,
            grams: _caloriesOnly ? 0 : _validWeight!,
          );
      if (!mounted) return;
      _message(l10n.dietRecordAdded);
      if (widget.openDetailOnCreate) {
        context.pop(true);
      } else if (widget.openDayMealsAfterAdd) {
        context.pushReplacement(dailyMealsPath(day));
      } else {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) _message(l10n.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _loading = false;
  bool _ready = false;

  bool get _isEdit => widget.foodId != null;

  bool get _canUseTemporaryModes =>
      !_isEdit &&
      widget.fromMeal &&
      widget.openDetailOnCreate &&
      widget.initialMealType != null &&
      !widget.returnFoodIdOnCreate;

  @override
  void initState() {
    super.initState();
    suppressInitialTextFocus(_nameFocus);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.foodId == null) {
      setState(() => _ready = true);
      return;
    }
    final food = await ref.read(foodRepositoryProvider).byId(widget.foodId!);
    if (!mounted) return;
    if (food == null || !food.isCustom || food.isTemporary) {
      setState(() => _ready = true);
      return;
    }
    _name.text = food.name;
    _kcal.text = _fmtOrEmpty(food.kcalPer100);
    _kj.text = _fmtOrEmpty(food.kcalPer100 * kKcalToKj);
    _protein.text = _fmtOrEmpty(food.proteinPer100);
    _carb.text = _fmtOrEmpty(food.carbPer100);
    _fat.text = _fmtOrEmpty(food.fatPer100);
    _alcohol.text = _fmtOrEmpty(food.alcoholPer100);
    _fiber.text = _fmtOrEmpty(food.fiberPer100);
    _sodium.text = _fmtOrEmpty(food.sodiumMgPer100);
    _sugar.text = _fmtOrEmpty(food.sugarPer100);
    _saturatedFat.text = _fmtOrEmpty(food.saturatedFatPer100);
    _calcium.text = _fmtOrEmpty(food.calciumMgPer100);
    setState(() => _ready = true);
  }

  String _fmt(double v) => !v.isFinite
      ? '—'
      : (v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1));

  /// 0 显示为空白，与新建时待输入状态一致。
  String _fmtOrEmpty(double v) => v == 0 ? '' : _fmt(v);

  double _parse(TextEditingController c) {
    final cached = _precise[c];
    if (cached != null && cached.$1 == c.text) return cached.$2;
    return double.tryParse(c.text.trim()) ?? 0;
  }

  void _onKcalChanged(String text) {
    if (_updatingEnergy) return;
    final v = double.tryParse(text.trim());
    _updatingEnergy = true;
    _kj.text = v == null ? '' : _fmt(v * kKcalToKj);
    _updatingEnergy = false;
  }

  void _onKjChanged(String text) {
    if (_updatingEnergy) return;
    final v = double.tryParse(text.trim());
    _updatingEnergy = true;
    _kcal.text = v == null ? '' : _fmt(v / kKcalToKj);
    if (v != null) _precise[_kcal] = (_kcal.text, v / kKcalToKj);
    _updatingEnergy = false;
  }

  @override
  void dispose() {
    _weight.dispose();
    _name.dispose();
    _nameFocus.dispose();
    _kcal.dispose();
    _kj.dispose();
    _protein.dispose();
    _carb.dispose();
    _fat.dispose();
    _alcohol.dispose();
    _fiber.dispose();
    _sodium.dispose();
    _sugar.dispose();
    _saturatedFat.dispose();
    _calcium.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_loading) return;
    setState(() => _loading = true);
    final l10n = context.l10n;
    try {
      final repo = ref.read(foodRepositoryProvider);
      if (_isEdit) {
        await repo.updateCustom(
          id: widget.foodId!,
          name: _name.text,
          kcalPer100: _parse(_kcal),
          proteinPer100: _parse(_protein),
          carbPer100: _parse(_carb),
          fatPer100: _parse(_fat),
          alcoholPer100: _parse(_alcohol),
          fiberPer100: _parse(_fiber),
          sodiumMgPer100: _parse(_sodium),
          sugarPer100: _parse(_sugar),
          saturatedFatPer100: _parse(_saturatedFat),
          calciumMgPer100: _parse(_calcium),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.saved)));
          context.pop();
        }
      } else {
        final id = await repo.createCustom(
          name: _name.text,
          kcalPer100: _parse(_kcal),
          proteinPer100: _parse(_protein),
          carbPer100: _parse(_carb),
          fatPer100: _parse(_fat),
          alcoholPer100: _parse(_alcohol),
          fiberPer100: _parse(_fiber),
          sodiumMgPer100: _parse(_sodium),
          sugarPer100: _parse(_sugar),
          saturatedFatPer100: _parse(_saturatedFat),
          calciumMgPer100: _parse(_calcium),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.customFoodAdded)));
          if (widget.returnFoodIdOnCreate) {
            context.pop(id);
          } else if (widget.openDetailOnCreate) {
            // Root twin: /foods/$id would remount the shell from /log-meal.
            final added = await openFoodDetail<bool>(
              context,
              id,
              mealType: widget.initialMealType,
              openDayMealsAfterAdd: widget.openDayMealsAfterAdd,
            );
            if (mounted) context.pop(added == true);
          } else {
            context.pushReplacement('/foods/$id');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? l10n.editCustomFood
              : switch (_mode) {
                  _FoodMode.normal => l10n.normalFoodTitle,
                  _FoodMode.temporaryFood => l10n.recordTemporaryFood,
                  _FoodMode.temporaryCalories => l10n.recordTemporaryCalories,
                },
        ),
        actions: [
          if (_canUseTemporaryModes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                child: IconButton(
                  key: const ValueKey('temporary-food-toggle'),
                  tooltip: l10n.cycleFoodMode(
                    _modeLabel(_mode),
                    _modeLabel(_FoodMode.values[(_mode.index + 1) % 3]),
                  ),
                  onPressed: _loading ? null : _cycleMode,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  icon: InkIcon(
                    switch (_mode) {
                      _FoodMode.normal => InkGlyph.foodSaved,
                      _FoodMode.temporaryFood => InkGlyph.foodTemporary,
                      _FoodMode.temporaryCalories => InkGlyph.caloriesTemporary,
                    },
                    size: 24,
                    color: AppThemeVisuals.of(context).accent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          TextField(
            controller: _name,
            focusNode: _nameFocus,
            decoration: InputDecoration(labelText: l10n.name),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.field),
          if (_temporary) ...[
            Text(
              l10n.temporaryFoodHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.section),
            if (!_caloriesOnly) _numField(_weight, l10n.actualFoodWeight),
          ],
          Text(
            _caloriesOnly ? l10n.thisIntakeCalories : l10n.per100gNutrition,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _numField(
                  _kcal,
                  l10n.kcalField,
                  onChanged: _onKcalChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.field),
                child: InkIcon(
                  InkGlyph.swapHorizontal,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: _numField(_kj, l10n.kjField, onChanged: _onKjChanged),
              ),
            ],
          ),
          if (!_caloriesOnly) ...[
            _numField(_protein, l10n.proteinG),
            _numField(_carb, l10n.carbG),
            _numField(_fat, l10n.fatG),
            const Divider(),
            TextButton(
              key: const ValueKey('optional-nutrition-toggle'),
              onPressed: () =>
                  setState(() => _optionalExpanded = !_optionalExpanded),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.optionalNutrition)),
                  InkIcon(
                    _optionalExpanded ? InkGlyph.collapse : InkGlyph.expand,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            if (_optionalExpanded) ...[
              _numField(_saturatedFat, l10n.saturatedFatGOptional),
              _numField(_sugar, l10n.sugarGOptional),
              _numField(_fiber, l10n.fiberGOptional),
              _numField(_sodium, l10n.sodiumMgOptional),
              _numField(_calcium, l10n.calciumMgOptional),
              _numField(_alcohol, l10n.alcoholGOptional),
            ],
          ],
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: _loading ? null : (_temporary ? _saveTemporary : _save),
            child: Text(
              _loading
                  ? l10n.saving
                  : (_temporary ? l10n.addDietRecord : l10n.save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(
    TextEditingController c,
    String label, {
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.field),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) return;
          // 聚焦时：把残留的 0 清掉；若已有值则全选方便覆盖输入
          if (c.text.trim() == '0') {
            c.text = '';
            c.selection = const TextSelection.collapsed(offset: 0);
            onChanged?.call(c.text);
          } else if (c.text.isNotEmpty) {
            c.selection = TextSelection(
              baseOffset: 0,
              extentOffset: c.text.length,
            );
          }
        },
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (value) {
            _precise.remove(c);
            onChanged?.call(value);
            if (_temporary) setState(() {});
          },
        ),
      ),
    );
  }
}
