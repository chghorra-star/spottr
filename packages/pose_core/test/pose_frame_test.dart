import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

Landmark _lm(double x, double y, {double visibility = 1}) =>
    Landmark(x: x, y: y, z: 0, visibility: visibility);

PoseFrame _frame(Map<Joint, Landmark> landmarks, {double confidence = 1}) =>
    PoseFrame(
      frameId: 1,
      t: Duration.zero,
      landmarks: landmarks,
      confidence: confidence,
    );

void main() {
  group('Joint', () {
    test('has the 33 BlazePose landmarks', () {
      expect(Joint.values.length, 33);
    });

    test('ordinals match the BlazePose index contract', () {
      // The native bridge and the Python extractor both send landmarks as an
      // array indexed by BlazePose position. Reordering this enum would
      // silently remap every joint, so the contract is pinned here.
      expect(Joint.nose.index, 0);
      expect(Joint.leftShoulder.index, 11);
      expect(Joint.rightShoulder.index, 12);
      expect(Joint.leftHip.index, 23);
      expect(Joint.rightHip.index, 24);
      expect(Joint.leftKnee.index, 25);
      expect(Joint.rightKnee.index, 26);
      expect(Joint.leftAnkle.index, 27);
      expect(Joint.rightAnkle.index, 28);
      expect(Joint.rightFootIndex.index, 32);
    });

    test('exposes the mirrored joint for symmetry checks', () {
      expect(Joint.leftKnee.mirrored, Joint.rightKnee);
      expect(Joint.rightShoulder.mirrored, Joint.leftShoulder);
      expect(Joint.nose.mirrored, Joint.nose);
    });
  });

  group('PoseFrame.point', () {
    test('returns the landmark position when visible', () {
      final frame = _frame({Joint.leftKnee: _lm(0.4, 0.7)});
      expect(frame.point(Joint.leftKnee)!.x, closeTo(0.4, 1e-9));
    });

    test('returns null for a joint the model did not report', () {
      final frame = _frame({Joint.leftKnee: _lm(0.4, 0.7)});
      expect(frame.point(Joint.rightKnee), isNull);
    });

    test('returns null when visibility is below the threshold', () {
      final frame = _frame({Joint.leftKnee: _lm(0.4, 0.7, visibility: 0.2)});
      expect(frame.point(Joint.leftKnee, minVisibility: 0.5), isNull);
      expect(frame.point(Joint.leftKnee, minVisibility: 0.1), isNotNull);
    });
  });

  group('PoseFrame.angleAt', () {
    test('computes a joint angle from three tracked joints', () {
      final frame = _frame({
        Joint.leftHip: _lm(0.50, 0.40),
        Joint.leftKnee: _lm(0.50, 0.65),
        Joint.leftAnkle: _lm(0.50, 0.90),
      });
      final knee = frame.angleAt(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle);
      expect(knee!, closeTo(180, 0.001));
    });

    test('returns null when any of the three joints is untracked', () {
      final frame = _frame({
        Joint.leftHip: _lm(0.50, 0.40),
        Joint.leftKnee: _lm(0.50, 0.65),
      });
      expect(
        frame.angleAt(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle),
        isNull,
      );
    });

    test('returns null when a joint is tracked but not confidently', () {
      final frame = _frame({
        Joint.leftHip: _lm(0.50, 0.40),
        Joint.leftKnee: _lm(0.50, 0.65),
        Joint.leftAnkle: _lm(0.50, 0.90, visibility: 0.1),
      });
      expect(
        frame.angleAt(
          Joint.leftHip,
          Joint.leftKnee,
          Joint.leftAnkle,
          minVisibility: 0.5,
        ),
        isNull,
      );
    });
  });

  group('PoseFrame.hasAll', () {
    test('is true only when every requested joint is confidently tracked', () {
      final frame = _frame({
        Joint.leftHip: _lm(0.5, 0.4),
        Joint.leftKnee: _lm(0.5, 0.65, visibility: 0.3),
      });
      expect(frame.hasAll({Joint.leftHip}), isTrue);
      expect(frame.hasAll({Joint.leftHip, Joint.leftKnee}), isFalse);
      expect(
        frame.hasAll({Joint.leftHip, Joint.leftKnee}, minVisibility: 0.2),
        isTrue,
      );
    });

    test('is true for an empty request', () {
      expect(_frame(const {}).hasAll(const {}), isTrue);
    });
  });

  group('Landmark', () {
    test('rejects a visibility outside 0..1', () {
      expect(
        () => Landmark(x: 0, y: 0, z: 0, visibility: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('compares by value', () {
      expect(_lm(0.1, 0.2), equals(_lm(0.1, 0.2)));
      expect(_lm(0.1, 0.2), isNot(equals(_lm(0.1, 0.3))));
    });
  });
}
