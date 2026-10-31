import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

final generator = PlanGenerator(standardCatalog);
final edits = PlanEdits(standardCatalog);

PlanRequest request({
  Goal goal = Goal.muscleBuilding,
  int daysPerWeek = 3,
  int sessionMinutes = 90,
  Level level = Level.intermediate,
  TrainingLocation location = TrainingLocation.fullGym,
  Set<BodyPart> injuries = const {},
  Set<int> runWeekdays = const {},
}) =>
    PlanRequest(
      goal: goal,
      daysPerWeek: daysPerWeek,
      sessionMinutes: sessionMinutes,
      level: level,
      location: location,
      injuries: injuries,
      runWeekdays: runWeekdays,
    );

List<String> idsOn(WeekPlan plan, int weekday) => plan.days
    .firstWhere((d) => d.weekday == weekday)
    .exercises
    .map((e) => e.exerciseId)
    .toList();

void main() {
  group('suggested alternatives', () {
    test('offers swaps for an exercise in the plan', () {
      final req = request();
      final plan = generator.generate(req);
      final squat = plan.days.first.exercises.first;

      final options = edits.alternativesFor(
        plan: plan,
        weekday: plan.days.first.weekday,
        exerciseId: squat.exerciseId,
        request: req,
      );

      expect(options, isNotEmpty);
      expect(options.map((e) => e.id), isNot(contains(squat.exerciseId)));
    });

    test('never offers something already in that day', () {
      final req = request();
      final plan = generator.generate(req);
      final day = plan.days.first;

      for (final planned in day.exercises) {
        final options = edits.alternativesFor(
          plan: plan,
          weekday: day.weekday,
          exerciseId: planned.exerciseId,
          request: req,
        );
        final idsToday = day.exercises.map((e) => e.exerciseId).toSet();
        expect(
          options.map((e) => e.id).toSet().intersection(idsToday),
          isEmpty,
        );
      }
    });

    test('never offers something the user cannot do', () {
      final req = request(
        location: TrainingLocation.homeDumbbells,
        injuries: {BodyPart.knees},
        level: Level.beginner,
      );
      final plan = generator.generate(req);

      for (final day in plan.days) {
        for (final planned in day.exercises) {
          final options = edits.alternativesFor(
            plan: plan,
            weekday: day.weekday,
            exerciseId: planned.exerciseId,
            request: req,
          );
          for (final option in options) {
            expect(option.isSafeFor({BodyPart.knees}), isTrue);
            expect(option.isAvailableWith(req.availableEquipment), isTrue);
            expect(option.suitsLevel(Level.beginner), isTrue);
          }
        }
      }
    });
  });

  group('swapExercise', () {
    test('replaces the exercise in place', () {
      final req = request();
      final plan = generator.generate(req);
      final weekday = plan.days.first.weekday;
      final original = idsOn(plan, weekday);
      final target = original.first;

      final replacement = edits
          .alternativesFor(
            plan: plan,
            weekday: weekday,
            exerciseId: target,
            request: req,
          )
          .first;

      final updated = edits.swapExercise(
        plan: plan,
        weekday: weekday,
        exerciseId: target,
        replacementId: replacement.id,
        request: req,
      );

      final after = idsOn(updated, weekday);
      expect(after.first, replacement.id);
      expect(after.length, original.length);
      expect(after.sublist(1), original.sublist(1));
    });

    test('keeps the slot it was filling', () {
      final req = request();
      final plan = generator.generate(req);
      final weekday = plan.days.first.weekday;
      final before = plan.days.first.exercises.first;

      final replacement = edits
          .alternativesFor(
            plan: plan,
            weekday: weekday,
            exerciseId: before.exerciseId,
            request: req,
          )
          .first;

      final updated = edits.swapExercise(
        plan: plan,
        weekday: weekday,
        exerciseId: before.exerciseId,
        replacementId: replacement.id,
        request: req,
      );
      final after = updated.days.first.exercises.first;

      expect(after.slotPattern, before.slotPattern);
      expect(after.priority, before.priority);
      expect(after.sets, before.sets);
      expect(after.templateSets, before.templateSets);
    });

    test('re-prescribes when the metric changes', () {
      // Swapping a rep-counted core exercise for a hold has to change the
      // prescription, or the UI would ask for 12 reps of a plank.
      final req = request(location: TrainingLocation.homeNone);
      final plan = generator.generate(req);
      final day = plan.days.first;
      final core = day.exercises.firstWhere(
        (e) => e.slotPattern == MovementPattern.core,
      );
      expect(core.metric, MetricType.holdSeconds); // plank

      final updated = edits.swapExercise(
        plan: plan,
        weekday: day.weekday,
        exerciseId: core.exerciseId,
        replacementId: 'dead_bug',
        request: req,
      );
      final after = updated.days.first.exercises.firstWhere(
        (e) => e.exerciseId == 'dead_bug',
      );

      expect(after.metric, MetricType.reps);
      expect(after.holdSeconds, isNull);
      expect(after.repsMin, req.prescription.accessoryRepsMin);
    });

    test('rejects a replacement the user has no equipment for', () {
      final req = request(location: TrainingLocation.homeNone);
      final plan = generator.generate(req);
      final day = plan.days.first;

      expect(
        () => edits.swapExercise(
          plan: plan,
          weekday: day.weekday,
          exerciseId: day.exercises.first.exerciseId,
          replacementId: 'barbell_back_squat',
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a replacement contraindicated by an injury', () {
      final req = request(injuries: {BodyPart.knees});
      final plan = generator.generate(req);
      final day = plan.days.first;

      expect(
        () => edits.swapExercise(
          plan: plan,
          weekday: day.weekday,
          exerciseId: day.exercises.first.exerciseId,
          replacementId: 'leg_press',
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a replacement above the user level', () {
      final req = request(level: Level.beginner);
      final plan = generator.generate(req);
      final day = plan.days.first;

      expect(
        () => edits.swapExercise(
          plan: plan,
          weekday: day.weekday,
          exerciseId: day.exercises.first.exerciseId,
          replacementId: 'barbell_back_squat',
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a replacement already in that day', () {
      final req = request();
      final plan = generator.generate(req);
      final day = plan.days.first;
      final ids = day.exercises.map((e) => e.exerciseId).toList();

      expect(
        () => edits.swapExercise(
          plan: plan,
          weekday: day.weekday,
          exerciseId: ids.first,
          replacementId: ids[1],
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an exercise that is not in that day', () {
      final req = request();
      final plan = generator.generate(req);

      expect(
        () => edits.swapExercise(
          plan: plan,
          weekday: plan.days.first.weekday,
          exerciseId: 'superman',
          replacementId: 'calf_raise',
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an unknown replacement id', () {
      final req = request();
      final plan = generator.generate(req);
      final day = plan.days.first;

      expect(
        () => edits.swapExercise(
          plan: plan,
          weekday: day.weekday,
          exerciseId: day.exercises.first.exerciseId,
          replacementId: 'jazzercise',
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('leaves the other days untouched', () {
      final req = request();
      final plan = generator.generate(req);
      final weekday = plan.days.first.weekday;
      final target = plan.days.first.exercises.first.exerciseId;
      final replacement = edits
          .alternativesFor(
            plan: plan,
            weekday: weekday,
            exerciseId: target,
            request: req,
          )
          .first;

      final updated = edits.swapExercise(
        plan: plan,
        weekday: weekday,
        exerciseId: target,
        replacementId: replacement.id,
        request: req,
      );

      for (final day in plan.days.skip(1)) {
        expect(idsOn(updated, day.weekday), idsOn(plan, day.weekday));
      }
    });
  });

  group('reorderExercise', () {
    test('moves an exercise to a new position', () {
      final plan = generator.generate(request());
      final weekday = plan.days.first.weekday;
      final before = idsOn(plan, weekday);

      final updated = edits.reorderExercise(
        plan: plan,
        weekday: weekday,
        fromIndex: 0,
        toIndex: 2,
      );
      final after = idsOn(updated, weekday);

      expect(after[2], before[0]);
      expect(after.toSet(), before.toSet());
      expect(after.length, before.length);
    });

    test('is a no-op when the indices match', () {
      final plan = generator.generate(request());
      final weekday = plan.days.first.weekday;
      final updated = edits.reorderExercise(
        plan: plan,
        weekday: weekday,
        fromIndex: 1,
        toIndex: 1,
      );
      expect(idsOn(updated, weekday), idsOn(plan, weekday));
    });

    test('rejects an index outside the day', () {
      final plan = generator.generate(request());
      final weekday = plan.days.first.weekday;

      expect(
        () => edits.reorderExercise(
          plan: plan,
          weekday: weekday,
          fromIndex: 0,
          toIndex: 99,
        ),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => edits.reorderExercise(
          plan: plan,
          weekday: weekday,
          fromIndex: -1,
          toIndex: 0,
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('moveDay', () {
    test('moves a day to a free weekday and keeps the week ordered', () {
      final req = request();
      final plan = generator.generate(req); // Mon/Wed/Fri
      final updated = edits.moveDay(
        plan: plan,
        fromWeekday: 1,
        toWeekday: 2,
        request: req,
      );

      final weekdays = updated.days.map((d) => d.weekday).toList();
      expect(weekdays, [2, 3, 5]);
      expect(weekdays, orderedEquals(List<int>.from(weekdays)..sort()));
    });

    test('carries the session with it', () {
      final req = request();
      final plan = generator.generate(req);
      final before = idsOn(plan, 1);

      final updated = edits.moveDay(
        plan: plan,
        fromWeekday: 1,
        toWeekday: 2,
        request: req,
      );
      expect(idsOn(updated, 2), before);
    });

    test('rejects moving onto an occupied weekday', () {
      final req = request();
      final plan = generator.generate(req);
      expect(
        () => edits.moveDay(
          plan: plan,
          fromWeekday: 1,
          toWeekday: 3,
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a weekday outside the week', () {
      final req = request();
      final plan = generator.generate(req);
      expect(
        () => edits.moveDay(
          plan: plan,
          fromWeekday: 1,
          toWeekday: 0,
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects moving a day that is not in the plan', () {
      final req = request();
      final plan = generator.generate(req);
      expect(
        () => edits.moveDay(
          plan: plan,
          fromWeekday: 2,
          toWeekday: 6,
          request: req,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cuts leg volume when the day lands before a run', () {
      // Training Mon/Wed/Fri with a Sunday run, then moving Friday to
      // Saturday puts a full-body day the night before the run.
      final req = request(goal: Goal.hybrid, runWeekdays: {7});
      final plan = generator.generate(req);

      final friday = plan.days.firstWhere((d) => d.weekday == 5);
      final squatBefore = friday.exercises.firstWhere(
        (e) => e.slotPattern == MovementPattern.squat,
      );
      expect(squatBefore.sets, greaterThan(DayRules.preRunLegSetCap));

      final updated = edits.moveDay(
        plan: plan,
        fromWeekday: 5,
        toWeekday: 6,
        request: req,
      );
      final saturday = updated.days.firstWhere((d) => d.weekday == 6);

      expect(saturday.precedesRunDay, isTrue);
      final squatAfter = saturday.exercises.firstWhere(
        (e) => e.slotPattern == MovementPattern.squat,
      );
      expect(squatAfter.sets, DayRules.preRunLegSetCap);
      expect(
        updated.notes.any(
          (n) =>
              n.kind == PlanNoteKind.legVolumeReducedForRun && n.weekday == 6,
        ),
        isTrue,
      );
    });

    test('restores leg volume when the day moves away from a run', () {
      final req = request(goal: Goal.hybrid, runWeekdays: {7});
      final plan = generator.generate(req);

      // Put a day before the run first, then move it clear again.
      final onto = edits.moveDay(
        plan: plan,
        fromWeekday: 5,
        toWeekday: 6,
        request: req,
      );
      final away = edits.moveDay(
        plan: onto,
        fromWeekday: 6,
        toWeekday: 4,
        request: req,
      );

      final thursday = away.days.firstWhere((d) => d.weekday == 4);
      expect(thursday.precedesRunDay, isFalse);
      expect(
        thursday.exercises
            .firstWhere((e) => e.slotPattern == MovementPattern.squat)
            .sets,
        greaterThan(DayRules.preRunLegSetCap),
        reason: 'leg volume should come back once the run is clear',
      );
      expect(
        away.notes.any(
          (n) =>
              n.kind == PlanNoteKind.legVolumeReducedForRun && n.weekday == 4,
        ),
        isFalse,
      );
    });

    test('keeps the moved day inside its time budget', () {
      final req = request(sessionMinutes: 30);
      final plan = generator.generate(req);
      final updated = edits.moveDay(
        plan: plan,
        fromWeekday: 1,
        toWeekday: 2,
        request: req,
      );
      for (final day in updated.days) {
        expect(day.estimatedSeconds, lessThanOrEqualTo(30 * 60));
      }
    });
  });

  group('applying progression', () {
    /// The plan and the first exercise of its first day, which every case
    /// below progresses one way or another.
    ({WeekPlan plan, PlannedExercise first, int weekday}) start() {
      final plan = generator.generate(request());
      final day = plan.days.first;
      return (plan: plan, first: day.exercises.first, weekday: day.weekday);
    }

    WeekPlan apply(
      ({WeekPlan plan, PlannedExercise first, int weekday}) from,
      ProgressionDecision decision,
    ) =>
        edits.applyProgression(
          plan: from.plan,
          weekday: from.weekday,
          decisions: [decision],
          request: request(),
        );

    test('a load increase lands on the target weight and nothing else', () {
      final from = start();
      final after = apply(
        from,
        ProgressionDecision(
          exerciseId: from.first.exerciseId,
          change: ProgressionChange.loadUp,
          reason: ProgressionReason.earnedLoad,
          nextWeightKg: 62.5,
        ),
      );

      final updated = after.days.first.exercises.first;
      expect(updated.targetWeightKg, 62.5);
      expect(updated.exerciseId, from.first.exerciseId);
      expect(updated.sets, from.first.sets);
      expect(updated.repsMin, from.first.repsMin);
      expect(updated.repsMax, from.first.repsMax);
    });

    test('a rep increase rewrites the range', () {
      final from = start();
      final after = apply(
        from,
        ProgressionDecision(
          exerciseId: from.first.exerciseId,
          change: ProgressionChange.repsUp,
          reason: ProgressionReason.earnedReps,
          nextRepsMin: 10,
          nextRepsMax: 14,
        ),
      );

      final updated = after.days.first.exercises.first;
      expect(updated.repsMin, 10);
      expect(updated.repsMax, 14);
    });

    test('a hold increase rewrites the seconds', () {
      final plan = generator.generate(request());
      final day = plan.days.firstWhere(
        (d) => d.exercises.any((e) => e.metric == MetricType.holdSeconds),
      );
      final held = day.exercises
          .firstWhere((e) => e.metric == MetricType.holdSeconds);

      final after = edits.applyProgression(
        plan: plan,
        weekday: day.weekday,
        decisions: [
          ProgressionDecision(
            exerciseId: held.exerciseId,
            change: ProgressionChange.holdUp,
            reason: ProgressionReason.earnedHold,
            nextHoldSeconds: (held.holdSeconds ?? 0) + 5,
          ),
        ],
        request: request(),
      );

      final updated = after.days
          .firstWhere((d) => d.weekday == day.weekday)
          .exercises
          .firstWhere((e) => e.exerciseId == held.exerciseId);
      expect(updated.holdSeconds, (held.holdSeconds ?? 0) + 5);
    });

    test('a variant change keeps the slot and re-prescribes the exercise', () {
      final from = start();
      final harder =
          standardCatalog.require(from.first.exerciseId).harderId ??
              standardCatalog.require(from.first.exerciseId).easierId;
      expect(harder, isNotNull, reason: 'premise: the squat has a ladder');

      final after = apply(
        from,
        ProgressionDecision(
          exerciseId: from.first.exerciseId,
          change: ProgressionChange.harderVariant,
          reason: ProgressionReason.earnedHarderVariant,
          nextExerciseId: harder,
        ),
      );

      final updated = after.days.first.exercises.first;
      expect(updated.exerciseId, harder);
      expect(updated.slotPattern, from.first.slotPattern);
      expect(updated.priority, from.first.priority);
      expect(updated.sets, from.first.sets);
      // A new exercise starts at its own prescription, not the old one's
      // accumulated load.
      expect(updated.targetWeightKg, isNull);
    });

    test('a variant the catalog does not know is ignored', () {
      final from = start();
      final after = apply(
        from,
        ProgressionDecision(
          exerciseId: from.first.exerciseId,
          change: ProgressionChange.harderVariant,
          reason: ProgressionReason.earnedHarderVariant,
          nextExerciseId: 'levitating_squat',
        ),
      );

      expect(after.days.first.exercises.first, from.first);
    });

    test('a hold leaves the plan exactly as it was', () {
      final from = start();
      final after = apply(
        from,
        ProgressionDecision(
          exerciseId: from.first.exerciseId,
          change: ProgressionChange.hold,
          reason: ProgressionReason.holdingSteady,
        ),
      );

      expect(after, from.plan);
    });

    test('a decision about an exercise no longer there is ignored', () {
      // The user can swap an exercise out between training it and finishing
      // the session. That is not an error, it is just nothing to apply.
      final from = start();
      final after = apply(
        from,
        const ProgressionDecision(
          exerciseId: 'seated_calf_raise',
          change: ProgressionChange.loadUp,
          reason: ProgressionReason.earnedLoad,
          nextWeightKg: 40,
        ),
      );

      expect(after, from.plan);
    });

    test('progression never changes how much work a day holds', () {
      final from = start();
      final after = edits.applyProgression(
        plan: from.plan,
        weekday: from.weekday,
        decisions: [
          for (final exercise in from.plan.days.first.exercises)
            ProgressionDecision(
              exerciseId: exercise.exerciseId,
              change: ProgressionChange.loadUp,
              reason: ProgressionReason.earnedLoad,
              nextWeightKg: 100,
            ),
        ],
        request: request(),
      );

      final before = from.plan.days.first;
      final day = after.days.first;
      expect(day.exercises.map((e) => e.exerciseId),
          before.exercises.map((e) => e.exerciseId));
      expect(day.exercises.map((e) => e.sets), before.exercises.map((e) => e.sets));
    });

    test('other days are left alone', () {
      final from = start();
      final after = apply(
        from,
        ProgressionDecision(
          exerciseId: from.first.exerciseId,
          change: ProgressionChange.loadUp,
          reason: ProgressionReason.earnedLoad,
          nextWeightKg: 62.5,
        ),
      );

      expect(after.days.skip(1).toList(), from.plan.days.skip(1).toList());
    });

    test('applying the same decisions twice changes nothing more', () {
      final from = start();
      final decision = ProgressionDecision(
        exerciseId: from.first.exerciseId,
        change: ProgressionChange.loadUp,
        reason: ProgressionReason.earnedLoad,
        nextWeightKg: 62.5,
      );
      final once = apply(from, decision);
      final twice = edits.applyProgression(
        plan: once,
        weekday: from.weekday,
        decisions: [decision],
        request: request(),
      );

      expect(twice, once);
    });

    test('an unknown weekday is a mistake, not a silent no-op', () {
      final from = start();
      expect(
        () => edits.applyProgression(
          plan: from.plan,
          weekday: 99,
          decisions: const [],
          request: request(),
        ),
        throwsArgumentError,
      );
    });
  });
}
