package com.fitnessplan.fitness_plan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class WorkoutReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra(
            WorkoutReminderScheduler.EXTRA_NOTIFICATION_ID,
            DEFAULT_NOTIFICATION_ID,
        )
        val title = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_TITLE)
            ?: context.getString(R.string.workout_reminder_default_title)
        val body = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_BODY)
            ?: context.getString(R.string.workout_reminder_default_body)
        val channelId = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_CHANNEL_ID)
            ?: FALLBACK_CHANNEL_ID
        val channelName = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_CHANNEL_NAME)
            ?: context.getString(R.string.workout_reminder_channel)
        val sound = intent.getBooleanExtra(WorkoutReminderScheduler.EXTRA_SOUND, true)
        val soundUri = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_SOUND_URI)

        ensureChannel(context, channelId, channelName, sound, soundUri)

        val openApp = PendingIntent.getActivity(
            context,
            notificationId,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(openApp)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(notificationId, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS denied — nothing else we can do from a receiver.
        }
    }

    /**
     * Creates [channelId] if it doesn't exist yet. Channels are immutable
     * once created — [channelId] is derived from the exact (mode, tone)
     * combination on the Dart side, so a changed setting always arrives
     * here under a fresh id rather than trying to mutate an existing one.
     */
    private fun ensureChannel(
        context: Context,
        channelId: String,
        channelName: String,
        sound: Boolean,
        soundUri: String?,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(channelId) != null) return
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.workout_reminder_channel_description)
            enableVibration(true)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            if (sound) {
                val uri = if (soundUri != null) {
                    Uri.parse(soundUri)
                } else {
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                }
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setSound(uri, attributes)
            } else {
                setSound(null, null)
            }
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val FALLBACK_CHANNEL_ID = "workout_reminder_native_v1"
        private const val DEFAULT_NOTIFICATION_ID = 72001
    }
}
