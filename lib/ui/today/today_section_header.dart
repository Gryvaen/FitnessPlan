import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

/// Header row for a collapsible Today block.
///
/// The title + chevron toggle the block; the plain "+" and any extra
/// actions are separate hit targets and never toggle.
class TodaySectionHeader extends StatelessWidget {
  const TodaySectionHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.expandLabel,
    required this.collapseLabel,
    this.summary,
    this.addLabel,
    this.onAdd,
    this.trailing = const [],
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final String expandLabel;
  final String collapseLabel;

  /// Short state text shown when collapsed (e.g. "2/5", "3 · 860 kcal").
  final String? summary;
  final String? addLabel;
  final VoidCallback? onAdd;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            expanded: expanded,
            label: expanded ? collapseLabel : expandLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            Text(title, style: theme.textTheme.titleMedium),
                            if (summary != null && summary!.isNotEmpty)
                              Text(summary!, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: kThemeAnimationDuration,
                        child: Icon(
                          Icons.expand_more,
                          size: 22,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (addLabel != null)
          PlainIconAction(
            icon: Icons.add,
            label: addLabel!,
            onPressed: onAdd,
            color: AppThemeVisuals.of(context).accent,
          ),
        ...trailing,
      ],
    );
  }
}
