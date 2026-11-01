import 'dart:async';
import 'dart:math' as math;

import 'joint.dart';
import 'landmark.dart';
import 'pose_frame.dart';

/// Default cutoff in Hz for a landmark that is not moving.
///
/// Low, because a stationary ankle shimmering by a couple of pixels is the
/// thing that makes a skeleton overlay look broken, and because a form rule
/// reading that shimmer as movement is worse.
const double defaultMinCutoff = 1.2;

/// How hard the cutoff rises with speed, in Hz per unit of speed.
///
/// This is the one-euro filter's whole trick, and the number is only
/// meaningful next to the units of the signal. Landmarks are **normalized
/// image coordinates**, so a hip dropping through a squat moves at a few
/// tenths of a unit per second — where the filter's published defaults are
/// written for pixels, which move a thousand times faster for the same
/// gesture.
///
/// At 0.05 the adaptive term contributed about one per cent of the cutoff
/// and the filter was a fixed 1.2Hz low-pass wearing a costume: it lagged a
/// squat descent by four degrees of knee angle and a fast rep by thirty. The
/// accuracy harness is what found that, by replaying the same movement at
/// two tempos. At 4.5 a brisk descent roughly doubles the cutoff and a
/// bounce lifts it to around 7Hz, while landmark noise on a planted ankle —
/// hundredths of a unit per second — still leaves it where it was.
const double defaultSpeedCoefficient = 4.5;

/// Fixed smoothing weight for landmark visibility.
const double defaultVisibilityAlpha = 0.3;

/// A gap longer than this is treated as an interruption, not a dropped
/// frame, and the filters start over.
///
/// At 30Hz a frame is 33ms, so this is a dozen frames: long past anything
/// the analyser merely skipped. Smoothing across it would drag the skeleton
/// in from wherever the user used to be standing.
const Duration defaultSmoothingResetAfter = Duration(milliseconds: 400);

/// A one-euro filter: a low-pass whose cutoff rises with the speed of the
/// signal.
///
/// A fixed low-pass has to choose between a steady reading when still and a
/// responsive one when moving, and pose data needs both — an ankle planted
/// on the floor and a hip dropping through a squat are the same stream. The
/// adaptive cutoff is what resolves that, so the filter smooths hard when
/// nothing is happening and gets out of the way when it is.
///
/// Driven by timestamps rather than by sample count, because frames drop.
class OneEuroFilter {
  OneEuroFilter({
    this.minCutoff = defaultMinCutoff,
    this.beta = defaultSpeedCoefficient,
    this.derivativeCutoff = 1.0,
  });

  /// Cutoff in Hz at zero speed.
  final double minCutoff;

  /// How much the cutoff rises per unit of estimated speed.
  final double beta;

  /// Cutoff in Hz for the speed estimate itself, which is noisier than the
  /// signal because it is a difference of two noisy samples.
  final double derivativeCutoff;

  double? _value;
  double? _derivative;
  Duration? _last;

  /// Filters [value], sampled at [t].
  double filter(double value, Duration t) {
    final previous = _value;
    final last = _last;
    _last = t;

    if (previous == null || last == null) {
      _value = value;
      _derivative = 0;
      return value;
    }

    final dt = (t - last).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) {
      // Two samples stamped the same instant. The derivative would be
      // infinite, which permanently pins the cutoff at its maximum, so the
      // sample is taken as-is and the state left for the next one.
      _value = value;
      return value;
    }

    final speed = (value - previous) / dt;
    final smoothedSpeed = _lowPass(_derivative ?? 0, speed, derivativeCutoff, dt);
    _derivative = smoothedSpeed;

    final cutoff = minCutoff + beta * smoothedSpeed.abs();
    final filtered = _lowPass(previous, value, cutoff, dt);
    _value = filtered;
    return filtered;
  }

  /// Throws away the history, so the next sample is taken at face value.
  void reset() {
    _value = null;
    _derivative = null;
    _last = null;
  }

  static double _lowPass(
    double previous,
    double value,
    double cutoff,
    double dt,
  ) {
    final tau = 1 / (2 * math.pi * cutoff);
    final alpha = 1 / (1 + tau / dt);
    return previous + alpha * (value - previous);
  }
}

/// Smooths a stream of [PoseFrame]s, one filter per joint per axis.
///
/// Stateful by nature: construct one per set, or use [PoseSmoothing], which
/// does that for each stream subscription.
class PoseSmoother {
  PoseSmoother({
    this.minCutoff = defaultMinCutoff,
    this.beta = defaultSpeedCoefficient,
    this.visibilityAlpha = defaultVisibilityAlpha,
    this.resetAfter = defaultSmoothingResetAfter,
  });

  final double minCutoff;
  final double beta;

  /// Visibility gets a plain exponential average, not the adaptive filter.
  /// Its wobble has nothing to do with how fast the body is moving, and an
  /// overlay that blinks a limb in and out reads as a bug even when the
  /// position underneath it is solid.
  final double visibilityAlpha;

  final Duration resetAfter;

  final Map<Joint, _JointFilters> _filters = {};
  Duration? _lastFrame;

  /// The smoothed form of [frame].
  ///
  /// Joints the frame does not carry are not carried forward: a held-over
  /// position is invented data, and the overlay would draw a limb nothing is
  /// tracking any more. Their filters are dropped too, so a joint that comes
  /// back somewhere else is treated as a new observation rather than
  /// dragged across from where it was.
  PoseFrame apply(PoseFrame frame) {
    final last = _lastFrame;
    if (last != null && frame.t - last > resetAfter) reset();
    _lastFrame = frame.t;

    final smoothed = <Joint, Landmark>{};
    for (final entry in frame.landmarks.entries) {
      final filters = _filters.putIfAbsent(
        entry.key,
        () => _JointFilters(minCutoff: minCutoff, beta: beta),
      );
      smoothed[entry.key] = filters.apply(
        entry.value,
        frame.t,
        visibilityAlpha,
      );
    }

    _filters.removeWhere((joint, _) => !frame.landmarks.containsKey(joint));

    return PoseFrame(
      frameId: frame.frameId,
      t: frame.t,
      landmarks: smoothed,
      confidence: frame.confidence,
    );
  }

  void reset() {
    _filters.clear();
    _lastFrame = null;
  }
}

class _JointFilters {
  _JointFilters({required double minCutoff, required double beta})
      : x = OneEuroFilter(minCutoff: minCutoff, beta: beta),
        y = OneEuroFilter(minCutoff: minCutoff, beta: beta),
        z = OneEuroFilter(minCutoff: minCutoff, beta: beta);

  final OneEuroFilter x;
  final OneEuroFilter y;
  final OneEuroFilter z;
  double? _visibility;

  Landmark apply(Landmark landmark, Duration t, double alpha) {
    final previous = _visibility;
    final visibility = previous == null
        ? landmark.visibility
        : previous + alpha * (landmark.visibility - previous);
    _visibility = visibility;

    return Landmark(
      x: x.filter(landmark.x, t),
      y: y.filter(landmark.y, t),
      z: z.filter(landmark.z, t),
      visibility: visibility.clamp(0.0, 1.0),
    );
  }
}

/// Applies a [PoseSmoother] to a stream, with its own state per subscription.
///
/// Const and shareable: the state belongs to the subscription, so the same
/// transformer can smooth two sets without the second starting part way
/// towards the end of the first.
class PoseSmoothing extends StreamTransformerBase<PoseFrame, PoseFrame> {
  const PoseSmoothing({
    this.minCutoff = defaultMinCutoff,
    this.beta = defaultSpeedCoefficient,
    this.visibilityAlpha = defaultVisibilityAlpha,
    this.resetAfter = defaultSmoothingResetAfter,
  });

  final double minCutoff;
  final double beta;
  final double visibilityAlpha;
  final Duration resetAfter;

  @override
  Stream<PoseFrame> bind(Stream<PoseFrame> stream) {
    final smoother = PoseSmoother(
      minCutoff: minCutoff,
      beta: beta,
      visibilityAlpha: visibilityAlpha,
      resetAfter: resetAfter,
    );
    return stream.map(smoother.apply);
  }
}
