import 'package:coach_engine/coach_engine.dart';
import 'package:test/test.dart';

FormViolation fired(String id, RuleSeverity severity) =>
    FormViolation(ruleId: id, severity: severity);

RepEvent repEvent({
  int index = 1,
  RepOutcome outcome = RepOutcome.counted,
  RepFault? fault,
}) =>
    RepEvent(
      index: index,
      outcome: outcome,
      fault: fault,
      duration: const Duration(milliseconds: 1800),
      descent: const Duration(milliseconds: 900),
      ascent: const Duration(milliseconds: 900),
      peakAngle: 95,
      rangeOfMotion: 85,
    );

/// A tick in the middle of a set of reps.
///
/// Built by hand rather than driven through the analyzer: arbitration is
/// what these tests are about, and a real body in them would make every
/// case an argument about geometry instead.
CoachTick repTick({
  required Duration at,
  int counted = 0,
  RepEvent? completed,
  List<FormViolation> violations = const [],
  Set<String> unchecked = const {},
  List<FormViolation> live = const [],
}) {
  final verdict = completed == null
      ? null
      : FormVerdict(
          violations: violations,
          passed: 4,
          notVisible: unchecked,
        );

  return CoachTick(
    t: at,
    counter: RepTick(
      phase: RepPhase.top,
      counted: counted,
      attempts: counted,
      depth: 0,
      tracking: true,
      completed: completed,
      last: completed,
    ),
    live: FormVerdict(violations: live, passed: 4),
    completed: verdict,
    last: verdict,
    review: const SetReview(exerciseId: 'bodyweight_squat', reps: []),
  );
}

CoachTick holdTick({
  required Duration at,
  Duration held = Duration.zero,
  List<FormViolation> live = const [],
}) =>
    CoachTick(
      t: at,
      counter: HoldTick(held: held, pause: null, tracking: true),
      live: FormVerdict(violations: live, passed: 3),
      review: const SetReview(exerciseId: 'plank', reps: []),
    );

/// A rep that finished at [at], with whatever fired on it.
CoachTick rep(
  int index,
  Duration at, {
  List<FormViolation> violations = const [],
  Set<String> unchecked = const {},
  RepOutcome outcome = RepOutcome.counted,
  RepFault? fault,
}) =>
    repTick(
      at: at,
      counted: index,
      completed: repEvent(index: index, outcome: outcome, fault: fault),
      violations: violations,
      unchecked: unchecked,
    );

void main() {
  group('CueEngine on a correction', () {
    test('says a coaching point the first time it happens', () {
      final engine = CueEngine();
      final cue = engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('squat_depth', RuleSeverity.minor),
        ]),
      );

      expect(cue, isA<RuleCue>());
      expect((cue! as RuleCue).ruleId, 'squat_depth');
    });

    test('says a coaching point once in a set, and not again', () {
      // A minor is worth mentioning. It is not worth mentioning twelve
      // times, which is what a coach that repeats itself sounds like.
      final engine = CueEngine();
      final said = <Cue>[];
      for (var index = 1; index <= 6; index++) {
        final cue = engine.update(
          rep(index, Duration(seconds: index * 4), violations: [
            fired('squat_depth', RuleSeverity.minor),
          ]),
        );
        if (cue != null) said.add(cue);
      }

      expect(said, hasLength(1));
    });

    test('holds a cue back until the rule has fired on two reps running', () {
      // The guard against an unvalidated rule. One rep is not evidence; the
      // same thing twice in a row is as much as this engine can ask for.
      final engine = CueEngine();

      expect(
        engine.update(
          rep(1, const Duration(seconds: 2), violations: [
            fired('hip_sag', RuleSeverity.major),
          ]),
        ),
        isNull,
      );
      expect(
        engine.update(
          rep(2, const Duration(seconds: 6), violations: [
            fired('hip_sag', RuleSeverity.major),
          ]),
        ),
        isA<RuleCue>(),
      );
    });

    test('never says a rule that fired once and then stopped', () {
      final engine = CueEngine();
      engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );
      final clean = engine.update(rep(2, const Duration(seconds: 6)));
      final third = engine.update(
        rep(3, const Duration(seconds: 10), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );

      expect(clean, isNull);
      expect(third, isNull, reason: 'the streak started again at one');
    });

    test('a rep the rule could not be checked on does not break the run', () {
      // Tracking came and went. That is not evidence the fault stopped, and
      // treating it as such would make the coach silent on exactly the sets
      // where the camera is struggling.
      final engine = CueEngine();
      engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );
      engine.update(rep(2, const Duration(seconds: 6), unchecked: {'hip_sag'}));
      final cue = engine.update(
        rep(3, const Duration(seconds: 10), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );

      expect(cue, isA<RuleCue>());
    });

    test('repeats a correction, but not every rep', () {
      final engine = CueEngine();
      final said = <Duration>[];
      for (var index = 1; index <= 12; index++) {
        final at = Duration(seconds: index * 4);
        final cue = engine.update(
          rep(index, at, violations: [fired('hip_sag', RuleSeverity.major)]),
        );
        if (cue != null) said.add(at);
      }

      expect(said.length, greaterThan(1));
      expect(said.length, lessThan(6));
      for (var i = 1; i < said.length; i++) {
        expect(
          said[i] - said[i - 1],
          greaterThanOrEqualTo(const CueBudget().majorCooldown),
        );
      }
    });
  });

  group('CueEngine on something unsafe', () {
    final rounding = [fired('back_rounding', RuleSeverity.unsafe)];

    test('waits for a second rep before saying it out loud', () {
      // The rule this guard was written for. Its signal is a proxy with
      // known artefacts, and interrupting somebody's set on one frame of
      // evidence is how a coach loses the benefit of the doubt.
      final engine = CueEngine();

      expect(
        engine.update(rep(1, const Duration(seconds: 2), violations: rounding)),
        isNull,
      );
      final cue =
          engine.update(rep(2, const Duration(seconds: 6), violations: rounding));

      expect(cue, isA<RuleCue>());
      expect(cue!.priority, CuePriority.safety);
    });

    test('pre-empts a correction that was waiting its turn', () {
      final engine = CueEngine();
      // Two reps of a major, so it is eligible and has just been said.
      engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );
      final major = engine.update(
        rep(2, const Duration(seconds: 6), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );
      expect(major, isA<RuleCue>());

      // Now something risky, twice running, close behind it.
      engine.update(rep(3, const Duration(seconds: 7), violations: rounding));
      final cue = engine
          .update(rep(4, const Duration(seconds: 8), violations: rounding));

      expect(cue, isA<RuleCue>());
      expect((cue! as RuleCue).ruleId, 'back_rounding');
    });

    test('keeps saying it, more often than a correction', () {
      final engine = CueEngine();
      final said = <Duration>[];
      for (var index = 1; index <= 12; index++) {
        final at = Duration(seconds: index * 4);
        final cue = engine.update(rep(index, at, violations: rounding));
        if (cue != null) said.add(at);
      }

      expect(said.length, greaterThan(2));
      expect(
        const CueBudget().unsafeCooldown,
        lessThan(const CueBudget().majorCooldown),
      );
    });
  });

  group('CueEngine on the count', () {
    test('says nothing about a rep that counted', () {
      // The screen already shows the number. Spending the voice budget on
      // it would mean the one thing worth saying arrives after the set.
      final engine = CueEngine(targetReps: 10);

      expect(engine.update(rep(1, const Duration(seconds: 2))), isNull);
    });

    test('says why a rep was refused', () {
      final engine = CueEngine();
      final cue = engine.update(
        rep(
          1,
          const Duration(seconds: 2),
          outcome: RepOutcome.notCounted,
          fault: RepFault.partialRange,
        ),
      );

      expect(cue, isA<RepCue>());
      expect((cue! as RepCue).fault, RepFault.partialRange);
    });

    test('does not repeat the same refusal every rep', () {
      final engine = CueEngine();
      final said = <Cue>[];
      for (var index = 1; index <= 6; index++) {
        final cue = engine.update(
          rep(
            index,
            Duration(seconds: index * 3),
            outcome: RepOutcome.notCounted,
            fault: RepFault.tooFast,
          ),
        );
        if (cue != null) said.add(cue);
      }

      expect(said.length, lessThan(3));
    });

    test('calls the target when it is reached, once', () {
      final engine = CueEngine(targetReps: 3);
      final said = <Cue>[];
      for (var index = 1; index <= 5; index++) {
        final cue = engine.update(rep(index, Duration(seconds: index * 4)));
        if (cue != null) said.add(cue);
      }

      expect(said, hasLength(1));
      expect(said.single, isA<TargetCue>());
    });

    test('says nothing about a target it was not given', () {
      final engine = CueEngine();
      final said = [
        for (var index = 1; index <= 5; index++)
          engine.update(rep(index, Duration(seconds: index * 4))),
      ];

      expect(said.whereType<Cue>(), isEmpty);
    });

    test('a correction outranks the target landing at the same moment', () {
      final engine = CueEngine(targetReps: 2);
      engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );
      final cue = engine.update(
        rep(2, const Duration(seconds: 6), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );

      expect(cue, isA<RuleCue>());
    });
  });

  group('CueEngine on a hold', () {
    test('says nothing about a wobble', () {
      final engine = CueEngine();
      final cue = engine.update(
        holdTick(
          at: const Duration(seconds: 4),
          held: const Duration(seconds: 4),
          live: [fired('hip_sag', RuleSeverity.major)],
        ),
      );

      expect(cue, isNull);
    });

    test('speaks once the fault has been there a while', () {
      // A hold has no reps, so the evidence a rep count would give has to
      // come from the clock instead.
      final engine = CueEngine();
      Cue? cue;
      for (var ms = 0; ms <= 4000; ms += 100) {
        cue ??= engine.update(
          holdTick(
            at: Duration(milliseconds: ms),
            held: Duration(milliseconds: ms),
            live: [fired('hip_sag', RuleSeverity.major)],
          ),
        );
      }

      expect(cue, isA<RuleCue>());
    });

    test('a fault that fixes itself resets the clock', () {
      final engine = CueEngine();
      for (var ms = 0; ms < 1000; ms += 100) {
        engine.update(
          holdTick(
            at: Duration(milliseconds: ms),
            live: [fired('hip_sag', RuleSeverity.major)],
          ),
        );
      }
      // Back in position.
      engine.update(holdTick(at: const Duration(milliseconds: 1100)));
      final cue = engine.update(
        holdTick(
          at: const Duration(milliseconds: 1200),
          live: [fired('hip_sag', RuleSeverity.major)],
        ),
      );

      expect(cue, isNull);
    });

    test('calls a hold target in seconds', () {
      final engine = CueEngine(targetHold: const Duration(seconds: 30));
      Cue? cue;
      for (var s = 0; s <= 35; s++) {
        cue ??= engine.update(
          holdTick(at: Duration(seconds: s), held: Duration(seconds: s)),
        );
      }

      expect(cue, isA<TargetCue>());
    });
  });

  group('CueEngine budget', () {
    test('leaves a gap so the voice cannot queue up', () {
      // Cues can be raised at thirty a second and speech runs at about one
      // short phrase every second and a half. Without a gap the coach ends
      // up seconds behind the set, which reads as broken rather than as
      // thorough.
      final engine = CueEngine();
      final said = <Duration>[];

      for (var ms = 0; ms <= 20000; ms += 100) {
        final at = Duration(milliseconds: ms);
        final cue = engine.update(
          holdTick(
            at: at,
            live: [
              fired('hip_sag', RuleSeverity.major),
              fired('neck_alignment', RuleSeverity.minor),
            ],
          ),
        );
        if (cue != null) said.add(at);
      }

      for (var i = 1; i < said.length; i++) {
        expect(
          said[i] - said[i - 1],
          greaterThanOrEqualTo(const CueBudget().gap),
        );
      }
    });

    test('something risky does not wait the full gap', () {
      const budget = CueBudget();
      final engine = CueEngine();

      engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );
      final major = engine.update(
        rep(2, const Duration(seconds: 6), violations: [
          fired('hip_sag', RuleSeverity.major),
        ]),
      );
      expect(major, isNotNull);

      engine.update(
        rep(3, const Duration(milliseconds: 6400), violations: [
          fired('back_rounding', RuleSeverity.unsafe),
        ]),
      );
      final safety = engine.update(
        rep(4, const Duration(milliseconds: 6800), violations: [
          fired('back_rounding', RuleSeverity.unsafe),
        ]),
      );

      expect(safety, isNotNull);
      expect(budget.safetyGap, lessThan(budget.gap));
    });

    test('remembers what it last said', () {
      final engine = CueEngine();
      expect(engine.last, isNull);

      final cue = engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('squat_depth', RuleSeverity.minor),
        ]),
      );

      expect(engine.last, same(cue));
    });

    test('forgets the set on reset', () {
      final engine = CueEngine();
      engine.update(
        rep(1, const Duration(seconds: 2), violations: [
          fired('squat_depth', RuleSeverity.minor),
        ]),
      );
      engine.reset();

      expect(engine.last, isNull);
      // The quota is per set, so the same point can be made in the next one.
      expect(
        engine.update(
          rep(1, const Duration(seconds: 2), violations: [
            fired('squat_depth', RuleSeverity.minor),
          ]),
        ),
        isA<RuleCue>(),
      );
    });

    test('a frame that reports nothing says nothing', () {
      final engine = CueEngine(targetReps: 5);

      expect(engine.update(repTick(at: const Duration(seconds: 1))), isNull);
    });
  });
}
