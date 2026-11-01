import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'fixture.dart';

/// Default frame interval: 30 frames a second, which is what the camera
/// layer asks the device for.
const Duration defaultFrameInterval = Duration(milliseconds: 33);

/// Time spent standing at the top between reps.
const Duration defaultRepGap = Duration(milliseconds: 600);

// Segment lengths in normalized image units, for a body that fills most of
// a portrait frame.
const double _shin = 0.17;
const double _thigh = 0.17;
const double _trunk = 0.24;
const double _upperArm = 0.13;
const double _forearm = 0.13;

/// How far the right side of the body sits from the left on screen.
///
/// Small on purpose: from the side view the far limb is almost exactly
/// behind the near one, which is the case the signals average over.
const double _sideOffset = 0.015;

/// A body seen from the side, described by the tilt of each segment.
///
/// Angles rather than positions, for two reasons. The counters measure
/// angles, so a fixture written in angles says what it means — "the knee is
/// bent to 95 degrees" rather than four coordinates somebody has to trust.
/// And interpolating angles bends a limb, where interpolating positions
/// stretches it.
///
/// Body tilts are degrees from straight **up**, arm tilts from straight
/// **down**, both positive leaning the way the user faces (towards +x). The
/// angle at a joint is then `180 - |a - b|` for the two segments meeting
/// there, which is what makes these poses easy to check by hand.
@immutable
class SideOnPose {
  const SideOnPose({
    required this.ankle,
    required this.shin,
    required this.thigh,
    required this.trunk,
    required this.upperArm,
    required this.forearm,
  });

  /// Where the chain starts. Everything else is built from it.
  final Point2 ankle;

  /// Ankle to knee.
  final double shin;

  /// Knee to hip.
  final double thigh;

  /// Hip to shoulder.
  final double trunk;

  /// Shoulder to elbow.
  final double upperArm;

  /// Elbow to wrist.
  final double forearm;

  SideOnPose lerp(SideOnPose other, double t) => SideOnPose(
        ankle: Point2(
          _mix(ankle.x, other.ankle.x, t),
          _mix(ankle.y, other.ankle.y, t),
        ),
        shin: _mix(shin, other.shin, t),
        thigh: _mix(thigh, other.thigh, t),
        trunk: _mix(trunk, other.trunk, t),
        upperArm: _mix(upperArm, other.upperArm, t),
        forearm: _mix(forearm, other.forearm, t),
      );

  /// The pose as landmarks, both sides.
  ///
  /// Six joints a side and no more: no head, hands or feet, because nothing
  /// measures them yet and a fixture that invented them would be claiming
  /// to have seen something it has not.
  Map<Joint, Landmark> landmarks({
    double visibility = 0.95,
    double jitter = 0,
    math.Random? random,
  }) {
    final knee = _step(ankle, _shin, shin, up: true);
    final hip = _step(knee, _thigh, thigh, up: true);
    final shoulder = _step(hip, _trunk, trunk, up: true);
    final elbow = _step(shoulder, _upperArm, upperArm, up: false);
    final wrist = _step(elbow, _forearm, forearm, up: false);

    final left = <Joint, Point2>{
      Joint.leftAnkle: ankle,
      Joint.leftKnee: knee,
      Joint.leftHip: hip,
      Joint.leftShoulder: shoulder,
      Joint.leftElbow: elbow,
      Joint.leftWrist: wrist,
    };

    final landmarks = <Joint, Landmark>{};
    for (final entry in left.entries) {
      landmarks[entry.key] = _landmark(
        entry.value.x,
        entry.value.y,
        visibility,
        jitter,
        random,
      );
      landmarks[entry.key.mirrored] = _landmark(
        entry.value.x + _sideOffset,
        entry.value.y,
        visibility,
        jitter,
        random,
      );
    }
    return landmarks;
  }

  @override
  String toString() => 'SideOnPose(shin: $shin, thigh: $thigh, '
      'trunk: $trunk, upperArm: $upperArm, forearm: $forearm)';
}

Point2 _step(Point2 from, double length, double tilt, {required bool up}) {
  final radians = tilt * math.pi / 180;
  final dy = up ? -math.cos(radians) : math.cos(radians);
  return Point2(
    from.x + length * math.sin(radians),
    from.y + length * dy,
  );
}

Landmark _landmark(
  double x,
  double y,
  double visibility,
  double jitter,
  math.Random? random,
) {
  final noise = jitter == 0 || random == null
      ? (0.0, 0.0)
      : (
          (random.nextDouble() * 2 - 1) * jitter,
          (random.nextDouble() * 2 - 1) * jitter,
        );
  return Landmark(
    x: (x + noise.$1).clamp(0.0, 1.0),
    y: (y + noise.$2).clamp(0.0, 1.0),
    z: 0,
    visibility: visibility,
  );
}

double _mix(double a, double b, double t) => a + (b - a) * t;

// ---------------------------------------------------------------------------
// The poses the suite is built from.
//
// Every one of these is checked by `synthetic_test.dart` against the signals
// the counters actually read, so a mistake in the geometry shows up as a
// wrong angle rather than as a mysteriously uncounted rep.
// ---------------------------------------------------------------------------

/// Standing, arms at the sides. Knee and hip straight.
const squatTop = SideOnPose(
  ankle: Point2(0.50, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 0,
  upperArm: 0,
  forearm: 0,
);

/// Below parallel: knee at 95 degrees, hip at 70, torso leaning forward to
/// stay over the feet, arms out in front for balance.
const squatBottom = SideOnPose(
  ankle: Point2(0.50, 0.90),
  shin: 15,
  thigh: -70,
  trunk: 40,
  upperArm: 10,
  forearm: 60,
);

/// Prone, arms locked out, body in one line.
const pushUpTop = SideOnPose(
  ankle: Point2(0.14, 0.68),
  shin: 90,
  thigh: 90,
  trunk: 90,
  upperArm: 0,
  forearm: 0,
);

/// Chest down, elbow at 90. The body drops by exactly the height the bent
/// arm loses, so the hands stay where they were put.
const pushUpBottom = SideOnPose(
  ankle: Point2(0.14, 0.756),
  shin: 90,
  thigh: 90,
  trunk: 90,
  upperArm: -45,
  forearm: 45,
);

/// Standing with the weight racked at the shoulders: elbow at 90.
const pressRacked = SideOnPose(
  ankle: Point2(0.50, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 0,
  upperArm: 45,
  forearm: 135,
);

/// Locked out overhead.
const pressLockout = SideOnPose(
  ankle: Point2(0.50, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 0,
  upperArm: 175,
  forearm: 175,
);

/// A plank: body horizontal, hips in line with shoulders and knees.
const plankHeld = SideOnPose(
  ankle: Point2(0.14, 0.70),
  shin: 90,
  thigh: 90,
  trunk: 90,
  upperArm: 0,
  forearm: 0,
);

/// Hips dropped. The trunk is still horizontal, so this is caught by the
/// hip band and not by the tilt band — which is the distinction a plank
/// hold exists to make.
const plankSagging = SideOnPose(
  ankle: Point2(0.14, 0.70),
  shin: 90,
  thigh: 115,
  trunk: 65,
  upperArm: 0,
  forearm: 0,
);

// ---------------------------------------------------------------------------
// Fixture generation.
// ---------------------------------------------------------------------------

/// One repetition's shape.
@immutable
class SyntheticRep {
  const SyntheticRep({
    this.depth = 1,
    this.duration = const Duration(milliseconds: 1800),
    this.holdAtBottom = Duration.zero,
  });

  /// How far into the movement this rep goes: 1 is full depth.
  final double depth;

  /// Top to top, excluding any pause at the bottom.
  final Duration duration;

  /// Time spent at the deepest point.
  final Duration holdAtBottom;

  Duration get span => duration + holdAtBottom;
}

/// A set of reps between two poses.
///
/// The caller states [expectedReps]: the generator describes what the body
/// did and the fixture author says what should have been counted. Deriving
/// the label from the thresholds instead would make the suite agree with the
/// counter by construction and measure nothing.
PoseFixture syntheticReps({
  required String name,
  required String exerciseId,
  required SideOnPose top,
  required SideOnPose bottom,
  required List<SyntheticRep> reps,
  required int expectedReps,
  String notes = '',
  CameraAngle angle = CameraAngle.side,
  Duration gap = defaultRepGap,
  Duration frameInterval = defaultFrameInterval,
  double jitter = 0,
  math.Random? random,
  Duration? dropoutFrom,
  Duration? dropoutFor,
}) {
  var total = gap;
  for (final rep in reps) {
    total += rep.span + gap;
  }

  return _build(
    name: name,
    exerciseId: exerciseId,
    angle: angle,
    notes: notes,
    expectedReps: expectedReps,
    total: total,
    frameInterval: frameInterval,
    jitter: jitter,
    random: random,
    dropoutFrom: dropoutFrom,
    dropoutFor: dropoutFor,
    poseAt: (t) => top.lerp(bottom, _phaseAt(t, reps, gap)),
  );
}

/// A hold, optionally broken for a window in the middle.
PoseFixture syntheticHold({
  required String name,
  required String exerciseId,
  required SideOnPose posture,
  required Duration duration,
  required Duration expectedHold,
  SideOnPose? broken,
  Duration? breakFrom,
  Duration? breakFor,
  String notes = '',
  CameraAngle angle = CameraAngle.side,
  Duration frameInterval = defaultFrameInterval,
  double jitter = 0,
  math.Random? random,
  Duration? dropoutFrom,
  Duration? dropoutFor,
}) =>
    _build(
      name: name,
      exerciseId: exerciseId,
      angle: angle,
      notes: notes,
      expectedHold: expectedHold,
      total: duration,
      frameInterval: frameInterval,
      jitter: jitter,
      random: random,
      dropoutFrom: dropoutFrom,
      dropoutFor: dropoutFor,
      poseAt: (t) {
        final from = breakFrom;
        final length = breakFor;
        if (broken == null || from == null || length == null) return posture;
        return t >= from && t < from + length ? broken : posture;
      },
    );

PoseFixture _build({
  required String name,
  required String exerciseId,
  required CameraAngle angle,
  required String notes,
  required Duration total,
  required Duration frameInterval,
  required double jitter,
  required math.Random? random,
  required Duration? dropoutFrom,
  required Duration? dropoutFor,
  required SideOnPose Function(Duration t) poseAt,
  int? expectedReps,
  Duration? expectedHold,
}) {
  final frames = <PoseFrame>[];
  final count = total.inMicroseconds ~/ frameInterval.inMicroseconds;
  final noise = random ?? math.Random(7);

  for (var i = 0; i <= count; i++) {
    final t = frameInterval * i;
    final blank = dropoutFrom != null &&
        dropoutFor != null &&
        t >= dropoutFrom &&
        t < dropoutFrom + dropoutFor;

    frames.add(
      PoseFrame(
        frameId: i,
        t: t,
        // A dropout is the model finding nobody, not the camera stopping:
        // the frames keep coming and they are empty. The two look very
        // different to a counter and identical to a user.
        landmarks: blank
            ? const {}
            : poseAt(t).landmarks(jitter: jitter, random: noise),
        confidence: blank ? 0 : 0.95,
      ),
    );
  }

  return PoseFixture(
    name: name,
    exerciseId: exerciseId,
    angle: angle,
    source: FixtureSource.synthetic,
    notes: notes,
    expectedReps: expectedReps,
    expectedHold: expectedHold,
    frames: frames,
  );
}

/// How deep into the movement the body is at [t].
///
/// A raised cosine rather than a triangle: a real rep has no corner at the
/// bottom, and a corner is exactly the kind of instantaneous reversal a
/// smoothing filter is built to flatten, so a triangular fixture would test
/// the filter instead of the counter.
double _phaseAt(Duration t, List<SyntheticRep> reps, Duration gap) {
  var at = t - gap;
  for (final rep in reps) {
    if (at < Duration.zero) return 0;
    if (at < rep.span) {
      final half = rep.duration * 0.5;
      if (at < half) {
        return rep.depth * _rise(at.inMicroseconds / half.inMicroseconds);
      }
      final afterHold = at - half - rep.holdAtBottom;
      if (afterHold < Duration.zero) return rep.depth;
      return rep.depth *
          _rise(1 - afterHold.inMicroseconds / half.inMicroseconds);
    }
    at -= rep.span + gap;
  }
  return 0;
}

/// 0 at `u = 0`, 1 at `u = 1`, flat at both ends.
double _rise(double u) =>
    (1 - math.cos(u.clamp(0.0, 1.0) * math.pi)) / 2;
