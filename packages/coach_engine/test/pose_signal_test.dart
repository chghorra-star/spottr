import 'package:coach_engine/coach_engine.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

import 'support/frames.dart';

void main() {
  group('JointAngle', () {
    test('measures the angle at the joint it names', () {
      expect(
        kneeSignal.measure(frame(leg(90))),
        closeTo(90, 0.5),
      );
    });

    test('measures the other side when the named one is not tracked', () {
      // The side view is the recommended angle for every launch exercise,
      // and from the side the far leg is behind the near one. Which of the
      // two the model happens to report is not something a config should
      // have to predict.
      expect(
        kneeSignal.measure(frame(leg(120, kneeX: 0.55, left: false))),
        closeTo(120, 0.5),
      );
    });

    test('averages the two sides when both are tracked', () {
      final both = {
        ...leg(100),
        ...leg(140, kneeX: 0.55, left: false),
      };

      expect(kneeSignal.measure(frame(both)), closeTo(120, 0.5));
    });

    test('is null when neither side is tracked', () {
      expect(kneeSignal.measure(frame(const {})), isNull);
    });

    test('ignores a side below the visibility floor', () {
      final both = {
        ...leg(100),
        ...leg(140, kneeX: 0.55, visibility: 0.2, left: false),
      };

      expect(kneeSignal.measure(frame(both)), closeTo(100, 0.5));
    });

    test('is null when a joint it needs is missing from an otherwise '
        'tracked side', () {
      final partial = {...leg(100)}..remove(Joint.leftAnkle);

      expect(kneeSignal.measure(frame(partial)), isNull);
    });

    test('names the joints it reads, both sides', () {
      expect(
        kneeSignal.joints,
        {
          Joint.leftHip,
          Joint.leftKnee,
          Joint.leftAnkle,
          Joint.rightHip,
          Joint.rightKnee,
          Joint.rightAnkle,
        },
      );
    });
  });

  group('SegmentTilt', () {
    const trunk = SegmentTilt(from: Joint.leftShoulder, to: Joint.leftHip);

    test('is 180 for a trunk the right way up', () {
      // from -> to points down the body, and the measurement is from
      // straight up, so an upright person reads 180 rather than 0.
      final upright = {
        Joint.leftShoulder: landmark(0.5, 0.3),
        Joint.leftHip: landmark(0.5, 0.6),
      };

      expect(trunk.measure(frame(upright)), closeTo(180, 0.5));
    });

    test('is 90 for a trunk lying down', () {
      final plank = {
        Joint.leftShoulder: landmark(0.3, 0.5),
        Joint.leftHip: landmark(0.6, 0.5),
      };

      expect(trunk.measure(frame(plank)), closeTo(90, 0.5));
    });

    test('does not distinguish leaning left from leaning right', () {
      final leftward = {
        Joint.leftShoulder: landmark(0.5, 0.3),
        Joint.leftHip: landmark(0.4, 0.6),
      };
      final rightward = {
        Joint.leftShoulder: landmark(0.5, 0.3),
        Joint.leftHip: landmark(0.6, 0.6),
      };

      expect(
        trunk.measure(frame(leftward)),
        closeTo(trunk.measure(frame(rightward))!, 0.5),
      );
    });

    test('is null for a segment with no length', () {
      final collapsed = {
        Joint.leftShoulder: landmark(0.5, 0.5),
        Joint.leftHip: landmark(0.5, 0.5),
      };

      expect(trunk.measure(frame(collapsed)), isNull);
    });
  });

  group('JointOffset', () {
    // A plank, seen from the side: the shoulder-knee line is the reference
    // and the hip is judged against it.
    const hipOffset = JointOffset(
      joint: Joint.leftHip,
      from: Joint.leftShoulder,
      to: Joint.leftKnee,
    );

    Map<Joint, Landmark> plank({
      required double hipY,
      double x = 0,
      bool left = true,
    }) {
      final points = {
        Joint.leftShoulder: landmark(0.20 + x, 0.50),
        Joint.leftHip: landmark(0.50 + x, hipY),
        Joint.leftKnee: landmark(0.80 + x, 0.50),
      };
      return left
          ? points
          : {for (final e in points.entries) e.key.mirrored: e.value};
    }

    test('reads a dropped hip as a positive percentage of the span', () {
      // 0.10 below a 0.60 long line.
      expect(
        hipOffset.measure(frame(plank(hipY: 0.60))),
        closeTo(16.67, 0.1),
      );
    });

    test('reads a raised hip as a negative one', () {
      expect(
        hipOffset.measure(frame(plank(hipY: 0.44))),
        closeTo(-10, 0.1),
      );
    });

    test('averages the two sides', () {
      final both = {
        ...plank(hipY: 0.60),
        ...plank(hipY: 0.50, x: 0.02, left: false),
      };

      expect(hipOffset.measure(frame(both)), closeTo(8.33, 0.1));
    });

    test('is null when the reference line is nearly vertical', () {
      // Standing up, where "the hip is below the shoulder-knee line" is not
      // a sentence about anything.
      final standing = {
        Joint.leftShoulder: landmark(0.50, 0.30),
        Joint.leftHip: landmark(0.52, 0.55),
        Joint.leftKnee: landmark(0.51, 0.75),
      };

      expect(hipOffset.measure(frame(standing)), isNull);
    });

    test('is null when the joint being judged is not tracked', () {
      final noHip = {
        Joint.leftShoulder: landmark(0.20, 0.50),
        Joint.leftKnee: landmark(0.80, 0.50),
      };

      expect(hipOffset.measure(frame(noHip)), isNull);
    });

    test('names every joint it reads, on both sides', () {
      expect(hipOffset.joints, {
        Joint.leftHip,
        Joint.leftShoulder,
        Joint.leftKnee,
        Joint.rightHip,
        Joint.rightShoulder,
        Joint.rightKnee,
      });
    });

    test('reports a percentage, not degrees', () {
      expect(hipOffset.unit, '%');
      expect(kneeSignal.unit, 'deg');
    });
  });

  group('SegmentRatio', () {
    // The trunk measured against the thigh: a length that does not change
    // when the body moves closer to the camera.
    const trunkRatio = SegmentRatio(
      segment: Segment(Joint.leftShoulder, Joint.leftHip),
      against: Segment(Joint.leftHip, Joint.leftKnee),
    );

    Map<Joint, Landmark> spine({
      required double trunk,
      double scale = 1,
      double x = 0,
      bool left = true,
    }) {
      final points = {
        Joint.leftShoulder: landmark(0.5 * scale + x, (0.6 - trunk) * scale),
        Joint.leftHip: landmark(0.5 * scale + x, 0.6 * scale),
        Joint.leftKnee: landmark(0.5 * scale + x, 0.8 * scale),
      };
      return left
          ? points
          : {for (final e in points.entries) e.key.mirrored: e.value};
    }

    test('reads one segment as a percentage of the other', () {
      expect(
        trunkRatio.measure(frame(spine(trunk: 0.3))),
        closeTo(150, 0.5),
      );
    });

    test('does not change when the body moves away from the camera', () {
      // The whole reason a form rule reads a ratio and not a length: a
      // threshold in normalized image units gets stricter as the user
      // steps back.
      final near = trunkRatio.measure(frame(spine(trunk: 0.3)));
      final far = trunkRatio.measure(frame(spine(trunk: 0.3, scale: 0.5)));

      expect(far, closeTo(near!, 0.5));
    });

    test('averages the two sides', () {
      final both = {
        ...spine(trunk: 0.3),
        ...spine(trunk: 0.2, x: 0.02, left: false),
      };

      expect(trunkRatio.measure(frame(both)), closeTo(125, 0.5));
    });

    test('is null when the reference segment is missing', () {
      final noThigh = {
        Joint.leftShoulder: landmark(0.5, 0.3),
        Joint.leftHip: landmark(0.5, 0.6),
      };

      expect(trunkRatio.measure(frame(noThigh)), isNull);
    });

    test('is null when the reference segment has no length', () {
      final collapsed = {
        Joint.leftShoulder: landmark(0.5, 0.3),
        Joint.leftHip: landmark(0.5, 0.6),
        Joint.leftKnee: landmark(0.5, 0.6),
      };

      expect(trunkRatio.measure(frame(collapsed)), isNull);
    });
  });
}
