/// Pose domain primitives shared by the camera layer, the coach engine, and
/// the accuracy harness.
///
/// Pure Dart on purpose: nothing here imports Flutter, so the entire form
/// analysis stack is testable from recorded fixtures without a device.
library;

export 'src/camera_angle.dart';
export 'src/geometry.dart';
export 'src/joint.dart';
export 'src/landmark.dart';
export 'src/point2.dart';
export 'src/pose_frame.dart';
