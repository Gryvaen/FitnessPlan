package com.fitnessplan.fitness_plan

import java.io.File
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ApkIntegrityTest {
    private val abcHash = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

    @Test fun verifiesKnownDigestAndSize() {
        val file = File.createTempFile("apk-integrity", ".apk")
        try {
            file.writeText("abc")
            assertTrue(ApkIntegrity.matches(file, 3, abcHash))
            assertFalse(ApkIntegrity.matches(file, 4, abcHash))
            assertFalse(ApkIntegrity.matches(file, 3, "0".repeat(64)))
            assertFalse(ApkIntegrity.matches(file, 3, ""))
            assertFalse(ApkIntegrity.matches(file, 0, abcHash))
            file.delete()
            assertFalse(ApkIntegrity.matches(file, 3, abcHash))
        } finally { file.delete() }
    }
}
