import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'counter_config.dart';
import 'pose_signal.dart';

// ---------------------------------------------------------------------------
// The signals the launch counters watch.
// ---------------------------------------------------------------------------

/// Hip, knee, ankle. A squat and a lunge.
const kneeAngle = JointAngle(
  from: Joint.leftHip,
  vertex: Joint.leftKnee,
  to: Joint.leftAnkle,
);

/// Shoulder, elbow, wrist. A push-up, a press, a row.
const elbowAngle = JointAngle(
  from: Joint.leftShoulder,
  vertex: Joint.leftElbow,
  to: Joint.leftWrist,
);

/// Shoulder, hip, knee. A hinge, a bridge, and the straightness of a plank.
const hipAngle = JointAngle(
  from: Joint.leftShoulder,
  vertex: Joint.leftHip,
  to: Joint.leftKnee,
);

/// Shoulder to hip, measured from vertical. 180 is upright, 90 is lying down.
const trunkTilt = SegmentTilt(from: Joint.leftShoulder, to: Joint.leftHip);

// ---------------------------------------------------------------------------
// The counters.
//
// Every number below is a starting point, not a measurement. They are
// anatomically plausible and they are internally consistent — the validator
// and the state-machine tests see to that — but nothing here has been tuned
// against footage of anybody actually training. M8 does that, per exercise,
// and `docs/dev-loop.md` says what the accuracy targets can honestly claim
// until then.
//
// Thresholds are configuration precisely so that tuning them is a data edit
// in this one table rather than a change to the machine that reads it.
// ---------------------------------------------------------------------------

const _squat = RepCounterConfig(
  id: 'squat_knee_angle',
  signal: kneeAngle,
  direction: RepDirection.closing,
  topThreshold: 160,
  bottomThreshold: 100,
  minRangeOfMotion: 40,
);

const _pushUp = RepCounterConfig(
  id: 'pushup_elbow_angle',
  signal: elbowAngle,
  direction: RepDirection.closing,
  topThreshold: 160,
  bottomThreshold: 100,
  minRangeOfMotion: 40,
);

const _lunge = RepCounterConfig(
  id: 'lunge_knee_angle',
  signal: kneeAngle,
  direction: RepDirection.closing,
  topThreshold: 160,
  bottomThreshold: 105,
  minRangeOfMotion: 40,
);

/// A bridge works the other way round: the hip angle *opens* as the hips come
/// up, and the rep starts and ends flat on the floor.
const _bridge = RepCounterConfig(
  id: 'bridge_hip_angle',
  signal: hipAngle,
  direction: RepDirection.opening,
  topThreshold: 120,
  bottomThreshold: 165,
  minRangeOfMotion: 25,
);

const _hinge = RepCounterConfig(
  id: 'hinge_hip_angle',
  signal: hipAngle,
  direction: RepDirection.closing,
  topThreshold: 160,
  bottomThreshold: 110,
  minRangeOfMotion: 35,
);

/// A press also opens: the rep starts racked at the shoulders with the elbow
/// bent, and the far end of the movement is the lockout overhead.
const _press = RepCounterConfig(
  id: 'press_elbow_angle',
  signal: elbowAngle,
  direction: RepDirection.opening,
  topThreshold: 95,
  bottomThreshold: 165,
  minRangeOfMotion: 45,
);

const _row = RepCounterConfig(
  id: 'row_elbow_angle',
  signal: elbowAngle,
  direction: RepDirection.closing,
  topThreshold: 155,
  bottomThreshold: 95,
  minRangeOfMotion: 40,
);

/// A plank needs both bands. The hip angle alone is just as true of somebody
/// standing still reading their phone.
const _plank = HoldCounterConfig(
  id: 'plank_hold',
  bands: [
    SignalBand(signal: hipAngle, min: 155),
    SignalBand(signal: trunkTilt, min: 55, max: 125),
  ],
);

/// Every counter the app can run, by the id a catalog entry refers to.
const Map<String, CounterConfig> counterCatalog = {
  'squat_knee_angle': _squat,
  'pushup_elbow_angle': _pushUp,
  'lunge_knee_angle': _lunge,
  'bridge_hip_angle': _bridge,
  'hinge_hip_angle': _hinge,
  'press_elbow_angle': _press,
  'row_elbow_angle': _row,
  'plank_hold': _plank,
};

/// The counter for [exercise], or `null` when the camera does not coach it.
CounterConfig? counterFor(Exercise exercise) {
  final camera = exercise.camera;
  if (camera == null) return null;
  return counterCatalog[camera.repCounterId];
}

/// What can be wrong with a counter configuration.
enum CounterProblemKind {
  /// A camera-supported exercise names a counter that does not exist.
  missingCounter,

  /// A counter no exercise refers to.
  unreferenced,

  /// The entry is filed under a key that is not its own id.
  idMismatch,

  /// The thresholds run the opposite way to the declared direction, so depth
  /// is negative throughout the movement and nothing ever counts.
  backwardsThresholds,

  /// The acceptance bar is further than the movement itself travels, so
  /// every rep is rejected as partial.
  unreachableRange,

  /// The acceptance bar is inside the tolerance band, so landmark noise can
  /// count as a repetition.
  rangeBelowHysteresis,

  /// The shortest acceptable rep is longer than the longest.
  backwardsDurations,

  /// A hold with no bands, which holds everything.
  noBands,

  /// A band whose minimum is above its maximum, which holds nothing.
  emptyBand,
}

/// One defect in the counter table.
@immutable
class CounterProblem {
  const CounterProblem(this.counterId, this.kind, this.detail);

  final String counterId;
  final CounterProblemKind kind;

  /// Actionable specifics, because this is read in a test failure.
  final String detail;

  @override
  String toString() => '[$counterId] ${kind.name}: $detail';
}

/// Every defect in [counters] as used by [catalog]. Empty is the shipping
/// condition, asserted by `counter_catalog_test.dart`.
///
/// None of this can be checked at the point of use: a counter whose
/// thresholds run backwards opens a camera, draws a skeleton and counts
/// nothing for ever, which looks exactly like a model that cannot see the
/// user. The table is small and the arithmetic is decidable, so it is
/// checked once here instead.
List<CounterProblem> validateCounters(
  ExerciseCatalog catalog, {
  Map<String, CounterConfig> counters = counterCatalog,
}) {
  final problems = <CounterProblem>[];
  final referenced = <String>{};

  for (final exercise in catalog.all) {
    final camera = exercise.camera;
    if (camera == null) continue;
    referenced.add(camera.repCounterId);
    if (!counters.containsKey(camera.repCounterId)) {
      problems.add(
        CounterProblem(
          camera.repCounterId,
          CounterProblemKind.missingCounter,
          'referred to by ${exercise.id} and not in the table',
        ),
      );
    }
  }

  for (final entry in counters.entries) {
    final config = entry.value;
    final id = config.id;

    if (entry.key != id) {
      problems.add(
        CounterProblem(
          entry.key,
          CounterProblemKind.idMismatch,
          'filed under "${entry.key}" but calls itself "$id"',
        ),
      );
    }

    if (!referenced.contains(entry.key)) {
      problems.add(
        CounterProblem(
          entry.key,
          CounterProblemKind.unreferenced,
          'no exercise in the catalog uses it',
        ),
      );
    }

    switch (config) {
      case RepCounterConfig():
        final opens = config.direction == RepDirection.opening;
        final ordered = opens
            ? config.bottomThreshold > config.topThreshold
            : config.bottomThreshold < config.topThreshold;
        if (!ordered) {
          problems.add(
            CounterProblem(
              id,
              CounterProblemKind.backwardsThresholds,
              'direction is ${config.direction.name} but the thresholds run '
              '${config.topThreshold} to ${config.bottomThreshold}',
            ),
          );
        }
        if (config.minRangeOfMotion > config.fullRange) {
          problems.add(
            CounterProblem(
              id,
              CounterProblemKind.unreachableRange,
              'needs ${config.minRangeOfMotion} degrees of travel in a '
              '${config.fullRange} degree movement',
            ),
          );
        }
        if (config.minRangeOfMotion <= config.hysteresis) {
          problems.add(
            CounterProblem(
              id,
              CounterProblemKind.rangeBelowHysteresis,
              'accepts ${config.minRangeOfMotion} degrees of travel inside a '
              '${config.hysteresis} degree tolerance',
            ),
          );
        }
        if (config.minRepDuration >= config.maxRepDuration) {
          problems.add(
            CounterProblem(
              id,
              CounterProblemKind.backwardsDurations,
              'shortest rep ${config.minRepDuration} is not shorter than the '
              'longest ${config.maxRepDuration}',
            ),
          );
        }
      case HoldCounterConfig():
        if (config.bands.isEmpty) {
          problems.add(
            CounterProblem(
              id,
              CounterProblemKind.noBands,
              'a hold with no bands accumulates in any posture',
            ),
          );
        }
        for (final band in config.bands) {
          final min = band.min;
          final max = band.max;
          if (min != null && max != null && min > max) {
            problems.add(
              CounterProblem(
                id,
                CounterProblemKind.emptyBand,
                'a band from $min to $max can never be satisfied',
              ),
            );
          }
        }
    }
  }

  return problems;
}
