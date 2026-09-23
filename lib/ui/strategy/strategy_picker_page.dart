import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/diet_strategy.dart';
import '../../domain/strategy_eligibility.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'strategy_labels.dart';

/// Profile → Nutrition → Strategy: pick one of the three primary strategies.
class StrategyPickerPage extends ConsumerWidget {
  const StrategyPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    final profile = ref.watch(profileProvider);
    final active = ref.watch(activeDietPlanProvider).value;
    final blocking = StrategyEligibility.check(profile);

    return AppChromeScaffold(
      appBar: AppBar(title: Text(l10n.dietStrategy)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          Text(l10n.strategyPickerIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.card),
          if (blocking.isNotEmpty) ...[
            for (final i in blocking)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.compact),
                child: Text(
                  i.message(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Divider(height: 1, color: visuals.divider),
            const SizedBox(height: AppSpacing.card),
          ],
          for (final kind in DietStrategyKind.values)
            _StrategyOption(
              kind: kind,
              current: active?.kind == kind,
              isDefault: kind == DietStrategyKind.balanced,
              enabled: blocking.isEmpty,
              onTap: () => context.push(
                '/profile/nutrition/strategy/configure?kind=${kind.name}',
              ),
            ),
          const SizedBox(height: AppSpacing.compact),
          Text(
            l10n.strategyScopeNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.compact),
          Text(
            l10n.strategyDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: visuals.onHeroMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyOption extends StatelessWidget {
  const _StrategyOption({
    required this.kind,
    required this.current,
    required this.isDefault,
    required this.enabled,
    required this.onTap,
  });

  final DietStrategyKind kind;
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
    return Semantics(
      button: true,
      selected: current,
      child: Material(
        color: Colors.transparent,
        shape: Border(bottom: BorderSide(color: visuals.divider)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.card),
            child: Row(
              children: [
                InkIcon(
                  current ? InkGlyph.radioChecked : InkGlyph.radioEmpty,
                  color: enabled
                      ? (current ? visuals.accent : scheme.onSurfaceVariant)
                      : scheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
                const SizedBox(width: AppSpacing.card),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              kind.label(l10n),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: current ? visuals.accent : null,
                              ),
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 6),
                            SoftChip(label: l10n.defaultWord),
                          ],
                          if (current) ...[
                            const SizedBox(width: 6),
                            SoftChip(
                              label: l10n.currentWord,
                              color: visuals.accentSoft,
                              foreground: visuals.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kind.description(l10n),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                InkIcon(
                  InkGlyph.chevronRight,
                  color: enabled
                      ? scheme.onSurfaceVariant
                      : theme.disabledColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
