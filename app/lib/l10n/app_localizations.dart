import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name, shown in the task switcher and app bar.
  ///
  /// In en, this message translates to:
  /// **'Spottr'**
  String get appTitle;

  /// Heading of the mandatory safety screen shown during onboarding.
  ///
  /// In en, this message translates to:
  /// **'Before we start'**
  String get disclaimerTitle;

  /// Safety disclaimer. Wording is deliberate: feedback and flagging, never a promise of injury prevention.
  ///
  /// In en, this message translates to:
  /// **'Spottr gives you form feedback and flags movement that looks risky. It is not medical advice, and it cannot guarantee you will avoid injury. If you are injured or in pain, talk to a doctor or physiotherapist before training.'**
  String get disclaimerBody;

  /// Button that records acceptance of the safety disclaimer.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get disclaimerAccept;

  /// Shown if the user tries to get past the disclaimer without accepting. There is no way around this screen.
  ///
  /// In en, this message translates to:
  /// **'Spottr needs you to read this before it builds you a plan.'**
  String get disclaimerRequired;

  /// Always-visible button during a set. Ends the set and logs it.
  ///
  /// In en, this message translates to:
  /// **'I feel pain'**
  String get painButton;

  /// Heading of the post-set summary sheet.
  ///
  /// In en, this message translates to:
  /// **'Set done'**
  String get setSummaryTitle;

  /// Rep tally in the set summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reps counted} =1{1 rep} other{{count} reps}}'**
  String repsCounted(int count);

  /// Spoken and shown near the end of a set.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last one} other{{count} to go}}'**
  String repsRemaining(int count);

  /// Form score for a rep or a set, 0 to 100.
  ///
  /// In en, this message translates to:
  /// **'Form {score}%'**
  String formScoreLabel(int score);

  /// Fired when the camera angle cannot support the depth and back rules.
  ///
  /// In en, this message translates to:
  /// **'Turn the phone to the side so I can see your depth'**
  String get cueTurnPhoneSideways;

  /// Fired when pose tracking drops out mid-set. Counting pauses.
  ///
  /// In en, this message translates to:
  /// **'I lost you — step back into frame'**
  String get cueTrackingLost;

  /// Coach personality option: energetic and loud.
  ///
  /// In en, this message translates to:
  /// **'Hype'**
  String get coachStyleHype;

  /// No description provided for @coachStyleHypeDetail.
  ///
  /// In en, this message translates to:
  /// **'Loud, fast, and all in. Expect to be shouted at in a good way.'**
  String get coachStyleHypeDetail;

  /// Coach personality option: technical and encouraging.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get coachStyleCalm;

  /// No description provided for @coachStyleCalmDetail.
  ///
  /// In en, this message translates to:
  /// **'Quieter and more technical. Mostly about where your body is.'**
  String get coachStyleCalmDetail;

  /// Coach personality option: direct, drill-sergeant.
  ///
  /// In en, this message translates to:
  /// **'Tough'**
  String get coachStyleTough;

  /// No description provided for @coachStyleToughDetail.
  ///
  /// In en, this message translates to:
  /// **'Blunt and demanding. Never tells you to push through pain.'**
  String get coachStyleToughDetail;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Build my plan'**
  String get onboardingFinish;

  /// Position in the onboarding flow.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingProgress(int current, int total);

  /// No description provided for @stepGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you training for?'**
  String get stepGoalTitle;

  /// No description provided for @stepDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'How many days a week can you train?'**
  String get stepDaysTitle;

  /// No description provided for @stepDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day a week} other{{count} days a week}}'**
  String stepDaysValue(int count);

  /// No description provided for @stepSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'How long is a session?'**
  String get stepSessionTitle;

  /// No description provided for @stepSessionValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String stepSessionValue(int minutes);

  /// No description provided for @stepSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr trims a session to fit rather than handing you a workout you cannot finish.'**
  String get stepSessionBody;

  /// No description provided for @stepLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'How much training experience do you have?'**
  String get stepLevelTitle;

  /// No description provided for @stepBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'A few optional details'**
  String get stepBodyTitle;

  /// No description provided for @stepBodyBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr does not need any of these to build your plan. Leave anything blank.'**
  String get stepBodyBody;

  /// No description provided for @fieldAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get fieldAge;

  /// No description provided for @fieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height in cm'**
  String get fieldHeight;

  /// No description provided for @fieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight in kg'**
  String get fieldWeight;

  /// No description provided for @fieldSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get fieldSex;

  /// No description provided for @stepInjuriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Anything hurting?'**
  String get stepInjuriesTitle;

  /// No description provided for @stepInjuriesBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr leaves out exercises that load an injured area. This is not medical advice — if something hurts, see a professional.'**
  String get stepInjuriesBody;

  /// No description provided for @fieldInjuryNotes.
  ///
  /// In en, this message translates to:
  /// **'Anything else we should know?'**
  String get fieldInjuryNotes;

  /// No description provided for @fieldInjuryNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Spottr shows this back to you and does not try to interpret it.'**
  String get fieldInjuryNotesHint;

  /// No description provided for @stepLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you train?'**
  String get stepLocationTitle;

  /// No description provided for @stepEquipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Anything else you have?'**
  String get stepEquipmentTitle;

  /// No description provided for @stepEquipmentBody.
  ///
  /// In en, this message translates to:
  /// **'Pick what you can actually reach. Spottr only prescribes what you can do.'**
  String get stepEquipmentBody;

  /// No description provided for @stepRunDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Which days do you run?'**
  String get stepRunDaysTitle;

  /// No description provided for @stepRunDaysBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr keeps heavy leg work off the day before a run, and suggests runs in text. It never tracks your runs.'**
  String get stepRunDaysBody;

  /// No description provided for @stepCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'How should your coach sound?'**
  String get stepCoachTitle;

  /// No description provided for @stepCoachBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this whenever you like.'**
  String get stepCoachBody;

  /// No description provided for @goalWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Lose fat'**
  String get goalWeightLoss;

  /// No description provided for @goalWeightLossDetail.
  ///
  /// In en, this message translates to:
  /// **'Higher reps and shorter rest, so more work fits in the time you have.'**
  String get goalWeightLossDetail;

  /// No description provided for @goalMuscleBuilding.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get goalMuscleBuilding;

  /// No description provided for @goalMuscleBuildingDetail.
  ///
  /// In en, this message translates to:
  /// **'Moderate reps and longer rest, so you can load each set properly.'**
  String get goalMuscleBuildingDetail;

  /// No description provided for @goalHybrid.
  ///
  /// In en, this message translates to:
  /// **'Gym and running'**
  String get goalHybrid;

  /// No description provided for @goalHybridDetail.
  ///
  /// In en, this message translates to:
  /// **'Gym sessions scheduled around your runs. Spottr does not track the runs themselves.'**
  String get goalHybridDetail;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'New to this'**
  String get levelBeginner;

  /// No description provided for @levelBeginnerDetail.
  ///
  /// In en, this message translates to:
  /// **'Under a year of consistent training, or starting again.'**
  String get levelBeginnerDetail;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get levelIntermediate;

  /// No description provided for @levelIntermediateDetail.
  ///
  /// In en, this message translates to:
  /// **'A year or more, and you know the main lifts.'**
  String get levelIntermediateDetail;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Experienced'**
  String get levelAdvanced;

  /// No description provided for @levelAdvancedDetail.
  ///
  /// In en, this message translates to:
  /// **'Several years, and you program for yourself already.'**
  String get levelAdvancedDetail;

  /// No description provided for @locationHomeNone.
  ///
  /// In en, this message translates to:
  /// **'Home, no equipment'**
  String get locationHomeNone;

  /// No description provided for @locationHomeNoneDetail.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight only.'**
  String get locationHomeNoneDetail;

  /// No description provided for @locationHomeDumbbells.
  ///
  /// In en, this message translates to:
  /// **'Home with dumbbells'**
  String get locationHomeDumbbells;

  /// No description provided for @locationHomeDumbbellsDetail.
  ///
  /// In en, this message translates to:
  /// **'A pair of dumbbells, adjustable or fixed.'**
  String get locationHomeDumbbellsDetail;

  /// No description provided for @locationFullGym.
  ///
  /// In en, this message translates to:
  /// **'Full gym'**
  String get locationFullGym;

  /// No description provided for @locationFullGymDetail.
  ///
  /// In en, this message translates to:
  /// **'Barbells, machines, cables, benches.'**
  String get locationFullGymDetail;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get sexPreferNotToSay;

  /// No description provided for @equipmentDumbbells.
  ///
  /// In en, this message translates to:
  /// **'Dumbbells'**
  String get equipmentDumbbells;

  /// No description provided for @equipmentBarbell.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get equipmentBarbell;

  /// No description provided for @equipmentKettlebell.
  ///
  /// In en, this message translates to:
  /// **'Kettlebell'**
  String get equipmentKettlebell;

  /// No description provided for @equipmentBench.
  ///
  /// In en, this message translates to:
  /// **'Bench'**
  String get equipmentBench;

  /// No description provided for @equipmentPullUpBar.
  ///
  /// In en, this message translates to:
  /// **'Pull-up bar'**
  String get equipmentPullUpBar;

  /// No description provided for @equipmentDipBars.
  ///
  /// In en, this message translates to:
  /// **'Dip bars'**
  String get equipmentDipBars;

  /// No description provided for @equipmentCableMachine.
  ///
  /// In en, this message translates to:
  /// **'Cable machine'**
  String get equipmentCableMachine;

  /// No description provided for @equipmentMachine.
  ///
  /// In en, this message translates to:
  /// **'Weight machines'**
  String get equipmentMachine;

  /// No description provided for @equipmentResistanceBand.
  ///
  /// In en, this message translates to:
  /// **'Resistance band'**
  String get equipmentResistanceBand;

  /// No description provided for @equipmentBox.
  ///
  /// In en, this message translates to:
  /// **'Box or sturdy step'**
  String get equipmentBox;

  /// No description provided for @bodyPartKnees.
  ///
  /// In en, this message translates to:
  /// **'Knees'**
  String get bodyPartKnees;

  /// No description provided for @bodyPartLowerBack.
  ///
  /// In en, this message translates to:
  /// **'Lower back'**
  String get bodyPartLowerBack;

  /// No description provided for @bodyPartShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get bodyPartShoulders;

  /// No description provided for @bodyPartWrists.
  ///
  /// In en, this message translates to:
  /// **'Wrists'**
  String get bodyPartWrists;

  /// No description provided for @bodyPartHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get bodyPartHips;

  /// No description provided for @bodyPartAnkles.
  ///
  /// In en, this message translates to:
  /// **'Ankles'**
  String get bodyPartAnkles;

  /// No description provided for @bodyPartElbows.
  ///
  /// In en, this message translates to:
  /// **'Elbows'**
  String get bodyPartElbows;

  /// No description provided for @bodyPartNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get bodyPartNeck;

  /// No description provided for @muscleQuads.
  ///
  /// In en, this message translates to:
  /// **'Quads'**
  String get muscleQuads;

  /// No description provided for @muscleHamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get muscleHamstrings;

  /// No description provided for @muscleGlutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get muscleGlutes;

  /// No description provided for @muscleCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get muscleCalves;

  /// No description provided for @muscleAdductors.
  ///
  /// In en, this message translates to:
  /// **'Inner thigh'**
  String get muscleAdductors;

  /// No description provided for @muscleAbductors.
  ///
  /// In en, this message translates to:
  /// **'Outer hip'**
  String get muscleAbductors;

  /// No description provided for @muscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleChest;

  /// No description provided for @muscleLats.
  ///
  /// In en, this message translates to:
  /// **'Lats'**
  String get muscleLats;

  /// No description provided for @muscleUpperBack.
  ///
  /// In en, this message translates to:
  /// **'Upper back'**
  String get muscleUpperBack;

  /// No description provided for @muscleLowerBack.
  ///
  /// In en, this message translates to:
  /// **'Lower back'**
  String get muscleLowerBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get muscleTriceps;

  /// No description provided for @muscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get muscleForearms;

  /// No description provided for @muscleCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get muscleCore;

  /// No description provided for @muscleObliques.
  ///
  /// In en, this message translates to:
  /// **'Obliques'**
  String get muscleObliques;

  /// No description provided for @patternSquat.
  ///
  /// In en, this message translates to:
  /// **'Squat'**
  String get patternSquat;

  /// No description provided for @patternHinge.
  ///
  /// In en, this message translates to:
  /// **'Hinge'**
  String get patternHinge;

  /// No description provided for @patternLunge.
  ///
  /// In en, this message translates to:
  /// **'Lunge'**
  String get patternLunge;

  /// No description provided for @patternHorizontalPush.
  ///
  /// In en, this message translates to:
  /// **'Pressing'**
  String get patternHorizontalPush;

  /// No description provided for @patternVerticalPush.
  ///
  /// In en, this message translates to:
  /// **'Overhead pressing'**
  String get patternVerticalPush;

  /// No description provided for @patternHorizontalPull.
  ///
  /// In en, this message translates to:
  /// **'Rowing'**
  String get patternHorizontalPull;

  /// No description provided for @patternVerticalPull.
  ///
  /// In en, this message translates to:
  /// **'Pulling up'**
  String get patternVerticalPull;

  /// No description provided for @patternCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get patternCore;

  /// No description provided for @patternIsolation.
  ///
  /// In en, this message translates to:
  /// **'Isolation'**
  String get patternIsolation;

  /// No description provided for @patternCarry.
  ///
  /// In en, this message translates to:
  /// **'Carry'**
  String get patternCarry;

  /// No description provided for @dayFullBody.
  ///
  /// In en, this message translates to:
  /// **'Full body'**
  String get dayFullBody;

  /// No description provided for @dayUpper.
  ///
  /// In en, this message translates to:
  /// **'Upper body'**
  String get dayUpper;

  /// No description provided for @dayLower.
  ///
  /// In en, this message translates to:
  /// **'Lower body'**
  String get dayLower;

  /// No description provided for @dayPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get dayPush;

  /// No description provided for @dayPull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get dayPull;

  /// No description provided for @dayLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get dayLegs;

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @runSuggestionEasy20.
  ///
  /// In en, this message translates to:
  /// **'Easy 20 minutes, conversational pace.'**
  String get runSuggestionEasy20;

  /// No description provided for @runSuggestionSteady35.
  ///
  /// In en, this message translates to:
  /// **'Steady 35 minutes at a pace you could hold for an hour.'**
  String get runSuggestionSteady35;

  /// No description provided for @runSuggestionTempo45.
  ///
  /// In en, this message translates to:
  /// **'45 minutes with 20 at tempo in the middle.'**
  String get runSuggestionTempo45;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get planTitle;

  /// No description provided for @planEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get planEmptyTitle;

  /// No description provided for @planEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Answer a few questions and Spottr will build your week.'**
  String get planEmptyBody;

  /// No description provided for @planEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get planEmptyAction;

  /// No description provided for @planErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Spottr could not load your plan'**
  String get planErrorTitle;

  /// No description provided for @planErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get planErrorRetry;

  /// No description provided for @planRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Rebuild my week'**
  String get planRegenerate;

  /// No description provided for @planRegenerateBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr will build a fresh week from your profile. Any swaps or reordering you did will be lost.'**
  String get planRegenerateBody;

  /// No description provided for @planRegenerateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Rebuild'**
  String get planRegenerateConfirm;

  /// No description provided for @planCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get planCancel;

  /// Subtitle on a day card. The minute figure is an estimate including a warm-up.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}} · about {minutes} min'**
  String planDaySummary(int count, int minutes);

  /// No description provided for @planPreRunBadge.
  ///
  /// In en, this message translates to:
  /// **'You run tomorrow'**
  String get planPreRunBadge;

  /// Sets and the target rep range.
  ///
  /// In en, this message translates to:
  /// **'{sets} × {min}–{max}'**
  String planSetsReps(int sets, int min, int max);

  /// No description provided for @planSetsHold.
  ///
  /// In en, this message translates to:
  /// **'{sets} × {seconds}s hold'**
  String planSetsHold(int sets, int seconds);

  /// No description provided for @planRestBetweenSets.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s rest'**
  String planRestBetweenSets(int seconds);

  /// No description provided for @planCameraCoachedDetail.
  ///
  /// In en, this message translates to:
  /// **'Spottr can count your reps and watch your form on this one.'**
  String get planCameraCoachedDetail;

  /// No description provided for @planRunSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'On your run days'**
  String get planRunSuggestionsTitle;

  /// No description provided for @planNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Why your week looks like this'**
  String get planNotesTitle;

  /// No description provided for @planActionSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap this exercise'**
  String get planActionSwap;

  /// No description provided for @planActionMoveDay.
  ///
  /// In en, this message translates to:
  /// **'Move this day'**
  String get planActionMoveDay;

  /// No description provided for @planActionReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get planActionReorder;

  /// No description provided for @planReorderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planReorderDone;

  /// No description provided for @planReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Spottr keeps the sets and reps you already have.'**
  String get planReorderHint;

  /// No description provided for @swapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap {exercise}'**
  String swapTitle(String exercise);

  /// No description provided for @swapBody.
  ///
  /// In en, this message translates to:
  /// **'Alternatives that do the same job and fit your equipment and injuries.'**
  String get swapBody;

  /// No description provided for @swapNoAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Nothing else in the catalog does this job with the equipment you have.'**
  String get swapNoAlternatives;

  /// No description provided for @swapTargets.
  ///
  /// In en, this message translates to:
  /// **'Works {muscles}'**
  String swapTargets(String muscles);

  /// No description provided for @moveDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Move {day}'**
  String moveDayTitle(String day);

  /// No description provided for @moveDayBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr re-checks leg volume against your run days after the move.'**
  String get moveDayBody;

  /// No description provided for @moveDayOccupied.
  ///
  /// In en, this message translates to:
  /// **'Already has a session'**
  String get moveDayOccupied;

  /// No description provided for @moveDayIsRunDay.
  ///
  /// In en, this message translates to:
  /// **'You run this day'**
  String get moveDayIsRunDay;

  /// Plan note. Shown rather than hidden so a short session looks explained instead of broken.
  ///
  /// In en, this message translates to:
  /// **'No {slot} exercise fits your equipment and injuries, so that slot is empty.'**
  String noteUnfilledSlot(String slot);

  /// One note per day, not one per exercise: the rule caps every movement that loads the legs, which on a leg day is most of them.
  ///
  /// In en, this message translates to:
  /// **'Leg work on {day} is lighter because you run the next day.'**
  String noteLegVolumeReducedForRun(String day);

  /// No description provided for @noteTrimmedForTime.
  ///
  /// In en, this message translates to:
  /// **'{exercise} was dropped to fit the session length you chose.'**
  String noteTrimmedForTime(String exercise);

  /// A split would have left a whole day with nothing in it, so the generator abandoned it.
  ///
  /// In en, this message translates to:
  /// **'Your week uses full-body days instead of a split, because {patterns} cannot be trained with your equipment and injuries.'**
  String noteTemplateSimplified(String patterns);

  /// No description provided for @noteDayUnderfilled.
  ///
  /// In en, this message translates to:
  /// **'{day} has less compound work than a full session. More equipment would fix it.'**
  String noteDayUnderfilled(String day);

  /// Said once for the week when every session fell well short of the length the user chose. Padding the session out would be worse than saying so.
  ///
  /// In en, this message translates to:
  /// **'Your longest session comes to about {minutes} minutes. Adding more volume with the equipment you have would not be useful training.'**
  String noteSessionShorterThanBudget(String minutes);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileRebuildWarning.
  ///
  /// In en, this message translates to:
  /// **'Saving a change to your goal, days, session length, experience, equipment or injuries rebuilds your week.'**
  String get profileRebuildWarning;

  /// No description provided for @exerciseBandAssistedPullUp.
  ///
  /// In en, this message translates to:
  /// **'Band-Assisted Pull-Up'**
  String get exerciseBandAssistedPullUp;

  /// No description provided for @exerciseBarbellBackSquat.
  ///
  /// In en, this message translates to:
  /// **'Barbell Back Squat'**
  String get exerciseBarbellBackSquat;

  /// No description provided for @exerciseBarbellBenchPress.
  ///
  /// In en, this message translates to:
  /// **'Barbell Bench Press'**
  String get exerciseBarbellBenchPress;

  /// No description provided for @exerciseBarbellDeadlift.
  ///
  /// In en, this message translates to:
  /// **'Barbell Deadlift'**
  String get exerciseBarbellDeadlift;

  /// No description provided for @exerciseBarbellHipThrust.
  ///
  /// In en, this message translates to:
  /// **'Barbell Hip Thrust'**
  String get exerciseBarbellHipThrust;

  /// No description provided for @exerciseBarbellOverheadPress.
  ///
  /// In en, this message translates to:
  /// **'Barbell Overhead Press'**
  String get exerciseBarbellOverheadPress;

  /// No description provided for @exerciseBarbellRomanianDeadlift.
  ///
  /// In en, this message translates to:
  /// **'Barbell Romanian Deadlift'**
  String get exerciseBarbellRomanianDeadlift;

  /// No description provided for @exerciseBarbellRow.
  ///
  /// In en, this message translates to:
  /// **'Barbell Row'**
  String get exerciseBarbellRow;

  /// No description provided for @exerciseBirdDog.
  ///
  /// In en, this message translates to:
  /// **'Bird Dog'**
  String get exerciseBirdDog;

  /// No description provided for @exerciseBodyweightSquat.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight Squat'**
  String get exerciseBodyweightSquat;

  /// No description provided for @exerciseCableFly.
  ///
  /// In en, this message translates to:
  /// **'Cable Fly'**
  String get exerciseCableFly;

  /// No description provided for @exerciseCableTricepsPushdown.
  ///
  /// In en, this message translates to:
  /// **'Cable Triceps Pushdown'**
  String get exerciseCableTricepsPushdown;

  /// No description provided for @exerciseCalfRaise.
  ///
  /// In en, this message translates to:
  /// **'Calf Raise'**
  String get exerciseCalfRaise;

  /// No description provided for @exerciseChestPressMachine.
  ///
  /// In en, this message translates to:
  /// **'Chest Press Machine'**
  String get exerciseChestPressMachine;

  /// No description provided for @exerciseDbBenchPress.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Bench Press'**
  String get exerciseDbBenchPress;

  /// No description provided for @exerciseDbBentOverRow.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Bent-Over Row'**
  String get exerciseDbBentOverRow;

  /// No description provided for @exerciseDbCurl.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Curl'**
  String get exerciseDbCurl;

  /// No description provided for @exerciseDbFloorPress.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Floor Press'**
  String get exerciseDbFloorPress;

  /// No description provided for @exerciseDbHammerCurl.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Hammer Curl'**
  String get exerciseDbHammerCurl;

  /// No description provided for @exerciseDbLateralRaise.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Lateral Raise'**
  String get exerciseDbLateralRaise;

  /// No description provided for @exerciseDbLunge.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Lunge'**
  String get exerciseDbLunge;

  /// No description provided for @exerciseDbRomanianDeadlift.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Romanian Deadlift'**
  String get exerciseDbRomanianDeadlift;

  /// No description provided for @exerciseDbShoulderPress.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Shoulder Press'**
  String get exerciseDbShoulderPress;

  /// No description provided for @exerciseDbSingleArmRow.
  ///
  /// In en, this message translates to:
  /// **'Single-Arm Dumbbell Row'**
  String get exerciseDbSingleArmRow;

  /// No description provided for @exerciseDbTricepsExtension.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell Triceps Extension'**
  String get exerciseDbTricepsExtension;

  /// No description provided for @exerciseDeadBug.
  ///
  /// In en, this message translates to:
  /// **'Dead Bug'**
  String get exerciseDeadBug;

  /// No description provided for @exerciseFacePull.
  ///
  /// In en, this message translates to:
  /// **'Face Pull'**
  String get exerciseFacePull;

  /// No description provided for @exerciseForwardLunge.
  ///
  /// In en, this message translates to:
  /// **'Forward Lunge'**
  String get exerciseForwardLunge;

  /// No description provided for @exerciseGluteBridge.
  ///
  /// In en, this message translates to:
  /// **'Glute Bridge'**
  String get exerciseGluteBridge;

  /// No description provided for @exerciseGobletSquat.
  ///
  /// In en, this message translates to:
  /// **'Goblet Squat'**
  String get exerciseGobletSquat;

  /// No description provided for @exerciseHackSquat.
  ///
  /// In en, this message translates to:
  /// **'Hack Squat'**
  String get exerciseHackSquat;

  /// No description provided for @exerciseHangingKneeRaise.
  ///
  /// In en, this message translates to:
  /// **'Hanging Knee Raise'**
  String get exerciseHangingKneeRaise;

  /// No description provided for @exerciseInclinePushUp.
  ///
  /// In en, this message translates to:
  /// **'Incline Push-Up'**
  String get exerciseInclinePushUp;

  /// No description provided for @exerciseInvertedRow.
  ///
  /// In en, this message translates to:
  /// **'Inverted Row'**
  String get exerciseInvertedRow;

  /// No description provided for @exerciseKneePushUp.
  ///
  /// In en, this message translates to:
  /// **'Knee Push-Up'**
  String get exerciseKneePushUp;

  /// No description provided for @exerciseLatPulldown.
  ///
  /// In en, this message translates to:
  /// **'Lat Pulldown'**
  String get exerciseLatPulldown;

  /// No description provided for @exerciseLegCurl.
  ///
  /// In en, this message translates to:
  /// **'Leg Curl'**
  String get exerciseLegCurl;

  /// No description provided for @exerciseLegExtension.
  ///
  /// In en, this message translates to:
  /// **'Leg Extension'**
  String get exerciseLegExtension;

  /// No description provided for @exerciseLegPress.
  ///
  /// In en, this message translates to:
  /// **'Leg Press'**
  String get exerciseLegPress;

  /// No description provided for @exerciseMachineShoulderPress.
  ///
  /// In en, this message translates to:
  /// **'Machine Shoulder Press'**
  String get exerciseMachineShoulderPress;

  /// No description provided for @exerciseMountainClimber.
  ///
  /// In en, this message translates to:
  /// **'Mountain Climber'**
  String get exerciseMountainClimber;

  /// No description provided for @exercisePikePushUp.
  ///
  /// In en, this message translates to:
  /// **'Pike Push-Up'**
  String get exercisePikePushUp;

  /// No description provided for @exercisePlank.
  ///
  /// In en, this message translates to:
  /// **'Plank'**
  String get exercisePlank;

  /// No description provided for @exercisePullUp.
  ///
  /// In en, this message translates to:
  /// **'Pull-Up'**
  String get exercisePullUp;

  /// No description provided for @exercisePushUp.
  ///
  /// In en, this message translates to:
  /// **'Push-Up'**
  String get exercisePushUp;

  /// No description provided for @exerciseReverseLunge.
  ///
  /// In en, this message translates to:
  /// **'Reverse Lunge'**
  String get exerciseReverseLunge;

  /// No description provided for @exerciseSeatedCableRow.
  ///
  /// In en, this message translates to:
  /// **'Seated Cable Row'**
  String get exerciseSeatedCableRow;

  /// No description provided for @exerciseSeatedCalfRaise.
  ///
  /// In en, this message translates to:
  /// **'Seated Calf Raise'**
  String get exerciseSeatedCalfRaise;

  /// No description provided for @exerciseSidePlank.
  ///
  /// In en, this message translates to:
  /// **'Side Plank'**
  String get exerciseSidePlank;

  /// No description provided for @exerciseSingleLegGluteBridge.
  ///
  /// In en, this message translates to:
  /// **'Single-Leg Glute Bridge'**
  String get exerciseSingleLegGluteBridge;

  /// No description provided for @exerciseSplitSquat.
  ///
  /// In en, this message translates to:
  /// **'Split Squat'**
  String get exerciseSplitSquat;

  /// No description provided for @exerciseStepUp.
  ///
  /// In en, this message translates to:
  /// **'Step-Up'**
  String get exerciseStepUp;

  /// No description provided for @exerciseSuperman.
  ///
  /// In en, this message translates to:
  /// **'Superman'**
  String get exerciseSuperman;

  /// No description provided for @exerciseWallSit.
  ///
  /// In en, this message translates to:
  /// **'Wall Sit'**
  String get exerciseWallSit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
