import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';

/// A writing/checklist glyph with a small swap mark, using the app's ink assets.
class NoteModeToggle extends StatelessWidget {
  const NoteModeToggle({
    super.key,
    required this.isPlan,
    required this.onPressed,
  });

  final bool isPlan;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final current = isPlan ? l10n.noteModePlan : l10n.noteModeRecord;
    final next = isPlan ? l10n.noteModeRecord : l10n.noteModePlan;
    return IconButton(
      key: const ValueKey('note-mode-toggle'),
      tooltip: '$current → $next',
      onPressed: onPressed,
      icon: SizedBox.square(
        dimension: 32,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: InkIcon(
                isPlan ? InkGlyph.factCheck : InkGlyph.edit,
                size: 25,
                color: onPressed == null
                    ? scheme.onSurfaceVariant
                    : scheme.primary,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: InkIcon(
                    InkGlyph.swapHorizontal,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
