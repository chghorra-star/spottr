import 'package:pose_core/pose_core.dart';

import 'camera_support.dart';
import 'catalog.dart';
import 'enums.dart';
import 'exercise.dart';

/// Groups of exercises that do the same job and can be swapped for one
/// another.
///
/// Alternatives are derived from these cliques rather than listed per entry,
/// which makes the symmetry the catalog validator demands automatic: if A is
/// in a group with B, each offers the other by construction.
const Map<String, List<String>> _alternativeGroups = {
  'squat': [
    'bodyweight_squat',
    'goblet_squat',
    'barbell_back_squat',
    'leg_press',
    'hack_squat',
  ],
  'hinge_glute': [
    'glute_bridge',
    'single_leg_glute_bridge',
    'barbell_hip_thrust',
  ],
  'hinge_hamstring': [
    'db_romanian_deadlift',
    'barbell_romanian_deadlift',
    'barbell_deadlift',
    'leg_curl',
  ],
  'lunge': [
    'forward_lunge',
    'reverse_lunge',
    'split_squat',
    'db_lunge',
    'step_up',
  ],
  'push_horizontal': [
    'push_up',
    'knee_push_up',
    'incline_push_up',
    'db_floor_press',
    'db_bench_press',
    'barbell_bench_press',
    'chest_press_machine',
  ],
  'push_vertical': [
    'db_shoulder_press',
    'barbell_overhead_press',
    'pike_push_up',
    'machine_shoulder_press',
  ],
  'pull_horizontal': [
    'db_bent_over_row',
    'db_single_arm_row',
    'barbell_row',
    'seated_cable_row',
    'inverted_row',
  ],
  'pull_vertical': [
    'lat_pulldown',
    'pull_up',
    'band_assisted_pull_up',
  ],
  'core': [
    'plank',
    'side_plank',
    'dead_bug',
    'bird_dog',
    'mountain_climber',
    'hanging_knee_raise',
  ],
  'biceps': ['db_curl', 'db_hammer_curl'],
  'triceps': ['db_triceps_extension', 'cable_triceps_pushdown'],
  'calves': ['calf_raise', 'seated_calf_raise'],
};

/// Alternatives for [id], derived from its clique.
List<String> _alternativesFor(String id) {
  for (final members in _alternativeGroups.values) {
    if (members.contains(id)) {
      return members.where((member) => member != id).toList();
    }
  }
  return const [];
}

Exercise _ex(
  String id, {
  required Set<MuscleGroup> primary,
  required Level difficulty,
  required MovementPattern pattern,
  Set<MuscleGroup> secondary = const {},
  Set<Equipment> equipment = const {},
  Set<BodyPart> contraindications = const {},
  bool unilateral = false,
  MetricType metric = MetricType.reps,
  CameraSupport? camera,
  String? easier,
  String? harder,
  double secondsPerRep = 3,
}) =>
    Exercise(
      id: id,
      nameKey: 'exercise_$id',
      primaryMuscles: primary,
      secondaryMuscles: secondary,
      requiredEquipment: equipment,
      difficulty: difficulty,
      pattern: pattern,
      contraindications: contraindications,
      isUnilateral: unilateral,
      metric: metric,
      camera: camera,
      alternativeIds: _alternativesFor(id),
      easierId: easier,
      harderId: harder,
      secondsPerRep: secondsPerRep,
    );

// ---------------------------------------------------------------------------
// Camera configurations for the launch exercises.
//
// No single angle can evaluate every rule: depth and spinal position need the
// side view, left-right symmetry needs the front. Each config therefore names
// every rule the exercise has, and says which ones a given angle cannot see.
// The recommended angle is the one that sees the most.
// ---------------------------------------------------------------------------

const _squatCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side, CameraAngle.front},
  repCounterId: 'squat_knee_angle',
  formRuleIds: {
    'squat_depth',
    'knee_valgus',
    'back_rounding',
    'heel_lift',
    'rom',
    'tempo',
  },
  rulesDisabledAt: {
    CameraAngle.front: {'squat_depth', 'back_rounding', 'heel_lift'},
    CameraAngle.side: {'knee_valgus'},
  },
);

const _pushUpCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side, CameraAngle.front},
  repCounterId: 'pushup_elbow_angle',
  formRuleIds: {'hip_sag', 'lockout', 'elbow_flare', 'rom', 'tempo'},
  rulesDisabledAt: {
    CameraAngle.front: {'hip_sag', 'lockout'},
    CameraAngle.side: {'elbow_flare'},
  },
);

const _lungeCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side, CameraAngle.front},
  repCounterId: 'lunge_knee_angle',
  formRuleIds: {
    'lunge_depth',
    'knee_travel',
    'torso_lean',
    'knee_valgus',
    'rom',
    'tempo',
  },
  rulesDisabledAt: {
    CameraAngle.front: {'lunge_depth', 'knee_travel', 'torso_lean'},
    CameraAngle.side: {'knee_valgus'},
  },
);

const _gluteBridgeCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side},
  repCounterId: 'bridge_hip_angle',
  // No back_arch: in a bridge the trunk is horizontal by design, and lumbar
  // hyperextension at the top of one is invisible to a side-on skeleton
  // that has no landmark on the pelvis or the spine. A rule that cannot be
  // measured is worse than a gap, because the gap is at least visible.
  formRuleIds: {'bridge_lockout', 'rom', 'tempo'},
);

const _hingeCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side},
  repCounterId: 'hinge_hip_angle',
  formRuleIds: {'back_rounding', 'hinge_depth', 'knee_bend', 'rom', 'tempo'},
);

const _shoulderPressCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side, CameraAngle.front},
  repCounterId: 'press_elbow_angle',
  // press_lockout rather than lockout: a press opens as it is performed, so
  // full extension is at the far end of the movement and not at the top of
  // the rep. Same distinction bridge_lockout already makes.
  formRuleIds: {'press_lockout', 'back_arch', 'elbow_flare', 'rom', 'tempo'},
  rulesDisabledAt: {
    CameraAngle.front: {'back_arch'},
    CameraAngle.side: {'elbow_flare'},
  },
);

const _rowCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side, CameraAngle.front},
  repCounterId: 'row_elbow_angle',
  formRuleIds: {'back_rounding', 'torso_swing', 'elbow_path', 'rom', 'tempo'},
  rulesDisabledAt: {
    CameraAngle.front: {'back_rounding', 'torso_swing'},
    CameraAngle.side: {'elbow_path'},
  },
);

const _plankCamera = CameraSupport(
  recommendedAngle: CameraAngle.side,
  acceptableAngles: {CameraAngle.side},
  repCounterId: 'plank_hold',
  formRuleIds: {'hip_sag', 'hip_pike', 'neck_alignment'},
);

/// The curated catalog.
///
/// Difficulty is a hard gate, not a preference: an exercise is only ever
/// offered at or below the user's level, so there is deliberately plenty of
/// beginner work in every pattern that bodyweight training can cover.
final List<Exercise> standardExercises = [
  // --- Squat ---------------------------------------------------------------
  _ex(
    'bodyweight_squat',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    secondary: {MuscleGroup.core},
    difficulty: Level.beginner,
    pattern: MovementPattern.squat,
    camera: _squatCamera,
    harder: 'goblet_squat',
  ),
  _ex(
    'goblet_squat',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    secondary: {MuscleGroup.core},
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.squat,
    camera: _squatCamera,
    easier: 'bodyweight_squat',
    harder: 'barbell_back_squat',
  ),
  _ex(
    'barbell_back_squat',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    secondary: {MuscleGroup.core, MuscleGroup.lowerBack},
    equipment: {Equipment.barbell},
    difficulty: Level.advanced,
    pattern: MovementPattern.squat,
    contraindications: {BodyPart.knees, BodyPart.lowerBack},
    easier: 'goblet_squat',
  ),
  _ex(
    'leg_press',
    primary: {MuscleGroup.quads},
    secondary: {MuscleGroup.glutes},
    equipment: {Equipment.machine},
    difficulty: Level.beginner,
    pattern: MovementPattern.squat,
    contraindications: {BodyPart.knees},
  ),
  _ex(
    'hack_squat',
    primary: {MuscleGroup.quads},
    secondary: {MuscleGroup.glutes},
    equipment: {Equipment.machine},
    difficulty: Level.intermediate,
    pattern: MovementPattern.squat,
    contraindications: {BodyPart.knees},
  ),

  // --- Hinge ---------------------------------------------------------------
  _ex(
    'glute_bridge',
    primary: {MuscleGroup.glutes},
    secondary: {MuscleGroup.hamstrings, MuscleGroup.core},
    difficulty: Level.beginner,
    pattern: MovementPattern.hinge,
    camera: _gluteBridgeCamera,
    harder: 'single_leg_glute_bridge',
  ),
  _ex(
    'single_leg_glute_bridge',
    primary: {MuscleGroup.glutes},
    secondary: {MuscleGroup.hamstrings, MuscleGroup.core},
    difficulty: Level.intermediate,
    pattern: MovementPattern.hinge,
    unilateral: true,
    easier: 'glute_bridge',
  ),
  _ex(
    'barbell_hip_thrust',
    primary: {MuscleGroup.glutes},
    secondary: {MuscleGroup.hamstrings},
    equipment: {Equipment.barbell, Equipment.bench},
    difficulty: Level.intermediate,
    pattern: MovementPattern.hinge,
  ),
  _ex(
    'db_romanian_deadlift',
    primary: {MuscleGroup.hamstrings, MuscleGroup.glutes},
    secondary: {MuscleGroup.lowerBack},
    equipment: {Equipment.dumbbells},
    difficulty: Level.intermediate,
    pattern: MovementPattern.hinge,
    contraindications: {BodyPart.lowerBack},
    camera: _hingeCamera,
    easier: 'glute_bridge',
    harder: 'barbell_romanian_deadlift',
    secondsPerRep: 4,
  ),
  _ex(
    'barbell_romanian_deadlift',
    primary: {MuscleGroup.hamstrings, MuscleGroup.glutes},
    secondary: {MuscleGroup.lowerBack},
    equipment: {Equipment.barbell},
    difficulty: Level.advanced,
    pattern: MovementPattern.hinge,
    contraindications: {BodyPart.lowerBack},
    easier: 'db_romanian_deadlift',
    secondsPerRep: 4,
  ),
  _ex(
    'barbell_deadlift',
    primary: {
      MuscleGroup.hamstrings,
      MuscleGroup.glutes,
      MuscleGroup.lowerBack,
    },
    secondary: {MuscleGroup.upperBack, MuscleGroup.quads},
    equipment: {Equipment.barbell},
    difficulty: Level.advanced,
    pattern: MovementPattern.hinge,
    contraindications: {BodyPart.lowerBack},
    secondsPerRep: 4,
  ),
  _ex(
    'leg_curl',
    primary: {MuscleGroup.hamstrings},
    equipment: {Equipment.machine},
    difficulty: Level.beginner,
    pattern: MovementPattern.hinge,
  ),

  // --- Lunge ---------------------------------------------------------------
  _ex(
    'forward_lunge',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    secondary: {MuscleGroup.core},
    difficulty: Level.beginner,
    pattern: MovementPattern.lunge,
    contraindications: {BodyPart.knees},
    unilateral: true,
    camera: _lungeCamera,
    harder: 'db_lunge',
  ),
  _ex(
    'reverse_lunge',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    secondary: {MuscleGroup.core},
    difficulty: Level.beginner,
    pattern: MovementPattern.lunge,
    unilateral: true,
  ),
  _ex(
    'split_squat',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    difficulty: Level.intermediate,
    pattern: MovementPattern.lunge,
    contraindications: {BodyPart.knees},
    unilateral: true,
  ),
  _ex(
    'db_lunge',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    secondary: {MuscleGroup.core},
    equipment: {Equipment.dumbbells},
    difficulty: Level.intermediate,
    pattern: MovementPattern.lunge,
    contraindications: {BodyPart.knees},
    unilateral: true,
    easier: 'forward_lunge',
  ),
  _ex(
    'step_up',
    primary: {MuscleGroup.quads, MuscleGroup.glutes},
    equipment: {Equipment.box},
    difficulty: Level.beginner,
    pattern: MovementPattern.lunge,
    unilateral: true,
  ),

  // --- Horizontal push -----------------------------------------------------
  _ex(
    'push_up',
    primary: {MuscleGroup.chest},
    secondary: {
      MuscleGroup.triceps,
      MuscleGroup.shoulders,
      MuscleGroup.core,
    },
    difficulty: Level.beginner,
    pattern: MovementPattern.horizontalPush,
    contraindications: {BodyPart.wrists, BodyPart.shoulders},
    camera: _pushUpCamera,
    easier: 'knee_push_up',
    harder: 'db_bench_press',
  ),
  _ex(
    'knee_push_up',
    primary: {MuscleGroup.chest},
    secondary: {MuscleGroup.triceps},
    difficulty: Level.beginner,
    pattern: MovementPattern.horizontalPush,
    contraindications: {BodyPart.wrists},
    harder: 'push_up',
  ),
  _ex(
    'incline_push_up',
    primary: {MuscleGroup.chest},
    secondary: {MuscleGroup.triceps, MuscleGroup.shoulders},
    difficulty: Level.beginner,
    pattern: MovementPattern.horizontalPush,
    contraindications: {BodyPart.wrists},
    harder: 'push_up',
  ),
  _ex(
    'db_floor_press',
    primary: {MuscleGroup.chest},
    secondary: {MuscleGroup.triceps},
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.horizontalPush,
  ),
  _ex(
    'db_bench_press',
    primary: {MuscleGroup.chest},
    secondary: {MuscleGroup.triceps, MuscleGroup.shoulders},
    equipment: {Equipment.dumbbells, Equipment.bench},
    difficulty: Level.intermediate,
    pattern: MovementPattern.horizontalPush,
    contraindications: {BodyPart.shoulders},
    easier: 'db_floor_press',
  ),
  _ex(
    'barbell_bench_press',
    primary: {MuscleGroup.chest},
    secondary: {MuscleGroup.triceps, MuscleGroup.shoulders},
    equipment: {Equipment.barbell, Equipment.bench},
    difficulty: Level.intermediate,
    pattern: MovementPattern.horizontalPush,
    contraindications: {BodyPart.shoulders},
  ),
  _ex(
    'chest_press_machine',
    primary: {MuscleGroup.chest},
    secondary: {MuscleGroup.triceps},
    equipment: {Equipment.machine},
    difficulty: Level.beginner,
    pattern: MovementPattern.horizontalPush,
  ),

  // --- Vertical push -------------------------------------------------------
  _ex(
    'db_shoulder_press',
    primary: {MuscleGroup.shoulders},
    secondary: {MuscleGroup.triceps, MuscleGroup.core},
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.verticalPush,
    contraindications: {BodyPart.shoulders},
    camera: _shoulderPressCamera,
    harder: 'barbell_overhead_press',
  ),
  _ex(
    'barbell_overhead_press',
    primary: {MuscleGroup.shoulders},
    secondary: {MuscleGroup.triceps, MuscleGroup.core},
    equipment: {Equipment.barbell},
    difficulty: Level.advanced,
    pattern: MovementPattern.verticalPush,
    contraindications: {BodyPart.shoulders, BodyPart.lowerBack},
    easier: 'db_shoulder_press',
  ),
  _ex(
    'pike_push_up',
    primary: {MuscleGroup.shoulders},
    secondary: {MuscleGroup.triceps},
    difficulty: Level.intermediate,
    pattern: MovementPattern.verticalPush,
    contraindications: {BodyPart.shoulders, BodyPart.wrists},
  ),
  _ex(
    'machine_shoulder_press',
    primary: {MuscleGroup.shoulders},
    secondary: {MuscleGroup.triceps},
    equipment: {Equipment.machine},
    difficulty: Level.beginner,
    pattern: MovementPattern.verticalPush,
    contraindications: {BodyPart.shoulders},
  ),

  // --- Horizontal pull -----------------------------------------------------
  _ex(
    'db_bent_over_row',
    primary: {MuscleGroup.lats, MuscleGroup.upperBack},
    secondary: {MuscleGroup.biceps, MuscleGroup.lowerBack},
    equipment: {Equipment.dumbbells},
    difficulty: Level.intermediate,
    pattern: MovementPattern.horizontalPull,
    contraindications: {BodyPart.lowerBack},
    camera: _rowCamera,
    easier: 'seated_cable_row',
    harder: 'barbell_row',
  ),
  _ex(
    'db_single_arm_row',
    primary: {MuscleGroup.lats, MuscleGroup.upperBack},
    secondary: {MuscleGroup.biceps},
    // No bench required: braced on a knee or a chair, a single-arm row is the
    // only horizontal pull a dumbbell-at-home beginner can actually do.
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.horizontalPull,
    unilateral: true,
  ),
  _ex(
    'barbell_row',
    primary: {MuscleGroup.lats, MuscleGroup.upperBack},
    secondary: {MuscleGroup.biceps, MuscleGroup.lowerBack},
    equipment: {Equipment.barbell},
    difficulty: Level.advanced,
    pattern: MovementPattern.horizontalPull,
    contraindications: {BodyPart.lowerBack},
    easier: 'db_bent_over_row',
  ),
  _ex(
    'seated_cable_row',
    primary: {MuscleGroup.lats, MuscleGroup.upperBack},
    secondary: {MuscleGroup.biceps},
    equipment: {Equipment.cableMachine},
    difficulty: Level.beginner,
    pattern: MovementPattern.horizontalPull,
  ),
  _ex(
    'inverted_row',
    primary: {MuscleGroup.lats, MuscleGroup.upperBack},
    secondary: {MuscleGroup.biceps, MuscleGroup.core},
    equipment: {Equipment.pullUpBar},
    difficulty: Level.intermediate,
    pattern: MovementPattern.horizontalPull,
  ),

  // --- Vertical pull -------------------------------------------------------
  _ex(
    'lat_pulldown',
    primary: {MuscleGroup.lats},
    secondary: {MuscleGroup.biceps, MuscleGroup.upperBack},
    equipment: {Equipment.cableMachine},
    difficulty: Level.beginner,
    pattern: MovementPattern.verticalPull,
  ),
  _ex(
    'pull_up',
    primary: {MuscleGroup.lats},
    secondary: {MuscleGroup.biceps, MuscleGroup.upperBack},
    equipment: {Equipment.pullUpBar},
    difficulty: Level.advanced,
    pattern: MovementPattern.verticalPull,
    contraindications: {BodyPart.shoulders, BodyPart.elbows},
    easier: 'band_assisted_pull_up',
  ),
  _ex(
    'band_assisted_pull_up',
    primary: {MuscleGroup.lats},
    secondary: {MuscleGroup.biceps, MuscleGroup.upperBack},
    equipment: {Equipment.pullUpBar, Equipment.resistanceBand},
    difficulty: Level.intermediate,
    pattern: MovementPattern.verticalPull,
    contraindications: {BodyPart.shoulders},
    easier: 'lat_pulldown',
    harder: 'pull_up',
  ),

  // --- Core ----------------------------------------------------------------
  _ex(
    'plank',
    primary: {MuscleGroup.core},
    secondary: {MuscleGroup.shoulders},
    difficulty: Level.beginner,
    pattern: MovementPattern.core,
    metric: MetricType.holdSeconds,
    camera: _plankCamera,
    harder: 'side_plank',
  ),
  _ex(
    'side_plank',
    primary: {MuscleGroup.core, MuscleGroup.obliques},
    secondary: {MuscleGroup.shoulders},
    difficulty: Level.intermediate,
    pattern: MovementPattern.core,
    metric: MetricType.holdSeconds,
    unilateral: true,
    easier: 'plank',
  ),
  _ex(
    'dead_bug',
    primary: {MuscleGroup.core},
    difficulty: Level.beginner,
    pattern: MovementPattern.core,
  ),
  _ex(
    'bird_dog',
    primary: {MuscleGroup.core, MuscleGroup.lowerBack},
    difficulty: Level.beginner,
    pattern: MovementPattern.core,
    unilateral: true,
  ),
  _ex(
    'mountain_climber',
    primary: {MuscleGroup.core},
    secondary: {MuscleGroup.shoulders, MuscleGroup.quads},
    difficulty: Level.beginner,
    pattern: MovementPattern.core,
    contraindications: {BodyPart.wrists},
    secondsPerRep: 1.5,
  ),
  _ex(
    'hanging_knee_raise',
    primary: {MuscleGroup.core},
    secondary: {MuscleGroup.forearms},
    equipment: {Equipment.pullUpBar},
    difficulty: Level.intermediate,
    pattern: MovementPattern.core,
    contraindications: {BodyPart.shoulders},
  ),

  // --- Isolation -----------------------------------------------------------
  _ex(
    'db_curl',
    primary: {MuscleGroup.biceps},
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
  ),
  _ex(
    'db_hammer_curl',
    primary: {MuscleGroup.biceps},
    secondary: {MuscleGroup.forearms},
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
  ),
  _ex(
    'db_triceps_extension',
    primary: {MuscleGroup.triceps},
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
    contraindications: {BodyPart.elbows},
  ),
  _ex(
    'cable_triceps_pushdown',
    primary: {MuscleGroup.triceps},
    equipment: {Equipment.cableMachine},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
    contraindications: {BodyPart.elbows},
  ),
  _ex(
    'db_lateral_raise',
    primary: {MuscleGroup.shoulders},
    equipment: {Equipment.dumbbells},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
    contraindications: {BodyPart.shoulders},
  ),
  _ex(
    'face_pull',
    primary: {MuscleGroup.upperBack},
    secondary: {MuscleGroup.shoulders},
    equipment: {Equipment.cableMachine},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
  ),
  _ex(
    'calf_raise',
    primary: {MuscleGroup.calves},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
    secondsPerRep: 2,
  ),
  _ex(
    'seated_calf_raise',
    primary: {MuscleGroup.calves},
    equipment: {Equipment.machine},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
    secondsPerRep: 2,
  ),
  _ex(
    'leg_extension',
    primary: {MuscleGroup.quads},
    equipment: {Equipment.machine},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
    contraindications: {BodyPart.knees},
  ),
  _ex(
    'cable_fly',
    primary: {MuscleGroup.chest},
    equipment: {Equipment.cableMachine},
    difficulty: Level.intermediate,
    pattern: MovementPattern.isolation,
    contraindications: {BodyPart.shoulders},
  ),
  _ex(
    'wall_sit',
    primary: {MuscleGroup.quads},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
    metric: MetricType.holdSeconds,
  ),
  _ex(
    'superman',
    primary: {MuscleGroup.lowerBack},
    secondary: {MuscleGroup.glutes},
    difficulty: Level.beginner,
    pattern: MovementPattern.isolation,
  ),
];

/// The catalog the app ships with.
final ExerciseCatalog standardCatalog = ExerciseCatalog(standardExercises);
