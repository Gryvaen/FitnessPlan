package com.fitnessplan.fitness_plan

/**
 * Pure counter transition; callers serialize persistence and supply the event's local day.
 *
 * [eventNanos] is the sensor event timestamp (only compared within one boot to
 * drop stale / replayed events). [elapsedNanos] is `SystemClock.elapsedRealtimeNanos()`
 * when the sample was processed; it bounds how many steps can physically have
 * happened, independent of how an OEM stamps sensor events.
 */
internal data class StepCounterState(
    val date: String,
    val bootId: String,
    val eventNanos: Long,
    val elapsedNanos: Long,
    val cumulative: Long,
    val steps: Int,
    val source: String,
    /** Consecutive same-boot samples below [cumulative]. */
    val lowStreak: Int = 0,
    /** [elapsedNanos] of the first sample in the current low streak. */
    val lowSinceNanos: Long = 0,
) {
    fun accept(day: String, boot: String, timestamp: Long, elapsed: Long, value: Long): StepCounterState {
        if (value < 0 || timestamp < 0 || elapsed < 0) return this
        val sameBoot = boot == bootId
        // A cached event must never overwrite a more recent service sample.
        if (sameBoot && timestamp <= eventNanos) return this
        if (day < date) return this
        val sameDay = day == date
        val keptSteps = if (sameDay) steps else 0
        val keptSource = if (sameDay) source else "day_anchor"

        if (sameBoot && value < cumulative) {
            // A decrease alone is not evidence of a reboot. Keep the high-water
            // mark so a later recovery cannot count the same steps a second time,
            // unless the counter stays low long enough to be a real sensor reset.
            val streak = lowStreak + 1
            val since = if (lowStreak == 0) elapsed else lowSinceNanos
            if (streak >= RESET_CONFIRM_SAMPLES && elapsed - since >= RESET_CONFIRM_NANOS) {
                return StepCounterState(day, boot, timestamp, elapsed, value, keptSteps, "sensor_reset")
            }
            return copy(
                date = day, eventNanos = timestamp, elapsedNanos = elapsed,
                steps = keptSteps, source = keptSource,
                lowStreak = streak, lowSinceNanos = since,
            )
        }

        val delta = if (sameBoot) value - cumulative else value
        // Since a reboot the window is the whole uptime; otherwise the gap
        // since the previous sample.
        val windowNanos = if (sameBoot) (elapsed - elapsedNanos).coerceAtLeast(0) else elapsed
        if (delta > maxPlausibleSteps(windowNanos)) {
            // Physically impossible jump: move the baseline, never add it.
            return StepCounterState(day, boot, timestamp, elapsed, value, keptSteps, "rate_rejected")
        }
        // A gap spanning midnight cannot reliably be assigned to either day.
        val total = if (sameDay) steps.toLong() + delta else 0L
        return StepCounterState(
            day, boot, timestamp, elapsed, value,
            total.coerceIn(0, Int.MAX_VALUE.toLong()).toInt(),
            if (!sameDay) "day_anchor" else if (!sameBoot) "confirmed_reboot" else source,
        )
    }

    /** Result of [advance]: the new state plus a closed-out day to archive, if any. */
    data class Advance(val state: StepCounterState, val archived: Pair<String, Int>?)

    companion object {
        /** Faster than any sustained human cadence (sprinting is ~4 steps/s). */
        private const val MAX_STEPS_PER_SECOND = 5L
        /** Slack for batching and rounding on short windows. */
        private const val STEP_ALLOWANCE = 1000L
        private const val RESET_CONFIRM_SAMPLES = 3
        private const val RESET_CONFIRM_NANOS = 5L * 60 * 1_000_000_000

        fun maxPlausibleSteps(windowNanos: Long): Long =
            windowNanos / 1_000_000_000 * MAX_STEPS_PER_SECOND + STEP_ALLOWANCE

        /**
         * Full transition including migration and day rollover. [bootToday]
         * says whether the current boot happened on [day], in which case
         * every step since boot belongs to today.
         */
        fun advance(
            previous: StepCounterState?,
            day: String,
            boot: String,
            timestamp: Long,
            elapsed: Long,
            value: Long,
            bootToday: Boolean,
        ): Advance {
            val sinceBoot = if (bootToday && value in 0..maxPlausibleSteps(elapsed)) value.toInt() else 0
            if (previous == null) {
                // Never import a legacy total: it may already carry a
                // cumulative counter that was mistaken for a reboot.
                return Advance(
                    StepCounterState(day, boot, timestamp, elapsed, value.coerceAtLeast(0), sinceBoot, "repair_anchor_v2"),
                    null,
                )
            }
            var next = previous.accept(day, boot, timestamp, elapsed, value)
            if (next.date == previous.date) return Advance(next, null)
            if (next.bootId != previous.bootId && next.source == "day_anchor" && sinceBoot > 0) {
                next = next.copy(steps = sinceBoot, source = "boot_today")
            }
            return Advance(next, previous.date to previous.steps)
        }
    }
}

/** Shared by every source, including midnight callbacks. */
internal object StepCounterTransaction {
    @Synchronized fun <T> run(block: () -> T): T = block()
}
