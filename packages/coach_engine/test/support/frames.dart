import 'dart:math' as math;

import 'package:coach_engine/coach_engine.dart';
import 'package:pose_core/pose_core.dart';

/// Frame builders for the counter tests.
///
/// Every counter test drives a signal through a shape — down, hold, up — so
/// these helpers take the *angle* the test is reasoning about and place the
/// joints that produce it, rather than the other way round. A test that has
/// to work out where a knee goes to express "bent to 90 degrees" is a test
/// nobody will read twice.
Landmark landmark(double x, double y, {double visibility = 1}) =>
    Landmark(x: x, y: y, z: 0, visibility: visibility);

/// A side-on leg whose knee is bent to [angle] degrees.
///
/// The knee sits at [kneeX], the ankle straight below it, and the hip at
/// [angle] from the shin. 180 is a straight leg; 90 is a right angle.
Map<Joint, Landmark> leg(
  double angle, {
  double kneeX = 0.5,
  double visibility = 1,
  bool left = true,
}) {
  final radians = angle * math.pi / 180;
  const segment = 0.2;
  const kneeY = 0.7;

  final hip = landmark(
    kneeX + segment * math.sin(radians),
    kneeY + segment * math.cos(radians),
    visibility: visibility,
  );
  final knee = landmark(kneeX, kneeY, visibility: visibility);
  final ankle = landmark(kneeX, kneeY + segment, visibility: visibility);

  return left
      ? {Joint.leftHip: hip, Joint.leftKnee: knee, Joint.leftAnkle: ankle}
      : {Joint.rightHip: hip, Joint.rightKnee: knee, Joint.rightAnkle: ankle};
}

/// Both legs at the same [angle], which is what a squat looks like.
Map<Joint, Landmark> legs(double angle, {double visibility = 1}) => {
      ...leg(angle, visibility: visibility),
      ...leg(angle, kneeX: 0.55, visibility: visibility, left: false),
    };

PoseFrame frame(
  Map<Joint, Landmark> landmarks, {
  int id = 0,
  Duration t = Duration.zero,
  double confidence = 0.9,
}) =>
    PoseFrame(
      frameId: id,
      t: t,
      landmarks: landmarks,
      confidence: confidence,
    );

/// The knee angle a squat counter measures.
const kneeSignal = JointAngle(
  from: Joint.leftHip,
  vertex: Joint.leftKnee,
  to: Joint.leftAnkle,
);

/// A trunk and a thigh, placed to produce a given [tilt] from vertical and a
/// given [hipAngle] at the hip.
///
/// Those two numbers are what tells a plank from a person standing still:
/// the hip angle of the two is the same and the trunk angle is not.
Map<Joint, Landmark> trunkAndThigh({
  required double tilt,
  required double hipAngle,
  double visibility = 1,
  bool left = true,
}) {
  final tiltRadians = tilt * math.pi / 180;
  final hipRadians = hipAngle * math.pi / 180;
  const segment = 0.3;

  // Down the body, from straight up.
  final down = (math.sin(tiltRadians), -math.cos(tiltRadians));
  // Back up it, which is what the hip angle is measured from.
  final up = (-down.$1, -down.$2);
  final thigh = (
    up.$1 * math.cos(hipRadians) - up.$2 * math.sin(hipRadians),
    up.$1 * math.sin(hipRadians) + up.$2 * math.cos(hipRadians),
  );

  const shoulder = (0.25, 0.5);
  final hip = (
    shoulder.$1 + segment * down.$1,
    shoulder.$2 + segment * down.$2,
  );
  final knee = (hip.$1 + segment * thigh.$1, hip.$2 + segment * thigh.$2);

  final offset = left ? 0.0 : 0.02;
  final points = {
    Joint.leftShoulder: landmark(
      shoulder.$1 + offset,
      shoulder.$2,
      visibility: visibility,
    ),
    Joint.leftHip: landmark(hip.$1 + offset, hip.$2, visibility: visibility),
    Joint.leftKnee: landmark(knee.$1 + offset, knee.$2, visibility: visibility),
  };

  return left
      ? points
      : {
          for (final entry in points.entries)
            entry.key.mirrored: entry.value,
        };
}

/// Both sides of a body at the same tilt and hip angle.
Map<Joint, Landmark> torso({
  required double tilt,
  required double hipAngle,
  double visibility = 1,
}) =>
    {
      ...trunkAndThigh(tilt: tilt, hipAngle: hipAngle, visibility: visibility),
      ...trunkAndThigh(
        tilt: tilt,
        hipAngle: hipAngle,
        visibility: visibility,
        left: false,
      ),
    };

/// The two signals a plank hold watches.
const hipSignal = JointAngle(
  from: Joint.leftShoulder,
  vertex: Joint.leftHip,
  to: Joint.leftKnee,
);

const trunkSignal = SegmentTilt(from: Joint.leftShoulder, to: Joint.leftHip);

/// A frame posed so that [signal] reads [value].
///
/// The inverse of a measurement, for the tests that drive a counter from the
/// numbers in its own configuration rather than from a body. It poses one
/// signal and nothing else: a frame from here is not a plausible human, and
/// the fixtures the harness replays are built by interpolating real poses
/// instead.
PoseFrame syntheticFrame(
  PoseSignal signal,
  double value,
  Duration t, {
  int id = 0,
}) {
  final radians = value * math.pi / 180;
  final landmarks = <Joint, Landmark>{};

  void both(Joint joint, double x, double y) {
    landmarks[joint] = landmark(x, y);
    landmarks[joint.mirrored] = landmark(x + 0.04, y);
  }

  switch (signal) {
    case JointAngle(:final from, :final vertex, :final to):
      const segment = 0.2;
      both(vertex, 0.5, 0.6);
      both(to, 0.5, 0.6 + segment);
      both(
        from,
        0.5 + segment * math.sin(radians),
        0.6 + segment * math.cos(radians),
      );
    case SegmentTilt(:final from, :final to):
      const segment = 0.3;
      both(from, 0.4, 0.4);
      both(
        to,
        0.4 + segment * math.sin(radians),
        0.4 - segment * math.cos(radians),
      );
  }

  return frame(landmarks, id: id, t: t);
}
