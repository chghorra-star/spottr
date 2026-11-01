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
      });
      // Five of the nine camera exercises have no fixture at all, and the
      // report says so rather than averaging over the four that do.
      expect(report.uncovered, isNotEmpty);
      expect(
        report.uncovered,
        containsAll(['glute_bridge', 'db_romanian_deadlift', 'forward_lunge']),
      );
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
}
