import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Hub listing fitness toolbox calculators.
class ToolsHubPage extends StatelessWidget {
  const ToolsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('工具箱')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          _ToolTile(
            icon: Icons.accessibility_new_outlined,
            title: '体脂估算',
            subtitle: '围度法（US Navy）估算体脂率',
            onTap: () => context.push('/profile/tools/body-fat'),
          ),
          const SizedBox(height: AppSpacing.field),
          _ToolTile(
            icon: Icons.monitor_weight_outlined,
            title: '身体指标',
            subtitle: 'BMI、理想体重、腰高比',
            onTap: () => context.push('/profile/tools/body-metrics'),
          ),
          const SizedBox(height: AppSpacing.field),
          _ToolTile(
            icon: Icons.restaurant_outlined,
            title: '食物换算',
            subtitle: '按克数换算食材热量与营养素',
            onTap: () => context.push('/profile/tools/food-convert'),
          ),
          const SizedBox(height: AppSpacing.field),
          _ToolTile(
            icon: Icons.timer_outlined,
            title: '休息计时器',
            subtitle: '组间倒计时，锁屏可提醒',
            onTap: () => context.push('/profile/tools/rest-timer'),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(
            '结果默认不写入档案或饮食记录。',
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
