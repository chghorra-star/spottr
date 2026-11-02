import AVFoundation
import CoreMedia
import CoreVideo
import Flutter
import MLKitPoseDetection
import MLKitVision
import QuartzCore
import os

/// One run of the camera: capture, inference, and landmarks out.
///
/// The iOS half of `PoseCameraSession.kt`, deliberately shaped so the two
/// can be read side by side. Owns an `AVCaptureSession` and an ML Kit
/// detector, and emits a flat landmark buffer per frame through `onFrame`.
///
/// Pixels never cross the bridge. They do pass through this class, because
/// the preview has to come from somewhere: the same sample buffer is handed
/// to the model and to a Flutter texture, and nothing is copied. What goes
/// to Dart is thirty-three joints.
final class PoseCameraSession: NSObject {
  /// Capture preset. 640x480 is the same analysis target the Android side
  /// asks for: BlazePose downscales its input anyway, and every pixel above
  /// that is heat and latency for no accuracy.
  private static let preset: AVCaptureSession.Preset = .vga640x480

  private static let log = Logger(
    subsystem: "com.spottr.pose_camera",
    category: "PoseCameraSession")

  private let textures: FlutterTextureRegistry
  private let onFrame: (Int64, Int64, Float, [Float]) -> Void
  private let onError: (String, String) -> Void

  /// Capture callbacks arrive here, and inference is kicked off from here.
  /// One queue, so there is one answer to what the camera is doing.
  private let queue = DispatchQueue(label: "com.spottr.pose_camera.capture")

  private var session: AVCaptureSession?
  private var detector: PoseDetector?
  private var texture: PreviewTexture?
  private var textureId: Int64?

  private var frameId: Int64 = 0
  private var firstFrameMicros: Int64?

  /// Whether the model is still working on the previous frame.
  ///
  /// `alwaysDiscardsLateVideoFrames` only drops frames while the delegate
  /// itself is blocked, and `process` returns immediately — so without this
  /// every captured frame would queue up behind the model and the coach
  /// would end up commenting on a rep that finished a second ago, which is
  /// worse than not commenting on it.
  private var busy = false

  private var reportedFrames = 0
  private var reportedConfidence: Float = 0
  private var reportedSince: CFTimeInterval = 0

  init(
    textures: FlutterTextureRegistry,
    onFrame: @escaping (Int64, Int64, Float, [Float]) -> Void,
    onError: @escaping (String, String) -> Void
  ) {
    self.textures = textures
    self.onFrame = onFrame
    self.onError = onError
    super.init()
  }

  /// Opens `lens` and starts delivering frames.
  ///
  /// Replies through `onReady` with the geometry Dart needs to lay the
  /// preview out, or through `onFailed` with one of the error codes
  /// `DevicePoseCamera` knows how to translate.
  func start(
    lens: String,
    onReady: @escaping ([String: Any?]) -> Void,
    onFailed: @escaping (String, String) -> Void
  ) {
    stop()

    let front = lens == "front"
    guard
      let device = AVCaptureDevice.default(
        .builtInWideAngleCamera,
        for: .video,
        position: front ? .front : .back)
    else {
      onFailed("noCamera", "no \(lens) camera on this device")
      return
    }

    let capture = AVCaptureSession()
    capture.beginConfiguration()
    capture.sessionPreset = Self.preset

    do {
      let input = try AVCaptureDeviceInput(device: device)
      guard capture.canAddInput(input) else {
        capture.commitConfiguration()
        onFailed("cameraInUse", "the camera could not be added to the session")
        return
      }
      capture.addInput(input)
    } catch {
      capture.commitConfiguration()
      onFailed("cameraInUse", error.localizedDescription)
      return
    }

    let output = AVCaptureVideoDataOutput()
    // BGRA because that is what a Flutter texture takes, and the model is
    // happy with it too — so one buffer serves both and nothing is copied.
    output.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    output.alwaysDiscardsLateVideoFrames = true
    output.setSampleBufferDelegate(self, queue: queue)
    guard capture.canAddOutput(output) else {
      capture.commitConfiguration()
      onFailed("cameraInUse", "the camera output could not be added")
      return
    }
    capture.addOutput(output)

    if let connection = output.connection(with: .video) {
      // Rotate at capture rather than at inference, so the buffers arrive
      // upright and the landmark coordinates are already in the space the
      // packer normalizes by. Android lets ML Kit do the rotating and has
      // to carry the arithmetic; doing it here means there is one less
      // place for a transposed skeleton to come from.
      if #available(iOS 17.0, *) {
        if connection.isVideoRotationAngleSupported(90) {
          connection.videoRotationAngle = 90
        }
      } else if connection.isVideoOrientationSupported {
        connection.videoOrientation = .portrait
      }

      // Explicitly not mirrored, and explicitly not left to AVFoundation to
      // decide. The front preview is shown mirrored, the way a gym mirror
      // is, and Flutter does that — to the preview and the overlay
      // together, so they cannot drift apart. Mirroring here as well would
      // cancel the flip on screen and leave the landmark x axis reversed
      // relative to Android, which no form rule should have to know about.
      if connection.isVideoMirroringSupported {
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = false
      }
    }

    capture.commitConfiguration()

    let options = PoseDetectorOptions()
    options.detectorMode = .stream
    detector = PoseDetector.poseDetector(options: options)

    let preview = PreviewTexture()
    texture = preview
    let id = textures.register(preview)
    textureId = id

    frameId = 0
    firstFrameMicros = nil
    busy = false
    session = capture

    // Starting blocks until the camera is open, which on a cold start is
    // long enough to drop a frame of the UI if it happened on the main
    // thread.
    queue.async { capture.startRunning() }

    let size = Self.uprightDimensions(for: device) ?? (480, 640)
    onReady([
      "imageWidth": size.0,
      "imageHeight": size.1,
      "lens": front ? "front" : "back",
      "mirrored": front,
      "textureId": id,
    ])
  }

  /// Closes the camera. Safe to call when nothing is running.
  func stop() {
    if let capture = session {
      capture.stopRunning()
      for input in capture.inputs { capture.removeInput(input) }
      for output in capture.outputs { capture.removeOutput(output) }
    }
    session = nil

    detector = nil
    busy = false

    if let id = textureId {
      textures.unregisterTexture(id)
    }
    textureId = nil
    texture = nil
  }

  func dispose() {
    stop()
  }

  /// The upright frame size for the preset, which on a portrait-locked
  /// screen is whichever way round is taller.
  ///
  /// The coach screen locks portrait, because a phone propped against a
  /// water bottle should not reorient the skeleton when it tips — so, like
  /// Android, there is no rotation arithmetic to do here beyond putting the
  /// smaller number first.
  private static func uprightDimensions(for device: AVCaptureDevice) -> (Int, Int)? {
    let dimensions = CMVideoFormatDescriptionGetDimensions(
      device.activeFormat.formatDescription)
    let width = Int(dimensions.width)
    let height = Int(dimensions.height)
    guard width > 0, height > 0 else { return nil }
    return (min(width, height), max(width, height))
  }

  /// Once a second, how many frames got through and how sure the model was.
  ///
  /// The only window onto the pipeline from outside Dart, and the thing
  /// that distinguishes "an empty room" from "no frames at all" — which
  /// look identical on screen. A count and a mean, never a landmark: a pose
  /// trace in the system log would be a copy of somebody's body leaving the
  /// app, which is the one thing this design promises not to do.
  private func report(_ confidence: Float) {
    #if DEBUG
      reportedFrames += 1
      reportedConfidence += confidence
      let now = CACurrentMediaTime()
      if reportedSince == 0 { reportedSince = now }
      guard now - reportedSince >= 1 else { return }

      Self.log.debug(
        "\(self.reportedFrames) fps, mean confidence \(self.reportedConfidence / Float(self.reportedFrames))"
      )
      reportedFrames = 0
      reportedConfidence = 0
      reportedSince = now
    #endif
  }
}

extension PoseCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    // The preview gets every frame, whether or not the model is keeping up.
    // A preview that stuttered with inference would look like a broken
    // camera rather than a busy one.
    texture?.update(pixels)
    if let id = textureId {
      textures.textureFrameAvailable(id)
    }

    guard let detector, !busy else { return }
    busy = true

    let width = CVPixelBufferGetWidth(pixels)
    let height = CVPixelBufferGetHeight(pixels)
    let presentation = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    let micros = Int64(CMTimeGetSeconds(presentation) * 1_000_000)
    if firstFrameMicros == nil { firstFrameMicros = micros }
    let elapsed = micros - (firstFrameMicros ?? micros)

    let image = VisionImage(buffer: sampleBuffer)
    // The buffer was rotated at capture, so there is nothing left to say
    // about its orientation.
    image.orientation = .up

    detector.process(image) { [weak self] pose, error in
      guard let self else { return }
      self.busy = false

      if let error {
        Self.log.warning("pose detection failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
          self.onError("modelFailed", error.localizedDescription)
        }
        return
      }

      let landmarks: [SourceLandmark] = (pose?.landmarks ?? []).compactMap { landmark in
        guard let index = PoseLandmarkOrdinal.index(of: landmark.type) else { return nil }
        return SourceLandmark(
          type: index,
          x: Float(landmark.position.x),
          y: Float(landmark.position.y),
          z: Float(landmark.position.z),
          likelihood: landmark.inFrameLikelihood)
      }

      // A frame with nobody in it is still a frame. The framing check needs
      // it in order to say "I cannot see you", and going silent would be
      // indistinguishable from the camera having died.
      let buffer = LandmarkPacker.pack(landmarks, width: width, height: height)
      let confidence = LandmarkPacker.confidence(landmarks)
      self.report(confidence)

      let id = self.frameId
      self.frameId += 1

      DispatchQueue.main.async {
        self.onFrame(id, elapsed, confidence, buffer)
      }
    }
  }
}

/// The newest camera frame, handed to Flutter when Flutter asks for it.
///
/// Android pushes into a `SurfaceProducer`; iOS pulls through
/// `FlutterTexture`, so this keeps exactly one frame and hands it over on
/// demand. One, not a queue: a preview is only ever about now.
final class PreviewTexture: NSObject, FlutterTexture {
  private let lock = NSLock()
  private var latest: CVPixelBuffer?

  func update(_ buffer: CVPixelBuffer) {
    lock.lock()
    latest = buffer
    lock.unlock()
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    lock.lock()
    defer { lock.unlock() }
    guard let latest else { return nil }
    return Unmanaged.passRetained(latest)
  }

  func onTextureUnregistered(_ texture: FlutterTexture) {
    lock.lock()
    latest = nil
    lock.unlock()
  }
}
