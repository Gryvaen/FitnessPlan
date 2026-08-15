import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

/// Profile → Theme: pick a named preset.
class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = ref.watch(themeProvider);

    return AppChromeScaffold(
      appBar: AppBar(title: Text(l10n.theme)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          for (var i = 0; i < AppThemeId.styledPresets.length; i++) ...[
            SportSurfaceCard(
              child: ListTile(
                leading: _ThemeSwatch(
                  colors: AppTheme.ofId(AppThemeId.styledPresets[i])
                      .extension<AppThemeVisuals>()!
                      .hero
                      .colors,
                ),
                title: Text(AppThemeId.styledPresets[i].label(l10n)),
                trailing: selected == AppThemeId.styledPresets[i]
                    ? Icon(
                        Icons.check_circle,
                        color: AppThemeVisuals.of(context).strokeGlow,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        color: theme.colorScheme.outlineVariant,
                      ),
                onTap: () => ref
                    .read(themeProvider.notifier)
                    .select(AppThemeId.styledPresets[i]),
              ),
            ),
            if (i != AppThemeId.styledPresets.length - 1)
              const SizedBox(height: AppSpacing.field),
          ],
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.colors});

  final List<Color> colors;

  static const double _size = 46;
  static const double _dot = 18;
  static const double _step = 7;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final dots = colors.isEmpty ? const [Colors.grey] : colors;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < dots.length; i++)
            Positioned(
              left: i * _step,
              top: i * _step,
              child: Container(
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(
                  color: dots[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: outline.withValues(alpha: 0.7)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension AppThemeIdL10n on AppThemeId {
  String label(AppLocalizations l10n) => switch (this) {
        AppThemeId.day => l10n.themeDay,
        AppThemeId.night => l10n.themeNight,
        AppThemeId.forest => l10n.themeForest,
        AppThemeId.midnight => l10n.themeMidnight,
        AppThemeId.sunrise => l10n.themeSunrise,
        AppThemeId.graphite => l10n.themeGraphite,
      };
}
