package com.spottr.pose_camera

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/**
 * The native half of the wire contract.
 *
 * These cover the arithmetic that cannot be checked from Dart: the joint
 * ordinal to buffer offset mapping, the normalization, and the rotation
 * transpose. Everything downstream of the buffer is covered by
 * `pose_core/test/pose_frame_codec_test.dart`.
 *
 * **These do not run in CI yet.** A Gradle unit test needs an example app
 * to host it and this plugin has none; see `docs/dev-loop.md`.
 */
internal class LandmarkPackerTest {
    private fun landmark(
        type: Int,
        x: Float,
        y: Float,
        likelihood: Float = 1f,
    ) = SourceLandmark(type = type, x = x, y = y, z = 0f, likelihood = likelihood)

    @Test
    fun bufferMatchesTheDartContract() {
        assertEquals(4, LandmarkPacker.STRIDE)
        assertEquals(33, LandmarkPacker.COUNT)
        assertEquals(132, LandmarkPacker.LENGTH)
        assertEquals(132, LandmarkPacker.pack(emptyList(), 480, 640).size)
    }

    @Test
    fun writesEachJointAtItsOrdinalOffset() {
        // 25 is the left knee. Landing it anywhere else remaps every joint
        // in the app, and nothing downstream could tell.
        val buffer = LandmarkPacker.pack(listOf(landmark(25, 120f, 320f)), 480, 640)

        assertEquals(0.25f, buffer[25 * 4])
        assertEquals(0.5f, buffer[25 * 4 + 1])
        assertEquals(1f, buffer[25 * 4 + 3])
    }

    @Test
    fun normalizesByTheImageItWasGiven() {
        val buffer = LandmarkPacker.pack(listOf(landmark(0, 240f, 160f)), 480, 640)

        assertEquals(0.5f, buffer[0])
        assertEquals(0.25f, buffer[1])
    }

    @Test
    fun marksAJointTheModelDidNotPlaceAsAbsent() {
        val buffer = LandmarkPacker.pack(listOf(landmark(11, 100f, 100f)), 480, 640)

        assertTrue(buffer[11 * 4].isFinite())
        assertTrue(buffer[12 * 4].isNaN())
        assertTrue(buffer[12 * 4 + 1].isNaN())
    }

    @Test
    fun ignoresALandmarkTypeOutsideTheContract() {
        // A newer ML Kit model with more landmarks must not write past the
        // end of the buffer or shift the joints that follow.
        val buffer = LandmarkPacker.pack(listOf(landmark(99, 10f, 10f)), 480, 640)

        assertEquals(132, buffer.size)
        assertTrue(buffer.all { it.isNaN() || it == 0f })
    }

    @Test
    fun doesNotMirrorAnything() {
        // Mirroring the front lens is a presentation decision, made once in
        // Flutter where the preview and the overlay flip together. A flip
        // here as well would cancel it out and nothing would look wrong
        // until a form rule read a left knee on the right.
        val buffer = LandmarkPacker.pack(listOf(landmark(25, 96f, 320f)), 480, 640)

        assertEquals(0.2f, buffer[25 * 4])
    }

    @Test
    fun rejectsAnImpossibleImageSize() {
        assertFailsWith<IllegalArgumentException> {
            LandmarkPacker.pack(listOf(landmark(0, 1f, 1f)), 0, 640)
        }
    }

    @Test
    fun confidenceIsZeroWhenThereIsNoPose() {
        assertEquals(0f, LandmarkPacker.confidence(emptyList()))
    }

    @Test
    fun confidenceAveragesOverEveryJointNotJustTheReportedOnes() {
        // Dividing by the number of landmarks reported would score a frame
        // holding one confident elbow as a perfect pose.
        val one = LandmarkPacker.confidence(listOf(landmark(13, 1f, 1f, 1f)))

        assertTrue(one < 0.05f)
    }

    @Test
    fun confidenceIsOneForAFullyTrackedBody() {
        val all = (0 until 33).map { landmark(it, 1f, 1f, 1f) }

        assertEquals(1f, LandmarkPacker.confidence(all))
    }

    @Test
    fun transposesTheImageSizeForAQuarterTurn() {
        assertEquals(480 to 640, LandmarkPacker.uprightSize(480, 640, 0))
        assertEquals(480 to 640, LandmarkPacker.uprightSize(480, 640, 180))
        assertEquals(640 to 480, LandmarkPacker.uprightSize(480, 640, 90))
        assertEquals(640 to 480, LandmarkPacker.uprightSize(480, 640, 270))
    }
}
