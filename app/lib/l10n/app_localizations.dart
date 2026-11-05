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

  /// No description provided for @planActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get planActionStart;

  /// No description provided for @planActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get planActionResume;

  /// No description provided for @planSessionElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Finish the session you already have open first.'**
  String get planSessionElsewhere;

  /// No description provided for @sessionElapsed.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min in'**
  String sessionElapsed(int minutes);

  /// The load progression picked from the last session on this exercise.
  ///
  /// In en, this message translates to:
  /// **'Target {weight} kg'**
  String sessionTargetWeight(String weight);

  /// No description provided for @sessionNoTarget.
  ///
  /// In en, this message translates to:
  /// **'No target yet — log what you use'**
  String get sessionNoTarget;

  /// No description provided for @sessionSetsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} sets'**
  String sessionSetsDone(int done, int total);

  /// No description provided for @sessionExerciseDone.
  ///
  /// In en, this message translates to:
  /// **'All sets done'**
  String get sessionExerciseDone;

  /// No description provided for @sessionRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get sessionRepsLabel;

  /// No description provided for @sessionHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get sessionHoldLabel;

  /// No description provided for @sessionWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get sessionWeightLabel;

  /// No description provided for @sessionLogSet.
  ///
  /// In en, this message translates to:
  /// **'Save set {number}'**
  String sessionLogSet(int number);

  /// No description provided for @sessionLoggedSetReps.
  ///
  /// In en, this message translates to:
  /// **'{reps} reps'**
  String sessionLoggedSetReps(int reps);

  /// No description provided for @sessionLoggedSetRepsWeighted.
  ///
  /// In en, this message translates to:
  /// **'{reps} × {weight} kg'**
  String sessionLoggedSetRepsWeighted(int reps, String weight);

  /// No description provided for @sessionLoggedSetHold.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String sessionLoggedSetHold(int seconds);

  /// No description provided for @sessionNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'A number, please'**
  String get sessionNumberRequired;

  /// No description provided for @sessionPainButton.
  ///
  /// In en, this message translates to:
  /// **'I feel pain'**
  String get sessionPainButton;

  /// No description provided for @sessionPainTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop this set'**
  String get sessionPainTitle;

  /// No description provided for @sessionPainBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr will end the set and log that it hurt, and nothing in your plan will go up. Do not train through pain — if it does not settle, see a professional.'**
  String get sessionPainBody;

  /// No description provided for @sessionPainConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop and log it'**
  String get sessionPainConfirm;

  /// No description provided for @sessionPainBadge.
  ///
  /// In en, this message translates to:
  /// **'Pain reported'**
  String get sessionPainBadge;

  /// No description provided for @sessionFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get sessionFinish;

  /// No description provided for @sessionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard session'**
  String get sessionDiscard;

  /// No description provided for @sessionDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Throw this session away?'**
  String get sessionDiscardTitle;

  /// No description provided for @sessionDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you logged goes with it, and your plan stays exactly as it is.'**
  String get sessionDiscardBody;

  /// No description provided for @sessionDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard it'**
  String get sessionDiscardConfirm;

  /// No description provided for @sessionRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'How did that feel?'**
  String get sessionRatingTitle;

  /// No description provided for @sessionRatingBody.
  ///
  /// In en, this message translates to:
  /// **'This is the one thing Spottr cannot see, and it decides what you lift next time.'**
  String get sessionRatingBody;

  /// No description provided for @sessionRatingSkip.
  ///
  /// In en, this message translates to:
  /// **'Rather not say'**
  String get sessionRatingSkip;

  /// No description provided for @ratingTooEasy.
  ///
  /// In en, this message translates to:
  /// **'Too easy'**
  String get ratingTooEasy;

  /// No description provided for @ratingTooEasyDetail.
  ///
  /// In en, this message translates to:
  /// **'I had plenty left in the tank'**
  String get ratingTooEasyDetail;

  /// No description provided for @ratingRight.
  ///
  /// In en, this message translates to:
  /// **'About right'**
  String get ratingRight;

  /// No description provided for @ratingRightDetail.
  ///
  /// In en, this message translates to:
  /// **'Hard, but I finished it'**
  String get ratingRightDetail;

  /// No description provided for @ratingTooHard.
  ///
  /// In en, this message translates to:
  /// **'Too hard'**
  String get ratingTooHard;

  /// No description provided for @ratingTooHardDetail.
  ///
  /// In en, this message translates to:
  /// **'I could not finish it properly'**
  String get ratingTooHardDetail;

  /// No description provided for @sessionSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Next time'**
  String get sessionSummaryTitle;

  /// No description provided for @sessionSummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your plan stays as it is next time.'**
  String get sessionSummaryEmpty;

  /// No description provided for @sessionSummaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sessionSummaryDone;

  /// One line per exercise: what changes, then why it changed.
  ///
  /// In en, this message translates to:
  /// **'{change} — {reason}'**
  String sessionSummaryLine(String change, String reason);

  /// No description provided for @sessionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned here'**
  String get sessionEmptyTitle;

  /// No description provided for @sessionEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This day has no session in your current plan.'**
  String get sessionEmptyBody;

  /// No description provided for @progressionWeightUp.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg next time'**
  String progressionWeightUp(String weight);

  /// No description provided for @progressionWeightDown.
  ///
  /// In en, this message translates to:
  /// **'Down to {weight} kg'**
  String progressionWeightDown(String weight);

  /// No description provided for @progressionRepsUp.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} reps next time'**
  String progressionRepsUp(int min, int max);

  /// No description provided for @progressionHoldUp.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds next time'**
  String progressionHoldUp(int seconds);

  /// No description provided for @progressionMovingUp.
  ///
  /// In en, this message translates to:
  /// **'Moving up to {exercise}'**
  String progressionMovingUp(String exercise);

  /// No description provided for @progressionMovingDown.
  ///
  /// In en, this message translates to:
  /// **'Easing back to {exercise}'**
  String progressionMovingDown(String exercise);

  /// No description provided for @progressionUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Same again next time'**
  String get progressionUnchanged;

  /// Wraps a progression line once the camera has a form score for it. Unused until the coach lands, and worded so it reads as part of the reason.
  ///
  /// In en, this message translates to:
  /// **'{change} at {score}% form'**
  String progressionFormSuffix(String change, int score);

  /// No description provided for @reasonPainReported.
  ///
  /// In en, this message translates to:
  /// **'you told us something hurt, so nothing goes up. If it does not settle, see a professional'**
  String get reasonPainReported;

  /// No description provided for @reasonSessionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'you did not get through every set'**
  String get reasonSessionIncomplete;

  /// No description provided for @reasonEarnedLoad.
  ///
  /// In en, this message translates to:
  /// **'you hit all {reps} on every set'**
  String reasonEarnedLoad(int reps);

  /// No description provided for @reasonEarnedLoadPlain.
  ///
  /// In en, this message translates to:
  /// **'you finished every set at the target'**
  String get reasonEarnedLoadPlain;

  /// No description provided for @reasonEarnedReps.
  ///
  /// In en, this message translates to:
  /// **'you reached the top of the range on every set'**
  String get reasonEarnedReps;

  /// No description provided for @reasonEarnedHold.
  ///
  /// In en, this message translates to:
  /// **'you held every set to the target'**
  String get reasonEarnedHold;

  /// No description provided for @reasonEarnedHarderVariant.
  ///
  /// In en, this message translates to:
  /// **'reps have gone as far as they usefully can'**
  String get reasonEarnedHarderVariant;

  /// No description provided for @reasonRatedTooEasy.
  ///
  /// In en, this message translates to:
  /// **'you said it was too easy'**
  String get reasonRatedTooEasy;

  /// No description provided for @reasonFormBreakingDown.
  ///
  /// In en, this message translates to:
  /// **'your form has slipped two sessions running'**
  String get reasonFormBreakingDown;

  /// No description provided for @reasonFormWatch.
  ///
  /// In en, this message translates to:
  /// **'your form slipped on this one, so Spottr is holding steady'**
  String get reasonFormWatch;

  /// No description provided for @reasonMissedReps.
  ///
  /// In en, this message translates to:
  /// **'{reps} on your hardest set was short of the target'**
  String reasonMissedReps(int reps);

  /// No description provided for @reasonMissedRepsPlain.
  ///
  /// In en, this message translates to:
  /// **'you came up short of the target'**
  String get reasonMissedRepsPlain;

  /// No description provided for @reasonRatedTooHard.
  ///
  /// In en, this message translates to:
  /// **'you said it was too hard'**
  String get reasonRatedTooHard;

  /// No description provided for @reasonAtCeiling.
  ///
  /// In en, this message translates to:
  /// **'there is nothing harder in the catalog you can do with the equipment you have'**
  String get reasonAtCeiling;

  /// No description provided for @reasonHoldingSteady.
  ///
  /// In en, this message translates to:
  /// **'a solid session at the weight you are on'**
  String get reasonHoldingSteady;

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

  /// No description provided for @coachTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera check'**
  String get coachTitle;

  /// No description provided for @coachOpen.
  ///
  /// In en, this message translates to:
  /// **'Coach this set'**
  String get coachOpen;

  /// No description provided for @coachDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get coachDone;

  /// No description provided for @coachClaim.
  ///
  /// In en, this message translates to:
  /// **'Spottr flags movement that looks risky. It cannot see everything, and it cannot guarantee you will not get hurt.'**
  String get coachClaim;

  /// No description provided for @coachSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to put your phone'**
  String get coachSetupTitle;

  /// No description provided for @coachDistance.
  ///
  /// In en, this message translates to:
  /// **'Stand about two metres back, with the phone propped up around hip height.'**
  String get coachDistance;

  /// No description provided for @coachAngleSide.
  ///
  /// In en, this message translates to:
  /// **'Put the phone to one side of you, so the camera sees you from the side.'**
  String get coachAngleSide;

  /// No description provided for @coachAngleFront.
  ///
  /// In en, this message translates to:
  /// **'Put the phone in front of you, facing you.'**
  String get coachAngleFront;

  /// No description provided for @coachNotSupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'No camera coaching for this one'**
  String get coachNotSupportedTitle;

  /// No description provided for @coachNotSupportedBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr only coaches the movements it has rules for. Log this one by hand.'**
  String get coachNotSupportedBody;

  /// No description provided for @coachPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Spottr needs the camera'**
  String get coachPermissionTitle;

  /// No description provided for @coachPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'The form coach runs on this device. Video is never uploaded and never leaves your phone.'**
  String get coachPermissionBody;

  /// No description provided for @coachPermissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get coachPermissionAllow;

  /// No description provided for @coachPermissionBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off'**
  String get coachPermissionBlockedTitle;

  /// No description provided for @coachPermissionBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Turn the camera on for Spottr in your device settings, then come back.'**
  String get coachPermissionBlockedBody;

  /// No description provided for @coachStarting.
  ///
  /// In en, this message translates to:
  /// **'Opening the camera'**
  String get coachStarting;

  /// No description provided for @coachErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start'**
  String get coachErrorTitle;

  /// No description provided for @coachErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get coachErrorRetry;

  /// No description provided for @coachErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Spottr does not have permission to use the camera.'**
  String get coachErrorPermission;

  /// No description provided for @coachErrorNoCamera.
  ///
  /// In en, this message translates to:
  /// **'This device has no camera the coach can use yet.'**
  String get coachErrorNoCamera;

  /// No description provided for @coachErrorInUse.
  ///
  /// In en, this message translates to:
  /// **'Another app is using the camera. Close it and try again.'**
  String get coachErrorInUse;

  /// No description provided for @coachErrorModel.
  ///
  /// In en, this message translates to:
  /// **'The pose model stopped working. Try again, and restart Spottr if it keeps happening.'**
  String get coachErrorModel;

  /// No description provided for @coachErrorBadFrame.
  ///
  /// In en, this message translates to:
  /// **'Spottr could not read what the camera sent. This is a bug; please report it.'**
  String get coachErrorBadFrame;

  /// No description provided for @coachErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the camera.'**
  String get coachErrorUnknown;

  /// No description provided for @coachFramingGood.
  ///
  /// In en, this message translates to:
  /// **'That works — I can see all of you.'**
  String get coachFramingGood;

  /// No description provided for @coachFramingNoPerson.
  ///
  /// In en, this message translates to:
  /// **'I cannot see anybody. Step into the frame.'**
  String get coachFramingNoPerson;

  /// No description provided for @coachFramingTooClose.
  ///
  /// In en, this message translates to:
  /// **'Step back — part of you is outside the frame.'**
  String get coachFramingTooClose;

  /// No description provided for @coachFramingTooFar.
  ///
  /// In en, this message translates to:
  /// **'Come a little closer, or move the phone nearer.'**
  String get coachFramingTooFar;

  /// No description provided for @coachFramingOffCentre.
  ///
  /// In en, this message translates to:
  /// **'Move towards the middle of the frame.'**
  String get coachFramingOffCentre;

  /// No description provided for @coachFramingMissingSeveral.
  ///
  /// In en, this message translates to:
  /// **'I can only see part of you. Step back, or re-aim the phone.'**
  String get coachFramingMissingSeveral;

  /// No description provided for @coachFramingMissingShoulders.
  ///
  /// In en, this message translates to:
  /// **'I cannot see your shoulders. Tilt the phone up a little.'**
  String get coachFramingMissingShoulders;

  /// No description provided for @coachFramingMissingHips.
  ///
  /// In en, this message translates to:
  /// **'I cannot see your hips. Re-aim the phone at your middle.'**
  String get coachFramingMissingHips;

  /// No description provided for @coachFramingMissingKnees.
  ///
  /// In en, this message translates to:
  /// **'I cannot see your knees. Step back or tilt the phone down.'**
  String get coachFramingMissingKnees;

  /// No description provided for @coachFramingMissingAnkles.
  ///
  /// In en, this message translates to:
  /// **'I cannot see your ankles. Step back, or tilt the phone down.'**
  String get coachFramingMissingAnkles;

  /// No description provided for @coachRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{rep} other{reps}}'**
  String coachRepsLabel(int count);

  /// No description provided for @coachHeldLabel.
  ///
  /// In en, this message translates to:
  /// **'held'**
  String get coachHeldLabel;

  /// No description provided for @coachRepGood.
  ///
  /// In en, this message translates to:
  /// **'Good rep.'**
  String get coachRepGood;

  /// No description provided for @coachRepShallow.
  ///
  /// In en, this message translates to:
  /// **'Counted, but short of depth — go lower on the next one.'**
  String get coachRepShallow;

  /// No description provided for @coachRepPartial.
  ///
  /// In en, this message translates to:
  /// **'Not counted: that was barely a dip.'**
  String get coachRepPartial;

  /// No description provided for @coachRepTooFast.
  ///
  /// In en, this message translates to:
  /// **'Not counted: too fast to be a real rep.'**
  String get coachRepTooFast;

  /// No description provided for @coachRepTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Not counted: that rep was never finished.'**
  String get coachRepTimedOut;

  /// No description provided for @coachRepLostTracking.
  ///
  /// In en, this message translates to:
  /// **'Not counted: I lost sight of you part way through.'**
  String get coachRepLostTracking;

  /// No description provided for @coachRepsNotCounted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt not counted} other{{count} attempts not counted}}'**
  String coachRepsNotCounted(int count);

  /// No description provided for @coachHoldRunning.
  ///
  /// In en, this message translates to:
  /// **'Holding. Keep going.'**
  String get coachHoldRunning;

  /// No description provided for @coachHoldOutOfPosition.
  ///
  /// In en, this message translates to:
  /// **'Paused — get back into position.'**
  String get coachHoldOutOfPosition;

  /// No description provided for @coachHoldUntracked.
  ///
  /// In en, this message translates to:
  /// **'Paused — I cannot see you.'**
  String get coachHoldUntracked;

  /// No description provided for @coachCounterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Spottr has no rep counter for this movement.'**
  String get coachCounterUnavailable;

  /// No description provided for @coachReady.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are.'**
  String get coachReady;

  /// No description provided for @coachStartSet.
  ///
  /// In en, this message translates to:
  /// **'Start set'**
  String get coachStartSet;

  /// No description provided for @coachStopSet.
  ///
  /// In en, this message translates to:
  /// **'Stop set'**
  String get coachStopSet;

  /// No description provided for @coachSetOf.
  ///
  /// In en, this message translates to:
  /// **'Set {number} of {total}'**
  String coachSetOf(int number, int total);

  /// No description provided for @coachSaveSet.
  ///
  /// In en, this message translates to:
  /// **'Save this set'**
  String get coachSaveSet;

  /// No description provided for @coachDiscardSet.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get coachDiscardSet;

  /// No description provided for @coachSetSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your session.'**
  String get coachSetSaved;

  /// No description provided for @coachSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'That set could not be saved.'**
  String get coachSaveFailed;

  /// No description provided for @coachNothingCounted.
  ///
  /// In en, this message translates to:
  /// **'Nothing counted, so there is nothing to save.'**
  String get coachNothingCounted;

  /// No description provided for @coachSummaryReps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rep} other{{count} reps}}'**
  String coachSummaryReps(int count);

  /// No description provided for @coachSummaryHold.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String coachSummaryHold(int seconds);

  /// No description provided for @coachSummaryAt.
  ///
  /// In en, this message translates to:
  /// **'at {weight}'**
  String coachSummaryAt(String weight);

  /// No description provided for @coachSummaryScore.
  ///
  /// In en, this message translates to:
  /// **'form {score}'**
  String coachSummaryScore(int score);

  /// No description provided for @coachSummaryNoScore.
  ///
  /// In en, this message translates to:
  /// **'no form score'**
  String get coachSummaryNoScore;

  /// No description provided for @coachMute.
  ///
  /// In en, this message translates to:
  /// **'Mute the coach'**
  String get coachMute;

  /// No description provided for @coachUnmute.
  ///
  /// In en, this message translates to:
  /// **'Let the coach speak'**
  String get coachUnmute;

  /// No description provided for @coachSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Coach is speaking'**
  String get coachSpeaking;

  /// No description provided for @coachTargetHype.
  ///
  /// In en, this message translates to:
  /// **'That is the set. Great work.'**
  String get coachTargetHype;

  /// No description provided for @coachTargetCalm.
  ///
  /// In en, this message translates to:
  /// **'That is your target. Nicely done.'**
  String get coachTargetCalm;

  /// No description provided for @coachTargetTough.
  ///
  /// In en, this message translates to:
  /// **'Target hit.'**
  String get coachTargetTough;

  /// No description provided for @coachFormUntested.
  ///
  /// In en, this message translates to:
  /// **'These form checks have not been measured against real training footage yet.'**
  String get coachFormUntested;

  /// No description provided for @coachFormGood.
  ///
  /// In en, this message translates to:
  /// **'Nothing to flag on that one.'**
  String get coachFormGood;

  /// No description provided for @coachFormWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching your form.'**
  String get coachFormWatching;

  /// No description provided for @coachFormScore.
  ///
  /// In en, this message translates to:
  /// **'Form {score}'**
  String coachFormScore(int score);

  /// No description provided for @coachFormUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Not watching: {rules}'**
  String coachFormUnchecked(String rules);

  /// No description provided for @coachFormNothingWatched.
  ///
  /// In en, this message translates to:
  /// **'No form checks run from this angle.'**
  String get coachFormNothingWatched;

  /// No description provided for @coachAdviceSquatDepth.
  ///
  /// In en, this message translates to:
  /// **'Short of depth — get your hips below your knees.'**
  String get coachAdviceSquatDepth;

  /// No description provided for @coachAdviceLungeDepth.
  ///
  /// In en, this message translates to:
  /// **'Drop the back knee further on the next one.'**
  String get coachAdviceLungeDepth;

  /// No description provided for @coachAdviceHingeDepth.
  ///
  /// In en, this message translates to:
  /// **'Push your hips further back — you are stopping high.'**
  String get coachAdviceHingeDepth;

  /// No description provided for @coachAdviceBridgeLockout.
  ///
  /// In en, this message translates to:
  /// **'Drive your hips all the way up at the top.'**
  String get coachAdviceBridgeLockout;

  /// No description provided for @coachAdviceLockout.
  ///
  /// In en, this message translates to:
  /// **'Straighten your arms out fully at the top.'**
  String get coachAdviceLockout;

  /// No description provided for @coachAdvicePressLockout.
  ///
  /// In en, this message translates to:
  /// **'Press all the way overhead — you are stopping short.'**
  String get coachAdvicePressLockout;

  /// No description provided for @coachAdviceKneeBend.
  ///
  /// In en, this message translates to:
  /// **'Your knees are bending — keep them long and move at the hips.'**
  String get coachAdviceKneeBend;

  /// No description provided for @coachAdviceHipSag.
  ///
  /// In en, this message translates to:
  /// **'Your hips are dropping — squeeze your glutes and hold the line.'**
  String get coachAdviceHipSag;

  /// No description provided for @coachAdviceHipPike.
  ///
  /// In en, this message translates to:
  /// **'Your hips are riding high — bring them down into line.'**
  String get coachAdviceHipPike;

  /// No description provided for @coachAdviceNeckAlignment.
  ///
  /// In en, this message translates to:
  /// **'Your head is hanging forward — look at the floor just ahead of you.'**
  String get coachAdviceNeckAlignment;

  /// No description provided for @coachAdviceHeelLift.
  ///
  /// In en, this message translates to:
  /// **'Your heels are coming up — keep them down.'**
  String get coachAdviceHeelLift;

  /// No description provided for @coachAdviceTorsoLean.
  ///
  /// In en, this message translates to:
  /// **'Stay upright — you are leaning into it.'**
  String get coachAdviceTorsoLean;

  /// No description provided for @coachAdviceBackArch.
  ///
  /// In en, this message translates to:
  /// **'You are leaning back instead of pressing up.'**
  String get coachAdviceBackArch;

  /// No description provided for @coachAdviceTorsoSwing.
  ///
  /// In en, this message translates to:
  /// **'Keep your torso still and let your arms do the work.'**
  String get coachAdviceTorsoSwing;

  /// No description provided for @coachAdviceBackRounding.
  ///
  /// In en, this message translates to:
  /// **'That looked like your back rounding. Stop the set and take weight off.'**
  String get coachAdviceBackRounding;

  /// No description provided for @coachAdviceRom.
  ///
  /// In en, this message translates to:
  /// **'These are getting shorter than your first few — stop the set when they do.'**
  String get coachAdviceRom;

  /// No description provided for @coachAdviceTempo.
  ///
  /// In en, this message translates to:
  /// **'You are dropping into it — lower under control.'**
  String get coachAdviceTempo;

  /// No description provided for @coachRuleSquatDepth.
  ///
  /// In en, this message translates to:
  /// **'squat depth'**
  String get coachRuleSquatDepth;

  /// No description provided for @coachRuleLungeDepth.
  ///
  /// In en, this message translates to:
  /// **'lunge depth'**
  String get coachRuleLungeDepth;

  /// No description provided for @coachRuleHingeDepth.
  ///
  /// In en, this message translates to:
  /// **'hinge depth'**
  String get coachRuleHingeDepth;

  /// No description provided for @coachRuleBridgeLockout.
  ///
  /// In en, this message translates to:
  /// **'hip extension'**
  String get coachRuleBridgeLockout;

  /// No description provided for @coachRuleLockout.
  ///
  /// In en, this message translates to:
  /// **'arm lockout'**
  String get coachRuleLockout;

  /// No description provided for @coachRulePressLockout.
  ///
  /// In en, this message translates to:
  /// **'overhead lockout'**
  String get coachRulePressLockout;

  /// No description provided for @coachRuleKneeBend.
  ///
  /// In en, this message translates to:
  /// **'knee bend'**
  String get coachRuleKneeBend;

  /// No description provided for @coachRuleHipSag.
  ///
  /// In en, this message translates to:
  /// **'hip sag'**
  String get coachRuleHipSag;

  /// No description provided for @coachRuleHipPike.
  ///
  /// In en, this message translates to:
  /// **'hip pike'**
  String get coachRuleHipPike;

  /// No description provided for @coachRuleNeckAlignment.
  ///
  /// In en, this message translates to:
  /// **'neck position'**
  String get coachRuleNeckAlignment;

  /// No description provided for @coachRuleHeelLift.
  ///
  /// In en, this message translates to:
  /// **'heel lift'**
  String get coachRuleHeelLift;

  /// No description provided for @coachRuleTorsoLean.
  ///
  /// In en, this message translates to:
  /// **'torso lean'**
  String get coachRuleTorsoLean;

  /// No description provided for @coachRuleBackArch.
  ///
  /// In en, this message translates to:
  /// **'back arch'**
  String get coachRuleBackArch;

  /// No description provided for @coachRuleTorsoSwing.
  ///
  /// In en, this message translates to:
  /// **'torso swing'**
  String get coachRuleTorsoSwing;

  /// No description provided for @coachRuleBackRounding.
  ///
  /// In en, this message translates to:
  /// **'back rounding'**
  String get coachRuleBackRounding;

  /// No description provided for @coachRuleRom.
  ///
  /// In en, this message translates to:
  /// **'range of motion'**
  String get coachRuleRom;

  /// No description provided for @coachRuleTempo.
  ///
  /// In en, this message translates to:
  /// **'tempo'**
  String get coachRuleTempo;

  /// No description provided for @coachRuleKneeValgus.
  ///
  /// In en, this message translates to:
  /// **'knees falling in'**
  String get coachRuleKneeValgus;

  /// No description provided for @coachRuleElbowFlare.
  ///
  /// In en, this message translates to:
  /// **'elbow flare'**
  String get coachRuleElbowFlare;

  /// No description provided for @coachRuleElbowPath.
  ///
  /// In en, this message translates to:
  /// **'elbow path'**
  String get coachRuleElbowPath;

  /// No description provided for @coachRuleKneeTravel.
  ///
  /// In en, this message translates to:
  /// **'knee travel'**
  String get coachRuleKneeTravel;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account and sync'**
  String get accountTitle;

  /// No description provided for @accountLocalFirstBody.
  ///
  /// In en, this message translates to:
  /// **'Spottr works without an account. Signing in copies your plan and your training log to your other devices. Nothing from the camera is ever uploaded.'**
  String get accountLocalFirstBody;

  /// No description provided for @accountUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync is not set up in this build'**
  String get accountUnavailableTitle;

  /// No description provided for @accountUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This copy of Spottr was built without a Supabase project, so there is nowhere to sync to. Everything else works as usual.'**
  String get accountUnavailableBody;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get accountSignUp;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(String email);

  /// No description provided for @accountSignedOutOf.
  ///
  /// In en, this message translates to:
  /// **'Signed out of {email}. This device still holds that training.'**
  String accountSignedOutOf(String email);

  /// No description provided for @accountEmailMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address for your account.'**
  String get accountEmailMissing;

  /// No description provided for @accountPasswordMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get accountPasswordMissing;

  /// No description provided for @accountSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountSyncNow;

  /// No description provided for @accountSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get accountSyncing;

  /// No description provided for @accountSyncedNothing.
  ///
  /// In en, this message translates to:
  /// **'Up to date. Nothing to send or fetch.'**
  String get accountSyncedNothing;

  /// No description provided for @accountSyncedCounts.
  ///
  /// In en, this message translates to:
  /// **'Sent {pushed}, fetched {pulled}.'**
  String accountSyncedCounts(int pushed, int pulled);

  /// No description provided for @accountSyncConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One change was made in two places; the later one was kept.} other{{count} changes were made in two places; the later one was kept each time.}}'**
  String accountSyncConflicts(int count);

  /// No description provided for @accountSyncStoppedOffline.
  ///
  /// In en, this message translates to:
  /// **'Stopped: no connection. Your training is on this device and the next sync picks up where this one left off.'**
  String get accountSyncStoppedOffline;

  /// No description provided for @accountSyncStoppedUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Stopped: your sign-in has expired. Sign in again to carry on syncing.'**
  String get accountSyncStoppedUnauthorized;

  /// No description provided for @accountSyncStoppedRejected.
  ///
  /// In en, this message translates to:
  /// **'Stopped: the server refused a change. {detail}'**
  String accountSyncStoppedRejected(String detail);

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'That email and password do not match an account.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'There is already an account with that email. Sign in instead.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'That password was refused: {detail}'**
  String authErrorWeakPassword(String detail);

  /// No description provided for @authErrorConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Check your email and confirm the address, then sign in.'**
  String get authErrorConfirmationRequired;

  /// No description provided for @authErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Nothing was changed on this device.'**
  String get authErrorOffline;

  /// No description provided for @authErrorRejected.
  ///
  /// In en, this message translates to:
  /// **'The server refused the request: {detail}'**
  String authErrorRejected(String detail);

  /// No description provided for @authErrorForeignAccount.
  ///
  /// In en, this message translates to:
  /// **'This device holds another account\'s training. Signing in as somebody else would move it into their account, so Spottr will not do it.'**
  String get authErrorForeignAccount;

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
