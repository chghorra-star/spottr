import 'dart:math' as math;

import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

import 'support/frames.dart';

final catalog = ExerciseCatalog(standardExercises);

const _interval = Duration(milliseconds: 33);

/// 0 at both ends and 1 in the middle, with no corner at the bottom.
double _rise(double u) => (1 - math.cos(u.clamp(0.0, 1.0) * math.pi)) / 2;

/// Frames for a set of squats, described by the knee angle.
///
/// Only legs: no trunk, no feet, no ears. That is deliberate for most of
/// these tests — a rule whose joints are missing has to say so rather than
/// pass — and the tests that need a whole body build one.
List<PoseFrame> squats({
  required int reps,
  double top = 170,
  double bottom = 95,
  Duration duration = const Duration(milliseconds: 1800),
  Duration gap = const Duration(milliseconds: 600),
  Duration descent = const Duration(milliseconds: 900),
}) {
  final frames = <PoseFrame>[];
  var t = Duration.zero;
  var id = 0;

  void emit(double angle) {
    frames.add(frame(legs(angle), id: id++, t: t));
    t += _interval;
  }

  void rest() {
    for (var i = 0; i < gap.inMicroseconds ~/ _interval.inMicroseconds; i++) {
      emit(top);
    }
  }

  rest();
  for (var rep = 0; rep < reps; rep++) {
    final down = descent.inMicroseconds ~/ _interval.inMicroseconds;
    final up = (duration - descent).inMicroseconds ~/ _interval.inMicroseconds;
    for (var i = 0; i < down; i++) {
      emit(top - (top - bottom) * _rise(i / down));
    }
    for (var i = 0; i < up; i++) {
      emit(bottom + (top - bottom) * _rise(i / up));
    }
    rest();
  }
  return frames;
}

/// A whole body in a plank, which is what the plank rules need.
///
/// [sag] is how far the hip drops below the shoulder-to-knee line, in
/// normalized units.
Map<Joint, Landmark> plankBody({double sag = 0}) {
  final points = <Joint, Point2>{
    Joint.leftShoulder: const Point2(0.20, 0.60),
    Joint.leftHip: Point2(0.50, 0.60 + sag),
    Joint.leftKnee: const Point2(0.74, 0.60),
    Joint.leftAnkle: const Point2(0.90, 0.60),
    // Roughly in line with the trunk, which is what neck_alignment is
    // about: the head carried on top of the body rather than hanging off
    // the front of it.
    Joint.leftEar: const Point2(0.08, 0.585),
    Joint.leftElbow: const Point2(0.20, 0.72),
    Joint.leftWrist: const Point2(0.20, 0.84),
  };

  final landmarks = <Joint, Landmark>{};
  for (final entry in points.entries) {
    landmarks[entry.key] = landmark(entry.value.x, entry.value.y);
    landmarks[entry.key.mirrored] =
        landmark(entry.value.x + 0.015, entry.value.y);
  }
  return landmarks;
}

List<PoseFrame> plank({
  required Duration duration,
  Duration? sagFrom,
  Duration? sagFor,
  double sag = 0.06,
}) {
  final frames = <PoseFrame>[];
  final count = duration.inMicroseconds ~/ _interval.inMicroseconds;

  for (var i = 0; i <= count; i++) {
    final t = _interval * i;
    final dropped = sagFrom != null &&
        sagFor != null &&
        t >= sagFrom &&
        t < sagFrom + sagFor;
    frames.add(
      frame(plankBody(sag: dropped ? sag : 0), id: i, t: t),
    );
  }
  return frames;
}

CoachTick run(FormAnalyzer analyzer, List<PoseFrame> frames) {
  var tick = analyzer.tick;
  for (final frame in frames) {
    tick = analyzer.update(frame);
  }
  return tick;
}

void main() {
  FormAnalyzer squatAnalyzer({CameraAngle? angle}) => FormAnalyzer(
        exercise: catalog.require('bodyweight_squat'),
        angle: angle,
      );

  group('FormAnalyzer', () {
    test('counts the set, same as the counter alone', () {
      final tick = run(squatAnalyzer(), squats(reps: 5));

      expect((tick.counter as RepTick).counted, 5);
      expect(tick.review.counted, 5);
    });

    test('reviews every attempt, in order', () {
      final analyzer = squatAnalyzer();
      final verdicts = <FormVerdict>[];
      for (final frame in squats(reps: 3)) {
        final tick = analyzer.update(frame);
        if (tick.completed != null) verdicts.add(tick.completed!);
      }

      expect(verdicts, hasLength(3));
      expect(
        analyzer.tick.review.reps.map((rep) => rep.event.index),
        [1, 2, 3],
      );
    });

    test('keeps the last verdict on every frame after it', () {
      // The same reason `RepTick.last` exists: the camera outruns the UI,
      // so a verdict delivered on one frame is a verdict nobody sees.
      final analyzer = squatAnalyzer();
      final tick = run(analyzer, squats(reps: 1));

      expect(tick.completed, isNull);
      expect(tick.last, isNotNull);
      expect(tick.last!.checked, greaterThan(0));
    });

    test('has no verdict before the first attempt finishes', () {
      final analyzer = squatAnalyzer();
      final tick = analyzer.update(frame(legs(170)));

      expect(tick.last, isNull);
      expect(tick.review.reps, isEmpty);
    });

    test('a full-depth squat passes the depth rule', () {
      final tick = run(squatAnalyzer(), squats(reps: 3, bottom: 95));

      expect(tick.review.firings, isNot(contains('squat_depth')));
      expect(tick.last!.violations, isEmpty);
    });

    test('a squat that stops high fires the depth rule on every rep', () {
      final tick = run(squatAnalyzer(), squats(reps: 3, bottom: 125));

      expect(tick.review.firings['squat_depth'], 3);
      expect(
        tick.last!.violations.map((violation) => violation.ruleId),
        contains('squat_depth'),
      );
    });

    test('a rule whose joints are missing is unchecked, never passed', () {
      // These frames are a pair of legs. Nothing about the spine or the
      // heels can be read from them, and a coach that said nothing would be
      // claiming both were fine.
      final tick = run(squatAnalyzer(), squats(reps: 2));

      expect(tick.last!.notVisible, containsAll(['back_rounding', 'heel_lift']));
      expect(tick.review.neverChecked, containsAll(['heel_lift']));
    });

    test('carries what the camera angle cannot see', () {
      final side = squatAnalyzer();
      expect(side.selection.blind, {'knee_valgus'});

      final tick = run(side, squats(reps: 1));
      expect(tick.last!.blind, {'knee_valgus'});
    });

    test('carries what the engine does not check yet', () {
      final front = squatAnalyzer(angle: CameraAngle.front);
      final tick = run(front, squats(reps: 1));

      expect(tick.last!.notImplemented, {'knee_valgus'});
      expect(front.selection.complete, isFalse);
    });

    test('from an angle it cannot coach from, it judges nothing', () {
      final analyzer = FormAnalyzer(
        exercise: catalog.require('plank'),
        angle: CameraAngle.front,
      );

      final tick = run(analyzer, plank(duration: const Duration(seconds: 5)));

      expect(analyzer.selection.active, isEmpty);
      expect(tick.review.formScore, isNull);
      expect(tick.live.checked, 0);
    });

    test('scores a clean set at full marks and a flagged one below', () {
      final clean = run(squatAnalyzer(), squats(reps: 4)).review;
      final shallow =
          run(squatAnalyzer(), squats(reps: 4, bottom: 125)).review;

      expect(clean.formScore, 100);
      expect(shallow.formScore!, lessThan(100));
    });

    test('a rep that did not count is reviewed but not scored', () {
      // Four attempts at 400ms each, which no squat is. They appear in the
      // ledger with a reason and they do not touch the score.
      final tick = run(
        squatAnalyzer(),
        squats(
          reps: 4,
          duration: const Duration(milliseconds: 400),
          descent: const Duration(milliseconds: 200),
        ),
      );

      expect(tick.review.reps, isNotEmpty);
      expect(tick.review.counted, 0);
      expect(tick.review.formScore, isNull);
    });

    test('reports what is firing right now, before the rep ends', () {
      // Mid-rep, there is no verdict to give and the live window is all the
      // coach has. A depth rule cannot answer from it — there is no bottom
      // yet — and that is the honest answer rather than a pass.
      final analyzer = squatAnalyzer();
      final frames = squats(reps: 1);
      CoachTick? midRep;
      for (final frame in frames) {
        final tick = analyzer.update(frame);
        final counter = tick.counter;
        if (counter is RepTick && counter.phase == RepPhase.descending) {
          midRep = tick;
        }
      }

      expect(midRep, isNotNull);
      expect(midRep!.completed, isNull);
      expect(midRep.live.notVisible, contains('squat_depth'));
    });

    test('forgets the set on reset', () {
      final analyzer = squatAnalyzer();
      run(analyzer, squats(reps: 3));
      analyzer.reset();

      expect(analyzer.tick.review.reps, isEmpty);
      expect(analyzer.tick.last, isNull);
      expect((analyzer.tick.counter as RepTick).counted, 0);
    });
  });

  group('FormAnalyzer on a hold', () {
    FormAnalyzer plankAnalyzer() =>
        FormAnalyzer(exercise: catalog.require('plank'));

    test('a straight plank passes its rules', () {
      final tick = run(plankAnalyzer(), plank(duration: const Duration(seconds: 8)));

      expect((tick.counter as HoldTick).held.inSeconds, greaterThan(6));
      expect(tick.review.hold, isNotNull);
      expect(tick.review.hold!.violations, isEmpty);
      expect(tick.review.formScore, 100);
    });

    test('hips that drop for a few seconds fire the sag rule', () {
      final tick = run(
        plankAnalyzer(),
        plank(
          duration: const Duration(seconds: 20),
          sagFrom: const Duration(seconds: 8),
          sagFor: const Duration(seconds: 5),
        ),
      );

      expect(tick.review.firings, contains('hip_sag'));
      expect(tick.review.formScore!, lessThan(100));
    });

    test('a sag is remembered after the hips come back up', () {
      // The rule is about what happened during the hold, and the set score
      // is read at the end of it. A fault that healed itself is still a
      // fault that happened.
      final analyzer = plankAnalyzer();
      run(
        analyzer,
        plank(
          duration: const Duration(seconds: 20),
          sagFrom: const Duration(seconds: 4),
          sagFor: const Duration(seconds: 4),
        ),
      );

      expect(analyzer.tick.live.violations, isEmpty);
      expect(analyzer.tick.review.hold!.violations, isNotEmpty);
    });

    test('a brief wobble is not a fault', () {
      final tick = run(
        plankAnalyzer(),
        plank(
          duration: const Duration(seconds: 20),
          sagFrom: const Duration(seconds: 8),
          sagFor: const Duration(milliseconds: 100),
        ),
      );

      expect(tick.review.firings, isNot(contains('hip_sag')));
    });

    test('reviews no reps, because a hold has none', () {
      final tick = run(plankAnalyzer(), plank(duration: const Duration(seconds: 5)));

      expect(tick.review.reps, isEmpty);
      expect(tick.completed, isNull);
      expect(tick.last, isNull);
    });
  });

  group('CoachStream', () {
    test('runs the analyzer over a frame stream', () async {
      final ticks = await Stream<PoseFrame>.fromIterable(squats(reps: 2))
          .transform(
            CoachStream(exercise: catalog.require('bodyweight_squat')),
          )
          .toList();

      expect(ticks, hasLength(squats(reps: 2).length));
      expect((ticks.last.counter as RepTick).counted, 2);
    });

    test('gives every subscription its own set', () async {
      // Two listeners are two sets, not one set counted twice. The same
      // contract the counter stream has, for the same reason.
      final stream = Stream<PoseFrame>.fromIterable(squats(reps: 2));
      final transformer = CoachStream(
        exercise: catalog.require('bodyweight_squat'),
      );
      final first = await stream.transform(transformer).last;

      final second = await Stream<PoseFrame>.fromIterable(squats(reps: 2))
          .transform(transformer)
          .last;

      expect((first.counter as RepTick).counted, 2);
      expect((second.counter as RepTick).counted, 2);
    });

    test('refuses an exercise the camera does not coach', () {
      expect(
        () => FormAnalyzer(exercise: catalog.require('barbell_back_squat')),
        throwsArgumentError,
      );
    });
  });

  group('what a rep window covers', () {
    test('the rest at the top counts as part of the rep that follows it', () {
      // A rule about the top of a rep has to read the moment the user was
      // actually standing up, which is not the frame the counter ended the
      // rep on: that one is up to a whole tolerance band short. Stood in
      // for here by a rule that demands a nearly straight knee at the top
      // of a squat, which the final frame of a rep never shows.
      final analyzer = FormAnalyzer(
        exercise: catalog.require('bodyweight_squat'),
        rules: const {
          'squat_depth': SignalBoundRule(
            id: 'squat_depth',
            severity: RuleSeverity.minor,
            signal: kneeAngle,
            at: RepSample.top,
            min: 168,
          ),
        },
      );

      final tick = run(analyzer, squats(reps: 3, top: 172));

      expect(tick.review.firings, isEmpty);
      expect(tick.last!.violations, isEmpty);
    });

    test('an attempt the counter refused is not judged by the rules', () {
      // Measuring how deep somebody got into a movement they abandoned
      // produces faults about a movement they never made. The counter's own
      // reason is the whole verdict for those.
      final tick = run(
        squatAnalyzer(),
        squats(reps: 4, bottom: 142),
      );

      expect(tick.review.counted, 0);
      expect(tick.review.reps, hasLength(4));
      expect(tick.review.firings, isEmpty);
      for (final rep in tick.review.reps) {
        expect(rep.verdict.checked, 0);
      }
    });
  });
}
