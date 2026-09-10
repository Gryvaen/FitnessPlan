package com.fitnessplan.fitness_plan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Keeps a listener on [Sensor.TYPE_STEP_COUNTER] registered as a foreground
 * service so the reboot-cumulative counter is observed continuously — including
 * across the local-midnight rollover — even on ColorOS / OneUI / MIUI builds
 * that kill background alarms and cached processes aggressively.
 *
 * All the day-boundary bookkeeping is delegated to
 * [StepCounterBridge.applyCumulative]; this class only pumps sensor values into
 * it and keeps the process alive.
 *
 * Opt-in: the user enables it from the steps sheet. State lives in the same
 * SharedPreferences file the bridge uses.
 */
class StepCounterService : Service(), SensorEventListener {
    private var sensorManager: SensorManager? = null

    override fun onCreate() {
        super.onCreate()
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIF_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH,
                )
            } else {
                startForeground(NOTIF_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground failed; stopping", e)
            stopSelf()
            return
        }

        val sm = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val sensor = sm?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sm == null || sensor == null) {
            stopSelf()
            return
        }
        sensorManager = sm
        // Batch up to a few minutes — the counter is cumulative so nothing is
        // lost between deliveries, and TYPE_STEP_COUNTER is a low-power sensor.
        sm.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL, BATCH_LATENCY_US)
        StepCounterBridge.scheduleNextMidnight(applicationContext)
        Log.i(TAG, "step counter service started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onSensorChanged(event: SensorEvent) {
        val value = event.values.firstOrNull()?.toLong() ?: return
        try {
            StepCounterBridge.applyCumulative(applicationContext, value)
        } catch (e: Exception) {
            Log.w(TAG, "applyCumulative from service failed", e)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        sensorManager = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        if (nm != null && nm.getNotificationChannel(CHANNEL_ID) == null) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.step_service_channel),
                    NotificationManager.IMPORTANCE_MIN,
                ).apply {
                    description = getString(R.string.step_service_channel_description)
                    setShowBadge(false)
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }

        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val open = PendingIntent.getActivity(
            this,
            NOTIF_ID,
            launch ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(getString(R.string.step_service_notification_title))
            .setContentText(getString(R.string.step_service_notification_body))
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(open)
            .build()
    }

    companion object {
        const val TAG = "StepCounterService"
        private const val CHANNEL_ID = "step_counter_service_v1"
        private const val NOTIF_ID = 71021
        private const val BATCH_LATENCY_US = 3 * 60 * 1_000_000
        const val ACTION_STOP = "com.fitnessplan.fitness_plan.STEP_SERVICE_STOP"

        private const val PREFS = "fitness_plan_step_counter"
        private const val KEY_ENABLED = "service_enabled"

        fun isEnabled(context: Context): Boolean =
            prefs(context).getBoolean(KEY_ENABLED, false)

        fun setEnabled(context: Context, enabled: Boolean) {
            prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
            if (enabled) start(context) else stop(context)
        }

        /** Start the service now (caller must be foreground, or a boot receiver). */
        fun start(context: Context) {
            val sm = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            if (sm?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) == null) return
            val intent = Intent(context, StepCounterService::class.java)
            try {
                context.startForegroundService(intent)
            } catch (e: Exception) {
                Log.w(TAG, "startForegroundService failed", e)
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, StepCounterService::class.java))
            } catch (_: Exception) {
            }
        }

        /** Re-arm after boot / app update. */
        fun startIfEnabled(context: Context) {
            if (isEnabled(context)) start(context)
        }

        private fun prefs(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }
}
