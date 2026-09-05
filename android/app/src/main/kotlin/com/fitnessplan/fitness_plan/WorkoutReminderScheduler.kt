package com.fitnessplan.fitness_plan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Schedules one-shot daily workout reminder alarms via [AlarmManager.setAlarmClock],
 * matching the rest-timer path that reliably wakes the device.
 */
object WorkoutReminderScheduler {
    const val CHANNEL = "fitness_plan/workout_reminder"
    const val EXTRA_NOTIFICATION_ID = "notification_id"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"

    private const val BASE_REQUEST_CODE = 72001
    private const val MAX_COUNT = 14

    fun scheduleAll(context: Context, items: List<ReminderItem>) {
        cancelAll(context)
        for (item in items) {
            scheduleOne(context, item)
        }
    }

    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        for (i in 0 until MAX_COUNT) {
            alarmManager.cancel(alarmPendingIntent(context, BASE_REQUEST_CODE + i, 0, "", ""))
        }
    }

    private fun scheduleOne(context: Context, item: ReminderItem) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val operation = alarmPendingIntent(
            context,
            item.id,
            item.id,
            item.title,
            item.body,
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
    ): PendingIntent {
        val intent = Intent(context, WorkoutReminderReceiver::class.java).apply {
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
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
    )
}
