package com.fitnessplan.fitness_plan

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WorkoutReminderScheduler.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAll" -> {
                        val rawItems = call.argument<List<*>>("items")
                        if (rawItems == null) {
                            result.error("invalid_arguments", "Missing items", null)
                            return@setMethodCallHandler
                        }
                        val items = rawItems.mapNotNull { entry ->
                            val map = entry as? Map<*, *> ?: return@mapNotNull null
                            val id = (map["id"] as? Number)?.toInt()
                            val triggerAtMillis = (map["triggerAtMillis"] as? Number)?.toLong()
                            val title = map["title"] as? String
                            val body = map["body"] as? String
                            if (id == null || triggerAtMillis == null || title == null || body == null) {
                                null
                            } else {
                                WorkoutReminderScheduler.ReminderItem(
                                    id, triggerAtMillis, title, body,
                                )
                            }
                        }
                        WorkoutReminderScheduler.scheduleAll(this, items)
                        result.success(null)
                    }
                    "cancelAll" -> {
                        WorkoutReminderScheduler.cancelAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, StepCounterBridge.CHANNEL)
            .setMethodCallHandler { call, result ->
                StepCounterBridge.handle(this, call.method, result)
            }
    }
}
