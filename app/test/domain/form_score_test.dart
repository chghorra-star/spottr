import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';

/// The seam between what the camera saw and what next week's weight will be.
///
/// `FormScore`'s penalties live in `coach_engine` and the bands they have to
/// land in live in `plan_engine`, and the two packages do not know about each
/// other — on purpose: one of them is pure arithmetic about a body and the
/// other is a training decision. The app depends on both, so this is the
/// only place the two sets of constants can be checked against each other,
/// and it is the test that fails if either is tuned without the other.
void main() {
  final progression = Progression(standardCatalog);

  const request = PlanRequest(
    goal: Goal.muscleBuilding,
    daysPerWeek: 4,
    sessionMinutes: 60,
    level: Level.intermediate,
    location: TrainingLocation.fullGym,
  );

  const planned = PlannedExercise(
    exerciseId: 'barbell_back_squat',
    slotPattern: MovementPattern.squat,
    priority: SlotPriority.primary,
    sets: 3,
    templateSets: 3,
    metric: MetricType.reps,
    restSeconds: 75,
    secondsPerRep: 3,
    repsMin: 8,
    repsMax: 12,
    targetWeightKg: 60,
  );

  RepEvent event(int index) => RepEvent(
        index: index,
        outcome: RepOutcome.counted,
        fault: null,
        duration: const Duration(milliseconds: 1800),
        descent: const Duration(milliseconds: 900),
        ascent: const Duration(milliseconds: 900),
        peakAngle: 95,
        rangeOfMotion: 85,
      );

  /// A twelve-rep set where every rep fired the same rule.
  SetReview set({RuleSeverity? severity, String ruleId = 'hip_sag'}) =>
      SetReview(
        exerciseId: 'barbell_back_squat',
        reps: [
          for (var index = 1; index <= 12; index++)
            RepReview(
              event: event(index),
              verdict: FormVerdict(
                passed: severity == null ? 5 : 4,
                violations: [
                  if (severity != null)
                    FormViolation(ruleId: ruleId, severity: severity),
                ],
              ),
            ),
        ],
      );

  /// Three such sets, logged, and what progression decides about them.
  ProgressionDecision decide(SetReview review, {int priorLowForm = 0}) =>
      progression.decideOne(
        input: ProgressionInput(
          planned: planned,
          completed: [
            for (var index = 0; index < 3; index++)
              CompletedSet(
                reps: 12,
                weightKg: 60,
                formScore: review.formScore,
              ),
          ],
          priorLowFormSessions: priorLowForm,
        ),
        request: request,
      );

  group('what a form score does to the next session', () {
    test('a clean set earns more weight', () {
      final review = set();

      expect(review.formScore, 100);
      expect(decide(review).change, ProgressionChange.loadUp);
    });

    test('a coaching point on every rep still earns more weight', () {
      // A minor is worth saying and is not a reason to stall somebody's
      // training. If this ever flips, either FormScore.perMinor went up or
      // Progression.formCeiling came down, and whichever it was, somebody
      // has quietly decided that a tempo cue should cost a kilo a week.
      final review = set(severity: RuleSeverity.minor, ruleId: 'tempo');

      expect(review.formScore, 100 - FormScore.perMinor);
      expect(decide(review).change, ProgressionChange.loadUp);
    });

    test('a cue firing on every rep holds the weight where it is', () {
      final review = set(severity: RuleSeverity.major);

      expect(decide(review).change, ProgressionChange.hold);
      expect(decide(review).reason, isNot(ProgressionReason.formWatch));
    });

    test('a set that looked unsafe is watched, then eased off', () {
      // Once is a bad day and the engine says so without acting. Twice
      // running takes weight off, which is the only lever it has.
      final review = set(severity: RuleSeverity.unsafe, ruleId: 'back_rounding');

      expect(review.formScore!, lessThan(Progression.formFloor));
      expect(decide(review).reason, ProgressionReason.formWatch);
      expect(
        decide(review, priorLowForm: 1).reason,
        ProgressionReason.formBreakingDown,
      );
    });

    test('a set nothing could be checked on is no objection', () {
      // The phone face down, or the user out of frame. A null score has to
      // read as "no evidence" and never as "good form", which is what the
      // verdict refusing to score an unchecked rep is for.
      final blind = SetReview(
        exerciseId: 'barbell_back_squat',
        reps: [
          for (var index = 1; index <= 12; index++)
            RepReview(
              event: event(index),
              verdict: const FormVerdict(notVisible: {'squat_depth'}),
            ),
        ],
      );

      expect(blind.formScore, isNull);
      expect(decide(blind).change, ProgressionChange.loadUp);
    });
  });

  group('the bands the penalties were chosen against', () {
    test('a minor sits above the ceiling and a major below it', () {
      expect(
        FormScore.full - FormScore.perMinor,
        greaterThanOrEqualTo(Progression.formCeiling),
      );
      expect(
        FormScore.full - FormScore.perMajor,
        lessThan(Progression.formCeiling),
      );
    });

    test('a major stays above the floor and an unsafe drops below it', () {
      // The distinction the whole severity scale rests on: a cue that fires
      // every rep stops the weight going up, and only something that looked
      // risky takes weight off.
      expect(
        FormScore.full - FormScore.perMajor,
        greaterThanOrEqualTo(Progression.formFloor),
      );
      expect(
        FormScore.full - FormScore.perUnsafe,
        lessThan(Progression.formFloor),
      );
    });
  });
}
