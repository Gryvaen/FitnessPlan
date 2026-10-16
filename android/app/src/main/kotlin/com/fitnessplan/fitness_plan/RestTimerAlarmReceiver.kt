package com.fitnessplan.fitness_plan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import android.util.Log

class RestTimerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        RestTimerAlarmScheduler.recordDelay(context, intent)
        RestTimerAlarmScheduler.cancelCountdown(context)
        val serviceIntent = Intent(context, RestTimerAlarmService::class.java).apply {
            putExtras(intent)
        }
        try {
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (e: RuntimeException) {
            Log.e("RestTimerAlarm", "Alarm service blocked; posting fallback", e)
            RestTimerFallbackNotification.show(context, intent)
        }
    }
}
