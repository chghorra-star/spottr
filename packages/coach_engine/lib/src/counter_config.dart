import 'package:meta/meta.dart';

import 'pose_signal.dart';

/// Default tolerance around a threshold, in degrees.
///
/// Wide enough that landmark noise at the top of a rep cannot chatter the
/// state machine, narrow enough that it does not eat a real movement.
const double defaultHysteresis = 8;

/// How long a tracked signal may go missing before the attempt in progress
/// is abandoned.
///
/// The same 400ms the smoothing filter resets after, and for the same
/// reason: past that, whatever comes back is a new reading rather than a
/// continuation of the old one.
const Duration defaultTrackingGap = Duration(milliseconds: 400);

/// What drives the counter for one exercise.
///
/// Configuration, not code: tuning a squat is a data edit and adding a ninth
/// camera exercise is a new entry in `counterCatalog`. The two shapes are a
/// repetition and a hold, because a plank is not a rep count with the
/// numbers changed.
@immutable
sealed class CounterConfig {
  const CounterConfig();

  /// Matches `CameraSupport.repCounterId` in the exercise catalog.
  String get id;

  /// Every joint any of its signals reads.
  Set<PoseSignal> get signals;
}

/// Which way the measured angle moves as the working phase is performed.
enum RepDirection {
  /// The angle gets smaller: a squat's knee, a push-up's elbow, a hinge's
  /// hip.
  closing,

  /// The angle gets larger: a glute bridge's hip, a shoulder press's elbow.
  opening,
}

/// A repetition counter: one angle, two ends, and the tolerances that decide
/// what counts.
final class RepCounterConfig extends CounterConfig {
  const RepCounterConfig({
    required this.id,
    required this.signal,
    required this.direction,
    required this.topThreshold,
    required this.bottomThreshold,
    required this.minRangeOfMotion,
    this.hysteresis = defaultHysteresis,
    this.minRepDuration = const Duration(milliseconds: 600),
    this.maxRepDuration = const Duration(seconds: 12),
    this.maxTrackingGap = defaultTrackingGap,
  });

  @override
  final String id;

  /// The one angle this counter watches.
  final PoseSignal signal;

  final RepDirection direction;

  /// The signal where a rep starts and ends — standing up, arms locked out,
  /// lying flat. Crossing away from it by more than [hysteresis] opens an
  /// attempt; coming back to it closes one.
  final double topThreshold;

  /// The signal at the far end of the movement. Reaching it is full depth;
  /// falling short of it is a shallow rep, which still counts.
  final double bottomThreshold;

  /// How far the signal must actually travel for the attempt to count, in
  /// degrees.
  ///
  /// Measured from where the user started, not from [topThreshold], so
  /// somebody who never quite stands up straight between reps is judged on
  /// what they moved rather than on where they began.
  final double minRangeOfMotion;

  final double hysteresis;

  /// Below this, the attempt is not a rep: a bounce, or the tracker jumping.
  final Duration minRepDuration;

  /// Above this, the attempt is abandoned. Somebody who stops half way
  /// through and walks off should not have a rep land minutes later.
  final Duration maxRepDuration;

  final Duration maxTrackingGap;

  @override
  Set<PoseSignal> get signals => {signal};

  /// Degrees between the two ends of the movement.
  double get fullRange => (bottomThreshold - topThreshold).abs();

  /// How far into the rep [value] is: 0 at the top, [fullRange] at the
  /// bottom, negative when the user is further back than the top threshold.
  ///
  /// This is the whole of what [direction] means. Everything above it works
  /// in depth, so the state machine has one direction rather than two.
  double depth(double value) => switch (direction) {
        RepDirection.closing => topThreshold - value,
        RepDirection.opening => value - topThreshold,
      };

  /// The raw signal at a given depth. The inverse of [depth], for reporting
  /// a peak back in the units the user would recognise.
  double angleAtDepth(double value) => switch (direction) {
        RepDirection.closing => topThreshold - value,
        RepDirection.opening => topThreshold + value,
      };
}

/// One signal and the range it has to stay inside.
///
/// Open ended on either side: a plank's hip angle has a floor and no
/// ceiling, because an unsigned joint angle cannot exceed 180 in the first
/// place.
@immutable
class SignalBand {
  const SignalBand({required this.signal, this.min, this.max})
      : assert(min != null || max != null, 'a band bounded on neither side');

  final PoseSignal signal;
  final double? min;
  final double? max;

  bool contains(double value) =>
      (min == null || value >= min!) && (max == null || value <= max!);
}

/// A hold counter: time accumulated in a posture, for a plank or any other
/// position worth staying in.
final class HoldCounterConfig extends CounterConfig {
  const HoldCounterConfig({
    required this.id,
    required this.bands,
    this.maxTrackingGap = defaultTrackingGap,
  });

  @override
  final String id;

  /// Every band has to be satisfied for the clock to run. A hold with no
  /// bands would hold everything, which `counter_catalog_test` rules out —
  /// a const constructor cannot check a list for itself.
  ///
  /// A plank needs two: the hips in line with shoulders and knees, and the
  /// trunk horizontal. The first alone is also true of somebody standing
  /// still.
  final List<SignalBand> bands;

  final Duration maxTrackingGap;

  @override
  Set<PoseSignal> get signals => {for (final band in bands) band.signal};
}
