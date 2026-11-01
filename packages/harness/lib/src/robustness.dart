import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'fixture.dart';
import 'replay.dart';
import 'synthetic.dart';

/// Landmark noise, in normalized image units, applied to every joint of
/// every frame.
///
/// The ladder reaches well past anything plausible on purpose: the question
/// is not whether the engine survives the noise a fixture was built with,
/// it is where it stops surviving.
const List<double> jitterLadder = [
  0,
  0.004,
  0.008,
  0.016,
  0.032,
  0.048,
  0.064,
  0.096,
  0.128,
];

/// Frame intervals, in milliseconds. 33 is the 30fps the camera layer asks
/// the device for; 200 is five frames a second, which is what a cheap phone
/// does while it is also doing something else.
const List<int> frameIntervalLadder = [
  33,
  50,
  66,
  100,
  150,
  200,
  300,
  500,
  750,
  1000,
];

/// One run of one set at one setting.
@immutable
class RobustnessPoint {
  const RobustnessPoint({
    required this.setting,
    required this.counted,
    required this.expected,
    required this.passed,
  });

  final double setting;
  final int counted;
  final int expected;
  final bool passed;

  @override
  String toString() =>
      '$setting: $counted of $expected${passed ? '' : ' (wrong)'}';
}

/// How far one set can be degraded before the engine gets it wrong.
@immutable
class RobustnessSweep {
  const RobustnessSweep({
    required this.name,
    required this.parameter,
    required this.unit,
    required this.points,
  });

  final String name;

  /// What was varied: 'jitter' or 'frameInterval'.
  final String parameter;
  final String unit;
  final List<RobustnessPoint> points;

  /// The worst setting the engine still counted correctly at, taking the
  /// settings in order and stopping at the first failure.
  ///
  /// In order, and stopping: an engine that counts correctly at 0.024 after
  /// getting it wrong at 0.016 has not earned 0.024, it has got lucky.
  double? get limit {
    double? best;
    for (final point in points) {
      if (!point.passed) break;
      best = point.setting;
    }
    return best;
  }

  /// Whether it survived everything the ladder had.
  bool get unbroken => limit == points.last.setting;

  @override
  String toString() => '$name $parameter limit ${limit ?? 'none'}$unit';
}

/// The clean sets the sweeps degrade.
///
/// Built here rather than taken from [syntheticSuite] because a sweep needs
/// the same movement generated again at a different setting, and a fixture
/// is frames by the time the suite hands it over.
Map<String,
        PoseFixture Function({
          double jitter,
          double drift,
          Duration frameInterval,
        })> cleanSets() => {
          'squat': ({jitter = 0, drift = 0, frameInterval = defaultFrameInterval}) =>
              syntheticReps(
                name: 'robust_squat',
                exerciseId: 'bodyweight_squat',
                top: squatTop,
                bottom: squatBottom,
                reps: List.filled(8, const SyntheticRep()),
                expectedReps: 8,
                jitter: jitter,
                drift: drift,
                frameInterval: frameInterval,
                random: math.Random(11),
              ),
          'push_up': ({jitter = 0, drift = 0, frameInterval = defaultFrameInterval}) =>
              syntheticReps(
                name: 'robust_pushup',
                exerciseId: 'push_up',
                top: pushUpTop,
                bottom: pushUpBottom,
                reps: List.filled(8, const SyntheticRep()),
                expectedReps: 8,
                jitter: jitter,
                drift: drift,
                frameInterval: frameInterval,
                random: math.Random(11),
              ),
          'press': ({jitter = 0, drift = 0, frameInterval = defaultFrameInterval}) =>
              syntheticReps(
                name: 'robust_press',
                exerciseId: 'db_shoulder_press',
                top: pressRacked,
                bottom: pressLockout,
                reps: List.filled(6, const SyntheticRep()),
                expectedReps: 6,
                jitter: jitter,
                drift: drift,
                frameInterval: frameInterval,
                random: math.Random(11),
              ),
          'hinge': ({jitter = 0, drift = 0, frameInterval = defaultFrameInterval}) =>
              syntheticReps(
                name: 'robust_hinge',
                exerciseId: 'db_romanian_deadlift',
                top: hingeTop,
                bottom: hingeBottom,
                reps: List.filled(8, const SyntheticRep()),
                expectedReps: 8,
                jitter: jitter,
                drift: drift,
                frameInterval: frameInterval,
                random: math.Random(11),
              ),
          'bridge': ({jitter = 0, drift = 0, frameInterval = defaultFrameInterval}) =>
              syntheticReps(
                name: 'robust_bridge',
                exerciseId: 'glute_bridge',
                top: bridgeDown,
                bottom: bridgeUp,
                reps: List.filled(8, const SyntheticRep()),
                expectedReps: 8,
                jitter: jitter,
                drift: drift,
                frameInterval: frameInterval,
                random: math.Random(11),
              ),
          'row': ({jitter = 0, drift = 0, frameInterval = defaultFrameInterval}) =>
              syntheticReps(
                name: 'robust_row',
                exerciseId: 'db_bent_over_row',
                top: rowTop,
                bottom: rowBottom,
                reps: List.filled(8, const SyntheticRep()),
                expectedReps: 8,
                jitter: jitter,
                drift: drift,
                frameInterval: frameInterval,
                random: math.Random(11),
              ),
        };

/// How much landmark noise each clean set survives.
///
/// The closest thing to an accuracy measurement that can be made without
/// footage. Real landmarks jitter; how much they jitter is a property of
/// the model and the lighting, and this says how much headroom the counter
/// has before that jitter starts inventing or losing reps.
List<RobustnessSweep> sweepJitter({List<double> ladder = jitterLadder}) => [
      for (final entry in cleanSets().entries)
        RobustnessSweep(
          name: entry.key,
          parameter: 'jitter',
          unit: '',
          points: [
            for (final jitter in ladder)
              _point(jitter, entry.value(jitter: jitter)),
          ],
        ),
    ];

/// How few frames a second each clean set survives.
///
/// The camera layer asks for thirty. A mid-range phone running a pose model
/// while the screen is on will not always give thirty, and nothing in this
/// project has ever measured what it does give — so the useful question is
/// how far down the engine still works.
List<RobustnessSweep> sweepFrameRate({
  List<int> ladder = frameIntervalLadder,
}) =>
    [
      for (final entry in cleanSets().entries)
        RobustnessSweep(
          name: entry.key,
          parameter: 'frameInterval',
          unit: 'ms',
          points: [
            for (final interval in ladder)
              _point(
                interval.toDouble(),
                entry.value(frameInterval: Duration(milliseconds: interval)),
              ),
          ],
        ),
    ];

RobustnessPoint _point(double setting, PoseFixture fixture) {
  final result = replay(fixture);
  return RobustnessPoint(
    setting: setting,
    counted: result.countedReps ?? 0,
    expected: fixture.expectedReps ?? 0,
    passed: result.countedRight,
  );
}

/// The report, as something a person reads.
String renderRobustness(
  List<RobustnessSweep> jitter,
  List<RobustnessSweep> drift,
  List<RobustnessSweep> frameRate,
) {
  final lines = <String>[
    'How much degradation the counter survives',
    '',
    'Generated movement, degraded on purpose. Still not a measurement of',
    'accuracy on a real body — it is a measurement of headroom, which is a',
    'different thing and the only one available without footage.',
    '',
    'Landmark noise, in normalized image units on every joint of every frame',
  ];

  final width = jitter.map((s) => s.name.length).fold(6, (a, b) => a > b ? a : b);

  for (final sweep in jitter) {
    final limit = sweep.limit;
    lines.add(
      '  ${sweep.name.padRight(width)}  '
      '${limit == null ? 'wrong even clean' : 'correct up to $limit'}'
      '${sweep.unbroken ? ' (the ladder ran out)' : ''}',
    );
  }

  lines.addAll([
    '',
    'Correlated wander: every joint drifting slowly, which is what a tracker',
    'actually does and what a low-pass filter cannot help with',
  ]);
  for (final sweep in drift) {
    final limit = sweep.limit;
    lines.add(
      '  ${sweep.name.padRight(width)}  '
      '${limit == null ? 'wrong even clean' : 'correct up to $limit'}'
      '${sweep.unbroken ? ' (the ladder ran out)' : ''}',
    );
  }

  lines.addAll([
    '',
    'Frame interval, against the 33ms the camera layer asks for',
  ]);
  for (final sweep in frameRate) {
    final limit = sweep.limit;
    lines.add(
      '  ${sweep.name.padRight(width)}  '
      '${limit == null ? 'wrong even at 33ms' : 'correct down to ${limit.round()}ms '
          '(${(1000 / limit).toStringAsFixed(1)}fps)'}'
      '${sweep.unbroken ? ' (the ladder ran out)' : ''}',
    );
  }

  return lines.join('\n');
}

/// Correlated tracker wander, in normalized image units.
///
/// Smaller than the jitter ladder on purpose: a slow wander of a few per
/// cent of the image changes the angle a joint reports for a second at a
/// time, which is a rep's worth, and that is a different problem from noise
/// a filter can average away.
const List<double> driftLadder = [
  0,
  0.004,
  0.008,
  0.012,
  0.016,
  0.024,
  0.032,
  0.048,
];

/// How much slow tracker wander each clean set survives.
List<RobustnessSweep> sweepDrift({List<double> ladder = driftLadder}) => [
      for (final entry in cleanSets().entries)
        RobustnessSweep(
          name: entry.key,
          parameter: 'drift',
          unit: '',
          points: [
            for (final drift in ladder)
              _point(drift, entry.value(drift: drift)),
          ],
        ),
    ];
