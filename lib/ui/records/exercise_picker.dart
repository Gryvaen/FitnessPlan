import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';

/// Picks one exercise from a bottom sheet grouped by [kExerciseCategoryOrder],
/// so users aren't scanning one long flat list to find a movement.
class ExercisePicker extends StatelessWidget {
  const ExercisePicker({
    super.key,
    required this.label,
    required this.displayText,
    required this.selectedId,
    required this.exercises,
    required this.onChanged,
  });

  final String label;
  final String displayText;
  final int? selectedId;
  final List<Exercise> exercises;
  final ValueChanged<Exercise> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<Exercise>(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => ExercisePickerSheet(
              exercises: exercises,
              selectedId: selectedId,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(displayText, style: theme.textTheme.bodyLarge),
            ),
            Icon(Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class ExercisePickerSheet extends StatelessWidget {
  const ExercisePickerSheet({super.key, required this.exercises, this.selectedId});

  final List<Exercise> exercises;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final byCategory = <String, List<Exercise>>{};
    for (final e in exercises) {
      byCategory.putIfAbsent(e.category, () => []).add(e);
    }
    final orderedCategories = [
      for (final c in kExerciseCategoryOrder)
        if (byCategory[c]?.isNotEmpty ?? false) c,
      for (final c in byCategory.keys)
        if (!kExerciseCategoryOrder.contains(c) && byCategory[c]!.isNotEmpty) c,
    ];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => SafeArea(
        child: ListView(
          controller: scrollController,
          children: [
            for (final category in orderedCategories) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  category.localizedExerciseCategory(l10n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              for (final exercise in byCategory[category]!)
                ListTile(
                  title: Text(exercise.name),
                  trailing: exercise.id == selectedId
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, exercise),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
