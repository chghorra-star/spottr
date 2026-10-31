import 'package:collection/collection.dart';
import 'package:exercise_library/exercise_library.dart';

import 'day_rules.dart';
import 'plan_request.dart';
import 'progression.dart';
import 'week_plan.dart';

/// User edits to a generated plan: swapping an exercise, reordering a day,
/// and moving a day to another weekday.
///
/// Every operation returns a new plan and re-applies [DayRules], so an edited
/// plan is indistinguishable from a generated one. In particular a day moved
/// onto the night before a run has its leg volume cut, and a day moved clear
/// of a run gets it back.
class PlanEdits {
  const PlanEdits(this.catalog);

  final ExerciseCatalog catalog;

  /// Exercises the user could swap in for [exerciseId] on [weekday].
  ///
  /// Curated alternatives for the same job, filtered to what this user can
  /// actually do, minus anything already in that day.
  List<Exercise> alternativesFor({
    required WeekPlan plan,
    required int weekday,
    required String exerciseId,
    required PlanRequest request,
  }) {
    final day = _dayOn(plan, weekday);
    final idsToday = day.exercises.map((e) => e.exerciseId).toSet();

    return catalog
        .alternativesFor(
          exerciseId,
          available: request.availableEquipment,
          injuries: request.injuries,
          level: request.level,
        )
        .where((exercise) => !idsToday.contains(exercise.id))
        .toList();
  }

  /// Replaces [exerciseId] with [replacementId] in the same slot.
  ///
  /// The replacement keeps the slot's pattern, priority and set count, but
  /// its prescription is rebuilt from scratch: swapping a rep-counted
  /// exercise for a hold has to change reps into seconds.
  WeekPlan swapExercise({
    required WeekPlan plan,
    required int weekday,
    required String exerciseId,
    required String replacementId,
    required PlanRequest request,
  }) {
    final day = _dayOn(plan, weekday);
    final index = day.exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (index < 0) {
      throw ArgumentError.value(
        exerciseId,
        'exerciseId',
        'Not prescribed on weekday $weekday',
      );
    }

    final replacement = catalog[replacementId];
    if (replacement == null) {
      throw ArgumentError.value(
        replacementId,
        'replacementId',
        'No exercise with that id',
      );
    }
    if (day.exercises.any((e) => e.exerciseId == replacementId)) {
      throw ArgumentError.value(
        replacementId,
        'replacementId',
        'Already prescribed on weekday $weekday',
      );
    }
    if (!replacement.isAvailableWith(request.availableEquipment)) {
      throw ArgumentError.value(
        replacementId,
        'replacementId',
        'Needs equipment the user does not have',
      );
    }
    if (!replacement.isSafeFor(request.injuries)) {
      throw ArgumentError.value(
        replacementId,
        'replacementId',
        'Contraindicated by a declared injury',
      );
    }
    if (!replacement.suitsLevel(request.level)) {
      throw ArgumentError.value(
        replacementId,
        'replacementId',
        'Above the user experience level',
      );
    }

    final slot = day.exercises[index];
    final exercises = [...day.exercises];
    exercises[index] = DayRules.prescribe(
      exercise: replacement,
      slotPattern: slot.slotPattern,
      priority: slot.priority,
      templateSets: slot.templateSets,
      request: request,
    );

    return _replaceDay(
      plan: plan,
      updated: day.copyWith(exercises: exercises),
      request: request,
    );
  }

  /// Moves the exercise at [fromIndex] to [toIndex] within one day.
  WeekPlan reorderExercise({
    required WeekPlan plan,
    required int weekday,
    required int fromIndex,
    required int toIndex,
  }) {
    final day = _dayOn(plan, weekday);
    final count = day.exercises.length;

    if (fromIndex < 0 || fromIndex >= count) {
      throw RangeError.index(fromIndex, day.exercises, 'fromIndex');
    }
    if (toIndex < 0 || toIndex >= count) {
      throw RangeError.index(toIndex, day.exercises, 'toIndex');
    }
    if (fromIndex == toIndex) return plan;

    final exercises = [...day.exercises];
    final moved = exercises.removeAt(fromIndex);
    exercises.insert(toIndex, moved);

    // Reordering changes nothing about the prescription, so the day rules
    // are deliberately not re-applied: a day the user trimmed by hand should
    // not spring back to full volume because they dragged a row.
    final days = [
      for (final existing in plan.days)
        if (existing.weekday == weekday)
          day.copyWith(exercises: exercises)
        else
          existing,
    ];
    return plan.copyWith(days: days);
  }

  /// Moves a whole session from one weekday to another free weekday.
  WeekPlan moveDay({
    required WeekPlan plan,
    required int fromWeekday,
    required int toWeekday,
    required PlanRequest request,
  }) {
    if (toWeekday < 1 || toWeekday > 7) {
      throw ArgumentError.value(
        toWeekday,
        'toWeekday',
        'Weekdays are ISO, 1 (Monday) to 7 (Sunday)',
      );
    }
    final day = _dayOn(plan, fromWeekday);
    if (fromWeekday == toWeekday) return plan;

    if (plan.days.any((d) => d.weekday == toWeekday)) {
      throw ArgumentError.value(
        toWeekday,
        'toWeekday',
        'Already has a session',
      );
    }

    final moved = PlannedDay(
      weekday: toWeekday,
      type: day.type,
      labelKey: day.labelKey,
      precedesRunDay: request.runWeekdays.contains(_nextDay(toWeekday)),
      exercises: day.exercises,
    );

    return _replaceDay(
      plan: plan,
      updated: moved,
      request: request,
      replacingWeekday: fromWeekday,
    );
  }

  /// Writes the next prescription for a day that has just been trained.
  ///
  /// Decisions come from [Progression]; this only moves the numbers into the
  /// plan. A decision whose exercise is no longer in the day is dropped
  /// rather than treated as an error: the user is free to swap something out
  /// between training it and finishing the session.
  ///
  /// The day rules are deliberately **not** re-applied. They own volume, and
  /// re-running them here could trim away the very exercise progression just
  /// advanced, or fill the freed time with something else. The cost is that a
  /// variant with a different tempo can move the session estimate by a minute
  /// or so; a progression that deleted work to stay on budget would be far
  /// worse than a day that reads 61 minutes.
  WeekPlan applyProgression({
    required WeekPlan plan,
    required int weekday,
    required List<ProgressionDecision> decisions,
    required PlanRequest request,
  }) {
    final day = _dayOn(plan, weekday);
    if (decisions.isEmpty) return plan;

    final byId = {
      for (final decision in decisions) decision.exerciseId: decision,
    };

    final exercises = [
      for (final exercise in day.exercises)
        _progressed(exercise, byId[exercise.exerciseId], request),
    ];

    final days = [
      for (final existing in plan.days)
        if (existing.weekday == weekday)
          day.copyWith(exercises: exercises)
        else
          existing,
    ];
    return plan.copyWith(days: days);
  }

  PlannedExercise _progressed(
    PlannedExercise exercise,
    ProgressionDecision? decision,
    PlanRequest request,
  ) {
    if (decision == null) return exercise;

    final nextId = decision.nextExerciseId;
    if (nextId != null) {
      final replacement = catalog[nextId];
      // A ladder pointing at nothing is a catalog bug the validator should
      // have caught. Here it means "leave the user where they are", which is
      // the right answer mid-session either way.
      if (replacement == null) return exercise;
      return DayRules.prescribe(
        exercise: replacement,
        slotPattern: exercise.slotPattern,
        priority: exercise.priority,
        templateSets: exercise.templateSets,
        request: request,
      ).copyWith(sets: exercise.sets);
    }

    return exercise.copyWith(
      targetWeightKg: decision.nextWeightKg,
      repsMin: decision.nextRepsMin,
      repsMax: decision.nextRepsMax,
      holdSeconds: decision.nextHoldSeconds,
    );
  }

  /// Puts [updated] back into the plan, re-applying the day rules and
  /// refreshing the notes that belong to it.
  WeekPlan _replaceDay({
    required WeekPlan plan,
    required PlannedDay updated,
    required PlanRequest request,
    int? replacingWeekday,
  }) {
    final oldWeekday = replacingWeekday ?? updated.weekday;
    final result = DayRules.apply(updated, request, catalog);

    final days = [
      for (final existing in plan.days)
        if (existing.weekday != oldWeekday) existing,
      result.day,
    ]..sort((a, b) => a.weekday.compareTo(b.weekday));

    // Stale rule notes for either weekday would otherwise outlive the edit.
    final notes = [
      ...plan.notes.where(
        (note) =>
            !_isRuleNote(note) ||
            (note.weekday != oldWeekday && note.weekday != updated.weekday),
      ),
      ...result.notes,
    ];

    return plan.copyWith(days: days, notes: notes);
  }

  /// Notes that [DayRules] regenerates and therefore owns.
  static bool _isRuleNote(PlanNote note) =>
      note.kind == PlanNoteKind.legVolumeReducedForRun ||
      note.kind == PlanNoteKind.trimmedForTime;

  PlannedDay _dayOn(WeekPlan plan, int weekday) {
    final day = plan.days.firstWhereOrNull((d) => d.weekday == weekday);
    if (day == null) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'No session on that weekday',
      );
    }
    return day;
  }

  static int _nextDay(int weekday) => (weekday % 7) + 1;
}
