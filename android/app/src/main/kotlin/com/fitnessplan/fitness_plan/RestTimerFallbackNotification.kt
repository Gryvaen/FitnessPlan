package com.fitnessplan.fitness_plan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/** Visible, audible fallback when Android refuses to launch the alarm service. */
object RestTimerFallbackNotification {
    private const val CHANNEL_PREFIX = "rest_timer_fallback_alarm_v2_"
    private const val NOTIFICATION_ID = 71003

    fun show(context: Context, intent: Intent) {
        try {
            showInternal(context, intent)
        } catch (e: RuntimeException) {
            Log.e("RestTimerAlarm", "Cannot post fallback notification", e)
        }
    }

    private fun showInternal(context: Context, intent: Intent) {
        val title = intent.getStringExtra(RestTimerAlarmScheduler.EXTRA_TITLE)
            ?: context.getString(R.string.rest_timer_alarm_title)
        val body = intent.getStringExtra(RestTimerAlarmScheduler.EXTRA_BODY)
            ?: context.getString(R.string.rest_timer_alarm_body)
        val dismissLabel = intent.getStringExtra(RestTimerAlarmScheduler.EXTRA_DISMISS_LABEL)
            ?: context.getString(R.string.rest_timer_alarm_dismiss)
        val soundEnabled = intent.getBooleanExtra(RestTimerAlarmScheduler.EXTRA_SOUND_ENABLED, true)
        val vibrationEnabled = intent.getBooleanExtra(RestTimerAlarmScheduler.EXTRA_VIBRATION_ENABLED, true)
        val mode = when {
            soundEnabled && vibrationEnabled -> "both"
            soundEnabled -> "ring"
            else -> "vibrate"
        }
        val channelId = CHANNEL_PREFIX + mode
        val channelName = when (mode) {
            "ring" -> context.getString(R.string.rest_timer_alarm_ring_channel)
            "vibrate" -> context.getString(R.string.rest_timer_alarm_vibrate_channel)
            else -> context.getString(R.string.rest_timer_alarm_both_channel)
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.rest_timer_alarm_channel_description)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(vibrationEnabled)
                setSound(
                    if (soundEnabled) RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) else null,
                    if (soundEnabled) AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build() else null,
                )
            })
        }
        val open = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            Intent(context, ReminderAlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(ReminderAlarmActivity.EXTRA_REST_TIMER, true)
                putExtra(RestTimerAlarmScheduler.EXTRA_TITLE, title)
                putExtra(RestTimerAlarmScheduler.EXTRA_BODY, body)
                putExtra(RestTimerAlarmScheduler.EXTRA_DISMISS_LABEL, dismissLabel)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val dismiss = PendingIntent.getBroadcast(
            context,
            NOTIFICATION_ID,
            Intent(context, RestTimerAlarmStopReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false)
            .setOngoing(true)
            .setContentIntent(open)
            .addAction(0, dismissLabel, dismiss)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            if (soundEnabled) builder.setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
            if (vibrationEnabled) builder.setVibrate(longArrayOf(0, 900, 350, 900))
        }
        val notification = builder.build()
        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }
}
