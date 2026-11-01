package com.spottr.pose_camera

/**
 * One landmark as the model reported it, in pixels of the upright image.
 *
 * A plain data class rather than ML Kit's `PoseLandmark` so that the packing
 * — the part where an off-by-one silently remaps every joint in the app —
 * can be tested without a device, a camera or the ML Kit runtime.
 */
internal data class SourceLandmark(
    val type: Int,
    val x: Float,
    val y: Float,
    val z: Float,
    val likelihood: Float,
)

/**
 * Packs landmarks into the flat buffer the Dart side decodes.
 *
 * The format is `pose_core`'s `PoseFrameCodec`: 33 joints in BlazePose
 * index order, four floats each — x, y, z, visibility — with x and y
 * normalized to 0..1 and NaN standing in for a joint the model did not
 * place.
 *
 * Nothing here mirrors anything. The front lens is *displayed* mirrored,
 * but that is a presentation decision and it is made once, in Flutter,
 * where the preview and the overlay are flipped together and therefore
 * cannot drift apart. Landmarks that cross the bridge are always in the
 * camera's own left-to-right space, so no form rule ever has to ask which
 * lens it is reading.
 */
internal object LandmarkPacker {
    /** Floats per landmark: x, y, z, visibility. */
    const val STRIDE = 4

    /** The BlazePose landmark count. */
    const val COUNT = 33

    const val LENGTH = COUNT * STRIDE

    /**
     * @param width width of the upright image the landmarks were measured in
     * @param height height of the upright image
     */
    fun pack(
        landmarks: List<SourceLandmark>,
        width: Int,
        height: Int,
    ): FloatArray {
        require(width > 0 && height > 0) { "image size must be positive, got ${width}x$height" }

        val buffer = FloatArray(LENGTH)
        // Absent by default. Every joint has a slot whether the model filled
        // it or not, and (0, 0) is the top left corner of the image, which a
        // form rule cannot tell apart from a real measurement.
        for (joint in 0 until COUNT) {
            buffer[joint * STRIDE] = Float.NaN
            buffer[joint * STRIDE + 1] = Float.NaN
        }

        for (landmark in landmarks) {
            if (landmark.type < 0 || landmark.type >= COUNT) continue
            val base = landmark.type * STRIDE
            buffer[base] = landmark.x / width
            buffer[base + 1] = landmark.y / height
            // z arrives in roughly the same scale as x; normalizing by width
            // keeps the three axes comparable, which is all a loosely
            // calibrated depth is good for.
            buffer[base + 2] = landmark.z / width
            buffer[base + 3] = landmark.likelihood
        }

        return buffer
    }

    /**
     * Mean in-frame likelihood, which is what stands in for a pose-level
     * confidence.
     *
     * ML Kit does not report one. The mean is honest about what it is: a
     * frame where half the body is guessed at scores low, and a frame with
     * no pose at all scores zero, which is exactly what the framing check
     * needs in order to say "I cannot see anybody".
     */
    fun confidence(landmarks: List<SourceLandmark>): Float {
        if (landmarks.isEmpty()) return 0f
        var total = 0f
        for (landmark in landmarks) total += landmark.likelihood
        return total / COUNT
    }

    /**
     * The image size after [rotationDegrees] is applied.
     *
     * ML Kit returns landmarks in the upright frame, so normalizing by the
     * sensor's own width and height transposes the whole skeleton on a
     * portrait phone — the single easiest way to get this wrong.
     */
    fun uprightSize(
        width: Int,
        height: Int,
        rotationDegrees: Int,
    ): Pair<Int, Int> =
        if (rotationDegrees == 90 || rotationDegrees == 270) {
            height to width
        } else {
            width to height
        }
}
