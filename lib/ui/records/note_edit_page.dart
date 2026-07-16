import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

enum _SaveStatus { idle, dirty, saving, saved }

/// Full-screen memo-style daily note editor with debounced autosave.
class NoteEditPage extends ConsumerStatefulWidget {
  const NoteEditPage({super.key, this.date});

  /// Calendar day to edit; null means today.
  final DateTime? date;

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  static const _debounce = Duration(milliseconds: 800);

  late final DateTime _day;
  late final TextEditingController _ctrl;
  var _loading = true;
  var _status = _SaveStatus.idle;
  DateTime? _savedAt;
  Timer? _timer;
  String _lastSaved = '';

  @override
  void initState() {
    super.initState();
    final raw = widget.date ?? DateTime.now();
    _day = DateTime(raw.year, raw.month, raw.day);
    _ctrl = TextEditingController();
    _ctrl.addListener(_onChanged);
    _load();
  }

  Future<void> _load() async {
    final note = await ref.read(noteRepositoryProvider).getByDate(_day);
    if (!mounted) return;
    final text = note?.content ?? '';
    _ctrl.text = text;
    _lastSaved = text.trim();
    setState(() {
      _loading = false;
      _savedAt = note?.updatedAt;
      _status = note == null ? _SaveStatus.idle : _SaveStatus.saved;
    });
  }

  void _onChanged() {
    final trimmed = _ctrl.text.trim();
    if (trimmed == _lastSaved) {
      _timer?.cancel();
      if (_status == _SaveStatus.dirty) {
        setState(() => _status = _SaveStatus.saved);
      }
      return;
    }
    setState(() => _status = _SaveStatus.dirty);
    _timer?.cancel();
    _timer = Timer(_debounce, _persist);
  }

  Future<void> _persist() async {
    _timer?.cancel();
    final text = _ctrl.text;
    final trimmed = text.trim();
    if (trimmed == _lastSaved) {
      if (mounted) setState(() => _status = _SaveStatus.saved);
      return;
    }
    setState(() => _status = _SaveStatus.saving);
    try {
      await ref.read(noteRepositoryProvider).saveOrClear(
            date: _day,
            content: text,
          );
      if (!mounted) return;
      _lastSaved = trimmed;
      setState(() {
        _status = _SaveStatus.saved;
        _savedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = _SaveStatus.dirty);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveFailed('$e'))),
      );
    }
  }

  String _titleForDay(AppLocalizations l10n, Locale locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return AppDates.relativeDayTitle(_day, today, l10n, locale);
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (_status) {
      case _SaveStatus.idle:
        return l10n.startWriting;
      case _SaveStatus.dirty:
        return l10n.unsaved;
      case _SaveStatus.saving:
        return l10n.saving;
      case _SaveStatus.saved:
        if (_savedAt == null) return l10n.saved;
        return l10n.savedAt(DateFormat('HH:mm').format(_savedAt!));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.55);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titleForDay(l10n, locale)),
            Text(
              _statusLabel(l10n),
              style: theme.textTheme.meta?.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _loading || _status == _SaveStatus.saving
                ? null
                : _persist,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.formPage,
                8,
                AppSpacing.formPage,
                AppSpacing.formPage,
              ),
              child: TextField(
                controller: _ctrl,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: bodyStyle,
                cursorColor: theme.colorScheme.primary,
                decoration: InputDecoration(
                  hintText: l10n.noteHint,
                  hintStyle: bodyStyle?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.55),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
    );
  }
}
