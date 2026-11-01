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
}
