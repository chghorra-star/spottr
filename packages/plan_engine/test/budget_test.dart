import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

/// Session length has to shape a plan, not just cap it.
///
/// Before this existed the generator filled a fixed template and trimmed it
/// if it overran, so 45, 60, 75 and 90 minutes produced byte-identical weeks
/// and someone who set aside an hour was handed a 34-minute session. These
/// tests pin the other half of the rule: a longer session gets more work,
/// up to the point where more work would stop being useful.
void main() {
  final generator = PlanGenerator(standardCatalog);

  PlanRequest request({
    int sessionMinutes = 60,
    int daysPerWeek = 4,
    Goal goal = Goal.muscleBuilding,
    Level level = Level.intermediate,
    TrainingLocation location = TrainingLocation.fullGym,
    Set<int> runWeekdays = const {},
  }) =>
      PlanRequest(
        goal: goal,
        daysPerWeek: daysPerWeek,
        sessionMinutes: sessionMinutes,
        level: level,
        location: location,
        runWeekdays: runWeekdays,
      );

  int totalSets(WeekPlan plan) =>
      plan.allExercises.fold(0, (sum, e) => sum + e.sets);

  int setsIn(PlannedDay day) => day.exercises.fold(0, (sum, e) => sum + e.sets);

  /// Whether nothing more could be added to [day] without going past what is
  /// useful — either every exercise is at its own cap, or the session has as
  /// many working sets as one session should have. A day is allowed to fall
  /// short of its budget only for one of those reasons, which for a
  /// bodyweight-at-home user it often does.
  bool isMaxedOut(PlannedDay day) =>
      setsIn(day) >= DayRules.maxWorkingSetsPerDay ||
      day.exercises.every((e) => e.sets >= DayRules.maxSetsFor(e.priority));

  group('a longer session gets more work', () {
    test('volume rises with the time available', () {
      final volumes = [
        for (final minutes in [30, 45, 60, 75, 90])
          totalSets(generator.generate(request(sessionMinutes: minutes))),
      ];

      expect(
        volumes,
        orderedEquals(List<int>.from(volumes)..sort()),
        reason: 'more time never means less work: $volumes',
      );
      expect(
        volumes.last,
        greaterThan(volumes.first),
        reason: 'a 90 minute week is not harder than a 30 minute one',
      );
      expect(
        volumes.toSet().length,
        greaterThan(2),
        reason: 'session length barely changes the plan: $volumes',
      );
    });

    test('an hour is not quietly turned into half of one', () {
      // The case that prompted all of this.
      final plan = generator.generate(request(sessionMinutes: 60));

      for (final day in plan.days) {
        expect(
          day.estimatedMinutes,
          greaterThan(45),
          reason: 'day ${day.weekday} uses only ${day.estimatedMinutes} '
              'minutes of the 60 asked for',
        );
      }
    });
  });

  group('every day either fills its budget or runs out of useful work', () {
    test('across locations, levels and session lengths', () {
      for (final location in TrainingLocation.values) {
        for (final level in Level.values) {
          for (final minutes in [20, 30, 45, 60, 75, 90]) {
            final plan = generator.generate(
              request(
                sessionMinutes: minutes,
                level: level,
                location: location,
              ),
            );

            for (final day in plan.days) {
              final context = '${location.name} / ${level.name} / '
                  '${minutes}min / day ${day.weekday} '
                  '(${day.estimatedMinutes}min)';

              expect(
                day.estimatedSeconds,
                lessThanOrEqualTo(minutes * 60),
                reason: '$context overruns',
              );

              if (day.estimatedMinutes < minutes - 10) {
                expect(
                  isMaxedOut(day),
                  isTrue,
                  reason: '$context is short of its budget with room to grow',
                );
              }
            }
          }
        }
      }
    });

    test('a week that cannot be filled says so, once', () {
      // Bodyweight at home has almost no isolation work in the catalog, so
      // an hour cannot be filled with anything worth doing. Saying that is
      // more useful than silently handing over a short session.
      final plan = generator.generate(
        request(
          sessionMinutes: 90,
          location: TrainingLocation.homeNone,
          level: Level.beginner,
        ),
      );

      final notes = plan.notes
          .where((n) => n.kind == PlanNoteKind.sessionShorterThanBudget)
          .toList();
      expect(notes, hasLength(1), reason: 'one note for the week, not per day');
      expect(int.parse(notes.single.detail), greaterThan(0));
    });

    test('a week that fills its budget says nothing', () {
      final plan = generator.generate(request(sessionMinutes: 45));

      expect(
        plan.notes.map((n) => n.kind),
        isNot(contains(PlanNoteKind.sessionShorterThanBudget)),
      );
    });
  });

  group('the limits that stop filling', () {
    test('no exercise is given more sets than its slot allows', () {
      final plan = generator.generate(request(sessionMinutes: 90));

      for (final exercise in plan.allExercises) {
        expect(
          exercise.sets,
          lessThanOrEqualTo(DayRules.maxSetsFor(exercise.priority)),
          reason: '${exercise.exerciseId} has ${exercise.sets} sets',
        );
        expect(exercise.sets, greaterThanOrEqualTo(DayRules.minimumSets));
      }
    });

    test('a session never grows into junk volume', () {
      // The per-exercise caps do not bound this on their own: a nine
      // exercise gym day can reach every one of them and still come to
      // thirty-seven sets, which is a worse session, not a longer one.
      for (final minutes in [60, 75, 90, 120]) {
        final plan = generator.generate(request(sessionMinutes: minutes));
        for (final day in plan.days) {
          expect(
            setsIn(day),
            lessThanOrEqualTo(DayRules.maxWorkingSetsPerDay),
            reason: '${minutes}min day ${day.weekday} has ${setsIn(day)} sets',
          );
        }
      }
    });

    test('compound work gets the extra sets before isolation does', () {
      // Filling a session must not turn it into an arm workout.
      final plan = generator.generate(request(sessionMinutes: 90));
      final day = plan.days.first;

      final primaries = day.exercises.where((e) => e.isPrimary);
      expect(primaries, isNotEmpty);
      for (final primary in primaries) {
        expect(
          primary.sets,
          DayRules.maxSetsFor(SlotPriority.primary),
          reason: 'compound work was left short while time remained',
        );
      }
    });

    test('a run the next day still caps leg volume, however long the '
        'session is', () {
      final plan = generator.generate(
        request(
          goal: Goal.hybrid,
          sessionMinutes: 90,
          daysPerWeek: 3,
          runWeekdays: {3, 6},
        ),
      );

      final preRun = plan.days.where((d) => d.precedesRunDay);
      expect(preRun, isNotEmpty, reason: 'premise: a day precedes a run');
      for (final day in preRun) {
        for (final exercise in day.exercises) {
          if (exercise.isPrimary && exercise.slotPattern.isLegDominant) {
            expect(
              exercise.sets,
              lessThanOrEqualTo(DayRules.preRunLegSetCap),
              reason: 'filling the budget undid the pre-run cap',
            );
          }
        }
      }
    });
  });

  group('optional work', () {
    test('is present when there is time and gone when there is not', () {
      final long = generator.generate(request(sessionMinutes: 90));
      final short = generator.generate(request(sessionMinutes: 30));

      int optionals(WeekPlan plan) => plan.allExercises
          .where((e) => e.priority == SlotPriority.optional)
          .length;

      expect(optionals(long), greaterThan(0));
      expect(optionals(short), 0);
    });

    test('never explains itself', () {
      // Optional work is what the template offers if the session is long
      // enough. Its absence is the system working, so a note about it would
      // be noise — unlike a compound the time budget had to drop.
      final short = generator.generate(request(sessionMinutes: 30));

      for (final note in short.notes) {
        expect(
          note.kind,
          isNot(PlanNoteKind.unfilledSlot),
          reason: 'optional slots must not report themselves unfilled',
        );
      }
    });

    test('is dropped before accessory work, which goes before compounds', () {
      final plan = generator.generate(request(sessionMinutes: 25));
      final day = plan.days.first;

      expect(
        day.exercises.where((e) => e.priority == SlotPriority.optional),
        isEmpty,
      );
      expect(day.primaryExercises, isNotEmpty);
    });
  });

  group('the time estimate', () {
    test('allows for getting set up on each exercise', () {
      // Without this the estimate is pure set arithmetic, which is why a
      // "30 minute" session really took closer to 40: nothing accounted for
      // walking to the rack and changing the weight.
      const exercise = PlannedExercise(
        exerciseId: 'barbell_back_squat',
        slotPattern: MovementPattern.squat,
        priority: SlotPriority.primary,
        sets: 3,
        templateSets: 3,
        metric: MetricType.reps,
        restSeconds: 60,
        secondsPerRep: 3,
        repsMin: 8,
        repsMax: 12,
      );

      const workAndRest = 3 * (10 * 3 + 60);
      expect(
        exercise.estimatedSeconds,
        workAndRest + PlannedExercise.setupSeconds,
      );
      expect(PlannedExercise.setupSeconds, greaterThan(0));
    });
  });

  group('the rules are idempotent', () {
    test('applying them twice changes nothing', () {
      // Every plan edit re-applies them, so a day that grew to fill its
      // budget must not grow again each time the user drags a row.
      final plan = generator.generate(request(sessionMinutes: 90));
      final planRequest = request(sessionMinutes: 90);

      for (final day in plan.days) {
        final once = DayRules.apply(day, planRequest, standardCatalog);
        final twice = DayRules.apply(once.day, planRequest, standardCatalog);
        expect(twice.day, once.day, reason: 'day ${day.weekday} drifted');
      }
    });

    test('a day that moves away from a run recovers its volume', () {
      final planRequest = request(
        goal: Goal.hybrid,
        sessionMinutes: 90,
        daysPerWeek: 3,
        runWeekdays: {3, 6},
      );
      final plan = generator.generate(planRequest);
      final preRun = plan.days.firstWhere((d) => d.precedesRunDay);

      final moved = DayRules.apply(
        PlannedDay(
          weekday: preRun.weekday,
          type: preRun.type,
          labelKey: preRun.labelKey,
          precedesRunDay: false,
          exercises: preRun.exercises,
        ),
        planRequest,
        standardCatalog,
      );

      final legs = moved.day.exercises
          .where((e) => e.isPrimary && e.slotPattern.isLegDominant);
      expect(legs, isNotEmpty);
      for (final exercise in legs) {
        expect(
          exercise.sets,
          greaterThan(DayRules.preRunLegSetCap),
          reason: 'volume did not come back after the run day moved',
        );
      }
    });
  });
}
