import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';

/// A titled group of muted explanatory notes, folded by default so sheets
/// stay as short as their action rows. Tap the title to read them.
class FoldedNotes extends StatefulWidget {
  const FoldedNotes({super.key, required this.title, required this.notes});

  final String title;
  final List<String> notes;

  @override
  State<FoldedNotes> createState() => _FoldedNotesState();
}

class _FoldedNotesState extends State<FoldedNotes> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.colorScheme.onSurfaceVariant;
    final noteStyle = theme.textTheme.bodySmall?.copyWith(color: muted);
    return Semantics(
      expanded: _expanded,
      hint: _expanded ? l10n.collapseSection : l10n.expandSection,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    InkIcon(
                      _expanded ? InkGlyph.collapse : InkGlyph.expand,
                      size: 18,
                      color: muted,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              for (final note in widget.notes) ...[
                const SizedBox(height: AppSpacing.compact),
                Text(note, style: noteStyle),
              ],
          ],
        ),
      ),
    );
  }
}
