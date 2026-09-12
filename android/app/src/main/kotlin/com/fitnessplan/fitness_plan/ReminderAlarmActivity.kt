package com.fitnessplan.fitness_plan

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/** Lock-screen alarm controls; does not unlock the device or open user records. */
class ReminderAlarmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        }
        showAlarm()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        showAlarm()
    }

    private fun showAlarm() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val padding = (24 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
        }
        layout.addView(TextView(this).apply {
            text = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_TITLE)
                ?: getString(R.string.workout_reminder_default_title)
            textSize = 28f
            gravity = Gravity.CENTER
        })
        layout.addView(TextView(this).apply {
            text = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_BODY)
                ?: getString(R.string.workout_reminder_default_body)
            textSize = 18f
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 32)
        })
        layout.addView(Button(this).apply {
            text = getString(R.string.rest_timer_alarm_dismiss)
            setOnClickListener {
                stopService(Intent(this@ReminderAlarmActivity, ReminderAlarmService::class.java))
                finish()
            }
        })
        setContentView(layout)
    }
}
