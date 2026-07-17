package com.fitnessplan.fitness_plan

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RestTimerAlarmScheduler.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val triggerAtMillis = call.argument<Number>("triggerAtMillis")?.toLong()
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        val dismissLabel = call.argument<String>("dismissLabel")
                        if (triggerAtMillis == null || title == null || body == null || dismissLabel == null) {
                            result.error("invalid_arguments", "Missing alarm arguments", null)
                            return@setMethodCallHandler
                        }
                        RestTimerAlarmScheduler.schedule(
                            this, triggerAtMillis, title, body, dismissLabel,
                        )
                        result.success(null)
                    }
                    "cancel" -> {
                        RestTimerAlarmScheduler.cancel(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
