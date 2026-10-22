import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';

enum _NameConflictChoice { cancel, changeName, overwrite }

/// Prompts for a preset name, then creates or overwrites a meal preset.
Future<void> saveMealPresetFromEntries({
  required BuildContext context,
  required WidgetRef ref,
  required String initialName,
  required List<MealEntry> entries,
}) async {
  final l10n = context.l10n;
  if (entries.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.noLogsToSave)));
    return;
  }

  var proposedName = initialName;
  var replaceExisting = false;
  final repo = ref.read(mealPresetRepositoryProvider);

  try {
    while (true) {
      final named = await _askPresetName(
        context: context,
        initialName: proposedName,
      );
      if (!context.mounted) return;
      if (named == null) return;
      proposedName = named;

      final existing = await repo.presetByName(proposedName);
      if (!context.mounted) return;
      if (existing == null) {
        replaceExisting = false;
        break;
      }

      final choice = await _askNameConflict(
        context: context,
        name: proposedName.trim(),
      );
      if (!context.mounted) return;
      switch (choice) {
        case _NameConflictChoice.cancel:
        case null:
          return;
        case _NameConflictChoice.changeName:
          continue;
        case _NameConflictChoice.overwrite:
          replaceExisting = true;
      }
      break;
    }

    await repo.createFromEntries(
      name: proposedName,
      entries: entries,
      replaceExisting: replaceExisting,
    );
    if (!context.mounted) return;
    ref.invalidate(mealPresetsProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.presetSaved)));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}

Future<String?> _askPresetName({
  required BuildContext context,
  required String initialName,
}) => showDialog<String>(
  context: context,
  builder: (_) => _PresetNameDialog(initialName: initialName),
);

class _PresetNameDialog extends StatefulWidget {
  const _PresetNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<_PresetNameDialog> {
  late final TextEditingController _nameController;
  final _nameFocus = FocusNode(canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    // Keep restored focus from opening the keyboard during the route push.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameFocus.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocus.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        _nameFocus.canRequestFocus = true;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.saveAsPreset),
      content: TextField(
        key: const ValueKey('save-preset-name-input'),
        controller: _nameController,
        focusNode: _nameFocus,
        decoration: InputDecoration(labelText: l10n.name),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _nameController.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

Future<_NameConflictChoice?> _askNameConflict({
  required BuildContext context,
  required String name,
}) {
  final l10n = context.l10n;
  return showDialog<_NameConflictChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.presetNameExists),
      content: Text(l10n.presetNameExistsConfirm(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _NameConflictChoice.cancel),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _NameConflictChoice.changeName),
          child: Text(l10n.changeName),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _NameConflictChoice.overwrite),
          child: Text(l10n.overwrite),
        ),
      ],
    ),
  );
}
