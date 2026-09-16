import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/energy_units.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/food_name_link.dart';
import '../widgets/search_field_focus.dart';

/// Create or edit a user-defined food (per 100g macros).
class CustomFoodEditPage extends ConsumerStatefulWidget {
  const CustomFoodEditPage({
    super.key,
    this.foodId,
    this.openDetailOnCreate = false,
    this.initialMealType,
    this.openDayMealsAfterAdd = true,
  });

  final int? foodId;

  /// When true (e.g. opened from 记一笔), open food detail after create so the
  /// user can log it there; pops `true` if they added a meal, else `false`/
  /// null — never auto-selects the grams sheet on 记一笔.
  final bool openDetailOnCreate;

  /// Forwarded to food detail so "add to breakfast/…" matches 记一笔.
  final MealType? initialMealType;

  /// Forwarded to food detail: after logging, open 饮食记录 (unless false).
  final bool openDayMealsAfterAdd;

  @override
  ConsumerState<CustomFoodEditPage> createState() => _CustomFoodEditPageState();
}

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
  bool _loading = false;
  bool _ready = false;

  bool get _isEdit => widget.foodId != null;

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
    if (food == null || !food.isCustom) {
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

  String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  /// 0 显示为空白，与新建时待输入状态一致。
  String _fmtOrEmpty(double v) => v == 0 ? '' : _fmt(v);

  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

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
    _updatingEnergy = false;
  }

  @override
  void dispose() {
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
          if (widget.openDetailOnCreate) {
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
        title: Text(_isEdit ? l10n.editCustomFood : l10n.addCustomFood),
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
          Text(
            l10n.per100gNutrition,
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
                child: Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: _numField(
                  _kj,
                  l10n.kjField,
                  onChanged: _onKjChanged,
                ),
              ),
            ],
          ),
          _numField(_protein, l10n.proteinG),
          _numField(_carb, l10n.carbG),
          _numField(_fat, l10n.fatG),
          _numField(_saturatedFat, l10n.saturatedFatGOptional),
          _numField(_sugar, l10n.sugarGOptional),
          _numField(_fiber, l10n.fiberGOptional),
          _numField(_sodium, l10n.sodiumMgOptional),
          _numField(_calcium, l10n.calciumMgOptional),
          _numField(_alcohol, l10n.alcoholGOptional),
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? l10n.saving : l10n.save),
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
          onChanged: onChanged,
        ),
      ),
    );
  }
}
