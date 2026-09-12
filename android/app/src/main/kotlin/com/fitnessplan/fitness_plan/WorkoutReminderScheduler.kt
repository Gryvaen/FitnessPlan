package com.fitnessplan.fitness_plan

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
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

    // One 100-slot id range per reminder kind (workout / water / meal /
    // weigh-in), matching ReminderKind.idBase on the Dart side.
    private val BASE_REQUEST_CODES = intArrayOf(72001, 72101, 72201, 72301)
    private const val SLOTS_PER_KIND = 32

    fun scheduleAll(context: Context, items: List<ReminderItem>, staleChannelIds: List<String> = emptyList()) {
        cancelAll(context)
        deleteChannels(context, staleChannelIds)
        save(context, items)
        for (item in items) {
            scheduleOne(context, item)
        }
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
        }
    }

    fun cancelAll(context: Context) {
        context.getSharedPreferences("reminder_alarms", Context.MODE_PRIVATE).edit().clear().apply()

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
        context.getSharedPreferences("reminder_alarms", Context.MODE_PRIVATE).edit()
            .putString("items", array.toString()).apply()
    }

    private fun saved(context: Context): JSONArray = JSONArray(
        context.getSharedPreferences("reminder_alarms", Context.MODE_PRIVATE)
            .getString("items", "[]") ?: "[]")

    private fun decode(row: JSONObject, trigger: Long = row.getLong("trigger")) = ReminderItem(
        row.getInt("id"), trigger, row.getString("title"), row.getString("body"),
        row.getString("channelId"), row.getString("channelName"), row.getBoolean("sound"),
        if (row.has("soundUri") && !row.isNull("soundUri")) row.getString("soundUri") else null)

    /** Each weekday slot renews itself, even if Flutter has not opened for a week. */
    fun scheduleNext(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        val rows = saved(context)
        val items = (0 until rows.length()).map { index ->
            val row = rows.getJSONObject(index)
            if (row.getInt("id") != id) decode(row) else decode(row, nextTime(row))
        }
        val next = items.firstOrNull { it.id == id } ?: return
        save(context, items)
        scheduleOne(context, next)
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
    fun restore(context: Context) {
        val rows = saved(context)
        val items = (0 until rows.length()).map {
            val row = rows.getJSONObject(it)
            decode(row, nextTime(row))
        }
        save(context, items)
        for (item in items) scheduleOne(context, item)
    }

    private fun scheduleOne(context: Context, item: ReminderItem) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val operation = alarmPendingIntent(
            context,
            item.id,
            item.id,
            item.title,
            item.body,
            item.channelId,
            item.channelName,
            item.sound,
            item.soundUri,
        )
        val showIntent = PendingIntent.getActivity(
            context,
            item.id,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(item.triggerAtMillis, showIntent),
                operation,
            )
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
