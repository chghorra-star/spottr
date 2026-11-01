import 'dart:async';

import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'counter_catalog.dart';
import 'counter_config.dart';
import 'form_catalog.dart';
import 'form_rule.dart';
import 'form_verdict.dart';
import 'pose_signal.dart';
import 'rep_event.dart';
import 'set_counter.dart';

/// How much recent movement the live verdict is drawn from.
///
/// Long enough that a single noisy frame cannot carry it and short enough
/// that it describes what the user is doing rather than what they did at the
/// start of the set.
const Duration defaultLiveWindow = Duration(seconds: 2);

/// How much of the rest at the top of a rep is counted as part of it.
///
/// Enough to contain the moment somebody finishes standing up, which is
/// where a lockout rule has to look, and not enough for a rest between sets
/// to become a rep that lasted a minute.
const Duration defaultTopDwell = Duration(seconds: 1);

/// What the coach made of one frame: the count, the live reading, and the
/// verdict on whatever has just finished.
@immutable
class CoachTick {
  const CoachTick({
    required this.counter,
    required this.live,
    required this.review,
    this.completed,
    this.last,
  });

  /// What the rep or hold counter made of this frame.
  final CounterTick counter;

  /// The rules over the last couple of seconds.
  ///
  /// What the coach would say right now. Rules that need a whole rep — depth,
  /// lockout, tempo — report themselves unchecked here rather than guessing
  /// from half a movement.
  final FormVerdict live;

  /// Set on the one frame an attempt's verdict landed, `null` otherwise.
  final FormVerdict? completed;

  /// The most recent attempt's verdict, on this frame and every frame after.
  final FormVerdict? last;

  /// The set so far, including the number the progression table reads.
  final SetReview review;
}

/// Runs the counter and the form rules over one set.
///
/// Stateful and synchronous, like the counter underneath it and for the same
/// reason: the object that judges a set in the gym is the object the harness
/// replays a fixture through, and anything asynchronous in here would make
/// those two runs differ.
///
/// It owns the counter rather than sitting beside one. A rule window is
/// defined by the rep boundaries the counter found, so two components
/// deciding separately where a rep began is two components that can
/// disagree.
class FormAnalyzer {
  FormAnalyzer({
    required this.exercise,
    CameraAngle? angle,
    Map<String, FormRule> rules = formCatalog,
    Map<String, CounterConfig> counters = counterCatalog,
    this.liveWindow = defaultLiveWindow,
    this.topDwell = defaultTopDwell,
  })  : angle = angle ?? exercise.camera?.recommendedAngle ?? CameraAngle.side,
        selection = rulesFor(exercise, angle: angle, rules: rules),
        config = _configFor(exercise, counters) {
    _counter = SetCounter.of(config);
    _review = SetReview(exerciseId: exercise.id, reps: const []);
    _tick = CoachTick(
      counter: _counter.tick,
      live: FormVerdict.nothing,
      review: _review,
    );
  }

  final Exercise exercise;

  /// The angle the rules were selected for. Fixed for the set: moving the
  /// phone half way through would change which rules apply, and a score
  /// assembled from two different rule sets is not a score.
  final CameraAngle angle;

  final RuleSelection selection;
  final CounterConfig config;
  final Duration liveWindow;
  final Duration topDwell;

  late final SetCounter _counter;

  final _Buffer _rep = _Buffer();
  final _Buffer _live = _Buffer();
  final List<RepReview> _reps = [];
  final _VerdictBuilder _hold = _VerdictBuilder();

  late SetReview _review;
  late CoachTick _tick;
  FormVerdict? _last;

  CoachTick get tick => _tick;

  /// Every attempt the counter has made, for a caller that wants the ledger
  /// without the verdicts.
  List<RepEvent> get ledger => [for (final rep in _reps) rep.event];

  CoachTick update(PoseFrame frame) {
    final counterTick = _counter.update(frame);

    final reading = <PoseSignal, double?>{
      for (final signal in selection.signals) signal: signal.measure(frame),
    };

    _live.add(frame.t, reading);
    _live.trim(liveWindow);

    final liveOutcomes = _run(_live.window());
    final live = _build(liveOutcomes);
    FormVerdict? completed;
    var changed = false;

    switch (counterTick) {
      case RepTick():
        completed = _onRep(counterTick, frame.t, reading);
        changed = completed != null;
      case HoldTick():
        // Only once the window describes a stretch of time rather than a
        // frame or two. A verdict taken from the first frame of a set would
        // be a verdict about the moment the user was still lying down.
        if (_live.spans(liveWindow * 0.5)) {
          changed = _hold.recordAll(liveOutcomes);
        }
    }

    if (changed) {
      _review = SetReview(
        exerciseId: exercise.id,
        reps: List.unmodifiable(_reps),
        hold: counterTick is HoldTick ? _hold.build(selection) : null,
      );
    }

    if (completed != null) _last = completed;

    return _tick = CoachTick(
      counter: counterTick,
      live: live,
      completed: completed,
      last: _last,
      review: _review,
    );
  }

  /// Back to the start of a set.
  void reset() {
    _counter.reset();
    _rep.clear();
    _live.clear();
    _reps.clear();
    _hold.clear();
    _last = null;
    _review = SetReview(exerciseId: exercise.id, reps: const []);
    _tick = CoachTick(
      counter: _counter.tick,
      live: FormVerdict.nothing,
      review: _review,
    );
  }

  /// Buffers the rep in progress and reviews it when it ends.
  FormVerdict? _onRep(
    RepTick tick,
    Duration t,
    Map<PoseSignal, double?> reading,
  ) {
    final event = tick.completed;

    if (event != null) {
      _rep.add(t, reading, depth: tick.depth);
      // Rules do not judge an attempt the counter has already refused. A
      // rep that was not a rep did not happen, and measuring how deep
      // somebody got into a movement they abandoned half way produces
      // faults about a movement they never made. The counter's own reason
      // is the whole verdict for those.
      final verdict = event.counted
          ? _build(_run(_rep.window(event: event, set: ledger)))
          : FormVerdict.nothing;
      _reps.add(RepReview(event: event, verdict: verdict));
      _rep.clear();
      return verdict;
    }

    if (tick.phase == RepPhase.idle) {
      // Nothing can be counted from here until the counter sees a top, so
      // there is no window worth keeping.
      _rep.clear();
      return null;
    }

    _rep.add(t, reading, depth: tick.depth);
    // The rest at the top belongs to the rep that follows it, because the
    // rest is where a lockout happens: the counter ends a rep the instant
    // the signal crosses back inside its tolerance band, which is before
    // the user has finished standing up. Only the last moment of it,
    // though — somebody who racks the weight and reads their phone has not
    // performed a two-minute rep.
    if (tick.phase == RepPhase.top) _rep.trim(topDwell);
    return null;
  }

  /// Every active rule's answer about one window.
  Map<FormRule, RuleOutcome> _run(RuleWindow window) => {
        for (final rule in selection.active) rule: rule.evaluate(window),
      };

  FormVerdict _build(Map<FormRule, RuleOutcome> outcomes) {
    final builder = _VerdictBuilder()..recordAll(outcomes);
    return builder.build(selection);
  }

  static CounterConfig _configFor(
    Exercise exercise,
    Map<String, CounterConfig> counters,
  ) {
    final camera = exercise.camera;
    final config = camera == null ? null : counters[camera.repCounterId];
    if (config == null) {
      throw ArgumentError.value(
        exercise.id,
        'exercise',
        'the camera does not coach this exercise',
      );
    }
    return config;
  }
}

/// Samples, aligned with the frames they came from.
class _Buffer {
  final List<Duration> times = [];
  final Map<PoseSignal, List<double?>> samples = {};

  int? _peakIndex;
  double _peakDepth = double.negativeInfinity;

  int? _topIndex;
  double _topDepth = double.infinity;

  void add(
    Duration t,
    Map<PoseSignal, double?> reading, {
    double? depth,
  }) {
    times.add(t);
    for (final entry in reading.entries) {
      (samples[entry.key] ??= <double?>[]).add(entry.value);
    }
    // On a tie the peak moves forward, matching the counter: a pause at the
    // bottom belongs to the descent.
    if (depth != null && depth >= _peakDepth) {
      _peakDepth = depth;
      _peakIndex = times.length - 1;
    }
    // The shallowest frame is the top: where the joint was straightest,
    // which is not the same frame as the end of the rep.
    if (depth != null && depth <= _topDepth) {
      _topDepth = depth;
      _topIndex = times.length - 1;
    }
  }

  /// Drops frames off the front until the buffer covers no more than
  /// [window].
  void trim(Duration window) {
    while (times.length > 1 && times.last - times.first > window) {
      times.removeAt(0);
      for (final series in samples.values) {
        series.removeAt(0);
      }
      if (_peakIndex != null) _peakIndex = _peakIndex! - 1;
      if (_topIndex != null) _topIndex = _topIndex! - 1;
    }
    if ((_peakIndex ?? 0) < 0) _peakIndex = null;
    if ((_topIndex ?? 0) < 0) _topIndex = null;
  }

  /// Whether the buffer covers at least [span] of time.
  bool spans(Duration span) =>
      times.length > 1 && times.last - times.first >= span;

  void clear() {
    times.clear();
    samples.clear();
    _peakIndex = null;
    _peakDepth = double.negativeInfinity;
    _topIndex = null;
    _topDepth = double.infinity;
  }

  /// A snapshot. Copied, because the buffer keeps filling and a rule window
  /// is supposed to be the past.
  RuleWindow window({RepEvent? event, List<RepEvent> set = const []}) =>
      RuleWindow(
        samples: {
          for (final entry in samples.entries) entry.key: List.of(entry.value),
        },
        times: List.of(times),
        peakIndex: _peakIndex,
        declaredTop: _topIndex,
        event: event,
        set: set,
      );
}

/// Collects rule outcomes into a verdict.
///
/// Also used to fold a sequence of live windows into one verdict for a hold,
/// which is why it keeps the worst outcome per rule rather than the latest:
/// a plank whose hips dropped for four seconds and came back up is a plank
/// whose hips dropped.
class _VerdictBuilder {
  final Map<String, RuleOutcome> _outcomes = {};
  final Map<String, RuleSeverity> _severities = {};

  static int _rank(RuleOutcome outcome) => switch (outcome) {
        RuleOutcome.fail => 3,
        RuleOutcome.pass => 2,
        RuleOutcome.notVisible => 1,
        RuleOutcome.notImplemented => 0,
      };

  /// Keeps [outcome] if it is worse than what this rule already had.
  /// Returns whether anything changed.
  bool record(FormRule rule, RuleOutcome outcome) {
    _severities[rule.id] = rule.severity;
    final previous = _outcomes[rule.id];
    if (previous != null && _rank(previous) >= _rank(outcome)) return false;
    _outcomes[rule.id] = outcome;
    return true;
  }

  /// Folds in a whole window's worth of answers. Returns whether anything
  /// changed, which is what tells the analyzer the set review is stale.
  bool recordAll(Map<FormRule, RuleOutcome> outcomes) {
    var changed = false;
    for (final entry in outcomes.entries) {
      if (record(entry.key, entry.value)) changed = true;
    }
    return changed;
  }

  /// Seeds the builder with every rule in [selection], so that a hold which
  /// has never been evaluated still reports them.
  void _seed(RuleSelection selection) {
    for (final rule in selection.active) {
      _severities.putIfAbsent(rule.id, () => rule.severity);
      _outcomes.putIfAbsent(rule.id, () => RuleOutcome.notVisible);
    }
  }

  FormVerdict build(RuleSelection selection) {
    _seed(selection);

    final violations = <FormViolation>[];
    final notVisible = <String>{};
    var passed = 0;

    for (final entry in _outcomes.entries) {
      switch (entry.value) {
        case RuleOutcome.fail:
          violations.add(
            FormViolation(
              ruleId: entry.key,
              severity: _severities[entry.key] ?? RuleSeverity.minor,
            ),
          );
        case RuleOutcome.pass:
          passed++;
        case RuleOutcome.notVisible:
        case RuleOutcome.notImplemented:
          notVisible.add(entry.key);
      }
    }

    violations.sort(
      (a, b) => b.severity.index.compareTo(a.severity.index),
    );

    return FormVerdict(
      violations: violations,
      passed: passed,
      notVisible: notVisible,
      notImplemented: {for (final rule in selection.pending) rule.id},
      blind: selection.blind,
    );
  }

  void clear() {
    _outcomes.clear();
    _severities.clear();
  }
}

/// Runs a whole coach over a frame stream.
///
/// A fresh analyzer per subscription, like the counter and the smoothing
/// filter below it: two listeners are two sets, not one set judged twice.
class CoachStream extends StreamTransformerBase<PoseFrame, CoachTick> {
  const CoachStream({
    required this.exercise,
    this.angle,
    this.liveWindow = defaultLiveWindow,
  });

  final Exercise exercise;
  final CameraAngle? angle;
  final Duration liveWindow;

  @override
  Stream<CoachTick> bind(Stream<PoseFrame> stream) {
    final analyzer = FormAnalyzer(
      exercise: exercise,
      angle: angle,
      liveWindow: liveWindow,
    );
    return stream.map(analyzer.update);
  }
}
