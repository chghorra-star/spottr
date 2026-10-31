import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

/// Value equality exists so that a plan which has been through persistence,
/// or through an edit that should have changed nothing, can be compared in
/// one expectation instead of field by field. A round-trip test that only
/// compares a few fields passes while silently dropping the rest.
void main() {
  PlannedExercise exercise({
    String id = 'bodyweight_squat',
    int sets = 3,
    int templateSets = 3,
    MetricType metric = MetricType.reps,
    int? repsMin = 8,
    int? repsMax = 12,
    int? holdSeconds,
  }) =>
      PlannedExercise(
        exerciseId: id,
        slotPattern: MovementPattern.squat,
        priority: SlotPriority.primary,
        sets: sets,
        templateSets: templateSets,
        metric: metric,
        restSeconds: 75,
        secondsPerRep: 3,
        repsMin: repsMin,
        repsMax: repsMax,
        holdSeconds: holdSeconds,
      );

  PlannedDay day({
    int weekday = 1,
    bool precedesRunDay = false,
    List<PlannedExercise>? exercises,
  }) =>
      PlannedDay(
        weekday: weekday,
        type: DayType.fullBody,
        labelKey: 'day_full_body',
        precedesRunDay: precedesRunDay,
        exercises: exercises ?? [exercise()],
      );

  WeekPlan plan({
    List<PlannedDay>? days,
    Set<int> runWeekdays = const {},
    List<String> runSuggestionKeys = const [],
    List<PlanNote> notes = const [],
  }) =>
      WeekPlan(
        templateId: 'full_body_2',
        goal: Goal.muscleBuilding,
        days: days ?? [day(), day(weekday: 4)],
        runWeekdays: runWeekdays,
        runSuggestionKeys: runSuggestionKeys,
        notes: notes,
      );

  group('PlanNote', () {
    test('equal notes compare equal and hash alike', () {
      const a = PlanNote(PlanNoteKind.trimmedForTime, 'plank', weekday: 3);
      const b = PlanNote(PlanNoteKind.trimmedForTime, 'plank', weekday: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('every field participates', () {
      const base = PlanNote(PlanNoteKind.trimmedForTime, 'plank', weekday: 3);
      expect(
        base,
        isNot(const PlanNote(PlanNoteKind.unfilledSlot, 'plank', weekday: 3)),
      );
      expect(
        base,
        isNot(const PlanNote(PlanNoteKind.trimmedForTime, 'squat', weekday: 3)),
      );
      expect(
        base,
        isNot(const PlanNote(PlanNoteKind.trimmedForTime, 'plank')),
      );
    });
  });

  group('PlannedExercise', () {
    test('equal prescriptions compare equal and hash alike', () {
      expect(exercise(), exercise());
      expect(exercise().hashCode, exercise().hashCode);
    });

    test('sets and templateSets are distinguished', () {
      // A trimmed day and a full one must never compare equal: that is the
      // difference the pre-run leg cap and the time budget produce.
      expect(exercise(sets: 2), isNot(exercise()));
      expect(exercise(templateSets: 4), isNot(exercise()));
    });

    test('a hold is never equal to a rep prescription', () {
      final hold = exercise(
        metric: MetricType.holdSeconds,
        repsMin: null,
        repsMax: null,
        holdSeconds: 45,
      );
      expect(hold, isNot(exercise()));
      expect(
        hold,
        exercise(
          metric: MetricType.holdSeconds,
          repsMin: null,
          repsMax: null,
          holdSeconds: 45,
        ),
      );
    });

    test('rep bounds participate', () {
      expect(exercise(repsMin: 12, repsMax: 15), isNot(exercise()));
    });
  });

  group('PlannedDay', () {
    test('equal days compare equal and hash alike', () {
      expect(day(), day());
      expect(day().hashCode, day().hashCode);
    });

    test('exercise order matters', () {
      final a = day(exercises: [exercise(), exercise(id: 'push_up')]);
      final b = day(exercises: [exercise(id: 'push_up'), exercise()]);
      expect(a, isNot(b));
    });

    test('weekday and the pre-run flag participate', () {
      expect(day(weekday: 2), isNot(day()));
      expect(day(precedesRunDay: true), isNot(day()));
    });
  });

  group('WeekPlan', () {
    test('equal plans compare equal and hash alike', () {
      expect(plan(), plan());
      expect(plan().hashCode, plan().hashCode);
    });

    test('notes, run days and suggestions participate', () {
      expect(plan(runWeekdays: {6}), isNot(plan()));
      expect(plan(runSuggestionKeys: ['run_suggestion_easy_20']),
          isNot(plan()));
      expect(
        plan(notes: const [PlanNote(PlanNoteKind.unfilledSlot, 'squat')]),
        isNot(plan()),
      );
    });

    test('day order matters', () {
      expect(plan(days: [day(weekday: 4), day()]), isNot(plan()));
    });

    test('an untouched copyWith equals the original', () {
      final original = plan();
      expect(original.copyWith(), original);
    });
  });
}
