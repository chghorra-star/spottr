import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'counter_catalog.dart';
import 'form_rule.dart';
import 'pose_signal.dart';

// ---------------------------------------------------------------------------
// The signals the form rules read, beyond the four the counters already use.
// ---------------------------------------------------------------------------

/// Which side of the shoulder-to-knee line the hip has fallen to, as a
/// percentage of that line's length.
///
/// The one signal that tells a sagging plank from a piked one. The angle at
/// the hip is the same for both — 180 minus the same number, whichever way
/// the hip went — and the side of the line it went to is not.
const hipOffset = JointOffset(
  joint: Joint.leftHip,
  from: Joint.leftShoulder,
  to: Joint.leftKnee,
);

/// Ear, shoulder, hip: the head's position on top of the trunk.
const neckAngle = JointAngle(
  from: Joint.leftEar,
  vertex: Joint.leftShoulder,
  to: Joint.leftHip,
);

/// Heel to toe, measured from vertical. 90 is a foot flat on the floor and
/// anything above it is a heel coming up off one.
const footTilt = SegmentTilt(from: Joint.leftHeel, to: Joint.leftFootIndex);

/// The trunk's length against the thigh's, as a percentage.
///
/// The spine proxy. There is no landmark between the shoulders and the hips,
/// so the trunk is a straight line by construction and a rounded back cannot
/// be seen directly. What can be seen is the line getting shorter, measured
/// against a bone whose length does not change.
const trunkRatio = SegmentRatio(
  segment: Segment(Joint.leftShoulder, Joint.leftHip),
  against: Segment(Joint.leftHip, Joint.leftKnee),
);

// ---------------------------------------------------------------------------
// The rules.
//
// Every number below is a plausible guess and not one of them is a
// measurement. They are internally consistent — `validateRules` and
// `form_rule_test.dart` see to that — and no rule here has ever been
// compared against footage of a real body performing a real fault. M8 does
// that, per rule, and publishes a false-positive rate alongside it.
//
// Until then the honest reading of a fired rule is "this movement looked
// like the shape we described", which is why nothing here cancels a rep and
// why the severity of the one `unsafe` rule is a curation judgement rather
// than a result.
// ---------------------------------------------------------------------------

/// Thighs to parallel. Measured at the deepest frame, because depth is a
/// question about one instant and averaging the frames either side of it
/// answers a different one.
const _squatDepth = SignalBoundRule(
  id: 'squat_depth',
  severity: RuleSeverity.minor,
  signal: kneeAngle,
  at: RepSample.peak,
  max: 100,
);

const _lungeDepth = SignalBoundRule(
  id: 'lunge_depth',
  severity: RuleSeverity.minor,
  signal: kneeAngle,
  at: RepSample.peak,
  max: 110,
);

const _hingeDepth = SignalBoundRule(
  id: 'hinge_depth',
  severity: RuleSeverity.minor,
  signal: hipAngle,
  at: RepSample.peak,
  max: 115,
);

/// The hips all the way up at the top of a bridge.
const _bridgeLockout = SignalBoundRule(
  id: 'bridge_lockout',
  severity: RuleSeverity.minor,
  signal: hipAngle,
  at: RepSample.peak,
  min: 165,
);

/// Elbows straight at the end of a push-up, which is where the rep ends.
const _lockout = SignalBoundRule(
  id: 'lockout',
  severity: RuleSeverity.minor,
  signal: elbowAngle,
  at: RepSample.top,
  min: 160,
);

/// Elbows straight at the end of a press, which is the **far** end of the
/// movement rather than the end of the rep.
///
/// Its own id for exactly the reason `bridge_lockout` has its own: a press
/// opens as it is performed, so full extension is at the deepest frame and
/// not at the top. One rule cannot read both without being told which way
/// the exercise runs, and a rule that needs to know that is not
/// configuration any more.
const _pressLockout = SignalBoundRule(
  id: 'press_lockout',
  severity: RuleSeverity.minor,
  signal: elbowAngle,
  at: RepSample.peak,
  min: 165,
);

/// A hinge is not a squat: the knees stay soft and nearly straight while the
/// hips do the moving.
const _kneeBend = SignalHoldRule(
  id: 'knee_bend',
  severity: RuleSeverity.minor,
  signal: kneeAngle,
  min: 150,
);

/// The hips dropped below the line of the body, which is a push-up or a
/// plank turning into a load on the lower back.
const _hipSag = SignalHoldRule(
  id: 'hip_sag',
  severity: RuleSeverity.major,
  signal: hipOffset,
  max: 6,
);

/// The hips pushed up above it, which is a plank made easier rather than a
/// plank done wrong — so it is worth saying once and no more.
const _hipPike = SignalHoldRule(
  id: 'hip_pike',
  severity: RuleSeverity.minor,
  signal: hipOffset,
  min: -8,
);

const _neckAlignment = SignalHoldRule(
  id: 'neck_alignment',
  severity: RuleSeverity.minor,
  signal: neckAngle,
  min: 150,
);

const _heelLift = SignalHoldRule(
  id: 'heel_lift',
  severity: RuleSeverity.minor,
  signal: footTilt,
  min: 80,
  max: 100,
);

/// Staying upright through a lunge.
const _torsoLean = SignalHoldRule(
  id: 'torso_lean',
  severity: RuleSeverity.minor,
  signal: trunkTilt,
  min: 155,
);

/// Leaning away from an overhead press instead of pressing it.
///
/// Measured as a lean from vertical in either direction, because
/// `angleFromVertical` is unsigned and nothing in the pose says which way
/// the user is facing. Under a press that is no loss — nobody leans forwards
/// into one — and it is why this rule no longer applies to the glute bridge,
/// where the trunk is horizontal by design and lumbar hyperextension is
/// invisible to a side-on skeleton with no landmark on the pelvis.
const _backArch = SignalHoldRule(
  id: 'back_arch',
  severity: RuleSeverity.major,
  signal: trunkTilt,
  min: 160,
);

/// A row rowed with the whole torso. Where the torso is, is not the
/// question; that it keeps moving while the arms work, is.
const _torsoSwing = SignalTravelRule(
  id: 'torso_swing',
  severity: RuleSeverity.major,
  signal: trunkTilt,
  max: 15,
);

/// The spine proxy, with the widest tolerance of any rule here.
///
/// **The one threshold in this file that is not a guess.** The accuracy
/// harness was asked how far the trunk-length ratio travels on each fixture
/// in the suite, and the answer separates into two groups: fixtures where
/// nothing rounds reach eleven points at the very worst, and the two
/// fixtures built with a trunk that shortens reach twenty and twenty-three.
///
/// The eleven is not noise in the fixture. It is three artefacts that all
/// shorten a trunk without anybody's back moving: landmark jitter, a limb
/// moving fast enough for the one-euro filter to lag, and the fact that
/// smoothing each landmark on its own does not preserve the distance
/// between two of them. Rotating towards the camera does the same thing and
/// no fixture here can show it.
///
/// So fifteen, between the two groups, with four points of margin either
/// side. It is still the rule most likely to be wrong on a real body, and
/// the only one serious enough to interrupt a set — an uncomfortable pairing
/// and the reason M7's cue arbitration has to make it fire twice running
/// before it says anything out loud.
const _backRounding = SignalTravelRule(
  id: 'back_rounding',
  severity: RuleSeverity.unsafe,
  signal: trunkRatio,
  max: 15,
);

/// Range shrinking across the set.
///
/// The one rule with no threshold in degrees, and therefore the one rule
/// that needs no footage before it can be trusted: it compares the user with
/// themselves a minute ago.
const _rom = RangeConsistencyRule(
  id: 'rom',
  severity: RuleSeverity.major,
);

const _tempo = DescentShareRule(
  id: 'tempo',
  severity: RuleSeverity.minor,
);

// ---------------------------------------------------------------------------
// The rules that are named and not evaluated.
//
// Entries rather than absences. A missing id would make the catalog look
// complete and the coach look thorough; these are counted by the validator,
// printed by the harness report, and shown to the user as things Spottr is
// not watching.
// ---------------------------------------------------------------------------

const _kneeValgus = PendingRule(
  id: 'knee_valgus',
  severity: RuleSeverity.major,
  reason: 'needs the front view: a knee falling inwards moves across the '
      'camera, and side on it moves along it. The signal is a joint offset '
      'from a near-vertical reference line, which has no gravity-referenced '
      'sign, and there is no front-view fixture generator to test it with.',
);

const _elbowFlare = PendingRule(
  id: 'elbow_flare',
  severity: RuleSeverity.major,
  reason: 'needs the front view, for the same reason as knee valgus: the '
      'elbow travels across the camera and not along it.',
);

const _elbowPath = PendingRule(
  id: 'elbow_path',
  severity: RuleSeverity.minor,
  reason: 'needs the front view, and a reference for where the elbow should '
      'be that does not exist until there is footage of a row done well.',
);

const _kneeTravel = PendingRule(
  id: 'knee_travel',
  severity: RuleSeverity.minor,
  reason: 'needs a signal that can name a side. Every PoseSignal averages '
      'the two, which is right for the seven symmetrical launch movements '
      'and wrong for a lunge, where one shin leans forwards and the other '
      'leans back and the mean of the two is a number about nobody.',
);

/// Every form rule the app can run, by the id a catalog entry refers to.
const Map<String, FormRule> formCatalog = {
  'squat_depth': _squatDepth,
  'lunge_depth': _lungeDepth,
  'hinge_depth': _hingeDepth,
  'bridge_lockout': _bridgeLockout,
  'lockout': _lockout,
  'press_lockout': _pressLockout,
  'knee_bend': _kneeBend,
  'hip_sag': _hipSag,
  'hip_pike': _hipPike,
  'neck_alignment': _neckAlignment,
  'heel_lift': _heelLift,
  'torso_lean': _torsoLean,
  'back_arch': _backArch,
  'torso_swing': _torsoSwing,
  'back_rounding': _backRounding,
  'rom': _rom,
  'tempo': _tempo,
  'knee_valgus': _kneeValgus,
  'elbow_flare': _elbowFlare,
  'elbow_path': _elbowPath,
  'knee_travel': _kneeTravel,
};

/// What the coach is watching for one exercise at one camera angle, and what
/// it is not.
///
/// Three lists rather than one, because "fine", "I cannot see that from
/// here" and "I do not check that yet" are three different things to tell
/// somebody, and a coach that collapses them into silence is claiming the
/// first.
@immutable
class RuleSelection {
  const RuleSelection({
    required this.active,
    required this.pending,
    required this.blind,
  });

  /// Rules that will actually be evaluated, in id order.
  final List<FormRule> active;

  /// Rules this angle could evaluate and the engine cannot yet.
  final List<FormRule> pending;

  /// Rules this exercise has that the camera angle in use cannot see.
  final Set<String> blind;

  /// Whether every rule the exercise has is being evaluated.
  bool get complete => pending.isEmpty && blind.isEmpty;

  /// Everything an analyzer has to sample to run [active].
  Set<PoseSignal> get signals => {
        for (final rule in active) ...rule.signals,
      };

  /// Rules of a given severity, for a caller that cares which.
  List<FormRule> withSeverity(RuleSeverity severity) =>
      [for (final rule in active) if (rule.severity == severity) rule];

  @override
  String toString() => 'RuleSelection(${active.length} active, '
      '${pending.length} pending, ${blind.length} blind)';
}

/// The rules for [exercise] at [angle], defaulting to its recommended angle.
///
/// An angle the exercise does not accept evaluates nothing at all: that is
/// the setup screen's problem to prevent, and silently coaching from an
/// unsupported angle would be worse than refusing to.
RuleSelection rulesFor(
  Exercise exercise, {
  CameraAngle? angle,
  Map<String, FormRule> rules = formCatalog,
}) {
  final camera = exercise.camera;
  if (camera == null) {
    return const RuleSelection(active: [], pending: [], blind: {});
  }

  final enabled = camera.rulesEnabledAt(angle ?? camera.recommendedAngle);
  final active = <FormRule>[];
  final pending = <FormRule>[];

  for (final id in enabled.toList()..sort()) {
    final rule = rules[id];
    // A rule the table does not have is a configuration error that
    // `validateRules` reports as one. Dropping it here keeps a typo from
    // taking down a set.
    if (rule == null) continue;
    if (rule is PendingRule) {
      pending.add(rule);
    } else {
      active.add(rule);
    }
  }

  return RuleSelection(
    active: active,
    pending: pending,
    blind: camera.formRuleIds.difference(enabled),
  );
}

/// What can be wrong with a rule configuration.
enum RuleProblemKind {
  /// A camera-supported exercise names a rule that does not exist.
  missingRule,

  /// A rule no exercise refers to.
  unreferenced,

  /// The entry is filed under a key that is not its own id.
  idMismatch,

  /// The bound or band runs the wrong way round, so nothing can satisfy it.
  backwardsBounds,

  /// A tolerance that allows every frame to be out of position, which means
  /// the rule can never fail.
  toothlessTolerance,

  /// A travel bound no movement could stay inside, including standing still.
  impossibleTravel,

  /// A share or fraction outside the range a fraction can take.
  impossibleFraction,

  /// A rule declared pending without saying what it is waiting for.
  unexplainedGap,
}

/// One defect in the rule table.
@immutable
class RuleProblem {
  const RuleProblem(this.ruleId, this.kind, this.detail);

  final String ruleId;
  final RuleProblemKind kind;

  /// Actionable specifics, because this is read in a test failure.
  final String detail;

  @override
  String toString() => '[$ruleId] ${kind.name}: $detail';
}

/// Every defect in [rules] as used by [catalog]. Empty is the shipping
/// condition, asserted by `form_catalog_test.dart`.
///
/// None of this is checkable at the point of use. A band that runs backwards
/// is a rule that fires on every rep for ever, and a tolerance of 1 is a
/// rule that never fires at all — and from the outside the second one is
/// indistinguishable from good form.
List<RuleProblem> validateRules(
  ExerciseCatalog catalog, {
  Map<String, FormRule> rules = formCatalog,
}) {
  final problems = <RuleProblem>[];
  final referenced = <String>{};

  for (final exercise in catalog.all) {
    final camera = exercise.camera;
    if (camera == null) continue;
    for (final id in camera.formRuleIds) {
      referenced.add(id);
      if (!rules.containsKey(id)) {
        problems.add(
          RuleProblem(
            id,
            RuleProblemKind.missingRule,
            'referred to by ${exercise.id} and not in the table',
          ),
        );
      }
    }
  }

  void fraction(String id, String name, double value) {
    if (value <= 0 || value > 1) {
      problems.add(
        RuleProblem(
          id,
          RuleProblemKind.impossibleFraction,
          '$name is $value, and a share of something is between 0 and 1',
        ),
      );
    }
  }

  void bounds(String id, double? min, double? max) {
    if (min != null && max != null && min > max) {
      problems.add(
        RuleProblem(
          id,
          RuleProblemKind.backwardsBounds,
          'from $min to $max, which nothing can satisfy',
        ),
      );
    }
  }

  for (final entry in rules.entries) {
    final rule = entry.value;
    final id = rule.id;

    if (entry.key != id) {
      problems.add(
        RuleProblem(
          entry.key,
          RuleProblemKind.idMismatch,
          'filed under "${entry.key}" but calls itself "$id"',
        ),
      );
    }

    if (!referenced.contains(entry.key)) {
      problems.add(
        RuleProblem(
          entry.key,
          RuleProblemKind.unreferenced,
          'no exercise in the catalog asks for it',
        ),
      );
    }

    switch (rule) {
      case SignalBoundRule():
        bounds(id, rule.min, rule.max);
      case SignalHoldRule():
        bounds(id, rule.min, rule.max);
        if (rule.tolerance < 0 || rule.tolerance >= 1) {
          problems.add(
            RuleProblem(
              id,
              RuleProblemKind.toothlessTolerance,
              'allows ${rule.tolerance} of the frames out of position, so it '
                  'can never fail',
            ),
          );
        }
      case SignalTravelRule():
        if (rule.max <= 0) {
          problems.add(
            RuleProblem(
              id,
              RuleProblemKind.impossibleTravel,
              'allows ${rule.max} of travel, which standing still would '
                  'exceed',
            ),
          );
        }
      case RangeConsistencyRule():
        fraction(id, 'minFraction', rule.minFraction);
      case DescentShareRule():
        fraction(id, 'minShare', rule.minShare);
      case PendingRule():
        if (rule.reason.trim().isEmpty) {
          problems.add(
            RuleProblem(
              id,
              RuleProblemKind.unexplainedGap,
              'declared pending with no reason, so nobody can tell what it '
                  'is waiting for',
            ),
          );
        }
    }
  }

  return problems;
}
