import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';

import 'plan_request.dart';
import 'templates.dart';
import 'week_plan.dart';

/// A day after the prescription rules have been applied, with whatever the
/// rules want to tell the user.
@immutable
class DayRulesResult {
  const DayRulesResult(this.day, this.notes);

  final PlannedDay day;
  final List<PlanNote> notes;
}

/// Rules that turn a day's template slots into an actual prescription.
///
/// Shared by the generator and by every plan edit, so that moving a day or
/// swapping an exercise produces exactly what generating it would have. The
/// rules derive from [PlannedExercise.templateSets] rather than from the
/// current set count, which makes them idempotent: applying them twice is
/// the same as applying them once, and a day that moves away from a run gets
/// its volume back.
abstract final class DayRules {
  /// Most sets of leg-dominant compound work allowed the day before a run.
  ///
  /// The brief asks to avoid *heavy* leg work before a run, not to skip legs
  /// entirely, so volume comes down rather than the session losing its
  /// purpose.
  static const int preRunLegSetCap = 2;

  /// Minimum sets a trimmed exercise keeps before it is dropped instead.
  static const int minimumSets = 2;

  static DayRulesResult apply(PlannedDay day, PlanRequest request) {
    final notes = <PlanNote>[];
    var exercises = [
      for (final exercise in day.exercises)
        _applyRunRule(exercise, day, notes),
    ];

    exercises = _fitToBudget(exercises, day.weekday, request, notes);

    return DayRulesResult(day.copyWith(exercises: exercises), notes);
  }

  static PlannedExercise _applyRunRule(
    PlannedExercise exercise,
    PlannedDay day,
    List<PlanNote> notes,
  ) {
    final shouldCap = day.precedesRunDay &&
        exercise.isPrimary &&
        exercise.slotPattern.isLegDominant &&
        exercise.templateSets > preRunLegSetCap;

    if (!shouldCap) {
      // Reset to the template, so a day that moved clear of a run recovers.
      return exercise.copyWith(sets: exercise.templateSets);
    }

    notes.add(
      PlanNote(
        PlanNoteKind.legVolumeReducedForRun,
        exercise.exerciseId,
        weekday: day.weekday,
      ),
    );
    return exercise.copyWith(sets: preRunLegSetCap);
  }

  /// Trims until the day fits its budget.
  ///
  /// Accessories go first, then set counts come down, and only then is a
  /// compound dropped. The session should get shorter without losing the
  /// reason it exists.
  static List<PlannedExercise> _fitToBudget(
    List<PlannedExercise> original,
    int weekday,
    PlanRequest request,
    List<PlanNote> notes,
  ) {
    final budget = request.sessionMinutes * 60;
    final exercises = [...original];

    int total() =>
        PlannedDay.warmupSeconds +
        exercises.fold(0, (sum, e) => sum + e.estimatedSeconds);

    while (total() > budget && exercises.isNotEmpty) {
      final lastAccessory = exercises.lastIndexWhere((e) => !e.isPrimary);
      if (lastAccessory >= 0) {
        notes.add(
          PlanNote(
            PlanNoteKind.trimmedForTime,
            exercises[lastAccessory].exerciseId,
            weekday: weekday,
          ),
        );
        exercises.removeAt(lastAccessory);
        continue;
      }

      final maxSets = exercises
          .map((e) => e.sets)
          .reduce((a, b) => a > b ? a : b);
      if (maxSets > minimumSets) {
        final index = exercises.lastIndexWhere((e) => e.sets == maxSets);
        exercises[index] = exercises[index].copyWith(sets: maxSets - 1);
        continue;
      }

      if (exercises.length > 1) {
        notes.add(
          PlanNote(
            PlanNoteKind.trimmedForTime,
            exercises.last.exerciseId,
            weekday: weekday,
          ),
        );
        exercises.removeLast();
        continue;
      }

      // A single exercise at minimum sets that still overruns means the
      // request itself is unreasonable. A short session beats no session.
      break;
    }

    return exercises;
  }

  /// Builds a prescription for [exercise] in the slot described by [slot].
  ///
  /// Used when filling a template slot and when swapping an exercise, so a
  /// swap that changes the metric is re-prescribed rather than inheriting
  /// rep targets that make no sense for a hold.
  static PlannedExercise prescribe({
    required Exercise exercise,
    required MovementPattern slotPattern,
    required SlotPriority priority,
    required int templateSets,
    required PlanRequest request,
  }) {
    final prescription = request.prescription;
    final isCompound = priority == SlotPriority.primary;

    if (exercise.metric == MetricType.holdSeconds) {
      return PlannedExercise(
        exerciseId: exercise.id,
        slotPattern: slotPattern,
        priority: priority,
        sets: templateSets,
        templateSets: templateSets,
        metric: MetricType.holdSeconds,
        restSeconds: prescription.restSeconds,
        secondsPerRep: exercise.secondsPerRep,
        holdSeconds: prescription.holdSeconds,
      );
    }

    return PlannedExercise(
      exerciseId: exercise.id,
      slotPattern: slotPattern,
      priority: priority,
      sets: templateSets,
      templateSets: templateSets,
      metric: MetricType.reps,
      restSeconds: prescription.restSeconds,
      secondsPerRep: exercise.secondsPerRep,
      repsMin: isCompound
          ? prescription.compoundRepsMin
          : prescription.accessoryRepsMin,
      repsMax: isCompound
          ? prescription.compoundRepsMax
          : prescription.accessoryRepsMax,
    );
  }
}
