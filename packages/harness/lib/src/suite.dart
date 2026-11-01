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
/// **What passing this proves:** the state machine, the thresholds and the
/// smoothing agree with each other on movement of a known shape.
/// **What it does not prove:** anything at all about a real body. There is
/// no clothing here, no occlusion, no model error, no camera. See
/// `docs/dev-loop.md` for what the accuracy targets can honestly claim
/// before there is footage.
List<PoseFixture> syntheticSuite() => [
      syntheticReps(
        name: 'squat_clean_8',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(8, const SyntheticRep()),
        expectedReps: 8,
        notes: 'eight full-depth reps at an even tempo',
      ),
      syntheticReps(
        name: 'squat_shallow_6',
        exerciseId: 'bodyweight_squat',
        top: squatTop,
        bottom: squatBottom,
        reps: List.filled(6, const SyntheticRep(depth: 0.65)),
        expectedReps: 6,
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
            'other two have to appear in the ledger with a reason',
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
            'is what the smoothing filter and the hysteresis band are for',
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
        name: 'pushup_clean_10',
        exerciseId: 'push_up',
        top: pushUpTop,
        bottom: pushUpBottom,
        reps: List.filled(10, const SyntheticRep()),
        expectedReps: 10,
        notes: 'ten push-ups, body in one line throughout',
      ),
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
        notes: 'twenty seconds with the hips dropped for five of them: the '
            'clock has to stop for the sag and keep what it had',
      ),
    ];
