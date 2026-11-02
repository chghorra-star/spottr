import MLKitPoseDetection

/// ML Kit's landmark identity, turned into the BlazePose index the wire
/// format is built on.
///
/// This file exists because the two platforms disagree about what a landmark
/// *is*. On Android `PoseLandmark.landmarkType` is already the BlazePose
/// index, so packing is arithmetic. On iOS the type is a string-backed
/// constant, so somebody has to write the order down — and writing it down
/// is the single easiest way to remap every joint in the app without
/// anything looking wrong. A transposed frame still draws a plausible
/// figure; a swapped pair draws one that is exactly right until a form rule
/// reads it.
///
/// Two safeguards. The names below are resolved by the Swift compiler, so a
/// constant that does not exist in the installed ML Kit is a build failure
/// rather than a joint that silently never arrives — **and the first macOS
/// build of this project is what will say so**, because nothing on Windows
/// can. And [order] is checked by `LandmarkPackerTests` to be exactly
/// thirty-three distinct entries, which catches the likelier mistake of a
/// duplicated or missing line.
enum PoseLandmarkOrdinal {
  /// Every landmark, in BlazePose index order.
  ///
  /// The order is the wire contract. It matches `pose_core`'s `Joint` enum
  /// declaration order, which `pose_frame_test.dart` pins, and the Android
  /// side gets the same order from ML Kit for free.
  static let order: [PoseLandmarkType] = [
    .nose,
    .leftEyeInner,
    .leftEye,
    .leftEyeOuter,
    .rightEyeInner,
    .rightEye,
    .rightEyeOuter,
    .leftEar,
    .rightEar,
    .mouthLeft,
    .mouthRight,
    .leftShoulder,
    .rightShoulder,
    .leftElbow,
    .rightElbow,
    .leftWrist,
    .rightWrist,
    .leftPinkyFinger,
    .rightPinkyFinger,
    .leftIndexFinger,
    .rightIndexFinger,
    .leftThumb,
    .rightThumb,
    .leftHip,
    .rightHip,
    .leftKnee,
    .rightKnee,
    .leftAnkle,
    .rightAnkle,
    .leftHeel,
    .rightHeel,
    .leftToe,
    .rightToe,
  ]

  /// Built once. Called thirty-three times a frame at thirty frames a
  /// second, which is not the place for a linear search.
  private static let indices: [PoseLandmarkType: Int] = {
    var table: [PoseLandmarkType: Int] = [:]
    for (index, type) in order.enumerated() {
      table[type] = index
    }
    return table
  }()

  /// The BlazePose index, or `nil` for a landmark this build does not know.
  ///
  /// `nil` rather than a fallback index: a landmark packed into the wrong
  /// slot is worse than a landmark the Dart side never sees, because the
  /// second one reads as "the model could not place it", which is a
  /// sentence the whole engine already knows how to handle.
  static func index(of type: PoseLandmarkType) -> Int? {
    indices[type]
  }
}
