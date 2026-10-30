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

This layer covers M1 through M3 entirely, plus the logic half of M5 and M6.

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

**The cheap way to close the gap**, if it becomes worth closing: layer 2
already requires exercise video to feed through the virtual camera. Those clips
are the corpus — the only additional cost is labeling, and the labeling tool is
built in M5 regardless. Separately, the `DecisionLog` dump means every real set
the app ever runs produces a landmark trace that can be labeled after the fact,
with no video stored.

## Commands

```bash
# Resolve the whole workspace (always from the repo root)
flutter pub get

# Everything CI runs, locally
powershell -ExecutionPolicy Bypass -File tool/check.ps1

# Regenerate Drift and ARB output after a schema or string change
powershell -ExecutionPolicy Bypass -File tool/generate.ps1
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
