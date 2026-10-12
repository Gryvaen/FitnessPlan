import '../../l10n/app_localizations.dart';

extension ReminderStatusLabels on AppLocalizations {
  bool get _zh => localeName.startsWith('zh');
  String get alarmAccessTitle => _zh ? '精确闹钟' : 'Exact alarms';
  String get exactAlarmMissing => _zh
      ? '未允许精确闹钟，提醒仍会安排，但可能晚于设定时间。'
      : 'Without exact alarms, reminders are scheduled but may arrive late.';
  String get fullScreenAlarmTitle => _zh ? '锁屏弹出提醒' : 'Lock screen alerts';
  String get fullScreenAlarmMissing => _zh
      ? '锁屏时可能不会弹出提醒页面，仍可从通知中查看和关闭。'
      : 'The alert may not open over the lock screen. You can still use its notification.';
  String get notificationPermissionMissing => _zh
      ? '通知已关闭，到点时可能无法显示提醒。'
      : 'Notifications are off, so scheduled alerts may not appear.';
  String get reminderLimitBlocking =>
      _zh ? '提醒可能收不到' : 'Reminders may not arrive';
  String get reminderLimitDelayed => _zh
      ? '提醒可能延迟或不在锁屏弹出'
      : 'Reminders may be late or hidden on the lock screen';
  String reminderLimitCount(int count) =>
      _zh ? '$count 项待检查' : '$count to check';
  String get reminderStatusTitle => _zh ? '提醒状态' : 'Reminder status';
  String reminderStatusReady(int count) =>
      _zh ? '已安排 $count 个提醒' : '$count reminders scheduled';
  String get reminderLimitSheetIntro => _zh
      ? '逐项检查下面的设置，处理后状态会自动更新。'
      : 'Check each setting below. Status updates when you return.';
  String get reminderOpenNotifications =>
      _zh ? '设置通知权限' : 'Set notification access';
  String get reminderOpenExact => _zh ? '允许精确闹钟' : 'Allow exact alarms';
  String get reminderOpenFullScreen =>
      _zh ? '设置锁屏弹出' : 'Set lock screen alerts';
  String get reminderRetrySchedule => _zh ? '重新安排提醒' : 'Schedule again';
  String get reminderScheduleUnknownTitle =>
      _zh ? '尚未确认排程结果' : 'Schedule not confirmed';
  String get reminderScheduleFailedTitle =>
      _zh ? '部分提醒安排失败' : 'Some reminders were not scheduled';
  String get reminderBatteryTitle =>
      _zh ? '后台运行可能受限' : 'Background activity may be limited';
  String get reminderBatteryDetail => _zh
      ? '这台手机可能会拦截后台提醒。请检查电池优化与自启动设置。'
      : 'This phone may block background alerts. Check battery and auto-start settings.';
  String get reminderAutoStartAppDetailsHint => _zh
      ? '已打开应用信息。可进入「应用的电池使用情况」查看「允许后台使用」；此设备可能没有单独的自启动开关。'
      : 'App info opened. Check Battery usage for background access. This device may not have a separate Auto-start switch.';
  String get reminderAutoStartBatteryHint => _zh
      ? '请查看「允许后台使用」；如果已经开启，无需更改。'
      : 'Check Allow background usage. If it is already on, no change is needed.';
  String get reminderAutoStartManualHint => _zh
      ? '无法打开设置。请到「设置 > 应用 > 健身计划 > 应用的电池使用情况」查看「允许后台使用」。'
      : 'Could not open settings. Go to Settings > Apps > Fitness Plan > App battery usage and check background access.';
  String get reminderBehaviorTitle => _zh ? '提醒如何工作' : 'How reminders work';
  String get reminderPowerOffNote => _zh
      ? '手机完全关机时无法响铃；开机后，原定时间过去不超过一小时的提醒会补发。'
      : 'A powered-off phone cannot alert. Reminders missed by less than an hour are delivered after reboot.';
  String get reminderBackgroundNote => _zh
      ? '系统强行停止应用或厂商限制后台运行时，提醒可能无法送达。'
      : 'Force-stopping the app or restricting background activity may prevent delivery.';
  String get reminderScheduleFailed => _zh
      ? '部分提醒没有安排到系统闹钟，请重新安排。'
      : 'Some reminders were not added to Android alarms. Schedule again.';
  String get reminderScheduleTitle => _zh ? '系统闹钟排程' : 'Alarm scheduling';
  String get reminderScheduleUnknown => _zh
      ? '无法确认系统闹钟是否已安排，请重新安排。'
      : 'Could not confirm whether Android scheduled the reminders. Schedule again.';
  String reminderScheduleReady(int count) => _zh
      ? '已向系统安排 $count 个提醒；实际送达仍受设备设置影响。'
      : '$count reminders scheduled with Android; delivery still depends on device settings.';
}
