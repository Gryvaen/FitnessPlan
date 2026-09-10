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
  Timer? _timer;
  var _loading = true;
  var _status = _SaveStatus.idle;
  DateTime? _savedAt;
  bool _loadFailed = false;
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
    try {
      final note = await ref.read(noteRepositoryProvider).getByDate(_day);
      if (!mounted) return;
      final text = note?.content ?? '';
      _lastSaved = text.trim();
      _ctrl.text = text;
      setState(() {
        _loading = false;
        _loadFailed = false;
        _savedAt = note?.updatedAt;
        _status = note == null ? _SaveStatus.idle : _SaveStatus.saved;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _onChanged() {
    if (!AppDates.isLocalToday(_day)) return;
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
    if (!AppDates.isLocalToday(_day) || _status == _SaveStatus.saving) return;
    final text = _ctrl.text;
    final trimmed = text.trim();
    if (trimmed == _lastSaved) {
      if (mounted) setState(() => _status = _SaveStatus.saved);
      return;
    }
    setState(() => _status = _SaveStatus.saving);
    try {
      await ref
          .read(noteRepositoryProvider)
          .saveOrClear(date: _day, content: text);
      if (!mounted) return;
      _lastSaved = trimmed;
      setState(() {
        _status = _SaveStatus.saved;
        _savedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = _SaveStatus.dirty);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed('$e'))));
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    if (!AppDates.isLocalToday(_day)) return l10n.pastDayReadOnly;
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
    final scheme = theme.colorScheme;
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.55);
    final editable = AppDates.isLocalToday(_day);

    return PopScope(
      canPop: !editable || _status != _SaveStatus.saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !editable) return;
        // Autosave already keeps the note current; flush any pending edit.
        final navigator = Navigator.of(context);
        _timer?.cancel();
        await _persist();
        if (mounted) navigator.pop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (editable)
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        _timer?.cancel();
                        await _persist();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                child: Text(l10n.done),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
            ? Center(
                child: TextButton(onPressed: _load, child: Text(l10n.retry)),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.formPage,
                  4,
                  AppSpacing.formPage,
                  AppSpacing.formPage,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDates.ymdWithWeekday(_day, locale),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.field),
                    Expanded(
                      child: Theme(
                        data: theme.copyWith(
                          inputDecorationTheme: const InputDecorationTheme(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          // Never toggle readOnly mid-session: flipping it while
                          // an autosave runs tears down and rebuilds the input
                          // connection, so the keyboard flickers shut on every
                          // debounced save.
                          readOnly: !editable,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          style: bodyStyle,
                          cursorColor: scheme.primary,
                          decoration: InputDecoration(
                            filled: false,
                            hintText: editable ? l10n.noteHint : null,
                            hintStyle: bodyStyle?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.charCount(_ctrl.text.trim().runes.length),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
