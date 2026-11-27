import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'note_plan_text.dart';

enum _SaveStatus { idle, dirty, saving, saved }

final _itemStart = RegExp(r'^\d+\.[ \t]?', multiLine: true);

/// Numbered items with some text in them.
int experienceItemCount(String text) => text
    .split(_itemStart)
    .skip(1)
    .where((item) => item.trim().isNotEmpty)
    .length;

/// 「经验之谈」: one numbered document, edited like the plan-mode note —
/// pressing Enter twice starts the next numbered item. Not tied to a day, so
/// it is always editable. Autosaves after a pause and on leaving.
class ExperiencePage extends ConsumerStatefulWidget {
  const ExperiencePage({super.key});

  @override
  ConsumerState<ExperiencePage> createState() => _ExperiencePageState();
}

class _ExperiencePageState extends ConsumerState<ExperiencePage> {
  static const _debounce = Duration(milliseconds: 800);

  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  Future<bool>? _pendingSave;
  bool _leaving = false;
  bool _allowPop = false;
  var _loading = true;
  var _loadFailed = false;
  var _status = _SaveStatus.idle;
  var _saved = '';
  DateTime? _savedAt;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await ref.read(experienceRepositoryProvider).load();
      if (!mounted) return;
      _saved = text.trim();
      _ctrl.text = displayPlan(text);
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      setState(() {
        _loading = false;
        _loadFailed = false;
        _status = _saved.isEmpty ? _SaveStatus.idle : _SaveStatus.saved;
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

  String get _content => planContent(_ctrl.text).trim();

  bool get _hasChanges => _content != _saved;

  void _onChanged() {
    if (_loading) return;
    _timer?.cancel();
    setState(
      () => _status = _hasChanges ? _SaveStatus.dirty : _SaveStatus.saved,
    );
    if (_hasChanges) _timer = Timer(_debounce, _persist);
  }

  Future<bool> _persist() async {
    _timer?.cancel();
    if (_loading || _loadFailed) return false;
    if (_pendingSave != null) return _pendingSave!;
    final pending = _saveUntilCurrent();
    _pendingSave = pending;
    try {
      return await pending;
    } finally {
      _pendingSave = null;
    }
  }

  Future<bool> _saveUntilCurrent() async {
    while (mounted) {
      if (!_hasChanges) {
        setState(() => _status = _SaveStatus.saved);
        return true;
      }
      final content = _content;
      setState(() => _status = _SaveStatus.saving);
      try {
        await ref.read(experienceRepositoryProvider).save(content);
        _saved = content;
        _savedAt = DateTime.now();
      } catch (e) {
        if (!mounted) return false;
        setState(() => _status = _SaveStatus.dirty);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed('$e'))));
        return false;
      }
    }
    return false;
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final saved = await _persist();
    if (!mounted) return;
    _leaving = false;
    if (!saved) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _statusLabel(AppLocalizations l10n) => switch (_status) {
    _SaveStatus.idle => l10n.startWriting,
    _SaveStatus.dirty => l10n.unsaved,
    _SaveStatus.saving => l10n.saving,
    _SaveStatus.saved =>
      _savedAt == null
          ? l10n.saved
          : l10n.savedAt(DateFormat('HH:mm').format(_savedAt!)),
  };

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bodyStyle = theme.textTheme.rowTitle?.copyWith(height: 1.55);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final count = experienceItemCount(_ctrl.text);
    final ready = !_loading && !_loadFailed;

    return PopScope(
      canPop: _allowPop || _loadFailed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: scheme.surface,
        appBar: AppBar(
          leading: BackButton(
            onPressed: _loadFailed
                ? () => Navigator.of(context).maybePop()
                : _leave,
          ),
          title: Text(l10n.experienceTitle),
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          actions: [
            TextButton(
              onPressed: ready ? _leave : null,
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
                    Text(_statusLabel(l10n), style: muted),
                    const SizedBox(height: AppSpacing.field),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('experience-text'),
                        controller: _ctrl,
                        focusNode: _focus,
                        inputFormatters: [PlanNumberFormatter()],
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        style: bodyStyle,
                        cursorColor: scheme.primary,
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(l10n.experienceCount(count), style: muted),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
