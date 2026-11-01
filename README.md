# Spottr

Adaptive gym plans, plus a live form coach through the phone camera: it counts
reps, flags risky technique, and coaches out loud while you train.

All pose processing happens on the device. **Video never leaves the phone, and
nothing is uploaded.**

Spottr gives form feedback and flags movement that looks risky. It is not
medical advice and does not prevent injury.

## Status

M6 complete — it judges form. Seventeen rules, each an id, a severity, a
signal and a number, run against every rep the counter accepts: the coach
screen says what to fix, scores the set, and names the checks it is **not**
running. 925 tests green, analyzer clean.

**Nothing a rule says cancels a rep.** A minor is worth saying once, a major
every time, and an unsafe means stop the set and take weight off — but every
threshold behind every rule is still a guess, and deleting work somebody
actually did on the strength of an unvalidated proxy is the one failure mode
that makes a coach impossible to trust.

The score is not a feeling. It is anchored to the progression table: a
coaching point on every rep still earns weight, a cue firing every rep holds
it, and a set that looked unsafe takes weight off after a second one.

**Every attempt is accounted for.** A rep can be counted, counted with a
warning, or not counted, and each one carries the reason: too shallow to be
a rep, past the bar but short of depth, faster than the movement allows,
abandoned half way, or lost to tracking. A counter that silently ignores
what you just did reads as broken.

Alongside it, `packages/harness` replays labelled landmark fixtures through
the real pipeline and gates CI on both the count and the rules — in both
directions, so a rule that fires on good form fails the build too. It has
found five defects across two milestones, including a smoothing coefficient
three orders of magnitude off for its signal and a travel bound that was
measuring landmark noise and calling it movement. What it cannot do is tell
you the engine is accurate: every fixture so far is generated, and the report
says so every time it prints a number.

Before M6, M5 made it count. One state machine, configured per exercise from
a table of thresholds, turns the landmark stream into reps — direction is
configuration, so the same machine serves a squat whose knee angle closes and
a bridge whose hip angle opens. A plank gets a clock instead, which stops
when the hips drop and keeps what it had.

Before that, M4 wired up the camera end to end: native CameraX and ML Kit own
capture and inference, the only thing crossing the bridge is a flat buffer
of 33 landmarks, and the camera check shows the live preview with the
tracked skeleton over it. Landmarks are smoothed once, by a one-euro filter
whose cutoff rises with speed. The framing check is pure arithmetic over one
frame and names **one** thing to fix, because a setup screen listing four
complaints gets read as none of them. Mirroring the front lens happens once,
in Flutter, where the preview and the skeleton are flipped together — a
second flip on the native side would cancel it out and nothing would look
wrong until a form rule read a left knee on the right.

Before that, M3 made the plan trainable: a day card starts a session, sets are
logged against the exact prescription they were performed against, and
finishing asks how it felt and writes what the session earned into the plan
as a new revision. Progression is a decision table with safety at the top of
it — the pain button stops anything going up, an unfinished session is not
treated as evidence about the weight, and a missing form score counts as no
objection rather than as failure.

Session length shapes a plan rather than only capping it: a template describes
the longest sensible session and the budget decides how much of it you get, so
an hour produces an hour's work instead of half of one. When a week genuinely
cannot be filled — bodyweight at home tops out around forty-five minutes —
Spottr says so rather than padding it out.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the design and
[docs/dev-loop.md](docs/dev-loop.md) for how to run and verify it.

| Milestone | Scope | State |
| --- | --- | --- |
| M0 | Scaffold and rails | done |
| M1 | Exercise library + plan generation | done |
| M2 | Onboarding, profile, plan UI | done |
| M3 | Workout logging + progression | done |
| M4 | Pose plumbing, native bridge, overlay | done |
| M5 | Rep counting + accuracy harness | done |
| M6 | Form rules + scoring | done |
| M7 | Live coach UX, voice, safety | next |
| M8 | Dataset validation and tuning | |
| M9 | iOS parity, cloud CI, TestFlight | |
| M10 | Supabase sync | |

## Layout

```
app/                    Flutter app
packages/pose_core/     pose primitives and geometry      [pure Dart]
packages/exercise_library/  curated exercise catalog      [pure Dart]
packages/coach_engine/  counting, form rules, scoring     [pure Dart]
packages/plan_engine/   plan generation, progression      [pure Dart]
packages/harness/       accuracy harness CLI              [pure Dart]
packages/pose_camera/   native camera + pose inference    [Flutter plugin]
```

This is a Dart pub workspace: one lockfile, and `flutter pub get` runs from the
repo root, never inside a package.

The five pure-Dart packages must never import Flutter. That constraint is
what lets the entire rep-counting and form-analysis stack be measured from
recorded fixtures with no device attached:

```bash
cd packages/harness
dart run bin/harness.dart
```

## Getting started

```bash
flutter pub get
powershell -ExecutionPolicy Bypass -File tool/check.ps1
```

Run the app:

```bash
cd app
flutter run
```

## Development

Test-first. Logic changes get unit tests before the implementation; UI changes
get at least a widget test for loading, empty, error and success.

After changing the Drift schema or any ARB string, regenerate and commit the
output — CI fails if it is stale:

```bash
powershell -ExecutionPolicy Bypass -File tool/generate.ps1
```
