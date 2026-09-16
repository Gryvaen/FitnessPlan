package com.fitnessplan.fitness_plan

import android.app.DownloadManager
import android.content.Context
import android.net.Uri

/**
 * Downloads an update APK via the system [DownloadManager] instead of a
 * plain Dart HTTP stream, so the download survives the app process being
 * backgrounded or killed — [DownloadManager] runs as its own system
 * service, independent of our process. Completion is picked up by
 * [ApkDownloadCompleteReceiver] (registered in the manifest) even when the
 * app isn't running.
 */
object ApkDownloader {
    const val CHANNEL = "fitness_plan/apk_downloader"

    fun enqueue(context: Context, url: String, fileName: String): Long {
        // Clear a stale file from a previous attempt so DownloadManager
        // doesn't append "(1)" to the destination name, which would break
        // the completion receiver's path check.
        context.getExternalFilesDir(null)?.resolve(fileName)?.let {
            if (it.exists()) it.delete()
        }
        val request = DownloadManager.Request(Uri.parse(url))
            .setDestinationInExternalFilesDir(context, null, fileName)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setTitle(fileName)
            .setMimeType("application/vnd.android.package-archive")
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        return manager.enqueue(request)
    }

    /** Returns `{status, bytesDownloaded, totalBytes, localPath, reason}`. */
    fun query(context: Context, downloadId: Long): Map<String, Any?> {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        manager.query(DownloadManager.Query().setFilterById(downloadId)).use { cursor ->
            if (!cursor.moveToFirst()) {
                return mapOf("status" to "missing")
            }
            val statusCol = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)
            val bytesCol = cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
            val totalCol = cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
            val uriCol = cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI)
            val reasonCol = cursor.getColumnIndex(DownloadManager.COLUMN_REASON)
            val status = when (cursor.getInt(statusCol)) {
                DownloadManager.STATUS_SUCCESSFUL -> "success"
                DownloadManager.STATUS_FAILED -> "failed"
                else -> "running"
            }
            val localUri = if (uriCol >= 0) cursor.getString(uriCol) else null
            return mapOf(
                "status" to status,
                "bytesDownloaded" to (if (bytesCol >= 0) cursor.getLong(bytesCol) else 0L),
                "totalBytes" to (if (totalCol >= 0) cursor.getLong(totalCol) else 0L),
                "localPath" to localUri?.let { Uri.parse(it).path },
                "reason" to (if (status == "failed" && reasonCol >= 0) cursor.getInt(reasonCol) else null),
            )
        }
    }

    fun cancel(context: Context, downloadId: Long) {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        manager.remove(downloadId)
    }
}
