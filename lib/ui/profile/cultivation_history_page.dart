import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/calendar_day.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'cultivation_labels.dart';

/// 「修行记录」：过往每日为境界修行贡献的 kcal 来源（步数 + 饮食，饮食一项
/// 可能为负——见 [cultivationDietKcalForDayProvider]）一览，从
/// [CultivationPage] 的侧边「修行记录」图标进入。
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
                '${l10n.cultivationHistoryTotalLabel} ${formatSignedKcal(record.totalKcal)} kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: record.totalKcal < 0
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
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
                '${l10n.cultivationHistoryStepsLabel} ${formatSignedKcal(record.stepsKcal)} kcal',
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
                '${l10n.cultivationHistoryDietLabel} ${formatSignedKcal(record.dietKcal)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: record.dietKcal < 0
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (!record.workout.isEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    children: [
                      for (final group in record.workout.groups)
                        if (group.items.isNotEmpty)
                          Text(
                            '${_groupName(group.workout.planName, l10n)} '
                            '${l10n.cultivationHistoryWorkoutProgress('${group.doneCount}', '${group.items.length}')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _groupName(String? planName, AppLocalizations l10n) {
    final trimmed = planName?.trim();
    return trimmed == null || trimmed.isEmpty
        ? l10n.untitledWorkoutGroup
        : trimmed;
  }
}
