import '../../l10n/app_localizations.dart';

extension ReminderStatusLabels on AppLocalizations {
  bool get _zh => localeName.startsWith('zh');
  String get alarmAccessTitle => _zh ? '闹钟权限' : 'Alarm permissions';
  String get exactAlarmMissing => _zh
      ? '未允许精确闹钟，提醒可能延迟。点按前往授权。'
      : 'Exact alarms are not allowed; reminders may be delayed. Tap to allow.';
  String get fullScreenAlarmMissing => _zh
      ? '未允许全屏提醒，锁屏时请从通知中关闭闹钟。点按前往授权。'
      : 'Full-screen alerts are not allowed. Dismiss from the notification, or tap to allow.';
  String get alarmBehaviorHint => _zh
      ? 'Android 提醒会持续响铃或振动，点按“关闭”停止，最多持续 10 分钟。响铃使用系统闹钟音量；OPPO 还需允许自启动和后台运行。'
      : 'Android reminders ring or vibrate until dismissed, for up to 10 minutes. Ringing uses alarm volume. On OPPO, also allow auto-start and background activity.';
}
