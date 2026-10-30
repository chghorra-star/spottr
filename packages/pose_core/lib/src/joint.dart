/// The 33 BlazePose body landmarks.
///
/// **The declaration order is a wire contract.** The native bridge and the
/// offline video extractor both send landmarks as a flat array indexed by
/// BlazePose position, so reordering these values would silently remap every
/// joint. `test/pose_frame_test.dart` pins the ordinals.
enum Joint {
  nose,
  leftEyeInner,
  leftEye,
  leftEyeOuter,
  rightEyeInner,
  rightEye,
  rightEyeOuter,
  leftEar,
  rightEar,
  mouthLeft,
  mouthRight,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftPinky,
  rightPinky,
  leftIndex,
  rightIndex,
  leftThumb,
  rightThumb,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex;

  /// The same joint on the other side of the body.
  ///
  /// Used by symmetry checks such as side-to-side load imbalance. The only
  /// joint without a lateral pair is [Joint.nose], which mirrors to itself.
  Joint get mirrored => switch (this) {
        Joint.nose => Joint.nose,
        Joint.leftEyeInner => Joint.rightEyeInner,
        Joint.leftEye => Joint.rightEye,
        Joint.leftEyeOuter => Joint.rightEyeOuter,
        Joint.rightEyeInner => Joint.leftEyeInner,
        Joint.rightEye => Joint.leftEye,
        Joint.rightEyeOuter => Joint.leftEyeOuter,
        Joint.leftEar => Joint.rightEar,
        Joint.rightEar => Joint.leftEar,
        Joint.mouthLeft => Joint.mouthRight,
        Joint.mouthRight => Joint.mouthLeft,
        Joint.leftShoulder => Joint.rightShoulder,
        Joint.rightShoulder => Joint.leftShoulder,
        Joint.leftElbow => Joint.rightElbow,
        Joint.rightElbow => Joint.leftElbow,
        Joint.leftWrist => Joint.rightWrist,
        Joint.rightWrist => Joint.leftWrist,
        Joint.leftPinky => Joint.rightPinky,
        Joint.rightPinky => Joint.leftPinky,
        Joint.leftIndex => Joint.rightIndex,
        Joint.rightIndex => Joint.leftIndex,
        Joint.leftThumb => Joint.rightThumb,
        Joint.rightThumb => Joint.leftThumb,
        Joint.leftHip => Joint.rightHip,
        Joint.rightHip => Joint.leftHip,
        Joint.leftKnee => Joint.rightKnee,
        Joint.rightKnee => Joint.leftKnee,
        Joint.leftAnkle => Joint.rightAnkle,
        Joint.rightAnkle => Joint.leftAnkle,
        Joint.leftHeel => Joint.rightHeel,
        Joint.rightHeel => Joint.leftHeel,
        Joint.leftFootIndex => Joint.rightFootIndex,
        Joint.rightFootIndex => Joint.leftFootIndex,
      };
}
