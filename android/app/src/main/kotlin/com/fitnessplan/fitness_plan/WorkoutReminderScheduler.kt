package com.fitnessplan.fitness_plan

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar
import org.json.JSONArray
import org.json.JSONObject

/**
 * Schedules one-shot daily workout reminder alarms via [AlarmManager.setAlarmClock],
 * matching the rest-timer path that reliably wakes the device.
 */
object WorkoutReminderScheduler {
    const val CHANNEL = "fitness_plan/workout_reminder"
    const val EXTRA_NOTIFICATION_ID = "notification_id"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"
    const val EXTRA_CHANNEL_ID = "channel_id"
    const val EXTRA_CHANNEL_NAME = "channel_name"
    const val EXTRA_SOUND = "sound"
    const val EXTRA_SOUND_URI = "sound_uri"
    const val EXTRA_TRIGGER_AT = "trigger_at"

    // One 100-slot id range per reminder kind (workout / water / meal /
    // weigh-in), matching ReminderKind.idBase on the Dart side.
    private val BASE_REQUEST_CODES = intArrayOf(72001, 72101, 72201, 72301)
    private const val SLOTS_PER_KIND = 32

    private const val PREFS = "reminder_alarms"
    private const val MISSED_WINDOW_MILLIS = 60 * 60 * 1000L

    data class ScheduleResult(val scheduled: Int, val failed: Int)

    @Synchronized
    fun scheduleAll(context: Context, items: List<ReminderItem>, staleChannelIds: List<String> = emptyList()): ScheduleResult {
        cancelAll(context)
        deleteChannels(context, staleChannelIds)
        save(context, items)
        var scheduled = 0
        var failed = 0
        for (item in items) {
            try {
                scheduleOne(context, item)
                scheduled++
            } catch (e: RuntimeException) {
                failed++
                Log.e("ReminderAlarm", "Cannot schedule reminder ${item.id}", e)
            }
        }
        setScheduleStatus(context, scheduled, failed)
        return ScheduleResult(scheduled, failed)
    }

    /**
     * Deletes notification channels superseded by a changed alert mode or
     * tone — channels are immutable once created, so a change produces a
     * new channel id and the old one would otherwise linger as an orphaned
     * duplicate in system settings.
     */
    private fun deleteChannels(context: Context, channelIds: List<String>) {
        if (channelIds.isEmpty() || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        for (id in channelIds) {
            manager.deleteNotificationChannel(id)
            manager.deleteNotificationChannel("${id}_fallback_v2")
        }
    }

    @Synchronized
    fun cancelAll(context: Context) {
        check(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove("items").remove("scheduled").remove("failed").commit()) {
            "Cannot clear reminder alarms"
        }

        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        for (base in BASE_REQUEST_CODES) {
            for (i in 0 until SLOTS_PER_KIND) {
                alarmManager.cancel(
                    alarmPendingIntent(context, base + i, 0, "", "", "", "", false, null),
                )
            }
        }
    }

    private fun save(context: Context, items: List<ReminderItem>) {
        val array = JSONArray()
        for (item in items) {
            val day = Calendar.getInstance().apply { timeInMillis = item.triggerAtMillis }
            array.put(JSONObject().apply {
                put("id", item.id); put("trigger", item.triggerAtMillis)
                put("title", item.title); put("body", item.body)
                put("channelId", item.channelId); put("channelName", item.channelName)
                put("sound", item.sound); put("soundUri", item.soundUri)
                put("weekday", day.get(Calendar.DAY_OF_WEEK))
                put("hour", day.get(Calendar.HOUR_OF_DAY)); put("minute", day.get(Calendar.MINUTE))
            })
        }
        check(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("items", array.toString()).commit()) { "Cannot persist reminder alarms" }
    }

    private fun saved(context: Context): JSONArray = JSONArray(
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString("items", "[]") ?: "[]")

    private fun decode(row: JSONObject, trigger: Long = row.getLong("trigger")) = ReminderItem(
        row.getInt("id"), trigger, row.getString("title"), row.getString("body"),
        row.getString("channelId"), row.getString("channelName"), row.getBoolean("sound"),
        if (row.has("soundUri") && !row.isNull("soundUri")) row.getString("soundUri") else null)

    /** Each weekday slot renews itself, even if Flutter has not opened for a week. */
    @Synchronized
    fun claimAndScheduleNext(context: Context, intent: Intent): Boolean {
        val id = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        val trigger = intent.getLongExtra(EXTRA_TRIGGER_AT, -1L)
        val rows = saved(context)
        val current = (0 until rows.length()).map { rows.getJSONObject(it) }
            .firstOrNull { it.getInt("id") == id } ?: return false
        if (trigger != current.getLong("trigger") || alreadyHandled(context, id, trigger)) return false
        markHandled(context, id, trigger)
        val items = (0 until rows.length()).map { index ->
            val row = rows.getJSONObject(index)
            if (row.getInt("id") != id) decode(row) else decode(row, nextTime(row))
        }
        val next = items.first { it.id == id }
        save(context, items)
        try {
            scheduleOne(context, next)
        } catch (e: RuntimeException) {
            markScheduleFailure(context)
            Log.e("ReminderAlarm", "Cannot renew reminder $id", e)
        }
        return true
    }

    private fun nextTime(row: JSONObject): Long {
        val now = System.currentTimeMillis()
        val day = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, row.getInt("hour"))
            set(Calendar.MINUTE, row.getInt("minute"))
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        while (day.timeInMillis <= now || day.get(Calendar.DAY_OF_WEEK) != row.getInt("weekday")) {
            day.add(Calendar.DAY_OF_MONTH, 1)
        }
        return day.timeInMillis
    }

    /** Restore alarms after reboot, update, timezone change or exact-alarm grant. */
    @Synchronized
    fun restore(context: Context, afterBoot: Boolean = false): List<Intent> {
        val rows = saved(context)
        val now = System.currentTimeMillis()
        val catchUps = mutableListOf<Intent>()
        val items = mutableListOf<ReminderItem>()
        for (i in 0 until rows.length()) {
            try {
                val row = rows.getJSONObject(i)
                val previous = row.getLong("trigger")
                val item = decode(row, nextTime(row))
                items.add(item)
                if (afterBoot && previous <= now && now - previous <= MISSED_WINDOW_MILLIS &&
                    !alreadyHandled(context, item.id, previous)) {
                    markHandled(context, item.id, previous)
                    catchUps.add(deliveryIntent(context, decode(row), previous))
                }
            } catch (e: RuntimeException) {
                Log.e("ReminderAlarm", "Cannot decode reminder slot $i", e)
            }
        }
        save(context, items)
        var scheduled = 0
        var failed = 0
        for (item in items) {
            try {
                scheduleOne(context, item)
                scheduled++
            } catch (e: RuntimeException) {
                failed++
                Log.e("ReminderAlarm", "Cannot restore reminder ${item.id}", e)
            }
        }
        setScheduleStatus(context, scheduled, failed)
        return catchUps
    }

    fun scheduleStatus(context: Context): ScheduleResult {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return ScheduleResult(prefs.getInt("scheduled", 0), prefs.getInt("failed", 0))
    }

    private fun setScheduleStatus(context: Context, scheduled: Int, failed: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putInt("scheduled", scheduled).putInt("failed", failed).apply()
    }

    private fun markScheduleFailure(context: Context) {
        val status = scheduleStatus(context)
        setScheduleStatus(context, status.scheduled, status.failed + 1)
    }

    private fun alreadyHandled(context: Context, id: Int, trigger: Long): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong("handled_$id", Long.MIN_VALUE) >= trigger

    private fun markHandled(context: Context, id: Int, trigger: Long) {
        check(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putLong("handled_$id", trigger).commit()) { "Cannot record reminder delivery" }
    }

    private fun scheduleOne(context: Context, item: ReminderItem) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
            ?: error("AlarmManager unavailable")
        val operation = PendingIntent.getBroadcast(context, item.id,
            deliveryIntent(context, item, item.triggerAtMillis),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val showIntent = PendingIntent.getActivity(
            context,
            item.id,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, item.triggerAtMillis, operation)
        } else try {
            alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(item.triggerAtMillis, showIntent), operation)
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    item.triggerAtMillis,
                    operation,
                )
            } else {
                @Suppress("DEPRECATION")
                alarmManager.set(AlarmManager.RTC_WAKEUP, item.triggerAtMillis, operation)
            }
        }
    }

    private fun deliveryIntent(context: Context, item: ReminderItem, trigger: Long): Intent =
        Intent(context, WorkoutReminderReceiver::class.java).apply {
            putExtra(EXTRA_NOTIFICATION_ID, item.id)
            putExtra(EXTRA_TRIGGER_AT, trigger)
            putExtra(EXTRA_TITLE, item.title)
            putExtra(EXTRA_BODY, item.body)
            putExtra(EXTRA_CHANNEL_ID, item.channelId)
            putExtra(EXTRA_CHANNEL_NAME, item.channelName)
            putExtra(EXTRA_SOUND, item.sound)
            putExtra(EXTRA_SOUND_URI, item.soundUri)
        }

    private fun alarmPendingIntent(
        context: Context,
        requestCode: Int,
        notificationId: Int,
        title: String,
        body: String,
        channelId: String,
        channelName: String,
        sound: Boolean,
        soundUri: String?,
    ): PendingIntent {
        val intent = Intent(context, WorkoutReminderReceiver::class.java).apply {
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_CHANNEL_ID, channelId)
            putExtra(EXTRA_CHANNEL_NAME, channelName)
            putExtra(EXTRA_SOUND, sound)
            putExtra(EXTRA_SOUND_URI, soundUri)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    data class ReminderItem(
        val id: Int,
        val triggerAtMillis: Long,
        val title: String,
        val body: String,
        val channelId: String,
        val channelName: String,
        val sound: Boolean,
        val soundUri: String?,
    )
}
