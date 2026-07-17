package com.fitnessplan.fitness_plan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object RestTimerAlarmScheduler {
    const val CHANNEL = "fitness_plan/rest_timer_alarm"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"
    const val EXTRA_DISMISS_LABEL = "dismiss_label"
    private const val REQUEST_CODE = 71001

    fun schedule(
        context: Context,
        triggerAtMillis: Long,
        title: String,
        body: String,
        dismissLabel: String,
    ) {
        cancel(context)
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val operation = alarmPendingIntent(context, title, body, dismissLabel)
        val showIntent = PendingIntent.getActivity(
            context,
            REQUEST_CODE,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent),
                operation,
            )
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAtMillis, operation,
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, operation)
            }
        }
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)
            .cancel(alarmPendingIntent(context, "", "", ""))
        context.stopService(Intent(context, RestTimerAlarmService::class.java))
    }

    private fun alarmPendingIntent(
        context: Context,
        title: String,
        body: String,
        dismissLabel: String,
    ): PendingIntent {
        val intent = Intent(context, RestTimerAlarmReceiver::class.java).apply {
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_DISMISS_LABEL, dismissLabel)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
