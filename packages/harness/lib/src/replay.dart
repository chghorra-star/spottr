import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'fixture.dart';

/// How far a hold may be out before it counts as wrong.
///
/// A clock that starts on the second valid frame is always one frame short,
/// and a human labelling footage is not accurate to the frame either. Two
/// per cent plus a tenth of a second is wide enough for both and far too
/// narrow to hide a hold that paused when it should not have.
Duration holdTolerance(Duration expected) =>
    Duration(milliseconds: 100 + (expected.inMilliseconds * 0.02).round());

/// What the engine made of one fixture.
@immutable
class FixtureResult {
  const FixtureResult({
    required this.fixture,
    required this.ledger,
    required this.framesSeen,
    required this.framesTracked,
    this.countedReps,
    this.attempts = 0,
    this.held,
  });

  final PoseFixture fixture;

  /// Every attempt the counter saw, counted or not. This is the part worth
  /// reading when a fixture disagrees: a set reported as 6 of 8 with two
  /// `partialRange` entries is a different problem from one reported as 6
  /// with no entries at all.
  final List<RepEvent> ledger;

  final int framesSeen;

  /// Frames the counter could measure its signal in. The gap between this
  /// and [framesSeen] is tracking dropout.
  final int framesTracked;

  /// `null` for a hold.
  final int? countedReps;

  final int attempts;

  /// `null` for a rep count.
  final Duration? held;

  /// Reps counted minus reps expected: positive means it over-counted.
  int get repError => (countedReps ?? 0) - (fixture.expectedReps ?? 0);

  Duration get holdError =>
      (held ?? Duration.zero) - (fixture.expectedHold ?? Duration.zero);

  bool get passed => fixture.isHold
      ? holdError.abs() <= holdTolerance(fixture.expectedHold!)
      : repError == 0;

  /// What the fixture asked for, as a string for the report.
  String get expectation => fixture.isHold
      ? '${_seconds(fixture.expectedHold!)}s'
      : '${fixture.expectedReps}';

  /// What the engine produced.
  String get actual =>
      fixture.isHold ? '${_seconds(held ?? Duration.zero)}s' : '$countedReps';

  Map<String, Object?> toJson() => <String, Object?>{
        'name': fixture.name,
        'exerciseId': fixture.exerciseId,
        'angle': fixture.angle.name,
        'source': fixture.source.name,
        'expected': expectation,
        'actual': actual,
        'passed': passed,
        'attempts': attempts,
        'framesSeen': framesSeen,
        'framesTracked': framesTracked,
        'faults': <String, int>{
          for (final event in ledger)
            if (event.fault != null)
              event.fault!.name:
                  ledger.where((e) => e.fault == event.fault).length,
        },
      };
}

String _seconds(Duration value) =>
    (value.inMilliseconds / 1000).toStringAsFixed(1);

/// Replays one fixture through the real pipeline.
///
/// **The same smoothing the app applies runs here too**, which is not a
/// nicety: a measurement taken on a different pipeline than the one that
/// ships is a measurement of something that does not ship. Pass
/// `smooth: false` only to see what the filter is contributing.
FixtureResult replay(
  PoseFixture fixture, {
  ExerciseCatalog? catalog,
  bool smooth = true,
}) {
  final library = catalog ?? ExerciseCatalog(standardExercises);
  final exercise = library[fixture.exerciseId];
  if (exercise == null) {
    throw ArgumentError.value(
      fixture.exerciseId,
      'exerciseId',
      'fixture "${fixture.name}" names an exercise that is not in the catalog',
    );
  }

  final config = counterFor(exercise);
  if (config == null) {
    throw ArgumentError.value(
      fixture.exerciseId,
      'exerciseId',
      'fixture "${fixture.name}" names an exercise the camera does not coach',
    );
  }

  if (fixture.isHold != config is HoldCounterConfig) {
    throw ArgumentError.value(
      fixture.name,
      'fixture',
      'expects ${fixture.isHold ? 'a hold' : 'reps'} but '
          '${fixture.exerciseId} is counted by a '
          '${config is HoldCounterConfig ? 'hold' : 'rep'} counter',
    );
  }

  final smoother = PoseSmoother();
  final counter = SetCounter.of(config);
  final ledger = <RepEvent>[];
  var tracked = 0;

  for (final raw in fixture.frames) {
    final frame = smooth ? smoother.apply(raw) : raw;
    final tick = counter.update(frame);
    if (tick.tracking) tracked++;
    if (tick is RepTick && tick.completed != null) ledger.add(tick.completed!);
  }

  return FixtureResult(
    fixture: fixture,
    ledger: ledger,
    framesSeen: fixture.frames.length,
    framesTracked: tracked,
    countedReps: counter is RepCounter ? counter.counted : null,
    attempts: ledger.length,
    held: counter is HoldCounter ? counter.held : null,
  );
}

/// The result of a whole suite.
@immutable
class HarnessReport {
  const HarnessReport({required this.results, required this.cameraExercises});

  final List<FixtureResult> results;

  /// Every exercise the app offers to coach, which is what coverage is
  /// measured against — never against the fixtures that happen to exist.
  final Set<String> cameraExercises;

  List<FixtureResult> get failures =>
      [for (final result in results) if (!result.passed) result];

  Iterable<FixtureResult> get repResults =>
      results.where((result) => !result.fixture.isHold);

  Iterable<FixtureResult> get holdResults =>
      results.where((result) => result.fixture.isHold);

  int get expectedReps => expectedRepsIn(null);

  int get countedReps => countedRepsIn(null);

  /// Total absolute miscount across every rep fixture.
  int get repError => repErrorIn(null);

  /// Reps counted correctly as a fraction of reps expected.
  ///
  /// Absolute error, so an over-count is as bad as an under-count: a counter
  /// that invents two reps and misses two is not accurate.
  double get repAccuracy => accuracy();

  /// The same, restricted to one kind of fixture.
  ///
  /// The restriction is the point. Synthetic and recorded fixtures measure
  /// different things, so one number over both would be an average of a
  /// self-consistency check and an accuracy measurement — which is not an
  /// accuracy measurement.
  double accuracy({FixtureSource? source}) {
    final expected = expectedRepsIn(source);
    if (expected == 0) return 1;
    return (1 - repErrorIn(source) / expected).clamp(0.0, 1.0);
  }

  Iterable<FixtureResult> _reps(FixtureSource? source) => repResults
      .where((r) => source == null || r.fixture.source == source);

  int expectedRepsIn(FixtureSource? source) =>
      _reps(source).fold(0, (sum, r) => sum + (r.fixture.expectedReps ?? 0));

  int countedRepsIn(FixtureSource? source) =>
      _reps(source).fold(0, (sum, r) => sum + (r.countedReps ?? 0));

  int repErrorIn(FixtureSource? source) =>
      _reps(source).fold(0, (sum, r) => sum + r.repError.abs());

  /// Exercises with any fixture at all.
  Set<String> get covered =>
      {for (final result in results) result.fixture.exerciseId};

  /// Exercises with footage of a real body.
  Set<String> get recorded => {
        for (final result in results)
          if (result.fixture.source == FixtureSource.recorded)
            result.fixture.exerciseId,
      };

  /// Exercises the app will coach and nothing has ever been measured on.
  Set<String> get uncovered => cameraExercises.difference(covered);

  Map<String, Object?> toJson() => <String, Object?>{
        'fixtures': results.length,
        'passed': results.length - failures.length,
        'repAccuracy': repAccuracy,
        'expectedReps': expectedReps,
        'countedReps': countedReps,
        'repError': repError,
        'coverage': <String, Object?>{
          'cameraExercises': cameraExercises.length,
          'covered': covered.toList()..sort(),
          'recorded': recorded.toList()..sort(),
          'uncovered': uncovered.toList()..sort(),
        },
        'results': [for (final result in results) result.toJson()],
      };
}

/// Replays every fixture and collects the results.
HarnessReport runFixtures(
  Iterable<PoseFixture> fixtures, {
  ExerciseCatalog? catalog,
  bool smooth = true,
}) {
  final library = catalog ?? ExerciseCatalog(standardExercises);

  return HarnessReport(
    results: [
      for (final fixture in fixtures)
        replay(fixture, catalog: library, smooth: smooth),
    ],
    cameraExercises: {for (final exercise in library.cameraSupported) exercise.id},
  );
}
