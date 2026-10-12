import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reminders_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'workout_reminder_notifications.dart';
import 'reminder_status_labels.dart';

/// Reminder settings: an independent on/off + time + repeat-days for each
/// reminder kind, plus the notification-permission status (board 06.03).
class RemindersHubPage extends ConsumerStatefulWidget {
  const RemindersHubPage({super.key});

  @override
  ConsumerState<RemindersHubPage> createState() => _RemindersHubPageState();
}

class _RemindersHubPageState extends ConsumerState<RemindersHubPage>
    with WidgetsBindingObserver {
  bool? _granted;
  bool _exact = true;
  bool _fullScreen = true;
  bool _showOemHint = false;
  bool _ignoringBatteryOpt = true;
  String? _autoStartGuidance;
  String? _pendingAutoStartFeedback;
  ({int scheduled, int failed})? _scheduleStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
    _refreshOemStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user typically flips these in a system settings screen and comes
    // straight back — re-check so the hint clears itself once granted.
    if (state == AppLifecycleState.resumed) {
      _showPendingAutoStartFeedback();
      _refreshOemStatus();
      _refreshPermission();
    }
  }

  void _showPendingAutoStartFeedback() {
    final message = _pendingAutoStartFeedback;
    if (!mounted || message == null) return;
    _pendingAutoStartFeedback = null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshPermission() async {
    final ok = await ReminderNotifications.permissionGranted();
    final status = await ReminderNotifications.alarmStatus();
    final schedule = await ReminderNotifications.scheduleStatus();
    if (!mounted) return;
    final newlyGranted = (!_exact && status.exact) || (_granted == false && ok);
    setState(() {
      _granted = ok;
      _exact = status.exact;
      _fullScreen = status.fullScreen;
      _scheduleStatus = schedule;
    });
    if (newlyGranted) {
      try {
        await ref.read(remindersProvider.notifier).syncSchedule();
      } catch (e) {
        debugPrint('reminder sync failed: $e');
      } finally {
        final refreshed = await ReminderNotifications.scheduleStatus();
        if (mounted) setState(() => _scheduleStatus = refreshed);
      }
    }
  }

  Future<void> _refreshOemStatus() async {
    final aggressive = await ReminderNotifications.isAggressiveOem();
    final ignoring =
        await ReminderNotifications.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _showOemHint = aggressive;
      _ignoringBatteryOpt = ignoring;
    });
  }

  Future<void> _toggle(ReminderKind kind, bool wantOn) async {
    if (wantOn && (!(_granted ?? false) || !_exact || !_fullScreen)) {
      await ReminderNotifications.requestPermissions();
      await _refreshPermission();
    }
    // Save the choice regardless of the permission outcome; the reminders row
    // below tells the user if notifications still need allowing.
    await ref.read(remindersProvider.notifier).setEnabled(kind, wantOn);
    await _refreshPermission();
  }

  Future<void> _pickTime(ReminderKind kind) async {
    final s = ref.read(remindersProvider.notifier).settingFor(kind);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(remindersProvider.notifier)
        .setTime(kind, hour: picked.hour, minute: picked.minute);
    await _refreshPermission();
  }

  Future<void> _toggleWeekday(ReminderKind kind, int weekday) async {
    final s = ref.read(remindersProvider.notifier).settingFor(kind);
    final next = {...s.weekdays};
    if (!next.remove(weekday)) next.add(weekday);
    if (next.isEmpty) return; // keep at least one day
    await ref.read(remindersProvider.notifier).setWeekdays(kind, next);
    await _refreshPermission();
  }

  Future<void> _setAlertMode(ReminderKind kind, ReminderAlertMode mode) async {
    await ref.read(remindersProvider.notifier).setAlertMode(kind, mode);
    await _refreshPermission();
  }

  Future<void> _pickSound(ReminderKind kind) async {
    await ref.read(remindersProvider.notifier).pickAndSetSound(kind);
    await _refreshPermission();
  }

  String _label(ReminderKind kind, AppLocalizations l10n) => switch (kind) {
    ReminderKind.workout => l10n.reminderKindWorkout,
    ReminderKind.water => l10n.reminderKindWater,
    ReminderKind.meal => l10n.reminderKindMeal,
    ReminderKind.weighIn => l10n.reminderKindWeighIn,
  };

  String _desc(ReminderKind kind, AppLocalizations l10n) => switch (kind) {
    ReminderKind.workout => l10n.reminderKindWorkoutDesc,
    ReminderKind.water => l10n.reminderKindWaterDesc,
    ReminderKind.meal => l10n.reminderKindMealDesc,
    ReminderKind.weighIn => l10n.reminderKindWeighInDesc,
  };

  InkGlyph _icon(ReminderKind kind) => switch (kind) {
    ReminderKind.workout => InkGlyph.training,
    ReminderKind.water => InkGlyph.water,
    ReminderKind.meal => InkGlyph.food,
    ReminderKind.weighIn => InkGlyph.weight,
  };

  Color _iconColor(ReminderKind kind) => switch (kind) {
    ReminderKind.workout => AppColors.protein,
    ReminderKind.water => AppColors.water,
    ReminderKind.meal => AppColors.carb,
    ReminderKind.weighIn => AppColors.fat,
  };

  List<_RestrictionIssue> _restrictionIssues(
    AppLocalizations l10n, {
    required bool enabled,
    required bool android,
  }) {
    final issues = <_RestrictionIssue>[];
    if (_granted == false) {
      issues.add(
        _RestrictionIssue(
          glyph: InkGlyph.notificationsOff,
          title: l10n.notificationPermissionRow,
          detail: l10n.notificationPermissionMissing,
          action: l10n.reminderOpenNotifications,
          blocking: true,
          onAction: ReminderNotifications.requestNotificationPermission,
        ),
      );
    }
    if (android && !_exact) {
      issues.add(
        _RestrictionIssue(
          glyph: InkGlyph.alarm,
          title: l10n.alarmAccessTitle,
          detail: l10n.exactAlarmMissing,
          action: l10n.reminderOpenExact,
          onAction: ReminderNotifications.requestExactAlarmPermission,
        ),
      );
    }
    if (android && !_fullScreen) {
      issues.add(
        _RestrictionIssue(
          glyph: InkGlyph.alarm,
          title: l10n.fullScreenAlarmTitle,
          detail: l10n.fullScreenAlarmMissing,
          action: l10n.reminderOpenFullScreen,
          onAction: ReminderNotifications.requestFullScreenPermission,
        ),
      );
    }
    if (android &&
        enabled &&
        (_scheduleStatus == null ||
            _scheduleStatus!.failed > 0 ||
            _scheduleStatus!.scheduled == 0)) {
      issues.add(
        _RestrictionIssue(
          glyph: InkGlyph.info,
          title: _scheduleStatus == null
              ? l10n.reminderScheduleUnknownTitle
              : l10n.reminderScheduleFailedTitle,
          detail: _scheduleStatus == null
              ? l10n.reminderScheduleUnknown
              : l10n.reminderScheduleFailed,
          action: l10n.reminderRetrySchedule,
          blocking: true,
          onAction: () => ref.read(remindersProvider.notifier).syncSchedule(),
        ),
      );
    }
    if (android && _showOemHint) {
      issues.add(
        _RestrictionIssue(
          glyph: InkGlyph.batteryAlert,
          title: l10n.reminderBatteryTitle,
          detail: l10n.reminderBatteryDetail,
          action: _ignoringBatteryOpt
              ? l10n.reminderOemHintAutostartButton
              : l10n.reminderOemHintBatteryButton,
          onAction: _ignoringBatteryOpt
              ? _openAutoStartSettings
              : ReminderNotifications.requestIgnoreBatteryOptimizations,
          secondaryAction: _ignoringBatteryOpt
              ? null
              : l10n.reminderOemHintAutostartButton,
          onSecondaryAction: _ignoringBatteryOpt
              ? null
              : _openAutoStartSettings,
        ),
      );
    }
    return issues;
  }

  Future<void> _openAutoStartSettings() async {
    try {
      final destination = await ReminderNotifications.openAutoStartSettings();
      if (!mounted) return;
      setState(() {
        _autoStartGuidance = switch (destination) {
          AutoStartSettingsDestination.oem => null,
          AutoStartSettingsDestination.battery =>
            context.l10n.reminderAutoStartBatteryHint,
          AutoStartSettingsDestination.appDetails =>
            context.l10n.reminderAutoStartAppDetailsHint,
        };
      });
      _pendingAutoStartFeedback = null;
      if (_autoStartGuidance != null) {
        _pendingAutoStartFeedback = _autoStartGuidance;
      }
    } catch (e) {
      debugPrint('auto-start settings unavailable: $e');
      if (!mounted) return;
      setState(() {
        _autoStartGuidance = context.l10n.reminderAutoStartManualHint;
      });
      _pendingAutoStartFeedback = _autoStartGuidance;
      _showPendingAutoStartFeedback();
    }
  }

  Future<void> _runRestrictionAction(
    BuildContext sheetContext,
    Future<void> Function() action,
  ) async {
    Navigator.pop(sheetContext);
    try {
      await action();
    } catch (e) {
      debugPrint('reminder setting action failed: $e');
    } finally {
      if (mounted) {
        await _refreshPermission();
        await _refreshOemStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(remindersProvider);
    final remindersNotifier = ref.read(remindersProvider.notifier);
    final enabled = settings.values.any((s) => s.enabled);
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final issues = _restrictionIssues(l10n, enabled: enabled, android: android);
    final hasIssue = issues.isNotEmpty;
    final showStatus = hasIssue || enabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminders)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          if (showStatus)
            _ReminderStatusRow(
              title: hasIssue
                  ? (issues.any((issue) => issue.blocking)
                        ? l10n.reminderLimitBlocking
                        : l10n.reminderLimitDelayed)
                  : (android
                        ? l10n.reminderStatusReady(_scheduleStatus!.scheduled)
                        : l10n.notificationPermissionOn),
              subtitle: hasIssue
                  ? l10n.reminderLimitCount(issues.length)
                  : null,
              restricted: hasIssue,
              onTap: () => _showStatusDetails(
                issues,
                android: android,
                scheduled: _scheduleStatus?.scheduled ?? 0,
              ),
            ),
          for (final kind in ReminderKind.values)
            _ReminderTile(
              kind: kind,
              icon: _icon(kind),
              iconColor: _iconColor(kind),
              label: _label(kind, l10n),
              description: _desc(kind, l10n),
              setting: settings[kind] ?? _fallback(kind),
              onToggle: (v) => _toggle(kind, v),
              onPickTime: () => _pickTime(kind),
              onToggleWeekday: (d) => _toggleWeekday(kind, d),
              onSetAlertMode: (m) => _setAlertMode(kind, m),
              onPickSound: () => _pickSound(kind),
              onSetContent: (title, body) async {
                await remindersNotifier.setNotificationContent(
                  kind,
                  title: title,
                  body: body,
                );
                if (mounted) await _refreshPermission();
              },
            ),
        ],
      ),
    );
  }

  ReminderSetting _fallback(ReminderKind kind) => ReminderSetting(
    enabled: false,
    hour: kind.defaultTime.hour,
    minute: kind.defaultTime.minute,
    weekdays: const {1, 2, 3, 4, 5, 6, 7},
  );

  void _showStatusDetails(
    List<_RestrictionIssue> issues, {
    required bool android,
    required int scheduled,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasIssue = issues.isNotEmpty;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.formPage,
              0,
              AppSpacing.formPage,
              AppSpacing.section,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasIssue
                      ? l10n.reminderRestrictionsSheetTitle
                      : l10n.reminderStatusTitle,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  hasIssue
                      ? l10n.reminderLimitSheetIntro
                      : (android
                            ? l10n.reminderScheduleReady(scheduled)
                            : l10n.notificationPermissionOn),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_autoStartGuidance != null) ...[
                  const SizedBox(height: AppSpacing.compact),
                  Text(
                    _autoStartGuidance!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.card),
                for (final issue in issues)
                  _RestrictionIssueRow(
                    issue: issue,
                    onAction: () =>
                        _runRestrictionAction(sheetContext, issue.onAction),
                    onSecondaryAction: issue.onSecondaryAction == null
                        ? null
                        : () => _runRestrictionAction(
                            sheetContext,
                            issue.onSecondaryAction!,
                          ),
                  ),
                const SizedBox(height: AppSpacing.section),
                Text(
                  l10n.reminderBehaviorTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.compact),
                Text(
                  l10n.reminderPowerOffNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.compact),
                Text(
                  l10n.reminderBackgroundNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestrictionIssue {
  const _RestrictionIssue({
    required this.glyph,
    required this.title,
    required this.detail,
    required this.action,
    required this.onAction,
    this.blocking = false,
    this.secondaryAction,
    this.onSecondaryAction,
  });

  final InkGlyph glyph;
  final String title;
  final String detail;
  final String action;
  final Future<void> Function() onAction;
  final bool blocking;
  final String? secondaryAction;
  final Future<void> Function()? onSecondaryAction;
}

class _ReminderStatusRow extends StatelessWidget {
  const _ReminderStatusRow({
    required this.title,
    required this.subtitle,
    required this.restricted,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool restricted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            InkIcon(
              restricted ? InkGlyph.info : InkGlyph.check,
              size: 16,
              color: restricted ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(width: 4),
            InkIcon(
              InkGlyph.chevronRight,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RestrictionIssueRow extends StatelessWidget {
  const _RestrictionIssueRow({
    required this.issue,
    required this.onAction,
    this.onSecondaryAction,
  });

  final _RestrictionIssue issue;
  final VoidCallback onAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.card),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkIcon(issue.glyph, size: 20, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 5),
                Text(
                  issue.detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(onPressed: onAction, child: Text(issue.action)),
                    if (issue.secondaryAction != null)
                      TextButton(
                        onPressed: onSecondaryAction,
                        child: Text(issue.secondaryAction!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.kind,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.setting,
    required this.onToggle,
    required this.onPickTime,
    required this.onToggleWeekday,
    required this.onSetAlertMode,
    required this.onPickSound,
    required this.onSetContent,
  });

  final ReminderKind kind;
  final InkGlyph icon;
  final Color iconColor;
  final String label;
  final String description;
  final ReminderSetting setting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;
  final ValueChanged<int> onToggleWeekday;
  final ValueChanged<ReminderAlertMode> onSetAlertMode;
  final VoidCallback onPickSound;
  final Future<void> Function(String? title, String? body) onSetContent;

  String get _timeText =>
      '${setting.hour.toString().padLeft(2, '0')}:'
      '${setting.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final labels = l10n.weekdayLettersMonSun.split(',');
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SportListTile(
          contentPadding: EdgeInsets.zero,
          leading: InkIcon(icon, color: iconColor),
          title: Text(label),
          subtitle: Text(
            setting.enabled ? l10n.reminderDailyAt(_timeText) : description,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          trailing: InkToggle(
            value: setting.enabled,
            onChanged: onToggle,
            semanticLabel: label,
          ),
          onTap: () => onToggle(!setting.enabled),
        ),
        if (setting.enabled) ...[
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onPickTime,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        InkIcon(InkGlyph.schedule, size: 18, color: muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.reminderTimeLabel,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_timeText, style: theme.textTheme.bodyMedium),
                        InkIcon(InkGlyph.chevronRight, size: 18, color: muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.reminderRepeatLabel,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      _DayToggle(
                        letter: labels.length >= 7 ? labels[d - 1] : '$d',
                        on: setting.firesOn(d),
                        onTap: () => onToggleWeekday(d),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _AlertModeToggle(
                  mode: setting.alertMode,
                  onChanged: onSetAlertMode,
                ),
                if (setting.alertMode == ReminderAlertMode.ring)
                  InkWell(
                    onTap: onPickSound,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          InkIcon(InkGlyph.music, size: 18, color: muted),
                          const SizedBox(width: 8),
                          Text(
                            l10n.reminderSoundLabel,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              setting.soundTitle ?? l10n.reminderSoundDefault,
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          InkIcon(
                            InkGlyph.chevronRight,
                            size: 18,
                            color: muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                _NotificationContentEditor(
                  key: ValueKey('reminder-content-${kind.name}'),
                  kind: kind,
                  setting: setting,
                  onSave: onSetContent,
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationContentEditor extends StatefulWidget {
  const _NotificationContentEditor({
    super.key,
    required this.kind,
    required this.setting,
    required this.onSave,
  });

  final ReminderKind kind;
  final ReminderSetting setting;
  final Future<void> Function(String? title, String? body) onSave;

  @override
  State<_NotificationContentEditor> createState() =>
      _NotificationContentEditorState();
}

class _NotificationContentEditorState
    extends State<_NotificationContentEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final FocusNode _titleFocus;
  late final FocusNode _bodyFocus;
  Timer? _saveTimer;
  Future<void> _saveQueue = Future<void>.value();
  String? _lastSubmittedTitle;
  String? _lastSubmittedBody;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.setting.customTitle);
    _bodyController = TextEditingController(text: widget.setting.customBody);
    _titleFocus = FocusNode()..addListener(_onTitleFocusChanged);
    _bodyFocus = FocusNode()..addListener(_onBodyFocusChanged);
    _lastSubmittedTitle = widget.setting.customTitle;
    _lastSubmittedBody = widget.setting.customBody;
  }

  void _onTitleFocusChanged() {
    if (!_titleFocus.hasFocus) _queueSave();
  }

  void _onBodyFocusChanged() {
    if (!_bodyFocus.hasFocus) _queueSave();
  }

  void _onChanged(String _) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _queueSave);
  }

  void _queueSave() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final title = normalizeReminderContent(_titleController.text);
    final body = normalizeReminderContent(_bodyController.text);
    if (title == _lastSubmittedTitle && body == _lastSubmittedBody) return;
    _lastSubmittedTitle = title;
    _lastSubmittedBody = body;
    final save = widget.onSave;
    _saveQueue = _saveQueue
        .catchError((Object error) {
          debugPrint('reminder content save failed: $error');
        })
        .then((_) => save(title, body));
    unawaited(
      _saveQueue.catchError((Object error) {
        debugPrint('reminder content save failed: $error');
      }),
    );
  }

  void _toggleExpanded() {
    if (_expanded) {
      _queueSave();
      FocusScope.of(context).unfocus();
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  void dispose() {
    _queueSave();
    _saveTimer?.cancel();
    _titleFocus
      ..removeListener(_onTitleFocusChanged)
      ..dispose();
    _bodyFocus
      ..removeListener(_onBodyFocusChanged)
      ..dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.colorScheme.onSurfaceVariant;
    final custom =
        widget.setting.customTitle != null ||
        widget.setting.customBody != null ||
        normalizeReminderContent(_titleController.text) != null ||
        normalizeReminderContent(_bodyController.text) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                InkIcon(InkGlyph.notification, size: 18, color: muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.reminderContentLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  custom
                      ? l10n.reminderContentCustom
                      : l10n.reminderContentDefault,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(width: 6),
                InkIcon(
                  _expanded ? InkGlyph.collapse : InkGlyph.expand,
                  size: 18,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _titleController,
            focusNode: _titleFocus,
            maxLength: 60,
            maxLines: 1,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.reminderContentTitleLabel,
              counterText: '',
            ),
            onChanged: _onChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            focusNode: _bodyFocus,
            maxLength: 240,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: l10n.reminderContentBodyLabel,
              counterText: '',
            ),
            onChanged: _onChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reminderContentEmptyHint,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          if (widget.kind == ReminderKind.workout)
            Text(
              l10n.reminderContentWorkoutHint,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AlertModeToggle extends StatelessWidget {
  const _AlertModeToggle({required this.mode, required this.onChanged});

  final ReminderAlertMode mode;
  final ValueChanged<ReminderAlertMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _AlertModeButton(
              glyph: InkGlyph.notification,
              label: l10n.reminderAlertModeRing,
              selected: mode == ReminderAlertMode.ring,
              onTap: () => onChanged(ReminderAlertMode.ring),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AlertModeButton(
              glyph: InkGlyph.vibration,
              label: l10n.reminderAlertModeVibrate,
              selected: mode == ReminderAlertMode.vibrate,
              onTap: () => onChanged(ReminderAlertMode.vibrate),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertModeButton extends StatelessWidget {
  const _AlertModeButton({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final InkGlyph glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkIcon(
                glyph,
                size: 16,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.letter,
    required this.on,
    required this.onTap,
  });

  final String letter;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? scheme.primary : scheme.surfaceContainerHighest,
        ),
        child: Text(
          letter,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Nudges the user toward the OS-level settings screens ([ReminderNotifications]
/// can only *open*, never grant outright) a manufacturer known for aggressive
/// background restrictions needs before a reminder can reliably ring/vibrate.
