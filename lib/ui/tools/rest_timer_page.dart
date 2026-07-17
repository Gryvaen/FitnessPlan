import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _presets = <int>[30, 60, 90, 120, 180, 300, 600];
  static const _selectedKey = 'rest_timer_selected_seconds';
  static const _deadlineKey = 'rest_timer_deadline_ms';
  static const _pausedKey = 'rest_timer_paused_seconds';

  int _selectedSeconds = 90;
  int _remainingSeconds = 90;
  int _totalSeconds = 90;
  bool _running = false;
  bool _paused = false;
  bool _finished = false;
  bool _permissionHintShown = false;
  Timer? _ticker;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = (prefs.getInt(_selectedKey) ?? 90).clamp(30, 600);
    final paused = prefs.getInt(_pausedKey);
    final deadlineMs = prefs.getInt(_deadlineKey);
    final deadline = deadlineMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deadlineMs);

    if (!mounted) return;
    if (deadline != null && deadline.isAfter(DateTime.now())) {
      final left = _secondsUntil(deadline);
      setState(() {
        _selectedSeconds = selected;
        _totalSeconds = math.max(selected, left);
        _remainingSeconds = left;
        _endsAt = deadline;
        _running = true;
      });
      _startTicker();
    } else {
      if (deadlineMs != null) await prefs.remove(_deadlineKey);
      setState(() {
        _selectedSeconds = selected;
        _remainingSeconds = paused?.clamp(1, 600) ?? selected;
        _totalSeconds = math.max(selected, _remainingSeconds);
        _paused = paused != null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    // Do not cancel the scheduled alert here: leaving this page must not stop
    // a running rest timer.
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncFromDeadline();
  }

  int _secondsUntil(DateTime deadline) {
    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    return math.max(0, (milliseconds + 999) ~/ 1000);
  }

  void _syncFromDeadline() {
    final ends = _endsAt;
    if (!_running || ends == null) return;
    final left = _secondsUntil(ends);
    if (left <= 0) {
      unawaited(_onFinished());
    } else if (mounted) {
      setState(() => _remainingSeconds = left);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _syncFromDeadline();
    });
  }

  Future<void> _start({bool resume = false}) async {
    if (_running) return;
    final seconds = (resume ? _remainingSeconds : _selectedSeconds).clamp(
      1,
      600,
    );
    final l10n = context.l10n;

    final permissionGranted = await RestTimerNotifications.requestPermissions();
    if (!mounted) return;
    if (!permissionGranted && !_permissionHintShown) {
      _permissionHintShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.restNotifyPermissionHint)));
    }

    final deadline = DateTime.now().add(Duration(seconds: seconds));
    setState(() {
      _running = true;
      _paused = false;
      _finished = false;
      _remainingSeconds = seconds;
      _totalSeconds = seconds;
      _endsAt = deadline;
    });
    await _persist();
    await RestTimerNotifications.scheduleRestEnd(
      Duration(seconds: seconds),
      title: l10n.restDoneTitle,
      body: l10n.restDoneBody,
      dismissLabel: l10n.restTimerDismiss,
    );
    _startTicker();
  }

  Future<void> _pause() async {
    final ends = _endsAt;
    if (!_running || ends == null) return;
    final left = math.max(1, _secondsUntil(ends));
    _ticker?.cancel();
    await RestTimerNotifications.cancel();
    if (!mounted) return;
    setState(() {
      _running = false;
      _paused = true;
      _remainingSeconds = left;
      _endsAt = null;
    });
    await _persist();
  }

  Future<void> _onFinished() async {
    if (!_running) return;
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _running = false;
      _paused = false;
      _finished = true;
      _remainingSeconds = 0;
      _endsAt = null;
    });
    await _persist();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.restDoneSnack)));
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    _ticker = null;
    await RestTimerNotifications.cancel();
    if (!mounted) return;
    setState(() {
      _running = false;
      _paused = false;
      _finished = false;
      _remainingSeconds = _selectedSeconds;
      _totalSeconds = _selectedSeconds;
      _endsAt = null;
    });
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedKey, _selectedSeconds);
    if (_running && _endsAt != null) {
      await prefs.setInt(_deadlineKey, _endsAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_deadlineKey);
    }
    if (_paused) {
      await prefs.setInt(_pausedKey, _remainingSeconds);
    } else {
      await prefs.remove(_pausedKey);
    }
  }

  String _format(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _presetLabel(int seconds) {
    if (seconds < 60) return '$seconds${context.l10n.seconds}';
    final minutes = seconds / 60;
    final value = minutes == minutes.roundToDouble()
        ? minutes.toInt().toString()
        : minutes.toStringAsFixed(1);
    return context.l10n.restTimerMinutes(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final display = _finished
        ? 0
        : (_running || _paused ? _remainingSeconds : _selectedSeconds);
    final progress = _totalSeconds == 0
        ? 0.0
        : (display / _totalSeconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolRestTimer)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.formPage),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.restTimerIntro,
                            style: theme.textTheme.meta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    SizedBox.square(
                      dimension: 210,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _running
                                    ? l10n.restTimerRunning
                                    : _paused
                                    ? l10n.restTimerPaused
                                    : _finished
                                    ? l10n.restTimerFinished
                                    : l10n.restTimerReady,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _format(display),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -2,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_running && !_paused) ...[
              const SizedBox(height: 24),
              Text(
                l10n.restTimerPresetTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 16) / 3;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final seconds in _presets)
                        SizedBox(
                          width: width,
                          child: _PresetButton(
                            label: _presetLabel(seconds),
                            selected: _selectedSeconds == seconds,
                            onPressed: () {
                              setState(() {
                                _selectedSeconds = seconds;
                                _remainingSeconds = seconds;
                                _totalSeconds = seconds;
                                _finished = false;
                              });
                              unawaited(_persist());
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.reset),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _running
                        ? _pause
                        : () => _start(resume: _paused),
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      _running
                          ? l10n.restTimerPause
                          : _paused
                          ? l10n.restTimerResume
                          : l10n.start,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
