package com.fitnessplan.fitness_plan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val missed = WorkoutReminderScheduler.restore(
                context,
                afterBoot = intent.action == Intent.ACTION_BOOT_COMPLETED ||
                    intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
                    intent.action == "com.htc.intent.action.QUICKBOOT_POWERON",
            )
            for (reminder in missed) {
                try {
                    WorkoutReminderReceiver.deliver(context, reminder)
                } catch (e: RuntimeException) {
                    Log.e("ReminderAlarm", "Cannot deliver missed reminder", e)
                }
            }
        } catch (e: RuntimeException) {
            Log.e("ReminderAlarm", "Cannot restore reminder alarms", e)
        }
    }
}
