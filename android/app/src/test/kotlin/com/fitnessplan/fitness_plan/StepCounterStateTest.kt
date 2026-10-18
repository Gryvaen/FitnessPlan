package com.fitnessplan.fitness_plan

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class StepCounterStateTest {
    private val sec = 1_000_000_000L
    private val initial = StepCounterState("2026-10-18", "6", 100 * sec, 100 * sec, 110000, 1200, "anchor")

    /** [time] is seconds; it stamps both the sensor event and elapsed realtime. */
    private fun StepCounterState.sample(value: Long, time: Long, boot: String = "6", day: String = date) =
        accept(day, boot, time * sec, time * sec, value)

    @Test fun duplicateAndOutOfOrderAreIgnored() {
        val current = initial.sample(110010, 110)
        assertEquals(current, current.sample(110020, 110))
        assertEquals(current, current.sample(100, 105))
        assertEquals(1211, current.sample(110011, 111).steps)
    }

    @Test fun rollbackNeverAddsTheCumulativeCounter() {
        val rollback = initial.sample(109990, 110)
        assertEquals(1200, rollback.steps)
        assertEquals(110000L, rollback.cumulative)
        assertEquals(1200, rollback.sample(110000, 120).steps)
        assertEquals(1203, rollback.sample(110003, 130).steps)
    }

    @Test fun confirmedRebootAddsNewBootStepsOnce() {
        val reboot = initial.sample(20, 5, boot = "7")
        assertEquals(1220, reboot.steps)
        assertEquals(1220, reboot.sample(20, 5, boot = "7").steps)
        assertEquals(1222, reboot.sample(22, 10, boot = "7").steps)
    }

    @Test fun rebootIsDetectedEvenIfNewCounterIsLarger() {
        // Up for 7 hours since the reboot: 110k steps is plausible.
        assertEquals(111201, initial.sample(110001, 7 * 3600, boot = "7").steps)
    }

    @Test fun impossibleJumpIsRebasedNotAdded() {
        val jumped = initial.sample(220000, 160)
        assertEquals(1200, jumped.steps)
        assertEquals("rate_rejected", jumped.source)
        assertEquals(220000L, jumped.cumulative)
        assertEquals(1205, jumped.sample(220005, 170).steps)
    }

    @Test fun spuriousRebootWithWholeCounterIsRejected() {
        // A boot id that changes a minute "after boot" cannot carry 110k steps.
        val bogus = initial.sample(110001, 60, boot = "7")
        assertEquals(1200, bogus.steps)
        assertEquals("rate_rejected", bogus.source)
    }

    @Test fun persistentLowCounterIsTreatedAsSensorReset() {
        val reset = initial.sample(10, 110).sample(20, 200).sample(30, 500)
        assertEquals("sensor_reset", reset.source)
        assertEquals(1200, reset.steps)
        assertEquals(30L, reset.cumulative)
        assertEquals(1210, reset.sample(40, 510).steps)
    }

    @Test fun briefLowBurstKeepsHighWaterMark() {
        val burst = initial.sample(10, 110).sample(20, 120).sample(30, 130)
        assertEquals(110000L, burst.cumulative)
        assertEquals(1205, burst.sample(110005, 140).steps)
    }

    @Test fun dayBoundaryAnchorsOnceAndDelayedAlarmDoesNotResetAgain() {
        val next = initial.sample(110020, 120, day = "2026-10-19")
        assertEquals(0, next.steps)
        val walking = next.sample(110027, 130)
        assertEquals(7, walking.steps)
        assertEquals(walking, walking.sample(110020, 120))
        assertEquals(walking, walking.sample(110030, 140, day = "2026-10-18"))
    }

    @Test fun migrationAnchorDoesNotImportLegacyTotal() {
        val anchor = StepCounterState("2026-10-18", "6", 100 * sec, 100 * sec, 110000, 0, "repair_anchor_v2")
        assertEquals(0, anchor.sample(110000, 101).steps)
        assertEquals(5, anchor.sample(110005, 105).steps)
    }

    @Test fun rollbackAtMidnightCannotLeakYesterdayTotal() {
        val next = initial.sample(100, 120, day = "2026-10-19")
        assertEquals("2026-10-19", next.date)
        assertEquals(0, next.steps)
        assertEquals(110000L, next.cumulative)
        assertEquals(3, next.sample(110003, 130).steps)
    }

    @Test fun foregroundServiceAndAlarmShareSerializedUpdates() {
        var state = initial
        val pool = Executors.newFixedThreadPool(3)
        val start = CountDownLatch(1)
        try {
            val work = (1..3).map {
                pool.submit {
                    start.await()
                    for (i in 1..100) {
                        StepCounterTransaction.run {
                            state = state.sample(110000L + i, 100L + i)
                        }
                    }
                }
            }
            start.countDown()
            work.forEach { it.get(5, TimeUnit.SECONDS) }
            assertEquals(1300, state.steps)
            assertEquals(110100L, state.cumulative)
        } finally {
            pool.shutdownNow()
        }
    }

    @Test fun invalidAndOverflowValuesCannotCorruptTotal() {
        assertEquals(initial, initial.sample(-1, 110))
        assertEquals(1200, initial.sample(Long.MAX_VALUE - 1200, 110).steps)
        val nearMax = initial.copy(steps = Int.MAX_VALUE - 5)
        assertEquals(Int.MAX_VALUE, nearMax.sample(110010, 110).steps)
    }

    private fun advance(
        previous: StepCounterState?,
        value: Long,
        time: Long,
        boot: String = "6",
        day: String = "2026-10-18",
        bootToday: Boolean = false,
    ) = StepCounterState.advance(previous, day, boot, time * sec, time * sec, value, bootToday)

    @Test fun firstRunAnchorsAtZeroUnlessBootedToday() {
        val stale = advance(null, 28441, 6 * 86400)
        assertEquals(0, stale.state.steps)
        assertEquals("repair_anchor_v2", stale.state.source)
        assertNull(stale.archived)
        assertEquals(300, advance(null, 300, 3600, bootToday = true).state.steps)
    }

    @Test fun dayRolloverArchivesPreviousDay() {
        val next = advance(initial, 110050, 200, day = "2026-10-19")
        assertEquals("2026-10-18" to 1200, next.archived)
        assertEquals(0, next.state.steps)
        assertNull(advance(initial, 110050, 200).archived)
    }

    @Test fun rebootTodaySeedsNewDayWithStepsSinceBoot() {
        val seeded = advance(initial, 300, 3600, boot = "7", day = "2026-10-19", bootToday = true)
        assertEquals(300, seeded.state.steps)
        assertEquals("boot_today", seeded.state.source)
        assertEquals("2026-10-18" to 1200, seeded.archived)
        // Booted a minute ago: 110k since boot is impossible, so no seed.
        val bogus = advance(initial, 110000, 60, boot = "7", day = "2026-10-19", bootToday = true)
        assertEquals(0, bogus.state.steps)
    }
}
