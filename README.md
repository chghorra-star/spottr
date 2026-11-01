# Spottr

Adaptive gym plans, plus a live form coach through the phone camera: it counts
reps, flags risky technique, and coaches out loud while you train.

All pose processing happens on the device. **Video never leaves the phone, and
nothing is uploaded.**

Spottr gives form feedback and flags movement that looks risky. It is not
medical advice and does not prevent injury.

## Status

M5 complete — it counts. One state machine, configured per exercise from a
table of thresholds, turns the landmark stream into reps: the coach screen
shows a live count, what became of the last attempt, and a tally of the ones
it did not count. A plank gets a clock instead, which stops when the hips
drop and keeps what it had. 764 tests green, analyzer clean.

It still judges no technique — that is M6 — and the screen says so rather
than implying a coach that is not there.

**Every attempt is accounted for.** A rep can be counted, counted with a
warning, or not counted, and each one carries the reason: too shallow to be
a rep, past the bar but short of depth, faster than the movement allows,
abandoned half way, or lost to tracking. A counter that silently ignores
what you just did reads as broken.

Alongside it, `packages/harness` replays labelled landmark fixtures through
the real pipeline and reports what was counted. It gates CI, and it found
two defects in its first run — one in how range of motion was measured, one
in a smoothing coefficient that was three orders of magnitude off for its
signal. What it cannot do is tell you the engine is accurate: every fixture
so far is generated, and the report says so every time it prints.

Before M5, M4 wired up the camera end to end: native CameraX and ML Kit own
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
| M6 | Form rules + scoring | next |
| M7 | Live coach UX, voice, safety | |
| M8 | Dataset validation and tuning | |
| M9 | iOS parity, cloud CI, TestFlight | |
| M10 | Supabase sync | |

## Layout

```
app/                    Flutter app
packages/pose_core/     pose primitives and geometry      [pure Dart]
packages/exercise_library/  curated exercise catalog      [pure Dart]
packages/coach_engine/  rep counting, form rules, cues    [pure Dart]
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
