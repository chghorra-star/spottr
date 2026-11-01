import 'joint.dart';
import 'point2.dart';
import 'pose_frame.dart';

/// Which joints are drawn connected to which.
///
/// Domain data rather than a constant inside the overlay widget: the
/// offline labelling tool and the decision-log viewer draw the same figure,
/// and three copies of this list would diverge.
///
/// **No face.** The overlay is there to show what the coach is measuring,
/// and no form rule reads a face landmark. A face mesh over somebody's
/// squat is decoration that makes the useful part harder to read.
abstract final class Skeleton {
  /// The trunk, the arms, the legs and the feet.
  static const List<(Joint, Joint)> bones = [
    // Trunk
    (Joint.leftShoulder, Joint.rightShoulder),
    (Joint.leftHip, Joint.rightHip),
    (Joint.leftShoulder, Joint.leftHip),
    (Joint.rightShoulder, Joint.rightHip),

    // Arms
    (Joint.leftShoulder, Joint.leftElbow),
    (Joint.leftElbow, Joint.leftWrist),
    (Joint.rightShoulder, Joint.rightElbow),
    (Joint.rightElbow, Joint.rightWrist),

    // Legs
    (Joint.leftHip, Joint.leftKnee),
    (Joint.leftKnee, Joint.leftAnkle),
    (Joint.rightHip, Joint.rightKnee),
    (Joint.rightKnee, Joint.rightAnkle),

    // Feet, which is how a side view shows whether the heels stayed down
    (Joint.leftAnkle, Joint.leftHeel),
    (Joint.leftHeel, Joint.leftFootIndex),
    (Joint.leftAnkle, Joint.leftFootIndex),
    (Joint.rightAnkle, Joint.rightHeel),
    (Joint.rightHeel, Joint.rightFootIndex),
    (Joint.rightAnkle, Joint.rightFootIndex),
  ];

  /// Every joint the skeleton draws.
  ///
  /// Derived from [bones] rather than listed again, so the two cannot
  /// disagree about whether a heel is part of the figure.
  static final Set<Joint> joints = {
    for (final (from, to) in bones) ...[from, to],
  };

  /// The bones of [frame] with both ends confidently tracked, as positions.
  ///
  /// A bone with one end missing is left out rather than drawn to the last
  /// place that joint was seen: a limb sitting where the tracker lost it
  /// looks exactly like a measurement.
  static List<(Point2, Point2)> visibleBones(
    PoseFrame frame, {
    double minVisibility = defaultMinVisibility,
  }) {
    final visible = <(Point2, Point2)>[];
    for (final (from, to) in bones) {
      final a = frame.point(from, minVisibility: minVisibility);
      final b = frame.point(to, minVisibility: minVisibility);
      if (a == null || b == null) continue;
      visible.add((a, b));
    }
    return visible;
  }
}
