import 'package:meta/meta.dart';

import 'geometry.dart';
import 'joint.dart';
import 'landmark.dart';
import 'point2.dart';

/// Minimum landmark confidence treated as "tracked" unless a caller says
/// otherwise. Form rules that need certainty pass a higher value.
const double defaultMinVisibility = 0.5;

/// One frame of pose output.
///
/// This is the only thing the native camera layer sends across the bridge —
/// never pixels. Every rep counter and form rule in [coach_engine] consumes
/// a stream of these, which is what lets the whole engine run from recorded
/// fixtures with no device attached.
@immutable
class PoseFrame {
  PoseFrame({
    required this.frameId,
    required this.t,
    required Map<Joint, Landmark> landmarks,
    required this.confidence,
  }) : landmarks = Map.unmodifiable(landmarks);

  /// Monotonic counter from the start of the set; gaps mean dropped frames.
  final int frameId;

  /// Elapsed time since the set started.
  final Duration t;

  /// Landmarks the model reported. Joints it could not place are absent
  /// rather than present with a zero position.
  final Map<Joint, Landmark> landmarks;

  /// Model confidence for the pose as a whole.
  final double confidence;

  /// Position of [joint], or `null` if it was not reported or its confidence
  /// is below [minVisibility].
  Point2? point(Joint joint, {double minVisibility = defaultMinVisibility}) {
    final landmark = landmarks[joint];
    if (landmark == null || landmark.visibility < minVisibility) return null;
    return landmark.point;
  }

  /// The angle at [vertex] between [from] and [to], or `null` if any of the
  /// three joints is not confidently tracked.
  double? angleAt(
    Joint from,
    Joint vertex,
    Joint to, {
    double minVisibility = defaultMinVisibility,
  }) {
    final a = point(from, minVisibility: minVisibility);
    final b = point(vertex, minVisibility: minVisibility);
    final c = point(to, minVisibility: minVisibility);
    if (a == null || b == null || c == null) return null;
    return angleAtVertex(a, b, c);
  }

  /// Whether every joint in [joints] is confidently tracked.
  bool hasAll(
    Set<Joint> joints, {
    double minVisibility = defaultMinVisibility,
  }) =>
      joints.every(
        (joint) => point(joint, minVisibility: minVisibility) != null,
      );

  @override
  String toString() => 'PoseFrame(#$frameId, ${t.inMilliseconds}ms, '
      '${landmarks.length} joints, conf=${confidence.toStringAsFixed(2)})';
}
