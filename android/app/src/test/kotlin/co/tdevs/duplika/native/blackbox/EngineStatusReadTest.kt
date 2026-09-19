package co.tdevs.duplika.native.blackbox

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The behaviour that keeps the home screen drawing while the engine's server process has
 * stopped answering. Each test stands in for a real engine state rather than a code path:
 * a healthy engine, one that has gone quiet, and one that answers again afterwards.
 */
class EngineStatusReadTest {

    /** A read that answers is passed straight through, with no deadline in the way. */
    @Test
    fun answersDirectlyWhenTheEngineReplies() {
        assertTrue(EngineStatusRead.answer(key(), optimistic = false) { true })
        assertEquals(false, EngineStatusRead.answer(key(), optimistic = true) { false })
    }

    /**
     * The case the guard exists for: a call that never comes back. The caller has to be
     * answered anyway, and quickly — this is the home screen's per-clone status read, and
     * before the guard it blocked the whole grid for up to a minute.
     */
    @Test
    fun answersOptimisticallyWhenTheEngineGoesQuiet() {
        val release = CountDownLatch(1)
        val started = System.nanoTime()

        val answer = EngineStatusRead.answer(key(), optimistic = true) {
            release.await()
            false
        }

        val waited = (System.nanoTime() - started) / 1_000_000
        release.countDown()

        assertTrue("reported the optimistic answer", answer)
        assertTrue("waited $waited ms, which is not bounded", waited < 4_000)
    }

    /**
     * A question asked while the same one is still outstanding joins it rather than starting
     * another: a grid of clones refreshing against a quiet engine must not put a thread per
     * clone per refresh into a call that is not coming back.
     */
    @Test
    fun doesNotAskTheSameQuestionTwiceAtOnce() {
        val key = key()
        val release = CountDownLatch(1)
        val asked = AtomicInteger()

        val read = {
            asked.incrementAndGet()
            release.await()
            true
        }

        repeat(3) { EngineStatusRead.answer(key, optimistic = false, read = read) }
        release.countDown()

        assertEquals(1, asked.get())
    }

    /**
     * The abandoned call still lands, and what it said is what the next refresh reports —
     * so a clone that really was uninstalled stops being reported installed as soon as the
     * engine is able to say so, without the screen ever having waited for it.
     */
    @Test
    fun remembersTheLateAnswerForTheNextRefresh() {
        val key = key()
        val release = CountDownLatch(1)
        val landed = CountDownLatch(1)

        val first = EngineStatusRead.answer(key, optimistic = true) {
            release.await()
            landed.countDown()
            false
        }
        assertTrue("answered optimistically while the engine was quiet", first)

        release.countDown()
        assertTrue("the read landed", landed.await(5, TimeUnit.SECONDS))
        // The recorded answer is written as the task completes, just after the read returns.
        Thread.sleep(200)

        val second = EngineStatusRead.answer(key, optimistic = true) {
            Thread.sleep(10_000)
            true
        }
        assertEquals("reported what the engine last said", false, second)
    }

    /** [EngineStatusRead] is a singleton, so every test needs a key of its own. */
    private fun key(): String = "test:${keys.incrementAndGet()}:pkg"

    private companion object {
        val keys = AtomicInteger()
    }
}
