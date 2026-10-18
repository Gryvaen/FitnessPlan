package com.fitnessplan.fitness_plan

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WorkoutReminderMissedTest {
    private val minute = 60_000L
    private val now = 1_000 * minute

    @Test fun onlyUndeliveredSlotsPastTheGraceAreOverdue() {
        val slots = listOf(
            now - 10 * minute to Long.MIN_VALUE, // never fired: blocked
            now - 10 * minute to now - 10 * minute, // delivered
            now - 1 * minute to Long.MIN_VALUE, // may still be on its way
            now + 60 * minute to Long.MIN_VALUE, // future
        )
        assertEquals(listOf(now - 10 * minute), WorkoutReminderScheduler.overdue(slots, now))
    }

    @Test fun lateDeliveryPastTheGraceIsReported() {
        assertTrue(WorkoutReminderScheduler.isLate(now - 7 * minute, now))
        assertFalse(WorkoutReminderScheduler.isLate(now - 30_000, now))
    }

    @Test fun missedLogIsDedupedSortedAndCapped() {
        assertEquals(listOf(1L, 2L, 3L), WorkoutReminderScheduler.mergeMissed(listOf(3L, 1L), listOf(2L, 3L)))
        val many = (1L..30L).toList()
        assertEquals((11L..30L).toList(), WorkoutReminderScheduler.mergeMissed(emptyList(), many))
    }
}
