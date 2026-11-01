import 'package:meta/meta.dart';

import 'pose_signal.dart';
import 'rep_event.dart';

/// How much of a window a rule has to have seen before it will answer.
///
/// Below this it says [RuleOutcome.notVisible] rather than judging the
/// frames it happens to have. A verdict drawn from a fifth of a rep is a
/// verdict about a fifth of a rep, and the user cannot tell the difference
/// from the outside.
const double minRuleCoverage = 0.6;

/// How much a violated rule matters.
///
/// Three levels, with the consequences fixed here so that a rule's entry in
/// the catalog is the only place its seriousness is decided.
enum RuleSeverity {
  /// Worth saying once. A coaching point, not a risk.
  minor,

  /// Worth saying every time it happens. The rep still counts.
  major,

  /// The movement looked risky. The coach says to stop the set and take
  /// weight off, and the score drops far enough to change the next session's
  /// prescription.
  ///
  /// **It does not cancel the rep.** Every threshold behind every rule is
  /// still a guess rather than a measurement — see `counterCatalog` and
  /// `docs/dev-loop.md` — and deleting work somebody actually did on the
  /// strength of an unvalidated proxy is the one failure mode that makes a
  /// coach impossible to trust. Counting the rep and saying plainly that it
  /// looked unsafe costs nothing if the rule is wrong.
  unsafe,
}

/// What a rule made of a window.
///
/// Four outcomes rather than two. "I did not check this" and "this was
/// fine" are different sentences, and a scoring function that cannot tell
/// them apart rewards a camera that sees nothing.
enum RuleOutcome {
  pass,
  fail,

  /// The signals it needs were not tracked for enough of the window.
  notVisible,

  /// Spottr does not evaluate this rule yet. The id stays in the catalog so
  /// that the gap is countable and visible rather than forgotten.
  notImplemented,
}

/// Where in a repetition a single-sample rule reads its signal.
enum RepSample {
  /// The frame the counter judged to be the end of the rep: standing up,
  /// locked out, back on the floor.
  top,

  /// The deepest frame of the rep.
  peak,
}

/// Everything a rule is allowed to look at.
///
/// One rep, or — for a hold — the recent past. Rules are pure functions of
/// this: no clock, no camera, no state of their own, so a rule that fires in
/// the gym fires identically in the harness on the same samples.
@immutable
class RuleWindow {
  const RuleWindow({
    required this.samples,
    required this.times,
    required this.peakIndex,
    required this.event,
    required this.set,
    this.declaredTop,
  });

  /// One series per signal, aligned with [times], with `null` for a frame
  /// the signal could not be read in.
  ///
  /// Aligned rather than compacted on purpose: [peakIndex] indexes these,
  /// and dropping the gaps would silently move the bottom of the rep.
  final Map<PoseSignal, List<double?>> samples;

  final List<Duration> times;

  /// Index of the deepest frame, or `null` for a window with no bottom to
  /// it, which is every hold.
  final int? peakIndex;

  /// The attempt this window covers, or `null` for a hold.
  final RepEvent? event;

  /// Attempts already finished in this set, oldest first.
  final List<RepEvent> set;

  /// The frame the analyzer picked out as the top, when it knows one.
  final int? declaredTop;

  /// Index of the frame closest to the top of the movement: the most
  /// extended, the most locked out, the most upright.
  ///
  /// **Not the last frame of the rep.** A rep ends the moment the signal
  /// crosses back inside the tolerance band, which is up to a whole
  /// hysteresis short of where the user actually finishes standing up — so
  /// a lockout rule reading the final frame would mark everybody down by
  /// eight degrees. The analyzer keeps the rest at the top in the window
  /// and points this at the best frame in it.
  ///
  /// Falls back to the last frame for a window built without one, which is
  /// every live window: there, the newest frame is the only sensible answer
  /// to "where are they now".
  int? get topIndex =>
      declaredTop ?? (times.isEmpty ? null : times.length - 1);

  List<double?> seriesOf(PoseSignal signal) =>
      samples[signal] ?? const <double?>[];

  /// One sample, or `null` if the index is out of range or the signal was
  /// not readable there.
  double? sampleAt(PoseSignal signal, int index) {
    final series = seriesOf(signal);
    if (index < 0 || index >= series.length) return null;
    return series[index];
  }

  /// Every frame the signal could be read in.
  List<double> trackedIn(PoseSignal signal) =>
      [for (final value in seriesOf(signal)) ?value];

  /// The fraction of the window a signal was readable in, 0 when the
  /// window is empty.
  double coverageOf(PoseSignal signal) {
    final series = seriesOf(signal);
    if (series.isEmpty) return 0;
    return trackedIn(signal).length / series.length;
  }
}

/// One thing the coach checks about a movement.
///
/// Configuration, like the counters: a rule is an id, a severity, a signal
/// and a number, and tuning one is an edit to [formCatalog] rather than a
/// change to anything that runs.
@immutable
sealed class FormRule {
  const FormRule();

  /// Matches an id in `CameraSupport.formRuleIds`.
  String get id;

  RuleSeverity get severity;

  /// Every signal the rule reads. The analyzer samples exactly these, so a
  /// rule that under-declares them gets nulls.
  Set<PoseSignal> get signals;

  RuleOutcome evaluate(RuleWindow window);
}

/// One sample, at one point in the rep, inside a bound.
///
/// Depth and lockout: both are a question about a single instant, and
/// averaging the instants either side of it would answer a different one.
final class SignalBoundRule extends FormRule {
  const SignalBoundRule({
    required this.id,
    required this.severity,
    required this.signal,
    required this.at,
    this.min,
    this.max,
  }) : assert(min != null || max != null, 'a bound on neither side');

  @override
  final String id;

  @override
  final RuleSeverity severity;

  final PoseSignal signal;
  final RepSample at;
  final double? min;
  final double? max;

  @override
  Set<PoseSignal> get signals => {signal};

  @override
  RuleOutcome evaluate(RuleWindow window) {
    final index = switch (at) {
      RepSample.top => window.topIndex,
      RepSample.peak => window.peakIndex,
    };
    if (index == null) return RuleOutcome.notVisible;

    final value = window.sampleAt(signal, index);
    if (value == null) return RuleOutcome.notVisible;

    final low = min, high = max;
    final inside = (low == null || value >= low) &&
        (high == null || value <= high);
    return inside ? RuleOutcome.pass : RuleOutcome.fail;
  }
}

/// A signal that has to stay inside a band for the whole window.
///
/// A plank's hips, a push-up's midline, a lunge's torso: the fault is being
/// somewhere wrong and staying there, so the rule is about the frames and
/// not about an instant.
final class SignalHoldRule extends FormRule {
  const SignalHoldRule({
    required this.id,
    required this.severity,
    required this.signal,
    this.min,
    this.max,
    this.tolerance = 0.1,
  }) : assert(min != null || max != null, 'a band bounded on neither side');

  @override
  final String id;

  @override
  final RuleSeverity severity;

  final PoseSignal signal;
  final double? min;
  final double? max;

  /// The share of tracked frames allowed outside the band before the rule
  /// fails.
  ///
  /// Not zero. Landmark noise puts a frame outside any band eventually, and
  /// a rule that fired on one frame would fire on every rep of every set.
  final double tolerance;

  @override
  Set<PoseSignal> get signals => {signal};

  bool contains(double value) =>
      (min == null || value >= min!) && (max == null || value <= max!);

  @override
  RuleOutcome evaluate(RuleWindow window) {
    if (window.coverageOf(signal) < minRuleCoverage) {
      return RuleOutcome.notVisible;
    }

    final tracked = window.trackedIn(signal);
    if (tracked.isEmpty) return RuleOutcome.notVisible;

    final outside = tracked.where((value) => !contains(value)).length;
    return outside / tracked.length > tolerance
        ? RuleOutcome.fail
        : RuleOutcome.pass;
  }
}

/// How far a signal is allowed to move across the window.
///
/// The complement of a hold: a row's torso may be at any angle the user
/// finds comfortable, and what makes it a fault is that the angle changes
/// while the arms do the work.
final class SignalTravelRule extends FormRule {
  const SignalTravelRule({
    required this.id,
    required this.severity,
    required this.signal,
    required this.max,
  });

  @override
  final String id;

  @override
  final RuleSeverity severity;

  final PoseSignal signal;

  /// Largest acceptable spread across the window.
  final double max;

  @override
  Set<PoseSignal> get signals => {signal};

  /// The spread between the 5th and 95th percentile of the samples.
  ///
  /// Not the difference between the extremes. Over sixty noisy frames the
  /// two furthest-apart samples are, with high probability, the two worst
  /// landmark errors in the set — so a rule written as `max - min` measures
  /// the noise and calls it movement. The accuracy harness found that on a
  /// fixture of clean reps with jitter added, which is exactly the fixture
  /// it exists for.
  ///
  /// On a short window this degenerates to `max - min`, which is right:
  /// there is nothing to trim.
  double? spreadIn(RuleWindow window) {
    final tracked = window.trackedIn(signal)..sort();
    if (tracked.length < 2) return null;
    final last = tracked.length - 1;
    final low = tracked[(last * 0.05).round()];
    final high = tracked[(last * 0.95).round()];
    return high - low;
  }

  @override
  RuleOutcome evaluate(RuleWindow window) {
    if (window.coverageOf(signal) < minRuleCoverage) {
      return RuleOutcome.notVisible;
    }
    final spread = spreadIn(window);
    if (spread == null) return RuleOutcome.notVisible;
    return spread > max ? RuleOutcome.fail : RuleOutcome.pass;
  }
}

/// This rep against the longest one the user has managed in this set.
///
/// The only rule in the catalog with no threshold in degrees, and the only
/// one that needs no footage to be trusted: it compares the user with
/// themselves ninety seconds ago. Range shrinking across a set is what
/// fatigue looks like, and it is the one form fault that is unambiguous
/// without knowing anything about the exercise or the body performing it.
final class RangeConsistencyRule extends FormRule {
  const RangeConsistencyRule({
    required this.id,
    required this.severity,
    this.minFraction = 0.8,
  });

  @override
  final String id;

  @override
  final RuleSeverity severity;

  /// Share of the set's best range this rep has to reach.
  final double minFraction;

  @override
  Set<PoseSignal> get signals => const {};

  @override
  RuleOutcome evaluate(RuleWindow window) {
    final event = window.event;
    if (event == null) return RuleOutcome.notVisible;

    // Counted reps only. An attempt that was thrown out for being a bounce
    // may well have travelled further than any real rep, and it is not the
    // standard the real ones are held to.
    var best = 0.0;
    for (final previous in window.set) {
      if (!previous.counted) continue;
      if (previous.rangeOfMotion > best) best = previous.rangeOfMotion;
    }

    // The first rep of a set has nothing to compare with, which is not the
    // same as being unmeasurable: there is no evidence of anything getting
    // shorter, so the rule passes.
    if (best <= 0) return RuleOutcome.pass;

    return event.rangeOfMotion < best * minFraction
        ? RuleOutcome.fail
        : RuleOutcome.pass;
  }
}

/// How much of the rep was spent on the way in.
///
/// A share rather than a stopwatch. "Three seconds down" is a different
/// instruction for a sprinter and for somebody on their eleventh rep, but
/// "do not drop into it" is the same instruction for both, and the shape
/// that distinguishes them is the proportion.
final class DescentShareRule extends FormRule {
  const DescentShareRule({
    required this.id,
    required this.severity,
    this.minShare = 0.3,
  });

  @override
  final String id;

  @override
  final RuleSeverity severity;

  /// Smallest acceptable share of the rep spent descending.
  final double minShare;

  @override
  Set<PoseSignal> get signals => const {};

  @override
  RuleOutcome evaluate(RuleWindow window) {
    final event = window.event;
    if (event == null || event.duration <= Duration.zero) {
      return RuleOutcome.notVisible;
    }

    final share =
        event.descent.inMicroseconds / event.duration.inMicroseconds;
    return share < minShare ? RuleOutcome.fail : RuleOutcome.pass;
  }
}

/// A rule the catalog names and the engine does not evaluate yet.
///
/// Deliberately a rule rather than an absence. A missing entry would make
/// the catalog look complete and the coach look thorough; this one is
/// counted, reported, and shown to the user as something Spottr is not
/// watching. [reason] is what has to change for it to become a real rule,
/// and it is printed by the harness report.
final class PendingRule extends FormRule {
  const PendingRule({
    required this.id,
    required this.severity,
    required this.reason,
  });

  @override
  final String id;

  /// What it would be worth if it worked. Carried so that the gap can be
  /// described honestly: an unchecked major is worse news than an unchecked
  /// minor.
  @override
  final RuleSeverity severity;

  final String reason;

  @override
  Set<PoseSignal> get signals => const {};

  @override
  RuleOutcome evaluate(RuleWindow window) => RuleOutcome.notImplemented;
}
