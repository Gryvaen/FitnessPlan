package com.fitnessplan.fitness_plan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max

/**
 * Reads [Sensor.TYPE_STEP_COUNTER] and converts the reboot-cumulative value into
 * local-calendar-day totals.
 *
 * Day boundary strategy (best → worst):
 * 1. Midnight alarm snapshot of the cumulative counter (exact baseline).
 * 2. Device booted today → cumulative == steps since boot ≈ today.
 * 3. Last sample was late yesterday (≤ 6 h before midnight) → treat all steps
 *    since that sample as today's (people rarely walk much before midnight).
 * 4. Last sample was earlier yesterday → time-weighted interpolation.
 * 5. Nothing usable → anchor at current value (morning steps are lost).
 */
object StepCounterBridge {
    const val CHANNEL = "fitness_plan/step_counter"
    const val ACTION_MIDNIGHT_SNAPSHOT = "com.fitnessplan.fitness_plan.STEP_COUNTER_MIDNIGHT"
    private const val TAG = "StepCounterBridge"
    private const val PREFS = "fitness_plan_step_counter"
    private const val KEY_DATE = "date"
    private const val KEY_BASELINE = "baseline"
    private const val KEY_LAST = "last"
    private const val KEY_LAST_TIME = "last_time"
    private const val KEY_TODAY = "today"
    private const val KEY_BASELINE_SOURCE = "baseline_source"
    private const val MIDNIGHT_REQUEST = 71011
    private const val SENSOR_TIMEOUT_MS = 6000L
    private const val LATE_EVENING_MS = 6 * 60 * 60 * 1000L

    /** How stale a prior sample may be and still seed today's reconstruction. */
    private const val RECONSTRUCT_WINDOW_MS = 3L * 24 * 60 * 60 * 1000

    fun handle(context: Context, method: String, result: MethodChannel.Result) {
        when (method) {
            "readTodaySteps" -> readTodayStepsAsync(context, result)
            "isAvailable" -> result.success(stepSensor(context) != null)
            "openHealthConnectSettings" -> result.success(openHealthConnectSettings(context))
            "diagnostics" -> diagnosticsAsync(context, result)
            else -> result.notImplemented()
        }
    }

    fun snapshotMidnightBaseline(context: Context) {
        readCumulative(context) { cumulative ->
            if (cumulative == null) return@readCumulative
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = localDateKey()
            prefs.edit()
                .putString(KEY_DATE, today)
                .putLong(KEY_BASELINE, cumulative)
                .putLong(KEY_LAST, cumulative)
                .putLong(KEY_LAST_TIME, System.currentTimeMillis())
                .putInt(KEY_TODAY, 0)
                .putString(KEY_BASELINE_SOURCE, "midnight_alarm")
                .apply()
            scheduleNextMidnight(context)
            Log.i(TAG, "midnight baseline=$cumulative date=$today")
        }
    }

    fun scheduleNextMidnight(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val triggerAt = nextLocalMidnightMillis()
        val operation = PendingIntent.getBroadcast(
            context,
            MIDNIGHT_REQUEST,
            Intent(context, StepCounterMidnightReceiver::class.java).setAction(ACTION_MIDNIGHT_SNAPSHOT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, operation)
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, operation)
            }
        } catch (e: Exception) {
            Log.w(TAG, "schedule midnight failed, falling back", e)
            try {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, operation)
            } catch (e2: Exception) {
                Log.e(TAG, "fallback midnight schedule failed", e2)
            }
        }
    }

    private fun readTodayStepsAsync(context: Context, result: MethodChannel.Result) {
        val oemToday = readOemTodaySteps(context)
        if (oemToday != null && oemToday > 0) {
            result.success(oemToday)
            scheduleNextMidnight(context)
            return
        }

        readCumulative(context) { cumulative ->
            if (cumulative == null) {
                result.success(null)
                return@readCumulative
            }
            try {
                val today = applyCumulative(context, cumulative)
                scheduleNextMidnight(context)
                result.success(today)
            } catch (e: Exception) {
                Log.e(TAG, "applyCumulative failed", e)
                result.success(null)
            }
        }
    }

    private fun diagnosticsAsync(context: Context, result: MethodChannel.Result) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val sensor = stepSensor(context)
        val bootAt = System.currentTimeMillis() - SystemClock.elapsedRealtime()
        val base = mutableMapOf<String, Any?>(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "sdkInt" to Build.VERSION.SDK_INT,
            "sensorAvailable" to (sensor != null),
            "sensorName" to sensor?.name,
            "bootTimeMillis" to bootAt,
            "bootToday" to isBootToday(),
            "storedDate" to prefs.getString(KEY_DATE, null),
            "baseline" to prefs.getLong(KEY_BASELINE, -1L),
            "baselineSource" to prefs.getString(KEY_BASELINE_SOURCE, null),
            "last" to prefs.getLong(KEY_LAST, -1L),
            "lastTimeMillis" to prefs.getLong(KEY_LAST_TIME, -1L),
            "today" to prefs.getInt(KEY_TODAY, -1),
            "oemToday" to readOemTodaySteps(context),
        )
        if (sensor == null) {
            base["cumulative"] = null
            result.success(base)
            return
        }
        readCumulative(context) { cumulative ->
            base["cumulative"] = cumulative
            result.success(base)
        }
    }

    /** MIUI exposes a documented steps provider; other OEMs do not. */
    private fun readOemTodaySteps(context: Context): Int? {
        val startOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        try {
            context.contentResolver.query(
                android.net.Uri.parse("content://com.miui.providers.steps/item"),
                arrayOf("_steps", "_begin_time", "_end_time"),
                "_begin_time>=?",
                arrayOf(startOfDay.toString()),
                null,
            )?.use { cursor ->
                val idx = cursor.getColumnIndex("_steps")
                if (idx < 0) return null
                var sum = 0
                while (cursor.moveToNext()) sum += cursor.getInt(idx).coerceAtLeast(0)
                if (sum > 0) return sum
            }
        } catch (e: Exception) {
            Log.d(TAG, "MIUI steps provider unavailable: ${e.message}")
        }
        return null
    }

    /** Guards the prefs read-modify-write against the sensor service and the
     *  MethodChannel touching the day counter at the same time. */
    private val counterLock = Any()

    internal fun applyCumulative(context: Context, cumulativeRaw: Long): Int =
        synchronized(counterLock) { applyCumulativeLocked(context, cumulativeRaw) }

    private fun applyCumulativeLocked(context: Context, cumulativeRaw: Long): Int {
        val cumulative = max(0L, cumulativeRaw)
        val now = System.currentTimeMillis()
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val todayKey = localDateKey()
        val storedDate = prefs.getString(KEY_DATE, null)
        var baseline = prefs.getLong(KEY_BASELINE, -1L)
        var last = prefs.getLong(KEY_LAST, -1L)
        val lastTime = prefs.getLong(KEY_LAST_TIME, -1L)
        var todaySteps = prefs.getInt(KEY_TODAY, 0).coerceAtLeast(0)
        var source = prefs.getString(KEY_BASELINE_SOURCE, null)
        val bootToday = isBootToday()

        if (storedDate != todayKey) {
            val midnight = todayStartMillis()
            val haveSample = last in 0L..cumulative && lastTime in 1 until now
            val sampleAgeMs = if (haveSample) now - lastTime else Long.MAX_VALUE
            if (bootToday) {
                todaySteps = cumulative.toInt().coerceAtLeast(0)
                baseline = 0L
                source = "boot_today"
            } else if (haveSample && sampleAgeMs <= RECONSTRUCT_WINDOW_MS) {
                val sinceSample = (cumulative - last).toInt().coerceAtLeast(0)
                val gapBeforeMidnight = midnight - lastTime
                if (lastTime < midnight && gapBeforeMidnight in 0..LATE_EVENING_MS) {
                    // Last sample was late yesterday evening — few people walk
                    // much before midnight, so count it all as today.
                    todaySteps = sinceSample
                    source = "late_evening_sample"
                } else {
                    // Apportion the steps since the last sample to the slice
                    // that falls after today's midnight.
                    val windowMs = (now - lastTime).coerceAtLeast(1L)
                    val afterMidnightMs = (now - midnight).coerceAtLeast(0L)
                    val fraction = (afterMidnightMs.toDouble() / windowMs).coerceIn(0.0, 1.0)
                    todaySteps = (sinceSample * fraction).toInt().coerceAtLeast(0)
                    source = "reconstructed"
                }
                baseline = cumulative - todaySteps
            } else {
                todaySteps = 0
                baseline = cumulative
                source = "anchored"
            }
            last = cumulative
            persist(prefs, todayKey, baseline, last, now, todaySteps, source)
            return todaySteps
        }

        if (last < 0L) {
            if (bootToday && todaySteps == 0 && baseline <= 0L) {
                todaySteps = cumulative.toInt().coerceAtLeast(0)
                baseline = 0L
                source = "boot_today"
            } else if (baseline >= 0L && cumulative >= baseline) {
                todaySteps = (cumulative - baseline).toInt().coerceAtLeast(0)
            }
        } else if (cumulative >= last) {
            todaySteps += (cumulative - last).toInt()
        } else {
            // Counter reset (reboot) — keep what we had, add steps since boot.
            todaySteps += cumulative.toInt().coerceAtLeast(0)
            baseline = 0L
            source = "reboot_midday"
        }
        last = cumulative
        persist(prefs, todayKey, baseline, last, now, todaySteps.coerceAtLeast(0), source)
        return todaySteps.coerceAtLeast(0)
    }

    private fun persist(
        prefs: android.content.SharedPreferences,
        date: String,
        baseline: Long,
        last: Long,
        lastTime: Long,
        today: Int,
        source: String?,
    ) {
        prefs.edit()
            .putString(KEY_DATE, date)
            .putLong(KEY_BASELINE, baseline)
            .putLong(KEY_LAST, last)
            .putLong(KEY_LAST_TIME, lastTime)
            .putInt(KEY_TODAY, today)
            .putString(KEY_BASELINE_SOURCE, source)
            .apply()
    }

    private fun stepSensor(context: Context): Sensor? {
        val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        return sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            ?: sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER, true)
    }

    private fun readCumulative(context: Context, callback: (Long?) -> Unit) {
        val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = stepSensor(context)
        if (sensor == null) {
            callback(null)
            return
        }

        val done = AtomicBoolean(false)
        val mainHandler = Handler(Looper.getMainLooper())
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (!done.compareAndSet(false, true)) return
                sensorManager.unregisterListener(this)
                callback(event.values[0].toLong())
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        val registered = sensorManager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_FASTEST)
        if (!registered) {
            callback(null)
            return
        }
        try {
            sensorManager.flush(listener)
        } catch (_: Exception) {
        }

        mainHandler.postDelayed({
            if (!done.compareAndSet(false, true)) return@postDelayed
            sensorManager.unregisterListener(listener)
            Log.w(TAG, "step counter produced no event within ${SENSOR_TIMEOUT_MS}ms")
            callback(null)
        }, SENSOR_TIMEOUT_MS)
    }

    private fun openHealthConnectSettings(context: Context): Boolean {
        val intents = listOf(
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"),
            Intent(Intent.ACTION_VIEW).setPackage("com.google.android.apps.healthdata"),
            Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = android.net.Uri.parse("package:${context.packageName}")
            },
        )
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
            }
        }
        return false
    }

    private fun nextLocalMidnightMillis(): Long {
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, 1)
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 5)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun todayStartMillis(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun localDateKey(atMillis: Long = System.currentTimeMillis()): String {
        val cal = Calendar.getInstance().apply { timeInMillis = atMillis }
        return "%04d-%02d-%02d".format(
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH),
        )
    }

    private fun isBootToday(): Boolean {
        val bootAt = System.currentTimeMillis() - SystemClock.elapsedRealtime()
        return localDateKey(bootAt) == localDateKey()
    }
}

class StepCounterMidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val app = context.applicationContext
        when (intent?.action) {
            StepCounterBridge.ACTION_MIDNIGHT_SNAPSHOT -> StepCounterBridge.snapshotMidnightBaseline(app)
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                StepCounterBridge.scheduleNextMidnight(app)
                StepCounterService.startIfEnabled(app)
            }
        }
    }
}
