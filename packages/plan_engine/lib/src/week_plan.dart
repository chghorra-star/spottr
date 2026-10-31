import 'package:collection/collection.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';

import 'goal.dart';
import 'templates.dart';

/// Order-sensitive list comparison, used by the plan value objects below.
///
/// A day whose exercises are in a different order is a different day: that is
/// precisely what reordering produces.
const _lists = ListEquality<Object?>();
const _ints = SetEquality<int>();

/// Why a plan does not look like the plain template.
enum PlanNoteKind {
  /// A slot the catalog could not fill for this user, usually missing
  /// equipment. Surfaced rather than hidden so the UI can explain a short
  /// session instead of looking broken.
  unfilledSlot,

  /// Leg volume was cut because a run follows the next day.
  legVolumeReducedForRun,

  /// Work was removed to fit the session into its time budget.
  trimmedForTime,

  /// The requested split was replaced by full-body days because the user
  /// cannot train one of the patterns it depends on.
  templateSimplified,

  /// A day ended up with too little compound work to be a real session.
  ///
  /// Almost always a bodyweight-only user on a four-plus day split, where
  /// the template asks for pulling that no bodyweight exercise can supply.
  dayUnderfilled,

  /// The sessions came out well short of the time the user set aside,
  /// because there was nothing left worth adding.
  ///
  /// Emitted once for the week rather than per day. Telling someone their
  /// hour produced forty minutes of work is more useful than quietly
  /// handing them a short session — and padding it out with junk volume
  /// would be worse than either.
  sessionShorterThanBudget,
}

/// One thing the generator wants the user to know.
@immutable
class PlanNote {
  const PlanNote(this.kind, this.detail, {this.weekday});

  final PlanNoteKind kind;

  /// Machine-readable specifics: a pattern name, an exercise id, or a day
  /// type. The UI maps [kind] to prose and uses this for the detail.
  final String detail;

  final int? weekday;

  @override
  bool operator ==(Object other) =>
      other is PlanNote &&
      other.kind == kind &&
      other.detail == detail &&
      other.weekday == weekday;

  @override
  int get hashCode => Object.hash(kind, detail, weekday);

  @override
  String toString() => '${kind.name}($detail'
      '${weekday == null ? '' : ', weekday $weekday'})';
}

/// One prescribed exercise within a day.
@immutable
class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    required this.slotPattern,
    required this.priority,
    required this.sets,
    required this.templateSets,
    required this.metric,
    required this.restSeconds,
    required this.secondsPerRep,
    this.repsMin,
    this.repsMax,
    this.holdSeconds,
    this.targetWeightKg,
  });

  final String exerciseId;

  /// The pattern of the slot this fills, which is not always the exercise's
  /// own pattern: an isolation fallback can fill an accessory slot.
  final MovementPattern slotPattern;

  final SlotPriority priority;

  /// Sets actually prescribed, after any pre-run leg cap or time trimming.
  final int sets;

  /// Sets the template asked for, before any reduction.
  ///
  /// Kept so that moving a day onto or away from a pre-run slot can
  /// re-derive the prescription instead of guessing what it used to be.
  final int templateSets;

  final MetricType metric;
  final int restSeconds;
  final double secondsPerRep;

  /// Target rep range, for [MetricType.reps].
  final int? repsMin;
  final int? repsMax;

  /// Target hold, for [MetricType.holdSeconds].
  final int? holdSeconds;

  /// Load to aim for, or null when there is none to aim for yet.
  ///
  /// The generator never sets this: what somebody should squat is not
  /// derivable from a questionnaire. It appears once they have logged a
  /// session, when progression writes the next target from what they
  /// actually lifted — so a null here means "first time, tell us what you
  /// used" rather than "bodyweight".
  final double? targetWeightKg;

  /// Flat allowance for getting set up on an exercise: walking to the rack,
  /// finding the dumbbells, changing the weight.
  ///
  /// Without it the estimate is pure set arithmetic, which is how a session
  /// billed as thirty minutes came to closer to forty in the gym. One number
  /// for every exercise is a simplification — a barbell squat costs more
  /// setup than a plank — but it is a far smaller error than ignoring it.
  static const int setupSeconds = 60;

  bool get isPrimary => priority == SlotPriority.primary;

  bool get isOptional => priority == SlotPriority.optional;

  /// Midpoint of the rep range, used for time estimates.
  int get repsMid =>
      repsMin == null || repsMax == null ? 0 : (repsMin! + repsMax!) ~/ 2;

  /// Rough wall-clock cost of this exercise: setup, then work plus rest.
  int get estimatedSeconds {
    final perSet = metric == MetricType.holdSeconds
        ? (holdSeconds ?? 0) + restSeconds
        : (repsMid * secondsPerRep).round() + restSeconds;
    return setupSeconds + sets * perSet;
  }

  PlannedExercise copyWith({
    int? sets,
    int? templateSets,
    int? repsMin,
    int? repsMax,
    int? holdSeconds,
    double? targetWeightKg,
  }) =>
      PlannedExercise(
        exerciseId: exerciseId,
        slotPattern: slotPattern,
        priority: priority,
        sets: sets ?? this.sets,
        templateSets: templateSets ?? this.templateSets,
        metric: metric,
        restSeconds: restSeconds,
        secondsPerRep: secondsPerRep,
        repsMin: repsMin ?? this.repsMin,
        repsMax: repsMax ?? this.repsMax,
        holdSeconds: holdSeconds ?? this.holdSeconds,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      );

  @override
  bool operator ==(Object other) =>
      other is PlannedExercise &&
      other.exerciseId == exerciseId &&
      other.slotPattern == slotPattern &&
      other.priority == priority &&
      other.sets == sets &&
      other.templateSets == templateSets &&
      other.metric == metric &&
      other.restSeconds == restSeconds &&
      other.secondsPerRep == secondsPerRep &&
      other.repsMin == repsMin &&
      other.repsMax == repsMax &&
      other.holdSeconds == holdSeconds &&
      other.targetWeightKg == targetWeightKg;

  @override
  int get hashCode => Object.hash(
        exerciseId,
        slotPattern,
        priority,
        sets,
        templateSets,
        metric,
        restSeconds,
        secondsPerRep,
        repsMin,
        repsMax,
        holdSeconds,
        targetWeightKg,
      );

  @override
  String toString() => '$exerciseId x$sets';
}

/// One training day.
@immutable
class PlannedDay {
  const PlannedDay({
    required this.weekday,
    required this.type,
    required this.labelKey,
    required this.precedesRunDay,
    required this.exercises,
  });

  /// Time reserved for warming up, included in [estimatedSeconds].
  static const int warmupSeconds = 360;

  /// ISO weekday, 1 = Monday.
  final int weekday;

  final DayType type;
  final String labelKey;

  /// Whether a run follows tomorrow. Leg volume is reduced on these days.
  final bool precedesRunDay;

  final List<PlannedExercise> exercises;

  List<PlannedExercise> get primaryExercises =>
      exercises.where((e) => e.isPrimary).toList();

  /// Estimated session length including the warm-up.
  int get estimatedSeconds =>
      warmupSeconds +
      exercises.fold(0, (total, e) => total + e.estimatedSeconds);

  int get estimatedMinutes => (estimatedSeconds / 60).ceil();

  PlannedDay copyWith({List<PlannedExercise>? exercises}) => PlannedDay(
        weekday: weekday,
        type: type,
        labelKey: labelKey,
        precedesRunDay: precedesRunDay,
        exercises: exercises ?? this.exercises,
      );

  @override
  bool operator ==(Object other) =>
      other is PlannedDay &&
      other.weekday == weekday &&
      other.type == type &&
      other.labelKey == labelKey &&
      other.precedesRunDay == precedesRunDay &&
      _lists.equals(other.exercises, exercises);

  @override
  int get hashCode => Object.hash(
        weekday,
        type,
        labelKey,
        precedesRunDay,
        Object.hashAll(exercises),
      );

  @override
  String toString() => 'Day $weekday ${type.name}: ${exercises.join(', ')}';
}

/// A generated week.
@immutable
class WeekPlan {
  const WeekPlan({
    required this.templateId,
    required this.goal,
    required this.days,
    required this.runWeekdays,
    required this.runSuggestionKeys,
    required this.notes,
  });

  final String templateId;
  final Goal goal;

  /// Training days, ordered by weekday.
  final List<PlannedDay> days;

  /// The user's run days, carried through so the UI can show the whole week.
  final Set<int> runWeekdays;

  /// ARB keys for the text running suggestions. Hybrid goal only, and never
  /// any tracking.
  final List<String> runSuggestionKeys;

  final List<PlanNote> notes;

  Iterable<PlannedExercise> get allExercises =>
      days.expand((day) => day.exercises);

  /// Distinct exercises across the week.
  Set<String> get exerciseIds =>
      allExercises.map((e) => e.exerciseId).toSet();

  WeekPlan copyWith({List<PlannedDay>? days, List<PlanNote>? notes}) =>
      WeekPlan(
        templateId: templateId,
        goal: goal,
        days: days ?? this.days,
        runWeekdays: runWeekdays,
        runSuggestionKeys: runSuggestionKeys,
        notes: notes ?? this.notes,
      );

  @override
  bool operator ==(Object other) =>
      other is WeekPlan &&
      other.templateId == templateId &&
      other.goal == goal &&
      _lists.equals(other.days, days) &&
      _ints.equals(other.runWeekdays, runWeekdays) &&
      _lists.equals(other.runSuggestionKeys, runSuggestionKeys) &&
      _lists.equals(other.notes, notes);

  @override
  int get hashCode => Object.hash(
        templateId,
        goal,
        Object.hashAll(days),
        _ints.hash(runWeekdays),
        Object.hashAll(runSuggestionKeys),
        Object.hashAll(notes),
      );

  @override
  String toString() => 'WeekPlan($templateId, ${days.length} days)';
}
