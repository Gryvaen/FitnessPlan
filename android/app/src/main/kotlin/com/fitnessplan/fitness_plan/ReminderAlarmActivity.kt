package com.fitnessplan.fitness_plan

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.text.DateFormat
import java.util.Date

/** Native lock-screen alert shared by daily reminders and the rest timer. */
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
        val rest = intent.getBooleanExtra(EXTRA_REST_TIMER, false)
        val kind = if (rest) Kind.REST else kindForId(
            intent.getIntExtra(WorkoutReminderScheduler.EXTRA_NOTIFICATION_ID, 72001),
        )
        val palette = if (savedThemeIsDark()) DARK else LIGHT
        window.statusBarColor = palette.surface
        window.navigationBarColor = palette.surface
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = if (palette === LIGHT) {
            View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
        } else 0

        val title = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_TITLE)
            ?: getString(if (rest) R.string.rest_timer_alarm_title else R.string.workout_reminder_default_title)
        val body = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_BODY)
            ?: getString(if (rest) R.string.rest_timer_alarm_body else R.string.workout_reminder_default_body)
        val dismiss = intent.getStringExtra(RestTimerAlarmScheduler.EXTRA_DISMISS_LABEL)
            ?: getString(R.string.rest_timer_alarm_dismiss)
        val font = try {
            Typeface.createFromAsset(assets, "flutter_assets/assets/fonts/LXGWWenKaiLite-Medium.ttf")
        } catch (_: RuntimeException) {
            Typeface.DEFAULT
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(palette.surface)
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        header.addView(label(getString(kind.label), 15f, palette.accent, font),
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        header.addView(label(DateFormat.getTimeInstance(DateFormat.SHORT).format(Date()),
            15f, palette.muted, font).apply { gravity = Gravity.END })
        root.addView(header)

        val scroll = ScrollView(this).apply {
            isFillViewport = true
            clipToPadding = false
            setPadding(0, dp(20), 0, dp(20))
        }
        val center = FrameLayout(this)
        val message = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(32), dp(12), dp(32))
        }
        message.addView(ImageView(this).apply {
            contentDescription = getString(kind.label)
            val variant = if (palette === DARK) "dark" else "light"
            val path = "flutter_assets/assets/ink/icons/$variant/${kind.icon}-v1.png"
            try {
                assets.open(path).use { setImageBitmap(BitmapFactory.decodeStream(it)) }
                if (palette === DARK) imageTintList = ColorStateList.valueOf(palette.accent)
            } catch (_: Exception) {
                setImageResource(applicationInfo.icon)
            }
            scaleType = ImageView.ScaleType.FIT_CENTER
        }, LinearLayout.LayoutParams(dp(72), dp(72)).apply { bottomMargin = dp(28) })
        message.addView(label(title, 28f, palette.text, font).apply { gravity = Gravity.CENTER },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        message.addView(label(body, 18f, palette.muted, font).apply {
            gravity = Gravity.CENTER
            setLineSpacing(dp(4).toFloat(), 1f)
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(14) })
        center.addView(message, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER))
        scroll.addView(center)
        root.addView(scroll, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))

        root.addView(label(dismiss, 18f, palette.onAccent, font).apply {
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = true
            background = RippleDrawable(ColorStateList.valueOf(palette.ripple),
                rounded(palette.accent, 16), null)
            setOnClickListener {
                if (rest) RestTimerAlarmScheduler.cancel(this@ReminderAlarmActivity)
                else stopService(Intent(this@ReminderAlarmActivity, ReminderAlarmService::class.java))
                finish()
            }
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(56)))
        setContentView(root)
    }

    private fun label(textValue: String, size: Float, color: Int, font: Typeface) = TextView(this).apply {
        text = textValue
        textSize = size
        typeface = font
        setTextColor(color)
    }

    private fun savedThemeIsDark(): Boolean {
        val theme = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.app_theme_id", null)
        return theme in setOf("graphite", "night", "midnight", "aurora")
    }

    private fun kindForId(id: Int): Kind = when (id) {
        in 72101..72200 -> Kind.WATER
        in 72201..72300 -> Kind.MEAL
        in 72301..72400 -> Kind.WEIGHT
        else -> Kind.WORKOUT
    }

    private fun rounded(color: Int, radius: Int, border: Int? = null) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(radius).toFloat()
        if (border != null) setStroke(dp(1), border)
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density + 0.5f).toInt()

    private enum class Kind(val label: Int, val icon: String) {
        WORKOUT(R.string.reminder_alarm_workout, "training"),
        WATER(R.string.reminder_alarm_water, "water"),
        MEAL(R.string.reminder_alarm_meal, "food"),
        WEIGHT(R.string.reminder_alarm_weight, "weight"),
        REST(R.string.reminder_alarm_rest, "timer"),
    }

    private data class Palette(val surface: Int,
        val text: Int, val muted: Int, val accent: Int, val onAccent: Int, val ripple: Int)

    companion object {
        const val EXTRA_REST_TIMER = "rest_timer"
        private val LIGHT = Palette(
            Color.rgb(244, 241, 233),
            Color.rgb(32, 38, 36), Color.rgb(102, 112, 108), Color.rgb(21, 94, 91),
            Color.WHITE, Color.argb(50, 255, 255, 255),
        )
        private val DARK = Palette(
            Color.rgb(27, 30, 34),
            Color.rgb(236, 239, 242), Color.rgb(166, 174, 184), Color.rgb(126, 196, 198),
            Color.rgb(15, 31, 32), Color.argb(50, 15, 31, 32),
        )
    }
}
