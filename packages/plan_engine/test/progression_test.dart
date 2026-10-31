import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

/// Progression is a decision table, so these tests are a truth table.
///
/// Every case names the user it is about rather than the branch it covers:
/// what matters is that someone who hit every rep gets more load, and that
/// someone whose form fell apart twice does not.
void main() {
  final progression = Progression(standardCatalog);

  const request = PlanRequest(
    goal: Goal.muscleBuilding,
    daysPerWeek: 4,
    sessionMinutes: 60,
    level: Level.intermediate,
    location: TrainingLocation.fullGym,
  );

  const homeRequest = PlanRequest(
    goal: Goal.muscleBuilding,
    daysPerWeek: 3,
    sessionMinutes: 45,
    level: Level.beginner,
    location: TrainingLocation.homeNone,
  );

  /// A prescription to progress from. Defaults to a loaded compound.
  PlannedExercise planned({
    String exerciseId = 'barbell_back_squat',
    MovementPattern pattern = MovementPattern.squat,
    SlotPriority priority = SlotPriority.primary,
    int sets = 3,
    MetricType metric = MetricType.reps,
    int? repsMin = 8,
    int? repsMax = 12,
    int? holdSeconds,
    double? targetWeightKg,
  }) =>
      PlannedExercise(
        exerciseId: exerciseId,
        slotPattern: pattern,
        priority: priority,
        sets: sets,
        templateSets: sets,
        metric: metric,
        restSeconds: 75,
        secondsPerRep: 3,
        repsMin: repsMin,
        repsMax: repsMax,
        holdSeconds: holdSeconds,
        targetWeightKg: targetWeightKg,
      );

  List<CompletedSet> reps(
    int count, {
    required int each,
    double? weightKg,
    double? formScore,
  }) =>
      [
        for (var index = 0; index < count; index++)
          CompletedSet(reps: each, weightKg: weightKg, formScore: formScore),
      ];

  ProgressionDecision decide(
    ProgressionInput input, {
    PlanRequest only = request,
  }) =>
      progression.decideOne(input: input, request: only);

  group('earning more', () {
    test('every rep at the top of the range raises the load', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60),
        ),
      );

      expect(decision.change, ProgressionChange.loadUp);
      expect(decision.reason, ProgressionReason.earnedLoad);
      expect(decision.nextWeightKg, greaterThan(60));
      expect(decision.repsAchieved, 12);
    });

    test('a load step is a real plate change, not a rounding artefact', () {
      for (final weight in [20.0, 42.5, 60.0, 100.0, 185.0]) {
        final decision = decide(
          ProgressionInput(
            planned: planned(targetWeightKg: weight),
            completed: reps(3, each: 12, weightKg: weight),
          ),
        );
        final next = decision.nextWeightKg!;
        expect(
          next - weight,
          greaterThanOrEqualTo(Progression.loadStepKg),
          reason: 'from $weight',
        );
        expect(
          (next / Progression.loadStepKg) % 1,
          0,
          reason: '$next is not a multiple of ${Progression.loadStepKg}',
        );
      }
    });

    test('a weight off the usual grid still moves by a real step', () {
      // Fixed dumbbells and odd machine stacks do not land on 2.5kg
      // boundaries. Snapping 24kg up to 25 would be a 1kg "increase" that
      // nobody can feel, so the step wins and the result stays off-grid.
      final decision = decide(
        ProgressionInput(
          planned: planned(exerciseId: 'goblet_squat', targetWeightKg: 24),
          completed: reps(3, each: 12, weightKg: 24),
        ),
      );

      expect(decision.nextWeightKg, 26.5);
    });

    test('a heavier lift moves in bigger jumps than a light one', () {
      double step(double weight) {
        final decision = decide(
          ProgressionInput(
            planned: planned(targetWeightKg: weight),
            completed: reps(3, each: 12, weightKg: weight),
          ),
        );
        return decision.nextWeightKg! - weight;
      }

      expect(step(200), greaterThan(step(40)));
    });

    test('good form earns the increase; mediocre form does not', () {
      final strong = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60, formScore: 92),
        ),
      );
      final scrappy = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60, formScore: 78),
        ),
      );

      expect(strong.change, ProgressionChange.loadUp);
      expect(strong.meanFormScore, 92);
      expect(scrappy.change, ProgressionChange.hold);
      expect(scrappy.reason, ProgressionReason.holdingSteady);
    });

    test('no camera means no form objection, which is the M3 case', () {
      // Every set logged by hand has a null form score. Progression that
      // waited for form data would never progress anybody before M5.
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60),
        ),
      );

      expect(decision.change, ProgressionChange.loadUp);
      expect(decision.meanFormScore, isNull);
    });

    test('a session the user calls too easy counts, short of the top', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 10, weightKg: 60),
          rating: SessionRating.tooEasy,
        ),
      );

      expect(decision.change, ProgressionChange.loadUp);
      expect(decision.reason, ProgressionReason.ratedTooEasy);
    });

    test('bodyweight work earns reps, because there is no load to add', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'push_up',
            pattern: MovementPattern.horizontalPush,
          ),
          completed: reps(3, each: 12),
        ),
        only: homeRequest,
      );

      expect(decision.change, ProgressionChange.repsUp);
      expect(decision.reason, ProgressionReason.earnedReps);
      expect(decision.nextRepsMin, 8 + Progression.repStep);
      expect(decision.nextRepsMax, 12 + Progression.repStep);
      expect(decision.nextWeightKg, isNull);
    });

    test('a logged weight is what makes load the dial, not the catalog', () {
      // A push-up with a weight vest progresses by load; the same exercise
      // logged bare progresses by reps. Asking the catalog whether an
      // exercise is "weighted" would get one of those two wrong.
      final weighted = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'push_up',
            pattern: MovementPattern.horizontalPush,
            targetWeightKg: 10,
          ),
          completed: reps(3, each: 12, weightKg: 10),
        ),
        only: homeRequest,
      );

      expect(weighted.change, ProgressionChange.loadUp);
    });

    test('a hold earns seconds', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'plank',
            pattern: MovementPattern.core,
            priority: SlotPriority.accessory,
            metric: MetricType.holdSeconds,
            repsMin: null,
            repsMax: null,
            holdSeconds: 45,
          ),
          completed: const [
            CompletedSet(holdSeconds: 45),
            CompletedSet(holdSeconds: 45),
            CompletedSet(holdSeconds: 45),
          ],
        ),
      );

      expect(decision.change, ProgressionChange.holdUp);
      expect(decision.reason, ProgressionReason.earnedHold);
      expect(decision.nextHoldSeconds, 45 + Progression.holdStep);
    });

    test('reps stop climbing and the exercise gets harder instead', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'knee_push_up',
            pattern: MovementPattern.horizontalPush,
            repsMin: Progression.repCeiling - 2,
            repsMax: Progression.repCeiling,
          ),
          completed: reps(3, each: Progression.repCeiling),
        ),
        only: homeRequest,
      );

      expect(decision.change, ProgressionChange.harderVariant);
      expect(decision.reason, ProgressionReason.earnedHarderVariant);
      expect(
        decision.nextExerciseId,
        standardCatalog.require('knee_push_up').harderId,
      );
    });

    test('an exercise with nowhere left to go says so', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'push_up',
            pattern: MovementPattern.horizontalPush,
            repsMin: Progression.repCeiling - 2,
            repsMax: Progression.repCeiling,
          ),
          completed: reps(3, each: Progression.repCeiling),
        ),
        only: const PlanRequest(
          goal: Goal.muscleBuilding,
          daysPerWeek: 3,
          sessionMinutes: 45,
          level: Level.beginner,
          location: TrainingLocation.homeNone,
        ),
      );

      expect(decision.change, ProgressionChange.hold);
      expect(decision.reason, ProgressionReason.atCeiling);
      expect(decision.nextExerciseId, isNull);
    });

    test('a harder variant the user cannot do is not offered', () {
      // A beginner at the top of their push-up range would normally be
      // moved on; a harder variant that needs equipment they do not have
      // must not be handed to them anyway.
      final decision = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'incline_push_up',
            pattern: MovementPattern.horizontalPush,
            repsMin: Progression.repCeiling - 2,
            repsMax: Progression.repCeiling,
          ),
          completed: reps(3, each: Progression.repCeiling),
        ),
        only: const PlanRequest(
          goal: Goal.muscleBuilding,
          daysPerWeek: 3,
          sessionMinutes: 45,
          level: Level.beginner,
          location: TrainingLocation.homeNone,
          injuries: {BodyPart.wrists},
        ),
      );

      expect(decision.nextExerciseId, isNull);
    });
  });

  group('backing off', () {
    test('a missed rep drops the load', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: [
            ...reps(2, each: 10, weightKg: 60),
            ...reps(1, each: 6, weightKg: 60),
          ],
        ),
      );

      expect(decision.change, ProgressionChange.loadDown);
      expect(decision.reason, ProgressionReason.missedReps);
      expect(decision.nextWeightKg, lessThan(60));
      expect(decision.repsAchieved, 6);
    });

    test('a session the user calls too hard drops the load', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60),
          rating: SessionRating.tooHard,
        ),
      );

      expect(decision.change, ProgressionChange.loadDown);
      expect(decision.reason, ProgressionReason.ratedTooHard);
    });

    test('the lightest load has nowhere to fall, and says so', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: Progression.loadStepKg),
          completed: reps(3, each: 4, weightKg: Progression.loadStepKg),
        ),
      );

      expect(decision.change, ProgressionChange.hold);
      expect(decision.reason, ProgressionReason.missedReps);
      expect(decision.nextWeightKg, isNull);
    });

    test('bodyweight work holds rather than pretending to deload', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'push_up',
            pattern: MovementPattern.horizontalPush,
          ),
          completed: reps(3, each: 5),
        ),
        only: homeRequest,
      );

      expect(decision.change, ProgressionChange.hold);
      expect(decision.reason, ProgressionReason.missedReps);
    });

    test('form below the floor once is a warning, not a demotion', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60, formScore: 62),
        ),
      );

      expect(decision.change, ProgressionChange.hold);
      expect(decision.reason, ProgressionReason.formWatch);
      expect(decision.nextWeightKg, isNull);
    });

    test('form below the floor twice regresses to the easier variant', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(
            exerciseId: 'push_up',
            pattern: MovementPattern.horizontalPush,
          ),
          completed: reps(3, each: 12, formScore: 55),
          priorLowFormSessions: 1,
        ),
        only: homeRequest,
      );

      expect(decision.change, ProgressionChange.easierVariant);
      expect(decision.reason, ProgressionReason.formBreakingDown);
      expect(
        decision.nextExerciseId,
        standardCatalog.require('push_up').easierId,
      );
    });

    test('a loaded lift loses weight rather than changing exercise', () {
      // Swapping somebody off a barbell squat because two sessions looked
      // scrappy is an overreaction when there is a load dial to turn.
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 100),
          completed: reps(3, each: 12, weightKg: 100, formScore: 55),
          priorLowFormSessions: 2,
        ),
      );

      expect(decision.change, ProgressionChange.loadDown);
      expect(decision.reason, ProgressionReason.formBreakingDown);
      // A regression cuts harder than a missed rep does.
      expect(decision.nextWeightKg, lessThanOrEqualTo(90));
    });
  });

  group('safety', () {
    test('pain stops progression dead, whatever else the session says', () {
      for (final rating in [null, ...SessionRating.values]) {
        final decision = decide(
          ProgressionInput(
            planned: planned(targetWeightKg: 60),
            completed: reps(3, each: 12, weightKg: 60, formScore: 99),
            rating: rating,
            painReported: true,
          ),
        );

        expect(decision.change, ProgressionChange.hold, reason: '$rating');
        expect(decision.reason, ProgressionReason.painReported);
        expect(decision.nextWeightKg, isNull);
        expect(decision.nextExerciseId, isNull);
        expect(decision.changesAnything, isFalse);
      }
    });

    test('an unfinished session is not evidence of anything', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(sets: 4, targetWeightKg: 60),
          completed: reps(2, each: 12, weightKg: 60),
        ),
      );

      expect(decision.change, ProgressionChange.hold);
      expect(decision.reason, ProgressionReason.sessionIncomplete);
    });

    test('a session with nothing logged changes nothing', () {
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: const [],
        ),
      );

      expect(decision.change, ProgressionChange.hold);
      expect(decision.reason, ProgressionReason.sessionIncomplete);
    });

    test('progression has no opinion about the set count', () {
      // The time budget owns how much work a day holds; progression owns how
      // hard that work is. A progression that could add a set would quietly
      // push a session past the length the user asked for.
      final decision = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60),
        ),
      );

      expect(
        ProgressionChange.values.map((c) => c.name),
        isNot(contains(contains('set'))),
      );
      expect(decision.nextWeightKg, isNotNull);
    });
  });

  group('the whole session', () {
    test('one decision per exercise, in the order they were trained', () {
      final decisions = progression.decide(
        inputs: [
          ProgressionInput(
            planned: planned(targetWeightKg: 60),
            completed: reps(3, each: 12, weightKg: 60),
          ),
          ProgressionInput(
            planned: planned(exerciseId: 'barbell_bench_press'),
            completed: const [],
          ),
        ],
        request: request,
      );

      expect(decisions.map((d) => d.exerciseId), [
        'barbell_back_squat',
        'barbell_bench_press',
      ]);
      expect(decisions.first.change, ProgressionChange.loadUp);
      expect(decisions.last.change, ProgressionChange.hold);
    });

    test('the same session decided twice gives the same answer', () {
      final input = ProgressionInput(
        planned: planned(targetWeightKg: 60),
        completed: reps(3, each: 12, weightKg: 60),
      );

      expect(decide(input), decide(input));
    });

    test('a hold reports that it changed nothing', () {
      final holding = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60, formScore: 75),
        ),
      );
      final moving = decide(
        ProgressionInput(
          planned: planned(targetWeightKg: 60),
          completed: reps(3, each: 12, weightKg: 60),
        ),
      );

      expect(holding.changesAnything, isFalse);
      expect(moving.changesAnything, isTrue);
    });
  });
}
