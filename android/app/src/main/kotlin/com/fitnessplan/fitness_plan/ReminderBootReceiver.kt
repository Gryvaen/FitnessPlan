package com.fitnessplan.fitness_plan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            WorkoutReminderScheduler.restore(context)
        } catch (e: RuntimeException) {
            Log.e("ReminderAlarm", "Cannot restore reminder alarms", e)
        }
    }
}
