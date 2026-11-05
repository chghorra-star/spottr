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
rule thresholds, cue ordering, form scores — and, from M7, how often the
coach would have spoken, because nothing in the cue engine or the voice
reads a real clock.
**Cannot prove:** anything about the camera, the model, or performance.

This layer covers M1 through M3 entirely, the pose domain in M4 — the wire
codec, the smoothing filters, the framing check and the skeleton, all pure
and all driven from hand-written frames — and the whole of M5 and M6: the
rep counters, the form rules and the scoring are pure Dart and run under
`dart test` in milliseconds.
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

The report also says how much the coach would have talked over the suite,
which is the only way to find out whether it is chatty before somebody has
to train with it. That number is printed and not gated: what counts as too
much talking is a judgement about a person rather than about a threshold.

`tool/check.ps1` runs it, and a miscounted rep fails the build. The gate on
generated fixtures is 100 per cent: generated movement has one right answer,
so anything short of it is a regression in the state machine, the catalog
thresholds or the filter — not a tuning question.

From M6 the form rules are gated too, and **in both directions**. Every
fixture carries the rules that should fire on it, including the empty label.
A rule that does not fire on the fault it was written for is useless; a rule
that fires on a fixture nothing is wrong with will fire on every set anybody
ever performs, and that is the worse of the two, because from the outside a
coach that is always wrong is indistinguishable from a coach that is never
listening.

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

### And in M6, when the form rules arrived

Three more, all three invisible to the unit tests that covered the same
code:

- **Rules judged attempts the counter had already refused.** A depth rule
  fired on the two half-dips in `squat_six_of_eight` and a range rule fired
  on the rep in `squat_dropout_8` whose tracking was lost. They are faults
  about movement nobody completed.
- **A lockout rule could not pass.** It fired on all ten reps of
  `pushup_clean_10`, because a rep ends the instant the signal crosses back
  inside its tolerance band — up to eight degrees before the user has
  finished straightening their arms.
- **A travel bound written as `max - min` measured the noise.** It fired on
  `squat_noisy_8`, which is eight clean reps with jitter added. Over sixty
  noisy frames the two furthest-apart samples are, with high probability,
  the two worst landmark errors in the set.

The third has the same shape as the smoothing coefficient: a statistic that
is right on clean data and measures an artefact on real data, passing every
unit test either way. That shape has now come up twice, and both times what
caught it was replaying one movement under two conditions rather than
asserting a property of one.

The suite also settled a threshold rather than just checking one. Asked how
far the trunk-length ratio travels on every fixture, it answered eleven
points at worst where nothing rounds and twenty-plus where something does,
which is how `back_rounding` ended up at fifteen instead of the ten
somebody guessed.

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
- `expected.faults` is the same, for form: the rule ids that should fire,
  **and the empty list where none should**. Leaving it out says no rule
  should fire, so a fixture of good form needs nothing written down and a
  fixture demonstrating a fault needs the id of the rule it demonstrates.
  The format version went from 1 to 2 when this was added.
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

## Layer 1b — asking the suite what it actually constrains

M8 is the milestone where the thresholds were supposed to be tuned against
footage. There is no footage and there is no way to produce any on this
machine, so what M8 did instead was measure how much the evidence that does
exist is worth. Two commands, neither of them in CI, both of them slow and
worth reading rather than passing.

```bash
cd packages/harness
dart run bin/harness.dart --margins     # how far each number can move
dart run bin/harness.dart --robustness  # how much degradation counting survives
```

### Every number in the engine is a knob, and almost none of them are measured

`engineKnobs()` enumerates them: 78 numbers across the counters and the form
rules, each with an id, a value, a unit, and a function that rebuilds its
configuration with that number changed. Exactly one of them —
`back_rounding.max` — has ever been compared against anything. The other 77
were chosen by somebody being plausible about anatomy.

That ratio is the honest headline of this project's accuracy story, and the
knob list is what makes it countable rather than rhetorical.

### What `--margins` says, and what it does not

For every knob, the sweep nudges the number up and down a ladder of offsets
and asks whether every fixture that could notice still agrees with its label.
A ladder rather than a binary search, because nothing guarantees a threshold
breaks monotonically.

**28 of the 78 numbers can be changed without any fixture noticing**, 10 of
them because nothing in the suite exercises them at all.

That is not permission to change them. It is the measurement of how little
generated movement constrains a threshold: every fixture is built from the
same anatomy the thresholds were guessed from, so of course it agrees with
them. A wide margin means the suite is silent, not that the number is safe.

A narrow margin is the more interesting reading, and it comes in two kinds:

- **The fixture is marginal.** Three of them were: a piked plank five degrees
  from the band that was supposed to catch it, a leaning press five degrees
  from the bound, and a *clean* hinge two degrees from being flagged as not
  deep enough. All three were fixtures demonstrating something unconvincingly,
  and all three were widened. A fault fixture that only just trips its rule is
  testing arithmetic rather than detection.
- **The separation is genuinely narrow.** `back_rounding.max` has a window of
  roughly 13 to 20, which is exactly the gap M6 measured by hand between the
  artefacts and a real shortening trunk — found again here by a different
  mechanism. `squat_depth.max` sits two degrees above where a full-depth squat
  lands after smoothing, which is a real tightness and one only footage can
  settle.

### What `--robustness` says

Clean sets, degraded on purpose, to find where counting breaks. Three axes:

- **Landmark jitter**, independent per joint per frame: counting survives
  about 0.1 normalized units, which is a tenth of the image on every joint.
- **Correlated wander**, every joint drifting slowly: counting breaks at
  0.032 to 0.048 — roughly **three times more damaging than jitter of the
  same amplitude**.
- **Frame interval**: counting survives down to 750ms a frame, which is well
  under two frames a second.

The wander number is the one that matters. Real landmark error is correlated
in time — a model that has misplaced a knee goes on misplacing it — and
independent per-frame noise is precisely what a low-pass filter is built to
remove. A suite that only tested jitter would have been testing the smoothing
filter. The first version of this sweep did exactly that, ran out of ladder
without breaking anything, and measured nothing.

All three numbers are implausibly large, and the reason is the same one the
margins give: generated movement is a big, clean, smooth signal that is
trivially detectable under noise which would make a real skeleton
unrecognisable. **These are measurements of headroom on synthetic data, not
of accuracy.** The useful one is the ratio between them, not any of the
absolute values.

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

Builds run on a hosted macOS runner and ship to TestFlight for testing on the
iPhone.

**Proves:** real camera, real model, real fps, real lighting, real thermals —
the only layer whose performance numbers are quotable.
**Cost:** a 10 to 20 minute loop with no local debugger, which is painful for
threshold tuning. Tune against layer 1, verify on layer 3.

### What M9 built, and what has run

The iOS half of the plugin exists: AVFoundation capture, ML Kit pose
inference, the same flat Float32 buffer over the same two channels Android
uses. It is written to be read side by side with the Kotlin — same class
names, same callbacks, same error codes.

**None of it had been compiled** when it was written. There is no macOS here
and no Xcode, so every line of Swift in this repository is code that was
reasoned about and never once put in front of a compiler. The CI jobs added
in M9 are what does that, and since 4 November 2026 there is somewhere for
them to run: `github.com/chghorra-star/spottr`, public, so the macOS runners
are free rather than ten times the price.

What the first run found is at the end of this section. Until it finished,
the honest status of iOS was: written, unverified, and with a specific list
of what was most likely wrong — kept below, because the list is what the
run was a test of.
So the honest status of iOS is: written, unverified, and with a specific list
of things most likely to be wrong.

- **The landmark ordinal table.** Android gets BlazePose indices from ML Kit
  for free; on iOS the landmark type is a string constant, so
  `PoseLandmarkOrdinal` writes the order out by hand. A wrong constant name
  is a compile error — that is the good case, and the one CI catches. A
  duplicated or missing line is not, which is why `PoseLandmarkOrdinalTests`
  checks the table is thirty-three distinct entries. What neither catches is
  ML Kit having renamed something: `leftPinkyFinger`, `leftIndexFinger` and
  `leftToe` are the iOS spellings of Android's `LEFT_PINKY`, `LEFT_INDEX` and
  `LEFT_FOOT_INDEX`, and those three are the first thing to check against the
  installed headers.
- **Rotation.** iOS rotates at capture rather than at inference, so buffers
  arrive upright and the packer normalizes by the buffer's own dimensions.
  That is one fewer place for a transposed skeleton than Android has, but
  `videoRotationAngle` is iOS 17+ and the fallback path is the deprecated
  `videoOrientation`. Both are written; neither has run.
- **Mirroring.** The connection is explicitly *not* mirrored, because Flutter
  flips the preview and the overlay together. If AVFoundation mirrors as well
  the preview will look right and the landmark x axis will be reversed
  relative to Android, which is the failure mode that looks like nothing at
  all until a form rule reads it.
- **The texture.** Android pushes into a `SurfaceProducer`; iOS pulls through
  `FlutterTexture`, so `PreviewTexture` keeps exactly one frame behind a lock
  and hands it over on demand. Lifecycle bugs here show up as a frozen
  preview or a crash on stop, not as a wrong number.
- **The Podfile.** Committed rather than generated, because three of its
  lines are not the defaults: a deployment target of 15 for ML Kit,
  `use_frameworks!` for a Swift pod, and `ENABLE_TESTABILITY` so the test
  target can reach into the plugin without the plugin making its arithmetic
  public. The first `pod install` will be CI's.
- **The Xcode project.** A `.swift` file in a directory is not a file in a
  target: `project.pbxproj` lists them explicitly, in four places, and this
  one was edited by hand because there is no Xcode here to do it. Had it
  been missed, the test job would have compiled the test target without the
  tests in it and passed — which is the exact shape of silent nothing this
  project is arranged to avoid.

### Why ML Kit and not Apple Vision

Vision is already on the device, needs no pod, and would have been less work.
It reports nineteen joints where BlazePose reports thirty-three, and it has
no heel and no toe — so `heel_lift` would silently stop existing on iOS, and
every threshold in the coach engine would mean something slightly different
depending on which phone somebody was holding.

The whole architecture is built on the two platforms being
indistinguishable above `PoseSource`. A second model would make that false in
a way no test in this repository could see.

### What CI does now

`.github/workflows/ci.yml` grew three jobs in M9, and fixed one omission:

- **analyze-and-test** now runs the accuracy harness. It has gated
  `tool/check.ps1` since M5 and a stale comment in the workflow promised it
  would be wired in here; it now is, so a miscounted rep or a rule that
  disagrees with a fixture label fails the build on a push rather than only
  on somebody's laptop.
- **ios-build** compiles the app and links the plugin on `macos-latest`, with
  no signing, and separately compiles the XCTest target. Compiling the tests
  is its own step on purpose: that is what resolves the ordinal constants.
- **ios-test** runs the native tests on `macos-15-intel`. ML Kit's pods ship
  an arm64 device slice and an x86_64 simulator slice and nothing else, so an
  Apple Silicon runner cannot link a simulator build at all. That image is
  the last x86_64 macOS GitHub offers and it retires in Fall 2027, after
  which this has to move to a real device. The job originally asked for
  `macos-13`, which GitHub removed in December 2025; it would have queued and
  died on the image without compiling a line.
- **testflight** is manual and fails fast without its secrets. Shipping needs
  an Apple developer account, an App Store Connect API key, a certificate and
  a provisioning profile, none of which this project has. The pipeline is
  here so that the day it has them the answer is a button rather than a week.

**Testing the workflow before the first push found four reasons it could not
work**, of which the dead runner label was one. The others: `testflight` was
gated on `workflow_dispatch` while the workflow listened only for `push` and
`pull_request`, so it could never run and nothing would ever have said so;
the simulator destination named a model the image might not carry, which
goes stale silently in one direction and loudly in the other; and the
accuracy harness was the M9 gap itself. `packages/harness/test/workflow_test.dart`
pins all four, plus the rule that every gate in `tool/check.ps1` appears in
CI too. The runner labels are pinned with GitHub's removal dates, so the
pin fails here in a second rather than on a runner after a queue.

### What the first run found

Run 1, 4 November 2026. `analyze-and-test` green: the analyzer, 1038 tests,
the codegen-drift gate and the accuracy harness all pass on a clean Linux
checkout, which is the first time any of that has happened anywhere but one
laptop. `testflight` skipped, correctly — it is gated on a manual dispatch
and this was a push.

**Both macOS jobs failed, in the same place, before compiling anything.**
`pod install`:

    [!] The 'Pods-Runner' target has transitive dependencies that include
        statically linked binaries: (GoogleUtilitiesComponents)

ML Kit depends on GoogleUtilitiesComponents, which ships as a static binary.
The Podfile said `use_frameworks!`, which asks for dynamic linkage, and
CocoaPods refuses to mix the two at all. `use_frameworks! :linkage =>
:static` keeps the module maps a Swift pod needs and drops the dynamic
requirement ML Kit cannot meet. The M9 note in the Podfile — "`use_frameworks!`
is what a Swift pod needs" — was half right, which is the expensive kind.

So the honest result of run 1 is narrower than it looks: **no Swift was
compiled.** The failure is in dependency resolution, upstream of the
compiler, so every item in the list above — the ordinal table, the rotation
path, the mirroring, the texture lifecycle — is exactly as unverified as it
was before the push. What the run did prove is that the pipeline reaches the
Mac, which is the part that could not be tested from here at all.

It also surfaced a warning worth writing down: Flutter now reports that
`pose_camera` has no Swift Package Manager manifest and that this becomes an
error in a future version. `Package.swift` was deleted in M9 on purpose,
because ML Kit is CocoaPods-only and an SPM manifest beside a podspec means
the dependency vanishes the day somebody enables SPM. When Flutter makes SPM
mandatory, that decision has to be revisited rather than rediscovered.

### Run 2: the compiler, at last

The linkage fix got `pod install` through in twenty seconds, Xcode built for
thirty-nine, **and then the Swift compiler read the file for the first
time** and rejected it:

    Value of type '[Pose]' has no member 'landmarks'
      PoseCameraSession.swift:289
    Value of type 'Any' has no member 'type'
      PoseCameraSession.swift:290

A fifth platform difference, and one nothing on this machine could have
found. `PoseDetector.process` hands iOS an **array** of poses where it hands
Android a single `Pose`. The detector is configured for one person so the
array holds nought or one, and the Dart contract cannot express a second
body in any case — a frame is one set of thirty-three joints or none — so
the fix is `poses?.first?.landmarks`. The second error was the first one
cascading: with the type unresolved, the closure's parameter degraded to
`Any`.

That is what a compiler is for, and it is worth being precise about which
kinds of error it catches. A wrong landmark *constant* would have failed
here too. A landmark table that is complete, distinct and in the wrong
*order* compiles perfectly and ships a skeleton with its knees in its
elbows, which is why `PoseLandmarkOrdinalTests` exists and why it has still
never run.

The simulator job failed differently, further up: `Module 'flutter_tts' not
found`, from `GeneratedPluginRegistrant.m`. Static linkage drops the dynamic
requirement ML Kit cannot meet but does not bring module maps with it, and
the registrant is Objective-C reaching each plugin through `@import`, which
needs one. The common advice is to go back to dynamic frameworks; ML Kit
forbids that, so `use_modular_headers!` is the combination left. The Podfile
now carries three non-default lines and a test for each, and every one of
them was bought with a CI run.

### Run 3: the app builds

`Build iOS` passed. **The app compiled and linked on a Mac** — the plugin's
Swift, ML Kit, the generated registrant, the lot. That is the first time any
Swift in this repository has been accepted by a compiler, and it took three
runs and three configuration facts that no amount of reading could have
supplied.

It failed one step later, compiling the XCTest target:

    LandmarkPackerTests.swift:4: error: compiling for iOS 13.0, but module
    'pose_camera' has a minimum deployment target of 15.0

Two files declare the minimum iOS version and nothing reconciled them. The
Podfile says 15, which is ML Kit's floor; the Xcode project still said 13,
which is what the Flutter template generated. Objective-C's `@import`
tolerated the gap, so the app built; Swift's `import` does not, so the one
file that uses `@testable import pose_camera` did not. The project now says
15 in all three configurations, and a test reads both files and fails if
they ever disagree again — which they will, because the template regenerates
with its own default.

`ios-test` still fails before that, on the simulator build, with
`Module 'flutter_tts' not found` despite `use_modular_headers!`. That one is
deliberately left for the next run rather than fixed alongside: the
deployment-target mismatch is itself a candidate cause, and changing two
things at once would make the result unreadable. One change, one answer.

### Run 4: the native tests compile

`ios-build` green, both steps. The app builds, **and the XCTest target
compiles** — which is the step that resolves every landmark constant, so
`leftPinkyFinger`, `leftIndexFinger` and `leftToe` are the right ML Kit iOS
spellings and the ordinal table names thirty-three things that exist. That
was the single largest guess in M9 and it was correct.

It is worth being exact about what that does and does not settle. The
compiler has now agreed that the table's *names* are real. Whether they are
in the right *order* is a different question, and a table that is complete,
distinct and transposed compiles exactly as happily. Only
`PoseLandmarkOrdinalTests` can answer that, and it has still never run,
because the job that runs it has never got past building the app for a
simulator.

Run 4 also gave a clean negative: the deployment target was **not** behind
the `flutter_tts` error. Same failure, same place, with 15.0 everywhere.

What was behind it is the asymmetry that explains why only the simulator
ever failed. The Podfile excludes arm64 for the simulator on every pod,
because ML Kit has no slice for it — and nothing applied that exclusion to
the app project. So the Runner asked a simulator build for an arm64 slice
that was deliberately never built, and clang reports a module it cannot
find for the current architecture as simply missing. The device build has no
exclusion on either side, which is why it was green while the simulator was
red through three runs. The app project now carries the same exclusion, and
a test fails if the two files ever disagree.

### Runs 5 and 6: everything compiles

Run 5 gave a second clean negative — the missing arch exclusion was not
behind the `flutter_tts` error either — which was two wrong guesses in a row
at six minutes each, so run 6 changed the diagnostics instead of the code.

`ios-test` had been building the app twice: `flutter build ios --simulator`
compiled everything, and then `xcodebuild test` compiled it again. The first
build's only contributions were to fail first and to summarise the compiler,
so three runs produced the same single line with no clang invocation, no
search paths and no reason. That step now runs `--config-only`, which is
what it was for: resolve the pods, write `Generated.xcconfig`, stop.

Removing the duplicate build removed the error. **Everything compiles and
links, on both destinations** — the plugin's Swift, ML Kit, `flutter_tts`,
the generated registrant, the XCTest target. The "module not found" was an
artefact of two builds disagreeing about the same derived data, not a fact
about `flutter_tts`, which compiles with nothing worse than a Sendable
warning. Six runs to learn that the only thing wrong with the code was one
array, and the rest was the build asking itself the same question twice.

What is left is not a compile error at all:

    Runner (14727) encountered an error
    (Test runner never began executing tests after launching)

Thirteen minutes of waiting, then that. The app is the test host, it was
launched, and XCTest never got a connection back — which is the shape of a
host launched into a simulator that was still coming up, since xcodebuild
boots one implicitly and does not wait for it to be ready. The job now boots
the device itself and blocks on `simctl bootstatus -b`, so a slow boot costs
time instead of a test result and a failed boot says so in its own step.

So the ordinal table's *order* is still unverified, and it is the last thing
standing between "it compiles" and "it is right".

### Run 7: the tests run

Booting the simulator explicitly and waiting on `simctl bootstatus -b` was
the last thing in the way. `ios-test` green, and with it every job in the
workflow: the Dart suite and the accuracy harness on Linux, the app and the
XCTest target compiled for a device, and the native tests executed on a
simulator.

With one reservation, which is the reason run 8 exists. `** TEST SUCCEEDED
**` is also what xcodebuild prints for a test target containing no tests,
and the log shows no individual cases — xcodebuild stopped printing them by
default. This project has already shipped a test file that sat in the
RunnerTests directory without being in the Xcode target, which would have
produced exactly this: a green suite that ran nothing. So the job now writes
a result bundle, reads `totalTestCount` back out of it with `xcresulttool`,
prints the number, and fails if it is zero.

Until that number is in a log, the honest claim is that the native test
suite built and reported success, not that twelve assertions about the
landmark table were evaluated. A green tick is evidence of what it counted.

### Run 9: thirteen of thirteen

The whole pipeline is green, and the number is in the log:

    native tests: 13 passed of 13

With the device it ran on, which is worth reading too:

    "deviceName" : "iPhone 16 Pro",
    "architecture" : "x86_64",
    "osVersion" : "18.6",
    "platform" : "iOS Simulator"

x86_64, on the Intel image, exactly as the ML Kit constraint requires. That
reasoning was written down in M9 without any way to check it and it holds.

Honest accounting of the thirteen: nine are `LandmarkPackerTests` — the
buffer layout against the Dart contract, ordinal offsets, normalisation,
absent joints, landmark types outside the contract, non-mirroring,
confidence over all thirty-three rather than the reported ones, and the
quarter-turn transpose. Three are `PoseLandmarkOrdinalTests`. The
thirteenth is `testExample` from the Flutter template, which asserts
nothing; it is left in place as the target's own canary, and it means the
count to compare against is twelve.

**The ordinal table is now verified, order included.**
`testIndexesInBlazePoseOrder` ran and passed, which is the one thing a
compiler could never have told us: the table is thirty-three distinct
names, each at the index BlazePose puts it at, so the skeleton that reaches
Dart on iOS is the same skeleton Android sends. That was the largest
unverified assumption in the project and it is now a fact with a log behind
it.

### What nine runs cost, and bought

Nine runs. One real bug in the Swift — the array of poses — and one real
bug in the Dart-side tooling, the lint. Everything else was build
configuration: four workflow defects found before the first push, then
linkage, deployment target, arch exclusion, a duplicated build, a simulator
that was not ready, and two renamed `xcresulttool` subcommands.

That ratio is the honest result. The code was nearly right and the
configuration around it was wrong in seven different ways, none of which
this machine could have discovered, and each of which is now pinned by a
test that fails in a second rather than after a queue.

### The Kotlin tests still do not run

`LandmarkPackerTest.kt` covers the same arithmetic on Android and remains
outside CI, because a Gradle unit test needs an example app to host it and
the plugin has none. iOS got its equivalent for free: the Runner has a test
target already, and `LandmarkPackerTests.swift` lives in it.

So the asymmetry is now the other way round from how it looked in M4 — the
platform that cannot be built locally is the one whose native arithmetic has
a home in CI.

## Layer 4 — a server nobody here has

M10's code is all written and none of it has met Supabase. This is layer 3
again with the serial numbers filed off: a correct-looking artifact that
only runs on somebody else's machine, and nine CI runs' worth of recent
evidence about how that goes.

What *is* verified, with no project and no network:

- the protocol, in `packages/sync_engine` — 48 tests over conflicts,
  cursors, pagination, batching and every way a sync can stop half way
- the local store, against a real in-memory SQLite, including a walk over
  all seven syncable tables round-tripping a synthesised row
- the first migration, against a v1 database built from the schema snapshot
  that shipped
- `SupabaseRemoteStore`'s requests, against a fake HTTP client: the URL, the
  filters, the headers, the body and the mapping of every status code
- all three together, in `two_devices_test.dart`: two SQLite databases, the
  real engine, real PostgREST requests, and a stand-in server answering out
  of a map

What is **not** verified, and what will say so first:

1. **Whether the SQL parses.** `supabase/migrations/0001_init.sql` has never
   been executed. The `do $$ ... $$` block that applies row level security
   in a loop is the least conventional part of it and the most likely to
   fail outright, which is the good kind of failure: `supabase db push`
   either takes it or it does not.
2. **Whether PostgREST answers the way the fake does.** The cursor filter
   (`synced_seq=gt.N`), the ordering, the limit, and `Prefer:
   resolution=merge-duplicates` with `on_conflict=user_id,id` are all read
   from documentation. A wrong conflict target does not error — it inserts,
   fails the primary key, and rejects the batch.
3. **Whether a composite foreign key accepts a null child column.**
   `set_logs.plan_exercise_id` and `sessions.plan_day_id` are nullable
   halves of composite keys, which Postgres allows under MATCH SIMPLE. If
   that reading is wrong, every hand-logged set is a rejected row.
4. **Whether `nextval` is callable from the trigger.** The grant is there;
   whether it is the grant that matters is a guess.
5. **The first sync's volume.** A device with a year of training pushes
   every row it has, in batches of two hundred, and nothing here has
   measured what that costs on a phone connection.

The order to find all this out in: apply the migration, sign in on one
device, sync, read the `sync_state` table, then sign in on a second device
and sync. The first two steps answer 1 and 2; the third answers 3.

### What has no test on this machine

The keychain. `KeychainSessionStore` is a method channel, so a test here
answers with `MissingPluginException` — which is why the part that could
corrupt a sign-in, the encoding, is a class of its own with tests of its
own, and the store around it is twenty lines of glue. What is untested is
whether the platform hands the blob back after a restart, and whether
`first_unlock_this_device` behaves as documented when a phone is restored
from a backup.

`flutter_secure_storage` is also the first new pod since M9. It compiles in
CI or it does not, and that is one run to find out.

### What this layer already closed

Two things that were open when the protocol landed, now done and tested:
there is a sign-in, and `deviceId` is this installation's own id rather
than the constant `'local'` every install used to share. The second was the
one that mattered — the tie-break that makes last-writer-wins converge
cannot break anything if every device claims the same name — and
`bootstrap_test.dart` asserts a row written afterwards carries the real id.

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
unproven for the rest. The per-exercise table M8 promised is in the report
now: one row per exercise the app offers to coach, including the two nothing
has ever been measured on, and an acceptance-targets block that says
UNMEASURED where it is unmeasured. The table exists; the footage column is
empty for all nine.

**Where this stands after M8.** The harness exists, it gates CI on counting
and on form, it prints a per-exercise table rather than an aggregate, and it
can now say how much its own evidence is worth. What it still cannot do is
measure accuracy, because that needs footage.

- **Exercises:** seven of the nine camera-coached movements have a generated
  fixture. The two that do not are the goblet squat, whose geometry is the
  bodyweight squat's, and the forward lunge, which the generator cannot pose
  at all — it mirrors one leg chain, and a lunge is the one launch movement
  whose two legs do different things.
- **Rules:** seventeen of the twenty-one the catalog names are evaluated, and
  fifteen of those seventeen have a fixture built to trip them. The two that
  do not, lunge depth and torso lean, belong to the lunge. The four that are
  not evaluated at all are named on screen and in the report, with a sentence
  each saying what would have to change.
- **Thresholds:** seventy-eight numbers, one of them measured. Twenty-eight
  could be changed without any fixture noticing. See layer 1b above for what
  that does and does not mean.
- **Footage: still none.** Every number above comes from generated movement.
- **The voice has never been heard.** Text-to-speech works in a build and is
  exercised by tests through a fake speaker, but no audio has come out of a
  device in this project yet — the emulator has no working GPU to render the
  screen that would trigger it.
- **No Swift has ever been compiled.** The iOS half of the plugin was written
  in M9 and there is no macOS here to build it. See layer 3 for the specific
  list of what is most likely wrong.

So the honest claim today is that the engine is self-consistent on movement
of a known shape, including on movement built to contain a fault, and that is
all. The report is written so that no number in it can be quoted without that
sentence attached.

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
