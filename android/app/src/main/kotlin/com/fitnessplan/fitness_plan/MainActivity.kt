package com.fitnessplan.fitness_plan

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingRingtoneResult: MethodChannel.Result? = null

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
                            val channelId = map["channelId"] as? String
                            val channelName = map["channelName"] as? String
                            val sound = map["sound"] as? Boolean
                            val soundUri = map["soundUri"] as? String
                            if (id == null || triggerAtMillis == null || title == null ||
                                body == null || channelId == null || channelName == null || sound == null
                            ) {
                                null
                            } else {
                                WorkoutReminderScheduler.ReminderItem(
                                    id, triggerAtMillis, title, body, channelId, channelName, sound, soundUri,
                                )
                            }
                        }
                        val staleChannelIds =
                            (call.argument<List<*>>("staleChannelIds") ?: emptyList<Any?>())
                                .filterIsInstance<String>()
                        WorkoutReminderScheduler.scheduleAll(this, items, staleChannelIds)
                        result.success(null)
                    }
                    "cancelAll" -> {
                        WorkoutReminderScheduler.cancelAll(this)
                        result.success(null)
                    }
                    "pickRingtone" -> {
                        val currentUri = call.argument<String>("currentUri")
                        pendingRingtoneResult = result
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(
                                RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI,
                                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                            )
                            if (currentUri != null) {
                                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUri))
                            }
                        }
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, RINGTONE_PICKER_REQUEST_CODE)
                        } catch (e: Exception) {
                            pendingRingtoneResult = null
                            result.error("picker_unavailable", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, StepCounterBridge.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setStepService" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        StepCounterService.setEnabled(applicationContext, enabled)
                        result.success(null)
                    }
                    "isStepServiceEnabled" ->
                        result.success(StepCounterService.isEnabled(applicationContext))
                    else -> StepCounterBridge.handle(this, call, result)
                }
            }

        // Re-arm the background counter after a cold start / app update.
        StepCounterService.startIfEnabled(applicationContext)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != RINGTONE_PICKER_REQUEST_CODE) return
        val result = pendingRingtoneResult ?: return
        pendingRingtoneResult = null
        val uri = data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        if (uri == null) {
            result.success(mapOf("uri" to null, "title" to null))
            return
        }
        val title = try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        } catch (_: Exception) {
            null
        }
        result.success(mapOf("uri" to uri.toString(), "title" to title))
    }

    companion object {
        private const val RINGTONE_PICKER_REQUEST_CODE = 4271
    }
}
