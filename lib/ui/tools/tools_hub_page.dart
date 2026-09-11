import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

/// Hub listing fitness toolbox calculators.
class ToolsHubPage extends StatelessWidget {
  const ToolsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return AppChromeScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.listPage,
          0,
          AppSpacing.listPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          PageTitle(
            title: l10n.toolbox,
            subtitle: l10n.toolboxTagline,
            padding: const EdgeInsets.only(bottom: AppSpacing.section),
          ),
          _ToolRow(
            icon: Icons.accessibility_new_outlined,
            title: l10n.toolBodyFat,
            subtitle: l10n.toolBodyFatSub,
            onTap: () => context.push('/profile/tools/body-fat'),
          ),
          _ToolRow(
            icon: Icons.monitor_weight_outlined,
            title: l10n.toolBodyMetrics,
            subtitle: l10n.toolBodyMetricsSub,
            onTap: () => context.push('/profile/tools/body-metrics'),
          ),
          _ToolRow(
            icon: Icons.restaurant_outlined,
            title: l10n.toolFoodConvert,
            subtitle: l10n.toolFoodConvertSub,
            onTap: () => context.push('/profile/tools/food-convert'),
          ),
          _ToolRow(
            icon: Icons.timer_outlined,
            title: l10n.toolRestTimer,
            subtitle: l10n.toolRestTimerSub,
            onTap: () => context.push('/profile/tools/rest-timer'),
          ),
          _ToolRow(
            icon: Icons.calculate_outlined,
            title: l10n.toolCalculator,
            subtitle: l10n.toolCalculatorSub,
            onTap: () => context.push('/profile/tools/calculator'),
          ),
          _ToolRow(
            icon: Icons.swap_vert_circle_outlined,
            title: l10n.toolEnergyConvert,
            subtitle: l10n.toolEnergyConvertSub,
            onTap: () => context.push('/profile/tools/energy-convert'),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(
            l10n.toolsDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SportListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
