import Flutter
import UIKit

/// The iOS pose camera — not implemented yet.
///
/// iOS parity is M9, and deliberately so: this project is developed on
/// Windows, where iOS cannot be built at all, so writing AVFoundation and
/// ML Kit code here now would mean shipping native code that has never been
/// compiled, let alone run. See `docs/dev-loop.md`.
///
/// What it does do is fail the way the Dart side expects. Every control
/// call answers with a code `DevicePoseCamera` knows how to translate, so
/// an iOS build reports "this device cannot coach yet" through the normal
/// error path rather than hanging on a channel nobody answers.
public class PoseCameraPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PoseCameraPlugin()

    let control = FlutterMethodChannel(
      name: "spottr/pose_camera",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: control)

    let frames = FlutterEventChannel(
      name: "spottr/pose_camera/frames",
      binaryMessenger: registrar.messenger())
    frames.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "permissionStatus", "requestPermission":
      // Not "denied": nothing was refused. The camera is simply not here
      // yet, and the screen above says so rather than offering a permission
      // prompt that would never arrive.
      result(
        FlutterError(
          code: "noCamera",
          message: "the pose camera is not implemented on iOS yet (M9)",
          details: nil))
    case "start":
      result(
        FlutterError(
          code: "noCamera",
          message: "the pose camera is not implemented on iOS yet (M9)",
          details: nil))
    case "stop":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    return FlutterError(
      code: "noCamera",
      message: "the pose camera is not implemented on iOS yet (M9)",
      details: nil)
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
