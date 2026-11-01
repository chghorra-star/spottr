import 'package:meta/meta.dart';
import 'point2.dart';

import 'joint.dart';
import 'pose_frame.dart';

/// What is wrong with how the user is standing in the frame.
enum FramingIssue {
  /// Nobody the model is confident about.
  noPerson,

  /// The body runs past the edge of the image, or fills it top to bottom.
  tooClose,

  /// A joint the exercise needs is not being tracked.
  jointsOutOfView,

  /// Everything is visible, but small enough that the landmarks will be
  /// noisy.
  tooFar,

  /// The body has drifted towards one side, which is how a set ends up
  /// half out of frame.
  offCentre,
}

/// How much a [FramingIssue] matters.
enum FramingSeverity {
  /// Nothing to say.
  good,

  /// Worth telling the user, but the coach can still work.
  adjust,

  /// The coach cannot do its job until this is fixed.
  blocked,
}

/// The tracked extent of the body in normalized image space.
@immutable
class BodyBox {
  const BodyBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centreX => (left + right) / 2;
  double get centreY => (top + bottom) / 2;

  @override
  String toString() => 'BodyBox(${left.toStringAsFixed(2)}, '
      '${top.toStringAsFixed(2)}, ${right.toStringAsFixed(2)}, '
      '${bottom.toStringAsFixed(2)})';
}

/// Whether the camera can see enough of the user to coach them.
@immutable
class FramingVerdict {
  const FramingVerdict({
    required this.issues,
    required this.missing,
    required this.bodyBox,
  });

  /// Everything wrong at once, so a debug overlay can show the lot.
  final Set<FramingIssue> issues;

  /// Required joints that are not being tracked.
  final Set<Joint> missing;

  /// Where the tracked body is, or null when there is nothing to measure.
  final BodyBox? bodyBox;

  /// The one issue to put on screen.
  ///
  /// A setup screen listing four complaints gets read as none of them, so
  /// the verdict picks. The order is by how fundamental the problem is and
  /// by how actionable the fix is: "step back" outranks "I cannot see your
  /// ankles" because when somebody stands too near the phone both are true
  /// and only one of them is an instruction.
  FramingIssue? get primary {
    for (final issue in _priority) {
      if (issues.contains(issue)) return issue;
    }
    return null;
  }

  FramingSeverity get severity {
    if (issues.any(_blocking.contains)) return FramingSeverity.blocked;
    if (issues.isNotEmpty) return FramingSeverity.adjust;
    return FramingSeverity.good;
  }

  /// Whether the coach can run at all.
  bool get isUsable => severity != FramingSeverity.blocked;

  static const List<FramingIssue> _priority = [
    FramingIssue.noPerson,
    FramingIssue.tooClose,
    FramingIssue.jointsOutOfView,
    FramingIssue.tooFar,
    FramingIssue.offCentre,
  ];

  static const Set<FramingIssue> _blocking = {
    FramingIssue.noPerson,
    FramingIssue.tooClose,
    FramingIssue.jointsOutOfView,
  };

  @override
  String toString() => 'FramingVerdict(${severity.name}, '
      '${primary?.name ?? 'nothing wrong'})';
}

/// Judging whether the phone is placed well enough to coach from.
///
/// Pure arithmetic over one frame, which is what lets the setup screen be
/// developed and tested without a camera. The thresholds are judgement
/// calls, documented where they are declared, and every one of them is a
/// row in `framing_test.dart`.
abstract final class Framing {
  /// The joints the launch exercises need between them.
  ///
  /// Trunk and legs, and deliberately no face: no form rule reads a face
  /// landmark, and a phone propped on the floor crops heads constantly, so
  /// requiring one would refuse to coach a squat it can see perfectly.
  static const Set<Joint> wholeBody = {
    Joint.leftShoulder,
    Joint.rightShoulder,
    Joint.leftHip,
    Joint.rightHip,
    Joint.leftKnee,
    Joint.rightKnee,
    Joint.leftAnkle,
    Joint.rightAnkle,
  };

  /// Pose confidence below which we say there is nobody there.
  static const double minPoseConfidence = 0.5;

  /// Body span, as a fraction of the frame, above which the user is too
  /// close for the whole movement to stay in shot.
  static const double maxBodySpan = 0.95;

  /// Body span below which landmark noise starts to matter more than the
  /// movement being measured.
  static const double minBodySpan = 0.45;

  /// How far the body's centre may sit from the middle of the frame.
  ///
  /// Generous, because a squat drifts and a lunge travels; this is about
  /// catching somebody set up near the edge, not about standing still.
  static const double maxCentreOffset = 0.25;

  /// Judges one frame.
  ///
  /// [required] defaults to [wholeBody]; from M5 the caller passes the set
  /// the exercise's rep counter actually needs, since a plank does not need
  /// ankles and a press does not need knees.
  static FramingVerdict assess(
    PoseFrame frame, {
    Set<Joint> required = wholeBody,
    double minVisibility = defaultMinVisibility,
    double minConfidence = minPoseConfidence,
  }) {
    Point2? seen(Joint joint) =>
        frame.point(joint, minVisibility: minVisibility);

    final missing = {
      for (final joint in required)
        if (seen(joint) == null) joint,
    };

    // The body box is measured from [wholeBody], never from [required].
    // "Too far away" is a question about how large the person appears, and
    // the answer cannot depend on which joints this particular exercise
    // happens to care about — measuring a press by shoulders and hips alone
    // would report a well-placed phone as too far every time.
    final reference = [
      for (final joint in wholeBody)
        if (seen(joint) != null) seen(joint)!,
    ];

    // Two points is the least that describes an extent. Below that there is
    // nothing to measure and nothing worth saying beyond "I cannot see you".
    if (frame.confidence < minConfidence || reference.length < 2) {
      return FramingVerdict(
        issues: const {FramingIssue.noPerson},
        missing: missing,
        bodyBox: reference.length < 2 ? null : _box(reference),
      );
    }

    final box = _box(reference);
    final issues = <FramingIssue>{};

    // The longer dimension, because a plank is a body too: upright it is the
    // height, face down it is the width, and one threshold has to mean the
    // same thing for both.
    final span = box.height > box.width ? box.height : box.width;

    // Past the edge of the image means part of the body is outside it. ML
    // Kit reports a landmark just out of shot with coordinates outside
    // 0..1 rather than dropping it, which is what makes this detectable at
    // all rather than only showing up as a missing joint.
    final clipped = reference.any(
      (point) => point.x < 0 || point.x > 1 || point.y < 0 || point.y > 1,
    );
    if (clipped || span > maxBodySpan) issues.add(FramingIssue.tooClose);
    if (missing.isNotEmpty) issues.add(FramingIssue.jointsOutOfView);
    if (span < minBodySpan) issues.add(FramingIssue.tooFar);
    if ((box.centreX - 0.5).abs() > maxCentreOffset) {
      issues.add(FramingIssue.offCentre);
    }

    return FramingVerdict(issues: issues, missing: missing, bodyBox: box);
  }

  static BodyBox _box(Iterable<Point2> points) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    for (final point in points) {
      if (point.x < left) left = point.x;
      if (point.x > right) right = point.x;
      if (point.y < top) top = point.y;
      if (point.y > bottom) bottom = point.y;
    }

    return BodyBox(left: left, top: top, right: right, bottom: bottom);
  }
}
