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
    required this.review,
    required this.framesSeen,
    required this.framesTracked,
    this.countedReps,
    this.held,
  });

  final PoseFixture fixture;

  /// Everything the engine concluded: every attempt, what fired on it, and
  /// the form score the progression table would read.
  ///
  /// This is the part worth reading when a fixture disagrees. A set reported
  /// as 6 of 8 with two `partialRange` entries is a different problem from
  /// one reported as 6 with no entries at all, and a clean set that fired
  /// `back_rounding` is a different problem again.
  final SetReview review;

  final int framesSeen;

  /// Frames the counter could measure its signal in. The gap between this
  /// and [framesSeen] is tracking dropout.
  final int framesTracked;

  /// `null` for a hold.
  final int? countedReps;

  /// `null` for a rep count.
  final Duration? held;

  /// Every attempt the counter saw, counted or not.
  List<RepEvent> get ledger => [for (final rep in review.reps) rep.event];

  int get attempts => ledger.length;

  /// Reps counted minus reps expected: positive means it over-counted.
  int get repError => (countedReps ?? 0) - (fixture.expectedReps ?? 0);

  Duration get holdError =>
      (held ?? Duration.zero) - (fixture.expectedHold ?? Duration.zero);

  /// Whether the count or the clock agrees with the label.
  bool get countedRight => fixture.isHold
      ? holdError.abs() <= holdTolerance(fixture.expectedHold!)
      : repError == 0;

  /// Rules the label says should have fired and did not.
  Set<String> get missedFaults =>
      fixture.expectedFaults.difference(review.firings.keys.toSet());

  /// Rules that fired and were not in the label.
  ///
  /// As much of a failure as a missed one, and on generated movement more
  /// so: a rule that fires on a clean fixture is a rule that will fire on
  /// every set somebody ever performs.
  Set<String> get unexpectedFaults =>
      review.firings.keys.toSet().difference(fixture.expectedFaults);

  bool get faultsRight => missedFaults.isEmpty && unexpectedFaults.isEmpty;

  bool get passed => countedRight && faultsRight;

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
        'countedRight': countedRight,
        'faultsRight': faultsRight,
        'passed': passed,
        'attempts': ledger.length,
        'framesSeen': framesSeen,
        'framesTracked': framesTracked,
        'formScore': review.formScore,
        'expectedFaults': fixture.expectedFaults.toList()..sort(),
        'firings': review.firings,
        'missedFaults': missedFaults.toList()..sort(),
        'unexpectedFaults': unexpectedFaults.toList()..sort(),
        'neverChecked': review.neverChecked.toList()..sort(),
        'repFaults': <String, int>{
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
/// **The same smoothing the app applies runs here too**, and the same
/// analyzer: counter, rules and scoring, in one object, because a
/// measurement taken on a different pipeline than the one that ships is a
/// measurement of something that does not ship. Pass `smooth: false` only to
/// see what the filter is contributing.
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
  // The fixture's own angle, not the recommended one: a fixture recorded
  // from the front is not a counter-example for a rule that needs the side,
  // and the analyzer is what knows the difference.
  final analyzer = FormAnalyzer(exercise: exercise, angle: fixture.angle);
  var tracked = 0;

  for (final raw in fixture.frames) {
    final frame = smooth ? smoother.apply(raw) : raw;
    final tick = analyzer.update(frame);
    if (tick.counter.tracking) tracked++;
  }

  final counter = analyzer.tick.counter;

  return FixtureResult(
    fixture: fixture,
    review: analyzer.tick.review,
    framesSeen: fixture.frames.length,
    framesTracked: tracked,
    countedReps: counter is RepTick ? counter.counted : null,
    held: counter is HoldTick ? counter.held : null,
  );
}

/// The result of a whole suite.
@immutable
class HarnessReport {
  const HarnessReport({
    required this.results,
    required this.cameraExercises,
    required this.rules,
  });

  final List<FixtureResult> results;

  /// Every exercise the app offers to coach, which is what coverage is
  /// measured against — never against the fixtures that happen to exist.
  final Set<String> cameraExercises;

  /// Every form rule in the engine, by id, so coverage can be measured
  /// against the rules that exist rather than the ones a fixture happens to
  /// trip.
  final Map<String, FormRule> rules;

  List<FixtureResult> get failures =>
      [for (final result in results) if (!result.passed) result];

  /// Fixtures whose count or clock disagreed with the label.
  List<FixtureResult> get countFailures =>
      [for (final result in results) if (!result.countedRight) result];

  /// Fixtures where a rule fired that should not have, or did not fire when
  /// it should.
  List<FixtureResult> get faultFailures =>
      [for (final result in results) if (!result.faultsRight) result];

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

  Iterable<FixtureResult> _reps(FixtureSource? source) =>
      repResults.where((r) => source == null || r.fixture.source == source);

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

  /// Rules a fixture in this run was labelled to demonstrate.
  Set<String> get rulesExercised => {
        for (final result in results) ...result.fixture.expectedFaults,
      };

  /// Rules the engine evaluates and no fixture demonstrates.
  ///
  /// The rule-level equivalent of an uncovered exercise, and the honest
  /// answer to "does the form engine work": it works on the rules something
  /// has been built to trip.
  Set<String> get rulesUnexercised => {
        for (final entry in rules.entries)
          if (entry.value is! PendingRule &&
              !rulesExercised.contains(entry.key))
            entry.key,
      };

  /// Rules named by the catalog that the engine does not evaluate at all.
  Map<String, String> get rulesPending => {
        for (final entry in rules.entries)
          if (entry.value case final PendingRule rule) entry.key: rule.reason,
      };

  /// Expected faults that fired, over expected faults labelled.
  double get faultDetection {
    final labelled = results.fold<int>(
      0,
      (sum, r) => sum + r.fixture.expectedFaults.length,
    );
    if (labelled == 0) return 1;
    final missed =
        results.fold<int>(0, (sum, r) => sum + r.missedFaults.length);
    return (1 - missed / labelled).clamp(0.0, 1.0);
  }

  /// Every rule that fired anywhere in the run, and how often.
  Map<String, int> get firings {
    final counts = <String, int>{};
    for (final result in results) {
      result.review.firings.forEach((id, times) {
        counts[id] = (counts[id] ?? 0) + times;
      });
    }
    return counts;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'fixtures': results.length,
        'passed': results.length - failures.length,
        'repAccuracy': repAccuracy,
        'expectedReps': expectedReps,
        'countedReps': countedReps,
        'repError': repError,
        'faultDetection': faultDetection,
        'firings': firings,
        'coverage': <String, Object?>{
          'cameraExercises': cameraExercises.length,
          'covered': covered.toList()..sort(),
          'recorded': recorded.toList()..sort(),
          'uncovered': uncovered.toList()..sort(),
          'rules': rules.length,
          'rulesExercised': rulesExercised.toList()..sort(),
          'rulesUnexercised': rulesUnexercised.toList()..sort(),
          'rulesPending': rulesPending.keys.toList()..sort(),
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
    cameraExercises: {
      for (final exercise in library.cameraSupported) exercise.id,
    },
    rules: formCatalog,
  );
}
