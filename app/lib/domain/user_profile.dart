import 'package:coach_engine/coach_engine.dart';
import 'package:collection/collection.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';
import 'package:plan_engine/plan_engine.dart';

/// Biological sex, asked optionally at onboarding.
///
/// Collected because the brief asks for it, stored, and currently read by
/// nothing: plan generation does not use it. It becomes load-bearing only if
/// energy-expenditure estimates ever arrive, which is the nutrition feature
/// the MVP leaves out.
enum Sex { female, male, preferNotToSay }

/// Everything onboarding collects, and the single source the plan request is
/// derived from.
///
/// Immutable, with value equality, so a screen can compare the profile it is
/// editing against the stored one and know whether anything actually changed
/// — which is what decides whether the plan needs regenerating.
@immutable
class UserProfile {
  UserProfile({
    required this.goal,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.level,
    required this.location,
    required this.coachStyle,
    this.id = localId,
    this.ageYears,
    this.heightCm,
    this.weightKg,
    this.sex,
    Set<BodyPart> injuries = const {},
    this.injuryNotes,
    Set<Equipment> extraEquipment = const {},
    Set<int> runWeekdays = const {},
    DateTime? disclaimerAcceptedAt,
  })  : injuries = Set.unmodifiable(injuries),
        extraEquipment = Set.unmodifiable(extraEquipment),
        runWeekdays = Set.unmodifiable(runWeekdays),
        // Normalized so that a profile which has been through storage
        // compares equal to the one that went in. `DateTime` equality
        // includes the zone flag, so a local and a UTC instant for the same
        // moment are not equal, and every timestamp here crosses a database.
        disclaimerAcceptedAt = disclaimerAcceptedAt?.toUtc();

  /// The draft a new user starts onboarding from.
  ///
  /// Every default here is the conservative one: a beginner, at home, with
  /// no equipment, on three moderate sessions. Someone who taps straight
  /// through the questions without reading them gets a plan that is too
  /// easy, never one that hands a novice a barbell. That is the right way
  /// round for the failure to happen.
  factory UserProfile.starting() => UserProfile(
        goal: Goal.muscleBuilding,
        daysPerWeek: 3,
        sessionMinutes: 45,
        level: Level.beginner,
        location: TrainingLocation.homeNone,
        coachStyle: CoachStyle.fallback,
      );

  /// The id of the one profile a device holds before accounts exist.
  ///
  /// Spottr is local-first with no login, so there is exactly one. When sync
  /// lands this becomes the authenticated user's id and the row migrates.
  static const String localId = 'local';

  /// Training frequencies a week template exists for.
  static const int minDaysPerWeek = 2;
  static const int maxDaysPerWeek = 6;

  /// Session lengths worth programming. The floor matches the plan engine's
  /// own rule; the ceiling only exists to catch a typo.
  static const int minSessionMinutes = 20;
  static const int maxSessionMinutes = 180;

  static const int minAgeYears = 10;
  static const int maxAgeYears = 120;

  final String id;
  final Goal goal;
  final int daysPerWeek;
  final int sessionMinutes;
  final Level level;
  final TrainingLocation location;
  final CoachStyle coachStyle;

  /// Optional body measurements. Nothing in the MVP reads them.
  final int? ageYears;
  final double? heightCm;
  final double? weightKg;
  final Sex? sex;

  /// Injury sites that exclude or modify exercises. The onboarding
  /// checkboxes cover knees, lower back, shoulders and wrists.
  final Set<BodyPart> injuries;

  /// Free text from the injury question. Shown back to the user and never
  /// parsed: guessing at prose would be the wrong kind of clever here.
  final String? injuryNotes;

  /// Equipment owned beyond what [location] implies, e.g. a pull-up bar.
  final Set<Equipment> extraEquipment;

  /// ISO weekdays the user runs on, kept whatever the goal is.
  final Set<int> runWeekdays;

  /// When the safety disclaimer was accepted, or null if it has not been.
  final DateTime? disclaimerAcceptedAt;

  bool get hasAcceptedDisclaimer => disclaimerAcceptedAt != null;

  /// Whether run days shape the plan. Only the hybrid goal runs.
  bool get usesRunDays => goal == Goal.hybrid;

  /// The request the plan generator takes.
  ///
  /// Run days are withheld unless the goal is hybrid: a user who switched
  /// away from hybrid keeps their answer, but their plan must stop being
  /// scheduled around runs they are no longer doing.
  PlanRequest toPlanRequest({List<String> recentExerciseIds = const []}) =>
      PlanRequest(
        goal: goal,
        daysPerWeek: daysPerWeek,
        sessionMinutes: sessionMinutes,
        level: level,
        location: location,
        extraEquipment: extraEquipment,
        injuries: injuries,
        runWeekdays: usesRunDays ? runWeekdays : const {},
        recentExerciseIds: recentExerciseIds,
      );

  /// Whether changing this profile into [other] would produce a different
  /// week, and therefore costs the user any swaps and reordering they did.
  ///
  /// Only the answers the generator reads count. A different coach voice,
  /// a corrected body weight or a note typed into the injury box change
  /// nothing about what is prescribed, and discarding someone's edited plan
  /// because they fixed a typo would be its own kind of bug.
  bool wouldChangePlan(UserProfile other) =>
      other.goal != goal ||
      other.daysPerWeek != daysPerWeek ||
      other.sessionMinutes != sessionMinutes ||
      other.level != level ||
      other.location != location ||
      !const SetEquality<Equipment>()
          .equals(other.extraEquipment, extraEquipment) ||
      !const SetEquality<BodyPart>().equals(other.injuries, injuries) ||
      // Run days only reach the generator for a hybrid goal, so a change to
      // them matters only when one of the two profiles actually runs.
      ((usesRunDays || other.usesRunDays) &&
          !const SetEquality<int>().equals(other.runWeekdays, runWeekdays));

  /// Throws if this profile could not produce a plan.
  void validate() {
    if (daysPerWeek < minDaysPerWeek || daysPerWeek > maxDaysPerWeek) {
      throw ArgumentError.value(
        daysPerWeek,
        'daysPerWeek',
        'Supported training frequency is $minDaysPerWeek to $maxDaysPerWeek '
            'days per week',
      );
    }
    if (sessionMinutes < minSessionMinutes ||
        sessionMinutes > maxSessionMinutes) {
      throw ArgumentError.value(
        sessionMinutes,
        'sessionMinutes',
        'A session runs $minSessionMinutes to $maxSessionMinutes minutes',
      );
    }
    for (final weekday in runWeekdays) {
      if (weekday < 1 || weekday > 7) {
        throw ArgumentError.value(
          weekday,
          'runWeekdays',
          'Run days are ISO weekdays, 1 (Monday) to 7 (Sunday)',
        );
      }
    }
    _checkRange(ageYears, 'ageYears', minAgeYears, maxAgeYears);
    _checkRange(heightCm, 'heightCm', 90, 260);
    _checkRange(weightKg, 'weightKg', 25, 400);
  }

  static void _checkRange(num? value, String name, num min, num max) {
    if (value == null) return;
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'Expected $min to $max');
    }
  }

  /// A copy with the given changes.
  ///
  /// The optional fields each take a `clear` flag, because passing null is
  /// how you say "leave it alone" and there has to be another way to say
  /// "the user removed it".
  UserProfile copyWith({
    String? id,
    Goal? goal,
    int? daysPerWeek,
    int? sessionMinutes,
    Level? level,
    TrainingLocation? location,
    CoachStyle? coachStyle,
    int? ageYears,
    bool clearAgeYears = false,
    double? heightCm,
    bool clearHeightCm = false,
    double? weightKg,
    bool clearWeightKg = false,
    Sex? sex,
    bool clearSex = false,
    Set<BodyPart>? injuries,
    String? injuryNotes,
    bool clearInjuryNotes = false,
    Set<Equipment>? extraEquipment,
    Set<int>? runWeekdays,
    DateTime? disclaimerAcceptedAt,
    bool clearDisclaimerAcceptedAt = false,
  }) =>
      UserProfile(
        id: id ?? this.id,
        goal: goal ?? this.goal,
        daysPerWeek: daysPerWeek ?? this.daysPerWeek,
        sessionMinutes: sessionMinutes ?? this.sessionMinutes,
        level: level ?? this.level,
        location: location ?? this.location,
        coachStyle: coachStyle ?? this.coachStyle,
        ageYears: clearAgeYears ? null : ageYears ?? this.ageYears,
        heightCm: clearHeightCm ? null : heightCm ?? this.heightCm,
        weightKg: clearWeightKg ? null : weightKg ?? this.weightKg,
        sex: clearSex ? null : sex ?? this.sex,
        injuries: injuries ?? this.injuries,
        injuryNotes:
            clearInjuryNotes ? null : injuryNotes ?? this.injuryNotes,
        extraEquipment: extraEquipment ?? this.extraEquipment,
        runWeekdays: runWeekdays ?? this.runWeekdays,
        disclaimerAcceptedAt: clearDisclaimerAcceptedAt
            ? null
            : disclaimerAcceptedAt ?? this.disclaimerAcceptedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.goal == goal &&
      other.daysPerWeek == daysPerWeek &&
      other.sessionMinutes == sessionMinutes &&
      other.level == level &&
      other.location == location &&
      other.coachStyle == coachStyle &&
      other.ageYears == ageYears &&
      other.heightCm == heightCm &&
      other.weightKg == weightKg &&
      other.sex == sex &&
      const SetEquality<BodyPart>().equals(other.injuries, injuries) &&
      other.injuryNotes == injuryNotes &&
      const SetEquality<Equipment>()
          .equals(other.extraEquipment, extraEquipment) &&
      const SetEquality<int>().equals(other.runWeekdays, runWeekdays) &&
      other.disclaimerAcceptedAt == disclaimerAcceptedAt;

  @override
  int get hashCode => Object.hash(
        id,
        goal,
        daysPerWeek,
        sessionMinutes,
        level,
        location,
        coachStyle,
        ageYears,
        heightCm,
        weightKg,
        sex,
        const SetEquality<BodyPart>().hash(injuries),
        injuryNotes,
        const SetEquality<Equipment>().hash(extraEquipment),
        const SetEquality<int>().hash(runWeekdays),
        disclaimerAcceptedAt,
      );

  @override
  String toString() => 'UserProfile(${goal.name}, $daysPerWeek days, '
      '${level.name}, ${location.name})';
}
