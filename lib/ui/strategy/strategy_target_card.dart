import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

/// Protein / carb / fat share of energy as one segmented bar (4 / 4 / 9
/// kcal per gram). Renders an empty track when there is no energy.
class MacroSplitBar extends StatelessWidget {
  const MacroSplitBar({
    super.key,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.height = 8,
  });

  final double proteinG;
  final double carbG;
  final double fatG;
  final double height;

  /// Energy shares in protein, carb, fat order; all zero when empty.
  static List<double> shares({
    required double proteinG,
    required double carbG,
    required double fatG,
  }) {
    double kcal(double g, int perG) => g.isFinite && g > 0 ? g * perG : 0;
    final parts = [kcal(proteinG, 4), kcal(carbG, 4), kcal(fatG, 9)];
    final total = parts.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const [0, 0, 0];
    return [for (final p in parts) p / total];
  }

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    final split = shares(proteinG: proteinG, carbG: carbG, fatG: fatG);
    const colors = [AppColors.protein, AppColors.carb, AppColors.fat];
    final segments = [
      for (var i = 0; i < 3; i++)
        if (split[i] > 0) (flex: (split[i] * 1000).round(), color: colors[i]),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: segments.isEmpty
            ? ColoredBox(color: v.track)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: segments[i].flex < 1 ? 1 : segments[i].flex,
                      child: ColoredBox(color: segments[i].color),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Open summary block at the top of the strategy screens (no card chrome,
/// like Today's header): title + status, big calories, the macro split and
/// a muted footnote, closed by a hairline divider.
class StrategyTargetCard extends StatelessWidget {
  const StrategyTargetCard({
    super.key,
    required this.title,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.status,
    this.kcalCaption,
    this.footnote,
    this.footnoteKey,
  });

  final String title;
  final String? status;
  final double kcal;
  final String? kcalCaption;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String? footnote;

  /// Key on the footnote [Text], for tests that read its content.
  final Key? footnoteKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final v = AppThemeVisuals.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.meta?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.compact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.subsectionTitle,
                ),
              ),
              if (status != null) ...[
                const SizedBox(width: AppSpacing.compact),
                Text(
                  status!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: v.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                kcal.isFinite ? '${kcal.round()}' : '–',
                style: theme.textTheme.statValue?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text('kcal', style: muted),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: Text(
                  kcalCaption ?? '',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: v.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.field),
          MacroSplitBar(proteinG: proteinG, carbG: carbG, fatG: fatG),
          const SizedBox(height: AppSpacing.compact),
          Row(
            children: [
              _MacroLegend(
                color: AppColors.protein,
                label: l10n.protein,
                grams: proteinG,
              ),
              _MacroLegend(
                color: AppColors.carb,
                label: l10n.carbs,
                grams: carbG,
              ),
              _MacroLegend(color: AppColors.fat, label: l10n.fat, grams: fatG),
            ],
          ),
          if (footnote != null && footnote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.field),
            Text(footnote!, key: footnoteKey, style: muted),
          ],
          const SizedBox(height: AppSpacing.card),
          Divider(height: 1, color: v.divider),
        ],
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  const _MacroLegend({
    required this.color,
    required this.label,
    required this.grams,
  });

  final Color color;
  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: grams.isFinite ? '${grams.round()}g' : '–',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.statLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading for the flat strategy screens.
class StrategySectionHeader extends StatelessWidget {
  const StrategySectionHeader({super.key, required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.section,
        bottom: AppSpacing.compact,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.sectionTitle),
          if (hint != null && hint!.isNotEmpty)
            Text(
              hint!,
              style: theme.textTheme.meta?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Label ……… value unit" read-only line used under section headers.
class StrategyFactRow extends StatelessWidget {
  const StrategyFactRow({
    super.key,
    required this.label,
    required this.value,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = AppThemeVisuals.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: v.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.rowTitle?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.field),
          // Value takes at most half the row but hugs the right edge.
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (unit != null)
                      TextSpan(text: ' $unit', style: theme.textTheme.meta),
                  ],
                ),
                textAlign: TextAlign.end,
                style: theme.textTheme.rowValue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat action row: icon, label, optional chevron. [destructive] paints the
/// label and icon in the error colour.
class StrategyActionRow extends StatelessWidget {
  const StrategyActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  final InkGlyph icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = AppThemeVisuals.of(context);
    final scheme = theme.colorScheme;
    final enabled = onTap != null;
    final color = !enabled
        ? theme.disabledColor
        : destructive
        ? scheme.error
        : v.accent;
    return Material(
      color: Colors.transparent,
      shape: Border(bottom: BorderSide(color: v.divider)),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              InkIcon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.field),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.rowTitle?.copyWith(
                    color: destructive && enabled ? scheme.error : null,
                  ),
                ),
              ),
              if (showChevron)
                InkIcon(
                  InkGlyph.chevronRight,
                  size: 18,
                  color: enabled
                      ? scheme.onSurfaceVariant
                      : theme.disabledColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable strategy row on a picker page (减脂 / 维持 pickers):
/// icon tile, name with a 当前 / 推荐 chip, two-line description, chevron.
class StrategyOptionRow extends StatelessWidget {
  const StrategyOptionRow({
    super.key,
    this.optionKey,
    required this.glyph,
    required this.label,
    required this.description,
    required this.current,
    required this.isDefault,
    required this.enabled,
    required this.onTap,
  });

  /// Key on the tappable area (tests tap it).
  final Key? optionKey;
  final InkGlyph glyph;
  final String label;
  final String description;
  final bool current;
  final bool isDefault;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    final scheme = theme.colorScheme;
    final muted = enabled ? scheme.onSurfaceVariant : theme.disabledColor;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: current,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: Border(bottom: BorderSide(color: visuals.divider)),
        child: InkWell(
          key: optionKey,
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.card),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current
                          ? visuals.accentSoft
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: InkIcon(
                      glyph,
                      size: 22,
                      color: current ? visuals.accent : muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.field),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.rowTitle?.copyWith(
                                color: !enabled
                                    ? theme.disabledColor
                                    : current
                                    ? visuals.accent
                                    : null,
                              ),
                            ),
                            if (current)
                              SoftChip(
                                label: l10n.currentWord,
                                color: visuals.accentSoft,
                                foreground: visuals.accent,
                              )
                            else if (isDefault)
                              SoftChip(label: l10n.defaultWord),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.meta?.copyWith(
                            color: muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.compact),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: InkIcon(
                      InkGlyph.chevronRight,
                      size: 18,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The configure pages' pinned bottom bar with the one apply button.
class StrategyApplyBar extends StatelessWidget {
  const StrategyApplyBar({super.key, required this.label, this.onPressed});

  final String label;

  /// Null disables the button (already applied, invalid, saving).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: AppThemeVisuals.of(context).divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.field,
          AppSpacing.formPage,
          AppSpacing.field,
        ),
        child: FilledButton(
          key: const ValueKey('strategyApplyButton'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}
