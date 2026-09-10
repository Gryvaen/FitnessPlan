import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reminders_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'workout_reminder_notifications.dart';

/// Reminder settings: an independent on/off + time + repeat-days for each
/// reminder kind, plus the notification-permission status (board 06.03).
class RemindersHubPage extends ConsumerStatefulWidget {
  const RemindersHubPage({super.key});

  @override
  ConsumerState<RemindersHubPage> createState() => _RemindersHubPageState();
}

class _RemindersHubPageState extends ConsumerState<RemindersHubPage> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final ok = await ReminderNotifications.permissionGranted();
    if (mounted) setState(() => _granted = ok);
  }

  Future<void> _toggle(ReminderKind kind, bool wantOn) async {
    if (wantOn && !(_granted ?? true)) {
      await ReminderNotifications.requestPermissions();
      await _refreshPermission();
    }
    // Save the choice regardless of the permission outcome; the reminders row
    // below tells the user if notifications still need allowing.
    await ref.read(remindersProvider.notifier).setEnabled(kind, wantOn);
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
  }

  void _toggleWeekday(ReminderKind kind, int weekday) {
    final s = ref.read(remindersProvider.notifier).settingFor(kind);
    final next = {...s.weekdays};
    if (!next.remove(weekday)) next.add(weekday);
    if (next.isEmpty) return; // keep at least one day
    ref.read(remindersProvider.notifier).setWeekdays(kind, next);
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

  IconData _icon(ReminderKind kind) => switch (kind) {
    ReminderKind.workout => Icons.fitness_center_outlined,
    ReminderKind.water => Icons.local_drink_outlined,
    ReminderKind.meal => Icons.restaurant_outlined,
    ReminderKind.weighIn => Icons.monitor_weight_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(remindersProvider);
    final granted = _granted ?? true;

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
          if (!granted)
            SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.notifications_off_outlined,
                color: theme.colorScheme.error,
              ),
              title: Text(l10n.notificationPermissionRow),
              subtitle: Text(
                l10n.notificationPermissionHint,
                style: theme.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await ReminderNotifications.requestPermissions();
                await _refreshPermission();
              },
            ),
          for (final kind in ReminderKind.values)
            _ReminderTile(
              icon: _icon(kind),
              label: _label(kind, l10n),
              description: _desc(kind, l10n),
              setting: settings[kind] ?? _fallback(kind),
              onToggle: (v) => _toggle(kind, v),
              onPickTime: () => _pickTime(kind),
              onToggleWeekday: (d) => _toggleWeekday(kind, d),
            ),
          if (granted) ...[
            const SizedBox(height: AppSpacing.section),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.notificationPermissionOn,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
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
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.setting,
    required this.onToggle,
    required this.onPickTime,
    required this.onToggleWeekday,
  });

  final IconData icon;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon),
          title: Text(label),
          subtitle: Text(
            setting.enabled ? l10n.reminderDailyAt(_timeText) : description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          value: setting.enabled,
          onChanged: onToggle,
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
                        const Icon(Icons.schedule_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n.reminderTimeLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(_timeText, style: theme.textTheme.bodyMedium),
                        const Icon(Icons.chevron_right, size: 18),
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
                const SizedBox(height: 10),
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
