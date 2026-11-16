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
import 'strategy_target_card.dart';

InkGlyph _glyphFor(DietStrategyKind kind) => switch (kind) {
  DietStrategyKind.balanced => InkGlyph.target,
  DietStrategyKind.carbCycle => InkGlyph.cycle,
  DietStrategyKind.carbTaper => InkGlyph.chart,
};

/// Profile → Nutrition → Strategy: pick one of the three primary strategies.
class StrategyPickerPage extends ConsumerStatefulWidget {
  const StrategyPickerPage({super.key});

  @override
  ConsumerState<StrategyPickerPage> createState() => _StrategyPickerPageState();
}

class _StrategyPickerPageState extends ConsumerState<StrategyPickerPage> {
  bool _rulesExpanded = false;

  @override
  Widget build(BuildContext context) {
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
          if (blocking.isNotEmpty) ...[
            for (final i in blocking)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.compact),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkIcon(
                      InkGlyph.error,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: Text(
                        i.message(l10n),
                        style: theme.textTheme.meta?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Divider(height: 1, color: visuals.divider),
          ],
          for (final kind in DietStrategyKind.values)
            StrategyOptionRow(
              optionKey: ValueKey('strategy-option-${kind.name}'),
              glyph: _glyphFor(kind),
              label: kind.label(l10n),
              description: kind.description(l10n),
              current: active?.kind == kind,
              isDefault: kind == DietStrategyKind.balanced,
              enabled: blocking.isEmpty,
              onTap: () => context.push(
                '/profile/nutrition/strategy/configure?kind=${kind.name}',
              ),
            ),
          const SizedBox(height: AppSpacing.section),
          _StrategyRulesNote(
            expanded: _rulesExpanded,
            onTap: () => setState(() => _rulesExpanded = !_rulesExpanded),
          ),
        ],
      ),
    );
  }
}

/// Secondary guidance below the three selectable strategy rows.
class _StrategyRulesNote extends StatelessWidget {
  const _StrategyRulesNote({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visuals = AppThemeVisuals.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final noteStyle = theme.textTheme.meta?.copyWith(height: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          label:
              '${l10n.strategyRulesTitle}, '
              '${expanded ? l10n.collapseSection : l10n.expandSection}',
          child: InkWell(
            key: const ValueKey('strategyPickerRules'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.field),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    InkIcon(
                      InkGlyph.info,
                      size: 18,
                      color: expanded ? visuals.accent : muted,
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: Text(
                        l10n.strategyRulesTitle,
                        style: theme.textTheme.meta?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: expanded ? visuals.accent : muted,
                        ),
                      ),
                    ),
                    InkIcon(
                      expanded ? InkGlyph.collapse : InkGlyph.expand,
                      size: 18,
                      color: expanded ? visuals.accent : muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: expanded
              ? Container(
                  margin: const EdgeInsets.only(
                    left: AppSpacing.compact,
                    bottom: AppSpacing.compact,
                  ),
                  padding: const EdgeInsets.only(
                    left: AppSpacing.card,
                    right: AppSpacing.compact,
                  ),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: visuals.divider)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.strategyPickerIntro, style: noteStyle),
                      const SizedBox(height: AppSpacing.field),
                      Text(l10n.strategyScopeNote, style: noteStyle),
                      const SizedBox(height: AppSpacing.field),
                      Text(l10n.strategyDisclaimer, style: noteStyle),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
