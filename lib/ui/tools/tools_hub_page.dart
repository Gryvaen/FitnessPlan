import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';

/// Hub listing fitness toolbox calculators.
class ToolsHubPage extends StatelessWidget {
  const ToolsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolbox)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          _ToolTile(
            icon: Icons.accessibility_new_outlined,
            title: l10n.toolBodyFat,
            subtitle: l10n.toolBodyFatSub,
            onTap: () => context.push('/profile/tools/body-fat'),
          ),
          const SizedBox(height: AppSpacing.field),
          _ToolTile(
            icon: Icons.monitor_weight_outlined,
            title: l10n.toolBodyMetrics,
            subtitle: l10n.toolBodyMetricsSub,
            onTap: () => context.push('/profile/tools/body-metrics'),
          ),
          const SizedBox(height: AppSpacing.field),
          _ToolTile(
            icon: Icons.restaurant_outlined,
            title: l10n.toolFoodConvert,
            subtitle: l10n.toolFoodConvertSub,
            onTap: () => context.push('/profile/tools/food-convert'),
          ),
          const SizedBox(height: AppSpacing.field),
          _ToolTile(
            icon: Icons.timer_outlined,
            title: l10n.toolRestTimer,
            subtitle: l10n.toolRestTimerSub,
            onTap: () => context.push('/profile/tools/rest-timer'),
          ),
          const SizedBox(height: AppSpacing.field),
          _ToolTile(
            icon: Icons.calculate_outlined,
            title: l10n.toolCalculator,
            subtitle: l10n.toolCalculatorSub,
            onTap: () => context.push('/profile/tools/calculator'),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(
            l10n.toolsDisclaimer,
            style: theme.textTheme.meta,
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.meta),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
