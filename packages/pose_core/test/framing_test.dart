import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

Landmark _lm(double x, double y, {double visibility = 1}) =>
    Landmark(x: x, y: y, z: 0, visibility: visibility);

/// A person standing upright, filling [height] of the frame, centred on [cx].
///
/// Only the joints [Framing.wholeBody] asks for, because that is what the
/// verdict is about; the face is deliberately not part of it.
PoseFrame _standing({
  double cx = 0.5,
  double top = 0.1,
  double height = 0.8,
  double confidence = 0.9,
  Set<Joint> omit = const {},
  Set<Joint> dim = const {},
}) {
  final rows = <Joint, double>{
    Joint.leftShoulder: top,
    Joint.rightShoulder: top,
    Joint.leftHip: top + height * 0.45,
    Joint.rightHip: top + height * 0.45,
    Joint.leftKnee: top + height * 0.72,
    Joint.rightKnee: top + height * 0.72,
    Joint.leftAnkle: top + height,
    Joint.rightAnkle: top + height,
  };

  return PoseFrame(
    frameId: 1,
    t: Duration.zero,
    landmarks: {
      for (final entry in rows.entries)
        if (!omit.contains(entry.key))
          entry.key: _lm(
            entry.key.name.startsWith('left') ? cx - 0.06 : cx + 0.06,
            entry.value,
            visibility: dim.contains(entry.key) ? 0.2 : 1,
          ),
    },
    confidence: confidence,
  );
}

void main() {
  group('Framing.wholeBody', () {
    test('asks for the trunk and the legs, not the face', () {
      // No launch form rule reads a face landmark, and a phone propped on
      // the floor crops heads constantly. Requiring one would refuse to
      // coach a squat it can see perfectly well.
      expect(
        Framing.wholeBody,
        {
          Joint.leftShoulder,
          Joint.rightShoulder,
          Joint.leftHip,
          Joint.rightHip,
          Joint.leftKnee,
          Joint.rightKnee,
          Joint.leftAnkle,
          Joint.rightAnkle,
        },
      );
    });
  });

  group('Framing.assess', () {
    test('a well framed person is good', () {
      final verdict = Framing.assess(_standing());

      expect(verdict.issues, isEmpty);
      expect(verdict.severity, FramingSeverity.good);
      expect(verdict.primary, isNull);
      expect(verdict.isUsable, isTrue);
    });

    test('reports no person when pose confidence is low', () {
      final verdict = Framing.assess(_standing(confidence: 0.2));

      expect(verdict.primary, FramingIssue.noPerson);
      expect(verdict.severity, FramingSeverity.blocked);
      expect(verdict.isUsable, isFalse);
    });

    test('reports no person when almost nothing is tracked', () {
      final verdict = Framing.assess(
        PoseFrame(
          frameId: 1,
          t: Duration.zero,
          landmarks: {Joint.leftShoulder: _lm(0.5, 0.3)},
          confidence: 0.9,
        ),
      );

      expect(verdict.primary, FramingIssue.noPerson);
    });

    test('names the joints it cannot see', () {
      final verdict = Framing.assess(
        _standing(omit: {Joint.leftAnkle, Joint.rightAnkle}),
      );

      expect(verdict.primary, FramingIssue.jointsOutOfView);
      expect(verdict.missing, {Joint.leftAnkle, Joint.rightAnkle});
      expect(verdict.isUsable, isFalse);
    });

    test('counts a joint tracked below the visibility floor as unseen', () {
      // A landmark ML Kit reports but has no confidence in is worse than a
      // missing one, because it looks like data.
      final verdict = Framing.assess(
        _standing(dim: {Joint.leftAnkle, Joint.rightAnkle}),
      );

      expect(verdict.primary, FramingIssue.jointsOutOfView);
      expect(verdict.missing, {Joint.leftAnkle, Joint.rightAnkle});
    });

    test('says nobody is there when the whole body is below the floor', () {
      final verdict = Framing.assess(_standing(dim: Framing.wholeBody));

      expect(verdict.primary, FramingIssue.noPerson);
      expect(verdict.bodyBox, isNull);
    });

    test('reports too close when the body runs off the edge of the frame', () {
      final verdict = Framing.assess(_standing(top: 0.2, height: 0.95));

      expect(verdict.issues, contains(FramingIssue.tooClose));
      expect(verdict.primary, FramingIssue.tooClose);
      expect(verdict.isUsable, isFalse);
    });

    test('reports too close when the body fills the frame top to bottom', () {
      final verdict = Framing.assess(_standing(top: 0.01, height: 0.98));

      expect(verdict.primary, FramingIssue.tooClose);
    });

    test('says step back rather than naming the joints it lost', () {
      // Both are true when somebody stands too near the phone, but only one
      // of them is an instruction. "Your ankles are out of view" describes
      // the symptom; "step back" fixes it.
      final verdict = Framing.assess(
        _standing(top: 0.3, height: 0.9, omit: {Joint.leftAnkle}),
      );

      expect(verdict.issues, contains(FramingIssue.jointsOutOfView));
      expect(verdict.primary, FramingIssue.tooClose);
    });

    test('reports too far when the body is small in the frame', () {
      final verdict = Framing.assess(_standing(top: 0.4, height: 0.3));

      expect(verdict.primary, FramingIssue.tooFar);
    });

    test('too far is an adjustment, not a refusal', () {
      // Everything needed is visible, just noisier than ideal. Refusing to
      // coach at all would be worse than coaching and saying so.
      final verdict = Framing.assess(_standing(top: 0.4, height: 0.3));

      expect(verdict.severity, FramingSeverity.adjust);
      expect(verdict.isUsable, isTrue);
    });

    test('reports off centre when the body drifts to one side', () {
      final verdict = Framing.assess(_standing(cx: 0.12));

      expect(verdict.primary, FramingIssue.offCentre);
      expect(verdict.severity, FramingSeverity.adjust);
      expect(verdict.isUsable, isTrue);
    });

    test('tolerates the drift of a normal set', () {
      expect(Framing.assess(_standing(cx: 0.42)).issues, isEmpty);
      expect(Framing.assess(_standing(cx: 0.58)).issues, isEmpty);
    });

    test('a blocking issue outranks an adjustment', () {
      final verdict = Framing.assess(
        _standing(cx: 0.1, top: 0.4, height: 0.2, omit: {Joint.leftKnee}),
      );

      expect(verdict.severity, FramingSeverity.blocked);
      expect(verdict.primary, FramingIssue.jointsOutOfView);
    });

    test('takes the required joints from the caller', () {
      // M5 reads this set from the exercise's rep-counter config: a plank
      // does not need ankles in view and a press does not need knees.
      final verdict = Framing.assess(
        _standing(omit: {Joint.leftAnkle, Joint.rightAnkle}),
        required: {Joint.leftShoulder, Joint.rightShoulder, Joint.leftHip},
      );

      expect(verdict.issues, isEmpty);
    });

    test('measures distance by the whole body, not the required joints', () {
      // Otherwise "too far away" depends on which joints the exercise
      // happens to need: a press asking only for shoulders and hips would
      // measure a third of a person and call a well-placed phone too far.
      final frame = _standing(top: 0.1, height: 0.8);
      final narrow = Framing.assess(
        frame,
        required: {Joint.leftShoulder, Joint.rightShoulder, Joint.leftHip},
      );

      expect(narrow.issues, isEmpty);
      expect(narrow.bodyBox!.height, closeTo(0.8, 1e-9));
    });

    test('judges a face-down body by its longer dimension', () {
      // A plank is horizontal: measured by height it is always too far
      // away, which would refuse to coach the only hold in the launch set.
      final plank = PoseFrame(
        frameId: 1,
        t: Duration.zero,
        landmarks: {
          Joint.leftShoulder: _lm(0.25, 0.48),
          Joint.rightShoulder: _lm(0.25, 0.52),
          Joint.leftHip: _lm(0.55, 0.49),
          Joint.rightHip: _lm(0.55, 0.53),
          Joint.leftKnee: _lm(0.72, 0.50),
          Joint.rightKnee: _lm(0.72, 0.54),
          Joint.leftAnkle: _lm(0.85, 0.51),
          Joint.rightAnkle: _lm(0.85, 0.55),
        },
        confidence: 0.9,
      );

      expect(Framing.assess(plank).issues, isEmpty);
    });

    test('measures the body box for the framing guide', () {
      final verdict = Framing.assess(_standing(cx: 0.5, top: 0.1, height: 0.8));

      expect(verdict.bodyBox, isNotNull);
      expect(verdict.bodyBox!.top, closeTo(0.1, 1e-9));
      expect(verdict.bodyBox!.bottom, closeTo(0.9, 1e-9));
      expect(verdict.bodyBox!.centreX, closeTo(0.5, 1e-9));
      expect(verdict.bodyBox!.height, closeTo(0.8, 1e-9));
    });

    test('has no body box when there is nobody there', () {
      final verdict = Framing.assess(
        PoseFrame(
          frameId: 1,
          t: Duration.zero,
          landmarks: const {},
          confidence: 0.1,
        ),
      );

      expect(verdict.bodyBox, isNull);
      expect(verdict.primary, FramingIssue.noPerson);
    });
  });
}
