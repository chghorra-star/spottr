// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Spottr';

  @override
  String get disclaimerTitle => 'Before we start';

  @override
  String get disclaimerBody =>
      'Spottr gives you form feedback and flags movement that looks risky. It is not medical advice, and it cannot guarantee you will avoid injury. If you are injured or in pain, talk to a doctor or physiotherapist before training.';

  @override
  String get disclaimerAccept => 'I understand';

  @override
  String get disclaimerRequired =>
      'Spottr needs you to read this before it builds you a plan.';

  @override
  String get painButton => 'I feel pain';

  @override
  String get setSummaryTitle => 'Set done';

  @override
  String repsCounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
      zero: 'No reps counted',
    );
    return '$_temp0';
  }

  @override
  String repsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to go',
      one: 'Last one',
    );
    return '$_temp0';
  }

  @override
  String formScoreLabel(int score) {
    return 'Form $score%';
  }

  @override
  String get cueTurnPhoneSideways =>
      'Turn the phone to the side so I can see your depth';

  @override
  String get cueTrackingLost => 'I lost you — step back into frame';

  @override
  String get coachStyleHype => 'Hype';

  @override
  String get coachStyleHypeDetail =>
      'Loud, fast, and all in. Expect to be shouted at in a good way.';

  @override
  String get coachStyleCalm => 'Calm';

  @override
  String get coachStyleCalmDetail =>
      'Quieter and more technical. Mostly about where your body is.';

  @override
  String get coachStyleTough => 'Tough';

  @override
  String get coachStyleToughDetail =>
      'Blunt and demanding. Never tells you to push through pain.';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Build my plan';

  @override
  String onboardingProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stepGoalTitle => 'What are you training for?';

  @override
  String get stepDaysTitle => 'How many days a week can you train?';

  @override
  String stepDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days a week',
      one: '1 day a week',
    );
    return '$_temp0';
  }

  @override
  String get stepSessionTitle => 'How long is a session?';

  @override
  String stepSessionValue(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get stepSessionBody =>
      'Spottr trims a session to fit rather than handing you a workout you cannot finish.';

  @override
  String get stepLevelTitle => 'How much training experience do you have?';

  @override
  String get stepBodyTitle => 'A few optional details';

  @override
  String get stepBodyBody =>
      'Spottr does not need any of these to build your plan. Leave anything blank.';

  @override
  String get fieldAge => 'Age';

  @override
  String get fieldHeight => 'Height in cm';

  @override
  String get fieldWeight => 'Weight in kg';

  @override
  String get fieldSex => 'Sex';

  @override
  String get stepInjuriesTitle => 'Anything hurting?';

  @override
  String get stepInjuriesBody =>
      'Spottr leaves out exercises that load an injured area. This is not medical advice — if something hurts, see a professional.';

  @override
  String get fieldInjuryNotes => 'Anything else we should know?';

  @override
  String get fieldInjuryNotesHint =>
      'Spottr shows this back to you and does not try to interpret it.';

  @override
  String get stepLocationTitle => 'Where do you train?';

  @override
  String get stepEquipmentTitle => 'Anything else you have?';

  @override
  String get stepEquipmentBody =>
      'Pick what you can actually reach. Spottr only prescribes what you can do.';

  @override
  String get stepRunDaysTitle => 'Which days do you run?';

  @override
  String get stepRunDaysBody =>
      'Spottr keeps heavy leg work off the day before a run, and suggests runs in text. It never tracks your runs.';

  @override
  String get stepCoachTitle => 'How should your coach sound?';

  @override
  String get stepCoachBody => 'You can change this whenever you like.';

  @override
  String get goalWeightLoss => 'Lose fat';

  @override
  String get goalWeightLossDetail =>
      'Higher reps and shorter rest, so more work fits in the time you have.';

  @override
  String get goalMuscleBuilding => 'Build muscle';

  @override
  String get goalMuscleBuildingDetail =>
      'Moderate reps and longer rest, so you can load each set properly.';

  @override
  String get goalHybrid => 'Gym and running';

  @override
  String get goalHybridDetail =>
      'Gym sessions scheduled around your runs. Spottr does not track the runs themselves.';

  @override
  String get levelBeginner => 'New to this';

  @override
  String get levelBeginnerDetail =>
      'Under a year of consistent training, or starting again.';

  @override
  String get levelIntermediate => 'Comfortable';

  @override
  String get levelIntermediateDetail =>
      'A year or more, and you know the main lifts.';

  @override
  String get levelAdvanced => 'Experienced';

  @override
  String get levelAdvancedDetail =>
      'Several years, and you program for yourself already.';

  @override
  String get locationHomeNone => 'Home, no equipment';

  @override
  String get locationHomeNoneDetail => 'Bodyweight only.';

  @override
  String get locationHomeDumbbells => 'Home with dumbbells';

  @override
  String get locationHomeDumbbellsDetail =>
      'A pair of dumbbells, adjustable or fixed.';

  @override
  String get locationFullGym => 'Full gym';

  @override
  String get locationFullGymDetail => 'Barbells, machines, cables, benches.';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMale => 'Male';

  @override
  String get sexPreferNotToSay => 'Prefer not to say';

  @override
  String get equipmentDumbbells => 'Dumbbells';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentKettlebell => 'Kettlebell';

  @override
  String get equipmentBench => 'Bench';

  @override
  String get equipmentPullUpBar => 'Pull-up bar';

  @override
  String get equipmentDipBars => 'Dip bars';

  @override
  String get equipmentCableMachine => 'Cable machine';

  @override
  String get equipmentMachine => 'Weight machines';

  @override
  String get equipmentResistanceBand => 'Resistance band';

  @override
  String get equipmentBox => 'Box or sturdy step';

  @override
  String get bodyPartKnees => 'Knees';

  @override
  String get bodyPartLowerBack => 'Lower back';

  @override
  String get bodyPartShoulders => 'Shoulders';

  @override
  String get bodyPartWrists => 'Wrists';

  @override
  String get bodyPartHips => 'Hips';

  @override
  String get bodyPartAnkles => 'Ankles';

  @override
  String get bodyPartElbows => 'Elbows';

  @override
  String get bodyPartNeck => 'Neck';

  @override
  String get muscleQuads => 'Quads';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleAdductors => 'Inner thigh';

  @override
  String get muscleAbductors => 'Outer hip';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleLats => 'Lats';

  @override
  String get muscleUpperBack => 'Upper back';

  @override
  String get muscleLowerBack => 'Lower back';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get patternSquat => 'Squat';

  @override
  String get patternHinge => 'Hinge';

  @override
  String get patternLunge => 'Lunge';

  @override
  String get patternHorizontalPush => 'Pressing';

  @override
  String get patternVerticalPush => 'Overhead pressing';

  @override
  String get patternHorizontalPull => 'Rowing';

  @override
  String get patternVerticalPull => 'Pulling up';

  @override
  String get patternCore => 'Core';

  @override
  String get patternIsolation => 'Isolation';

  @override
  String get patternCarry => 'Carry';

  @override
  String get dayFullBody => 'Full body';

  @override
  String get dayUpper => 'Upper body';

  @override
  String get dayLower => 'Lower body';

  @override
  String get dayPush => 'Push';

  @override
  String get dayPull => 'Pull';

  @override
  String get dayLegs => 'Legs';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get runSuggestionEasy20 => 'Easy 20 minutes, conversational pace.';

  @override
  String get runSuggestionSteady35 =>
      'Steady 35 minutes at a pace you could hold for an hour.';

  @override
  String get runSuggestionTempo45 =>
      '45 minutes with 20 at tempo in the middle.';

  @override
  String get planTitle => 'Your week';

  @override
  String get planEmptyTitle => 'No plan yet';

  @override
  String get planEmptyBody =>
      'Answer a few questions and Spottr will build your week.';

  @override
  String get planEmptyAction => 'Start';

  @override
  String get planErrorTitle => 'Spottr could not load your plan';

  @override
  String get planErrorRetry => 'Try again';

  @override
  String get planRegenerate => 'Rebuild my week';

  @override
  String get planRegenerateBody =>
      'Spottr will build a fresh week from your profile. Any swaps or reordering you did will be lost.';

  @override
  String get planRegenerateConfirm => 'Rebuild';

  @override
  String get planCancel => 'Cancel';

  @override
  String planDaySummary(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0 · about $minutes min';
  }

  @override
  String get planPreRunBadge => 'You run tomorrow';

  @override
  String planSetsReps(int sets, int min, int max) {
    return '$sets × $min–$max';
  }

  @override
  String planSetsHold(int sets, int seconds) {
    return '$sets × ${seconds}s hold';
  }

  @override
  String planRestBetweenSets(int seconds) {
    return '${seconds}s rest';
  }

  @override
  String get planCameraCoachedDetail =>
      'Spottr can count your reps and watch your form on this one.';

  @override
  String get planRunSuggestionsTitle => 'On your run days';

  @override
  String get planNotesTitle => 'Why your week looks like this';

  @override
  String get planActionSwap => 'Swap this exercise';

  @override
  String get planActionMoveDay => 'Move this day';

  @override
  String get planActionReorder => 'Reorder';

  @override
  String get planReorderDone => 'Done';

  @override
  String get planReorderHint =>
      'Drag to reorder. Spottr keeps the sets and reps you already have.';

  @override
  String get planActionStart => 'Start';

  @override
  String get planActionResume => 'Resume';

  @override
  String get planSessionElsewhere =>
      'Finish the session you already have open first.';

  @override
  String sessionElapsed(int minutes) {
    return '$minutes min in';
  }

  @override
  String sessionTargetWeight(String weight) {
    return 'Target $weight kg';
  }

  @override
  String get sessionNoTarget => 'No target yet — log what you use';

  @override
  String sessionSetsDone(int done, int total) {
    return '$done of $total sets';
  }

  @override
  String get sessionExerciseDone => 'All sets done';

  @override
  String get sessionRepsLabel => 'Reps';

  @override
  String get sessionHoldLabel => 'Seconds';

  @override
  String get sessionWeightLabel => 'Weight (kg)';

  @override
  String sessionLogSet(int number) {
    return 'Save set $number';
  }

  @override
  String sessionLoggedSetReps(int reps) {
    return '$reps reps';
  }

  @override
  String sessionLoggedSetRepsWeighted(int reps, String weight) {
    return '$reps × $weight kg';
  }

  @override
  String sessionLoggedSetHold(int seconds) {
    return '${seconds}s';
  }

  @override
  String get sessionNumberRequired => 'A number, please';

  @override
  String get sessionPainButton => 'I feel pain';

  @override
  String get sessionPainTitle => 'Stop this set';

  @override
  String get sessionPainBody =>
      'Spottr will end the set and log that it hurt, and nothing in your plan will go up. Do not train through pain — if it does not settle, see a professional.';

  @override
  String get sessionPainConfirm => 'Stop and log it';

  @override
  String get sessionPainBadge => 'Pain reported';

  @override
  String get sessionFinish => 'Finish';

  @override
  String get sessionDiscard => 'Discard session';

  @override
  String get sessionDiscardTitle => 'Throw this session away?';

  @override
  String get sessionDiscardBody =>
      'Everything you logged goes with it, and your plan stays exactly as it is.';

  @override
  String get sessionDiscardConfirm => 'Discard it';

  @override
  String get sessionRatingTitle => 'How did that feel?';

  @override
  String get sessionRatingBody =>
      'This is the one thing Spottr cannot see, and it decides what you lift next time.';

  @override
  String get sessionRatingSkip => 'Rather not say';

  @override
  String get ratingTooEasy => 'Too easy';

  @override
  String get ratingTooEasyDetail => 'I had plenty left in the tank';

  @override
  String get ratingRight => 'About right';

  @override
  String get ratingRightDetail => 'Hard, but I finished it';

  @override
  String get ratingTooHard => 'Too hard';

  @override
  String get ratingTooHardDetail => 'I could not finish it properly';

  @override
  String get sessionSummaryTitle => 'Next time';

  @override
  String get sessionSummaryEmpty => 'Your plan stays as it is next time.';

  @override
  String get sessionSummaryDone => 'Done';

  @override
  String sessionSummaryLine(String change, String reason) {
    return '$change — $reason';
  }

  @override
  String get sessionEmptyTitle => 'Nothing planned here';

  @override
  String get sessionEmptyBody =>
      'This day has no session in your current plan.';

  @override
  String progressionWeightUp(String weight) {
    return '$weight kg next time';
  }

  @override
  String progressionWeightDown(String weight) {
    return 'Down to $weight kg';
  }

  @override
  String progressionRepsUp(int min, int max) {
    return '$min–$max reps next time';
  }

  @override
  String progressionHoldUp(int seconds) {
    return '$seconds seconds next time';
  }

  @override
  String progressionMovingUp(String exercise) {
    return 'Moving up to $exercise';
  }

  @override
  String progressionMovingDown(String exercise) {
    return 'Easing back to $exercise';
  }

  @override
  String get progressionUnchanged => 'Same again next time';

  @override
  String progressionFormSuffix(String change, int score) {
    return '$change at $score% form';
  }

  @override
  String get reasonPainReported =>
      'you told us something hurt, so nothing goes up. If it does not settle, see a professional';

  @override
  String get reasonSessionIncomplete => 'you did not get through every set';

  @override
  String reasonEarnedLoad(int reps) {
    return 'you hit all $reps on every set';
  }

  @override
  String get reasonEarnedLoadPlain => 'you finished every set at the target';

  @override
  String get reasonEarnedReps =>
      'you reached the top of the range on every set';

  @override
  String get reasonEarnedHold => 'you held every set to the target';

  @override
  String get reasonEarnedHarderVariant =>
      'reps have gone as far as they usefully can';

  @override
  String get reasonRatedTooEasy => 'you said it was too easy';

  @override
  String get reasonFormBreakingDown =>
      'your form has slipped two sessions running';

  @override
  String get reasonFormWatch =>
      'your form slipped on this one, so Spottr is holding steady';

  @override
  String reasonMissedReps(int reps) {
    return '$reps on your hardest set was short of the target';
  }

  @override
  String get reasonMissedRepsPlain => 'you came up short of the target';

  @override
  String get reasonRatedTooHard => 'you said it was too hard';

  @override
  String get reasonAtCeiling =>
      'there is nothing harder in the catalog you can do with the equipment you have';

  @override
  String get reasonHoldingSteady => 'a solid session at the weight you are on';

  @override
  String swapTitle(String exercise) {
    return 'Swap $exercise';
  }

  @override
  String get swapBody =>
      'Alternatives that do the same job and fit your equipment and injuries.';

  @override
  String get swapNoAlternatives =>
      'Nothing else in the catalog does this job with the equipment you have.';

  @override
  String swapTargets(String muscles) {
    return 'Works $muscles';
  }

  @override
  String moveDayTitle(String day) {
    return 'Move $day';
  }

  @override
  String get moveDayBody =>
      'Spottr re-checks leg volume against your run days after the move.';

  @override
  String get moveDayOccupied => 'Already has a session';

  @override
  String get moveDayIsRunDay => 'You run this day';

  @override
  String noteUnfilledSlot(String slot) {
    return 'No $slot exercise fits your equipment and injuries, so that slot is empty.';
  }

  @override
  String noteLegVolumeReducedForRun(String day) {
    return 'Leg work on $day is lighter because you run the next day.';
  }

  @override
  String noteTrimmedForTime(String exercise) {
    return '$exercise was dropped to fit the session length you chose.';
  }

  @override
  String noteTemplateSimplified(String patterns) {
    return 'Your week uses full-body days instead of a split, because $patterns cannot be trained with your equipment and injuries.';
  }

  @override
  String noteDayUnderfilled(String day) {
    return '$day has less compound work than a full session. More equipment would fix it.';
  }

  @override
  String noteSessionShorterThanBudget(String minutes) {
    return 'Your longest session comes to about $minutes minutes. Adding more volume with the equipment you have would not be useful training.';
  }

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileSave => 'Save';

  @override
  String get profileRebuildWarning =>
      'Saving a change to your goal, days, session length, experience, equipment or injuries rebuilds your week.';

  @override
  String get exerciseBandAssistedPullUp => 'Band-Assisted Pull-Up';

  @override
  String get exerciseBarbellBackSquat => 'Barbell Back Squat';

  @override
  String get exerciseBarbellBenchPress => 'Barbell Bench Press';

  @override
  String get exerciseBarbellDeadlift => 'Barbell Deadlift';

  @override
  String get exerciseBarbellHipThrust => 'Barbell Hip Thrust';

  @override
  String get exerciseBarbellOverheadPress => 'Barbell Overhead Press';

  @override
  String get exerciseBarbellRomanianDeadlift => 'Barbell Romanian Deadlift';

  @override
  String get exerciseBarbellRow => 'Barbell Row';

  @override
  String get exerciseBirdDog => 'Bird Dog';

  @override
  String get exerciseBodyweightSquat => 'Bodyweight Squat';

  @override
  String get exerciseCableFly => 'Cable Fly';

  @override
  String get exerciseCableTricepsPushdown => 'Cable Triceps Pushdown';

  @override
  String get exerciseCalfRaise => 'Calf Raise';

  @override
  String get exerciseChestPressMachine => 'Chest Press Machine';

  @override
  String get exerciseDbBenchPress => 'Dumbbell Bench Press';

  @override
  String get exerciseDbBentOverRow => 'Dumbbell Bent-Over Row';

  @override
  String get exerciseDbCurl => 'Dumbbell Curl';

  @override
  String get exerciseDbFloorPress => 'Dumbbell Floor Press';

  @override
  String get exerciseDbHammerCurl => 'Dumbbell Hammer Curl';

  @override
  String get exerciseDbLateralRaise => 'Dumbbell Lateral Raise';

  @override
  String get exerciseDbLunge => 'Dumbbell Lunge';

  @override
  String get exerciseDbRomanianDeadlift => 'Dumbbell Romanian Deadlift';

  @override
  String get exerciseDbShoulderPress => 'Dumbbell Shoulder Press';

  @override
  String get exerciseDbSingleArmRow => 'Single-Arm Dumbbell Row';

  @override
  String get exerciseDbTricepsExtension => 'Dumbbell Triceps Extension';

  @override
  String get exerciseDeadBug => 'Dead Bug';

  @override
  String get exerciseFacePull => 'Face Pull';

  @override
  String get exerciseForwardLunge => 'Forward Lunge';

  @override
  String get exerciseGluteBridge => 'Glute Bridge';

  @override
  String get exerciseGobletSquat => 'Goblet Squat';

  @override
  String get exerciseHackSquat => 'Hack Squat';

  @override
  String get exerciseHangingKneeRaise => 'Hanging Knee Raise';

  @override
  String get exerciseInclinePushUp => 'Incline Push-Up';

  @override
  String get exerciseInvertedRow => 'Inverted Row';

  @override
  String get exerciseKneePushUp => 'Knee Push-Up';

  @override
  String get exerciseLatPulldown => 'Lat Pulldown';

  @override
  String get exerciseLegCurl => 'Leg Curl';

  @override
  String get exerciseLegExtension => 'Leg Extension';

  @override
  String get exerciseLegPress => 'Leg Press';

  @override
  String get exerciseMachineShoulderPress => 'Machine Shoulder Press';

  @override
  String get exerciseMountainClimber => 'Mountain Climber';

  @override
  String get exercisePikePushUp => 'Pike Push-Up';

  @override
  String get exercisePlank => 'Plank';

  @override
  String get exercisePullUp => 'Pull-Up';

  @override
  String get exercisePushUp => 'Push-Up';

  @override
  String get exerciseReverseLunge => 'Reverse Lunge';

  @override
  String get exerciseSeatedCableRow => 'Seated Cable Row';

  @override
  String get exerciseSeatedCalfRaise => 'Seated Calf Raise';

  @override
  String get exerciseSidePlank => 'Side Plank';

  @override
  String get exerciseSingleLegGluteBridge => 'Single-Leg Glute Bridge';

  @override
  String get exerciseSplitSquat => 'Split Squat';

  @override
  String get exerciseStepUp => 'Step-Up';

  @override
  String get exerciseSuperman => 'Superman';

  @override
  String get exerciseWallSit => 'Wall Sit';
}
