import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';

/// Flat disclosure row shared by strategy setup and active-plan details.
class StrategyFoldSection extends StatelessWidget {
  const StrategyFoldSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
    this.summary,
    this.leading,
  });

  final String title;
  final String? summary;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;
  final InkGlyph? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label:
              '$title, ${summary ?? ''}, '
              '${expanded ? l10n.collapseSection : l10n.expandSection}',
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.field),
              child: Row(
                children: [
                  if (leading != null) ...[
                    InkIcon(
                      leading!,
                      size: 20,
                      color: expanded
                          ? visuals.accent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.field),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: expanded ? visuals.accent : null,
                          ),
                        ),
                        if (summary != null && summary!.isNotEmpty)
                          Text(
                            summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  InkIcon(
                    expanded ? InkGlyph.collapse : InkGlyph.expand,
                    size: 20,
                    color: expanded
                        ? visuals.accent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.card),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
        ),
        Divider(height: 1, color: visuals.divider),
      ],
    );
  }
}
