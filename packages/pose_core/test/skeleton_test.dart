import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

Landmark _lm(double x, double y, {double visibility = 1}) =>
    Landmark(x: x, y: y, z: 0, visibility: visibility);

PoseFrame _frame(Map<Joint, Landmark> landmarks) => PoseFrame(
      frameId: 1,
      t: Duration.zero,
      landmarks: landmarks,
      confidence: 0.9,
    );

void main() {
  group('Skeleton.bones', () {
    test('every bone joins two different joints', () {
      for (final bone in Skeleton.bones) {
        expect(bone.$1, isNot(bone.$2), reason: '$bone');
      }
    });

    test('no bone is listed twice, in either direction', () {
      final seen = <String>{};
      for (final bone in Skeleton.bones) {
        final key = [bone.$1.index, bone.$2.index]
            .map((index) => index.toString())
            .toList()
          ..sort();
        expect(seen.add(key.join('-')), isTrue, reason: 'duplicate $bone');
      }
    });

    test('is left-right symmetric', () {
      // A limb drawn on one side only is the kind of thing nobody notices
      // in a screenshot and everybody notices on their own body.
      final bones = {
        for (final bone in Skeleton.bones) '${bone.$1.name}-${bone.$2.name}',
      };

      for (final bone in Skeleton.bones) {
        final mirrored = '${bone.$1.mirrored.name}-${bone.$2.mirrored.name}';
        final reversed = '${bone.$2.mirrored.name}-${bone.$1.mirrored.name}';
        expect(
          bones.contains(mirrored) || bones.contains(reversed),
          isTrue,
          reason: '$bone has no mirror',
        );
      }
    });

    test('draws the trunk and the limbs', () {
      bool joins(Joint a, Joint b) => Skeleton.bones.any(
            (bone) =>
                (bone.$1 == a && bone.$2 == b) ||
                (bone.$1 == b && bone.$2 == a),
          );

      expect(joins(Joint.leftShoulder, Joint.rightShoulder), isTrue);
      expect(joins(Joint.leftHip, Joint.rightHip), isTrue);
      expect(joins(Joint.leftShoulder, Joint.leftHip), isTrue);
      expect(joins(Joint.leftHip, Joint.leftKnee), isTrue);
      expect(joins(Joint.leftKnee, Joint.leftAnkle), isTrue);
      expect(joins(Joint.leftShoulder, Joint.leftElbow), isTrue);
      expect(joins(Joint.leftElbow, Joint.leftWrist), isTrue);
    });

    test('draws no face', () {
      // The overlay exists to show what the coach is measuring, and no form
      // rule reads a face landmark. A face mesh over somebody's squat is
      // decoration that makes the useful part harder to see.
      const face = {
        Joint.nose,
        Joint.leftEye,
        Joint.rightEye,
        Joint.leftEar,
        Joint.rightEar,
        Joint.mouthLeft,
        Joint.mouthRight,
      };

      for (final bone in Skeleton.bones) {
        expect(face, isNot(contains(bone.$1)), reason: '$bone');
        expect(face, isNot(contains(bone.$2)), reason: '$bone');
      }
    });
  });

  group('Skeleton.joints', () {
    test('is every end of every bone, and nothing else', () {
      final ends = <Joint>{
        for (final bone in Skeleton.bones) ...[bone.$1, bone.$2],
      };

      expect(Skeleton.joints, ends);
      expect(Skeleton.joints, isNot(contains(Joint.nose)));
      expect(Skeleton.joints, contains(Joint.leftKnee));
      expect(Skeleton.joints, contains(Joint.rightHeel));
    });
  });

  group('Skeleton.visibleBones', () {
    test('returns the bones whose ends are both tracked', () {
      final bones = Skeleton.visibleBones(
        _frame({
          Joint.leftHip: _lm(0.4, 0.5),
          Joint.leftKnee: _lm(0.4, 0.7),
          Joint.leftAnkle: _lm(0.4, 0.9),
        }),
      );

      expect(bones, hasLength(2));
      expect(bones.first.$1.y, closeTo(0.5, 1e-9));
      expect(bones.last.$2.y, closeTo(0.9, 1e-9));
    });

    test('leaves out a bone with one end missing', () {
      // Drawing to a joint that is not being tracked would put a limb
      // wherever the last guess landed, which looks like a measurement.
      final bones = Skeleton.visibleBones(
        _frame({
          Joint.leftHip: _lm(0.4, 0.5),
          Joint.leftKnee: _lm(0.4, 0.7),
        }),
      );

      expect(bones, hasLength(1));
    });

    test('leaves out a bone with one end tracked badly', () {
      final bones = Skeleton.visibleBones(
        _frame({
          Joint.leftHip: _lm(0.4, 0.5),
          Joint.leftKnee: _lm(0.4, 0.7, visibility: 0.1),
        }),
      );

      expect(bones, isEmpty);
    });

    test('takes the visibility floor from the caller', () {
      final frame = _frame({
        Joint.leftHip: _lm(0.4, 0.5, visibility: 0.3),
        Joint.leftKnee: _lm(0.4, 0.7, visibility: 0.3),
      });

      expect(Skeleton.visibleBones(frame), isEmpty);
      expect(Skeleton.visibleBones(frame, minVisibility: 0.2), hasLength(1));
    });

    test('returns nothing for an empty frame', () {
      expect(Skeleton.visibleBones(_frame(const {})), isEmpty);
    });
  });
}
