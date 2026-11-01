import 'package:meta/meta.dart';

import 'form_analyzer.dart';
import 'form_rule.dart';
import 'form_verdict.dart';
import 'rep_event.dart';
import 'set_counter.dart';

/// How urgently a cue wants to be said.
///
/// Ordered by index so that more urgent compares as greater: safety
/// pre-empts correction, correction pre-empts progress.
enum CuePriority { progress, correction, safety }

/// One thing the coach could say.
///
/// A value, never a sentence. Which words come out is the app's business
/// and the ARB file's, because the wording depends on the user's chosen
/// coach style and the engine must not know what language anybody speaks.
@immutable
sealed class Cue {
  const Cue({required this.at});

  /// When it was raised, measured from the start of the set.
  ///
  /// Carried so that whatever speaks it can drop a cue that went stale
  /// waiting its turn. A correction delivered four seconds after the rep it
  /// was about is worse than silence: the user applies it to the rep they
  /// are in the middle of.
  final Duration at;

  CuePriority get priority;

  /// Identity for the purposes of not repeating oneself.
  String get key;
}

/// A form rule fired.
final class RuleCue extends Cue {
  const RuleCue({
    required this.ruleId,
    required this.severity,
    required super.at,
  });

  final String ruleId;
  final RuleSeverity severity;

  @override
  CuePriority get priority => severity == RuleSeverity.unsafe
      ? CuePriority.safety
      : CuePriority.correction;

  @override
  String get key => 'rule.$ruleId';

  @override
  String toString() => 'RuleCue($ruleId, ${severity.name})';
}

/// An attempt did not count, and the user is owed the reason.
final class RepCue extends Cue {
  const RepCue({required this.fault, required super.at});

  final RepFault fault;

  @override
  CuePriority get priority => CuePriority.correction;

  @override
  String get key => 'rep.${fault.name}';

  @override
  String toString() => 'RepCue(${fault.name})';
}

/// The set reached what it was prescribed.
final class TargetCue extends Cue {
  const TargetCue({required super.at});

  @override
  CuePriority get priority => CuePriority.progress;

  @override
  String get key => 'target';

  @override
  String toString() => 'TargetCue()';
}

/// What the coach is allowed to say, and how often.
///
/// Every number here is about a voice rather than about a body, which makes
/// it the one table in this package that can be reasoned about without
/// footage: speech runs at roughly one short phrase every second and a
/// half, and cues can be raised thirty times a second.
@immutable
class CueBudget {
  const CueBudget({
    this.gap = const Duration(milliseconds: 2500),
    this.safetyGap = const Duration(milliseconds: 500),
    this.majorCooldown = const Duration(seconds: 15),
    this.unsafeCooldown = const Duration(seconds: 8),
    this.repCooldown = const Duration(seconds: 10),
    this.minorQuota = 1,
    this.majorRuns = 2,
    this.unsafeRuns = 2,
    this.minorRuns = 1,
    this.holdPersistence = const Duration(milliseconds: 1500),
  });

  /// Shortest time between any two cues.
  final Duration gap;

  /// The same, when what wants saying is a safety cue.
  ///
  /// Shorter, not zero. Talking over the end of the previous phrase is how
  /// a coach makes both of them unintelligible.
  final Duration safetyGap;

  final Duration majorCooldown;
  final Duration unsafeCooldown;
  final Duration repCooldown;

  /// How many times a coaching point may be made in one set.
  final int minorQuota;

  /// Consecutive reps a rule has to fire on before it is said out loud.
  ///
  /// One for a coaching point, two for anything that interrupts. No
  /// threshold in this engine has been measured against a real body, and
  /// the same thing happening twice in a row is as much corroboration as
  /// can be had without footage.
  final int majorRuns;
  final int unsafeRuns;
  final int minorRuns;

  /// How long a fault has to persist in a hold before it is said.
  ///
  /// A hold has no reps, so the evidence a rep count would give has to come
  /// from the clock instead.
  final Duration holdPersistence;

  int runsFor(RuleSeverity severity) => switch (severity) {
        RuleSeverity.minor => minorRuns,
        RuleSeverity.major => majorRuns,
        RuleSeverity.unsafe => unsafeRuns,
      };

  Duration cooldownFor(RuleSeverity severity) => switch (severity) {
        // A coaching point has a quota instead, which is stricter than any
        // cooldown: once a set and no more.
        RuleSeverity.minor => Duration.zero,
        RuleSeverity.major => majorCooldown,
        RuleSeverity.unsafe => unsafeCooldown,
      };
}

/// Decides what the coach says, and when, and how often.
///
/// At most one cue per frame, and most frames produce none. The hard part
/// is not choosing the most important thing — it is refusing to say the
/// other things, because a coach that reads out everything it notices is a
/// coach nobody can train with.
///
/// Stateful and synchronous, like everything else in this package: the
/// object that talks over a set in the gym is the object a test drives from
/// hand-written ticks, and it carries no clock of its own. Time comes from
/// the frames.
class CueEngine {
  CueEngine({
    this.targetReps,
    this.targetHold,
    this.budget = const CueBudget(),
  });

  /// What the set was prescribed, or null when it is not being run against
  /// a plan. Without one there is nothing to call.
  final int? targetReps;
  final Duration? targetHold;

  final CueBudget budget;

  /// Consecutive reps each rule has fired on.
  final Map<String, int> _runs = {};

  /// When each rule started failing continuously, for a hold.
  final Map<String, Duration> _failingSince = {};

  final Map<String, int> _saidCount = {};
  final Map<String, Duration> _saidAt = {};

  Duration? _lastAt;
  Cue? _last;
  bool _targetCalled = false;

  /// The last cue this engine produced, or null if it has not spoken.
  Cue? get last => _last;

  /// Whatever is worth saying about this frame, or nothing.
  Cue? update(CoachTick tick) {
    final now = tick.t;
    final candidates = <Cue>[];

    switch (tick.counter) {
      case final RepTick counter:
        final event = counter.completed;
        if (event != null) {
          _recordRun(tick.completed ?? FormVerdict.nothing);
          if (!event.counted && event.fault != null) {
            candidates.add(RepCue(fault: event.fault!, at: now));
          }
          candidates.addAll(_ruleCues(tick.completed, now, byRun: true));
        }
        if (_targetReached(reps: counter.counted)) {
          candidates.add(TargetCue(at: now));
        }
      case final HoldTick counter:
        _recordFailing(tick.live, now);
        candidates.addAll(_ruleCues(tick.live, now, byRun: false));
        if (_targetReached(held: counter.held)) {
          candidates.add(TargetCue(at: now));
        }
    }

    final cue = _choose(candidates, now);
    if (cue == null) return null;

    if (cue is TargetCue) _targetCalled = true;
    _saidCount[cue.key] = (_saidCount[cue.key] ?? 0) + 1;
    _saidAt[cue.key] = now;
    _lastAt = now;
    return _last = cue;
  }

  /// Back to the start of a set.
  void reset() {
    _runs.clear();
    _failingSince.clear();
    _saidCount.clear();
    _saidAt.clear();
    _lastAt = null;
    _last = null;
    _targetCalled = false;
  }

  /// Updates each rule's streak from one rep's verdict.
  ///
  /// A rule that could not be checked leaves its streak alone. Tracking
  /// coming and going is not evidence that a fault stopped, and treating it
  /// as such would make the coach quietest on exactly the sets where the
  /// camera is struggling.
  void _recordRun(FormVerdict verdict) {
    final failed = {for (final v in verdict.violations) v.ruleId};
    for (final id in {..._runs.keys, ...failed}) {
      if (failed.contains(id)) {
        _runs[id] = (_runs[id] ?? 0) + 1;
      } else if (!verdict.unchecked.contains(id)) {
        _runs[id] = 0;
      }
    }
  }

  void _recordFailing(FormVerdict verdict, Duration now) {
    final failed = {for (final v in verdict.violations) v.ruleId};
    for (final id in failed) {
      _failingSince.putIfAbsent(id, () => now);
    }
    for (final id in _failingSince.keys.toList()) {
      if (failed.contains(id) || verdict.unchecked.contains(id)) continue;
      _failingSince.remove(id);
    }
  }

  Iterable<Cue> _ruleCues(
    FormVerdict? verdict,
    Duration now, {
    required bool byRun,
  }) sync* {
    if (verdict == null) return;
    for (final violation in verdict.violations) {
      final enough = byRun
          ? (_runs[violation.ruleId] ?? 0) >=
              budget.runsFor(violation.severity)
          : now - (_failingSince[violation.ruleId] ?? now) >=
              budget.holdPersistence;
      if (!enough) continue;
      yield RuleCue(
        ruleId: violation.ruleId,
        severity: violation.severity,
        at: now,
      );
    }
  }

  bool _targetReached({int? reps, Duration? held}) {
    if (_targetCalled) return false;
    final target = targetReps;
    final hold = targetHold;
    if (target != null && reps != null) return reps >= target;
    if (hold != null && held != null) return held >= hold;
    return false;
  }

  /// The one cue worth saying, or none.
  Cue? _choose(List<Cue> candidates, Duration now) {
    final ready = [
      for (final cue in candidates)
        if (_withinQuota(cue) && _outOfCooldown(cue, now)) cue,
    ];
    if (ready.isEmpty) return null;

    ready.sort((a, b) {
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;
      return _weight(b).compareTo(_weight(a));
    });

    final best = ready.first;
    // The gap is about the voice being busy, so a cue that loses to it is
    // dropped rather than queued. Whatever raised it will raise it again on
    // the next rep if it still matters.
    final since = _lastAt;
    final gap =
        best.priority == CuePriority.safety ? budget.safetyGap : budget.gap;
    if (since != null && now - since < gap) return null;
    return best;
  }

  /// Tie-break within a priority: the more serious rule first.
  int _weight(Cue cue) => switch (cue) {
        RuleCue(:final severity) => severity.index,
        RepCue() => 0,
        TargetCue() => 0,
      };

  bool _withinQuota(Cue cue) {
    final said = _saidCount[cue.key] ?? 0;
    return switch (cue) {
      RuleCue(severity: RuleSeverity.minor) => said < budget.minorQuota,
      TargetCue() => said < 1,
      _ => true,
    };
  }

  bool _outOfCooldown(Cue cue, Duration now) {
    final said = _saidAt[cue.key];
    if (said == null) return true;
    final cooldown = switch (cue) {
      RuleCue(:final severity) => budget.cooldownFor(severity),
      RepCue() => budget.repCooldown,
      TargetCue() => Duration.zero,
    };
    return now - said >= cooldown;
  }
}
