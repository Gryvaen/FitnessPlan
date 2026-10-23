import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import 'note_plan_text.dart';
import 'note_mode_toggle.dart';
import '../theme/app_theme.dart';
import '../widgets/search_field_focus.dart';

enum _SaveStatus { idle, dirty, saving, saved }

const _modeRecord = 'record';
const _modePlan = 'plan';

/// Full-screen daily-note editor with debounced autosave. Each day holds one
/// independent note per mode: free-text record and numbered plan.
class NoteEditPage extends ConsumerStatefulWidget {
  const NoteEditPage({super.key, this.date, this.mode = 'record'});

  /// Calendar day to edit; null means today.
  final DateTime? date;
  final String mode;

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  static const _debounce = Duration(milliseconds: 800);

  late final DateTime _day;
  late final TextEditingController _ctrl;
  Future<bool>? _pendingSave;
  bool _leaving = false;
  bool _allowPop = false;
  final _focus = FocusNode();
  Timer? _timer;
  var _loading = true;
  var _status = _SaveStatus.idle;
  var _mode = _modeRecord;
  final _drafts = <String, String>{_modeRecord: '', _modePlan: '1. '};
  final _saved = <String, String>{_modeRecord: '', _modePlan: ''};
  DateTime? _savedAt;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.date ?? DateTime.now();
    _day = DateTime(raw.year, raw.month, raw.day);
    _ctrl = TextEditingController();
    _ctrl.addListener(_onChanged);
    suppressInitialTextFocus(_focus);
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(noteRepositoryProvider);
      final record = await repo.getByDate(_day);
      final plan = await repo.getByDate(_day, mode: _modePlan);
      if (!mounted) return;
      _drafts[_modeRecord] = record?.content ?? '';
      _drafts[_modePlan] = displayPlan(plan?.content ?? '');
      _saved[_modeRecord] = record?.content.trim() ?? '';
      _saved[_modePlan] = plan?.content.trim() ?? '';
      final mode = widget.mode == _modePlan ? _modePlan : _modeRecord;
      final note = mode == _modePlan ? plan : record;
      _ctrl.text = _drafts[mode]!;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      setState(() {
        _mode = mode;
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

  String _currentContent() =>
      _mode == _modePlan ? planContent(_ctrl.text) : _ctrl.text;

  void _setMode(String mode) {
    if (mode == _mode) return;
    _drafts[_mode] = _ctrl.text;
    _ctrl.removeListener(_onChanged);
    _ctrl.text = _drafts[mode]!;
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _ctrl.addListener(_onChanged);
    setState(() => _mode = mode);
    _onChanged();
  }

  String _contentFor(String mode) {
    final text = _drafts[mode]!;
    return (mode == _modePlan ? planContent(text) : text).trim();
  }

  bool get _hasChanges =>
      _saved.keys.any((mode) => _contentFor(mode) != _saved[mode]);

  void _onChanged() {
    if (_loading || !AppDates.isLocalToday(_day)) return;
    _drafts[_mode] = _ctrl.text;
    _timer?.cancel();
    setState(
      () => _status = _hasChanges ? _SaveStatus.dirty : _SaveStatus.saved,
    );
    if (_hasChanges) _timer = Timer(_debounce, _persist);
  }

  Future<bool> _persist() async {
    _timer?.cancel();
    if (_loading || _loadFailed) return false;
    if (!AppDates.isLocalToday(_day)) return true;
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
      _drafts[_mode] = _ctrl.text;
      if (!_hasChanges) {
        setState(() => _status = _SaveStatus.saved);
        return true;
      }
      final mode = _saved.keys.firstWhere(
        (mode) => _contentFor(mode) != _saved[mode],
      );
      final content = _contentFor(mode);
      setState(() => _status = _SaveStatus.saving);
      try {
        await ref
            .read(noteRepositoryProvider)
            .saveOrClear(date: _day, content: content, mode: mode);
        _saved[mode] = content;
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
    _focus.dispose();
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
      canPop: _allowPop || !editable || _loadFailed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && editable) _leave();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: scheme.surface,
        appBar: AppBar(
          leading: BackButton(
            onPressed: editable && !_loadFailed
                ? _leave
                : () => Navigator.of(context).maybePop(),
          ),
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          actions: [
            NoteModeToggle(
              isPlan: _mode == _modePlan,
              onPressed: _loading || _loadFailed
                  ? null
                  : () =>
                        _setMode(_mode == _modePlan ? _modeRecord : _modePlan),
            ),
            if (editable)
              TextButton(
                onPressed: _loading || _loadFailed ? null : _leave,
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppDates.ymdWithWeekday(_day, locale),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          _statusLabel(l10n),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.field),
                    Expanded(
                      child: _buildRecordBody(
                        theme,
                        scheme,
                        l10n,
                        bodyStyle,
                        editable,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.charCount(_currentContent().trim().runes.length),
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

  Widget _buildRecordBody(
    ThemeData theme,
    ColorScheme scheme,
    AppLocalizations l10n,
    TextStyle? bodyStyle,
    bool editable,
  ) {
    return Theme(
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
        inputFormatters: _mode == _modePlan ? [PlanNumberFormatter()] : null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        focusNode: _focus,
        // Never toggle readOnly mid-session: flipping it while an autosave runs
        // tears down and rebuilds the input connection, so the keyboard
        // flickers shut on every debounced save.
        readOnly: !editable,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        style: bodyStyle,
        cursorColor: scheme.primary,
        decoration: InputDecoration(
          filled: false,
          hintText: editable && _mode == _modeRecord ? l10n.noteHint : null,
          hintStyle: bodyStyle?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
