package com.fitnessplan.fitness_plan

import android.app.DownloadManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import java.io.File

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

    fun enqueue(context: Context, url: String, fileName: String, size: Long, sha256: String): Long {
        require(size > 0 && sha256.matches(Regex("[a-fA-F0-9]{64}"))) { "Missing checksum" }
        require(File(fileName).name == fileName && fileName.endsWith(".apk")) { "Invalid filename" }
        require(Uri.parse(url).scheme == "https") { "HTTPS required" }
        // Each attempt gets its own destination. An older install notification
        // must never point at a new file that is still being downloaded.
        val destination = "${System.currentTimeMillis()}-$fileName"
        val request = DownloadManager.Request(Uri.parse(url))
            .setDestinationInExternalFilesDir(context, null, destination)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setTitle(fileName)
            .setMimeType("application/vnd.android.package-archive")
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
        // GitHub's REST asset endpoint serves the file itself only when asked
        // for octet-stream (see isGithubApiAssetUrl in app_update_repository.dart).
        if (Uri.parse(url).host == "api.github.com") {
            request.addRequestHeader("Accept", "application/octet-stream")
        }
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val id = manager.enqueue(request)
        context.getSharedPreferences("apk_integrity", Context.MODE_PRIVATE).edit()
            .putLong("$id.size", size).putString("$id.sha256", sha256.lowercase()).commit()
        return id
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
                "waitingForNetwork" to (!hasNetwork(context) || cursor.getInt(statusCol) == DownloadManager.STATUS_PAUSED &&
                    cursor.getInt(reasonCol) in listOf(DownloadManager.PAUSED_WAITING_FOR_NETWORK, DownloadManager.PAUSED_QUEUED_FOR_WIFI)),
                "reason" to (if (status == "failed" && reasonCol >= 0) cursor.getInt(reasonCol) else null),
            )
        }
    }

    private fun hasNetwork(context: Context): Boolean {
        val manager = context.getSystemService(ConnectivityManager::class.java)
        val capabilities = manager.getNetworkCapabilities(manager.activeNetwork) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    @Synchronized
    fun verify(context: Context, downloadId: Long): Boolean {
        val prefs = context.getSharedPreferences("apk_integrity", Context.MODE_PRIVATE)
        val expected = prefs.getString("$downloadId.sha256", null) ?: return false
        val info = query(context, downloadId)
        if (info["status"] != "success") return false
        val file = File(info["localPath"] as? String ?: return false)
        val root = context.getExternalFilesDir(null)?.canonicalFile ?: return false
        if (file.canonicalFile.parentFile != root) return false
        val valid = ApkIntegrity.matches(file, prefs.getLong("$downloadId.size", -1L), expected)
        if (!valid) file.delete()
        return valid
    }

    fun cancel(context: Context, downloadId: Long) {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        manager.remove(downloadId)
        context.getSharedPreferences("apk_integrity", Context.MODE_PRIVATE).edit()
            .remove("$downloadId.size").remove("$downloadId.sha256").apply()
    }
}
