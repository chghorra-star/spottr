# Spottr

Adaptive gym plans, plus a live form coach through the phone camera: it counts
reps, flags risky technique, and coaches out loud while you train.

All pose processing happens on the device. **Video never leaves the phone, and
nothing is uploaded.**

Spottr gives form feedback and flags movement that looks risky. It is not
medical advice and does not prevent injury.

## Status

M1 complete — a 54-exercise curated catalog with an integrity validator, and a
deterministic plan generator with scheduling, ranking, time budgeting, hybrid
run-day rules, and swap/reorder/move-day editing. 203 tests green, analyzer
clean. No UI yet: the engine is there, the screens are M2.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the design and
[docs/dev-loop.md](docs/dev-loop.md) for how to run and verify it.

| Milestone | Scope | State |
| --- | --- | --- |
| M0 | Scaffold and rails | done |
| M1 | Exercise library + plan generation | done |
| M2 | Onboarding, profile, plan UI | next |
| M3 | Workout logging + progression | |
| M4 | Pose plumbing, native bridge, overlay | |
| M5 | Rep counting + accuracy harness | |
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
