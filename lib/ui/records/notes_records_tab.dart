import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

String noteEditPath(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  final key = DateFormat('yyyy-MM-dd').format(d);
  return '/records/notes/edit?date=$key';
}

String _noteTitle(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final d = DateTime(day.year, day.month, day.day);
  if (d == today) return '今天';
  if (d == yesterday) return '昨天';
  const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  final wd = weekdays[d.weekday - 1];
  if (d.year == today.year) {
    return '${DateFormat('M月d日').format(d)} $wd';
  }
  return '${DateFormat('yyyy年M月d日').format(d)} $wd';
}

String _notePreview(String content) {
  final lines = content
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .take(2)
      .toList();
  if (lines.isEmpty) return '';
  return lines.join('\n');
}

String _noteMeta(DailyNote note) {
  final chars = note.content.trim().runes.length;
  final updated = note.updatedAt;
  final now = DateTime.now();
  final sameDay = updated.year == now.year &&
      updated.month == now.month &&
      updated.day == now.day;
  final time = sameDay
      ? DateFormat('HH:mm').format(updated)
      : DateFormat('M/d HH:mm').format(updated);
  return '$chars 字 · 已更新 $time';
}

/// Daily journal notes list under Records → 便签.
class NotesRecordsTab extends ConsumerWidget {
  const NotesRecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(dailyNotesProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (notes) {
        if (notes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.formPage),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '记录今天的训练感受、睡眠或饮食偏差',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点右下角开始写',
                    style: theme.textTheme.meta,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.listPage,
            8,
            AppSpacing.listPage,
            88,
          ),
          itemCount: notes.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          itemBuilder: (context, index) {
            final note = notes[index];
            final day = DateTime(note.date.year, note.date.month, note.date.day);
            final isToday = day == today;
            final preview = _notePreview(note.content);

            return Dismissible(
              key: ValueKey(note.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: scheme.error,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('删除便签'),
                        content: Text('确定删除 ${_noteTitle(note.date)} 的便签？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    ) ==
                    true;
              },
              onDismissed: (_) {
                ref.read(noteRepositoryProvider).delete(note.id);
              },
              child: InkWell(
                onTap: () => context.push(noteEditPath(note.date)),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 3,
                        color: isToday
                            ? scheme.primary
                            : Colors.transparent,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _noteTitle(note.date),
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ),
                                  if (isToday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '今天',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (preview.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                _noteMeta(note),
                                style: theme.textTheme.meta,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
