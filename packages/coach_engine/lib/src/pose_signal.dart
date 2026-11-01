import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

/// One scalar read off a pose, in degrees.
///
/// A rep counter watches exactly one of these and a hold watches a few. Both
/// are configuration rather than code: adding a ninth camera exercise is a
/// new signal and a new set of thresholds, not a new state machine.
///
/// Every signal is measured on **both sides of the body** and averaged over
/// whichever sides are tracked. From the side view — the recommended angle
/// for every launch exercise — the far limb is behind the near one, and
/// which of the two the model reports is not something a config can predict.
/// Averaging is right for the launch set because every camera-supported
/// movement is bilaterally synchronous; a genuinely one-sided movement would
/// have to name its side, and that is a problem for the exercise that needs
/// it.
@immutable
sealed class PoseSignal {
  const PoseSignal();

  /// The value in degrees, or `null` when neither side is confidently
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
