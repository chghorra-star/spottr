package com.spottr.pose_camera

import android.content.Context
import android.util.Log
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseDetector
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min

/**
 * One run of the camera: capture, inference, and landmarks out.
 *
 * Owns a CameraX binding and an ML Kit detector, and emits a flat landmark
 * buffer per frame through [onFrame]. Pixels never leave this class — the
 * preview goes straight from CameraX into a Flutter texture, and the
 * analysis frames are closed as soon as the model has read them.
 */
internal class PoseCameraSession(
    private val context: Context,
    private val textures: TextureRegistry,
    private val onFrame: (frameId: Long, tUs: Long, confidence: Float, buffer: FloatArray) -> Unit,
    private val onError: (code: String, message: String) -> Unit,
) {
    private companion object {
        const val TAG = "PoseCameraSession"

        /**
         * Analysis target. Small on purpose: BlazePose downscales its input
         * anyway, and every pixel above this is heat and latency for no
         * accuracy. Preview asks for the same aspect ratio so that the
         * overlay, which maps normalized landmarks onto the preview box,
         * cannot end up stretched against it.
         */
        val TARGET = Size(480, 640)
    }

    /** A lifecycle we drive ourselves, so Dart decides when the camera runs. */
    private class SessionLifecycle : LifecycleOwner {
        private val registry = LifecycleRegistry(this)

        override val lifecycle: Lifecycle get() = registry

        fun resume() {
            registry.currentState = Lifecycle.State.RESUMED
        }

        fun destroy() {
            registry.currentState = Lifecycle.State.DESTROYED
        }
    }

    private val main = ContextCompat.getMainExecutor(context)
    private val analysisExecutor = Executors.newSingleThreadExecutor()

    private var detector: PoseDetector? = null
    private var provider: ProcessCameraProvider? = null
    private var owner: SessionLifecycle? = null
    private var producer: TextureRegistry.SurfaceProducer? = null

    private var frameId = 0L
    private var firstFrameNanos = 0L

    private var reportedFrames = 0
    private var reportedConfidence = 0f
    private var reportedSince = 0L

    /**
     * Opens [lens] and starts delivering frames.
     *
     * Replies through [onReady] with the geometry Dart needs to lay the
     * preview out, or through [onFailed] with one of the error codes the
     * Dart side knows how to translate.
     */
    fun start(
        lens: String,
        onReady: (Map<String, Any?>) -> Unit,
        onFailed: (String, String) -> Unit,
    ) {
        stop()

        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            try {
                bind(future.get(), lens, onReady)
            } catch (error: Throwable) {
                onFailed("noCamera", error.message ?: error.toString())
            }
        }, main)
    }

    private fun bind(
        cameraProvider: ProcessCameraProvider,
        lens: String,
        onReady: (Map<String, Any?>) -> Unit,
    ) {
        provider = cameraProvider

        val front = lens == "front"
        val selector = CameraSelector.Builder()
            .requireLensFacing(
                if (front) CameraSelector.LENS_FACING_FRONT else CameraSelector.LENS_FACING_BACK,
            )
            .build()

        if (!cameraProvider.hasCamera(selector)) {
            onError("noCamera", "no $lens camera on this device")
            return
        }

        val resolution = ResolutionSelector.Builder()
            .setAspectRatioStrategy(AspectRatioStrategy.RATIO_4_3_FALLBACK_AUTO_STRATEGY)
            .setResolutionStrategy(
                ResolutionStrategy(TARGET, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER),
            )
            .build()

        val surfaceProducer = textures.createSurfaceProducer()
        producer = surfaceProducer

        val preview = Preview.Builder().setResolutionSelector(resolution).build()
        preview.setSurfaceProvider { request ->
            surfaceProducer.setSize(request.resolution.width, request.resolution.height)
            request.provideSurface(surfaceProducer.surface, main) { }
        }

        val analysis = ImageAnalysis.Builder()
            .setResolutionSelector(resolution)
            // Drop frames rather than queue them. A backlog would make the
            // coach comment on a rep that finished a second ago, which is
            // worse than not commenting on it.
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()

        val poseDetector = PoseDetection.getClient(
            PoseDetectorOptions.Builder()
                .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
                .build(),
        )
        detector = poseDetector
        analysis.setAnalyzer(analysisExecutor) { proxy -> analyze(proxy, poseDetector) }

        frameId = 0
        firstFrameNanos = 0

        val lifecycle = SessionLifecycle()
        owner = lifecycle
        lifecycle.resume()

        try {
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(lifecycle, selector, preview, analysis)
        } catch (error: Throwable) {
            onError("cameraInUse", error.message ?: error.toString())
            return
        }

        // Portrait only — the coach screen locks it, because a phone propped
        // against a water bottle should not reorient the skeleton when it
        // tips. So the upright image is whichever way round is taller, and
        // no rotation arithmetic is needed to report it.
        val resolved = analysis.resolutionInfo?.resolution
        val width = resolved?.width ?: TARGET.width
        val height = resolved?.height ?: TARGET.height

        onReady(
            mapOf(
                "imageWidth" to min(width, height),
                "imageHeight" to max(width, height),
                "lens" to if (front) "front" else "back",
                // The front preview is shown mirrored, the way a gym mirror
                // is. Flutter does the flipping, to the preview and the
                // overlay together; the landmarks below are never flipped.
                "mirrored" to front,
                "textureId" to surfaceProducer.id(),
            ),
        )
    }

    private fun analyze(
        proxy: ImageProxy,
        poseDetector: PoseDetector,
    ) {
        val media = proxy.image
        if (media == null) {
            proxy.close()
            return
        }

        val rotation = proxy.imageInfo.rotationDegrees
        val (width, height) = LandmarkPacker.uprightSize(proxy.width, proxy.height, rotation)
        val timestamp = proxy.imageInfo.timestamp
        if (firstFrameNanos == 0L) firstFrameNanos = timestamp

        poseDetector
            .process(InputImage.fromMediaImage(media, rotation))
            .addOnSuccessListener { pose ->
                val landmarks = pose.allPoseLandmarks.map { landmark ->
                    SourceLandmark(
                        type = landmark.landmarkType,
                        x = landmark.position.x,
                        y = landmark.position.y,
                        z = landmark.position3D.z,
                        likelihood = landmark.inFrameLikelihood,
                    )
                }

                // A frame with nobody in it is still a frame. The framing
                // check needs it in order to say "I cannot see you", and
                // going silent would be indistinguishable from the camera
                // having died.
                val buffer = LandmarkPacker.pack(landmarks, width, height)
                val id = frameId++
                val micros = (timestamp - firstFrameNanos) / 1000

                val confidence = LandmarkPacker.confidence(landmarks)
                report(confidence)

                main.execute {
                    onFrame(id, micros, confidence, buffer)
                }
            }
            .addOnFailureListener { error ->
                Log.w(TAG, "pose detection failed", error)
                main.execute {
                    onError("modelFailed", error.message ?: error.toString())
                }
            }
            .addOnCompleteListener { proxy.close() }
    }

    /**
     * Once a second, how many frames got through and how sure the model was.
     *
     * The only window onto the pipeline from outside Dart, and the thing
     * that distinguishes "an empty room" from "no frames at all" — which
     * look identical on screen. A count and a mean, never a landmark: a
     * pose trace in the system log would be a copy of somebody's body
     * leaving the app, which is the one thing this design promises not to
     * do.
     */
    private fun report(confidence: Float) {
        if (!BuildConfig.DEBUG) return

        reportedFrames++
        reportedConfidence += confidence
        val now = System.nanoTime()
        if (reportedSince == 0L) reportedSince = now
        if (now - reportedSince < 1_000_000_000L) return

        Log.d(
            TAG,
            "$reportedFrames fps, mean confidence " +
                "${reportedConfidence / reportedFrames}",
        )
        reportedFrames = 0
        reportedConfidence = 0f
        reportedSince = now
    }

    /** Closes the camera. Safe to call when nothing is running. */
    fun stop() {
        provider?.unbindAll()
        owner?.destroy()
        owner = null
        provider = null

        detector?.close()
        detector = null

        producer?.release()
        producer = null
    }

    fun dispose() {
        stop()
        analysisExecutor.shutdown()
    }
}
