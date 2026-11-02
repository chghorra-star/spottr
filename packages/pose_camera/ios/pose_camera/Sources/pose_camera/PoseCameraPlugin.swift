import AVFoundation
import Flutter
import UIKit

/// The native half of the pose camera, on iOS.
///
/// Two channels, the same two Android uses and with the same names: control
/// calls — permission, start, stop — are request and reply and go over a
/// `FlutterMethodChannel`, and landmark frames are a one-way firehose at
/// camera rate and go over a `FlutterEventChannel`.
///
/// No pixel buffer is ever sent across the bridge. The preview goes from
/// AVFoundation into a Flutter texture and the analysis frames are handed
/// to the model and released; what reaches Dart is thirty-three joints.
public class PoseCameraPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let controlChannel = "spottr/pose_camera"
  private static let framesChannel = "spottr/pose_camera/frames"

  private let textures: FlutterTextureRegistry
  private var sink: FlutterEventSink?
  private var session: PoseCameraSession?

  init(textures: FlutterTextureRegistry) {
    self.textures = textures
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PoseCameraPlugin(textures: registrar.textures())

    let control = FlutterMethodChannel(
      name: controlChannel,
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: control)

    let frames = FlutterEventChannel(
      name: framesChannel,
      binaryMessenger: registrar.messenger())
    frames.setStreamHandler(instance)

    // Without this the plugin is only held by the channels, and a camera
    // that stops when the engine garbage-collects its delegate is a bug
    // that only shows up on a slow phone.
    registrar.publish(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    session?.dispose()
    session = nil
    sink = nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "permissionStatus":
      result(Self.permission(AVCaptureDevice.authorizationStatus(for: .video)))
    case "requestPermission":
      requestPermission(result)
    case "start":
      let lens = (call.arguments as? [String: Any])?["lens"] as? String ?? "back"
      start(lens: lens, result: result)
    case "stop":
      session?.stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  /// iOS can tell a refusal from a question that has never been asked,
  /// which Android cannot do before the first prompt.
  ///
  /// So, unlike the Android side, `permissionStatus` here reports
  /// `permanentlyDenied` accurately and without having to ask anybody
  /// anything — and `denied` means only "not asked yet", which is exactly
  /// the state the screen offers a button for.
  private static func permission(_ status: AVAuthorizationStatus) -> String {
    switch status {
    case .authorized:
      return "granted"
    case .notDetermined:
      return "denied"
    case .denied, .restricted:
      // Restricted is a device policy rather than a choice, and it has the
      // same consequence: nothing this app does will change it.
      return "permanentlyDenied"
    @unknown default:
      // Not defaulted to "denied": an unrecognised status means this build
      // and the OS disagree, and failing closed would read as a permission
      // problem for ever instead of as the version skew it is.
      return "unknown"
    }
  }

  private func requestPermission(_ result: @escaping FlutterResult) {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    guard status == .notDetermined else {
      result(Self.permission(status))
      return
    }

    AVCaptureDevice.requestAccess(for: .video) { granted in
      DispatchQueue.main.async {
        // Refused once is refused for good on iOS: the system will not show
        // the prompt again, so a button offering to ask would do nothing.
        result(granted ? "granted" : "permanentlyDenied")
      }
    }
  }

  private func start(lens: String, result: @escaping FlutterResult) {
    guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
      result(
        FlutterError(
          code: "permissionDenied",
          message: "camera permission not granted",
          details: nil))
      return
    }

    let running =
      session
      ?? {
        let created = PoseCameraSession(
          textures: textures,
          onFrame: { [weak self] frameId, micros, confidence, buffer in
            self?.emit(
              frameId: frameId, micros: micros, confidence: confidence, buffer: buffer)
          },
          onError: { [weak self] code, message in
            self?.fail(code: code, message: message)
          })
        session = created
        return created
      }()

    // Replies exactly once, whichever way it goes. A camera that fails
    // after the reply has gone out reports through the frame stream
    // instead, which is where a mid-set failure belongs.
    var replied = false
    running.start(
      lens: lens,
      onReady: { geometry in
        guard !replied else { return }
        replied = true
        result(geometry)
      },
      onFailed: { code, message in
        guard !replied else { return }
        replied = true
        result(FlutterError(code: code, message: message, details: nil))
      })
  }

  private func emit(frameId: Int64, micros: Int64, confidence: Float, buffer: [Float]) {
    guard let sink else { return }
    sink([
      // Both go as 64-bit, like Android: microseconds in a 32-bit int would
      // have run out after thirty-five minutes.
      "frameId": frameId,
      "tUs": micros,
      "confidence": Double(confidence),
      // Typed data, not an array of numbers. The Dart codec has a fast path
      // for a Float32List and a slow one for a list of boxed doubles, and
      // this is thirty frames a second.
      "landmarks": FlutterStandardTypedData(
        float32: buffer.withUnsafeBufferPointer { Data(buffer: $0) }),
    ])
  }

  private func fail(code: String, message: String) {
    sink?(FlutterError(code: code, message: message, details: nil))
  }
}
