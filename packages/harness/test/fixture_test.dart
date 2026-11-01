import 'dart:convert';

import 'package:harness/harness.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

PoseFrame _frame(int id) => PoseFrame(
      frameId: id,
      t: Duration(milliseconds: id * 33),
      landmarks: {
        Joint.leftKnee: Landmark(x: 0.5, y: 0.6, z: 0, visibility: 0.9),
      },
      confidence: 0.9,
    );

PoseFixture _fixture({
  int? reps = 8,
  Duration? hold,
  int frames = 3,
}) =>
    PoseFixture(
      name: 'squat_clean',
      exerciseId: 'bodyweight_squat',
      angle: CameraAngle.side,
      source: FixtureSource.synthetic,
      notes: 'eight clean reps',
      expectedReps: reps,
      expectedHold: hold,
      frames: [for (var i = 0; i < frames; i++) _frame(i)],
    );

Map<String, Object?> _json(PoseFixture fixture) =>
    jsonDecode(jsonEncode(fixture.toJson())) as Map<String, Object?>;

void main() {
  group('PoseFixture', () {
    test('round-trips through JSON', () {
      final restored = PoseFixture.fromJson(_json(_fixture()));

      expect(restored.name, 'squat_clean');
      expect(restored.exerciseId, 'bodyweight_squat');
      expect(restored.angle, CameraAngle.side);
      expect(restored.source, FixtureSource.synthetic);
      expect(restored.notes, 'eight clean reps');
      expect(restored.expectedReps, 8);
      expect(restored.frames, hasLength(3));
      expect(restored.frames[1].t, const Duration(milliseconds: 33));
      expect(
        restored.frames.first.landmarks[Joint.leftKnee]!.x,
        closeTo(0.5, 1e-6),
      );
    });

    test('keeps a joint the model never placed absent', () {
      // The whole reason fixtures hold nulls: a recorded set where an ankle
      // leaves the frame has to read back as an ankle that is not there,
      // not as one at the top left corner of the image.
      final restored = PoseFixture.fromJson(_json(_fixture()));

      expect(restored.frames.first.landmarks.keys, [Joint.leftKnee]);
    });

    test('knows a hold from a rep count', () {
      final hold = _fixture(reps: null, hold: const Duration(seconds: 30));

      expect(hold.isHold, isTrue);
      expect(_fixture().isHold, isFalse);
    });

    test('reports how long it runs for', () {
      expect(_fixture(frames: 4).span, const Duration(milliseconds: 99));
    });

    test('rejects a version it does not know', () {
      // A fixture written by a newer extractor may have a different joint
      // ordering, and decoding it anyway would silently remap the body.
      final raw = _json(_fixture())..['fixtureVersion'] = 99;

      expect(
        () => PoseFixture.fromJson(raw),
        throwsA(
          isA<FormatException>()
              .having((e) => e.message, 'message', contains('fixtureVersion')),
        ),
      );
    });

    test('rejects a fixture that expects nothing', () {
      final raw = _json(_fixture())..remove('expected');

      expect(() => PoseFixture.fromJson(raw), throwsFormatException);
    });

    test('rejects a fixture that expects both reps and a hold', () {
      final raw = _json(_fixture())
        ..['expected'] = {'reps': 8, 'holdMs': 30000};

      expect(() => PoseFixture.fromJson(raw), throwsFormatException);
    });

    test('rejects a fixture with no frames', () {
      final raw = _json(_fixture())..['frames'] = <Object?>[];

      expect(() => PoseFixture.fromJson(raw), throwsFormatException);
    });

    test('rejects frames that run backwards', () {
      // Replay assumes time moves forward: the counters ignore a frame older
      // than the last one, so a shuffled fixture would quietly measure
      // nothing and still report a number.
      final raw = _json(_fixture());
      final frames = (raw['frames']! as List<Object?>).reversed.toList();

      expect(
        () => PoseFixture.fromJson(raw..['frames'] = frames),
        throwsFormatException,
      );
    });

    test('rejects an angle it does not know', () {
      final raw = _json(_fixture())..['angle'] = 'overhead';

      expect(() => PoseFixture.fromJson(raw), throwsFormatException);
    });
  });

  group('labelled faults', () {
    test('round-trip through JSON', () {
      final labelled = PoseFixture(
        name: 'labelled',
        exerciseId: 'bodyweight_squat',
        angle: CameraAngle.side,
        source: FixtureSource.recorded,
        notes: 'loose hoodie, phone on a bench',
        expectedReps: 5,
        expectedFaults: const {'back_rounding', 'squat_depth'},
        frames: _fixture().frames,
      );

      final back = PoseFixture.fromJson(_json(labelled));

      expect(back.expectedFaults, {'back_rounding', 'squat_depth'});
    });

    test('a fixture with no faults listed expects none', () {
      // Which is a label, not a gap: it is the one that catches a rule
      // firing on good form.
      final back = PoseFixture.fromJson(_json(_fixture()));

      expect(back.expectedFaults, isEmpty);
    });

    test('refuses a label that is not a list of rule ids', () {
      final raw = _json(_fixture());
      (raw['expected']! as Map<String, Object?>)['faults'] = 'back_rounding';

      expect(
        () => PoseFixture.fromJson(raw),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('faults'),
          ),
        ),
      );
    });
  });
}
