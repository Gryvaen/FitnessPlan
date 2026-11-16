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
                          style: theme.textTheme.subsectionTitle?.copyWith(
                            color: expanded ? visuals.accent : null,
                          ),
                        ),
                        if (summary != null && summary!.isNotEmpty)
                          Text(
                            summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.meta?.copyWith(
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

/// Read-only label / value / unit row inside a configure fold section.
class StrategyReadOnlyMetric extends StatelessWidget {
  const StrategyReadOnlyMetric({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      readOnly: true,
      label: label,
      value: '$value $unit',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.rowTitle,
                ),
              ),
              const SizedBox(width: AppSpacing.field),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.rowValue?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(unit, style: theme.textTheme.meta),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A radio-style row for the "effective date" choice (今天 / 明天).
class StrategyDateOption extends StatelessWidget {
  const StrategyDateOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            InkIcon(
              selected ? InkGlyph.radioChecked : InkGlyph.radioEmpty,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.rowTitle)),
          ],
        ),
      ),
    );
  }
}
