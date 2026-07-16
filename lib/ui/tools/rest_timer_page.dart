import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';
import 'rest_timer_notifications.dart';

class RestTimerPage extends StatefulWidget {
  const RestTimerPage({super.key});

  @override
  State<RestTimerPage> createState() => _RestTimerPageState();
}

class _RestTimerPageState extends State<RestTimerPage>
    with WidgetsBindingObserver {
  static const _presets = <int>[60, 90, 120, 180];

  int _selectedSeconds = 90;
  int _remainingSeconds = 90;
  bool _running = false;
  bool _permissionHintShown = false;
  Timer? _ticker;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapPermissions();
  }

  Future<void> _bootstrapPermissions() async {
    final ok = await RestTimerNotifications.requestPermissions();
    if (!mounted || ok || _permissionHintShown) return;
    _permissionHintShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.restNotifyPermissionHint),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    unawaited(RestTimerNotifications.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running || _endsAt == null) return;
    if (state == AppLifecycleState.resumed) {
      _syncFromDeadline();
    }
  }

  void _syncFromDeadline() {
    final ends = _endsAt;
    if (ends == null) return;
    final left = ends.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      _onFinished(fromNotification: false);
    } else {
      setState(() => _remainingSeconds = left);
    }
  }

  Future<void> _start() async {
    if (_running) return;
    final l10n = context.l10n;
    final secs = _selectedSeconds.clamp(30, 600);
    setState(() {
      _running = true;
      _remainingSeconds = secs;
      _endsAt = DateTime.now().add(Duration(seconds: secs));
    });
    await RestTimerNotifications.scheduleRestEnd(
      Duration(seconds: secs),
      title: l10n.restDoneTitle,
      body: l10n.restDoneBody,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final ends = _endsAt;
      if (ends == null) return;
      final left = ends.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        _onFinished(fromNotification: false);
      } else {
        setState(() => _remainingSeconds = left);
      }
    });
  }

  Future<void> _onFinished({required bool fromNotification}) async {
    _ticker?.cancel();
    _ticker = null;
    if (!_running && !fromNotification) return;
    setState(() {
      _running = false;
      _remainingSeconds = 0;
      _endsAt = null;
    });
    await RestTimerNotifications.cancel();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.restDoneSnack)),
    );
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    _ticker = null;
    await RestTimerNotifications.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _selectedSeconds;
      _endsAt = null;
    });
  }

  String _format(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final display = _running ? _remainingSeconds : _selectedSeconds;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolRestTimer)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.restTimerIntro,
              style: theme.textTheme.meta,
            ),
            const SizedBox(height: AppSpacing.section),
            Center(
              child: Text(
                _format(display),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _presets)
                  ChoiceChip(
                    label: Text(_format(s)),
                    selected: !_running && _selectedSeconds == s,
                    onSelected: _running
                        ? null
                        : (_) => setState(() {
                              _selectedSeconds = s;
                              _remainingSeconds = s;
                            }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.field),
            if (!_running) ...[
              Text(l10n.customDuration, style: theme.textTheme.fieldLabel),
              Slider(
                min: 30,
                max: 600,
                divisions: 114,
                label: _format(_selectedSeconds),
                value: _selectedSeconds.toDouble().clamp(30, 600),
                onChanged: (v) => setState(() {
                  _selectedSeconds = v.round();
                  _remainingSeconds = _selectedSeconds;
                }),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: Text(l10n.reset),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _running ? null : _start,
                    child: Text(_running ? l10n.timing : l10n.start),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
          ],
        ),
      ),
    );
  }
}
