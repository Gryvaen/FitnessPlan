package com.fitnessplan.fitness_plan

import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.FileProvider
import java.io.File

/**
 * Picks up [DownloadManager.ACTION_DOWNLOAD_COMPLETE] even if the app
 * process was killed mid-download — this action is exempt from the
 * Android 8+ implicit-broadcast manifest restrictions, so a static
 * `<receiver>` registration still gets it. Posts a notification to install
 * the update: tapping a notification counts as direct user interaction, so
 * it can launch the installer even from the background, unlike starting it
 * straight from this receiver (which Android 10+ would block).
 */
class ApkDownloadCompleteReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        val downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
        if (downloadId < 0) return

        val info = ApkDownloader.query(context, downloadId)
        if (info["status"] != "success") return
        val localPath = info["localPath"] as? String ?: return
        val ownDir = context.getExternalFilesDir(null)?.absolutePath ?: return
        // This broadcast is fanned out to every app with a registered
        // receiver, not just the one that enqueued the download — only
        // handle downloads that actually landed in our own app-private
        // directory (nothing else could write there).
        if (!localPath.startsWith(ownDir)) return

        showInstallNotification(context, localPath)
    }

    private fun showInstallNotification(context: Context, apkPath: String) {
        val apkUri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileProvider.com.crazecoder.openfile",
            File(apkPath),
        )
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            installIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        createChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(context.getString(R.string.app_update_notification_title))
            .setContentText(context.getString(R.string.app_update_notification_body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        context.getSystemService(NotificationManager::class.java)
            ?.notify(NOTIFICATION_ID, notification)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.app_update_channel),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.app_update_channel_description)
        }
        context.getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "app_update_v1"
        private const val NOTIFICATION_ID = 73001
    }
}
