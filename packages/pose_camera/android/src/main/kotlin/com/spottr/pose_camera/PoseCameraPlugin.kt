package com.spottr.pose_camera

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry

/**
 * The native half of the pose camera.
 *
 * Two channels. Control calls — permission, start, stop — are request and
 * reply and go over a [MethodChannel]. Landmark frames are a one-way
 * firehose at camera rate and go over an [EventChannel], where each costs
 * one message instead of a call and a reply.
 *
 * No pixel buffer is ever sent. The preview goes from CameraX straight into
 * a Flutter texture, and analysis frames are released as soon as the model
 * has read them.
 */
class PoseCameraPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private companion object {
        const val CONTROL_CHANNEL = "spottr/pose_camera"
        const val FRAMES_CHANNEL = "spottr/pose_camera/frames"
        const val PERMISSION_REQUEST = 0x5074 // "Sp"
    }

    private lateinit var control: MethodChannel
    private lateinit var frames: EventChannel
    private lateinit var textures: TextureRegistry
    private var applicationContext: android.content.Context? = null

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var sink: EventChannel.EventSink? = null
    private var session: PoseCameraSession? = null
    private var pendingPermission: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        textures = binding.textureRegistry

        control = MethodChannel(binding.binaryMessenger, CONTROL_CHANNEL)
        control.setMethodCallHandler(this)

        frames = EventChannel(binding.binaryMessenger, FRAMES_CHANNEL)
        frames.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        control.setMethodCallHandler(null)
        frames.setStreamHandler(null)
        session?.dispose()
        session = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
        // The camera cannot outlive the activity it was bound through.
        session?.stop()
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "permissionStatus" -> result.success(if (hasPermission()) "granted" else "denied")
            "requestPermission" -> requestPermission(result)
            "start" -> start(call.argument<String>("lens") ?: "back", result)
            "stop" -> {
                session?.stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun hasPermission(): Boolean {
        val context = applicationContext ?: return false
        return ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
    }

    /**
     * Asks for the camera.
     *
     * `permissionStatus` never reports `permanentlyDenied`, deliberately.
     * Telling the two apart needs `shouldShowRequestPermissionRationale`,
     * which is also false before the user has ever been asked — so reading
     * it on a fresh install would send somebody to the system settings to
     * grant a permission they were never offered. After an actual request,
     * the same signal is unambiguous.
     */
    private fun requestPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success("granted")
            return
        }

        val host = activity
        if (host == null) {
            result.error("permissionDenied", "no activity to ask through", null)
            return
        }
        if (pendingPermission != null) {
            result.error("permissionDenied", "a request is already in flight", null)
            return
        }

        pendingPermission = result
        ActivityCompat.requestPermissions(
            host,
            arrayOf(Manifest.permission.CAMERA),
            PERMISSION_REQUEST,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false

        val result = pendingPermission ?: return true
        pendingPermission = null

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        val host = activity

        result.success(
            when {
                granted -> "granted"
                host != null &&
                    !ActivityCompat.shouldShowRequestPermissionRationale(
                        host,
                        Manifest.permission.CAMERA,
                    ) -> "permanentlyDenied"
                else -> "denied"
            },
        )
        return true
    }

    private fun start(
        lens: String,
        result: MethodChannel.Result,
    ) {
        if (!hasPermission()) {
            result.error("permissionDenied", "camera permission not granted", null)
            return
        }
        val context = applicationContext
        if (context == null) {
            result.error("noCamera", "plugin is not attached", null)
            return
        }

        val running = session ?: PoseCameraSession(
            context = context,
            textures = textures,
            onFrame = ::emit,
            onError = ::fail,
        ).also { session = it }

        // Replies exactly once, whichever way it goes. A camera that fails
        // after the reply has gone out reports through the frame stream
        // instead, which is where a mid-set failure belongs.
        var replied = false
        running.start(
            lens = lens,
            onReady = { geometry ->
                if (!replied) {
                    replied = true
                    result.success(geometry)
                }
            },
            onFailed = { code, message ->
                if (!replied) {
                    replied = true
                    result.error(code, message, null)
                }
            },
        )
    }

    private fun emit(
        frameId: Long,
        tUs: Long,
        confidence: Float,
        buffer: FloatArray,
    ) {
        sink?.success(
            mapOf(
                // Both go as 64-bit: the standard codec maps a Kotlin Long
                // to a Dart int, so nothing needs truncating. Microseconds
                // in an Int would have run out after 35 minutes.
                "frameId" to frameId,
                "tUs" to tUs,
                "confidence" to confidence.toDouble(),
                "landmarks" to buffer,
            ),
        )
    }

    private fun fail(
        code: String,
        message: String,
    ) {
        sink?.error(code, message, null)
    }
}
