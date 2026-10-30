/// Experience level, used for both a user's self-reported experience and an
/// exercise's difficulty. The same three-point scale on purpose: it makes
/// "would I offer this exercise to this user" a single comparison.
enum Level {
  beginner,
  intermediate,
  advanced;

  /// Whether this level is at or below [other].
  bool isAtMost(Level other) => index <= other.index;
}

/// Muscle groups the catalog can target. Coarse by design — finer anatomy
/// would not change which exercise the generator picks.
enum MuscleGroup {
  quads,
  hamstrings,
  glutes,
  calves,
  adductors,
  abductors,
  chest,
  lats,
  upperBack,
  lowerBack,
  shoulders,
  biceps,
  triceps,
  forearms,
  core,
  obliques,
}

/// Equipment an exercise can require.
///
/// There is deliberately no "none" value: an exercise that needs nothing has
/// an empty requirement set, which makes availability a plain subset check.
enum Equipment {
  dumbbells,
  barbell,
  kettlebell,
  bench,
  pullUpBar,
  dipBars,
  cableMachine,
  machine,
  resistanceBand,
  box,
}

/// Where the user trains, and what that implies they have.
enum TrainingLocation {
  homeNone,
  homeDumbbells,
  fullGym;

  /// Equipment this location implies before the user adds anything extra.
  Set<Equipment> get impliedEquipment => switch (this) {
        TrainingLocation.homeNone => const {},
        TrainingLocation.homeDumbbells => const {Equipment.dumbbells},
        TrainingLocation.fullGym => Equipment.values.toSet(),
      };
}

/// Injury sites the user can declare. Onboarding exposes knees, lower back,
/// shoulders and wrists as checkboxes; the rest exist so the catalog can be
/// precise about what a given exercise loads.
enum BodyPart {
  knees,
  lowerBack,
  shoulders,
  wrists,
  hips,
  ankles,
  elbows,
  neck,
}

/// What an exercise fundamentally does. Plan templates are written in terms
/// of patterns rather than named exercises, which is what lets the same
/// template serve a bodyweight-at-home user and a full-gym user.
enum MovementPattern {
  squat,
  hinge,
  lunge,
  horizontalPush,
  verticalPush,
  horizontalPull,
  verticalPull,
  core,
  isolation,
  carry;

  /// Whether this pattern puts meaningful load through the legs.
  ///
  /// Drives the hybrid-goal rule that keeps heavy leg work off the day before
  /// a run.
  bool get isLegDominant =>
      this == MovementPattern.squat ||
      this == MovementPattern.hinge ||
      this == MovementPattern.lunge;

  /// Whether this pattern earns a primary slot in a session. Accessory work
  /// is dropped first when a session has to fit a shorter time budget.
  bool get isCompound =>
      this != MovementPattern.isolation && this != MovementPattern.core;
}

/// How a set is measured.
enum MetricType {
  /// Counted repetitions.
  reps,

  /// Time under tension, for planks and other holds.
  holdSeconds,
}
