import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

String noteEditPath(DateTime day) {
  final d = AppDates.dayOnly(day);
  final key = DateFormat('yyyy-MM-dd').format(d);
  return '/records/notes/edit?date=$key';
}

String _noteTitle(DateTime day, AppLocalizations l10n, Locale locale) {
  return AppDates.relativeDayTitle(day, AppDates.todayLocal(), l10n, locale);
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

String _noteMeta(DailyNote note, AppLocalizations l10n) {
  final chars = note.content.trim().runes.length;
  final updated = note.updatedAt;
  final now = DateTime.now();
  final sameDay = updated.year == now.year &&
      updated.month == now.month &&
      updated.day == now.day;
  final time = sameDay
      ? DateFormat('HH:mm').format(updated)
      : DateFormat('M/d HH:mm').format(updated);
  return l10n.charsUpdated(chars, time);
}

/// Daily journal notes list under Records → Notes.
class NotesRecordsTab extends ConsumerWidget {
  const NotesRecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final notesAsync = ref.watch(dailyNotesProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.listPage, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.segmentNotes,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: l10n.fabWriteNote,
            onPressed: () => context.push(noteEditPath(DateTime.now())),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.loadFailed('$e'))),
      data: (notes) {
        if (notes.isEmpty) {
          return Column(
            children: [
              header,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.formPage),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.notesEmptyHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.notesEmptyCta,
                          style: theme.textTheme.meta,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            header,
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.listPage,
                  8,
                  AppSpacing.listPage,
                  listBottomInset(context, hasFab: false),
                ),
                itemCount: notes.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          itemBuilder: (context, index) {
            final note = notes[index];
            final day = AppDates.dayOnly(note.date);
            final isToday = AppDates.isLocalToday(day, now);
            final preview = _notePreview(note.content);
            final title = _noteTitle(note.date, l10n, locale);

            final tile = InkWell(
              onTap: () => context.push(noteEditPath(note.date)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      color: isToday ? scheme.primary : Colors.transparent,
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
                                    title,
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
                                      l10n.todayWord,
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
                              _noteMeta(note, l10n),
                              style: theme.textTheme.meta,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (!isToday) return tile;

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
                        title: Text(l10n.deleteNote),
                        content: Text(l10n.confirmDeleteNote(title)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    ) ==
                    true;
              },
              onDismissed: (_) {
                ref.read(noteRepositoryProvider).delete(note.id);
              },
              child: tile,
            );
          },
              ),
            ),
          ],
        );
      },
    );
  }
}
