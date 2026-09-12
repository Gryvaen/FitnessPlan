package com.fitnessplan.fitness_plan

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

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
    /** Manufacturers known for this kind of background restriction. */
    private val AGGRESSIVE_BRANDS = setOf(
        "oppo", "oneplus", "realme", "xiaomi", "redmi", "poco",
        "huawei", "honor", "vivo", "iqoo", "meizu", "letv", "lenovo",
    )

    fun isAggressiveOem(): Boolean {
        val brand = Build.BRAND.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        return AGGRESSIVE_BRANDS.any { brand.contains(it) || manufacturer.contains(it) }
    }

    fun manufacturer(): String = Build.MANUFACTURER

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

    /**
     * Best-effort deep link into the OEM's own "auto-start" / "allow
     * background running" management screen — these have no stable public
     * API and have moved/renamed across OS versions, so every candidate is
     * tried in order and the first one whose target actually resolves on
     * this device wins. Falls back to the app's own system details page
     * (always resolvable) when none of them do.
     */
    fun autoStartIntent(context: Context): Intent {
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
        for (intent in candidates) {
            if (intent.resolveActivity(context.packageManager) != null) return intent
        }
        // Every OEM screen understands its own app's details page; falling
        // back here still gets the user one tap from "Battery" / "Auto-start".
        return Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${context.packageName}")
        }
    }

    private fun componentIntent(pkg: String, cls: String): Intent {
        return Intent().apply {
            component = android.content.ComponentName(pkg, cls)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
