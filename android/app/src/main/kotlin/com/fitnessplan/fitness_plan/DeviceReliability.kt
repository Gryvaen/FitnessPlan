package com.fitnessplan.fitness_plan

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Helpers for the background-restriction workarounds several Android OEM
 * skins need before a scheduled reminder can reliably ring/vibrate/fire at
 * all — most notoriously ColorOS (OPPO / OnePlus / Realme), MIUI (Xiaomi /
 * Redmi / POCO), EMUI/HarmonyOS (Huawei / Honor) and OriginOS/FuntouchOS
 * (vivo). These skins layer their own aggressive Doze-like background
 * killer and a separate per-app "auto-start" / "allow background running"
 * toggle on top of stock Android, neither of which [AlarmManager] or the
 * notification-channel APIs can satisfy on their own — the OS can silently
 * drop the alarm, or fire it but mute its sound/vibration, regardless of
 * how the channel itself is configured. There's no supported API to grant
 * these programmatically; the best an app can do is detect the situation
 * and hand the user directly to the right settings screen.
 */
object DeviceReliability {
    enum class AutoStartDestination(val wireValue: String) {
        OEM("oem"), BATTERY("battery"), APP_DETAILS("appDetails"),
    }

    /** Manufacturers known for this kind of background restriction. */
    private val AGGRESSIVE_BRANDS = setOf(
        "oppo", "oneplus", "realme", "xiaomi", "redmi", "poco",
        "huawei", "honor", "vivo", "iqoo", "meizu", "letv", "lenovo",
    )

    fun isAggressiveOem(): Boolean {
        // A custom ROM does not inherit MIUI/ColorOS background controls just
        // because the physical handset was made by one of those vendors.
        if (Build.DISPLAY.lowercase().contains("lineage")) return false
        val brand = Build.BRAND.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        return AGGRESSIVE_BRANDS.any { brand.contains(it) || manufacturer.contains(it) }
    }

    fun manufacturer(): String = Build.MANUFACTURER

    /** Null means the platform cannot report this restriction. */
    fun isBackgroundRestricted(context: Context): Boolean? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            activityManager?.isBackgroundRestricted
        } catch (e: Exception) {
            Log.w("ReminderSettings", "Cannot read background restriction state", e)
            null
        }
    }

    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            ?: return true
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    /** System dialog asking the user to exempt this app from battery optimization. */
    fun batteryOptimizationIntent(context: Context): Intent {
        return Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
        }
    }

    /** Tries OEM screens, then per-app battery settings, then app details. */
    fun openAutoStartSettings(context: Context): AutoStartDestination {
        val candidates = listOf(
            // ColorOS (OPPO / OnePlus / Realme).
            componentIntent("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
            componentIntent("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
            componentIntent("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
            // MIUI (Xiaomi / Redmi / POCO).
            componentIntent("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
            // EMUI / HarmonyOS (Huawei / Honor).
            componentIntent("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
            componentIntent("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
            // OriginOS / FuntouchOS (vivo / iQOO).
            componentIntent("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
            componentIntent("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
            // Flyme (Meizu).
            componentIntent("com.meizu.safe", "com.meizu.safe.permission.SmartBGActivity"),
        )
        val packageUri = Uri.parse("package:${context.packageName}")
        val batterySettings = Intent("android.settings.VIEW_ADVANCED_POWER_USAGE_DETAIL").apply {
            data = packageUri
        }
        val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = packageUri
        }
        return launchFirstAvailable(candidates, batterySettings, appDetails, context::startActivity) { intent, error ->
            Log.w("ReminderSettings", "Cannot open ${intent.component ?: intent.action}", error)
        }
    }

    /** The launcher is injected so the candidate/fallback flow can be tested. */
    internal fun <T> launchFirstAvailable(
        candidates: List<T>,
        batterySettings: T,
        appDetails: T,
        launch: (T) -> Unit,
        onFailure: (T, RuntimeException) -> Unit = { _, _ -> },
    ): AutoStartDestination {
        for (candidate in candidates) {
            try {
                launch(candidate)
                return AutoStartDestination.OEM
            } catch (e: RuntimeException) {
                onFailure(candidate, e)
            }
        }
        try {
            launch(batterySettings)
            return AutoStartDestination.BATTERY
        } catch (e: RuntimeException) {
            onFailure(batterySettings, e)
        }
        try {
            launch(appDetails)
            return AutoStartDestination.APP_DETAILS
        } catch (e: RuntimeException) {
            onFailure(appDetails, e)
            throw IllegalStateException("No settings page can be opened", e)
        }
    }

    private fun componentIntent(pkg: String, cls: String): Intent {
        return Intent().apply {
            component = android.content.ComponentName(pkg, cls)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
