import 'package:meta/meta.dart';

/// Where in a repetition the user is.
enum RepPhase {
  /// Nothing to count yet: no signal, or the user started somewhere other
  /// than the top and the counter is waiting for them to get there.
  idle,

  /// At the top, between reps.
  top,

  /// On the way into the movement.
  descending,

  /// At or near full depth.
  bottom,

  /// On the way back.
  ascending,
}

/// What became of one attempt.
///
/// Three outcomes rather than two, because a counter that silently drops a
/// rep reads as broken, and a counter that accepts everything teaches
/// nothing. Every attempt the user makes lands in the ledger as one of
/// these, with a reason.
enum RepOutcome { counted, countedWithWarning, notCounted }

/// Why an attempt was flagged or refused.
///
/// Nothing here is about form — these are properties of the movement itself,
/// measurable from one angle with no view of the spine or the knees. Form
/// faults arrive in M6 as rule violations alongside this.
enum RepFault {
  /// It did not travel far enough to be a repetition at all.
  partialRange,

  /// Past the acceptance bar but short of full depth. Counted, and said.
  shallow,

  /// Faster than the movement can physically be performed: a bounce, or the
  /// tracker jumping between frames.
  tooFast,

  /// Abandoned part way through. The user stopped, or walked off.
  timedOut,

  /// The joints the counter needs went missing mid-rep for longer than it
  /// is willing to guess across.
  lostTracking,
}

/// One completed attempt at a repetition.
@immutable
class RepEvent {
  const RepEvent({
    required this.index,
    required this.outcome,
    required this.fault,
    required this.duration,
    required this.descent,
    required this.ascent,
    required this.peakAngle,
    required this.rangeOfMotion,
  });

  /// Attempt number within the set, from 1 — **not** the rep count.
  ///
  /// A rejected attempt gets an index too, so the ledger the set summary
  /// shows has no holes in it and nothing the user did goes unexplained.
  final int index;

  final RepOutcome outcome;

  /// `null` only when the outcome is a clean [RepOutcome.counted].
  final RepFault? fault;

  /// Top to top.
  final Duration duration;

  /// Time from the start of the movement to the deepest point, including any
  /// pause there.
  final Duration descent;

  /// Deepest point back to the top.
  final Duration ascent;

  /// The measured angle at the deepest point, in the units the exercise is
  /// described in — a knee angle for a squat, an elbow angle for a press.
  final double peakAngle;

  /// Degrees the signal actually travelled, measured from where this attempt
  /// started.
  final double rangeOfMotion;

  /// Whether this attempt added to the user's rep count.
  bool get counted => outcome != RepOutcome.notCounted;

  @override
  String toString() => 'RepEvent(#$index, ${outcome.name}'
      '${fault == null ? '' : ', ${fault!.name}'}, '
      '${duration.inMilliseconds}ms, '
      'rom=${rangeOfMotion.toStringAsFixed(0)}deg)';
}
