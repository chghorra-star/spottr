# Spottr

Adaptive gym plans, plus a live form coach through the phone camera: it counts
reps, flags risky technique, and coaches out loud while you train.

All pose processing happens on the device. **Video never leaves the phone, and
nothing is uploaded.**

Spottr gives form feedback and flags movement that looks risky. It is not
medical advice and does not prevent injury.

## Status

M4 complete — the camera is wired up end to end. Native CameraX and ML Kit
own capture and inference, and the only thing that crosses the bridge is a
flat buffer of 33 landmarks. A camera check on every coached movement shows
the live preview with the tracked skeleton drawn over it and tells you where
to stand. 611 tests green, analyzer clean.

It counts nothing and judges nothing yet — rep counting is M5 and form rules
are M6 — and the screen says so rather than implying a coach that is not
there.

The parts worth knowing about: landmarks are smoothed by a one-euro filter,
whose cutoff rises with speed, so a planted ankle stops shimmering without a
dropping hip falling behind. The framing check is pure arithmetic over one
frame and names **one** thing to fix, because a setup screen listing four
complaints gets read as none of them. And mirroring the front lens happens
once, in Flutter, where the preview and the skeleton are flipped together —
a second flip on the native side would cancel it out and nothing would look
wrong until a form rule read a left knee on the right.

Before M4, M3 made the plan trainable: a day card starts a session, sets are
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
| M5 | Rep counting + accuracy harness | next |
| M6 | Form rules + scoring | |
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

The four pure-Dart engine packages must never import Flutter. That constraint
is what lets the entire rep-counting and form-analysis stack be tested from
recorded fixtures with no device attached.

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
