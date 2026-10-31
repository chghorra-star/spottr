import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/widgets.dart';
import 'package:plan_engine/plan_engine.dart';

import '../domain/user_profile.dart';
import '../domain/workout_session.dart';
import 'app_localizations.dart';

/// Turns the identifiers the catalog and the plan engine deal in into text
/// the user can read.
///
/// Everything the engine produces is an id or an ARB key — never prose — so
/// this is the single seam where the two meet. Keeping it in one class, free
/// of `BuildContext`, means the whole mapping is unit testable, and a test
/// that walks every enum and the whole catalog can prove no value is
/// missing. A raw `exercise_db_bent_over_row` on screen is the failure this
/// class exists to prevent.
@immutable
class PlanStrings {
  const PlanStrings(this.l10n, this.catalog);

  /// The usual way to get one inside a widget.
  factory PlanStrings.of(BuildContext context, ExerciseCatalog catalog) =>
      PlanStrings(AppLocalizations.of(context), catalog);

  final AppLocalizations l10n;
  final ExerciseCatalog catalog;

  /// The display name of a catalog exercise.
  String exercise(String exerciseId) =>
      exerciseByKey(catalog.require(exerciseId).nameKey);

  /// The display name for a catalog `nameKey`.
  ///
  /// The catalog's keys are snake_case because it derives them from ids; the
  /// ARB keys are camelCase because the generated getters have to pass the
  /// analyzer. This switch is where those two spellings meet, and the only
  /// place that has to know both.
  String exerciseByKey(String nameKey) => switch (nameKey) {
        'exercise_band_assisted_pull_up' => l10n.exerciseBandAssistedPullUp,
        'exercise_barbell_back_squat' => l10n.exerciseBarbellBackSquat,
        'exercise_barbell_bench_press' => l10n.exerciseBarbellBenchPress,
        'exercise_barbell_deadlift' => l10n.exerciseBarbellDeadlift,
        'exercise_barbell_hip_thrust' => l10n.exerciseBarbellHipThrust,
        'exercise_barbell_overhead_press' => l10n.exerciseBarbellOverheadPress,
        'exercise_barbell_romanian_deadlift' => l10n.exerciseBarbellRomanianDeadlift,
        'exercise_barbell_row' => l10n.exerciseBarbellRow,
        'exercise_bird_dog' => l10n.exerciseBirdDog,
        'exercise_bodyweight_squat' => l10n.exerciseBodyweightSquat,
        'exercise_cable_fly' => l10n.exerciseCableFly,
        'exercise_cable_triceps_pushdown' => l10n.exerciseCableTricepsPushdown,
        'exercise_calf_raise' => l10n.exerciseCalfRaise,
        'exercise_chest_press_machine' => l10n.exerciseChestPressMachine,
        'exercise_db_bench_press' => l10n.exerciseDbBenchPress,
        'exercise_db_bent_over_row' => l10n.exerciseDbBentOverRow,
        'exercise_db_curl' => l10n.exerciseDbCurl,
        'exercise_db_floor_press' => l10n.exerciseDbFloorPress,
        'exercise_db_hammer_curl' => l10n.exerciseDbHammerCurl,
        'exercise_db_lateral_raise' => l10n.exerciseDbLateralRaise,
        'exercise_db_lunge' => l10n.exerciseDbLunge,
        'exercise_db_romanian_deadlift' => l10n.exerciseDbRomanianDeadlift,
        'exercise_db_shoulder_press' => l10n.exerciseDbShoulderPress,
        'exercise_db_single_arm_row' => l10n.exerciseDbSingleArmRow,
        'exercise_db_triceps_extension' => l10n.exerciseDbTricepsExtension,
        'exercise_dead_bug' => l10n.exerciseDeadBug,
        'exercise_face_pull' => l10n.exerciseFacePull,
        'exercise_forward_lunge' => l10n.exerciseForwardLunge,
        'exercise_glute_bridge' => l10n.exerciseGluteBridge,
        'exercise_goblet_squat' => l10n.exerciseGobletSquat,
        'exercise_hack_squat' => l10n.exerciseHackSquat,
        'exercise_hanging_knee_raise' => l10n.exerciseHangingKneeRaise,
        'exercise_incline_push_up' => l10n.exerciseInclinePushUp,
        'exercise_inverted_row' => l10n.exerciseInvertedRow,
        'exercise_knee_push_up' => l10n.exerciseKneePushUp,
        'exercise_lat_pulldown' => l10n.exerciseLatPulldown,
        'exercise_leg_curl' => l10n.exerciseLegCurl,
        'exercise_leg_extension' => l10n.exerciseLegExtension,
        'exercise_leg_press' => l10n.exerciseLegPress,
        'exercise_machine_shoulder_press' => l10n.exerciseMachineShoulderPress,
        'exercise_mountain_climber' => l10n.exerciseMountainClimber,
        'exercise_pike_push_up' => l10n.exercisePikePushUp,
        'exercise_plank' => l10n.exercisePlank,
        'exercise_pull_up' => l10n.exercisePullUp,
        'exercise_push_up' => l10n.exercisePushUp,
        'exercise_reverse_lunge' => l10n.exerciseReverseLunge,
        'exercise_seated_cable_row' => l10n.exerciseSeatedCableRow,
        'exercise_seated_calf_raise' => l10n.exerciseSeatedCalfRaise,
        'exercise_side_plank' => l10n.exerciseSidePlank,
        'exercise_single_leg_glute_bridge' => l10n.exerciseSingleLegGluteBridge,
        'exercise_split_squat' => l10n.exerciseSplitSquat,
        'exercise_step_up' => l10n.exerciseStepUp,
        'exercise_superman' => l10n.exerciseSuperman,
        'exercise_wall_sit' => l10n.exerciseWallSit,
        _ => throw ArgumentError.value(
            nameKey,
            'nameKey',
            'No display name. Adding a catalog entry means adding an ARB key',
          ),
      };

  String day(String labelKey) => switch (labelKey) {
        'day_full_body' => l10n.dayFullBody,
        'day_upper' => l10n.dayUpper,
        'day_lower' => l10n.dayLower,
        'day_push' => l10n.dayPush,
        'day_pull' => l10n.dayPull,
        'day_legs' => l10n.dayLegs,
        _ => throw ArgumentError.value(labelKey, 'labelKey', 'No day label'),
      };

  String dayType(DayType type) => switch (type) {
        DayType.fullBody => l10n.dayFullBody,
        DayType.upper => l10n.dayUpper,
        DayType.lower => l10n.dayLower,
        DayType.push => l10n.dayPush,
        DayType.pull => l10n.dayPull,
        DayType.legs => l10n.dayLegs,
      };

  /// The name of an ISO weekday, 1 (Monday) to 7 (Sunday).
  String weekday(int isoWeekday) => switch (isoWeekday) {
        1 => l10n.weekdayMonday,
        2 => l10n.weekdayTuesday,
        3 => l10n.weekdayWednesday,
        4 => l10n.weekdayThursday,
        5 => l10n.weekdayFriday,
        6 => l10n.weekdaySaturday,
        7 => l10n.weekdaySunday,
        _ => throw RangeError.range(isoWeekday, 1, 7, 'isoWeekday'),
      };

  String pattern(MovementPattern value) => switch (value) {
        MovementPattern.squat => l10n.patternSquat,
        MovementPattern.hinge => l10n.patternHinge,
        MovementPattern.lunge => l10n.patternLunge,
        MovementPattern.horizontalPush => l10n.patternHorizontalPush,
        MovementPattern.verticalPush => l10n.patternVerticalPush,
        MovementPattern.horizontalPull => l10n.patternHorizontalPull,
        MovementPattern.verticalPull => l10n.patternVerticalPull,
        MovementPattern.core => l10n.patternCore,
        MovementPattern.isolation => l10n.patternIsolation,
        MovementPattern.carry => l10n.patternCarry,
      };

  String muscle(MuscleGroup value) => switch (value) {
        MuscleGroup.quads => l10n.muscleQuads,
        MuscleGroup.hamstrings => l10n.muscleHamstrings,
        MuscleGroup.glutes => l10n.muscleGlutes,
        MuscleGroup.calves => l10n.muscleCalves,
        MuscleGroup.adductors => l10n.muscleAdductors,
        MuscleGroup.abductors => l10n.muscleAbductors,
        MuscleGroup.chest => l10n.muscleChest,
        MuscleGroup.lats => l10n.muscleLats,
        MuscleGroup.upperBack => l10n.muscleUpperBack,
        MuscleGroup.lowerBack => l10n.muscleLowerBack,
        MuscleGroup.shoulders => l10n.muscleShoulders,
        MuscleGroup.biceps => l10n.muscleBiceps,
        MuscleGroup.triceps => l10n.muscleTriceps,
        MuscleGroup.forearms => l10n.muscleForearms,
        MuscleGroup.core => l10n.muscleCore,
        MuscleGroup.obliques => l10n.muscleObliques,
      };

  /// Muscle names in catalog order, so the same set always reads the same.
  String muscleList(Iterable<MuscleGroup> muscles) => [
        for (final candidate in MuscleGroup.values)
          if (muscles.contains(candidate)) muscle(candidate),
      ].join(', ');

  String equipment(Equipment value) => switch (value) {
        Equipment.dumbbells => l10n.equipmentDumbbells,
        Equipment.barbell => l10n.equipmentBarbell,
        Equipment.kettlebell => l10n.equipmentKettlebell,
        Equipment.bench => l10n.equipmentBench,
        Equipment.pullUpBar => l10n.equipmentPullUpBar,
        Equipment.dipBars => l10n.equipmentDipBars,
        Equipment.cableMachine => l10n.equipmentCableMachine,
        Equipment.machine => l10n.equipmentMachine,
        Equipment.resistanceBand => l10n.equipmentResistanceBand,
        Equipment.box => l10n.equipmentBox,
      };

  String bodyPart(BodyPart value) => switch (value) {
        BodyPart.knees => l10n.bodyPartKnees,
        BodyPart.lowerBack => l10n.bodyPartLowerBack,
        BodyPart.shoulders => l10n.bodyPartShoulders,
        BodyPart.wrists => l10n.bodyPartWrists,
        BodyPart.hips => l10n.bodyPartHips,
        BodyPart.ankles => l10n.bodyPartAnkles,
        BodyPart.elbows => l10n.bodyPartElbows,
        BodyPart.neck => l10n.bodyPartNeck,
      };

  String goal(Goal value) => switch (value) {
        Goal.weightLoss => l10n.goalWeightLoss,
        Goal.muscleBuilding => l10n.goalMuscleBuilding,
        Goal.hybrid => l10n.goalHybrid,
      };

  String goalDetail(Goal value) => switch (value) {
        Goal.weightLoss => l10n.goalWeightLossDetail,
        Goal.muscleBuilding => l10n.goalMuscleBuildingDetail,
        Goal.hybrid => l10n.goalHybridDetail,
      };

  String level(Level value) => switch (value) {
        Level.beginner => l10n.levelBeginner,
        Level.intermediate => l10n.levelIntermediate,
        Level.advanced => l10n.levelAdvanced,
      };

  String levelDetail(Level value) => switch (value) {
        Level.beginner => l10n.levelBeginnerDetail,
        Level.intermediate => l10n.levelIntermediateDetail,
        Level.advanced => l10n.levelAdvancedDetail,
      };

  String location(TrainingLocation value) => switch (value) {
        TrainingLocation.homeNone => l10n.locationHomeNone,
        TrainingLocation.homeDumbbells => l10n.locationHomeDumbbells,
        TrainingLocation.fullGym => l10n.locationFullGym,
      };

  String locationDetail(TrainingLocation value) => switch (value) {
        TrainingLocation.homeNone => l10n.locationHomeNoneDetail,
        TrainingLocation.homeDumbbells => l10n.locationHomeDumbbellsDetail,
        TrainingLocation.fullGym => l10n.locationFullGymDetail,
      };

  String coachStyle(CoachStyle value) => switch (value) {
        CoachStyle.hype => l10n.coachStyleHype,
        CoachStyle.calm => l10n.coachStyleCalm,
        CoachStyle.tough => l10n.coachStyleTough,
      };

  String coachStyleDetail(CoachStyle value) => switch (value) {
        CoachStyle.hype => l10n.coachStyleHypeDetail,
        CoachStyle.calm => l10n.coachStyleCalmDetail,
        CoachStyle.tough => l10n.coachStyleToughDetail,
      };

  String sex(Sex value) => switch (value) {
        Sex.female => l10n.sexFemale,
        Sex.male => l10n.sexMale,
        Sex.preferNotToSay => l10n.sexPreferNotToSay,
      };

  String runSuggestion(String key) => switch (key) {
        'run_suggestion_easy_20' => l10n.runSuggestionEasy20,
        'run_suggestion_steady_35' => l10n.runSuggestionSteady35,
        'run_suggestion_tempo_45' => l10n.runSuggestionTempo45,
        _ => throw ArgumentError.value(key, 'key', 'No run suggestion'),
      };

  /// Prose for a plan note.
  ///
  /// The generator writes machine-readable details — a pattern name, an
  /// exercise id, a day type — and this is where they become a sentence.
  /// The point of surfacing them at all is that a short or simplified week
  /// should look explained rather than broken.
  String note(PlanNote value) => switch (value.kind) {
        PlanNoteKind.unfilledSlot =>
          l10n.noteUnfilledSlot(_slotName(value.detail)),
        PlanNoteKind.legVolumeReducedForRun =>
          l10n.noteLegVolumeReducedForRun(_dayName(value)),
        PlanNoteKind.trimmedForTime =>
          l10n.noteTrimmedForTime(exercise(value.detail)),
        PlanNoteKind.templateSimplified =>
          l10n.noteTemplateSimplified(_patternList(value.detail)),
        PlanNoteKind.dayUnderfilled =>
          l10n.noteDayUnderfilled(dayType(_dayTypeNamed(value.detail))),
        PlanNoteKind.sessionShorterThanBudget =>
          l10n.noteSessionShorterThanBudget(value.detail),
      };

  /// The weekday a note belongs to, falling back to the kind of session it
  /// was. "Leg work on Monday" says more than "on your lower body day", but
  /// a note without a weekday still has to read as a sentence.
  String _dayName(PlanNote note) => note.weekday == null
      ? dayType(_dayTypeNamed(note.detail))
      : weekday(note.weekday!);

  /// How a session felt, as the user is offered it.
  String rating(SessionRating value) => switch (value) {
        SessionRating.tooEasy => l10n.ratingTooEasy,
        SessionRating.right => l10n.ratingRight,
        SessionRating.tooHard => l10n.ratingTooHard,
      };

  String ratingDetail(SessionRating value) => switch (value) {
        SessionRating.tooEasy => l10n.ratingTooEasyDetail,
        SessionRating.right => l10n.ratingRightDetail,
        SessionRating.tooHard => l10n.ratingTooHardDetail,
      };

  /// One line for a progression decision: what changes, then why.
  ///
  /// Assembled from two halves rather than written out per combination.
  /// Seven changes times twelve reasons is eighty-four sentences nobody
  /// would keep correct; this way each idea is worded once.
  String progression(ProgressionDecision value) =>
      l10n.sessionSummaryLine(_change(value), _reason(value));

  /// A weight as a human writes it: 60 rather than 60.0, 62.5 as it is.
  String weight(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  String _change(ProgressionDecision value) => switch (value.change) {
        ProgressionChange.loadUp =>
          l10n.progressionWeightUp(weight(value.nextWeightKg!)),
        ProgressionChange.loadDown =>
          l10n.progressionWeightDown(weight(value.nextWeightKg!)),
        ProgressionChange.repsUp =>
          l10n.progressionRepsUp(value.nextRepsMin!, value.nextRepsMax!),
        ProgressionChange.holdUp =>
          l10n.progressionHoldUp(value.nextHoldSeconds!),
        ProgressionChange.harderVariant =>
          l10n.progressionMovingUp(exercise(value.nextExerciseId!)),
        ProgressionChange.easierVariant =>
          l10n.progressionMovingDown(exercise(value.nextExerciseId!)),
        ProgressionChange.hold => l10n.progressionUnchanged,
      };

  /// The why, with the form score folded in when there is one.
  ///
  /// There never is one before the camera lands, which is why the score is a
  /// suffix rather than part of every sentence.
  String _reason(ProgressionDecision value) {
    final reps = value.repsAchieved;
    final base = switch (value.reason) {
      ProgressionReason.painReported => l10n.reasonPainReported,
      ProgressionReason.sessionIncomplete => l10n.reasonSessionIncomplete,
      ProgressionReason.earnedLoad => reps == null
          ? l10n.reasonEarnedLoadPlain
          : l10n.reasonEarnedLoad(reps),
      ProgressionReason.earnedReps => l10n.reasonEarnedReps,
      ProgressionReason.earnedHold => l10n.reasonEarnedHold,
      ProgressionReason.earnedHarderVariant =>
        l10n.reasonEarnedHarderVariant,
      ProgressionReason.ratedTooEasy => l10n.reasonRatedTooEasy,
      ProgressionReason.formBreakingDown => l10n.reasonFormBreakingDown,
      ProgressionReason.formWatch => l10n.reasonFormWatch,
      ProgressionReason.missedReps => reps == null
          ? l10n.reasonMissedRepsPlain
          : l10n.reasonMissedReps(reps),
      ProgressionReason.ratedTooHard => l10n.reasonRatedTooHard,
      ProgressionReason.atCeiling => l10n.reasonAtCeiling,
      ProgressionReason.holdingSteady => l10n.reasonHoldingSteady,
    };

    final score = value.meanFormScore;
    return score == null
        ? base
        : l10n.progressionFormSuffix(base, score.round());
  }

  /// One set as it was logged, for the list of what is already done.
  String loggedSet(LoggedSet value) {
    final seconds = value.holdSeconds;
    if (seconds != null) return l10n.sessionLoggedSetHold(seconds);
    final reps = value.reps ?? 0;
    final load = value.weightKg;
    return load == null
        ? l10n.sessionLoggedSetReps(reps)
        : l10n.sessionLoggedSetRepsWeighted(reps, weight(load));
  }

  /// Sets and reps, or sets and a hold.
  String prescription(PlannedExercise value) =>
      value.metric == MetricType.holdSeconds
          ? l10n.planSetsHold(value.sets, value.holdSeconds ?? 0)
          : l10n.planSetsReps(
              value.sets,
              value.repsMin ?? 0,
              value.repsMax ?? 0,
            );

  /// An unfilled slot's detail is either a pattern name or
  /// `pattern:muscle`. The muscle is the more useful half when it is there:
  /// "no biceps exercise" says more than "no isolation exercise".
  String _slotName(String detail) {
    final parts = detail.split(':');
    if (parts.length == 2) {
      return muscle(_named(MuscleGroup.values, parts[1], 'muscle'));
    }
    return pattern(_named(MovementPattern.values, parts.first, 'pattern'));
  }

  String _patternList(String detail) => detail
      .split(',')
      .map((name) => pattern(_named(MovementPattern.values, name, 'pattern')))
      .join(', ');

  DayType _dayTypeNamed(String name) =>
      _named(DayType.values, name, 'day type');

  static T _named<T extends Enum>(List<T> values, String name, String what) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw ArgumentError.value(name, what, 'Not a known $what');
  }
}
