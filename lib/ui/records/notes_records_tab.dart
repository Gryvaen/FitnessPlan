import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

String noteEditPath(DateTime day) {
  final d = AppDates.dayOnly(day);
  final key = DateFormat('yyyy-MM-dd').format(d);
  return '/records/notes/edit?date=$key';
}

String _noteMeta(DailyNote note, AppLocalizations l10n, Locale locale) {
  final updated = note.updatedAt;
  final now = DateTime.now();
  final today = AppDates.dayOnly(now);
  final updatedDay = AppDates.dayOnly(updated);
  final time = DateFormat('HH:mm').format(updated);
  final String dayPart;
  if (updatedDay == today) {
    dayPart = l10n.todayWord;
  } else if (updatedDay == today.subtract(const Duration(days: 1))) {
    dayPart = l10n.yesterday;
  } else {
    dayPart = AppDates.md(updated, locale);
  }
  return '$dayPart · $time';
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
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dailyJournal,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              PlainIconAction(
                icon: Icons.add,
                label: l10n.fabWriteNote,
                onPressed: () => context.push(noteEditPath(DateTime.now())),
              ),
            ],
          ),
          Text(l10n.journalSubtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SportInkRow(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.journalPrompt),
            trailing: const Icon(Icons.arrow_forward, size: 18),
            onTap: () => context.push(noteEditPath(DateTime.now())),
          ),
        ],
      ),
    );

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          SportLoadError(onRetry: () => ref.invalidate(dailyNotesProvider)),
      data: (notes) {
        if (notes.isEmpty) {
          return ListView(
            children: [
              header,
              SportEmptyState(
                title: l10n.notesEmptyHint,
                icon: Icons.edit_note,
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
                  final lines = note.content
                      .split('\n')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  final title = lines.isEmpty ? l10n.dailyJournal : lines.first;
                  final monthStart =
                      index == 0 ||
                      notes[index - 1].date.month != day.month ||
                      notes[index - 1].date.year != day.year;
                  final tile = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (monthStart)
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 12),
                          child: Text(
                            DateFormat.yMMMM(
                              locale.toLanguageTag(),
                            ).format(day),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      InkWell(
                        onTap: () => context.push(noteEditPath(day)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 56,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${day.day}'.padLeft(2, '0'),
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    Text(
                                      DateFormat.E(
                                        locale.toLanguageTag(),
                                      ).format(day),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      if (lines.length > 1) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          lines.skip(1).join('\n'),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        _noteMeta(note, l10n, locale),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
