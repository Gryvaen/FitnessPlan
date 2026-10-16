import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import 'reminder_status_labels.dart';
import 'rest_timer_notifications.dart';
import 'restriction_issue_row.dart';
import 'workout_reminder_notifications.dart';

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
  static const _finishedKey = 'rest_timer_finished';
  static const _alertModeKey = 'rest_timer_alert_mode';
  static const _backgroundAckKey = 'rest_timer_background_ack';

  int _selectedSeconds = 90;
  int _remainingSeconds = 90;
  int _totalSeconds = 90;
  bool _running = false;
  bool _paused = false;
  bool _finished = false;
  bool _permissionHintShown = false;
  bool _notificationsAllowed = true;
  bool _exactAlarmAllowed = true;
  bool _scheduleFailed = false;

  /// On ColorOS/MIUI-style skins the system freezes the app in the
  /// background and holds its alarms until it is reopened. True until the
  /// user has visited the battery settings (no API reports the toggle).
  bool _backgroundRisk = false;
  bool _backgroundHintShown = false;

  /// Which switch to look for, shown once the user is back from settings.
  String? _pendingSettingsHint;
  bool _restoring = true;
  bool _modeChanging = false;
  RestTimerAlertMode _alertMode = RestTimerAlertMode.ringAndVibrate;

  /// Guards [_start] itself: `_running` only flips true after the
  /// permission-request await resolves, so without this a rapid double-tap
  /// on the play button (permission already granted → the await is fast
  /// but not instant) could both pass the `_running` check and schedule two
  /// competing notifications.
  bool _starting = false;
  Timer? _ticker;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restore());
    unawaited(_refreshAlertStatus());
    unawaited(_checkAlarmDelay());
  }

  Future<void> _refreshAlertStatus() async {
    final status = await RestTimerNotifications.alarmStatus();
    final aggressive = await ReminderNotifications.isAggressiveOem();
    final prefs = await SharedPreferences.getInstance();
    final acknowledged = prefs.getBool(_backgroundAckKey) ?? false;
    if (!mounted) return;
    setState(() {
      _notificationsAllowed = status.notifications;
      _exactAlarmAllowed = status.exact;
      _backgroundRisk = aggressive && !acknowledged;
    });
  }

  /// Surfaces an alert the system held back while the app was frozen, and
  /// brings the background-settings issue back since the fix did not stick.
  Future<void> _checkAlarmDelay() async {
    final delay = await RestTimerNotifications.takeLastAlarmDelay();
    if (delay == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundAckKey, false);
    if (!mounted) return;
    setState(() => _backgroundRisk = true);
    _backgroundHintShown = true;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.restTimerAlarmDelayed(delay.inSeconds)),
        action: SnackBarAction(
          label: l10n.reminderOemHintAutostartButton,
          onPressed: _openBackgroundSettings,
        ),
      ),
    );
  }

  void _showPendingSettingsHint() {
    final hint = _pendingSettingsHint;
    if (!mounted || hint == null) return;
    _pendingSettingsHint = null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(hint), duration: const Duration(seconds: 8)),
      );
  }

  Future<void> _openBackgroundSettings() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    AutoStartSettingsDestination destination;
    try {
      destination = await ReminderNotifications.openAutoStartSettings();
    } catch (_) {
      // No settings page could be opened; the issue stays listed.
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.reminderAutoStartManualHint)),
      );
      return;
    }
    // Generic pages need one more step; say which switch to look for when
    // the user comes back (a SnackBar shown now would expire unseen).
    _pendingSettingsHint = switch (destination) {
      AutoStartSettingsDestination.oem => null,
      AutoStartSettingsDestination.battery => l10n.reminderAutoStartBatteryHint,
      AutoStartSettingsDestination.appDetails =>
        l10n.reminderAutoStartAppDetailsHint,
      AutoStartSettingsDestination.colorOsAppDetails =>
        l10n.reminderAutoStartColorOsHint,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundAckKey, true);
    if (mounted) setState(() => _backgroundRisk = false);
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = (prefs.getInt(_selectedKey) ?? 90).clamp(30, 600);
    final paused = prefs.getInt(_pausedKey);
    final wasFinished = prefs.getBool(_finishedKey) ?? false;
    final savedMode = prefs.getString(_alertModeKey);
    final alertMode = RestTimerAlertMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => RestTimerAlertMode.ringAndVibrate,
    );
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
        _alertMode = alertMode;
        _restoring = false;
      });
      _startTicker();
    } else {
      if (deadlineMs != null) await prefs.remove(_deadlineKey);
      if (deadlineMs != null) await prefs.setBool(_finishedKey, true);
      if (!mounted) return;
      setState(() {
        _selectedSeconds = selected;
        _remainingSeconds = deadlineMs != null || wasFinished
            ? 0
            : paused?.clamp(1, 600) ?? selected;
        _totalSeconds = math.max(selected, _remainingSeconds);
        _paused = deadlineMs == null && !wasFinished && paused != null;
        _finished = deadlineMs != null || wasFinished;
        _alertMode = alertMode;
        _restoring = false;
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
    if (state == AppLifecycleState.resumed) {
      _syncFromDeadline();
      unawaited(_refreshAlertStatus());
      unawaited(_checkAlarmDelay());
      _showPendingSettingsHint();
    }
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
    if (_running || _starting || _restoring) return;
    setState(() => _starting = true);
    try {
      final seconds = (resume ? _remainingSeconds : _selectedSeconds).clamp(
        1,
        600,
      );
      final l10n = context.l10n;

      bool permissionGranted;
      try {
        permissionGranted = await RestTimerNotifications.requestPermissions();
      } catch (_) {
        permissionGranted = false;
      }
      if (!mounted) return;
      if (!permissionGranted && !_permissionHintShown) {
        _permissionHintShown = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.restNotifyPermissionHint)));
      } else if (_backgroundRisk && !_backgroundHintShown) {
        _backgroundHintShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.restTimerBackgroundSnack),
            action: SnackBarAction(
              label: l10n.reminderOemHintAutostartButton,
              onPressed: _openBackgroundSettings,
            ),
          ),
        );
      }

      final deadline = DateTime.now().add(Duration(seconds: seconds));
      setState(() {
        _running = true;
        _paused = false;
        _finished = false;
        _remainingSeconds = seconds;
        _totalSeconds = seconds;
        _endsAt = deadline;
        _scheduleFailed = false;
      });
      _startTicker();
      await _persist();
      try {
        await _scheduleAlert(deadline, _alertMode, l10n);
      } catch (_) {
        if (mounted) setState(() => _scheduleFailed = true);
      }
      unawaited(_refreshAlertStatus());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
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
    if (defaultTargetPlatform != TargetPlatform.android ||
        _alertMode.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _setAlertMode(RestTimerAlertMode mode) async {
    if (_modeChanging || _alertMode == mode) return;
    setState(() {
      _modeChanging = true;
      _alertMode = mode;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alertModeKey, mode.name);
      if (!mounted) return;
      final deadline = _endsAt;
      if (!_running || deadline == null) return;
      try {
        await _scheduleAlert(deadline, mode, context.l10n);
        if (mounted) setState(() => _scheduleFailed = false);
      } catch (_) {
        if (mounted) setState(() => _scheduleFailed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _scheduleFailed = true);
    } finally {
      if (mounted) setState(() => _modeChanging = false);
    }
  }

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// What may keep the lock-screen alert from firing. Shown in the settings
  /// sheet; the settings icon carries a dot while any remain.
  List<RestrictionIssue> _issues(AppLocalizations l10n) => [
    if (!_notificationsAllowed)
      RestrictionIssue(
        glyph: InkGlyph.notificationsOff,
        title: l10n.notificationPermissionRow,
        detail: l10n.restTimerNotificationMissing,
        action: l10n.reminderOpenNotifications,
        blocking: true,
        onAction: RestTimerNotifications.requestPermissions,
      ),
    if (!_exactAlarmAllowed)
      RestrictionIssue(
        glyph: InkGlyph.alarm,
        title: l10n.alarmAccessTitle,
        detail: l10n.restTimerExactAlarmMissing,
        action: l10n.reminderOpenExact,
        onAction: RestTimerNotifications.requestPermissions,
      ),
    if (_android && _backgroundRisk)
      RestrictionIssue(
        glyph: InkGlyph.battery,
        title: l10n.restTimerBackgroundTitle,
        detail: l10n.restTimerBackgroundDetail,
        action: l10n.reminderOemHintAutostartButton,
        blocking: true,
        onAction: _openBackgroundSettings,
      ),
    if (_scheduleFailed)
      RestrictionIssue(
        glyph: InkGlyph.info,
        title: l10n.reminderScheduleFailedTitle,
        detail: l10n.restTimerScheduleFailed,
        action: l10n.reminderRetrySchedule,
        blocking: true,
        onAction: _retrySchedule,
      ),
  ];

  /// [l10n] is read by the caller before any await, so a start begun on
  /// this page still schedules after the page is left.
  Future<void> _scheduleAlert(
    DateTime deadline,
    RestTimerAlertMode mode,
    AppLocalizations l10n,
  ) {
    return RestTimerNotifications.scheduleRestEnd(
      deadline,
      title: l10n.restDoneTitle,
      body: l10n.restDoneBody,
      dismissLabel: l10n.restTimerDismiss,
      soundEnabled: mode.soundEnabled,
      vibrationEnabled: mode.vibrationEnabled,
      countdownTitle: l10n.restTimerRunning,
    );
  }

  Future<void> _retrySchedule() async {
    final l10n = context.l10n;
    final deadline = _endsAt;
    if (!_running || deadline == null) {
      setState(() => _scheduleFailed = false);
      return;
    }
    try {
      await _scheduleAlert(deadline, _alertMode, l10n);
      if (mounted) setState(() => _scheduleFailed = false);
    } catch (_) {
      if (mounted) setState(() => _scheduleFailed = true);
    }
  }

  Future<void> _runIssueAction(
    BuildContext sheetContext,
    Future<void> Function() action,
  ) async {
    Navigator.pop(sheetContext);
    try {
      await action();
    } catch (_) {
      // The issue stays listed when the action could not fix it.
    } finally {
      if (mounted) await _refreshAlertStatus();
    }
  }

  void _showAlertSettings() {
    final l10n = context.l10n;
    final issues = _issues(l10n);
    showModalBottomSheet<void>(
      context: context,
      // Above the bottom tab bar, which would otherwise cover the actions.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      l10n.restTimerAlertSettings,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (_android)
                    for (final mode in RestTimerAlertMode.values)
                      ListTile(
                        leading: InkIcon(
                          mode == RestTimerAlertMode.vibrateOnly
                              ? InkGlyph.vibration
                              : InkGlyph.alarm,
                        ),
                        title: Text(switch (mode) {
                          RestTimerAlertMode.ringAndVibrate =>
                            l10n.restTimerAlertBoth,
                          RestTimerAlertMode.ringOnly =>
                            l10n.restTimerAlertRingOnly,
                          RestTimerAlertMode.vibrateOnly =>
                            l10n.restTimerAlertVibrateOnly,
                        }),
                        trailing: _alertMode == mode
                            ? const InkIcon(InkGlyph.check)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          unawaited(_setAlertMode(mode));
                        },
                      ),
                  if (issues.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.reminderRestrictionsSheetTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    for (final issue in issues)
                      RestrictionIssueRow(
                        issue: issue,
                        onAction: () =>
                            _runIssueAction(sheetContext, issue.onAction),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    _ticker = null;
    await RestTimerNotifications.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() {
      _running = false;
      _paused = false;
      _finished = false;
      _remainingSeconds = _selectedSeconds;
      _totalSeconds = _selectedSeconds;
      _endsAt = null;
      _scheduleFailed = false;
    });
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedKey, _selectedSeconds);
    await prefs.setBool(_finishedKey, _finished);
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

    final scheme = theme.colorScheme;
    final hasIssue = _issues(l10n).isNotEmpty;
    final statusLabel = _running
        ? l10n.restTimerRunning
        : _paused
        ? l10n.restTimerPaused
        : _finished
        ? l10n.restTimerFinished
        : l10n.toolRestTimer;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.toolRestTimer),
        actions: [
          if (_android || hasIssue)
            IconButton(
              key: const ValueKey('rest-timer-settings'),
              tooltip: l10n.restTimerAlertSettings,
              onPressed: _restoring || _starting || _modeChanging
                  ? null
                  : _showAlertSettings,
              icon: Badge(
                isLabelVisible: hasIssue,
                smallSize: 8,
                backgroundColor: AppColors.warning,
                child: const InkIcon(InkGlyph.settings),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.formPage),
          children: [
            const SizedBox(height: 24),
            Center(
              child: SizedBox.square(
                dimension: 248,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress.toDouble(),
                    track: scheme.surfaceContainerHighest,
                    fill: scheme.primary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _format(display),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (!_running && !_paused)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final seconds in _presets)
                    _PresetChip(
                      label: _presetLabel(seconds),
                      selected: _selectedSeconds == seconds,
                      onTap: () {
                        setState(() {
                          _selectedSeconds = seconds;
                          _remainingSeconds = seconds;
                          _totalSeconds = seconds;
                          _finished = false;
                        });
                        unawaited(_persist());
                      },
                    ),
                ],
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restoring || _starting || _modeChanging
                    ? null
                    : _running
                    ? _pause
                    : () => _start(resume: _paused),
                icon: InkIcon(_running ? InkGlyph.pause : InkGlyph.play),
                label: Text(
                  _running
                      ? l10n.restTimerPause
                      : _paused
                      ? l10n.restTimerResume
                      : l10n.start,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _restoring || _starting || _modeChanging
                    ? null
                    : _reset,
                icon: const InkIcon(InkGlyph.replay),
                label: Text(l10n.reset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded-cap progress ring for the rest timer.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - stroke / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, base);
    if (progress > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fill != fill || old.track != track;
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
