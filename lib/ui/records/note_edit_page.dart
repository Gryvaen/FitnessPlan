import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  String _titleForDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (_day == today) return '今天';
    if (_day == yesterday) return '昨天';
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final wd = weekdays[_day.weekday - 1];
    if (_day.year == today.year) {
      return '${DateFormat('M月d日').format(_day)} $wd';
    }
    return '${DateFormat('yyyy年M月d日').format(_day)} $wd';
  }

  String _statusLabel() {
    switch (_status) {
      case _SaveStatus.idle:
        return '开始书写';
      case _SaveStatus.dirty:
        return '未保存';
      case _SaveStatus.saving:
        return '保存中…';
      case _SaveStatus.saved:
        if (_savedAt == null) return '已保存';
        return '已保存 · ${DateFormat('HH:mm').format(_savedAt!)}';
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
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.55);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titleForDay()),
            Text(
              _statusLabel(),
              style: theme.textTheme.meta?.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _loading || _status == _SaveStatus.saving
                ? null
                : _persist,
            child: const Text('保存'),
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
                  hintText: '记录今天的训练感受、睡眠或饮食偏差…',
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
