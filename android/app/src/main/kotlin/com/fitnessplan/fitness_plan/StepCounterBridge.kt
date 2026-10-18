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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Reads [Sensor.TYPE_STEP_COUNTER] and converts the reboot-cumulative value into
 * local-calendar-day totals via [StepCounterState].
 *
 * Only increases within one boot are counted; stale / out-of-order events are
 * dropped by their sensor timestamp, and a reboot is recognized only by the
 * boot id changing — never by the counter going down. Any jump faster than a
 * human can walk only moves the baseline (see [StepCounterState.maxPlausibleSteps]).
 *
 * Day boundary: the midnight alarm (or the foreground service) anchors the new
 * day at 0. If the device booted today, steps since boot seed the day.
 * Otherwise steps walked before the first post-midnight sample are lost.
 */
object StepCounterBridge {
    const val CHANNEL = "fitness_plan/step_counter"
    const val ACTION_MIDNIGHT_SNAPSHOT = "com.fitnessplan.fitness_plan.STEP_COUNTER_MIDNIGHT"
    private const val TAG = "StepCounterBridge"
    private const val PREFS = "fitness_plan_step_counter"
    private val LEGACY_KEYS = listOf("date", "baseline", "last", "last_time", "today", "baseline_source")
    private const val KEY_V2_DATE = "v2_date"
    private const val KEY_V2_BOOT = "v2_boot"
    private const val KEY_V2_BOOT_AT = "v2_boot_at"
    private const val KEY_V2_EVENT_NANOS = "v2_event_nanos"
    private const val KEY_V2_ELAPSED_NANOS = "v2_elapsed_nanos"
    private const val KEY_V2_LOW_STREAK = "v2_low_streak"
    private const val KEY_V2_LOW_SINCE = "v2_low_since"
    private const val KEY_V2_CUMULATIVE = "v2_cumulative"
    private const val KEY_V2_STEPS = "v2_steps"
    private const val KEY_V2_SOURCE = "v2_source"
    private const val HISTORY_PREFIX = "history_"
    private const val MIDNIGHT_REQUEST = 71011
    private const val SENSOR_TIMEOUT_MS = 6000L
    private const val BOOT_TIME_TOLERANCE_MS = 10 * 60 * 1000L
    private const val HISTORY_KEEP_DAYS = 90

    /** No human walks this much in a day; only the legacy reboot bug did. */
    private const val MAX_PLAUSIBLE_DAILY_STEPS = 100_000

    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "readTodaySteps" -> readTodayStepsAsync(context, result)
            "isAvailable" -> result.success(stepSensor(context) != null)
            "openHealthConnectSettings" -> result.success(openHealthConnectSettings(context))
            "diagnostics" -> diagnosticsAsync(context, result)
            "readRecentSteps" -> {
                val days = call.argument<Int>("days") ?: 14
                result.success(readRecentStepsMap(context, days))
            }
            else -> result.notImplemented()
        }
    }

    /** Archived per-day totals the day boundary has already closed out, keyed
     *  by local date ("yyyy-MM-dd"). This is the only place history survives
     *  once the live counter anchors a new day. */
    private fun archiveCompletedDay(
        prefs: android.content.SharedPreferences,
        date: String?,
        steps: Int,
    ) {
        if (date == null) return
        val oldest = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -HISTORY_KEEP_DAYS) }
        val cutoff = HISTORY_PREFIX + localDateKey(oldest.timeInMillis)
        val edit = prefs.edit().putInt(HISTORY_PREFIX + date, steps.coerceAtLeast(0))
        // yyyy-MM-dd keys sort chronologically, so a string compare is a date compare.
        for (key in prefs.all.keys) {
            if (key.startsWith(HISTORY_PREFIX) && key < cutoff) edit.remove(key)
        }
        edit.apply()
    }

    private fun readRecentStepsMap(context: Context, days: Int): Map<String, Int> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val out = mutableMapOf<String, Int>()
        val cal = Calendar.getInstance()
        val limit = days.coerceIn(1, 60)
        for (i in 0 until limit) {
            val key = localDateKey(cal.timeInMillis)
            val steps = prefs.getInt(HISTORY_PREFIX + key, -1)
            if (steps >= 0) out[key] = steps
            cal.add(Calendar.DAY_OF_YEAR, -1)
        }
        return out
    }

    fun snapshotMidnightBaseline(context: Context) {
        readCumulative(context) { sample ->
            if (sample != null) {
                try {
                    applyCumulative(context, sample.value, sample.eventNanos)
                } catch (e: Exception) {
                    Log.e(TAG, "midnight applyCumulative failed", e)
                }
                Log.i(TAG, "midnight sample=${sample.value} date=${localDateKey()}")
            }
            scheduleNextMidnight(context)
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

        readCumulative(context) { sample ->
            if (sample == null) {
                result.success(null)
                return@readCumulative
            }
            try {
                val today = applyCumulative(context, sample.value, sample.eventNanos)
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
            "bootId" to currentBootId(context, prefs, persist = false),
            "storedDate" to prefs.getString(KEY_V2_DATE, null),
            "storedBootId" to prefs.getString(KEY_V2_BOOT, null),
            "eventNanos" to prefs.getLong(KEY_V2_EVENT_NANOS, -1L),
            "last" to prefs.getLong(KEY_V2_CUMULATIVE, -1L),
            "today" to prefs.getInt(KEY_V2_STEPS, -1),
            "source" to prefs.getString(KEY_V2_SOURCE, null),
            "lowStreak" to prefs.getInt(KEY_V2_LOW_STREAK, 0),
            "oemToday" to readOemTodaySteps(context),
        )
        if (sensor == null) {
            base["cumulative"] = null
            result.success(base)
            return
        }
        readCumulative(context) { sample ->
            base["cumulative"] = sample?.value
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

    /** Feeds one sensor sample through [StepCounterState]. Every caller — the
     *  foreground service, the MethodChannel one-shot read and the midnight
     *  alarm — goes through here so they share one serialized transition. */
    internal fun applyCumulative(context: Context, value: Long, eventNanos: Long): Int =
        StepCounterTransaction.run {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val previous = loadState(prefs)
            if (previous == null) {
                Log.w(TAG, "no step state; re-anchoring (keys=${prefs.all.keys.filterNot { it.startsWith(HISTORY_PREFIX) }})")
                migrateLegacy(prefs)
            }
            val (next, archived) = StepCounterState.advance(
                previous,
                day = localDateKey(),
                boot = currentBootId(context, prefs),
                timestamp = eventNanos,
                elapsed = SystemClock.elapsedRealtimeNanos(),
                value = value,
                bootToday = isBootToday(),
            )
            if (archived != null) archiveCompletedDay(prefs, archived.first, archived.second)
            if (next != previous) saveState(prefs, next)
            if (next.source != previous?.source) Log.i(TAG, "step source=${next.source} value=$value steps=${next.steps}")
            next.steps
        }

    private fun loadState(prefs: android.content.SharedPreferences): StepCounterState? {
        val date = prefs.getString(KEY_V2_DATE, null) ?: return null
        val boot = prefs.getString(KEY_V2_BOOT, null) ?: return null
        return StepCounterState(
            date,
            boot,
            prefs.getLong(KEY_V2_EVENT_NANOS, 0L),
            prefs.getLong(KEY_V2_ELAPSED_NANOS, 0L),
            prefs.getLong(KEY_V2_CUMULATIVE, 0L),
            prefs.getInt(KEY_V2_STEPS, 0).coerceAtLeast(0),
            prefs.getString(KEY_V2_SOURCE, null) ?: "unknown",
            prefs.getInt(KEY_V2_LOW_STREAK, 0),
            prefs.getLong(KEY_V2_LOW_SINCE, 0L),
        )
    }

    private fun saveState(prefs: android.content.SharedPreferences, state: StepCounterState) {
        prefs.edit()
            .putString(KEY_V2_DATE, state.date)
            .putString(KEY_V2_BOOT, state.bootId)
            .putLong(KEY_V2_EVENT_NANOS, state.eventNanos)
            .putLong(KEY_V2_ELAPSED_NANOS, state.elapsedNanos)
            .putInt(KEY_V2_LOW_STREAK, state.lowStreak)
            .putLong(KEY_V2_LOW_SINCE, state.lowSinceNanos)
            .putLong(KEY_V2_CUMULATIVE, state.cumulative)
            .putInt(KEY_V2_STEPS, state.steps)
            .putString(KEY_V2_SOURCE, state.source)
            .commit()
    }

    /** Drops the v1 day counter and any archived day that could only have come
     *  from the old "decrease == reboot" bug. */
    private fun migrateLegacy(prefs: android.content.SharedPreferences) {
        val edit = prefs.edit()
        for (key in LEGACY_KEYS) edit.remove(key)
        for ((key, v) in prefs.all) {
            if (key.startsWith(HISTORY_PREFIX) && v is Int && v >= MAX_PLAUSIBLE_DAILY_STEPS) {
                edit.remove(key)
            }
        }
        edit.apply()
    }

    /**
     * Identifies the current boot. A counter decrease alone must never be read
     * as a reboot (ColorOS replays stale cached events), so reboots are only
     * recognized by this id changing.
     */
    private fun currentBootId(
        context: Context,
        prefs: android.content.SharedPreferences,
        persist: Boolean = true,
    ): String {
        try {
            val count = android.provider.Settings.Global.getInt(
                context.contentResolver,
                android.provider.Settings.Global.BOOT_COUNT,
            )
            return "c$count"
        } catch (_: Exception) {
        }
        // Wall-clock derived boot time drifts with NTP / manual clock changes,
        // so reuse the stored id while it stays within tolerance.
        val bootAt = System.currentTimeMillis() - SystemClock.elapsedRealtime()
        val storedAt = prefs.getLong(KEY_V2_BOOT_AT, Long.MIN_VALUE)
        val stored = prefs.getString(KEY_V2_BOOT, null)
        if (stored != null && storedAt != Long.MIN_VALUE &&
            kotlin.math.abs(bootAt - storedAt) <= BOOT_TIME_TOLERANCE_MS
        ) {
            return stored
        }
        if (persist) prefs.edit().putLong(KEY_V2_BOOT_AT, bootAt).apply()
        return "t$bootAt"
    }

    private fun stepSensor(context: Context): Sensor? {
        val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        return sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            ?: sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER, true)
    }

    class Sample(val value: Long, val eventNanos: Long)

    private fun readCumulative(context: Context, callback: (Sample?) -> Unit) {
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
                callback(Sample(event.values[0].toLong(), event.timestamp))
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
