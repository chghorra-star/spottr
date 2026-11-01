/// Camera capture and on-device pose inference.
///
/// Native code owns the camera and the model; only landmark frames cross
/// the bridge. See `PoseSource` for the seam that makes everything above
/// this package testable without a device.
library;

export 'src/device_pose_camera.dart';
export 'src/pose_camera_preview.dart';
export 'src/pose_source.dart';
