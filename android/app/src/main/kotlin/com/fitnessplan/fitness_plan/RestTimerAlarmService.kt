package com.fitnessplan.fitness_plan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

class RestTimerAlarmService : Service() {
    private lateinit var vibrator: Vibrator

    override fun onCreate() {
        super.onCreate()
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(RestTimerAlarmScheduler.EXTRA_TITLE)
            ?: getString(R.string.rest_timer_alarm_title)
        val body = intent?.getStringExtra(RestTimerAlarmScheduler.EXTRA_BODY)
            ?: getString(R.string.rest_timer_alarm_body)
        val dismissLabel = intent?.getStringExtra(RestTimerAlarmScheduler.EXTRA_DISMISS_LABEL)
            ?: getString(R.string.rest_timer_alarm_dismiss)

        startForeground(NOTIFICATION_ID, buildNotification(title, body, dismissLabel))
        startRepeatingVibration()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        vibrator.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startRepeatingVibration() {
        if (!vibrator.hasVibrator()) return
        val pattern = longArrayOf(0, 900, 350, 900, 800)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0), attributes)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, 0, attributes)
        }
    }

    private fun buildNotification(title: String, body: String, dismissLabel: String): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val dismissIntent = PendingIntent.getBroadcast(
            this,
            NOTIFICATION_ID,
            Intent(this, RestTimerAlarmStopReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(openIntent)
            .setFullScreenIntent(openIntent, true)
            .addAction(0, dismissLabel, dismissIntent)
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.rest_timer_alarm_channel),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.rest_timer_alarm_channel_description)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(null, null)
            enableVibration(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "rest_timer_native_alarm_v1"
        private const val NOTIFICATION_ID = 71002
    }
}
