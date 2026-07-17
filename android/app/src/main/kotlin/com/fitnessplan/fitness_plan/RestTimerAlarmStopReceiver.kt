package com.fitnessplan.fitness_plan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class RestTimerAlarmStopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        RestTimerAlarmScheduler.cancel(context)
    }
}
