package com.fitnessplan.fitness_plan

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

/** Owns alarm playback; a notification channel alone cannot sustain an alarm. */
class ReminderAlarmService : Service() {
    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { stopSelf() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        stopPlayback()
        val title = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_TITLE)
            ?: getString(R.string.workout_reminder_default_title)
        val body = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_BODY)
            ?: getString(R.string.workout_reminder_default_body)
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(
            CHANNEL_ID, getString(R.string.reminder_alarm_channel), NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            setSound(null, null) // Playback uses the alarm audio stream below.
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        })
        val open = PendingIntent.getActivity(this, NOTIFICATION_ID,
            Intent(this, ReminderAlarmActivity::class.java).putExtras(intent).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, NOTIFICATION_ID,
            Intent(this, ReminderAlarmService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon).setContentTitle(title).setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_ALARM).setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC).setOngoing(true)
            .setContentIntent(open).setDeleteIntent(stop)
            .addAction(0, getString(R.string.rest_timer_alarm_dismiss), stop)
        if (Build.VERSION.SDK_INT < 34 || manager.canUseFullScreenIntent()) {
            builder.setFullScreenIntent(open, true)
        }
        startForeground(NOTIFICATION_ID, builder.build())
        val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        vibrator = if (Build.VERSION.SDK_INT >= 31) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        vibrator?.let {
            if (it.hasVibrator()) it.vibrate(
                VibrationEffect.createWaveform(longArrayOf(0, 800, 400, 800, 1000), 0), attributes)
        }
        if (intent.getBooleanExtra(WorkoutReminderScheduler.EXTRA_SOUND, true)) {
            val custom = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_SOUND_URI)?.let(Uri::parse)
            play(custom, attributes)
        }
        // Never leave an unattended alarm running indefinitely.
        handler.postDelayed(timeout, 10 * 60 * 1000L)
        return START_NOT_STICKY
    }

    private fun play(custom: Uri?, attributes: AudioAttributes) {
        val fallback = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        for (uri in listOfNotNull(custom, fallback).distinct()) {
            val candidate = MediaPlayer()
            try {
                candidate.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK)
                candidate.setAudioAttributes(attributes)
                candidate.setDataSource(this, uri)
                candidate.isLooping = true
                candidate.prepare()
                candidate.start()
                player = candidate
                return
            } catch (e: Exception) {
                candidate.release()
                Log.w("ReminderAlarm", "Cannot play selected alarm; trying default", e)
            }
        }
    }

    private fun stopPlayback() {
        handler.removeCallbacks(timeout)
        player?.release()
        player = null
        vibrator?.cancel()
    }

    override fun onDestroy() {
        stopPlayback()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    companion object {
        const val ACTION_STOP = "com.fitnessplan.fitness_plan.STOP_REMINDER"
        const val CHANNEL_ID = "daily_reminder_alarm_service_v1"
        private const val NOTIFICATION_ID = 72401
    }
}
