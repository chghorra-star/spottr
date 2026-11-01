import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:harness/harness.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

PoseFixture _named(String name) =>
    syntheticSuite().firstWhere((fixture) => fixture.name == name);

void main() {
  group('replay', () {
    test('counts a clean set exactly', () {
      final result = replay(_named('squat_clean_8'));

      expect(result.countedReps, 8);
      expect(result.attempts, 8);
      expect(result.passed, isTrue);
      expect(
        result.ledger.map((event) => event.outcome).toSet(),
        {RepOutcome.counted},
      );
    });

    test('counts a shallow set and flags every rep in it', () {
      final result = replay(_named('squat_shallow_6'));

      expect(result.countedReps, 6);
      expect(
        result.ledger.map((event) => event.fault).toSet(),
        {RepFault.shallow},
      );
    });

    test('leaves the partial reps out of the count and in the ledger', () {
      final result = replay(_named('squat_six_of_eight'));

      expect(result.countedReps, 6);
      expect(result.attempts, 8);
      expect(
        result.ledger.where((event) => !event.counted).map((e) => e.fault),
        everyElement(RepFault.partialRange),
      );
    });

    test('refuses a set performed faster than the movement allows', () {
      final result = replay(_named('squat_bounced_8'));

      expect(result.countedReps, 0);
      expect(
        result.ledger.map((event) => event.fault).toSet(),
        {RepFault.tooFast},
      );
    });

    test('counts through landmark noise', () {
      // The case the smoothing filter and the hysteresis band exist for.
      final result = replay(_named('squat_noisy_8'));

      expect(result.countedReps, 8);
    });

    test('loses the rep the tracking dropped and keeps the rest', () {
      final result = replay(_named('squat_dropout_8'));

      expect(result.countedReps, 7);
      expect(
        result.ledger.map((event) => event.fault),
        contains(RepFault.lostTracking),
      );
      expect(result.framesTracked, lessThan(result.framesSeen));
    });

    test('counts a rep with a pause at the bottom', () {
      final result = replay(_named('squat_paused_4'));

      expect(result.countedReps, 4);
      // The pause lands in the descent, which is what makes the tempo
      // figures comparable between a paused rep and a continuous one.
      expect(result.ledger.first.descent, greaterThan(result.ledger.first.ascent));
    });

    test('counts a movement that opens rather than closes', () {
      expect(replay(_named('press_clean_6')).countedReps, 6);
    });

    test('counts a push-up', () {
      expect(replay(_named('pushup_clean_10')).countedReps, 10);
    });

    test('times a hold', () {
      final result = replay(_named('plank_30s'));

      expect(result.held, isNotNull);
      expect(result.countedReps, isNull);
      expect(result.passed, isTrue);
      expect(
        (result.held! - const Duration(seconds: 30)).abs(),
        lessThan(const Duration(milliseconds: 100)),
      );
    });

    test('stops the clock for the part of a hold that broke', () {
      final result = replay(_named('plank_broken_20s'));

      expect(result.passed, isTrue);
      expect(
        (result.held! - const Duration(seconds: 15)).abs(),
        lessThan(const Duration(milliseconds: 400)),
      );
    });

    test('runs the same smoothing the app does', () {
      // Not a nicety. A measurement taken on a different pipeline than the
      // one that ships is a measurement of something that does not ship.
      final raw = replay(_named('squat_noisy_8'), smooth: false);
      final smoothed = replay(_named('squat_noisy_8'));

      expect(smoothed.ledger.first.rangeOfMotion,
          isNot(closeTo(raw.ledger.first.rangeOfMotion, 1e-6)));
    });

    test('refuses a fixture for an exercise the camera does not coach', () {
      final fixture = PoseFixture(
        name: 'nonsense',
        exerciseId: 'barbell_back_squat',
        angle: CameraAngle.side,
        source: FixtureSource.synthetic,
        notes: '',
        expectedReps: 1,
        frames: _named('squat_clean_8').frames,
      );

      expect(() => replay(fixture), throwsArgumentError);
    });

    test('refuses a fixture for an exercise that does not exist', () {
      final fixture = PoseFixture(
        name: 'nonsense',
        exerciseId: 'moon_jump',
        angle: CameraAngle.side,
        source: FixtureSource.synthetic,
        notes: '',
        expectedReps: 1,
        frames: _named('squat_clean_8').frames,
      );

      expect(() => replay(fixture), throwsArgumentError);
    });

    test('the filter is what keeps noise from inventing reps', () {
      // Replaying the same fixture with and without the smoothing step is
      // the only way to see what the filter is actually buying, and it is
      // not a tidier overlay: unsmoothed, landmark noise opens an attempt
      // that never happened and mangles the range of the ones that did.
      final smoothed = replay(_named('squat_noisy_8'));
      final raw = replay(_named('squat_noisy_8'), smooth: false);

      expect(smoothed.attempts, 8);
      expect(raw.attempts, greaterThan(smoothed.attempts));
    });
  });

  group('runFixtures', () {
    test('reports the whole suite', () {
      final report = runFixtures(syntheticSuite());

      expect(report.results, hasLength(syntheticSuite().length));
      expect(report.failures, isEmpty);
      expect(report.repAccuracy, 1);
    });

    test('scores a miscount as the error it is', () {
      final clean = _named('squat_clean_8');
      final mislabelled = PoseFixture(
        name: 'squat_mislabelled',
        exerciseId: clean.exerciseId,
        angle: clean.angle,
        source: clean.source,
        notes: '',
        expectedReps: 10,
        frames: clean.frames,
      );
      final report = runFixtures([mislabelled]);

      expect(report.expectedReps, 10);
      expect(report.countedReps, 8);
      expect(report.repAccuracy, closeTo(0.8, 1e-9));
      expect(report.failures, hasLength(1));
    });

    test('never mixes synthetic results into a claim about real footage', () {
      final report = runFixtures(syntheticSuite());

      expect(report.recorded, isEmpty);
      expect(report.covered, {
        'bodyweight_squat',
        'db_shoulder_press',
        'push_up',
        'plank',
        'db_romanian_deadlift',
        'glute_bridge',
        'db_bent_over_row',
      });
      // Two of the nine camera exercises have no fixture at all, and the
      // report says so rather than averaging over the seven that do. The
      // lunge is one of them on purpose: a side-on generator mirrors one
      // leg chain, and a lunge is the one launch movement whose two legs do
      // different things.
      expect(report.uncovered, {'forward_lunge', 'goblet_squat'});
    });

    test('counts coverage against the catalog, not against itself', () {
      final catalog = ExerciseCatalog(standardExercises);
      final report = runFixtures(syntheticSuite());

      expect(
        report.cameraExercises,
        catalog.all
            .where((exercise) => exercise.camera != null)
            .map((exercise) => exercise.id)
            .toSet(),
      );
    });
  });

  group('replay and the form rules', () {
    /// The same frames, labelled with a different set of faults.
    PoseFixture labelled(String name, Set<String> faults) {
      final clean = _named(name);
      return PoseFixture(
        name: '${name}_relabelled',
        exerciseId: clean.exerciseId,
        angle: clean.angle,
        source: clean.source,
        notes: clean.notes,
        expectedReps: clean.expectedReps,
        expectedHold: clean.expectedHold,
        expectedFaults: faults,
        frames: clean.frames,
      );
    }

    test('a clean set fires nothing and scores full marks', () {
      final result = replay(_named('squat_clean_8'));

      expect(result.review.firings, isEmpty);
      expect(result.review.formScore, 100);
      expect(result.faultsRight, isTrue);
    });

    test('the fault a fixture was built around fires on every rep', () {
      final result = replay(_named('squat_rounded_6'));

      expect(result.review.firings['back_rounding'], 6);
      expect(result.review.worst, RuleSeverity.unsafe);
      expect(result.review.formScore!, lessThan(70));
    });

    test('a labelled fault that does not fire is a failure', () {
      // The direction people remember: a rule that misses the fault it was
      // written for.
      final result = replay(labelled('squat_clean_8', {'back_rounding'}));

      expect(result.countedRight, isTrue);
      expect(result.faultsRight, isFalse);
      expect(result.missedFaults, {'back_rounding'});
      expect(result.passed, isFalse);
    });

    test('a fault that fires and was not labelled is a failure too', () {
      // The direction that matters more. A rule that fires on a fixture
      // nothing is wrong with will fire on every set anybody performs, and
      // the user cannot tell a coach that is always wrong from a coach that
      // is never listening.
      final result = replay(labelled('squat_rounded_6', const {}));

      expect(result.faultsRight, isFalse);
      expect(result.unexpectedFaults, {'back_rounding'});
    });

    test('a rule the camera angle cannot see is not scored against', () {
      final result = replay(_named('squat_clean_8'));

      expect(result.review.neverChecked, contains('knee_valgus'));
      expect(result.review.formScore, 100);
    });

    test('a hold keeps the fault after the posture comes back', () {
      final result = replay(_named('plank_broken_20s'));

      expect(result.review.firings, contains('hip_sag'));
      expect(result.review.formScore!, lessThan(100));
    });

    test('a sag and a pike are told apart', () {
      // Identical hip angles, opposite sides of the line between the
      // shoulder and the knee. Nothing else in the engine can separate
      // them.
      expect(
        replay(_named('plank_broken_20s')).review.firings.keys,
        ['hip_sag'],
      );
      expect(
        replay(_named('plank_piked_20s')).review.firings.keys,
        ['hip_pike'],
      );
    });
  });

  group('rule coverage', () {
    final report = runFixtures(syntheticSuite());

    test('names the rules no fixture is built to trip', () {
      // The rule-level equivalent of an uncovered exercise. Both of these
      // belong to the lunge, which the generator cannot pose.
      expect(report.rulesUnexercised, {'lunge_depth', 'torso_lean'});
    });

    test('names the rules the engine does not evaluate at all', () {
      expect(report.rulesPending.keys, {
        'knee_valgus',
        'elbow_flare',
        'elbow_path',
        'knee_travel',
      });
      for (final reason in report.rulesPending.values) {
        expect(reason, isNotEmpty);
      }
    });

    test('a pending rule is never counted as exercised', () {
      expect(
        report.rulesExercised.intersection(report.rulesPending.keys.toSet()),
        isEmpty,
      );
    });

    test('every labelled fault in the suite fires', () {
      expect(report.faultDetection, 1);
      expect(report.faultFailures, isEmpty);
    });
  });

  group('what the coach would have said', () {
    test('a clean set is coached in silence', () {
      expect(replay(_named('squat_clean_8')).cues, isEmpty);
      expect(replay(_named('plank_30s')).cues, isEmpty);
    });

    test('a repeated fault is said out loud, and not on every rep', () {
      final result = replay(_named('squat_shallow_6'));

      expect(result.cues, isNotEmpty);
      expect(result.cues.length, lessThan(result.countedReps!));
    });

    test('the one thing that stops a set is said more than once', () {
      final rounding = replay(_named('hinge_rounded_6'));

      expect(
        rounding.cues.whereType<RuleCue>().map((cue) => cue.ruleId).toSet(),
        {'back_rounding'},
      );
      expect(rounding.cues.length, greaterThan(1));
    });

    test('the run reports how much talking it did', () {
      final report = runFixtures(syntheticSuite());

      expect(report.cues, greaterThan(0));
      // Seconds of movement per thing said. Not gated on: what counts as
      // too much talking is a judgement about a person.
      expect(report.secondsPerCue, greaterThan(5));
    });
  });
}
