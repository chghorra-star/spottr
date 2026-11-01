import 'package:coach_engine/coach_engine.dart';
import 'package:test/test.dart';

FormVerdict verdict({
  List<FormViolation> violations = const [],
  int passed = 0,
  Set<String> notVisible = const {},
  Set<String> notImplemented = const {},
  Set<String> blind = const {},
}) =>
    FormVerdict(
      violations: violations,
      passed: passed,
      notVisible: notVisible,
      notImplemented: notImplemented,
      blind: blind,
    );

FormViolation fired(String id, RuleSeverity severity) =>
    FormViolation(ruleId: id, severity: severity);

RepEvent rep({
  int index = 1,
  RepOutcome outcome = RepOutcome.counted,
  RepFault? fault,
  double rangeOfMotion = 60,
}) =>
    RepEvent(
      index: index,
      outcome: outcome,
      fault: fault,
      duration: const Duration(milliseconds: 1800),
      descent: const Duration(milliseconds: 900),
      ascent: const Duration(milliseconds: 900),
      peakAngle: 100,
      rangeOfMotion: rangeOfMotion,
    );

void main() {
  group('FormVerdict', () {
    test('a rep with every rule passing scores full marks', () {
      expect(verdict(passed: 5).score, 100);
    });

    test('a minor is worth saying and not worth much', () {
      final one = verdict(
        passed: 4,
        violations: [fired('tempo', RuleSeverity.minor)],
      );

      expect(one.score, 100 - FormScore.perMinor);
      // Still inside the band a set has to stay in to earn more weight: a
      // coaching point is not a reason to stop progressing somebody.
      expect(one.score!, greaterThanOrEqualTo(85));
    });

    test('a major holds the weight where it is', () {
      final one = verdict(
        passed: 4,
        violations: [fired('hip_sag', RuleSeverity.major)],
      );

      expect(one.score, 100 - FormScore.perMajor);
      // Below the ceiling that earns an increase, above the floor that
      // takes weight off. The exact numbers are plan_engine's and the app
      // has a test that pins this mapping to them.
      expect(one.score!, lessThan(85));
      expect(one.score!, greaterThanOrEqualTo(70));
    });

    test('an unsafe rep drops the set below the form floor on its own', () {
      final one = verdict(
        passed: 4,
        violations: [fired('back_rounding', RuleSeverity.unsafe)],
      );

      expect(one.score, 100 - FormScore.perUnsafe);
      expect(one.score!, lessThan(70));
    });

    test('violations add up', () {
      final two = verdict(
        passed: 2,
        violations: [
          fired('tempo', RuleSeverity.minor),
          fired('hip_sag', RuleSeverity.major),
        ],
      );

      expect(two.score, 100 - FormScore.perMinor - FormScore.perMajor);
    });

    test('a score has a floor', () {
      // More violations at once than any one exercise in the catalog could
      // produce. The clamp is here so that the arithmetic cannot hand a
      // negative number to something that averages it.
      final awful = verdict(
        violations: [
          fired('back_rounding', RuleSeverity.unsafe),
          fired('hip_sag', RuleSeverity.major),
          fired('back_arch', RuleSeverity.major),
          fired('torso_swing', RuleSeverity.major),
          fired('rom', RuleSeverity.major),
        ],
      );

      expect(awful.score, 0);
    });

    test('a rep nothing could be checked on has no score at all', () {
      // Not 100. A camera that saw nothing must not hand out a perfect set,
      // which is the whole reason a verdict counts what it checked.
      final blindfolded = verdict(
        notVisible: {'squat_depth', 'back_rounding'},
        blind: {'knee_valgus'},
      );

      expect(blindfolded.score, isNull);
      expect(blindfolded.checked, 0);
      expect(blindfolded.clean, isFalse);
    });

    test('counts what it looked at', () {
      final partial = verdict(
        passed: 3,
        violations: [fired('tempo', RuleSeverity.minor)],
        notVisible: {'heel_lift'},
        notImplemented: {'knee_valgus'},
      );

      expect(partial.checked, 4);
      expect(partial.unchecked, {'heel_lift', 'knee_valgus'});
    });

    test('names the worst thing that happened', () {
      expect(
        verdict(
          violations: [
            fired('tempo', RuleSeverity.minor),
            fired('back_rounding', RuleSeverity.unsafe),
            fired('hip_sag', RuleSeverity.major),
          ],
        ).worst,
        RuleSeverity.unsafe,
      );
      expect(verdict(passed: 2).worst, isNull);
    });

    test('a clean rep is one where something was checked and nothing fired',
        () {
      expect(verdict(passed: 2).clean, isTrue);
      expect(
        verdict(passed: 2, violations: [fired('tempo', RuleSeverity.minor)])
            .clean,
        isFalse,
      );
    });

    test('says whether the coach is willing to interrupt the set', () {
      expect(
        verdict(violations: [fired('back_rounding', RuleSeverity.unsafe)])
            .unsafe,
        isTrue,
      );
      expect(
        verdict(violations: [fired('hip_sag', RuleSeverity.major)]).unsafe,
        isFalse,
      );
    });
  });

  group('SetReview', () {
    RepReview review(
      int index, {
      List<FormViolation> violations = const [],
      int passed = 4,
      RepOutcome outcome = RepOutcome.counted,
    }) =>
        RepReview(
          event: rep(index: index, outcome: outcome),
          verdict: verdict(passed: passed, violations: violations),
        );

    test('a clean set scores full marks', () {
      final set = SetReview(
        exerciseId: 'bodyweight_squat',
        reps: [review(1), review(2), review(3)],
      );

      expect(set.formScore, 100);
      expect(set.counted, 3);
    });

    test('averages the reps rather than taking the worst of them', () {
      final set = SetReview(
        exerciseId: 'bodyweight_squat',
        reps: [
          review(1),
          review(2, violations: [fired('hip_sag', RuleSeverity.major)]),
        ],
      );

      expect(set.formScore, (100 + (100 - FormScore.perMajor)) / 2);
    });

    test('an attempt that did not count is not scored', () {
      // It was not a rep. Scoring it would punish somebody twice for the
      // same half-rep: once by not counting it and once in the number that
      // decides next week's weight.
      final set = SetReview(
        exerciseId: 'bodyweight_squat',
        reps: [
          review(1),
          review(
            2,
            outcome: RepOutcome.notCounted,
            violations: [fired('back_rounding', RuleSeverity.unsafe)],
          ),
        ],
      );

      expect(set.formScore, 100);
      expect(set.counted, 1);
    });

    test('a set where nothing counted has no score', () {
      final set = SetReview(
        exerciseId: 'bodyweight_squat',
        reps: [review(1, outcome: RepOutcome.notCounted)],
      );

      expect(set.formScore, isNull);
    });

    test('an empty set has no score', () {
      expect(
        const SetReview(exerciseId: 'bodyweight_squat', reps: []).formScore,
        isNull,
      );
    });

    test('tallies how often each rule fired', () {
      final set = SetReview(
        exerciseId: 'bodyweight_squat',
        reps: [
          review(1, violations: [fired('tempo', RuleSeverity.minor)]),
          review(2, violations: [fired('tempo', RuleSeverity.minor)]),
          review(3, violations: [fired('squat_depth', RuleSeverity.minor)]),
        ],
      );

      expect(set.firings, {'tempo': 2, 'squat_depth': 1});
    });

    test('lists what was never checked on a single rep of the set', () {
      // Checked on one rep and not another is a signal that came and went,
      // which is tracking. Never checked at all is a claim the coach should
      // not have made.
      final set = SetReview(
        exerciseId: 'bodyweight_squat',
        reps: [
          RepReview(
            event: rep(),
            verdict: verdict(passed: 2, notVisible: {'heel_lift', 'rom'}),
          ),
          RepReview(
            event: rep(index: 2),
            verdict: verdict(passed: 3, notVisible: {'heel_lift'}),
          ),
        ],
      );

      expect(set.neverChecked, {'heel_lift'});
    });

    test('a hold is scored from its own verdict', () {
      final set = SetReview(
        exerciseId: 'plank',
        reps: const [],
        hold: verdict(
          passed: 2,
          violations: [fired('hip_sag', RuleSeverity.major)],
        ),
      );

      expect(set.formScore, 100 - FormScore.perMajor);
      expect(set.counted, 0);
    });

    test('names the worst thing that happened in the whole set', () {
      final set = SetReview(
        exerciseId: 'bodyweight_squat',
        reps: [
          review(1, violations: [fired('tempo', RuleSeverity.minor)]),
          review(2, violations: [fired('back_rounding', RuleSeverity.unsafe)]),
        ],
      );

      expect(set.worst, RuleSeverity.unsafe);
    });
  });
}
