import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'workout_reminder_notifications.dart';

/// Hub for reminder settings (daily workout, etc.).
class RemindersHubPage extends ConsumerWidget {
  const RemindersHubPage({super.key});

  Future<void> _onWorkoutToggle(WidgetRef ref, BuildContext context, bool wantOn) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (wantOn) {
      final ok = await WorkoutReminderNotifications.requestPermissions();
      if (!context.mounted) return;
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.workoutReminderPermissionDenied)),
        );
        return;
      }
    }
    await ref.read(workoutReminderProvider.notifier).setEnabled(wantOn);
  }

  Future<void> _pickWorkoutTime(WidgetRef ref, BuildContext context) async {
    final current = ref.read(workoutReminderProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null || !context.mounted) return;
    await ref
        .read(workoutReminderProvider.notifier)
        .setTime(hour: picked.hour, minute: picked.minute);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reminder = ref.watch(workoutReminderProvider);
    final timeLabel = _formatTime(
      TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminders)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fitness_center_outlined),
                  title: Text(l10n.workoutReminderTile),
                  subtitle: Text(
                    reminder.enabled
                        ? l10n.workoutReminderSubtitleOn(timeLabel)
                        : l10n.workoutReminderSubtitleOff,
                    style: theme.textTheme.meta,
                  ),
                  value: reminder.enabled,
                  onChanged: (v) => _onWorkoutToggle(ref, context, v),
                ),
                if (reminder.enabled)
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(timeLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickWorkoutTime(ref, context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
