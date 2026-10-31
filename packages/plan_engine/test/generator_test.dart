import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

final generator = PlanGenerator(standardCatalog);

PlanRequest request({
  Goal goal = Goal.muscleBuilding,
  int daysPerWeek = 3,
  int sessionMinutes = 60,
  Level level = Level.beginner,
  TrainingLocation location = TrainingLocation.fullGym,
  Set<Equipment> extraEquipment = const {},
  Set<BodyPart> injuries = const {},
  Set<int> runWeekdays = const {},
  List<String> recentExerciseIds = const [],
}) =>
    PlanRequest(
      goal: goal,
      daysPerWeek: daysPerWeek,
      sessionMinutes: sessionMinutes,
      level: level,
      location: location,
      extraEquipment: extraEquipment,
      injuries: injuries,
      runWeekdays: runWeekdays,
      recentExerciseIds: recentExerciseIds,
    );

List<String> idsOf(WeekPlan plan) =>
    plan.allExercises.map((e) => e.exerciseId).toList();

void main() {
  group('shape', () {
    test('produces one day per requested training day', () {
      for (var days = 2; days <= 6; days++) {
        final plan = generator.generate(request(daysPerWeek: days));
        expect(plan.days.length, days);
      }
    });

    test('carries the template id so the plan can be explained', () {
      expect(
        generator.generate(request(daysPerWeek: 6)).templateId,
        'ppl_6',
      );
    });

    test('every day has at least one exercise', () {
      for (final location in TrainingLocation.values) {
        for (var days = 2; days <= 6; days++) {
          final plan = generator.generate(
            request(daysPerWeek: days, location: location),
          );
          for (final day in plan.days) {
            expect(
              day.exercises,
              isNotEmpty,
              reason: '${location.name} day ${day.weekday} is empty',
            );
          }
        }
      }
    });

    test('never repeats an exercise within one day', () {
      for (var days = 2; days <= 6; days++) {
        final plan = generator.generate(
          request(daysPerWeek: days, level: Level.advanced),
        );
        for (final day in plan.days) {
          final ids = day.exercises.map((e) => e.exerciseId).toList();
          expect(ids.toSet().length, ids.length, reason: 'duplicate in $ids');
        }
      }
    });

    test('is deterministic', () {
      // Golden tests and reproducible bug reports both depend on this.
      final first = generator.generate(request(daysPerWeek: 5));
      final second = generator.generate(request(daysPerWeek: 5));
      expect(idsOf(first), idsOf(second));
    });
  });

  group('hard constraints', () {
    test('never prescribes a contraindicated exercise', () {
      for (final injury in BodyPart.values) {
        for (var days = 2; days <= 6; days++) {
          final plan = generator.generate(
            request(
              daysPerWeek: days,
              level: Level.advanced,
              injuries: {injury},
            ),
          );
          for (final planned in plan.allExercises) {
            expect(
              standardCatalog.require(planned.exerciseId).isSafeFor({injury}),
              isTrue,
              reason: '${planned.exerciseId} is unsafe for ${injury.name}',
            );
          }
        }
      }
    });

    test('never prescribes equipment the user does not have', () {
      for (final location in TrainingLocation.values) {
        final plan = generator.generate(
          request(location: location, level: Level.advanced, daysPerWeek: 5),
        );
        for (final planned in plan.allExercises) {
          expect(
            standardCatalog
                .require(planned.exerciseId)
                .isAvailableWith(location.impliedEquipment),
            isTrue,
            reason: '${planned.exerciseId} needs kit a ${location.name} '
                'user lacks',
          );
        }
      }
    });

    test('never prescribes an exercise above the user level', () {
      for (final level in Level.values) {
        final plan = generator.generate(
          request(level: level, daysPerWeek: 6),
        );
        for (final planned in plan.allExercises) {
          expect(
            standardCatalog.require(planned.exerciseId).suitsLevel(level),
            isTrue,
            reason: '${planned.exerciseId} is too advanced for ${level.name}',
          );
        }
      }
    });

    test('honours extra equipment a home user owns', () {
      final plan = generator.generate(
        request(
          location: TrainingLocation.homeDumbbells,
          extraEquipment: {Equipment.pullUpBar},
          level: Level.advanced,
          daysPerWeek: 4,
        ),
      );
      expect(idsOf(plan), contains('pull_up'));
    });
  });

  group('time budget', () {
    test('every day fits the session length', () {
      for (final minutes in [30, 45, 60, 90]) {
        for (var days = 2; days <= 6; days++) {
          final plan = generator.generate(
            request(daysPerWeek: days, sessionMinutes: minutes),
          );
          for (final day in plan.days) {
            expect(
              day.estimatedSeconds,
              lessThanOrEqualTo(minutes * 60),
              reason: '$minutes min / $days days: day ${day.weekday} runs '
                  '${day.estimatedSeconds}s',
            );
          }
        }
      }
    });

    test('a short session trims accessories before compounds', () {
      final short = generator.generate(request(sessionMinutes: 30));
      final long = generator.generate(request(sessionMinutes: 90));

      final shortDay = short.days.first;
      final longDay = long.days.first;

      expect(shortDay.exercises.length, lessThan(longDay.exercises.length));
      expect(
        shortDay.exercises.where((e) => e.priority == SlotPriority.primary),
        isNotEmpty,
      );
      expect(
        short.notes.any((n) => n.kind == PlanNoteKind.trimmedForTime),
        isTrue,
      );
    });

    test('a long session keeps the whole template', () {
      final plan = generator.generate(
        request(sessionMinutes: 90, location: TrainingLocation.fullGym),
      );
      expect(
        plan.notes.any((n) => n.kind == PlanNoteKind.trimmedForTime),
        isFalse,
      );
      // Nothing was given up, which for a long session means even the
      // optional work the template offers last is still there.
      expect(
        plan.days.first.exercises
            .where((e) => e.priority == SlotPriority.optional),
        isNotEmpty,
      );
    });

    test('keeps at least one primary exercise however tight the budget', () {
      final plan = generator.generate(request(sessionMinutes: 20));
      for (final day in plan.days) {
        expect(
          day.exercises.where((e) => e.priority == SlotPriority.primary),
          isNotEmpty,
        );
      }
    });
  });

  group('prescription', () {
    test('uses the goal rep range for compound work', () {
      final plan = generator.generate(request(goal: Goal.muscleBuilding));
      final compound = plan.allExercises.firstWhere(
        (e) => e.priority == SlotPriority.primary,
      );
      expect(compound.repsMin, 8);
      expect(compound.repsMax, 12);
      expect(compound.restSeconds, 75);
    });

    test('fat loss trains higher and rests less', () {
      final plan = generator.generate(request(goal: Goal.weightLoss));
      final compound = plan.allExercises.firstWhere(
        (e) => e.priority == SlotPriority.primary,
      );
      expect(compound.repsMin, 12);
      expect(compound.restSeconds, 45);
    });

    test('prescribes seconds, not reps, for a hold', () {
      final plan = generator.generate(
        request(location: TrainingLocation.homeNone, sessionMinutes: 90),
      );
      final holds = plan.allExercises.where(
        (e) => e.metric == MetricType.holdSeconds,
      );
      expect(holds, isNotEmpty);
      for (final hold in holds) {
        expect(hold.holdSeconds, isNotNull);
        expect(hold.repsMin, isNull);
      }
    });

    test('narrows an isolation slot to the muscle it asked for', () {
      final plan = generator.generate(
        request(daysPerWeek: 4, sessionMinutes: 90, level: Level.advanced),
      );
      final upperDay = plan.days.firstWhere((d) => d.type == DayType.upper);
      // The accessory isolation slots, not the optional ones a long session
      // also brings in: those name their own muscles.
      final isolation = upperDay.exercises.where(
        (e) =>
            e.slotPattern == MovementPattern.isolation &&
            e.priority == SlotPriority.accessory,
      );
      expect(isolation.length, 2);

      final muscles = isolation
          .map((e) => standardCatalog.require(e.exerciseId).primaryMuscles)
          .expand((m) => m)
          .toSet();
      expect(muscles, containsAll({MuscleGroup.biceps, MuscleGroup.triceps}));
    });
  });

  group('ranking', () {
    test('prefers a camera-supported exercise among equals', () {
      // Camera support is weighted at roughly one level of progression, so a
      // beginner at a full gym should still get the coached squat.
      final plan = generator.generate(
        request(level: Level.beginner, sessionMinutes: 90),
      );
      final squat = plan.days.first.exercises.firstWhere(
        (e) => e.slotPattern == MovementPattern.squat,
      );
      expect(
        standardCatalog.require(squat.exerciseId).isCameraSupported,
        isTrue,
      );
    });

    test('still loads an advanced lifter properly', () {
      // Two levels of progression outrank camera support: an advanced lifter
      // gets the barbell squat, not the coached bodyweight one.
      final plan = generator.generate(
        request(level: Level.advanced, sessionMinutes: 90, daysPerWeek: 4),
      );
      final lower = plan.days.firstWhere((d) => d.type == DayType.lower);
      final squat = lower.exercises.firstWhere(
        (e) => e.slotPattern == MovementPattern.squat,
      );
      expect(squat.exerciseId, 'barbell_back_squat');
    });

    test('prefers loaded work over bodyweight when kit is available', () {
      final home = generator.generate(
        request(location: TrainingLocation.homeNone, sessionMinutes: 90),
      );
      final gym = generator.generate(
        request(
          location: TrainingLocation.homeDumbbells,
          sessionMinutes: 90,
        ),
      );

      String squatIn(WeekPlan plan) => plan.days.first.exercises
          .firstWhere((e) => e.slotPattern == MovementPattern.squat)
          .exerciseId;

      expect(squatIn(home), 'bodyweight_squat');
      expect(squatIn(gym), 'goblet_squat');
    });

    test('varies the second push day away from the first', () {
      final plan = generator.generate(
        request(daysPerWeek: 6, sessionMinutes: 90, level: Level.advanced),
      );
      final pushDays =
          plan.days.where((d) => d.type == DayType.push).toList();
      expect(pushDays.length, 2);

      final first = pushDays[0].exercises.map((e) => e.exerciseId).toSet();
      final second = pushDays[1].exercises.map((e) => e.exerciseId).toSet();
      expect(
        second.difference(first),
        isNotEmpty,
        reason: 'the two push days are identical',
      );
    });

    test('rotates away from a recent exercise when an equal one exists', () {
      String pressFor(List<String> recent) => generator
          .generate(
            request(
              level: Level.advanced,
              sessionMinutes: 90,
              recentExerciseIds: recent,
            ),
          )
          .days
          .first
          .exercises
          .firstWhere((e) => e.slotPattern == MovementPattern.horizontalPush)
          .exerciseId;

      final fresh = pressFor(const []);
      expect(fresh, 'barbell_bench_press');
      expect(pressFor([fresh]), 'db_bench_press');
    });

    test('variety never downgrades the prescription', () {
      // Repeating the best option beats rotating to a worse one. A dumbbell
      // owner gets goblet squats every session, not bodyweight squats
      // mid-week for the sake of change.
      final plan = generator.generate(
        request(
          location: TrainingLocation.homeDumbbells,
          sessionMinutes: 90,
          recentExerciseIds: ['goblet_squat'],
        ),
      );
      for (final day in plan.days) {
        expect(
          day.exercises
              .firstWhere((e) => e.slotPattern == MovementPattern.squat)
              .exerciseId,
          'goblet_squat',
        );
      }
    });
  });

  group('unfillable slots', () {
    test('notes a pattern the user has no equipment for', () {
      final plan = generator.generate(
        request(
          daysPerWeek: 4,
          location: TrainingLocation.homeNone,
          sessionMinutes: 90,
        ),
      );
      final unfilled = plan.notes
          .where((n) => n.kind == PlanNoteKind.unfilledSlot)
          .map((n) => n.detail)
          .toSet();

      // Nothing in the catalog trains pulling without a bar.
      expect(unfilled, contains('horizontalPull'));
    });

    test('still produces a usable session around the gap', () {
      final plan = generator.generate(
        request(
          daysPerWeek: 4,
          location: TrainingLocation.homeNone,
          sessionMinutes: 60,
        ),
      );
      for (final day in plan.days) {
        expect(day.exercises, isNotEmpty);
      }
    });

    test('falls back to any isolation when the target muscle is unavailable', () {
      // A pull-up bar is enough to earn an upper/lower split, but there is
      // still no way to isolate biceps without dumbbells or a cable. The
      // accessory slot takes bodyweight work rather than being lost.
      final plan = generator.generate(
        request(
          daysPerWeek: 4,
          location: TrainingLocation.homeNone,
          extraEquipment: {Equipment.pullUpBar},
          level: Level.intermediate,
          sessionMinutes: 90,
        ),
      );
      final upper = plan.days.firstWhere((d) => d.type == DayType.upper);
      final isolation = upper.exercises.where(
        (e) => e.slotPattern == MovementPattern.isolation,
      );
      expect(isolation, isNotEmpty);
      expect(
        standardCatalog
            .require(isolation.first.exerciseId)
            .primaryMuscles
            .contains(MuscleGroup.biceps),
        isFalse,
        reason: 'expected a fallback, not a real biceps exercise',
      );
    });

    test('abandons a split the user cannot physically train', () {
      // An upper/lower or push/pull/legs split is built around pulling. A
      // bodyweight-only user has no pull at all, so a pull day would be
      // empty. Full-body days are the honest prescription instead.
      for (final days in [4, 5, 6]) {
        final plan = generator.generate(
          request(
            daysPerWeek: days,
            location: TrainingLocation.homeNone,
            sessionMinutes: 90,
          ),
        );

        expect(plan.templateId, 'full_body_$days');
        expect(
          plan.notes.any((n) => n.kind == PlanNoteKind.templateSimplified),
          isTrue,
        );
        for (final day in plan.days) {
          expect(day.type, DayType.fullBody);
          expect(
            day.primaryExercises.length,
            greaterThanOrEqualTo(2),
            reason: 'day ${day.weekday} is still not a real session',
          );
        }
      }
    });

    test('keeps the split when a pull-up bar makes it trainable', () {
      final plan = generator.generate(
        request(
          daysPerWeek: 4,
          location: TrainingLocation.homeNone,
          extraEquipment: {Equipment.pullUpBar},
          level: Level.intermediate,
          sessionMinutes: 90,
        ),
      );
      expect(plan.templateId, 'upper_lower_4');
      expect(
        plan.notes.any((n) => n.kind == PlanNoteKind.templateSimplified),
        isFalse,
      );
    });

    test('does not announce a simplification that changes nothing', () {
      // Two and three days are full body anyway, so there is nothing to tell
      // the user about.
      for (final days in [2, 3]) {
        final plan = generator.generate(
          request(
            daysPerWeek: days,
            location: TrainingLocation.homeNone,
            sessionMinutes: 60,
          ),
        );
        expect(
          plan.notes.any((n) => n.kind == PlanNoteKind.templateSimplified),
          isFalse,
        );
      }
    });

    test('flags nothing thin for a bodyweight full-body week', () {
      // Three full-body days is the right prescription for this user, and it
      // should come out clean apart from the missing pull.
      final plan = generator.generate(
        request(
          daysPerWeek: 3,
          location: TrainingLocation.homeNone,
          sessionMinutes: 60,
        ),
      );
      expect(
        plan.notes.where((n) => n.kind == PlanNoteKind.dayUnderfilled),
        isEmpty,
      );
    });

    test('reports no gaps for a full gym', () {
      final plan = generator.generate(
        request(daysPerWeek: 6, sessionMinutes: 90, level: Level.advanced),
      );
      expect(
        plan.notes.where((n) => n.kind == PlanNoteKind.unfilledSlot),
        isEmpty,
      );
    });
  });

  group('running days', () {
    test('schedules nothing on a run day when the week has room', () {
      final plan = generator.generate(
        request(goal: Goal.hybrid, daysPerWeek: 3, runWeekdays: {1, 5}),
      );
      expect(
        plan.days.map((d) => d.weekday).toSet().intersection({1, 5}),
        isEmpty,
      );
    });

    test('reduces leg volume on a day that precedes a run', () {
      final plan = generator.generate(
        request(
          goal: Goal.hybrid,
          daysPerWeek: 3,
          sessionMinutes: 90,
          runWeekdays: {2, 4, 6},
        ),
      );
      final preRun = plan.days.where((d) => d.precedesRunDay).toList();
      expect(preRun, isNotEmpty);

      for (final day in preRun) {
        for (final planned in day.exercises) {
          if (planned.slotPattern.isLegDominant &&
              planned.priority == SlotPriority.primary) {
            expect(
              planned.sets,
              lessThanOrEqualTo(2),
              reason: 'heavy leg work left on pre-run day ${day.weekday}',
            );
          }
        }
      }
      expect(
        plan.notes.any((n) => n.kind == PlanNoteKind.legVolumeReducedForRun),
        isTrue,
      );
    });

    test('leaves leg volume alone when no run follows', () {
      final plan = generator.generate(
        request(goal: Goal.hybrid, daysPerWeek: 3, sessionMinutes: 90),
      );
      final squat = plan.days.first.exercises.firstWhere(
        (e) => e.slotPattern == MovementPattern.squat,
      );
      expect(
        squat.sets,
        greaterThan(DayRules.preRunLegSetCap),
        reason: 'leg volume was cut with no run to cut it for',
      );
      expect(
        plan.notes.any((n) => n.kind == PlanNoteKind.legVolumeReducedForRun),
        isFalse,
      );
    });

    test('offers running suggestions only for the hybrid goal', () {
      final hybrid = generator.generate(
        request(goal: Goal.hybrid, runWeekdays: {3}),
      );
      expect(hybrid.runSuggestionKeys, isNotEmpty);
      expect(hybrid.runWeekdays, {3});

      final lifting = generator.generate(
        request(goal: Goal.muscleBuilding, runWeekdays: {3}),
      );
      expect(lifting.runSuggestionKeys, isEmpty);
    });

    test('scales the running suggestion to experience', () {
      String keyFor(Level level) => generator
          .generate(
            request(goal: Goal.hybrid, level: level, runWeekdays: {3}),
          )
          .runSuggestionKeys
          .first;

      expect(keyFor(Level.beginner), isNot(keyFor(Level.advanced)));
      for (final level in Level.values) {
        expect(keyFor(level), matches(RegExp(r'^run_suggestion_[a-z_0-9]+$')));
      }
    });
  });

  group('validation', () {
    test('rejects an unsupported training frequency', () {
      expect(
        () => generator.generate(request(daysPerWeek: 7)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an impossibly short session', () {
      expect(
        () => generator.generate(request(sessionMinutes: 5)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a run day outside the week', () {
      expect(
        () => generator.generate(request(runWeekdays: {0})),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => generator.generate(request(runWeekdays: {8})),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
