import 'package:meta/meta.dart';
import 'package:plan_engine/plan_engine.dart';

/// One set, as it was actually performed.
///
/// Stored rather than derived: what somebody lifted last Tuesday is the one
/// fact progression cannot reconstruct from anything else.
@immutable
class LoggedSet {
  const LoggedSet({
    required this.id,
    required this.exerciseId,
    required this.setIndex,
    required this.completedAt,
    this.planExerciseId,
    this.reps,
    this.holdSeconds,
    this.weightKg,
    this.formScore,
  });

  final String id;

  /// Catalog id. Kept even though [planExerciseId] implies it, so a log
  /// survives the plan row it pointed at being tombstoned.
  final String exerciseId;

  /// The exact prescription this was performed against, or null for work
  /// done outside the plan.
  final String? planExerciseId;

  /// Position within this exercise, from zero.
  final int setIndex;

  final int? reps;
  final int? holdSeconds;
  final double? weightKg;

  /// 0..100 mean over counted reps. Null for every hand-logged set, which
  /// is all of them until the camera lands.
  final double? formScore;

  final DateTime completedAt;

  /// The same set as the plan engine wants it: no ids, no timestamps.
  CompletedSet toCompleted() => CompletedSet(
        reps: reps,
        holdSeconds: holdSeconds,
        weightKg: weightKg,
        formScore: formScore,
      );

  @override
  bool operator ==(Object other) =>
      other is LoggedSet &&
      other.id == id &&
      other.exerciseId == exerciseId &&
      other.planExerciseId == planExerciseId &&
      other.setIndex == setIndex &&
      other.reps == reps &&
      other.holdSeconds == holdSeconds &&
      other.weightKg == weightKg &&
      other.formScore == formScore &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
        id,
        exerciseId,
        planExerciseId,
        setIndex,
        reps,
        holdSeconds,
        weightKg,
        formScore,
        completedAt,
      );

  @override
  String toString() => '$exerciseId set ${setIndex + 1}';
}

/// One workout, in progress or finished.
@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startedAt,
    required this.sets,
    this.planDayId,
    this.weekday,
    this.endedAt,
    this.rating,
    this.painReported = false,
    this.notes,
  });

  final String id;

  /// The plan day this was trained against, and the weekday it sat on.
  ///
  /// Both are null for a session logged with no plan — which the MVP does
  /// not offer, but the schema allows and progression has to tolerate.
  final String? planDayId;
  final int? weekday;

  final DateTime startedAt;
  final DateTime? endedAt;

  final SessionRating? rating;

  /// Whether the pain button was pressed. Never cleared, by anything.
  final bool painReported;

  final String? notes;

  /// Every set logged, ordered as they were performed.
  final List<LoggedSet> sets;

  bool get isActive => endedAt == null;

  /// How long the session took, or how long it has been running.
  Duration elapsedAt(DateTime now) =>
      (endedAt ?? now).difference(startedAt);

  List<LoggedSet> setsFor(String exerciseId) =>
      [for (final set in sets) if (set.exerciseId == exerciseId) set];

  int completedCountFor(String exerciseId) => setsFor(exerciseId).length;

  /// Mean form over the sets of one exercise a camera judged, or null if
  /// none were.
  double? meanFormFor(String exerciseId) {
    final scores = [
      for (final set in setsFor(exerciseId))
        if (set.formScore != null) set.formScore!,
    ];
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// The heaviest load used on an exercise in this session.
  double? topWeightFor(String exerciseId) {
    double? top;
    for (final set in setsFor(exerciseId)) {
      final weight = set.weightKg;
      if (weight != null && (top == null || weight > top)) top = weight;
    }
    return top;
  }

  @override
  String toString() =>
      'WorkoutSession($id, ${sets.length} sets, '
      '${isActive ? 'active' : 'finished'})';
}
