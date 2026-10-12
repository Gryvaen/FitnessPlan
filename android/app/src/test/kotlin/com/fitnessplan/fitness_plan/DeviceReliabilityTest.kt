package com.fitnessplan.fitness_plan

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class DeviceReliabilityTest {
    @Test fun firstCandidateOpens() {
        val attempted = mutableListOf<String>()
        val destination = DeviceReliability.launchFirstAvailable(listOf("oppo", "oneplus"), "battery", "details", {
            attempted += it
        })
        assertEquals(DeviceReliability.AutoStartDestination.OEM, destination)
        assertEquals(listOf("oppo"), attempted)
    }

    @Test fun continuesAfterFailedCandidates() {
        val attempted = mutableListOf<String>()
        val destination = DeviceReliability.launchFirstAvailable(listOf("oppo", "oneplus", "realme"), "battery", "details", {
            attempted += it
            if (it != "realme") throw SecurityException("unavailable")
        })
        assertEquals(DeviceReliability.AutoStartDestination.OEM, destination)
        assertEquals(listOf("oppo", "oneplus", "realme"), attempted)
    }

    @Test fun fallsBackToBatterySettings() {
        val attempted = mutableListOf<String>()
        val destination = DeviceReliability.launchFirstAvailable(listOf("oppo", "oneplus"), "battery", "details", {
            attempted += it
            if (it != "battery") throw SecurityException("unavailable")
        })
        assertEquals(DeviceReliability.AutoStartDestination.BATTERY, destination)
        assertEquals(listOf("oppo", "oneplus", "battery"), attempted)
    }

    @Test fun fallsBackToAppDetails() {
        val attempted = mutableListOf<String>()
        val destination = DeviceReliability.launchFirstAvailable(listOf("oppo"), "battery", "details", {
            attempted += it
            if (it != "details") throw SecurityException("unavailable")
        })
        assertEquals(DeviceReliability.AutoStartDestination.APP_DETAILS, destination)
        assertEquals(listOf("oppo", "battery", "details"), attempted)
    }

    @Test fun reportsWhenEveryPageFails() {
        val attempted = mutableListOf<String>()
        assertThrows(IllegalStateException::class.java) {
            DeviceReliability.launchFirstAvailable(listOf("oppo", "oneplus"), "battery", "details", {
                attempted += it
                throw SecurityException("unavailable")
            })
        }
        assertEquals(listOf("oppo", "oneplus", "battery", "details"), attempted)
    }
}
