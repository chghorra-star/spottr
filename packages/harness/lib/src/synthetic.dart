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
const double _head = 0.12;
const double _footLength = 0.09;

/// How far behind the ankle the heel sits, and how far below it.
///
/// Small, and only roughly right. What the one rule that reads the foot
/// cares about is the *tilt* of the heel-to-toe line, so the thing worth
/// getting right is that a flat foot is flat.
const double _heelBack = 0.03;
const double _heelDrop = 0.01;

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
    this.trunkLength = _trunk,
    this.head = 0,
    this.foot = 90,
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

  /// Hip to shoulder, as a length rather than an angle.
  ///
  /// The one segment whose length is allowed to vary, because it is the one
  /// the engine measures a length of. A rounded back is invisible to a
  /// skeleton with no landmark on the spine; what is visible is the trunk
  /// getting shorter, so a fixture that wants to demonstrate a rounded back
  /// has to be able to shorten it.
  final double trunkLength;

  /// How far the head juts forward of the trunk line, in degrees. 0 carries
  /// it in line with the body.
  final double head;

  /// Tilt of the heel-to-toe line from vertical. 90 is a foot flat on the
  /// floor; more than that is a heel coming up off one.
  final double foot;

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
        trunkLength: _mix(trunkLength, other.trunkLength, t),
        head: _mix(head, other.head, t),
        foot: _mix(foot, other.foot, t),
      );

  /// The pose as landmarks, both sides.
  ///
  /// Nine joints a side: the six the counters read, plus an ear and a foot
  /// because M6's rules read those. Still no hands and no eyes — nothing
  /// measures them, and a fixture that invented them would be claiming to
  /// have seen something it has not.
  Map<Joint, Landmark> landmarks({
    double visibility = 0.95,
    double jitter = 0,
    math.Random? random,
  }) {
    final knee = _step(ankle, _shin, shin, up: true);
    final hip = _step(knee, _thigh, thigh, up: true);
    final shoulder = _step(hip, trunkLength, trunk, up: true);
    final elbow = _step(shoulder, _upperArm, upperArm, up: false);
    final wrist = _step(elbow, _forearm, forearm, up: false);
    // The head carries on in the direction the trunk was going, turned by
    // however far it is jutting forward.
    final ear = _step(shoulder, _head, trunk + head, up: true);
    final heel = Point2(ankle.x - _heelBack, ankle.y + _heelDrop);
    final toe = _step(heel, _footLength, foot, up: true);

    final left = <Joint, Point2>{
      Joint.leftAnkle: ankle,
      Joint.leftKnee: knee,
      Joint.leftHip: hip,
      Joint.leftShoulder: shoulder,
      Joint.leftElbow: elbow,
      Joint.leftWrist: wrist,
      Joint.leftEar: ear,
      Joint.leftHeel: heel,
      Joint.leftFootIndex: toe,
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

/// Hips pushed up into a tent. Reads as a negative hip offset where a sag
/// reads positive, which is the whole reason that signal is signed.
const plankPiked = SideOnPose(
  ankle: Point2(0.14, 0.70),
  shin: 90,
  thigh: 75,
  trunk: 105,
  upperArm: 0,
  forearm: 0,
);

// ---------------------------------------------------------------------------
// Poses that demonstrate a fault, for the rules added in M6.
//
// Each one differs from a clean pose in exactly the quantity the rule it is
// meant to trip reads, and in nothing else. A fault fixture that also
// changed the depth would not tell you which rule had fired on what.
// ---------------------------------------------------------------------------

/// The bottom of a squat with the trunk shortened, which is what spinal
/// flexion looks like to a skeleton that has no landmark on the spine.
const squatRoundedBottom = SideOnPose(
  ankle: Point2(0.50, 0.90),
  shin: 15,
  thigh: -70,
  trunk: 40,
  upperArm: 10,
  forearm: 60,
  trunkLength: 0.205,
);

/// The bottom of a squat with the heels coming off the floor.
const squatHeelsUpBottom = SideOnPose(
  ankle: Point2(0.50, 0.90),
  shin: 15,
  thigh: -70,
  trunk: 40,
  upperArm: 10,
  forearm: 60,
  foot: 115,
);

/// The bottom of a push-up with the hips dropped out of line.
///
/// The wrists move, which a real push-up's would not — the hands stay where
/// they were put. Nothing measures the wrists in a push-up, and bending the
/// body at the hip while keeping the hands planted needs a chain that can
/// close a loop, which this one cannot.
const pushUpSaggingBottom = SideOnPose(
  ankle: Point2(0.14, 0.756),
  shin: 90,
  thigh: 100,
  trunk: 80,
  upperArm: -45,
  forearm: 45,
);

/// Standing, hips and knees straight, ready to hinge.
const hingeTop = SideOnPose(
  ankle: Point2(0.40, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 0,
  upperArm: 0,
  forearm: 0,
);

/// Folded at the hip with the knees still long: a Romanian deadlift at the
/// bottom.
const hingeBottom = SideOnPose(
  ankle: Point2(0.40, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 70,
  upperArm: 0,
  forearm: 0,
);

/// The same hinge with the trunk shortened: a back rounding under load,
/// which is the one fault this engine is willing to interrupt a set over.
const hingeRoundedBottom = SideOnPose(
  ankle: Point2(0.40, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 70,
  upperArm: 0,
  forearm: 0,
  trunkLength: 0.20,
);

/// Lying on the back, knees bent, hips on the floor.
const bridgeDown = SideOnPose(
  ankle: Point2(0.62, 0.90),
  shin: 20,
  thigh: -152,
  trunk: -90,
  upperArm: -90,
  forearm: -90,
);

/// Hips driven up into line with the shoulders and knees.
const bridgeUp = SideOnPose(
  ankle: Point2(0.62, 0.90),
  shin: 20,
  thigh: -98,
  trunk: -90,
  upperArm: -90,
  forearm: -90,
);

/// Bent over a pair of dumbbells, arms hanging straight down.
const rowTop = SideOnPose(
  ankle: Point2(0.40, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 70,
  upperArm: 0,
  forearm: 0,
);

/// The dumbbells at the ribs, elbow at a right angle, torso where it was.
const rowBottom = SideOnPose(
  ankle: Point2(0.40, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 70,
  upperArm: -20,
  forearm: 70,
);

/// The top of a push-up with the elbows never quite straightening.
///
/// 155 degrees, which is inside the tolerance the counter needs to see a
/// top and outside what the lockout rule asks for. Five degrees further and
/// the counter would never find a top at all and nothing would be counted,
/// which is a different fixture and a worse one to debug.
const pushUpSoftTop = SideOnPose(
  ankle: Point2(0.14, 0.68),
  shin: 90,
  thigh: 90,
  trunk: 90,
  upperArm: -12.5,
  forearm: 12.5,
);

/// Locked out overhead by leaning away from the weight.
const pressLeaningLockout = SideOnPose(
  ankle: Point2(0.50, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 25,
  upperArm: 175,
  forearm: 175,
);

/// A hinge turned into a squat: the knees bend and the hips stop moving.
const hingeKneesBentBottom = SideOnPose(
  ankle: Point2(0.40, 0.90),
  shin: 0,
  thigh: -40,
  trunk: 70,
  upperArm: 0,
  forearm: 0,
);

/// A plank held straight with the head hanging forward of the trunk.
const plankHeadDown = SideOnPose(
  ankle: Point2(0.14, 0.70),
  shin: 90,
  thigh: 90,
  trunk: 90,
  upperArm: 0,
  forearm: 0,
  head: 45,
);

/// The same row with the torso heaving up to help: the fault
/// `torso_swing` is about.
const rowSwungBottom = SideOnPose(
  ankle: Point2(0.40, 0.90),
  shin: 0,
  thigh: 0,
  trunk: 45,
  upperArm: -20,
  forearm: 70,
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
    this.descentShare = 0.5,
  });

  /// How far into the movement this rep goes: 1 is full depth.
  final double depth;

  /// Top to top, excluding any pause at the bottom.
  final Duration duration;

  /// Time spent at the deepest point.
  final Duration holdAtBottom;

  /// Share of [duration] spent on the way in. A half is an even tempo;
  /// much less than that is a rep dropped into rather than lowered.
  final double descentShare;

  Duration get span => duration + holdAtBottom;

  Duration get descent => duration * descentShare;

  Duration get ascent => duration - descent;
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
  Set<String> expectedFaults = const {},
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
    expectedFaults: expectedFaults,
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
  Set<String> expectedFaults = const {},
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
      expectedFaults: expectedFaults,
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
  Set<String> expectedFaults = const {},
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
    expectedFaults: expectedFaults,
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
      final down = rep.descent;
      if (at < down) {
        return rep.depth * _rise(at.inMicroseconds / down.inMicroseconds);
      }
      final afterHold = at - down - rep.holdAtBottom;
      if (afterHold < Duration.zero) return rep.depth;
      return rep.depth *
          _rise(1 - afterHold.inMicroseconds / rep.ascent.inMicroseconds);
    }
    at -= rep.span + gap;
  }
  return 0;
}

/// 0 at `u = 0`, 1 at `u = 1`, flat at both ends.
double _rise(double u) =>
    (1 - math.cos(u.clamp(0.0, 1.0) * math.pi)) / 2;
