import 'dart:math' as math;

import 'package:coach_engine/coach_engine.dart';
import 'package:harness/harness.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

PoseFrame _at(SideOnPose pose) => PoseFrame(
      frameId: 0,
      t: Duration.zero,
      landmarks: pose.landmarks(),
      confidence: 0.95,
    );

void main() {
  group('SideOnPose', () {
    test('places a straight leg at 180 degrees', () {
      expect(kneeAngle.measure(_at(squatTop)), closeTo(180, 1));
    });

    test('interpolates between two poses', () {
      final half = squatTop.lerp(squatBottom, 0.5);
      final top = kneeAngle.measure(_at(squatTop))!;
      final bottom = kneeAngle.measure(_at(squatBottom))!;

      expect(
        kneeAngle.measure(_at(half)),
        closeTo((top + bottom) / 2, 2),
      );
    });

    test('keeps the body inside the frame', () {
      for (final pose in [
        squatTop,
        squatBottom,
        pushUpTop,
        pushUpBottom,
        pressRacked,
        pressLockout,
        plankHeld,
        plankSagging,
      ]) {
        for (final entry in pose.landmarks().entries) {
          expect(
            entry.value.x,
            inInclusiveRange(0, 1),
            reason: '${entry.key.name} x is off the image in $pose',
          );
          expect(
            entry.value.y,
            inInclusiveRange(0, 1),
            reason: '${entry.key.name} y is off the image in $pose',
          );
        }
      }
    });

    test('poses both sides of the body', () {
      final landmarks = squatTop.landmarks();

      expect(landmarks.containsKey(Joint.leftKnee), isTrue);
      expect(landmarks.containsKey(Joint.rightKnee), isTrue);
    });
  });

  group('the launch poses', () {
    test('a squat goes from standing to below parallel', () {
      expect(kneeAngle.measure(_at(squatTop)), closeTo(180, 1));
      expect(kneeAngle.measure(_at(squatBottom)), closeTo(95, 2));
      expect(hipAngle.measure(_at(squatBottom)), closeTo(70, 2));
    });

    test('a push-up goes from locked out to a right angle', () {
      expect(elbowAngle.measure(_at(pushUpTop)), closeTo(180, 1));
      expect(elbowAngle.measure(_at(pushUpBottom)), closeTo(90, 2));
      // Body straight at both ends: a push-up with a sagging hip is a fault,
      // and a fixture that has one by accident would fail an M6 rule for the
      // wrong reason.
      expect(hipAngle.measure(_at(pushUpTop)), closeTo(180, 2));
      expect(hipAngle.measure(_at(pushUpBottom)), closeTo(180, 2));
    });

    test('a push-up keeps its hands on the floor', () {
      final top = pushUpTop.landmarks()[Joint.leftWrist]!;
      final bottom = pushUpBottom.landmarks()[Joint.leftWrist]!;

      expect(bottom.x, closeTo(top.x, 0.02));
      expect(bottom.y, closeTo(top.y, 0.02));
    });

    test('a press goes from the shoulders to overhead', () {
      expect(elbowAngle.measure(_at(pressRacked)), closeTo(90, 2));
      expect(elbowAngle.measure(_at(pressLockout)), closeTo(180, 2));
    });

    test('a plank is horizontal and straight', () {
      expect(trunkTilt.measure(_at(plankHeld)), closeTo(90, 3));
      expect(hipAngle.measure(_at(plankHeld)), closeTo(180, 2));
    });

    test('a sagging plank breaks the hip band and not the trunk band', () {
      // Which band catches it matters: the hold has to pause because the
      // hips dropped, not because the body stopped being horizontal.
      expect(hipAngle.measure(_at(plankSagging))! < 155, isTrue);
      expect(trunkTilt.measure(_at(plankSagging)), inInclusiveRange(55, 125));
    });
  });

  group('syntheticReps', () {
    PoseFixture squatSet({
      int reps = 3,
      double depth = 1,
      Duration repDuration = const Duration(milliseconds: 1800),
      double jitter = 0,
      Duration? dropoutFrom,
      Duration? dropoutFor,
    }) =>
        syntheticReps(
          name: 'test_set',
          exerciseId: 'bodyweight_squat',
          top: squatTop,
          bottom: squatBottom,
          reps: [
            for (var i = 0; i < reps; i++)
              SyntheticRep(depth: depth, duration: repDuration),
          ],
          expectedReps: reps,
          jitter: jitter,
          random: math.Random(1),
          dropoutFrom: dropoutFrom,
          dropoutFor: dropoutFor,
        );

    test('runs at the frame rate it was asked for', () {
      final fixture = squatSet(reps: 1);

      expect(fixture.frames.first.t, Duration.zero);
      for (var i = 1; i < fixture.frames.length; i++) {
        expect(
          fixture.frames[i].t - fixture.frames[i - 1].t,
          const Duration(milliseconds: 33),
        );
        expect(fixture.frames[i].frameId, i);
      }
    });

    test('starts and ends at the top', () {
      final fixture = squatSet(reps: 2);

      expect(kneeAngle.measure(fixture.frames.first), closeTo(180, 2));
      expect(kneeAngle.measure(fixture.frames.last), closeTo(180, 2));
    });

    test('reaches the bottom once per rep', () {
      final fixture = squatSet(reps: 3);
      final deep = [
        for (final frame in fixture.frames)
          if (kneeAngle.measure(frame)! < 110) frame,
      ];

      // Three separate visits, not one long one.
      var visits = 0;
      double? previous;
      for (final frame in fixture.frames) {
        final angle = kneeAngle.measure(frame)!;
        if (angle < 110 && (previous == null || previous >= 110)) visits++;
        previous = angle;
      }

      expect(deep, isNotEmpty);
      expect(visits, 3);
    });

    test('goes only as deep as the rep asks', () {
      final shallow = squatSet(reps: 1, depth: 0.5);
      final deepest = shallow.frames
          .map((frame) => kneeAngle.measure(frame)!)
          .reduce(math.min);

      expect(deepest, closeTo(180 - 85 * 0.5, 3));
    });

    test('adds noise without moving the body off the image', () {
      final noisy = squatSet(reps: 1, jitter: 0.01);

      for (final frame in noisy.frames) {
        for (final landmark in frame.landmarks.values) {
          expect(landmark.x, inInclusiveRange(0, 1));
          expect(landmark.y, inInclusiveRange(0, 1));
        }
      }
    });

    test('noise moves the landmarks', () {
      final clean = squatSet(reps: 1);
      final noisy = squatSet(reps: 1, jitter: 0.01);

      expect(
        noisy.frames[5].landmarks[Joint.leftKnee]!.x,
        isNot(closeTo(clean.frames[5].landmarks[Joint.leftKnee]!.x, 1e-6)),
      );
    });

    test('drops the body entirely for a dropout window', () {
      final fixture = squatSet(
        reps: 3,
        dropoutFrom: const Duration(seconds: 2),
        dropoutFor: const Duration(milliseconds: 600),
      );
      final blank = [
        for (final frame in fixture.frames)
          if (frame.landmarks.isEmpty) frame,
      ];

      expect(blank, isNotEmpty);
      expect(blank.first.t.inMilliseconds, greaterThanOrEqualTo(2000));
      expect(blank.last.t.inMilliseconds, lessThan(2700));
      // Frames keep arriving through a dropout — the camera does not stop
      // just because the model found nobody.
      expect(fixture.frames.length, squatSet(reps: 3).frames.length);
    });

    test('carries the label it was given', () {
      expect(squatSet(reps: 5).expectedReps, 5);
      expect(squatSet().source, FixtureSource.synthetic);
      expect(squatSet().angle, CameraAngle.side);
    });
  });

  group('syntheticHold', () {
    test('holds the posture for the time asked for', () {
      final fixture = syntheticHold(
        name: 'test_hold',
        exerciseId: 'plank',
        posture: plankHeld,
        duration: const Duration(seconds: 2),
        expectedHold: const Duration(seconds: 2),
      );

      expect(fixture.isHold, isTrue);
      expect(fixture.span, const Duration(milliseconds: 1980));
      for (final frame in fixture.frames) {
        expect(hipAngle.measure(frame), closeTo(180, 2));
      }
    });

    test('breaks the posture for the window it is given', () {
      final fixture = syntheticHold(
        name: 'test_hold',
        exerciseId: 'plank',
        posture: plankHeld,
        broken: plankSagging,
        duration: const Duration(seconds: 3),
        breakFrom: const Duration(seconds: 1),
        breakFor: const Duration(seconds: 1),
        expectedHold: const Duration(seconds: 2),
      );
      final sagging = [
        for (final frame in fixture.frames)
          if (hipAngle.measure(frame)! < 155) frame,
      ];

      expect(sagging, isNotEmpty);
      expect(sagging.first.t.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(sagging.last.t.inMilliseconds, lessThan(2050));
    });
  });

  group('syntheticSuite', () {
    test('every fixture is valid and labelled', () {
      for (final fixture in syntheticSuite()) {
        expect(fixture.frames, isNotEmpty);
        expect(fixture.source, FixtureSource.synthetic);
        expect(fixture.notes, isNotEmpty);
        expect(fixture.name, isNotEmpty);
      }
    });

    test('has unique names', () {
      final names = syntheticSuite().map((fixture) => fixture.name).toList();

      expect(names.toSet(), hasLength(names.length));
    });

    test('survives a round trip through JSON', () {
      for (final fixture in syntheticSuite()) {
        final restored = PoseFixture.fromJson(fixture.toJson());

        expect(restored.frames, hasLength(fixture.frames.length));
        expect(restored.expectedReps, fixture.expectedReps);
        expect(restored.expectedHold, fixture.expectedHold);
      }
    });
  });
}
