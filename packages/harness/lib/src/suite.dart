import 'dart:math' as math;

import 'fixture.dart';
import 'synthetic.dart';

/// The committed synthetic suite.
///
/// Generated rather than stored, because the alternative is megabytes of
/// float arrays in the repository that nobody can review. The cases are the
/// reviewable part, and they are chosen to be the ones a rep counter gets
/// wrong: not eight clean reps, but eight clean reps with noise on them,
/// two that stop half way, a set bounced too fast to be real, and a rep the
/// tracker loses in the middle.
///
/// From M6 every fixture also carries the form rules that **should** fire on
/// it, including the empty label — which is the one that catches a rule
/// firing on good form. Those labels are written here, by hand, from what
/// each case was built to contain. Deriving them from the thresholds would
/// make the suite agree with the engine by construction.
///
/// **What passing this proves:** the state machine, the thresholds, the
/// rules and the smoothing agree with each other on movement of a known
/// shape.
/// **What it does not prove:** anything at all about a real body. There is
/// no clothing here, no occlusion, no model error, no camera. See
/// `docs/dev-loop.md` for what the accuracy targets can honestly claim
/// before there is footage.
List<PoseFixture> syntheticSuite() => [
      // --- Squat: counting ------------------------------------------------
      syntheticReps(
        name: 'squat_clean_8',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        notes: 'eight full-depth reps at an even tempo, and nothing for any '
            'rule to say about them',
      ),
      syntheticReps(
        name: 'squat_shallow_6',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(6, const SyntheticRep(depth: 0.65)),
        expectedReps: 6,
        expectedFaults: {'squat_depth'},
        notes: 'six reps that stop above depth: counted, and every one of '
            'them flagged shallow',
      ),
      syntheticReps(
        name: 'squat_six_of_eight',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: const [
          SyntheticRep(),
          SyntheticRep(),
          SyntheticRep(),
          SyntheticRep(depth: 0.45),
          SyntheticRep(),
          SyntheticRep(),
          SyntheticRep(depth: 0.45),
          SyntheticRep(),
        ],
        expectedReps: 6,
        notes: 'eight attempts, two of them barely a dip: six count and the '
            'other two have to appear in the ledger with a reason. No rule '
            'fires, because the rules do not judge an attempt the counter '
            'has already refused',
      ),
      syntheticReps(
        name: 'squat_bounced_8',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(
          8,
          const SyntheticRep(duration: Duration(milliseconds: 400)),
        ),
        expectedReps: 0,
        notes: 'full range at 400ms a rep, which no squat is: none of them '
            'count',
      ),
      syntheticReps(
        name: 'squat_noisy_8',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        jitter: 0.008,
        random: math.Random(11),
        notes: 'eight clean reps with landmark noise on every joint, which '
            'is what the smoothing filter and the hysteresis band are for. '
            'No rule may fire: a rule that trips on noise is a rule that '
            'trips on every set',
      ),
      syntheticReps(
        name: 'squat_dropout_8',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 7,
        dropoutFrom: const Duration(milliseconds: 8700),
        dropoutFor: const Duration(milliseconds: 600),
        notes: 'the model loses the body at the bottom of the fourth rep: '
            'that rep is abandoned and the other seven count',
      ),
      syntheticReps(
        name: 'squat_paused_4',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(
          4,
          const SyntheticRep(holdAtBottom: Duration(milliseconds: 1500)),
        ),
        expectedReps: 4,
        notes: 'a second and a half held at the bottom of each rep, which is '
            'a slow rep and not an abandoned one',
      ),

      // --- Squat: form ----------------------------------------------------
      syntheticReps(
        name: 'squat_rounded_6',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatRoundedBottom,
        reps: List.filled(6, const SyntheticRep()),
        expectedReps: 6,
        expectedFaults: {'back_rounding'},
        notes: 'full depth with the trunk shortening on the way down, which '
            'is what a rounding back looks like to a skeleton that has no '
            'landmark on the spine',
      ),
      syntheticReps(
        name: 'squat_heels_up_6',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatHeelsUpBottom,
        reps: List.filled(6, const SyntheticRep()),
        expectedReps: 6,
        expectedFaults: {'heel_lift'},
        notes: 'full depth with the heels coming off the floor at the bottom',
      ),
      syntheticReps(
        name: 'squat_fading_8',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: const [
          SyntheticRep(),
          SyntheticRep(),
          SyntheticRep(),
          SyntheticRep(depth: 0.95),
          SyntheticRep(depth: 0.85),
          SyntheticRep(depth: 0.75),
          SyntheticRep(depth: 0.7),
          SyntheticRep(depth: 0.7),
        ],
        expectedReps: 8,
        expectedFaults: {'rom', 'squat_depth'},
        notes: 'eight reps getting shorter as the set goes on, which is what '
            'fatigue looks like. Every one of them counts and the later ones '
            'are measured against the earlier ones',
      ),
      syntheticReps(
        name: 'squat_dropped_6',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(6, const SyntheticRep(descentShare: 0.15)),
        expectedReps: 6,
        expectedFaults: {'tempo'},
        notes: 'full depth and full range, dropped into in a sixth of the '
            'rep and ground back up over the rest of it',
      ),

      // --- Push-up --------------------------------------------------------
      syntheticReps(
        name: 'pushup_clean_10',
        exerciseId: 'push_up',
        top: pushUpTop,
        bottom: pushUpBottom,
        reps: List.filled(10, const SyntheticRep()),
        expectedReps: 10,
        notes: 'ten push-ups, body in one line throughout',
      ),
      syntheticReps(
        name: 'pushup_sagging_8',
        exerciseId: 'push_up',
        top: pushUpTop,
        bottom: pushUpSaggingBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        expectedFaults: {'hip_sag'},
        notes: 'eight push-ups with the hips dropping out of line at the '
            'bottom of each one',
      ),
      syntheticReps(
        name: 'pushup_soft_lockout_8',
        exerciseId: 'push_up',
        top: pushUpSoftTop,
        bottom: pushUpBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        expectedFaults: {'lockout'},
        notes: 'eight push-ups that never quite straighten the arms at the '
            'top. Still inside the tolerance the counter needs to see a top, '
            'which is the only reason they are counted at all',
      ),

      // --- Shoulder press -------------------------------------------------
      syntheticReps(
        name: 'press_clean_6',
        exerciseId: 'db_shoulder_press',
        top: pressRacked,
        bottom: pressLockout,
        reps: List.filled(6, const SyntheticRep()),
        expectedReps: 6,
        notes: 'six presses: the movement whose measured angle opens rather '
            'than closes as the rep is performed',
      ),
      syntheticReps(
        name: 'press_half_6',
        exerciseId: 'db_shoulder_press',
        top: pressRacked,
        bottom: pressLockout,
        reps: List.filled(6, const SyntheticRep(depth: 0.7)),
        expectedReps: 6,
        expectedFaults: {'press_lockout'},
        notes: 'six presses that stop short of the lockout overhead',
      ),
      syntheticReps(
        name: 'press_leaning_6',
        exerciseId: 'db_shoulder_press',
        top: pressRacked,
        bottom: pressLeaningLockout,
        reps: List.filled(6, const SyntheticRep()),
        expectedReps: 6,
        expectedFaults: {'back_arch'},
        notes: 'six presses with the torso leaning away from the weight '
            'instead of pressing it',
      ),

      // --- Hinge ----------------------------------------------------------
      syntheticReps(
        name: 'hinge_clean_8',
        exerciseId: 'db_romanian_deadlift',
        top: hingeTop,
        bottom: hingeBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        notes: 'eight hinges: hips back, knees long, trunk rigid',
      ),
      syntheticReps(
        name: 'hinge_rounded_6',
        exerciseId: 'db_romanian_deadlift',
        top: hingeTop,
        bottom: hingeRoundedBottom,
        reps: List.filled(6, const SyntheticRep()),
        expectedReps: 6,
        expectedFaults: {'back_rounding'},
        notes: 'the fault the whole severity scale exists for: a back '
            'rounding under load, as a trunk that shortens through the rep',
      ),
      syntheticReps(
        name: 'hinge_shallow_6',
        exerciseId: 'db_romanian_deadlift',
        top: hingeTop,
        bottom: hingeBottom,
        reps: List.filled(6, const SyntheticRep(depth: 0.6)),
        expectedReps: 6,
        expectedFaults: {'hinge_depth'},
        notes: 'six hinges that stop well above the depth this exercise is '
            'prescribed for',
      ),
      syntheticReps(
        name: 'hinge_squatted_6',
        exerciseId: 'db_romanian_deadlift',
        top: hingeTop,
        bottom: hingeKneesBentBottom,
        reps: List.filled(6, const SyntheticRep()),
        expectedReps: 6,
        expectedFaults: {'knee_bend'},
        notes: 'six hinges turned into squats by bending the knees, which is '
            'the most common way a hinge stops training what it is for',
      ),

      // --- Glute bridge ---------------------------------------------------
      syntheticReps(
        name: 'bridge_clean_8',
        exerciseId: 'glute_bridge',
        top: bridgeDown,
        bottom: bridgeUp,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        notes: 'eight bridges from the floor to full hip extension. Like a '
            'press, the measured angle opens as the rep is performed',
      ),
      syntheticReps(
        name: 'bridge_low_6',
        exerciseId: 'glute_bridge',
        top: bridgeDown,
        bottom: bridgeUp,
        reps: List.filled(6, const SyntheticRep(depth: 0.6)),
        expectedReps: 6,
        expectedFaults: {'bridge_lockout'},
        notes: 'six bridges that never finish the hip extension at the top',
      ),

      // --- Row ------------------------------------------------------------
      syntheticReps(
        name: 'row_clean_8',
        exerciseId: 'db_bent_over_row',
        top: rowTop,
        bottom: rowBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        notes: 'eight rows with the torso held still throughout',
      ),
      syntheticReps(
        name: 'row_swinging_6',
        exerciseId: 'db_bent_over_row',
        top: rowTop,
        bottom: rowSwungBottom,
        reps: List.filled(6, const SyntheticRep()),
        expectedReps: 6,
        expectedFaults: {'torso_swing'},
        notes: 'six rows pulled with the whole torso. Where the torso is, is '
            'not the fault; that it keeps moving while the arms work, is',
      ),

      // --- Plank ----------------------------------------------------------
      syntheticHold(
        name: 'plank_30s',
        exerciseId: 'plank',
        posture: plankHeld,
        duration: const Duration(seconds: 30),
        expectedHold: const Duration(seconds: 30),
        notes: 'thirty seconds held straight',
      ),
      syntheticHold(
        name: 'plank_broken_20s',
        exerciseId: 'plank',
        posture: plankHeld,
        broken: plankSagging,
        duration: const Duration(seconds: 20),
        breakFrom: const Duration(seconds: 8),
        breakFor: const Duration(seconds: 5),
        expectedHold: const Duration(seconds: 15),
        expectedFaults: {'hip_sag'},
        notes: 'twenty seconds with the hips dropped for five of them: the '
            'clock has to stop for the sag and keep what it had, and the sag '
            'has to still be in the set review after the hips come back up',
      ),
      syntheticHold(
        name: 'plank_piked_20s',
        exerciseId: 'plank',
        posture: plankHeld,
        broken: plankPiked,
        duration: const Duration(seconds: 20),
        breakFrom: const Duration(seconds: 8),
        breakFor: const Duration(seconds: 5),
        expectedHold: const Duration(seconds: 15),
        expectedFaults: {'hip_pike'},
        notes: 'the same five seconds out of position the other way up. A '
            'sag and a pike give the hip the same angle and opposite sides '
            'of the shoulder-to-knee line, and only the second of those can '
            'tell them apart',
      ),
      syntheticHold(
        name: 'plank_head_down_15s',
        exerciseId: 'plank',
        posture: plankHeadDown,
        duration: const Duration(seconds: 15),
        expectedHold: const Duration(seconds: 15),
        expectedFaults: {'neck_alignment'},
        notes: 'fifteen seconds held straight with the head hanging off the '
            'front of it. The hold is good and the neck is not',
      ),
    ];
