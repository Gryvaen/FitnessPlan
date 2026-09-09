import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

/// Profile → Theme: pick one of the four presets.
class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = ref.watch(themeProvider);
    final presets = AppThemeId.presets;

    return AppChromeScaffold(
      appBar: AppBar(title: Text(l10n.theme)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          for (var i = 0; i < presets.length; i++) ...[
            _ThemeOption(
              id: presets[i],
              selected: selected == presets[i],
              onTap: () => ref.read(themeProvider.notifier).select(presets[i]),
            ),
            if (i != presets.length - 1)
              const SizedBox(height: AppSpacing.field),
          ],
          const SizedBox(height: AppSpacing.section),
          Text(l10n.themeNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final AppThemeId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    final preview = AppTheme.visualsFor(id);
    final scheme = AppTheme.schemeFor(id);

    return Semantics(
      selected: selected,
      button: true,
      label: id.label(l10n),
      child: Material(
        color: visuals.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: selected ? visuals.accent : visuals.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.section),
            child: Row(
              children: [
                _MiniPreview(scheme: scheme, visuals: preview),
                const SizedBox(width: AppSpacing.section),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(id.label(l10n), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        id.description(l10n),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? visuals.accent
                      : theme.colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny mock of the Today card in the target theme.
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.scheme, required this.visuals});

  final ColorScheme scheme;
  final AppThemeVisuals visuals;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: visuals.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: visuals.heroCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: visuals.cardBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Container(
                    width: 14,
                    height: 4,
                    decoration: BoxDecoration(
                      color: visuals.onHero.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: visuals.accent, width: 2),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final c in [
                AppColors.protein,
                AppColors.carb,
                AppColors.fat,
                AppColors.water,
              ]) ...[
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (c != AppColors.water) const SizedBox(width: 2),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

extension AppThemeIdL10n on AppThemeId {
  String label(AppLocalizations l10n) => switch (this) {
    AppThemeId.fresh => l10n.themeFresh,
    AppThemeId.aurora => l10n.themeAurora,
    AppThemeId.warm => l10n.themeWarm,
    AppThemeId.graphite => l10n.themeGraphite,
  };

  String description(AppLocalizations l10n) => switch (this) {
    AppThemeId.fresh => l10n.themeFreshDesc,
    AppThemeId.aurora => l10n.themeAuroraDesc,
    AppThemeId.warm => l10n.themeWarmDesc,
    AppThemeId.graphite => l10n.themeGraphiteDesc,
  };
}
