import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'counter_config.dart';
import 'rep_event.dart';

/// What a counter made of one frame.
@immutable
sealed class CounterTick {
  const CounterTick({required this.tracking});

  /// Whether every signal the counter needs was measurable in this frame.
  ///
  /// A counter that cannot see the joints it needs says so rather than
  /// reporting zero: "I cannot see your knees" and "your knees did not move"
  /// are different sentences and they need different answers.
  final bool tracking;
}

/// The counter's view of one frame of a repetition exercise.
final class RepTick extends CounterTick {
  const RepTick({
    required this.phase,
    required this.counted,
    required this.attempts,
    required this.depth,
    required super.tracking,
    this.completed,
    this.last,
  });

  final RepPhase phase;

  /// Reps credited so far in this set.
  final int counted;

  /// Attempts made so far, credited or not.
  final int attempts;

  /// How far into the current rep the user is, in degrees, or `null` when
  /// nothing is tracked. Negative when they are further back than the top.
  final double? depth;

  /// Set on the one frame an attempt finished, and `null` on every other.
  ///
  /// For anything that sees every tick: a cue engine, a logger, the harness.
  final RepEvent? completed;

  /// The most recent attempt, on this frame and every frame after it.
  ///
  /// For anything that reads the newest tick and no others, which is what a
  /// screen does. The camera produces frames faster than the UI redraws, so
  /// a verdict reported only on the frame it happened would be a verdict the
  /// user never sees — and holding it in the widget instead would lose it
  /// the same way, because the dropped frame never reaches the widget at
  /// all.
  final RepEvent? last;
}

/// Why a hold's clock is not running.
enum HoldPause {
  /// The joints the hold needs are not being tracked.
  untracked,

  /// Tracked, but out of the posture being held.
  outOfPosition,
}

/// The counter's view of one frame of a hold.
final class HoldTick extends CounterTick {
  const HoldTick({
    required this.held,
    required this.pause,
    required super.tracking,
  });

  /// Time accumulated in position so far.
  final Duration held;

  /// `null` while the clock is running.
  final HoldPause? pause;

  bool get accumulating => pause == null;
}

/// Counts one set, one frame at a time.
///
/// Stateful and deliberately synchronous: the same object runs under a live
/// camera and under the accuracy harness replaying a fixture, and anything
/// asynchronous in here would make those two runs differ.
abstract class SetCounter {
  /// The counter the catalog configuration asks for.
  factory SetCounter.of(CounterConfig config) => switch (config) {
        RepCounterConfig() => RepCounter(config),
        HoldCounterConfig() => HoldCounter(config),
      };

  CounterConfig get config;

  /// The last tick produced, or a fresh one before any frame has arrived.
  CounterTick get tick;

  CounterTick update(PoseFrame frame);

  /// Back to the start of a set.
  void reset();
}

/// The repetition state machine.
///
/// ```
/// idle -> top -> descending -> bottom -> ascending -> (rep) -> top
/// ```
///
/// Two things about it are worth not re-deriving later.
///
/// **It will not count a rep it joined half way through.** From [idle] it
/// waits for the top before it will open an attempt, because the set starts
/// when the user taps start and not when they happen to be standing up. A
/// machine that treated its first frame as the top would hand a free rep to
/// anybody who began mid-squat.
///
/// **Every attempt is reported.** An attempt that was too shallow, too fast,
/// abandoned or lost to tracking emits a [RepEvent] saying so instead of
/// disappearing. A counter that silently ignores what the user did reads as
/// broken, and they have no way to find out which of their reps it disliked.
class RepCounter implements SetCounter {
  RepCounter(this.config);

  @override
  final RepCounterConfig config;

  RepPhase _phase = RepPhase.idle;
  int _counted = 0;
  int _attempts = 0;
  final List<RepEvent> _ledger = [];

  Duration? _lastFrame;
  Duration? _lastTracked;
  double? _lastDepth;

  /// The most recent frame judged to be at the top: when the movement
  /// started.
  Duration _topAt = Duration.zero;

  /// The deepest the signal rested at during the current stay at the top:
  /// where the movement started *from*.
  ///
  /// Taken from a different frame than [_topAt] on purpose. Time runs from
  /// the moment the user left the top, so dawdling up there is not part of
  /// the rep; position comes from where they were standing, because the
  /// alternative is to start the tape measure at the edge of the tolerance
  /// band and lose everything inside it — which would make
  /// `minRangeOfMotion` mean something other than what it says.
  double _topDepth = 0;

  /// Non-null while an attempt is open.
  Duration? _startedAt;
  double _startDepth = 0;
  double _peakDepth = 0;
  double _peakValue = 0;
  Duration _peakAt = Duration.zero;

  RepTick _tick = const RepTick(
    phase: RepPhase.idle,
    counted: 0,
    attempts: 0,
    depth: null,
    tracking: false,
  );

  @override
  RepTick get tick => _tick;

  /// Reps credited in this set.
  int get counted => _counted;

  /// Every attempt, credited or not, in the order they were made.
  List<RepEvent> get ledger => List.unmodifiable(_ledger);

  @override
  RepTick update(PoseFrame frame) {
    final t = frame.t;
    // A frame older than the one just read is a reordering somewhere below
    // us, and feeding it in would run the clock backwards.
    if (_lastFrame != null && t < _lastFrame!) return _emit(null);
    _lastFrame = t;

    final value = config.signal.measure(frame);
    if (value == null) {
      final since = _lastTracked;
      if (_startedAt != null &&
          since != null &&
          t - since > config.maxTrackingGap) {
        return _emit(_abandon(t, RepFault.lostTracking), tracking: false);
      }
      return _emit(null, tracking: false);
    }

    _lastTracked = t;
    final depth = config.depth(value);
    _lastDepth = depth;

    if (_startedAt != null) {
      if (t - _startedAt! > config.maxRepDuration) {
        return _emit(_abandon(t, RepFault.timedOut));
      }
      if (depth <= config.hysteresis) {
        final event = _complete(t);
        _phase = RepPhase.top;
        _topAt = t;
        _topDepth = depth;
        return _emit(event);
      }
      if (depth >= _peakDepth) {
        // On a tie the peak moves forward, so a pause at the bottom lands in
        // the descent rather than being split across both phases.
        _peakDepth = depth;
        _peakValue = value;
        _peakAt = t;
      }
      _phase = _phaseAt(depth);
      return _emit(null);
    }

    if (depth <= config.hysteresis) {
      _topDepth =
          _phase == RepPhase.top ? math.min(_topDepth, depth) : depth;
      _phase = RepPhase.top;
      _topAt = t;
    } else if (_phase == RepPhase.top) {
      _startedAt = _topAt;
      _startDepth = _topDepth;
      _peakDepth = depth;
      _peakValue = value;
      _peakAt = t;
      _phase = _phaseAt(depth);
    } else {
      // Mid-movement with no top to start from: wait for one.
      _phase = RepPhase.idle;
    }
    return _emit(null);
  }

  @override
  void reset() {
    _phase = RepPhase.idle;
    _counted = 0;
    _attempts = 0;
    _ledger.clear();
    _lastFrame = null;
    _lastTracked = null;
    _lastDepth = null;
    _startedAt = null;
    _tick = const RepTick(
      phase: RepPhase.idle,
      counted: 0,
      attempts: 0,
      depth: null,
      tracking: false,
    );
  }

  RepPhase _phaseAt(double depth) {
    if (depth >= config.fullRange - config.hysteresis) return RepPhase.bottom;
    if (depth <= _peakDepth - config.hysteresis) return RepPhase.ascending;
    // A dip on the way up is a wobble, not a new descent: staying in
    // [RepPhase.ascending] is what stops one rep being reported as two.
    if (_phase == RepPhase.ascending) return RepPhase.ascending;
    return RepPhase.descending;
  }

  RepEvent _complete(Duration t) {
    final duration = t - _startedAt!;
    final range = _peakDepth - _startDepth;

    final (RepOutcome outcome, RepFault? fault) = switch (null) {
      // Range before speed: a quick shallow dip is better explained by how
      // far it went than by how long it took, because "go deeper" is an
      // instruction and "that was too fast" is a riddle.
      _ when range < config.minRangeOfMotion => (
          RepOutcome.notCounted,
          RepFault.partialRange,
        ),
      _ when duration < config.minRepDuration => (
          RepOutcome.notCounted,
          RepFault.tooFast,
        ),
      _ when _peakDepth < config.fullRange - config.hysteresis => (
          RepOutcome.countedWithWarning,
          RepFault.shallow,
        ),
      _ => (RepOutcome.counted, null),
    };

    return _record(
      RepEvent(
        index: _attempts + 1,
        outcome: outcome,
        fault: fault,
        duration: duration,
        descent: _peakAt - _startedAt!,
        ascent: t - _peakAt,
        peakAngle: _peakValue,
        rangeOfMotion: range,
      ),
    );
  }

  RepEvent _abandon(Duration t, RepFault fault) {
    final event = _record(
      RepEvent(
        index: _attempts + 1,
        outcome: RepOutcome.notCounted,
        fault: fault,
        duration: t - _startedAt!,
        descent: _peakAt - _startedAt!,
        ascent: t - _peakAt,
        peakAngle: _peakValue,
        rangeOfMotion: _peakDepth - _startDepth,
      ),
    );
    // Back to idle rather than to the top: whatever happens next, the user
    // has to be seen at the top again before it can be a rep.
    _phase = RepPhase.idle;
    return event;
  }

  RepEvent _record(RepEvent event) {
    _attempts++;
    if (event.counted) _counted++;
    _ledger.add(event);
    _startedAt = null;
    return event;
  }

  RepTick _emit(RepEvent? completed, {bool tracking = true}) {
    _tick = RepTick(
      phase: _phase,
      counted: _counted,
      attempts: _attempts,
      depth: tracking ? _lastDepth : null,
      tracking: tracking,
      completed: completed,
      last: completed ?? _tick.last,
    );
    return _tick;
  }
}

/// Accumulates time spent in a posture.
///
/// A plank is not a rep count with the numbers changed: there is no cycle to
/// detect, only a clock that runs while every band is satisfied and stops
/// when one is not.
class HoldCounter implements SetCounter {
  HoldCounter(this.config);

  @override
  final HoldCounterConfig config;

  Duration _held = Duration.zero;
  Duration? _lastFrame;

  /// The time of the last frame that was in position, and therefore the
  /// point the next interval is measured from.
  Duration? _lastValid;

  HoldTick _tick = const HoldTick(
    held: Duration.zero,
    pause: HoldPause.untracked,
    tracking: false,
  );

  @override
  HoldTick get tick => _tick;

  Duration get held => _held;

  @override
  HoldTick update(PoseFrame frame) {
    final t = frame.t;
    if (_lastFrame != null && t < _lastFrame!) return _tick;
    _lastFrame = t;

    var tracked = true;
    var inPosition = true;
    for (final band in config.bands) {
      final value = band.signal.measure(frame);
      if (value == null) {
        tracked = false;
        break;
      }
      if (!band.contains(value)) inPosition = false;
    }

    if (!tracked || !inPosition) {
      _lastValid = null;
      return _emit(
        tracking: tracked,
        pause: tracked ? HoldPause.outOfPosition : HoldPause.untracked,
      );
    }

    final previous = _lastValid;
    _lastValid = t;
    // Time is accumulated between two frames that were both in position,
    // never from one frame alone — and never across a gap long enough that
    // what happened in the middle is a guess.
    if (previous != null && t - previous <= config.maxTrackingGap) {
      _held += t - previous;
    }
    return _emit(tracking: true, pause: null);
  }

  @override
  void reset() {
    _held = Duration.zero;
    _lastFrame = null;
    _lastValid = null;
    _tick = const HoldTick(
      held: Duration.zero,
      pause: HoldPause.untracked,
      tracking: false,
    );
  }

  HoldTick _emit({required bool tracking, required HoldPause? pause}) {
    _tick = HoldTick(held: _held, pause: pause, tracking: tracking);
    return _tick;
  }
}

/// Runs a counter over a frame stream.
///
/// A fresh counter per subscription, like the smoothing filter below it: two
/// listeners are two sets, not one set counted twice.
class CounterStream extends StreamTransformerBase<PoseFrame, CounterTick> {
  const CounterStream(this.config);

  final CounterConfig config;

  @override
  Stream<CounterTick> bind(Stream<PoseFrame> stream) {
    final counter = SetCounter.of(config);
    return stream.map(counter.update);
  }
}
