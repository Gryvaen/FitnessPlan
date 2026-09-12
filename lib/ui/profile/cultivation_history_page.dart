import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/calendar_day.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'cultivation_labels.dart';

/// 「修行记录」：过往每日为境界修行贡献的 kcal 来源（步数 + 饮食盈余）一览，
/// 从 [CultivationPage] 的侧边「修行记录」图标进入。
class CultivationHistoryPage extends ConsumerWidget {
  const CultivationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final days = ref.watch(cultivationHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cultivationHistoryTitle)),
      body: days.isEmpty
          ? Center(
              child: Text(
                l10n.cultivationHistoryEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.listPage,
                AppSpacing.compact,
                AppSpacing.listPage,
                listBottomInset(context, hasFab: false),
              ),
              itemCount: days.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.compact),
              itemBuilder: (context, i) => _DayRow(record: days[i]),
            ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.record});

  final CultivationDayRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isToday =
        CalendarDay.dayOnly(record.date) == CalendarDay.todayLocal();
    final dateLabel = isToday
        ? l10n.cultivationHistoryTodayLabel
        : DateFormat('M/d').format(record.date);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dateLabel, style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${l10n.cultivationHistoryTotalLabel} ${formatKcal(record.totalKcal)} kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.directions_walk,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${l10n.cultivationHistoryStepsLabel} ${formatKcal(record.stepsKcal)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.restaurant_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${l10n.cultivationHistoryDietLabel} ${formatKcal(record.dietKcal)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
