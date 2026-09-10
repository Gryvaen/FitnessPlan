import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reminders_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'workout_reminder_notifications.dart';

/// Reminder settings: an independent on/off + time for each reminder kind,
/// plus the notification-permission status (board 06.03).
class RemindersHubPage extends ConsumerStatefulWidget {
  const RemindersHubPage({super.key});

  @override
  ConsumerState<RemindersHubPage> createState() => _RemindersHubPageState();
}

class _RemindersHubPageState extends ConsumerState<RemindersHubPage> {
  Future<bool>? _permission;

  @override
  void initState() {
    super.initState();
    _permission = ReminderNotifications.permissionGranted();
  }

  Future<void> _toggle(ReminderKind kind, bool wantOn) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (wantOn) {
      final ok = await ReminderNotifications.requestPermissions();
      if (!mounted) return;
      setState(() => _permission = ReminderNotifications.permissionGranted());
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.workoutReminderPermissionDenied)),
        );
        return;
      }
    }
    try {
      await ref.read(remindersProvider.notifier).setEnabled(kind, wantOn);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.workoutReminderPermissionDenied)),
      );
    }
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

  String _time(ReminderSetting s) =>
      '${s.hour.toString().padLeft(2, '0')}:'
      '${s.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(remindersProvider);

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
          for (final kind in ReminderKind.values)
            _ReminderTile(
              icon: _icon(kind),
              label: _label(kind, l10n),
              description: _desc(kind, l10n),
              setting: settings[kind]!,
              timeText: _time(settings[kind]!),
              onToggle: (v) => _toggle(kind, v),
              onPickTime: () => _pickTime(kind),
            ),
          const SizedBox(height: AppSpacing.section),
          FutureBuilder<bool>(
            future: _permission,
            builder: (context, snap) {
              final granted = snap.data ?? true;
              return SportListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  granted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                ),
                title: Text(l10n.notificationPermissionRow),
                subtitle: Text(
                  granted
                      ? l10n.notificationPermissionOn
                      : l10n.notificationPermissionHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: granted ? null : const Icon(Icons.chevron_right),
                onTap: granted
                    ? null
                    : () async {
                        await ReminderNotifications.requestPermissions();
                        if (!mounted) return;
                        setState(
                          () => _permission =
                              ReminderNotifications.permissionGranted(),
                        );
                      },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.setting,
    required this.timeText,
    required this.onToggle,
    required this.onPickTime,
  });

  final IconData icon;
  final String label;
  final String description;
  final ReminderSetting setting;
  final String timeText;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon),
          title: Text(label),
          subtitle: Text(
            setting.enabled ? l10n.reminderDailyAt(timeText) : description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          value: setting.enabled,
          onChanged: onToggle,
        ),
        if (setting.enabled)
          SportListTile(
            contentPadding: const EdgeInsets.only(left: 40),
            leading: const Icon(Icons.schedule_outlined, size: 20),
            title: Text(timeText),
            trailing: const Icon(Icons.chevron_right),
            onTap: onPickTime,
          ),
      ],
    );
  }
}
