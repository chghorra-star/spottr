# Spottr — architecture

Spottr generates adaptive gym plans and acts as a live form coach through the
phone camera. This document records the structure and the decisions behind it.
It is the reference for every milestone; update it when a decision changes.

## The one decision everything else follows from

**Camera capture and pose inference run in native code. Only landmark frames
cross the bridge.**

Native Kotlin (CameraX + ML Kit Pose) and Swift (AVFoundation + ML Kit) own
the camera and the model. They emit a `PoseFrame` — 33 landmarks, a timestamp
and a confidence — over an `EventChannel`. No pixel buffer is ever copied into
the Dart heap.

Everything above that is pure Dart with no camera dependency, which is what
makes the accuracy harness possible: the entire rep-counting and form-analysis
stack can be driven from recorded fixtures with no device attached.

## Platform choice

Flutter 3.44 / Dart 3.12, iOS and Android from one codebase.

React Native with VisionCamera frame processors was the serious alternative and
is genuinely strong at real-time ML. It lost because the ML runs native either
way, so the bridge argument mostly evaporates — and against that it would mean
trading a stack already proven on another shipped app for one that is not.

## Package layout

A Dart pub workspace: one `pubspec.lock`, one `flutter pub get` at the root.
Four of the six packages are pure Dart and test in milliseconds.

```
app/                    Flutter app — UI, DI, Drift, platform wiring
packages/
  pose_core/            [pure] PoseFrame, Joint, geometry, filters
  exercise_library/     [pure] catalog schema + JSON assets + integrity checks
  coach_engine/         [pure] rep state machines, form rules, scoring, cues
  plan_engine/          [pure] templates, slot filling, progression
  harness/              [pure] CLI: replay fixtures, report accuracy, fail CI
  pose_camera/          [plugin] native camera + pose, plus FakePoseCamera
```

The dependency direction is strictly one way: `app` depends on everything,
`coach_engine` depends on `pose_core` and `exercise_library`, and nothing pure
depends on Flutter. A `flutter` import appearing under `packages/*_core` or
`packages/*_engine` is a design regression.

## Coordinate convention

Landmarks are normalized image space: **x grows right, y grows down**, matching
both ML Kit and MediaPipe. Every form rule depends on this, so it is pinned by
tests in `pose_core/test/geometry_test.dart`.

`angleAtVertex` and `angleFromVertical` return `double?`, not `double`. A
degenerate frame returns `null` rather than `NaN`, because a `NaN` silently
poisons every downstream threshold comparison instead of failing loudly.

## Joint ordering is a wire contract

`Joint` declares the 33 BlazePose landmarks **in BlazePose index order**. The
native bridge and the offline video extractor both send landmarks as a flat
array indexed by position, so reordering the enum would silently remap every
joint in the app. `pose_frame_test.dart` pins the ordinals.

## Rep counting

One config-driven state machine, instantiated per exercise from catalog data:

```
idle -> ready(top) -> descending -> bottom -> ascending -> repComplete
```

Thresholds (`topThreshold`, `bottomThreshold`, `hysteresis`,
`minRepDuration`, `maxRepDuration`, `minRangeOfMotion`) are catalog JSON, not
code. Tuning a squat is a data edit; adding a ninth camera exercise is a new
catalog entry. Plank and other holds swap in a `HoldCounter` that accumulates
time in valid posture and pauses on violation.

Each rep emits a `RepEvent` with its index, duration, peak angle, range of
motion, tempo, form score, violations, and `counted` plus a reason.

### Rejected reps are surfaced, never swallowed

A counter that silently ignores a rep reads as broken. Every rep lands in one
of three outcomes — `counted`, `counted with warning`, `not counted` — and the
set summary shows the ledger with the reason for each.

### Why "count at a bad angle" and "don't count unsafe reps" do not conflict

These two requirements appear to collide on a risky-looking rep at a poor
angle. They do not, because **rejection for safety requires evidence, and
evidence requires the angle.**

A rep is only rejected for unsafe form when the rule that flagged it was
enabled at the current camera angle. From the front we cannot see back
rounding, so we never reject for it — we count the rep and tell the user the
angle limits feedback. Partial-range rejection works at any angle the counter
supports, so it always applies.

The user is therefore never punished for our blind spots, and every rejection
is explainable.

## Form rules

Each rule is a pure function over a `RepWindow` (the frames of one rep plus
derived angles), declaring which camera angles it needs:

```dart
abstract class FormRule {
  String get id;
  Set<CameraAngle> get requiredAngles;
  FormVerdict evaluate(RepWindow window);
}
```

Severity is `ok | minor | major | unsafe`. Form score is 100 minus weighted
penalties scaled by violation magnitude, clamped — fully deterministic, so a
decision table covers it.

Launch rules: squat depth, knee valgus (front), back rounding (side), hips
rising early (side), elbow flare, lockout, range of motion, tempo, plank hip
sag.

## Coach voice

```dart
abstract class CoachVoice { CoachLine? lineFor(CoachEvent e, CoachPersonality p); }
```

`RulesCoachVoice` selects from a cue library keyed by event, personality and
severity. `LlmCoachVoice` exists as a feature-flagged stub; the MVP is
rule-based so it stays offline, free, deterministic and testable.

**Cue arbitration is the hard part.** Events fire at up to 30 Hz while TTS
speaks roughly one short phrase per 1.5 s. Without a budget the coach queues up
and drifts seconds behind the set, which users read as broken. Cues therefore
pass through a priority queue with cooldowns — safety preempts correction,
correction preempts motivation — and anything stale at dequeue time is dropped
rather than spoken late.

All user-facing strings live in ARB files from day one.

## Plan generation

```
PlanRequest{goal, daysPerWeek, sessionMinutes, level, equipment, injuries, runDays}
  -> WeekTemplate         fullBody x2-3 | upperLower x4 | ppl x5-6
  -> SlotSpec per day     {pattern, priority, metric, repRangeByGoal}
  -> filter candidates    equipment available, difficulty <= level+1,
                          no contraindication against a declared injury
  -> rank                 camera-supported first, then pattern fit,
                          then variety against recent history
  -> fit to time budget   sets x (reps x tempo + rest) <= sessionMinutes
```

Hybrid goal: run days are marked, heavy squat/hinge/lunge slots are forbidden
the day before one, and running output is text suggestion only. Spottr does not
track runs.

## Progression

```
ProgressionInput{planned, completed(reps, weight, formScores), sessionRating}
  -> ProgressionDecision{nextWeight, nextReps, nextSets, swapTo?, reason}
```

All reps at the top of range with mean form >= 85 and not rated too-hard raises
load. Form below 70 across two sessions cuts load 10% or regresses via the
catalog's easier variant. Missed reps or a too-hard rating holds or drops 5%.

Every decision carries its `reason` string, so the UI can say "Weight up — you
hit all 10 at 92% form" instead of silently changing numbers. That string is
also the assertion target in tests.

## Persistence

Drift / SQLite, local-first. The MVP has no network at all.

Schema v1 already carries `updated_at`, `deleted_at` and `device_id` on every
table that will eventually replicate, so adding Supabase later is one
implementation class rather than a migration across nine tables. Deletes are
soft; a hard delete is invisible to a peer.

`rep_logs` and `form_events` are deliberately **local-only**: per-rep traces and
rule verdicts are thousands of rows per session, invaluable for debugging and
for generating harness fixtures, and of no use to another device.
`database_test.dart` asserts that every table is classified one way or the
other, so a new table cannot be added without that decision being made.

## Observability

A `DecisionLog` ring buffer records, per frame, pose confidence, derived
angles, state machine transitions and every rule verdict. Any set can be dumped
to JSON — which is both the debugging artifact and a replayable regression
fixture.

This is the mechanism that turns real use into test data: a recorded set
produces landmark JSON that can be labeled later, with no video stored at any
point.

## Privacy

Video never leaves the device, and under this design it never needs to be
stored at all. The optional local clip recording in the brief is deferred and
is the first feature to cut. Nothing in the sync design carries frames, images
or landmark traces off the device.

## Testing

- Pure-Dart packages hold the logic, so most of the suite runs in milliseconds
  with no device and no Flutter engine.
- Plan generation is checked with property tests over randomized profiles
  asserting invariants — no contraindicated exercise, correct day count, every
  day inside its time budget — rather than only golden outputs.
- Progression is a decision table.
- The live coach is tested by driving `FakePoseCamera` through a recorded set
  and asserting the exact cue sequence.
- The accuracy harness reports rep-count error and per-rule precision and
  recall, and gates CI once it exists in M5.

Acceptance targets: rep count accuracy >= 95% at the recommended angle, form
warnings firing on labeled faults with a low false-positive rate. These are
measurements against labeled footage, not checkboxes — see `docs/dev-loop.md`
for where that footage comes from and what is honestly claimable without it.
