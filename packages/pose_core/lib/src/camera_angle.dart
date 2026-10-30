/// Where the phone is placed relative to the user for a set.
///
/// Each camera-supported exercise declares a recommended angle and the angles
/// it will tolerate. A tolerated-but-not-recommended angle still counts reps;
/// it just disables the form rules it cannot see.
enum CameraAngle {
  /// Phone beside the user, perpendicular to the direction they face.
  /// Needed for anything about depth, hip hinge, or spinal position.
  side,

  /// Phone in front of the user. Needed for anything about left-right
  /// symmetry, such as knees caving inward.
  front,
}
