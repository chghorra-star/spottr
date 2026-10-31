import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';

import 'plan_request.dart';
import 'week_plan.dart';

/// How the session felt, asked once at the end.
///
/// Three options rather than a ten-point scale: the answer feeds a decision
/// table with three branches, and asking for precision the engine cannot use
/// only makes the question harder to answer honestly.
enum SessionRating { tooEasy, right, tooHard }

/// One set as it was actually performed.
///
/// [reps] for counted work and [holdSeconds] for holds — whichever the
/// exercise is measured in. [formScore] is null for every set logged by hand,
/// which is every set until the camera lands, so progression has to be able
/// to decide without it.
@immutable
class CompletedSet {
  const CompletedSet({
    this.reps,
    this.holdSeconds,
    this.weightKg,
    this.formScore,
  }) : assert(
          reps != null || holdSeconds != null,
          'A logged set is either reps or a hold',
        );

  final int? reps;
  final int? holdSeconds;

  /// Load used, or null for bodyweight work.
  ///
  /// This, not the catalog, is what decides whether progression adds load or
  /// adds reps: a push-up in a weight vest is a loaded exercise and the
  /// catalog has no way of knowing.
  final double? weightKg;

  /// 0..100, mean over the reps the counter accepted, or null when no camera
  /// judged the set.
  final double? formScore;

  /// What the user achieved, in whatever unit the exercise is measured in.
  int get achieved => reps ?? holdSeconds!;

  @override
  bool operator ==(Object other) =>
      other is CompletedSet &&
      other.reps == reps &&
      other.holdSeconds == holdSeconds &&
      other.weightKg == weightKg &&
      other.formScore == formScore;

  @override
  int get hashCode => Object.hash(reps, holdSeconds, weightKg, formScore);

  @override
  String toString() => 'CompletedSet($achieved'
      '${weightKg == null ? '' : ' @ ${weightKg}kg'})';
}

/// One exercise's evidence from one session.
@immutable
class ProgressionInput {
  const ProgressionInput({
    required this.planned,
    required this.completed,
    this.rating,
    this.painReported = false,
    this.priorLowFormSessions = 0,
  });

  /// What the user was asked to do.
  final PlannedExercise planned;

  /// What they did, one entry per set actually logged.
  final List<CompletedSet> completed;

  /// How the whole session felt. Null when the user skipped the question.
  final SessionRating? rating;

  /// Whether the pain button was pressed during this session.
  final bool painReported;

  /// How many sessions in a row before this one came in under
  /// [Progression.formFloor] on this exercise.
  ///
  /// One bad session is a bad day; two in a row is a pattern, and only the
  /// second one acts on it.
  final int priorLowFormSessions;

  /// Mean form across the sets a camera judged, or null if none were.
  double? get meanFormScore {
    final scores = [
      for (final set in completed)
        if (set.formScore != null) set.formScore!,
    ];
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// The load the user actually worked with, taken from the last set that
  /// carried one. The last set is the one the next session starts from.
  double? get workingWeightKg {
    for (final set in completed.reversed) {
      if (set.weightKg != null) return set.weightKg;
    }
    return planned.targetWeightKg;
  }
}

/// What progression decided to do next time.
///
/// Deliberately nothing about set counts: the time budget owns how much work
/// a day holds, progression owns how hard that work is.
enum ProgressionChange {
  /// The prescription stands. [ProgressionDecision.reason] says why.
  hold,
  loadUp,
  loadDown,
  repsUp,
  holdUp,

  /// Move up the catalog's ladder, because reps or seconds have run out of
  /// room.
  harderVariant,

  /// Move down it, because form is not holding at this one.
  easierVariant,
}

/// Why, as an identifier the UI renders into prose.
///
/// The plan engine never holds user-facing text — the reason is a value that
/// `PlanStrings` turns into a sentence, so "you hit all 12" can be worded,
/// reworded and translated without touching the decision table.
enum ProgressionReason {
  /// The pain button was pressed. Nothing else about the session matters.
  painReported,

  /// Fewer sets were logged than were asked for.
  sessionIncomplete,

  earnedLoad,
  earnedReps,
  earnedHold,
  earnedHarderVariant,

  /// The user said the session was too easy, having missed nothing.
  ratedTooEasy,

  /// Form has been under the floor two sessions running.
  formBreakingDown,

  /// Form was under the floor once. Watched, not acted on.
  formWatch,

  missedReps,
  ratedTooHard,

  /// Earned a step up with nothing left to step up to.
  atCeiling,

  /// A perfectly good session that earned nothing in particular.
  holdingSteady,
}

/// One exercise's next prescription, and why.
@immutable
class ProgressionDecision {
  const ProgressionDecision({
    required this.exerciseId,
    required this.change,
    required this.reason,
    this.nextWeightKg,
    this.nextRepsMin,
    this.nextRepsMax,
    this.nextHoldSeconds,
    this.nextExerciseId,
    this.repsAchieved,
    this.holdSecondsAchieved,
    this.meanFormScore,
  });

  /// The exercise this is about, as prescribed.
  final String exerciseId;

  final ProgressionChange change;
  final ProgressionReason reason;

  final double? nextWeightKg;
  final int? nextRepsMin;
  final int? nextRepsMax;
  final int? nextHoldSeconds;

  /// Set only by [ProgressionChange.harderVariant] and
  /// [ProgressionChange.easierVariant].
  final String? nextExerciseId;

  /// The lowest rep count across the session's sets, which is the number the
  /// decision turned on — and the one worth quoting back.
  final int? repsAchieved;

  /// The same, for holds.
  final int? holdSecondsAchieved;

  final double? meanFormScore;

  bool get changesAnything =>
      nextWeightKg != null ||
      nextRepsMin != null ||
      nextHoldSeconds != null ||
      nextExerciseId != null;

  @override
  bool operator ==(Object other) =>
      other is ProgressionDecision &&
      other.exerciseId == exerciseId &&
      other.change == change &&
      other.reason == reason &&
      other.nextWeightKg == nextWeightKg &&
      other.nextRepsMin == nextRepsMin &&
      other.nextRepsMax == nextRepsMax &&
      other.nextHoldSeconds == nextHoldSeconds &&
      other.nextExerciseId == nextExerciseId &&
      other.repsAchieved == repsAchieved &&
      other.holdSecondsAchieved == holdSecondsAchieved &&
      other.meanFormScore == meanFormScore;

  @override
  int get hashCode => Object.hash(
        exerciseId,
        change,
        reason,
        nextWeightKg,
        nextRepsMin,
        nextRepsMax,
        nextHoldSeconds,
        nextExerciseId,
        repsAchieved,
        holdSecondsAchieved,
        meanFormScore,
      );

  @override
  String toString() => '$exerciseId: ${change.name} (${reason.name})';
}

/// Decides what to prescribe next, from what the user actually did.
///
/// A decision table, not a model: every branch is a rule somebody can read,
/// argue with and test. The order of the branches is the whole design —
/// safety first, then evidence quality, then backing off, and only then
/// adding anything.
class Progression {
  const Progression(this.catalog);

  final ExerciseCatalog catalog;

  /// Mean form below this is a problem.
  static const double formFloor = 70;

  /// Mean form at or above this is good enough to add load on.
  static const double formCeiling = 85;

  /// The smallest change worth making to a barbell or a dumbbell pair.
  static const double loadStepKg = 2.5;

  /// How much load a earned session adds, before rounding to [loadStepKg].
  static const double increaseFraction = 0.025;

  /// How much a missed session takes off.
  static const double decreaseFraction = 0.05;

  /// How much form breaking down twice takes off — twice as much, because
  /// the evidence is twice as strong.
  static const double regressFraction = 0.10;

  /// How far a rep range moves when bodyweight work is earned.
  static const int repStep = 2;

  /// Beyond this, adding reps stops training strength and starts training
  /// patience: the exercise itself has to get harder instead.
  static const int repCeiling = 20;

  static const int holdStep = 5;

  /// Same argument as [repCeiling]. A two-minute plank is a party trick.
  static const int holdCeiling = 90;

  /// One decision per input, in the order they were given.
  List<ProgressionDecision> decide({
    required Iterable<ProgressionInput> inputs,
    required PlanRequest request,
  }) =>
      [
        for (final input in inputs) decideOne(input: input, request: request),
      ];

  ProgressionDecision decideOne({
    required ProgressionInput input,
    required PlanRequest request,
  }) {
    final planned = input.planned;
    final isHold = planned.metric == MetricType.holdSeconds;

    ProgressionDecision hold(ProgressionReason reason) => _decision(
          input,
          change: ProgressionChange.hold,
          reason: reason,
        );

    // 1. Pain outranks everything, including a session that looks perfect.
    // Spottr does not decide what hurt or why; it stops adding to it.
    if (input.painReported) return hold(ProgressionReason.painReported);

    // 2. A session that was not finished is not evidence about the weight.
    if (input.completed.length < planned.sets) {
      return hold(ProgressionReason.sessionIncomplete);
    }

    final meanForm = input.meanFormScore;
    final weight = input.workingWeightKg;

    // 3. Form. Once is a bad day; twice running is the prescription.
    if (meanForm != null && meanForm < formFloor) {
      if (input.priorLowFormSessions < 1) {
        return hold(ProgressionReason.formWatch);
      }
      return _easeOff(
        input,
        request: request,
        reason: ProgressionReason.formBreakingDown,
        fraction: regressFraction,
        offerEasierVariant: true,
      );
    }

    final missed = input.completed.any(
      (set) => set.achieved < (isHold ? planned.holdSeconds ?? 0 : planned.repsMin ?? 0),
    );

    // 4 and 5. The user's own verdict first, then the numbers.
    if (input.rating == SessionRating.tooHard) {
      return _easeOff(
        input,
        request: request,
        reason: ProgressionReason.ratedTooHard,
        fraction: decreaseFraction,
        offerEasierVariant: false,
      );
    }
    if (missed) {
      return _easeOff(
        input,
        request: request,
        reason: ProgressionReason.missedReps,
        fraction: decreaseFraction,
        offerEasierVariant: false,
      );
    }

    // 6. Did this session earn more? Either every set reached the top of the
    // range, or the user said it was too easy and missed nothing.
    final atTop = input.completed.every(
      (set) =>
          set.achieved >= (isHold ? planned.holdSeconds ?? 0 : planned.repsMax ?? 0),
    );
    final formAllows = meanForm == null || meanForm >= formCeiling;
    if (!formAllows || !(atTop || input.rating == SessionRating.tooEasy)) {
      return hold(ProgressionReason.holdingSteady);
    }

    final earnedBy = atTop
        ? (isHold ? ProgressionReason.earnedHold : ProgressionReason.earnedReps)
        : ProgressionReason.ratedTooEasy;

    if (weight != null) {
      return _decision(
        input,
        change: ProgressionChange.loadUp,
        reason: atTop ? ProgressionReason.earnedLoad : ProgressionReason.ratedTooEasy,
        nextWeightKg: _increased(weight),
      );
    }

    if (isHold) {
      final seconds = (planned.holdSeconds ?? 0) + holdStep;
      if (seconds <= holdCeiling) {
        return _decision(
          input,
          change: ProgressionChange.holdUp,
          reason: earnedBy,
          nextHoldSeconds: seconds,
        );
      }
      return _harderOrCeiling(input, request: request);
    }

    final nextMax = (planned.repsMax ?? 0) + repStep;
    if (nextMax <= repCeiling) {
      return _decision(
        input,
        change: ProgressionChange.repsUp,
        reason: earnedBy,
        nextRepsMin: (planned.repsMin ?? 0) + repStep,
        nextRepsMax: nextMax,
      );
    }
    return _harderOrCeiling(input, request: request);
  }

  /// Back off: take load off if there is load to take off, drop to an easier
  /// variant if that is the only dial, and otherwise hold and say so.
  ///
  /// Bodyweight work is where this matters. Five percent off a push-up is not
  /// a thing, and inventing a reduction the user cannot act on would be
  /// worse than admitting there is none.
  ProgressionDecision _easeOff(
    ProgressionInput input, {
    required PlanRequest request,
    required ProgressionReason reason,
    required double fraction,
    required bool offerEasierVariant,
  }) {
    final weight = input.workingWeightKg;
    if (weight != null) {
      final next = _decreased(weight, fraction);
      if (next == null) {
        return _decision(
          input,
          change: ProgressionChange.hold,
          reason: reason,
        );
      }
      return _decision(
        input,
        change: ProgressionChange.loadDown,
        reason: reason,
        nextWeightKg: next,
      );
    }

    if (offerEasierVariant) {
      final easier = _variant(
        catalog[input.planned.exerciseId]?.easierId,
        request: request,
        metric: input.planned.metric,
        // An easier exercise is never gated on the user's level: the point
        // is that the current one is too much.
        requireLevel: false,
      );
      if (easier != null) {
        return _decision(
          input,
          change: ProgressionChange.easierVariant,
          reason: reason,
          nextExerciseId: easier.id,
        );
      }
    }

    return _decision(input, change: ProgressionChange.hold, reason: reason);
  }

  ProgressionDecision _harderOrCeiling(
    ProgressionInput input, {
    required PlanRequest request,
  }) {
    final harder = _variant(
      catalog[input.planned.exerciseId]?.harderId,
      request: request,
      metric: input.planned.metric,
      requireLevel: true,
    );
    if (harder == null) {
      return _decision(
        input,
        change: ProgressionChange.hold,
        reason: ProgressionReason.atCeiling,
      );
    }
    return _decision(
      input,
      change: ProgressionChange.harderVariant,
      reason: ProgressionReason.earnedHarderVariant,
      nextExerciseId: harder.id,
    );
  }

  /// The ladder rung called [id], if this user can actually use it.
  ///
  /// A progression target the user has no equipment for, or that is ruled
  /// out by an injury they declared, is not a progression — it is a dead end
  /// in next week's plan.
  Exercise? _variant(
    String? id, {
    required PlanRequest request,
    required MetricType metric,
    required bool requireLevel,
  }) {
    if (id == null) return null;
    final candidate = catalog[id];
    if (candidate == null) return null;
    // Reps and seconds are not interchangeable: a ladder that crossed from
    // one to the other would silently rewrite the prescription's units.
    if (candidate.metric != metric) return null;
    if (!candidate.isAvailableWith(request.availableEquipment)) return null;
    if (!candidate.isSafeFor(request.injuries)) return null;
    if (requireLevel && !candidate.suitsLevel(request.level)) return null;
    return candidate;
  }

  /// Load after an earned session: a percentage, rounded up to something you
  /// can actually load onto a bar, and never less than one plate change.
  static double _increased(double weight) {
    final scaled = _ceilToStep(weight * (1 + increaseFraction));
    final minimum = weight + loadStepKg;
    return scaled > minimum ? scaled : minimum;
  }

  /// Load after a missed session, or null when it is already as light as the
  /// smallest increment allows.
  static double? _decreased(double weight, double fraction) {
    final next = _floorToStep(weight * (1 - fraction));
    final floored = next < loadStepKg ? loadStepKg : next;
    return floored >= weight ? null : floored;
  }

  static double _ceilToStep(double value) =>
      (value / loadStepKg - 1e-9).ceil() * loadStepKg;

  static double _floorToStep(double value) =>
      (value / loadStepKg + 1e-9).floor() * loadStepKg;

  ProgressionDecision _decision(
    ProgressionInput input, {
    required ProgressionChange change,
    required ProgressionReason reason,
    double? nextWeightKg,
    int? nextRepsMin,
    int? nextRepsMax,
    int? nextHoldSeconds,
    String? nextExerciseId,
  }) {
    final isHold = input.planned.metric == MetricType.holdSeconds;
    final lowest = input.completed.isEmpty
        ? null
        : input.completed
            .map((set) => set.achieved)
            .reduce((a, b) => a < b ? a : b);

    return ProgressionDecision(
      exerciseId: input.planned.exerciseId,
      change: change,
      reason: reason,
      nextWeightKg: nextWeightKg,
      nextRepsMin: nextRepsMin,
      nextRepsMax: nextRepsMax,
      nextHoldSeconds: nextHoldSeconds,
      nextExerciseId: nextExerciseId,
      repsAchieved: isHold ? null : lowest,
      holdSecondsAchieved: isHold ? lowest : null,
      meanFormScore: input.meanFormScore,
    );
  }
}
