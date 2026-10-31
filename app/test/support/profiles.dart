import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/domain/user_profile.dart';

/// A complete, valid profile that tests vary one field at a time.
///
/// Defaults are deliberately boring — a four-day intermediate gym user — so
/// that whatever a test overrides is the only interesting thing about it.
UserProfile testProfile({
  String id = UserProfile.localId,
  Goal goal = Goal.muscleBuilding,
  int daysPerWeek = 4,
  int sessionMinutes = 60,
  Level level = Level.intermediate,
  TrainingLocation location = TrainingLocation.fullGym,
  CoachStyle coachStyle = CoachStyle.calm,
  int? ageYears = 34,
  double? heightCm = 180,
  double? weightKg = 82,
  Sex? sex = Sex.male,
  Set<BodyPart> injuries = const {},
  String? injuryNotes,
  Set<Equipment> extraEquipment = const {},
  Set<int> runWeekdays = const {},
  DateTime? disclaimerAcceptedAt,
}) =>
    UserProfile(
      id: id,
      goal: goal,
      daysPerWeek: daysPerWeek,
      sessionMinutes: sessionMinutes,
      level: level,
      location: location,
      coachStyle: coachStyle,
      ageYears: ageYears,
      heightCm: heightCm,
      weightKg: weightKg,
      sex: sex,
      injuries: injuries,
      injuryNotes: injuryNotes,
      extraEquipment: extraEquipment,
      runWeekdays: runWeekdays,
      disclaimerAcceptedAt: disclaimerAcceptedAt,
    );

/// A profile that has cleared the disclaimer gate, which is what most of the
/// app's screens require before they will show anything.
UserProfile onboardedProfile({
  Goal goal = Goal.muscleBuilding,
  int daysPerWeek = 4,
  int sessionMinutes = 60,
  Level level = Level.intermediate,
  TrainingLocation location = TrainingLocation.fullGym,
  CoachStyle coachStyle = CoachStyle.calm,
  Set<BodyPart> injuries = const {},
  Set<Equipment> extraEquipment = const {},
  Set<int> runWeekdays = const {},
}) =>
    testProfile(
      goal: goal,
      daysPerWeek: daysPerWeek,
      sessionMinutes: sessionMinutes,
      level: level,
      location: location,
      coachStyle: coachStyle,
      injuries: injuries,
      extraEquipment: extraEquipment,
      runWeekdays: runWeekdays,
      disclaimerAcceptedAt: DateTime.utc(2026, 10, 31),
    );
