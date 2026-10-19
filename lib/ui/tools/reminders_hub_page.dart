import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/reminders_repository.dart';
import '../../data/services/oem_background_guide.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/folded_notes.dart';
import 'workout_reminder_notifications.dart';
import 'reminder_status_labels.dart';
import 'restriction_issue_row.dart';

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
  bool? _backgroundRestricted;
  List<DateTime> _missed = const [];
  bool _backgroundGuide = false;
  String? _autoStartGuidance;
  String? _pendingAutoStartFeedback;
  ({int scheduled, int failed})? _scheduleStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
    _refreshBackgroundStatus();
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
      _refreshBackgroundStatus();
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

  Future<void> _refreshBackgroundStatus() async {
    final restricted = await ReminderNotifications.isBackgroundRestricted();
    final missed = await ReminderNotifications.missedReminders();
    final aggressive = await ReminderNotifications.isAggressiveOem();
    final prefs = ref.read(sharedPreferencesProvider);
    // A missed reminder proves the earlier settings visit did not stick.
    if (missed.isNotEmpty) await OemBackgroundGuide.reset(prefs);
    if (!mounted) return;
    setState(() {
      _backgroundRestricted = restricted;
      _missed = missed;
      _backgroundGuide = aggressive && !OemBackgroundGuide.acknowledged(prefs);
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
    // The brand alone is not listed as a pending issue (no API can confirm
    // the restriction), so nudge once at the moment it matters instead.
    if (wantOn && _backgroundGuide && mounted) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.reminderBackgroundGuideSnack),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: l10n.reminderOemHintAutostartButton,
              onPressed: _thenRefresh(_openBackgroundSettings),
            ),
          ),
        );
    }
  }

  /// Opens auto-start / app details and counts the visit as done.
  Future<void> _openBackgroundSettings() async {
    await _openAutoStartSettings();
    await OemBackgroundGuide.acknowledge(ref.read(sharedPreferencesProvider));
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

  Future<void> _setAlertMode(ReminderAlertMode mode) async {
    await ref.read(remindersProvider.notifier).setAlertModeAll(mode);
    await _refreshPermission();
  }

  Future<void> _pickSound() async {
    await ref.read(remindersProvider.notifier).pickAndSetSharedSound();
    await _refreshPermission();
  }

  Future<void> _editContent(ReminderKind kind) async {
    final setting = ref.read(remindersProvider.notifier).settingFor(kind);
    final result = await showModalBottomSheet<({String title, String body})>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _ContentSheet(title: _label(kind, context.l10n), setting: setting),
    );
    if (result == null || !mounted) return;
    await ref
        .read(remindersProvider.notifier)
        .setNotificationContent(kind, title: result.title, body: result.body);
    if (mounted) await _refreshPermission();
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

  /// Re-checks every status once [action] finishes, so a permission granted
  /// from an in-app dialog shows up even when no resume event follows.
  Future<void> Function() _thenRefresh(FutureOr<void> Function() action) {
    return () async {
      try {
        await action();
      } finally {
        if (mounted) {
          await _refreshPermission();
          await _refreshBackgroundStatus();
        }
      }
    };
  }

  List<RestrictionIssue> _restrictionIssues(
    AppLocalizations l10n, {
    required bool enabled,
    required bool android,
  }) {
    final issues = <RestrictionIssue>[];
    if (android && _missed.isNotEmpty) {
      // `isBackgroundRestricted` cannot see ColorOS auto-start blocking; a
      // reminder that never fired (or fired late) is the only reliable sign.
      final format = DateFormat.Md(l10n.localeName).add_Hm();
      final times = [
        for (final t in _missed.reversed.take(3)) format.format(t),
      ].join(l10n.localeName.startsWith('zh') ? '、' : ', ');
      issues.add(
        RestrictionIssue(
          glyph: InkGlyph.batteryAlert,
          title: l10n.reminderMissedTitle,
          detail: l10n.reminderMissedDetail(times),
          action: l10n.reminderOemHintAutostartButton,
          blocking: true,
          onAction: _thenRefresh(() async {
            await _openBackgroundSettings();
            await ReminderNotifications.acknowledgeMissedReminders();
          }),
        ),
      );
    }

    if (_granted == false) {
      issues.add(
        RestrictionIssue(
          glyph: InkGlyph.notificationsOff,
          title: l10n.notificationPermissionRow,
          detail: l10n.notificationPermissionMissing,
          action: l10n.reminderOpenNotifications,
          blocking: true,
          onAction: _thenRefresh(
            ReminderNotifications.requestNotificationPermission,
          ),
        ),
      );
    }
    if (android && !_exact) {
      issues.add(
        RestrictionIssue(
          glyph: InkGlyph.alarm,
          title: l10n.alarmAccessTitle,
          detail: l10n.exactAlarmMissing,
          action: l10n.reminderOpenExact,
          onAction: _thenRefresh(
            ReminderNotifications.requestExactAlarmPermission,
          ),
        ),
      );
    }
    if (android && !_fullScreen) {
      issues.add(
        RestrictionIssue(
          glyph: InkGlyph.alarm,
          title: l10n.fullScreenAlarmTitle,
          detail: l10n.fullScreenAlarmMissing,
          action: l10n.reminderOpenFullScreen,
          onAction: _thenRefresh(
            ReminderNotifications.requestFullScreenPermission,
          ),
        ),
      );
    }
    if (android &&
        enabled &&
        (_scheduleStatus == null ||
            _scheduleStatus!.failed > 0 ||
            _scheduleStatus!.scheduled == 0)) {
      issues.add(
        RestrictionIssue(
          glyph: InkGlyph.info,
          title: _scheduleStatus == null
              ? l10n.reminderScheduleUnknownTitle
              : l10n.reminderScheduleFailedTitle,
          detail: _scheduleStatus == null
              ? l10n.reminderScheduleUnknown
              : l10n.reminderScheduleFailed,
          action: l10n.reminderRetrySchedule,
          blocking: true,
          onAction: _thenRefresh(
            () => ref.read(remindersProvider.notifier).syncSchedule(),
          ),
        ),
      );
    }
    if (android && _backgroundRestricted == true) {
      issues.add(
        RestrictionIssue(
          glyph: InkGlyph.batteryAlert,
          title: l10n.reminderBatteryTitle,
          detail: l10n.reminderBatteryDetail,
          blocking: true,
          action: l10n.reminderOemHintAutostartButton,
          onAction: _openAutoStartSettings,
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
          AutoStartSettingsDestination.colorOsAppDetails =>
            context.l10n.reminderAutoStartColorOsHint,
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
        await _refreshBackgroundStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(remindersProvider);
    final enabled = settings.values.any((s) => s.enabled);
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final issues = _restrictionIssues(l10n, enabled: enabled, android: android);
    final hasIssue = issues.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminders),
        actions: [
          IconButton(
            key: const ValueKey('reminders-settings'),
            tooltip: l10n.reminderSettingsTitle,
            onPressed: () => _showSettings(issues),
            icon: Badge(
              isLabelVisible: hasIssue,
              smallSize: 8,
              backgroundColor: AppColors.warning,
              child: const InkIcon(InkGlyph.settings),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
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

  /// Same layout as the rest timer's alert settings: a warning dot on the
  /// gear flags issues, and the sheet lists them with their fixes.
  void _showSettings(List<RestrictionIssue> issues) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      // Above the bottom tab bar, which would otherwise cover the actions.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, ref, _) {
          final theme = Theme.of(sheetContext);
          final muted = theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
          final settings = ref.watch(remindersProvider);
          final shared = ref.read(remindersProvider.notifier).sharedAlert;
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
                        l10n.reminderSettingsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    // Problems first: they are why the dot is on the gear.
                    if (issues.isEmpty)
                      ListTile(
                        leading: const InkIcon(
                          InkGlyph.check,
                          color: AppColors.success,
                        ),
                        title: Text(l10n.reminderPermissionsOk),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.reminderRestrictionsSheetTitle,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(l10n.reminderLimitSheetIntro, style: muted),
                            if (_autoStartGuidance != null) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(_autoStartGuidance!, style: muted),
                            ],
                          ],
                        ),
                      ),
                      for (final issue in issues)
                        RestrictionIssueRow(
                          issue: issue,
                          onAction: () => _runRestrictionAction(
                            sheetContext,
                            issue.onAction,
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    for (final mode in ReminderAlertMode.values)
                      ListTile(
                        key: ValueKey('reminder-alert-${mode.name}'),
                        leading: InkIcon(
                          mode == ReminderAlertMode.vibrate
                              ? InkGlyph.vibration
                              : InkGlyph.alarm,
                        ),
                        title: Text(switch (mode) {
                          ReminderAlertMode.ring => l10n.reminderAlertModeRing,
                          ReminderAlertMode.vibrate =>
                            l10n.reminderAlertModeVibrate,
                        }),
                        trailing: shared.alertMode == mode
                            ? const InkIcon(InkGlyph.check)
                            : null,
                        onTap: () => unawaited(_setAlertMode(mode)),
                      ),
                    if (shared.alertMode == ReminderAlertMode.ring)
                      ListTile(
                        key: const ValueKey('reminder-sound'),
                        leading: const InkIcon(InkGlyph.music),
                        title: Text(l10n.reminderSoundLabel),
                        trailing: _TrailingValue(
                          shared.soundTitle ?? l10n.reminderSoundDefault,
                        ),
                        onTap: () => unawaited(_pickSound()),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.reminderContentLabel,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    for (final kind in ReminderKind.values)
                      ListTile(
                        key: ValueKey('reminder-content-${kind.name}'),
                        leading: InkIcon(_icon(kind), color: _iconColor(kind)),
                        title: Text(_label(kind, l10n)),
                        trailing: _TrailingValue(
                          settings[kind]?.customTitle != null ||
                                  settings[kind]?.customBody != null
                              ? l10n.reminderContentCustom
                              : l10n.reminderContentDefault,
                        ),
                        onTap: () => unawaited(_editContent(kind)),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: FoldedNotes(
                        title: l10n.reminderBehaviorTitle,
                        notes: [
                          l10n.reminderPowerOffNote,
                          l10n.reminderBackgroundNote,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Muted value + chevron, the trailing of a settings row that opens a picker.
class _TrailingValue extends StatelessWidget {
  const _TrailingValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          InkIcon(InkGlyph.chevronRight, size: 18, color: muted),
        ],
      ),
    );
  }
}

/// Bottom sheet editing one kind's custom notification title/body; empty
/// fields fall back to the default copy. Pops `(title, body)` on save, null
/// on cancel.
class _ContentSheet extends StatefulWidget {
  const _ContentSheet({required this.title, required this.setting});

  final String title;
  final ReminderSetting setting;

  @override
  State<_ContentSheet> createState() => _ContentSheetState();
}

class _ContentSheetState extends State<_ContentSheet> {
  late final _title = TextEditingController(text: widget.setting.customTitle);
  late final _body = TextEditingController(text: widget.setting.customBody);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          32,
          0,
          32,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(widget.title, style: theme.textTheme.titleLarge),
            ),
            TextField(
              key: const ValueKey('reminder-content-title'),
              controller: _title,
              maxLength: 60,
              maxLines: 1,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.reminderContentTitleLabel,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('reminder-content-body'),
              controller: _body,
              maxLength: 240,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.reminderContentBodyLabel,
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.card),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.compact),
                FilledButton(
                  key: const ValueKey('reminder-content-save'),
                  onPressed: () => Navigator.pop(context, (
                    title: _title.text,
                    body: _body.text,
                  )),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ],
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
