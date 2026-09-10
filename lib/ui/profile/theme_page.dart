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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          for (final id in presets)
            _ThemeOption(
              id: id,
              selected: selected == id,
              onTap: () => ref.read(themeProvider.notifier).select(id),
            ),
          const SizedBox(height: AppSpacing.section),
          Text(
            l10n.themeNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
    final v = AppThemeVisuals.of(context);
    final swatch = AppTheme.visualsFor(id).accent;

    return Semantics(
      selected: selected,
      button: true,
      label: id.label(l10n),
      child: Material(
        color: Colors.transparent,
        shape: Border(bottom: BorderSide(color: v.divider)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.card),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(id.label(l10n), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        id.description(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? v.accent
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
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
