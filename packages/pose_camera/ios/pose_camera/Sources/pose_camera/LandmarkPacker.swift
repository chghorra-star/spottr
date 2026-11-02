import Foundation

/// One landmark as the model reported it, in pixels of the upright image.
///
/// A plain struct rather than ML Kit's `PoseLandmark` so that the packing —
/// the part where an off-by-one silently remaps every joint in the app —
/// can be tested without a device, a camera or the ML Kit runtime. The
/// Android side has the same struct for the same reason.
struct SourceLandmark: Equatable {
  let type: Int
  let x: Float
  let y: Float
  let z: Float
  let likelihood: Float

  init(type: Int, x: Float, y: Float, z: Float, likelihood: Float) {
    self.type = type
    self.x = x
    self.y = y
    self.z = z
    self.likelihood = likelihood
  }
}

/// Packs landmarks into the flat buffer the Dart side decodes.
///
/// The format is `pose_core`'s `PoseFrameCodec`: 33 joints in BlazePose
/// index order, four floats each — x, y, z, visibility — with x and y
/// normalized to 0..1 and NaN standing in for a joint the model did not
/// place. Byte for byte the same thing Android sends, which is the whole
/// point: a form rule must not be able to tell which phone it is running
/// on.
///
/// Nothing here mirrors anything. The front lens is *displayed* mirrored,
/// but that is a presentation decision made once, in Flutter, where the
/// preview and the overlay are flipped together and therefore cannot drift
/// apart. Landmarks that cross the bridge are always in the camera's own
/// left-to-right space.
enum LandmarkPacker {
  /// Floats per landmark: x, y, z, visibility. `STRIDE` on the Kotlin side.
  static let valuesPerJoint = 4

  /// The BlazePose landmark count.
  static let jointCount = 33

  static let length = jointCount * valuesPerJoint

  /// - Parameters:
  ///   - width: width of the upright image the landmarks were measured in
  ///   - height: height of the upright image
  static func pack(_ landmarks: [SourceLandmark], width: Int, height: Int) -> [Float] {
    precondition(width > 0 && height > 0, "image size must be positive, got \(width)x\(height)")

    var buffer = [Float](repeating: 0, count: length)
    // Absent by default. Every joint has a slot whether the model filled it
    // or not, and (0, 0) is the top left corner of the image, which a form
    // rule cannot tell apart from a real measurement.
    for joint in 0..<jointCount {
      buffer[joint * valuesPerJoint] = Float.nan
      buffer[joint * valuesPerJoint + 1] = Float.nan
    }

    for landmark in landmarks {
      guard landmark.type >= 0, landmark.type < jointCount else { continue }
      let base = landmark.type * valuesPerJoint
      buffer[base] = landmark.x / Float(width)
      buffer[base + 1] = landmark.y / Float(height)
      // z arrives in roughly the same scale as x; normalizing by width keeps
      // the three axes comparable, which is all a loosely calibrated depth
      // is good for.
      buffer[base + 2] = landmark.z / Float(width)
      buffer[base + 3] = landmark.likelihood
    }

    return buffer
  }

  /// Mean in-frame likelihood, which is what stands in for a pose-level
  /// confidence.
  ///
  /// ML Kit does not report one. The mean is honest about what it is: a
  /// frame where half the body is guessed at scores low, and a frame with
  /// no pose at all scores zero, which is exactly what the framing check
  /// needs in order to say "I cannot see anybody".
  ///
  /// Divided by the joint count rather than by how many were found, so that
  /// it matches Android exactly — and so that a frame with three confident
  /// joints does not score the same as a frame with a whole confident body.
  static func confidence(_ landmarks: [SourceLandmark]) -> Float {
    if landmarks.isEmpty { return 0 }
    var total: Float = 0
    for landmark in landmarks { total += landmark.likelihood }
    return total / Float(jointCount)
  }

  /// The image size after a rotation is applied.
  ///
  /// Kept for parity with Android, where ML Kit does the rotating and the
  /// sensor's own width and height would transpose the whole skeleton on a
  /// portrait phone. On iOS the capture connection is rotated instead, so
  /// buffers arrive upright and this is the identity — but the arithmetic
  /// is here, and tested, because the two platforms must agree about what
  /// "upright" means.
  static func uprightSize(width: Int, height: Int, rotationDegrees: Int) -> (Int, Int) {
    if rotationDegrees == 90 || rotationDegrees == 270 {
      return (height, width)
    }
    return (width, height)
  }
}
