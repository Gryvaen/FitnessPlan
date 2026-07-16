import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

/// Create or edit a user-defined food (per 100g macros).
class CustomFoodEditPage extends ConsumerStatefulWidget {
  const CustomFoodEditPage({super.key, this.foodId});

  final int? foodId;

  @override
  ConsumerState<CustomFoodEditPage> createState() => _CustomFoodEditPageState();
}

class _CustomFoodEditPageState extends ConsumerState<CustomFoodEditPage> {
  final _name = TextEditingController();
  final _kcal = TextEditingController(text: '0');
  final _protein = TextEditingController(text: '0');
  final _carb = TextEditingController(text: '0');
  final _fat = TextEditingController(text: '0');
  final _alcohol = TextEditingController(text: '0');
  bool _loading = false;
  bool _ready = false;

  bool get _isEdit => widget.foodId != null;

  @override
  void initState() {
    super.initState();
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
    _kcal.text = _fmt(food.kcalPer100);
    _protein.text = _fmt(food.proteinPer100);
    _carb.text = _fmt(food.carbPer100);
    _fat.text = _fmt(food.fatPer100);
    _alcohol.text = _fmt(food.alcoholPer100);
    setState(() => _ready = true);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carb.dispose();
    _fat.dispose();
    _alcohol.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
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
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保存')),
          );
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
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已添加自定义食材')),
          );
          context.pushReplacement('/foods/$id');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑自定义食材' : '添加自定义食材')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '名称'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.field),
          Text('每 100 克营养', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _numField(_kcal, '热量 (kcal)'),
          _numField(_protein, '蛋白质 (g)'),
          _numField(_carb, '碳水 (g)'),
          _numField(_fat, '脂肪 (g)'),
          _numField(_alcohol, '酒精 (g，可选)'),
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? '保存中…' : '保存'),
          ),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.field),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            // 聚焦时：把默认的 0 清掉；若已有值则全选方便覆盖输入
            if (c.text.trim() == '0') {
              c.text = '';
              c.selection = const TextSelection.collapsed(offset: 0);
            } else if (c.text.isNotEmpty) {
              c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
            }
          } else {
            // 失焦时：若没输入则显示 0
            if (c.text.trim().isEmpty) {
              c.text = '0';
              c.selection = TextSelection.collapsed(offset: c.text.length);
            }
          }
        },
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
      ),
    );
  }
}
