package com.fitnessplan.fitness_plan

import java.io.File
import java.security.MessageDigest

/** Shared gate for foreground installation and background install notifications. */
object ApkIntegrity {
    fun matches(file: File, size: Long, sha256: String): Boolean {
        if (size <= 0 || !sha256.matches(Regex("[a-fA-F0-9]{64}"))) return false
        return try {
            file.isFile && file.length() == size && file.inputStream().use { input ->
                val digest = MessageDigest.getInstance("SHA-256")
                val buffer = ByteArray(65536)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    digest.update(buffer, 0, count)
                }
                digest.digest().joinToString("") { "%02x".format(it) }.equals(sha256, ignoreCase = true)
            }
        } catch (_: Exception) { false }
    }
}
