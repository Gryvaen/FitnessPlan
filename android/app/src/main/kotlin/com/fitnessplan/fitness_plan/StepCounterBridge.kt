package com.fitnessplan.fitness_plan

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * One-shot read of [Sensor.TYPE_STEP_COUNTER] (cumulative steps since last reboot).
 * Used as a fallback when Health Connect has no step data (common on OPPO / ColorOS).
 */
object StepCounterBridge {
    const val CHANNEL = "fitness_plan/step_counter"

    fun handle(context: Context, method: String, result: MethodChannel.Result) {
        when (method) {
            "readCumulativeSteps" -> readCumulativeSteps(context, result)
            "isAvailable" -> {
                val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
                result.success(sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null)
            }
            else -> result.notImplemented()
        }
    }

    private fun readCumulativeSteps(context: Context, result: MethodChannel.Result) {
        val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensor == null) {
            result.success(null)
            return
        }

        val done = AtomicBoolean(false)
        val mainHandler = Handler(Looper.getMainLooper())

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (!done.compareAndSet(false, true)) return
                sensorManager.unregisterListener(this)
                result.success(event.values[0].toLong())
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        val registered = sensorManager.registerListener(
            listener,
            sensor,
            SensorManager.SENSOR_DELAY_NORMAL,
        )
        if (!registered) {
            result.success(null)
            return
        }

        mainHandler.postDelayed({
            if (!done.compareAndSet(false, true)) return@postDelayed
            sensorManager.unregisterListener(listener)
            result.success(null)
        }, 2500)
    }
}
