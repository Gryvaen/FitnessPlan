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
 * - If the device booted today, cumulative ≈ steps since boot (best-effort today).
 * - Otherwise uses a midnight baseline snapshot (AlarmManager) so later days match
 *   the system pedometer more closely.
 * - Mid-day first install still cannot recover morning steps without Health Connect.
 */
object StepCounterBridge {
    const val CHANNEL = "fitness_plan/step_counter"
    const val ACTION_MIDNIGHT_SNAPSHOT = "com.fitnessplan.fitness_plan.STEP_COUNTER_MIDNIGHT"
    private const val TAG = "StepCounterBridge"
    private const val PREFS = "fitness_plan_step_counter"
    private const val KEY_DATE = "date"
    private const val KEY_BASELINE = "baseline"
    private const val KEY_LAST = "last"
    private const val KEY_TODAY = "today"
    private const val MIDNIGHT_REQUEST = 71011

    fun handle(context: Context, method: String, result: MethodChannel.Result) {
        when (method) {
            "readTodaySteps" -> readTodayStepsAsync(context, result)
            "isAvailable" -> {
                val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
                val sensor = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
                    ?: sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER, true)
                result.success(sensor != null)
            }
            "openHealthConnectSettings" -> {
                result.success(openHealthConnectSettings(context))
            }
            else -> result.notImplemented()
        }
    }

    fun snapshotMidnightBaseline(context: Context) {
        readCumulativeBlocking(context) { cumulative ->
            if (cumulative == null) return@readCumulativeBlocking
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = localDateKey()
            prefs.edit()
                .putString(KEY_DATE, today)
                .putLong(KEY_BASELINE, cumulative)
                .putLong(KEY_LAST, cumulative)
                .putInt(KEY_TODAY, 0)
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
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S &&
                !alarmManager.canScheduleExactAlarms()
            ) {
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
        // Best-effort OEM shortcuts (may exist on some ColorOS / MIUI builds).
        val oemToday = readOemTodaySteps(context)
        if (oemToday != null && oemToday > 0) {
            result.success(oemToday)
            scheduleNextMidnight(context)
            return
        }

        readCumulativeBlocking(context) { cumulative ->
            if (cumulative == null) {
                result.success(null)
                return@readCumulativeBlocking
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

    /** Try known OEM content providers / settings keys; null if unavailable. */
    private fun readOemTodaySteps(context: Context): Int? {
        val resolver = context.contentResolver
        val startOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val uris = listOf(
            "content://com.miui.providers.steps/item",
            "content://com.oplus.providers.steps/item",
            "content://com.heytap.providers.steps/item",
            "content://com.coloros.providers.steps/item",
        )
        for (uriString in uris) {
            try {
                val uri = android.net.Uri.parse(uriString)
                resolver.query(
                    uri,
                    arrayOf("_steps", "_begin_time", "_end_time"),
                    "_begin_time>=?",
                    arrayOf(startOfDay.toString()),
                    null,
                )?.use { cursor ->
                    var sum = 0
                    val stepsIdx = cursor.getColumnIndex("_steps")
                    if (stepsIdx < 0) return@use
                    while (cursor.moveToNext()) {
                        sum += cursor.getInt(stepsIdx).coerceAtLeast(0)
                    }
                    if (sum > 0) {
                        Log.i(TAG, "OEM steps from $uriString = $sum")
                        return sum
                    }
                }
            } catch (e: Exception) {
                Log.d(TAG, "OEM uri $uriString unavailable: ${e.message}")
            }
        }

        val settingKeys = listOf(
            "today_steps",
            "step_today",
            "oplus_today_steps",
            "heytap_today_steps",
        )
        for (key in settingKeys) {
            try {
                val v = android.provider.Settings.System.getInt(resolver, key, -1)
                if (v > 0) {
                    Log.i(TAG, "OEM settings $key = $v")
                    return v
                }
            } catch (_: Exception) {
            }
            try {
                val v = android.provider.Settings.Secure.getInt(resolver, key, -1)
                if (v > 0) {
                    Log.i(TAG, "OEM secure $key = $v")
                    return v
                }
            } catch (_: Exception) {
            }
        }
        return null
    }

    internal fun applyCumulative(context: Context, cumulativeRaw: Long): Int {
        val cumulative = max(0L, cumulativeRaw)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val todayKey = localDateKey()
        val storedDate = prefs.getString(KEY_DATE, null)
        var baseline = prefs.getLong(KEY_BASELINE, -1L)
        var last = prefs.getLong(KEY_LAST, -1L)
        var todaySteps = prefs.getInt(KEY_TODAY, 0).coerceAtLeast(0)
        val bootToday = isBootToday()

        if (storedDate != todayKey) {
            if (bootToday) {
                // Counter started today → cumulative is a usable today estimate.
                todaySteps = cumulative.toInt().coerceAtLeast(0)
                baseline = 0L
                last = cumulative
            } else {
                // First open of the day without a midnight snapshot — anchor.
                // Morning steps before this open are not recoverable from the sensor.
                todaySteps = 0
                baseline = cumulative
                last = cumulative
            }
            prefs.edit()
                .putString(KEY_DATE, todayKey)
                .putLong(KEY_BASELINE, baseline)
                .putLong(KEY_LAST, last)
                .putInt(KEY_TODAY, todaySteps)
                .apply()
            return todaySteps
        }

        // Same calendar day.
        if (last < 0L) {
            if (bootToday && todaySteps == 0 && baseline <= 0L) {
                todaySteps = cumulative.toInt().coerceAtLeast(0)
                baseline = 0L
            } else if (baseline >= 0L && cumulative >= baseline) {
                todaySteps = (cumulative - baseline).toInt().coerceAtLeast(0)
            }
            last = cumulative
        } else if (cumulative >= last) {
            todaySteps += (cumulative - last).toInt()
            last = cumulative
        } else {
            // Reboot: counter restarted.
            todaySteps += cumulative.toInt().coerceAtLeast(0)
            baseline = 0L
            last = cumulative
        }

        prefs.edit()
            .putString(KEY_DATE, todayKey)
            .putLong(KEY_BASELINE, baseline)
            .putLong(KEY_LAST, last)
            .putInt(KEY_TODAY, todaySteps.coerceAtLeast(0))
            .apply()
        return todaySteps.coerceAtLeast(0)
    }

    private fun readCumulativeBlocking(context: Context, callback: (Long?) -> Unit) {
        val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            ?: sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER, true)
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

        val registered = sensorManager.registerListener(
            listener,
            sensor,
            SensorManager.SENSOR_DELAY_FASTEST,
        )
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
            callback(null)
        }, 4000)
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

    private fun localDateKey(): String {
        val cal = Calendar.getInstance()
        val y = cal.get(Calendar.YEAR)
        val m = cal.get(Calendar.MONTH) + 1
        val d = cal.get(Calendar.DAY_OF_MONTH)
        return "%04d-%02d-%02d".format(y, m, d)
    }

    private fun isBootToday(): Boolean {
        val bootAt = System.currentTimeMillis() - SystemClock.elapsedRealtime()
        val bootCal = Calendar.getInstance().apply { timeInMillis = bootAt }
        val nowCal = Calendar.getInstance()
        return bootCal.get(Calendar.YEAR) == nowCal.get(Calendar.YEAR) &&
            bootCal.get(Calendar.DAY_OF_YEAR) == nowCal.get(Calendar.DAY_OF_YEAR)
    }
}

class StepCounterMidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val app = context.applicationContext
        when (intent?.action) {
            StepCounterBridge.ACTION_MIDNIGHT_SNAPSHOT -> {
                StepCounterBridge.snapshotMidnightBaseline(app)
            }
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                // Do not snapshot here — that would zero out steps since boot.
                StepCounterBridge.scheduleNextMidnight(app)
            }
        }
    }
}
