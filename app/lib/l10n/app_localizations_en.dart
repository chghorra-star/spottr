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
  String get coachTitle => 'Camera check';

  @override
  String get coachOpen => 'Coach this set';

  @override
  String get coachDone => 'Done';

  @override
  String get coachClaim =>
      'Spottr flags movement that looks risky. It cannot see everything, and it cannot guarantee you will not get hurt.';

  @override
  String get coachSetupTitle => 'Where to put your phone';

  @override
  String get coachDistance =>
      'Stand about two metres back, with the phone propped up around hip height.';

  @override
  String get coachAngleSide =>
      'Put the phone to one side of you, so the camera sees you from the side.';

  @override
  String get coachAngleFront => 'Put the phone in front of you, facing you.';

  @override
  String get coachNotSupportedTitle => 'No camera coaching for this one';

  @override
  String get coachNotSupportedBody =>
      'Spottr only coaches the movements it has rules for. Log this one by hand.';

  @override
  String get coachPermissionTitle => 'Spottr needs the camera';

  @override
  String get coachPermissionBody =>
      'The form coach runs on this device. Video is never uploaded and never leaves your phone.';

  @override
  String get coachPermissionAllow => 'Allow camera';

  @override
  String get coachPermissionBlockedTitle => 'Camera access is turned off';

  @override
  String get coachPermissionBlockedBody =>
      'Turn the camera on for Spottr in your device settings, then come back.';

  @override
  String get coachStarting => 'Opening the camera';

  @override
  String get coachErrorTitle => 'The camera could not start';

  @override
  String get coachErrorRetry => 'Try again';

  @override
  String get coachErrorPermission =>
      'Spottr does not have permission to use the camera.';

  @override
  String get coachErrorNoCamera =>
      'This device has no camera the coach can use yet.';

  @override
  String get coachErrorInUse =>
      'Another app is using the camera. Close it and try again.';

  @override
  String get coachErrorModel =>
      'The pose model stopped working. Try again, and restart Spottr if it keeps happening.';

  @override
  String get coachErrorBadFrame =>
      'Spottr could not read what the camera sent. This is a bug; please report it.';

  @override
  String get coachErrorUnknown => 'Something went wrong with the camera.';

  @override
  String get coachFramingGood => 'That works — I can see all of you.';

  @override
  String get coachFramingNoPerson =>
      'I cannot see anybody. Step into the frame.';

  @override
  String get coachFramingTooClose =>
      'Step back — part of you is outside the frame.';

  @override
  String get coachFramingTooFar =>
      'Come a little closer, or move the phone nearer.';

  @override
  String get coachFramingOffCentre => 'Move towards the middle of the frame.';

  @override
  String get coachFramingMissingSeveral =>
      'I can only see part of you. Step back, or re-aim the phone.';

  @override
  String get coachFramingMissingShoulders =>
      'I cannot see your shoulders. Tilt the phone up a little.';

  @override
  String get coachFramingMissingHips =>
      'I cannot see your hips. Re-aim the phone at your middle.';

  @override
  String get coachFramingMissingKnees =>
      'I cannot see your knees. Step back or tilt the phone down.';

  @override
  String get coachFramingMissingAnkles =>
      'I cannot see your ankles. Step back, or tilt the phone down.';

  @override
  String coachRepsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reps',
      one: 'rep',
    );
    return '$_temp0';
  }

  @override
  String get coachHeldLabel => 'held';

  @override
  String get coachRepGood => 'Good rep.';

  @override
  String get coachRepShallow =>
      'Counted, but short of depth — go lower on the next one.';

  @override
  String get coachRepPartial => 'Not counted: that was barely a dip.';

  @override
  String get coachRepTooFast => 'Not counted: too fast to be a real rep.';

  @override
  String get coachRepTimedOut => 'Not counted: that rep was never finished.';

  @override
  String get coachRepLostTracking =>
      'Not counted: I lost sight of you part way through.';

  @override
  String coachRepsNotCounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts not counted',
      one: '1 attempt not counted',
    );
    return '$_temp0';
  }

  @override
  String get coachHoldRunning => 'Holding. Keep going.';

  @override
  String get coachHoldOutOfPosition => 'Paused — get back into position.';

  @override
  String get coachHoldUntracked => 'Paused — I cannot see you.';

  @override
  String get coachCounterUnavailable =>
      'Spottr has no rep counter for this movement.';

  @override
  String get coachReady => 'Ready when you are.';

  @override
  String get coachStartSet => 'Start set';

  @override
  String get coachStopSet => 'Stop set';

  @override
  String coachSetOf(int number, int total) {
    return 'Set $number of $total';
  }

  @override
  String get coachSaveSet => 'Save this set';

  @override
  String get coachDiscardSet => 'Discard';

  @override
  String get coachSetSaved => 'Saved to your session.';

  @override
  String get coachSaveFailed => 'That set could not be saved.';

  @override
  String get coachNothingCounted =>
      'Nothing counted, so there is nothing to save.';

  @override
  String coachSummaryReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String coachSummaryHold(int seconds) {
    return '$seconds seconds';
  }

  @override
  String coachSummaryAt(String weight) {
    return 'at $weight';
  }

  @override
  String coachSummaryScore(int score) {
    return 'form $score';
  }

  @override
  String get coachSummaryNoScore => 'no form score';

  @override
  String get coachMute => 'Mute the coach';

  @override
  String get coachUnmute => 'Let the coach speak';

  @override
  String get coachSpeaking => 'Coach is speaking';

  @override
  String get coachTargetHype => 'That is the set. Great work.';

  @override
  String get coachTargetCalm => 'That is your target. Nicely done.';

  @override
  String get coachTargetTough => 'Target hit.';

  @override
  String get coachFormUntested =>
      'These form checks have not been measured against real training footage yet.';

  @override
  String get coachFormGood => 'Nothing to flag on that one.';

  @override
  String get coachFormWatching => 'Watching your form.';

  @override
  String coachFormScore(int score) {
    return 'Form $score';
  }

  @override
  String coachFormUnchecked(String rules) {
    return 'Not watching: $rules';
  }

  @override
  String get coachFormNothingWatched => 'No form checks run from this angle.';

  @override
  String get coachAdviceSquatDepth =>
      'Short of depth — get your hips below your knees.';

  @override
  String get coachAdviceLungeDepth =>
      'Drop the back knee further on the next one.';

  @override
  String get coachAdviceHingeDepth =>
      'Push your hips further back — you are stopping high.';

  @override
  String get coachAdviceBridgeLockout =>
      'Drive your hips all the way up at the top.';

  @override
  String get coachAdviceLockout => 'Straighten your arms out fully at the top.';

  @override
  String get coachAdvicePressLockout =>
      'Press all the way overhead — you are stopping short.';

  @override
  String get coachAdviceKneeBend =>
      'Your knees are bending — keep them long and move at the hips.';

  @override
  String get coachAdviceHipSag =>
      'Your hips are dropping — squeeze your glutes and hold the line.';

  @override
  String get coachAdviceHipPike =>
      'Your hips are riding high — bring them down into line.';

  @override
  String get coachAdviceNeckAlignment =>
      'Your head is hanging forward — look at the floor just ahead of you.';

  @override
  String get coachAdviceHeelLift =>
      'Your heels are coming up — keep them down.';

  @override
  String get coachAdviceTorsoLean => 'Stay upright — you are leaning into it.';

  @override
  String get coachAdviceBackArch =>
      'You are leaning back instead of pressing up.';

  @override
  String get coachAdviceTorsoSwing =>
      'Keep your torso still and let your arms do the work.';

  @override
  String get coachAdviceBackRounding =>
      'That looked like your back rounding. Stop the set and take weight off.';

  @override
  String get coachAdviceRom =>
      'These are getting shorter than your first few — stop the set when they do.';

  @override
  String get coachAdviceTempo =>
      'You are dropping into it — lower under control.';

  @override
  String get coachRuleSquatDepth => 'squat depth';

  @override
  String get coachRuleLungeDepth => 'lunge depth';

  @override
  String get coachRuleHingeDepth => 'hinge depth';

  @override
  String get coachRuleBridgeLockout => 'hip extension';

  @override
  String get coachRuleLockout => 'arm lockout';

  @override
  String get coachRulePressLockout => 'overhead lockout';

  @override
  String get coachRuleKneeBend => 'knee bend';

  @override
  String get coachRuleHipSag => 'hip sag';

  @override
  String get coachRuleHipPike => 'hip pike';

  @override
  String get coachRuleNeckAlignment => 'neck position';

  @override
  String get coachRuleHeelLift => 'heel lift';

  @override
  String get coachRuleTorsoLean => 'torso lean';

  @override
  String get coachRuleBackArch => 'back arch';

  @override
  String get coachRuleTorsoSwing => 'torso swing';

  @override
  String get coachRuleBackRounding => 'back rounding';

  @override
  String get coachRuleRom => 'range of motion';

  @override
  String get coachRuleTempo => 'tempo';

  @override
  String get coachRuleKneeValgus => 'knees falling in';

  @override
  String get coachRuleElbowFlare => 'elbow flare';

  @override
  String get coachRuleElbowPath => 'elbow path';

  @override
  String get coachRuleKneeTravel => 'knee travel';

  @override
  String get accountTitle => 'Account and sync';

  @override
  String get accountLocalFirstBody =>
      'Spottr works without an account. Signing in copies your plan and your training log to your other devices. Nothing from the camera is ever uploaded.';

  @override
  String get accountUnavailableTitle => 'Sync is not set up in this build';

  @override
  String get accountUnavailableBody =>
      'This copy of Spottr was built without a Supabase project, so there is nowhere to sync to. Everything else works as usual.';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountSignUp => 'Create an account';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String accountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String accountSignedOutOf(String email) {
    return 'Signed out of $email. This device still holds that training.';
  }

  @override
  String get accountEmailMissing => 'Enter the email address for your account.';

  @override
  String get accountPasswordMissing => 'Enter your password.';

  @override
  String get accountSyncNow => 'Sync now';

  @override
  String get accountSyncing => 'Syncing';

  @override
  String get accountSyncedNothing => 'Up to date. Nothing to send or fetch.';

  @override
  String accountSyncedCounts(int pushed, int pulled) {
    return 'Sent $pushed, fetched $pulled.';
  }

  @override
  String accountSyncConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes were made in two places; the later one was kept each time.',
      one: 'One change was made in two places; the later one was kept.',
    );
    return '$_temp0';
  }

  @override
  String get accountSyncStoppedOffline =>
      'Stopped: no connection. Your training is on this device and the next sync picks up where this one left off.';

  @override
  String get accountSyncStoppedUnauthorized =>
      'Stopped: your sign-in has expired. Sign in again to carry on syncing.';

  @override
  String accountSyncStoppedRejected(String detail) {
    return 'Stopped: the server refused a change. $detail';
  }

  @override
  String get authErrorInvalidCredentials =>
      'That email and password do not match an account.';

  @override
  String get authErrorEmailTaken =>
      'There is already an account with that email. Sign in instead.';

  @override
  String authErrorWeakPassword(String detail) {
    return 'That password was refused: $detail';
  }

  @override
  String get authErrorConfirmationRequired =>
      'Check your email and confirm the address, then sign in.';

  @override
  String get authErrorOffline =>
      'No connection. Nothing was changed on this device.';

  @override
  String authErrorRejected(String detail) {
    return 'The server refused the request: $detail';
  }

  @override
  String get authErrorForeignAccount =>
      'This device holds another account\'s training. Signing in as somebody else would move it into their account, so Spottr will not do it.';

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
