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

  /// Most sets an exercise is ever given, by the kind of slot it fills.
  ///
  /// This is what stops "use the time available" from turning into junk
  /// volume. Compound work earns the extra sets first and tops out highest;
  /// optional work is there to round out a long session, not to become the
  /// session. A day that reaches these caps and still has time left is as
  /// full as it is going to get, and the generator says so.
  static int maxSetsFor(SlotPriority priority) => switch (priority) {
        SlotPriority.primary => 5,
        SlotPriority.accessory => 4,
        SlotPriority.optional => 3,
      };

  /// Most working sets a single session is ever given.
  ///
  /// The per-exercise caps alone do not bound this: a nine-exercise gym day
  /// can reach them all and come to thirty-seven sets, which is not a long
  /// session but a bad one. Somebody who sets aside ninety minutes is better
  /// served by being told their session comes to seventy than by being given
  /// another seven sets they do not need.
  ///
  /// Optional slots start at [minimumSets] in the templates for the same
  /// reason this exists. If they started full they would spend the session's
  /// budget before the compounds had theirs, and filling would stop with the
  /// squat on three sets and the lateral raise on three.
  static const int maxWorkingSetsPerDay = 32;

  /// Muscles that have to be fresh for a run.
  static const Set<MuscleGroup> _legMuscles = {
    MuscleGroup.quads,
    MuscleGroup.hamstrings,
    MuscleGroup.glutes,
    MuscleGroup.calves,
    MuscleGroup.adductors,
    MuscleGroup.abductors,
  };

  static DayRulesResult apply(
    PlannedDay day,
    PlanRequest request,
    ExerciseCatalog catalog,
  ) {
    final notes = <PlanNote>[];
    var exercises = [
      for (final exercise in day.exercises)
        _applyRunRule(exercise, day, catalog),
    ];

    if (exercises.length != day.exercises.length ||
        _anyCapped(day, exercises)) {
      // One note for the day, not one per exercise. Before this rule
      // reached isolation work a pre-run day capped three lifts; now it
      // caps six, and six sentences saying the same thing is not an
      // explanation, it is noise.
      notes.add(
        PlanNote(
          PlanNoteKind.legVolumeReducedForRun,
          day.type.name,
          weekday: day.weekday,
        ),
      );
    }

    exercises = _fitToBudget(exercises, day.weekday, request, notes);
    exercises = _fillBudget(exercises, day, request, catalog);

    return DayRulesResult(day.copyWith(exercises: exercises), notes);
  }

  static bool _anyCapped(PlannedDay day, List<PlannedExercise> exercises) {
    for (var index = 0; index < exercises.length; index++) {
      if (exercises[index].sets < day.exercises[index].templateSets) {
        return true;
      }
    }
    return false;
  }

  /// Whether [exercise] puts meaningful load through the legs.
  ///
  /// Asked of the catalog rather than of the slot, because the slot does not
  /// know: a leg extension fills an *isolation* slot and is more fatiguing
  /// for the quads than the squat sets the pre-run rule just took away.
  static bool _loadsLegs(PlannedExercise exercise, ExerciseCatalog catalog) {
    if (exercise.slotPattern.isLegDominant) return true;
    final entry = catalog[exercise.exerciseId];
    if (entry == null) return false;
    return entry.primaryMuscles.any(_legMuscles.contains);
  }

  /// The most sets [exercise] may have on [day], after every rule that caps
  /// it rather than counts it.
  static int _ceilingFor(
    PlannedExercise exercise,
    PlannedDay day,
    ExerciseCatalog catalog,
  ) {
    if (day.precedesRunDay && _loadsLegs(exercise, catalog)) {
      return preRunLegSetCap;
    }
    return maxSetsFor(exercise.priority);
  }

  /// Grows the day into whatever time the budget has left.
  ///
  /// Sets are added one at a time, compound work first, cycling through the
  /// exercises so the volume spreads rather than piling onto whichever lift
  /// happens to be first. Nothing is added past [_ceilingFor], which is what
  /// keeps the pre-run leg cap intact in a long session.
  ///
  /// Deriving everything from `templateSets` and the budget is what makes
  /// this idempotent: applying the rules to an already-filled day gives the
  /// same day back, so an edit does not inflate the week a little more each
  /// time the user drags a row.
  static List<PlannedExercise> _fillBudget(
    List<PlannedExercise> original,
    PlannedDay day,
    PlanRequest request,
    ExerciseCatalog catalog,
  ) {
    final budget = request.sessionMinutes * 60;
    final exercises = [...original];

    int total() =>
        PlannedDay.warmupSeconds +
        exercises.fold(0, (sum, e) => sum + e.estimatedSeconds);

    int workingSets() => exercises.fold(0, (sum, e) => sum + e.sets);

    for (final priority in SlotPriority.values) {
      var added = true;
      while (added) {
        added = false;
        for (var index = 0; index < exercises.length; index++) {
          if (workingSets() >= maxWorkingSetsPerDay) return exercises;

          final exercise = exercises[index];
          if (exercise.priority != priority) continue;
          if (exercise.sets >= _ceilingFor(exercise, day, catalog)) continue;

          final grown = exercise.copyWith(sets: exercise.sets + 1);
          final cost = grown.estimatedSeconds - exercise.estimatedSeconds;
          if (total() + cost > budget) continue;

          exercises[index] = grown;
          added = true;
        }
      }
    }

    return exercises;
  }

  static PlannedExercise _applyRunRule(
    PlannedExercise exercise,
    PlannedDay day,
    ExerciseCatalog catalog,
  ) {
    final shouldCap = day.precedesRunDay &&
        _loadsLegs(exercise, catalog) &&
        exercise.templateSets > preRunLegSetCap;

    if (!shouldCap) {
      // Reset to the template, so a day that moved clear of a run recovers.
      return exercise.copyWith(sets: exercise.templateSets);
    }
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
      // Optional work goes first and goes quietly: it is what the template
      // offers when there is time, so its absence is not news.
      final lastOptional = exercises.lastIndexWhere((e) => e.isOptional);
      if (lastOptional >= 0) {
        exercises.removeAt(lastOptional);
        continue;
      }

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
