package com.fitnessplan.fitness_plan

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object RestTimerAlarmScheduler {
    const val CHANNEL = "fitness_plan/rest_timer_alarm"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"
    const val EXTRA_DISMISS_LABEL = "dismiss_label"
    const val EXTRA_SOUND_ENABLED = "sound_enabled"
    const val EXTRA_VIBRATION_ENABLED = "vibration_enabled"
    const val EXTRA_TRIGGER_AT = "trigger_at"
    private const val REQUEST_CODE = 71001
    private const val COUNTDOWN_NOTIFICATION_ID = 71004
    private const val COUNTDOWN_CHANNEL_ID = "rest_timer_countdown_v1"
    private const val PREFS = "rest_timer_alarm"
    private const val KEY_LAST_DELAY_MS = "last_delay_ms"

    /** Alarms later than this were held back by the system (e.g. ColorOS freezing the app). */
    private const val DELAY_THRESHOLD_MS = 5_000L

    fun schedule(
        context: Context,
        triggerAtMillis: Long,
        title: String,
        body: String,
        dismissLabel: String,
        soundEnabled: Boolean,
        vibrationEnabled: Boolean,
        countdownTitle: String,
    ) {
        cancel(context)
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val operation = alarmPendingIntent(
            context, title, body, dismissLabel, soundEnabled, vibrationEnabled, triggerAtMillis,
        )
        val showIntent = PendingIntent.getActivity(
            context,
            REQUEST_CODE,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent),
                operation,
            )
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAtMillis, operation,
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, operation)
            }
        }
        showCountdown(context, triggerAtMillis, countdownTitle, showIntent)
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)
            .cancel(alarmPendingIntent(context, "", "", "", true, true, 0L))
        context.stopService(Intent(context, RestTimerAlarmService::class.java))
        RestTimerFallbackNotification.cancel(context)
        cancelCountdown(context)
    }

    fun cancelCountdown(context: Context) {
        NotificationManagerCompat.from(context).cancel(COUNTDOWN_NOTIFICATION_ID)
    }

    /** Remembers how late the alarm arrived when the system held it back. */
    fun recordDelay(context: Context, intent: Intent) {
        val triggerAt = intent.getLongExtra(EXTRA_TRIGGER_AT, 0L)
        if (triggerAt <= 0L) return
        val delay = System.currentTimeMillis() - triggerAt
        if (delay < DELAY_THRESHOLD_MS) return
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putLong(KEY_LAST_DELAY_MS, delay).apply()
    }

    /** Returns and clears the last recorded delay, or null when none. */
    fun takeLastDelayMs(context: Context): Long? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.contains(KEY_LAST_DELAY_MS)) return null
        val delay = prefs.getLong(KEY_LAST_DELAY_MS, 0L)
        prefs.edit().remove(KEY_LAST_DELAY_MS).apply()
        return delay
    }

    /**
     * A silent ongoing notification whose countdown SystemUI draws itself, so
     * the remaining time stays visible even while the app process is frozen.
     * The system removes it at the deadline via [NotificationCompat.Builder.setTimeoutAfter].
     */
    private fun showCountdown(
        context: Context,
        triggerAtMillis: Long,
        title: String,
        contentIntent: PendingIntent,
    ) {
        val remaining = triggerAtMillis - System.currentTimeMillis()
        if (remaining <= 0L) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.getSystemService(NotificationManager::class.java).createNotificationChannel(
                    NotificationChannel(
                        COUNTDOWN_CHANNEL_ID,
                        context.getString(R.string.rest_timer_countdown_channel),
                        NotificationManager.IMPORTANCE_LOW,
                    ).apply {
                        setSound(null, null)
                        enableVibration(false)
                        setShowBadge(false)
                    },
                )
            }
            val notification = NotificationCompat.Builder(context, COUNTDOWN_CHANNEL_ID)
                .setSmallIcon(context.applicationInfo.icon)
                .setContentTitle(title)
                .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setWhen(triggerAtMillis)
                .setShowWhen(true)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setTimeoutAfter(remaining)
                .setContentIntent(contentIntent)
                .build()
            NotificationManagerCompat.from(context).notify(COUNTDOWN_NOTIFICATION_ID, notification)
        } catch (e: RuntimeException) {
            // Notification permission missing: the alarm itself is already set.
            android.util.Log.w("RestTimerAlarm", "Cannot post countdown notification", e)
        }
    }

    private fun alarmPendingIntent(
        context: Context,
        title: String,
        body: String,
        dismissLabel: String,
        soundEnabled: Boolean,
        vibrationEnabled: Boolean,
        triggerAtMillis: Long,
    ): PendingIntent {
        val intent = Intent(context, RestTimerAlarmReceiver::class.java).apply {
            putExtra(EXTRA_TRIGGER_AT, triggerAtMillis)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_DISMISS_LABEL, dismissLabel)
            putExtra(EXTRA_SOUND_ENABLED, soundEnabled)
            putExtra(EXTRA_VIBRATION_ENABLED, vibrationEnabled)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
