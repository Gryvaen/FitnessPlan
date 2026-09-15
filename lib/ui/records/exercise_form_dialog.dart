import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../widgets/form_options.dart';
import '../widgets/search_field_focus.dart';

class ExerciseFormData {
  const ExerciseFormData({
    required this.name,
    required this.unit,
    required this.category,
  });

  final String name;
  final ExerciseUnit unit;
  final String category;
}

Future<ExerciseFormData?> showExerciseFormDialog({
  required BuildContext context,
  Exercise? exercise,
  String defaultCategory = 'chest',
}) {
  return showDialog<ExerciseFormData>(
    context: context,
    builder: (ctx) => _ExerciseFormDialog(
      exercise: exercise,
      defaultCategory: defaultCategory,
    ),
  );
}

class _ExerciseFormDialog extends StatefulWidget {
  const _ExerciseFormDialog({this.exercise, this.defaultCategory = 'chest'});

  final Exercise? exercise;
  final String defaultCategory;

  @override
  State<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<_ExerciseFormDialog> {
  late final TextEditingController _nameCtrl;
  final _nameFocus = FocusNode();
  late ExerciseUnit _unit;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _nameCtrl = TextEditingController(text: exercise?.name ?? '');
    _unit = exercise != null
        ? ExerciseUnit.fromStorage(exercise.unit)
        : ExerciseUnit.reps;
    _selectedCategory =
        exercise != null && kExerciseCategoryOrder.contains(exercise.category)
        ? exercise.category
        : widget.defaultCategory;
    suppressInitialTextFocus(_nameFocus);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.exercise != null;
    return AlertDialog(
      title: Text(isEdit ? l10n.edit : l10n.addExercise),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              decoration: InputDecoration(labelText: l10n.exerciseName),
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: l10n.categories,
              value: _selectedCategory,
              items: kExerciseCategoryOrder,
              itemLabel: (c) => c.localizedExerciseCategory(l10n),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 12),
            AppDropdown<ExerciseUnit>(
              label: _selectedCategory == 'cardio'
                  ? l10n.repsOrMinutes
                  : l10n.repsOrSeconds,
              value: _unit,
              items: ExerciseUnit.values,
              itemLabel: (u) =>
                  u.unitChoiceLabel(l10n, category: _selectedCategory),
              onChanged: (v) => setState(() => _unit = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ExerciseFormData(
              name: _nameCtrl.text,
              unit: _unit,
              category: _selectedCategory,
            ),
          ),
          child: Text(isEdit ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
