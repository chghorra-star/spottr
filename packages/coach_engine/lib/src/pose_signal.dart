import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

/// One scalar read off a pose.
///
/// Most are angles in degrees. A few are dimensionless ratios expressed as
/// percentages, because a threshold written in normalized image units gets
/// stricter as the user steps away from the camera. Each variant says
/// which it is, and [unit] carries it as far as the report.
///
/// A rep counter watches exactly one of these and a hold watches a few. Both
/// are configuration rather than code: adding a ninth camera exercise is a
/// new signal and a new set of thresholds, not a new state machine.
///
/// Every signal is measured on **both sides of the body** and averaged over
/// whichever sides are tracked. From the side view — the recommended angle
/// for every launch exercise — the far limb is behind the near one, and
/// which of the two the model reports is not something a config can predict.
/// Averaging is right for seven of the eight camera-supported movements,
/// which are bilaterally synchronous. It is wrong for the lunge, where one
/// shin leans forwards and the other leans back and the mean of the two is a
/// number about nobody — which is why `knee_travel` is the one form rule
/// that is pending for a reason other than the camera angle. A genuinely
/// one-sided movement has to name its side, and nothing here can.
@immutable
sealed class PoseSignal {
  const PoseSignal();

  /// The value in [unit], or `null` when neither side is confidently
  /// tracked.
  ///
  /// `null` means "no reading", never zero: a counter has to be able to tell
  /// a joint it cannot see from a joint that is folded shut.
  double? measure(
    PoseFrame frame, {
    double minVisibility = defaultMinVisibility,
  });

  /// Every joint the signal reads, on both sides.
  Set<Joint> get joints;

  /// What the number means: 'deg' for an angle, '%' for a ratio.
  ///
  /// Only ever used for display. A rule that read this to decide how to
  /// compare two values would be a rule whose threshold means two different
  /// things.
  String get unit;
}

/// The angle at [vertex], between [from] and [to].
///
/// A squat's knee, a push-up's elbow, a hinge's hip. 180 is a straight
/// joint and 0 is a folded one.
final class JointAngle extends PoseSignal {
  const JointAngle({
    required this.from,
    required this.vertex,
    required this.to,
  });

  final Joint from;
  final Joint vertex;
  final Joint to;

  @override
  double? measure(
    PoseFrame frame, {
    double minVisibility = defaultMinVisibility,
  }) =>
      _average([
        frame.angleAt(from, vertex, to, minVisibility: minVisibility),
        frame.angleAt(
          from.mirrored,
          vertex.mirrored,
          to.mirrored,
          minVisibility: minVisibility,
        ),
      ]);

  @override
  Set<Joint> get joints => {
        from,
        vertex,
        to,
        from.mirrored,
        vertex.mirrored,
        to.mirrored,
      };

  @override
  String get unit => 'deg';
}

/// The angle of the segment [from] -> [to] measured from straight up.
///
/// 180 is a body the right way up, 90 is one lying down. This is what tells
/// a plank from a standing rest: the hip angle of the two is the same, and
/// the trunk angle is not.
final class SegmentTilt extends PoseSignal {
  const SegmentTilt({required this.from, required this.to});

  final Joint from;
  final Joint to;

  @override
  double? measure(
    PoseFrame frame, {
    double minVisibility = defaultMinVisibility,
  }) {
    double? tilt(Joint a, Joint b) {
      final start = frame.point(a, minVisibility: minVisibility);
      final end = frame.point(b, minVisibility: minVisibility);
      if (start == null || end == null) return null;
      return angleFromVertical(start, end);
    }

    return _average([tilt(from, to), tilt(from.mirrored, to.mirrored)]);
  }

  @override
  Set<Joint> get joints => {from, to, from.mirrored, to.mirrored};

  @override
  String get unit => 'deg';
}

double? _average(List<double?> values) {
  var sum = 0.0;
  var count = 0;
  for (final value in values) {
    if (value == null) continue;
    sum += value;
    count++;
  }
  return count == 0 ? null : sum / count;
}

/// Two joints and the line between them.
///
/// Only [SegmentRatio] takes these; the older signals name their joints
/// one by one. A ratio needs four joints in two pairs, and four loose
/// named parameters in a configuration table is three too many to read.
@immutable
class Segment {
  const Segment(this.from, this.to);

  final Joint from;
  final Joint to;

  Segment get mirrored => Segment(from.mirrored, to.mirrored);

  Set<Joint> get joints => {from, to};

  /// Length in normalized image units, or `null` if either end is not
  /// confidently tracked.
  double? lengthIn(
    PoseFrame frame, {
    double minVisibility = defaultMinVisibility,
  }) {
    final a = frame.point(from, minVisibility: minVisibility);
    final b = frame.point(to, minVisibility: minVisibility);
    if (a == null || b == null) return null;
    return distance(a, b);
  }

  @override
  bool operator ==(Object other) =>
      other is Segment && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'Segment(${from.name} -> ${to.name})';
}

/// How far [joint] sits off the line from [from] to [to], as a percentage of
/// that line's length.
///
/// Positive is below the line on screen and negative is above it, referenced
/// to gravity rather than to which way the body faces. This is the one
/// signal that can tell a **sagging** hip from a **piked** one: the angle at
/// the hip is identical for the two — 180 minus the same number either way —
/// and the side of the shoulder-to-knee line the hip has fallen to is not.
///
/// `null` when the reference line is near vertical, which is what
/// [perpendicularOffset] does with a line that has no meaningful "below".
/// For a standing exercise that means this signal reads nothing, and a rule
/// built on it is one the coach cannot evaluate — which it has to say, not
/// treat as a pass.
final class JointOffset extends PoseSignal {
  const JointOffset({
    required this.joint,
    required this.from,
    required this.to,
  });

  /// The joint being judged.
  final Joint joint;

  /// The two ends of the line it is judged against.
  final Joint from;
  final Joint to;

  @override
  double? measure(
    PoseFrame frame, {
    double minVisibility = defaultMinVisibility,
  }) {
    double? offset(Joint p, Joint a, Joint b) {
      final point = frame.point(p, minVisibility: minVisibility);
      final start = frame.point(a, minVisibility: minVisibility);
      final end = frame.point(b, minVisibility: minVisibility);
      if (point == null || start == null || end == null) return null;
      final fraction = perpendicularOffset(point, start, end);
      return fraction == null ? null : fraction * 100;
    }

    return _average([
      offset(joint, from, to),
      offset(joint.mirrored, from.mirrored, to.mirrored),
    ]);
  }

  @override
  Set<Joint> get joints => {
        joint,
        from,
        to,
        joint.mirrored,
        from.mirrored,
        to.mirrored,
      };

  @override
  String get unit => '%';
}

/// The length of [segment] as a percentage of the length of [against].
///
/// Dimensionless on purpose. The only use for it at launch is a proxy for
/// spinal flexion: the 33 landmarks include no point on the spine, so the
/// shoulder-to-hip line is straight by construction and a rounded back is
/// not directly visible. What is visible is that the line **gets shorter**,
/// because flexion brings the shoulders towards the hips and foreshortening
/// does the rest. Measured against a bone that does not change length — the
/// thigh — that shortening is a number.
///
/// It is a proxy and it has a known false positive: rotating towards the
/// camera shortens the trunk too, without anybody's back rounding. That is
/// why the rule built on it has a tolerance rather than a hard bound, and
/// why `docs/dev-loop.md` lists it among the things only footage can settle.
final class SegmentRatio extends PoseSignal {
  const SegmentRatio({required this.segment, required this.against});

  final Segment segment;

  /// The reference length. Something that does not change with the
  /// movement being judged, or the ratio measures two things at once.
  final Segment against;

  @override
  double? measure(
    PoseFrame frame, {
    double minVisibility = defaultMinVisibility,
  }) {
    double? ratio(Segment top, Segment bottom) {
      final a = top.lengthIn(frame, minVisibility: minVisibility);
      final b = bottom.lengthIn(frame, minVisibility: minVisibility);
      if (a == null || b == null || b < 1e-6) return null;
      return a / b * 100;
    }

    return _average([
      ratio(segment, against),
      ratio(segment.mirrored, against.mirrored),
    ]);
  }

  @override
  Set<Joint> get joints => {
        ...segment.joints,
        ...against.joints,
        ...segment.mirrored.joints,
        ...against.mirrored.joints,
      };

  @override
  String get unit => '%';
}
