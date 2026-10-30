import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';

/// Builds a minimal exercise for tests. Every field has a boring default so a
/// test only has to state the part it cares about.
Exercise exercise(
  String id, {
  Set<MuscleGroup> primaryMuscles = const {MuscleGroup.quads},
  Set<MuscleGroup> secondaryMuscles = const {},
  Set<Equipment> requiredEquipment = const {},
  Level difficulty = Level.beginner,
  MovementPattern pattern = MovementPattern.squat,
  Set<BodyPart> contraindications = const {},
  bool isUnilateral = false,
  MetricType metric = MetricType.reps,
  CameraSupport? camera,
  List<String> alternativeIds = const [],
  String? easierId,
  String? harderId,
  double secondsPerRep = 3,
}) =>
    Exercise(
      id: id,
      nameKey: 'exercise_$id',
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      requiredEquipment: requiredEquipment,
      difficulty: difficulty,
      pattern: pattern,
      contraindications: contraindications,
      isUnilateral: isUnilateral,
      metric: metric,
      camera: camera,
      alternativeIds: alternativeIds,
      easierId: easierId,
      harderId: harderId,
      secondsPerRep: secondsPerRep,
    );

/// Builds camera support for tests.
CameraSupport cameraSupport({
  CameraAngle recommendedAngle = CameraAngle.side,
  Set<CameraAngle> acceptableAngles = const {CameraAngle.side},
  String repCounterId = 'squat_knee_angle',
  Set<String> formRuleIds = const {'squat_depth'},
  Map<CameraAngle, Set<String>> rulesDisabledAt = const {},
}) =>
    CameraSupport(
      recommendedAngle: recommendedAngle,
      acceptableAngles: acceptableAngles,
      repCounterId: repCounterId,
      formRuleIds: formRuleIds,
      rulesDisabledAt: rulesDisabledAt,
    );
