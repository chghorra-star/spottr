# Development loop

Spottr is developed on Windows, with an iPhone and no Android handset. A
camera-based form coach cannot be developed against an emulator's synthetic
camera, and iOS cannot be built locally from Windows. So the loop is three
layers, each proving something different.

## Layer 1 — fixture replay (no camera, no device)

The default. `FakePoseCamera` replays a recorded or synthetic landmark
sequence through the real pipeline, so rep counters, form rules, scoring and
cue arbitration all run under `dart test` in milliseconds.

**Proves:** state machine correctness, hysteresis, partial-rep handling,
rule thresholds, cue ordering, form scores.
**Cannot prove:** anything about the camera, the model, or performance.

This layer covers M1 through M3 entirely, the pose domain in M4 — the wire
codec, the smoothing filters, the framing check and the skeleton, all pure
and all driven from hand-written frames — plus the logic half of M5 and M6.
From M4 on it also covers the camera stack above `PoseSource`, because
`FakePoseCamera` substitutes for the device at that seam and the widget
tests run the real smoothing and framing code underneath the screen.
### The accuracy harness is layer 1 with a number on it

From M5 this layer has a command of its own:

```bash
cd packages/harness
dart run bin/harness.dart              # the generated suite
dart run bin/harness.dart --json       # for a machine
dart run bin/harness.dart --no-smooth  # what the smoothing filter buys
dart run bin/harness.dart -f recorded/ # landmarks extracted from video
```

`tool/check.ps1` runs it, and a miscounted rep fails the build. The gate on
generated fixtures is 100 per cent: generated movement has one right answer,
so anything short of it is a regression in the state machine, the catalog
thresholds or the filter — not a tuning question.

**It replays the pipeline that ships**, smoothing included. A measurement
taken on a different pipeline than the one that ships measures something
that does not ship.

### What the harness found in its first run

Two defects, neither of which any unit test was going to notice, both now
fixed with tests of their own:

- **Range of motion was measured from the edge of the tolerance band**
  rather than from where the user was standing, so a full-depth squat
  reported 61 degrees of travel on 85 degrees of movement — and
  `minRangeOfMotion` meant something other than what it said.
- **The smoothing filter's speed coefficient was three orders of magnitude
  too small for its signal.** `beta` was a pixel-shaped number against
  landmark velocities measured in normalized image units, so the one-euro
  filter was a fixed 1.2Hz low-pass with an adaptive term that contributed
  about one per cent. It lagged a squat descent by four degrees of knee
  angle and a fast rep by thirty. Replaying one movement at two tempos is
  what made it visible.

The second one is worth remembering as a shape: every M4 smoothing test
passed, because they asserted that jitter is attenuated and that a step is
damped, and both were true of a filter that was not doing the thing it was
chosen for.

### Adding a recorded fixture

The format is one JSON file per set — `packages/harness/README.md` has the
shape. The parts that matter when writing one by hand or from an extractor:

- `landmarks` is `PoseFrameCodec`'s flat buffer, 33 joints in BlazePose
  ordinal order, four values each, `null` for a joint the model did not
  place.
- `source` must say `recorded`. The report counts synthetic and recorded
  fixtures separately and never averages them, and that field is what makes
  the difference.
- `expected` is the label, from somebody watching the video. It is not
  derived from the thresholds; a suite that agreed with the counter by
  construction would measure nothing.
- `notes` is for whatever explains a disagreement later: the clothing, the
  lighting, the fault being demonstrated.

Fixtures live outside the repository until there is a decision about size
and licensing. `dart run bin/harness.dart -f <dir>` takes a path.

### Widget tests do not touch the database

Two things make a widget test that waits on a real SQLite read a bad bet. A
widget test runs on a fake clock, which never advances the real asynchronous
work the read is waiting for; and `pumpAndSettle` cannot settle while an
indeterminate progress indicator is on screen, because it animates forever —
so a screen that is showing its loading state never settles.

So widget tests stub the two data streams and the controllers (see
`test/support/pump.dart` and `test/support/fakes.dart`) and assert what the
screen shows and what it asks for. The database path is covered by the
repository and controller tests, which are ordinary async tests against a real
in-memory SQLite and have none of these problems.

What this leaves genuinely untested is the construction of the on-device
database itself, which needs a real platform. That is integration territory
and belongs in Layer 2.

## Layer 2 — Android emulator with the host webcam

The emulator can expose a host camera as its back camera.

From Android Studio: **Device Manager → edit the AVD → Advanced Settings →
Back Camera → Webcam0**. Or from the command line:

```bash
emulator -avd rivo_pixel -camera-back webcam0
```

To feed a recorded clip rather than a live webcam, run OBS Studio with the clip
as a Media Source and start its Virtual Camera, which registers as a webcam the
emulator can select.

**Caveat worth knowing before you spend time on it:** the emulator enumerates
host cameras through DirectShow and does not always list virtual devices. If
`webcam0` turns out to be the physical camera and OBS never appears, the crude
fallback works fine — play the clip full-screen on a second monitor and point
the real webcam at it. Image quality is poor but landmark extraction is
surprisingly tolerant, and this layer is for plumbing, not accuracy.

**Proves:** the native bridge, camera permissions, frame delivery, the skeleton
overlay, the setup and framing screen, end-to-end wiring.
**Cannot prove:** frame rate, latency, thermal behaviour, or real-world
accuracy. Emulator fps is not representative of a mid-range phone and must
never be quoted as a result.

### What layer 2 actually proved in M4, and what it did not

Run on `rivo_pixel` with `hw.camera.back=webcam0` and the app driven through
`adb`, the camera check **did** show: the permission flow, CameraX opening
the camera, the preview arriving through a Flutter texture at the right
aspect ratio and the right way up, frames reaching Dart continuously, the
framing check reading them, the camera stopping when the app is backgrounded
and starting again on return.

It did **not** show a skeleton on a body, because the webcam was pointed at
a ceiling and nobody can be put in front of it from here. So the piece that
remains unverified on real hardware is the one with the most ways to be
quietly wrong: the joint-ordinal mapping, the normalization and the rotation
transpose in `LandmarkPacker`. Those are pinned by `LandmarkPackerTest.kt`
and, on the other side of the wire, by `pose_frame_codec_test.dart` — but a
test written by the same person who wrote the bug is not a device.

**The first time a real body goes through this path, check the skeleton
tracks the limbs it names.** A transposed frame still produces a plausible
figure; a left-right swap produces one that is exactly right until a form
rule reads it.

### Reading the pipeline from outside

In a debug build `PoseCameraSession` logs a frame count and a mean
confidence once a second:

```bash
adb logcat -s PoseCameraSession:D
```

This is the only window onto the native half, and it is what distinguishes
"an empty room" from "no frames at all" — which look identical on screen. It
is a count and a mean and never a landmark: a pose trace in the system log
would be a copy of somebody's body leaving the app, which is the one thing
this design promises not to do.

Running it that way on the emulator reported 3 to 6 fps with the confidence
at zero. The zero is correct for a ceiling. The fps is software rendering on
a machine with `hw.gpu.enabled=no` and means nothing about a phone.

### The native unit tests do not run

`LandmarkPackerTest.kt` covers the arithmetic that cannot be checked from
Dart. It is not in CI and not in `tool/check.ps1`, because a Gradle unit
test needs an example app to host it and this plugin has none.

Adding one is a real option and the cost is a second Gradle build in CI.
Until then the native half is verified by reading it, by the Dart side of
the contract, and by layer 2 — and the gap is exactly where the warning
above says to look.

## Layer 3 — iOS on real hardware via cloud macOS CI

Builds run on a hosted macOS runner (Codemagic or GitHub Actions macOS) and
ship to TestFlight for testing on the iPhone.

**Proves:** real camera, real model, real fps, real lighting, real thermals —
the only layer whose performance numbers are quotable.
**Cost:** a 10 to 20 minute loop with no local debugger, which is painful for
threshold tuning. Tune against layer 1, verify on layer 3.

This lands in M9. Until then, nothing about on-device performance is known.

## What the acceptance targets can honestly claim

The MVP targets rep accuracy >= 95% at the recommended angle and form warnings
firing on labeled faults with a low false-positive rate. Those are
measurements, and a measurement needs labeled footage.

The planned corpus is synthetic fixtures plus public datasets. That combination
has a known gap:

- **Synthetic fixtures** prove the engine is internally correct. They prove
  nothing about real-world accuracy, because they contain no real noise,
  occlusion, loose clothing, or tracking dropout.
- **Public datasets** (MM-Fit, Fit3D, InfiniteRep and similar) should cover
  squat, push-up, lunge and shoulder press reasonably. Expect poor to zero
  coverage of glute bridge, dumbbell Romanian deadlift, bent-over row and plank
  at our recommended angles, plus licensing review and a fault-taxonomy
  mismatch to reconcile against our rule ids.

So the target will be verifiable for roughly half the launch exercises and
unproven for the rest. M8 publishes a per-exercise accuracy table that states
plainly which exercises lack real footage rather than quoting one aggregate
number.

**Where this stands after M5.** The harness exists, it gates CI, and it
prints the coverage line every time it runs: four of the nine
camera-coached exercises have a generated fixture, and **none has footage of
a real body.** So the honest claim today is that the engine is
self-consistent on movement of a known shape, and that is all. The report is
written so that the number cannot be quoted without that sentence attached.

**The cheap way to close the gap**, if it becomes worth closing: layer 2
already requires exercise video to feed through the virtual camera. Those
clips are the corpus, and the only additional cost is labelling. What M5
built for that is the format and the runner — a fixture file carries its own
label and notes, and `--fixtures <dir>` replays a directory of them. There
is **no** labelling tool, no extractor and no video pipeline; an earlier
draft of this document promised one in M5 and it was not built. Turning an
mp4 into landmarks needs MediaPipe, which needs Python, which is not
installed on this machine.

Separately, the `DecisionLog` dump means every real set the app ever runs
produces a landmark trace that can be labelled after the fact, with no video
stored.

## Commands

```bash
# Resolve the whole workspace (always from the repo root)
flutter pub get

# Everything CI runs, locally
powershell -ExecutionPolicy Bypass -File tool/check.ps1

# Regenerate Drift and ARB output after a schema or string change
powershell -ExecutionPolicy Bypass -File tool/generate.ps1

# The accuracy harness on its own, with the report
cd packages/harness && dart run bin/harness.dart
```

Android builds need the Android Studio JDK:

```bash
JAVA_HOME="C:\Program Files\Android\Android Studio\jbr" flutter build apk --debug
```

## Known Windows build issue

This project lives on `D:` while the pub cache lives on `C:`. Kotlin's
incremental compiler cannot relativize paths across Windows drive roots and
fails with `this and base files have different roots`. Both
`app/android/gradle.properties` and
`packages/pose_camera/android/gradle.properties` set
`kotlin.incremental=false` to work around it. Do not remove those lines without
moving the project and the pub cache onto the same drive.
