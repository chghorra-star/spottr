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

## The camera bridge

Four things cross it, and only four: a permission question, a start, a stop,
and a stream of landmark frames.

Control calls go over a `MethodChannel` because they are request and reply.
Frames go over an `EventChannel` because they are a one-way firehose at
camera rate, and a method call per frame would pay for a reply nobody reads.

### The wire format is a flat float buffer

`PoseFrameCodec` owns it, in `pose_core`, not in the plugin — because there
are two senders. The native bridge emits it at camera rate, and the offline
video extractor writes the same shape into fixture files, which is what lets
the harness replay a recorded set with no Flutter anywhere in the picture.

Landmarks travel as **one `Float32List` of 33 x 4 values** — `x, y, z,
visibility` per joint, indexed by BlazePose ordinal. A map keyed by joint
name would be far friendlier to read and would also box 33 strings and 132
doubles thirty times a second; the flat buffer crosses as raw bytes.

A fixed-length buffer has to say "no landmark here" with a value rather than
an absence, and that value is `NaN` in the position. It is the only bit
pattern that cannot be mistaken for a place on the body — `(0, 0)` is the
top left corner of the image, and no rule could tell that apart from a
measurement.

Two details that look like paranoia and are not:

- **Visibility is clamped, not asserted.** Float32 rounding and ML Kit's own
  arithmetic both produce values a hair outside the documented `0..1`, and
  `Landmark` asserts on its range — so an unclamped decoder takes the whole
  stream down over a frame that is otherwise perfectly good.
- **A non-finite confidence is rejected outright.** Every threshold
  comparison against `NaN` is false, so a `NaN` confidence would quietly
  make "is this pose good enough" answer no forever instead of failing.

### Landmarks that cross the bridge are never mirrored

The front lens is *shown* mirrored, the way a gym mirror is. That is a
presentation decision and it is made once, in Flutter, where one
`Transform.flip` turns the preview and the skeleton over together so they
cannot come apart.

Mirroring on the native side as well would cancel the flip out, and nothing
would look wrong — until a form rule read a left knee on the right. So the
native side normalizes, rotates upright and sends; it flips nothing. No form
rule ever has to ask which lens it is reading.

### Normalizing by the rotated image, not the sensor

ML Kit returns landmark positions in the **upright** frame, so dividing by
the sensor's own width and height transposes the entire skeleton on a
portrait phone. `LandmarkPacker.uprightSize` swaps the two for a quarter
turn and the coach screen locks portrait, so there is one orientation to get
right rather than four.

## Smoothing is part of the pipeline, not of the camera

Raw landmarks wobble by a pixel or two on a body that is holding still. A
fixed low-pass has to choose between a steady ankle and a responsive hip,
and pose data needs both at once from the same stream — so the filter is a
**one-euro filter**, a low-pass whose cutoff rises with the speed of the
signal. It smooths hard when nothing is happening and gets out of the way
when it is.

It lives in `pose_core` and is applied once, in the provider between the
source and everything above it, because the overlay, the framing check and
the rep counter all want the same steadied signal rather than three
different ones.

It is applied **once**, to a broadcast stream, rather than per consumer: a
transformer builds a fresh filter per subscription, so two listeners would
otherwise run two filters started at different moments and disagree about
the same body for the first few frames — and the app and the accuracy
harness would be measuring differently filtered signals, which is the one
thing the harness exists to rule out.

Four decisions inside it:

- **It is driven by timestamps, not by sample count**, because frames drop
  and a filter that assumed 30Hz would smooth a gap as if it were movement.
- **The speed coefficient is in the units of the signal.** Landmarks are
  normalized image coordinates, where a hip dropping through a squat moves
  at a few tenths of a unit per second; the filter's published defaults are
  written for pixels, which move a thousand times faster for the same
  gesture. At the pixel-shaped value the adaptive term contributed about one
  per cent of the cutoff and this was a fixed low-pass wearing a costume —
  it lagged a squat descent by four degrees of knee angle and a fast rep by
  thirty. The accuracy harness found it by replaying one movement at two
  tempos.
- **A gap longer than 400ms resets it.** That is a dozen frames at 30Hz,
  well past anything merely skipped. Smoothing across it drags the skeleton
  in from wherever the user used to be standing.
- **Visibility gets a plain exponential average**, not the adaptive filter.
  Its wobble has nothing to do with how fast the body is moving, and an
  overlay that blinks a limb in and out reads as a bug even when the
  position underneath it is solid.

A joint the model stops reporting is **dropped, not held**. A held-over
position is invented data, and a limb resting where the tracker lost it
looks exactly like a measurement.

## Framing is a domain question, not a screen

`Framing.assess` is arithmetic over one frame: is there anybody there, is
any of them outside the frame, are they too far away, have they drifted to
one side. Pure, which is what lets the setup screen be built and tested
without a camera, and what will let the rep counter refuse to count at a
framing it cannot trust.

Two decisions worth not re-litigating:

- **The body box is measured from a fixed reference span — shoulders to
  ankles — never from the joints the caller asked for.** "Too far away" is a
  question about how large the person appears, and the answer cannot depend
  on which joints this exercise happens to care about. Measuring a press by
  shoulders and hips alone reports a well-placed phone as too far, every
  time. This was a real bug, caught by the test that passes a narrower
  required set.
- **The span is the longer dimension of the box, not its height**, because a
  plank is a body too. Upright it is the height; face down it is the width;
  one threshold has to mean the same thing for both.

The verdict carries every issue it found and names **one** of them as the
thing to say. A setup screen listing four complaints gets read as none of
them. The order is by how fundamental the problem is and then by how
actionable the fix is, which is why "step back" outranks "I cannot see your
ankles": when somebody stands too near the phone both are true, and only one
of them is an instruction.

Issues split into **blocked** (nobody there, out of frame, a needed joint
unseen) and **adjust** (too far, off centre). Too far is deliberately not a
refusal — everything needed is visible, just noisier than ideal, and
refusing to coach would be worse than coaching and saying so.

## `PoseSource` is the seam the camera stack is built on

```dart
abstract class PoseSource {
  Stream<PoseFrame> get frames;
  Future<CameraPermissionStatus> permissionStatus();
  Future<CameraPermissionStatus> requestPermission();
  Future<PoseSourceInfo> start({CameraLens lens});
  Future<void> stop();
  Future<void> dispose();
}
```

`DevicePoseCamera` runs a camera and a model. `FakePoseCamera` replays
frames a test wrote by hand or a fixture recorded earlier. Every layer above
— the overlay, the framing banner, and from M5 the rep counter and the form
rules — is written against this interface, so the widget tests substitute
the source and the real smoothing and framing code runs underneath them.

There is deliberately **no `PlatformInterface`**. That pattern exists so a
third party can supply another platform's implementation of a published
plugin. This plugin is private to one app and ships both platforms itself,
so the registration dance buys nothing, and the seam that is actually worth
having is this one.

`frames` is a broadcast stream, and the device source attaches to the native
channel on the first listener and stays attached until disposal. The
overlay, the framing banner and the rep counter all watch it at once;
detaching when the last listener left would tear the native subscription
down and rebuild it every time the UI rebuilt its watchers, dropping
whatever arrived in between.

One unreadable frame is an error on the stream, not the end of it. The set
carries on, and the alternative — an exception thrown out of a channel
callback — is an unhandled error with no clue which frame caused it.

### `PoseSourceInfo` comes back from `start`, not with every frame

An image size and a lens do not change thirty times a second, and a
`PoseFrame` carrying them would stop being a pose and start being a camera
reading — which the harness, replaying a fixture, has no business inventing.

### The preview is letterboxed, not cropped

A correctness decision rather than a cosmetic one. Landmarks arrive in
normalized image space, so the overlay maps them to pixels with a multiply —
but only while the box it draws in really is the image. Fill the screen with
`BoxFit.cover` and the box is a crop, every landmark needs the same crop
applied, and the day somebody changes the fit the skeleton silently slides
off the body. Letterboxing keeps the two in step by construction, and the
user needs to see the whole frame anyway to know whether they are in it.

The overlay is stacked inside that same aspect-ratio box, and both camera
use cases ask CameraX for the same aspect ratio, so the preview and the
analysis frames cannot disagree about the shape of the picture.

## The skeleton shows what is being measured

`Skeleton.bones` is domain data in `pose_core`, not a constant inside the
widget, because the offline labelling tool and the decision-log viewer draw
the same figure and three copies of the list would diverge. `Skeleton.joints`
is derived from it rather than listed again.

**It draws no face.** No form rule reads a face landmark, and a face mesh
over somebody's squat is decoration that makes the useful part harder to
read. The figure comes out headless, which turns out to be the honest
picture: it marks exactly the joints the coach is working from.

A skeleton is also the only honest answer to "is it working". A framing
verdict in words can be perfectly confident about a body it has mislocated.

## Dart decides when the camera runs

Native binds CameraX to a lifecycle it owns itself rather than to the
activity's, so starting and stopping is an explicit call from Dart. The
screen then stops the camera when it is disposed and when the app is
backgrounded — a camera left running behind another app is somebody's
battery and somebody's privacy, in that order of how quickly they notice.

The screen reads the source out of the container **once, in `initState`**,
and never through `ref` again. `dispose` has to stop the camera, and by then
reading a provider through that widget throws. That is the M3 lesson applied
before it cost anything: it passed every widget test there too.

### Permission has three answers, and the third is not asked for twice

`granted`, `denied`, and `permanentlyDenied` — the last one separate because
only the system settings can undo it, and a button offering to ask again
makes the app look broken rather than the setting look wrong.

`permissionStatus` never reports `permanentlyDenied`, deliberately. Telling
it apart from a plain refusal needs
`shouldShowRequestPermissionRationale`, which is **also false before the
user has ever been asked** — so reading it on a fresh install would send
somebody to the system settings to grant a permission they were never
offered. After an actual request the same signal is unambiguous. The cost is
one wasted tap for a user who already refused permanently, which is the
right way round.

### An unrecognised status is an error, not a refusal

If the native side answers with something Dart does not know, the two halves
of the bridge disagree. Failing closed would read as a permission problem
forever instead of as the version skew it is, so the decoder throws.

## The coach screen claims exactly what it does

The screen is still a setup screen first: where to put the phone, and
whether it can see you. From M5 it counts and from M6 it judges, and it says
both — and says what it is still not doing. Three claims, all pinned by
test.

The standing one: Spottr flags risky movement, cannot see everything, and
cannot guarantee you will not get hurt.

The M6 one, which replaced M5's line about not judging technique: these form
checks have not been measured against real training footage. That is still
true of every rule but one, and it is the sentence that has to go the day it
stops being true.

And the one the screen computes rather than states: the rules it is **not**
watching, by name. A coach that says nothing about somebody's knees is
making a claim, and from the side it cannot see them fall inwards at all.

Knowing where to stand the phone was worth a screen on its own even before
anything counted. Getting it wrong is the most likely reason the coach would
appear not to work at all.

## Rep counting

One state machine, configured per exercise:

```
idle -> top -> descending -> bottom -> ascending -> (rep) -> top
```

Everything the machine knows about an exercise arrives as a
`RepCounterConfig`: which signal to watch, which way it moves, where the two
ends of the movement are, and the tolerances that decide what counts. Tuning
a squat is an edit to one table; adding a ninth camera exercise is a new
entry in it. `counterCatalog` holds the launch set, keyed by the
`repCounterId` a catalog entry already carries.

A plank gets a `HoldCounter` instead, which accumulates time in a posture
rather than looking for a cycle, because a plank is not a rep count with the
numbers changed.

### A signal is configuration, not code

Both counters read `PoseSignal`, of which there are two kinds: `JointAngle`
(the angle at a joint — a knee, an elbow, a hip) and `SegmentTilt` (the
angle of a segment from vertical). Each is **measured on both sides of the
body and averaged over whichever sides are tracked**, because from the side
view the far limb is behind the near one and which of the two the model
reports is not something a config can predict. That averaging is right for
the launch set because every camera-coached movement in it is bilaterally
synchronous; a genuinely one-sided movement would have to name its side.

A signal that cannot be measured returns `null`, never zero. A counter has
to be able to tell a knee it cannot see from a knee that is folded shut.

### Direction is a config, not two state machines

A squat's knee angle gets *smaller* as the rep is performed; a glute
bridge's hip angle and a press's elbow angle get *larger*. Rather than two
machines or a pile of comparisons that flip, the config declares its
direction and the machine works in **depth**: zero at the top of the rep,
`fullRange` at the bottom, whichever way the underlying angle moved. There
is one set of comparisons above it, and `validateCounters` rejects a config
whose thresholds and direction disagree — a mistake that would otherwise
open a camera, draw a skeleton and count nothing for ever, which looks
exactly like a model that cannot see the user.

### It will not count a rep it joined half way through

From `idle` the machine waits to see the top before it will open an attempt.
The set starts when the user taps start, which is not the same moment they
are standing up, and a machine that treated its first frame as the top would
hand a free rep to anybody who began mid-squat.

### Range of motion is measured from where the user was standing

`rangeOfMotion` is travel from the deepest point they *rested* at, not from
the threshold and not from the last frame that happened to be inside the
tolerance band. Measuring from the band loses everything inside it —
systematically, about twenty-four degrees on a squat — which makes
`minRangeOfMotion` mean something other than what it says and drags the
shallow-rep boundary in with it. Position therefore comes from the deepest
frame of the current stay at the top and time comes from the last one, which
are deliberately different frames: dawdling at the top is not part of the
rep, but standing up straight is where the rep started from.

This was a real bug, and the accuracy harness is what found it: a generated
set of full-depth squats reported sixty-one degrees of travel on
eighty-five degrees of movement.

### Rejected reps are surfaced, never swallowed

A counter that silently ignores a rep reads as broken. Every attempt lands in
one of three outcomes — `counted`, `countedWithWarning`, `notCounted` — and
carries the reason: `shallow` (past the acceptance bar, short of depth),
`partialRange`, `tooFast`, `timedOut` (abandoned part way through), or
`lostTracking`. The ledger keeps them all, in order, with no gaps in the
numbering, and the screen shows the last verdict and a tally of the rest.

The order the checks run in matters. Range is tested before speed, because a
quick shallow dip is better explained by how far it went than by how long it
took: "go deeper" is an instruction and "that was too fast" is a riddle.

### Nothing is held across a gap it would have to guess across

A signal that goes missing mid-rep for longer than `maxTrackingGap` — the
same 400ms the smoothing filter resets after — abandons the attempt with
`lostTracking` rather than resuming as though the body had been where it was
left. Shorter gaps are ridden out. A hold's clock only ever accumulates the
interval between two frames that were both in position, so a break costs
exactly the time it lasted and nothing that was already banked.

### A tick carries both the edge and the standing value

`RepTick.completed` is set on the single frame an attempt finished, for
anything that sees every tick: the cue engine in M7, a logger, the harness.
`RepTick.last` is the same event on that frame and every frame after it, for
anything that reads only the newest tick — which is what a screen does. The
camera produces frames faster than the UI redraws, so an edge-only report is
a verdict the user never sees, and holding it in the widget instead would
lose it the same way, because the dropped frame never reaches the widget at
all. That was the second thing M5 got wrong first.

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

### Framing and counting are separate judgements

The counter does not consult the framing check. It needs its own signal
joints and nothing more, and somebody standing a little too far away is
still training — a counter that stopped would look broken rather than
careful. The framing bar says what to fix; the count keeps running.

## The accuracy harness

`packages/harness` replays labelled landmark fixtures through the real
pipeline and reports what was counted. It is a command, it gates CI, and it
is the reason the engine is pure Dart: no Flutter, no camera, no device.

```bash
dart run harness                        # the generated suite
dart run harness --fixtures recorded/   # landmarks extracted from video
dart run harness --no-smooth            # what the filter contributes
```

### It replays the pipeline that ships

The same smoothing filter the app applies runs inside `replay`. This is not
a nicety: a measurement taken on a different pipeline than the one that ships
is a measurement of something that does not ship. The app feeds every
consumer from one broadcast, once-smoothed stream for the same reason.

The `--no-smooth` switch exists to make the filter's contribution visible
rather than assumed, and the answer is not a tidier overlay: unsmoothed, the
noisy fixture opens a ninth attempt that never happened and reports ranges of
29 and 60 degrees on 85-degree reps.

### The label is the author's, not the counter's

A fixture states what should have been counted. Deriving that from the
thresholds would make the suite agree with the engine by construction and
measure nothing.

### Fixtures are `PoseFrameCodec`, on disk

One JSON file per set: the exercise id, the camera angle, where the
landmarks came from, free-text notes, the label, and frames in the codec's
flat 33-joint buffer. JSON has no `NaN`, so a joint the model did not place
is `null` — the same meaning as `absent` on the wire, because a format that
cannot say "nothing here" cannot record a set where a limb left the frame,
which is most of the sets worth recording.

The suite is **generated rather than stored**. Committing it would be
megabytes of float arrays nobody can review; the cases are the reviewable
part. `SideOnPose` describes a body by the tilt of each segment, so a pose
reads as "the knee is bent to 95 degrees" rather than as a dozen
coordinates, and interpolating between two poses bends a limb where
interpolating positions would stretch it. One small fixture is committed as
a file so the reader is tested against a file on disk rather than against
the writer that produced it.

### What a passing run proves, and what it does not

It proves the state machine, the catalog thresholds and the smoothing filter
agree with each other about movement of a known shape — including the cases
a counter gets wrong: noise on every joint, reps that stop half way, a set
bounced faster than the movement allows, a rep the tracker loses in the
middle, a pause at the bottom, and a hold that breaks.

It proves **nothing about a real body.** There is no clothing in a generated
fixture, no occlusion, no model error and no camera. So the report never
prints one accuracy figure over fixtures of different kinds, and it always
says how many exercises have footage of a real body, which is currently
none. The synthetic gate is 100 per cent — generated movement has one right
answer, so anything else is a regression — and the recorded gate is the
MVP's 95 per cent acceptance target, which applies the day there is footage
to apply it to.

### The harness has already earned its keep

Two defects, in its first run, neither of which any unit test was going to
notice:

- **Range of motion was measured from the edge of the tolerance band**, so
  every rep under-reported its travel by the width of the band plus whatever
  the user was standing above the threshold.
- **The smoothing filter's speed coefficient was three orders of magnitude
  too small for its signal.** `beta` was 0.05 against landmark velocities of
  a few tenths of a normalized unit per second, so the adaptive term
  contributed about one per cent of the cutoff and the one-euro filter was a
  fixed 1.2Hz low-pass wearing a costume. It lagged a squat descent by four
  degrees of knee angle and a fast rep by thirty. Replaying the same
  movement at two tempos is what made that visible, and nothing in the M4
  tests could have: they asserted that jitter is attenuated and that a step
  is damped, both of which were true.

## Form rules

A rule is an id, a severity, a signal and a number. Tuning one is an edit to
`formCatalog`, not a change to anything that runs, and the id is the one the
exercise catalog already names in `camera.formRuleIds` — so an exercise's
rules are curation and the engine never learns a movement's name.

```dart
sealed class FormRule {
  String get id;
  RuleSeverity get severity;
  Set<PoseSignal> get signals;
  RuleOutcome evaluate(RuleWindow window);
}
```

Five shapes cover the launch set. A **bound** is one sample at one point in
the rep inside a limit — depth at the bottom, a lockout at the top; a
**band** is a signal that has to stay inside a range for the whole window —
a plank's hips, a lunge's torso; a **travel** bound is how far a signal may
move across the window, which is the complement of a band: a row's torso may
be at any angle the user likes, and what makes it a fault is that the angle
keeps changing. The last two read the rep rather than the pose: **range
consistency** against the user's own best rep in this set, and **descent
share**, how much of the rep was spent on the way in.

### Two rules read the user instead of a threshold

`rom` and `tempo` are worth singling out because they need no number in
degrees, and therefore need no footage before they can be trusted.

`rom` compares this rep with the longest one the user managed earlier in the
same set. Range shrinking across a set is what fatigue looks like, and it is
the one form fault that is unambiguous without knowing anything about the
exercise or the body performing it. `tempo` is a share and not a stopwatch:
"three seconds down" is a different instruction for a sprinter and for
somebody on their eleventh rep, and "do not drop into it" is the same
instruction for both.

Every other threshold in the table is a plausible guess, and the file says so
where somebody tuning them will read it.

### Four outcomes, because "I did not check" is not "that was fine"

`pass`, `fail`, `notVisible`, `notImplemented`. A verdict records what it
could not evaluate as carefully as what failed, and carries three separate
reasons for silence: the signal was not tracked for enough of the window, the
camera angle cannot see that rule at all, or the engine does not evaluate it
yet.

A rep where nothing could be checked scores `null` rather than 100. A set run
with the phone face down would otherwise come out perfect, and `Progression`
already treats a missing form score as no objection rather than as approval.

### The rules do not judge an attempt the counter refused

A rep that was not a rep did not happen. Measuring how deep somebody got into
a movement they abandoned half way produces faults about a movement they
never made — the accuracy harness found exactly that, as a depth rule firing
on the two half-dips in `squat_six_of_eight` and a range rule firing on the
rep whose tracking was lost. The counter's own reason is the whole verdict for
those.

### The rest at the top of a rep belongs to the rep

The counter ends a rep the instant the signal crosses back inside its
tolerance band, which is up to a whole hysteresis before the user has
finished standing up. A lockout rule reading the final frame of a rep would
therefore mark everybody down by eight degrees, and did: it fired on all ten
reps of `pushup_clean_10`.

So a rep's window carries the last second of rest at the top, and the
analyzer tells the window which frame in it was the most extended. One
second, not all of it — somebody who racks the weight and reads their phone
has not performed a two-minute rep.

### Nothing a rule says cancels a rep

Severity decides what happens, and the scale has three levels: a **minor** is
worth saying once, a **major** is worth saying every time, and an **unsafe**
means the coach says to stop the set and take weight off.

None of them refuses the rep. An earlier note in the theme file said an
unsafe rep would not be counted, and that is the one thing this engine must
not do: every threshold behind every rule is still a guess, and deleting work
somebody actually did on the strength of an unvalidated proxy is the failure
mode that makes a coach impossible to trust. Counting the rep and saying
plainly that it looked unsafe costs nothing if the rule turns out to be
wrong.

### The score is anchored to the progression table, not to feel

`Progression` asks two questions of a set's mean form score: is it at or
above `formCeiling`, which earns more weight, and is it below `formFloor`,
which takes weight off after a second session. The penalties are chosen so
that three sentences come out true:

- a minor on every rep still earns weight, because a coaching point is not a
  reason to stall somebody's training;
- a major on every rep holds the weight where it is, which is what "the cue
  fires every time and the rep still counts" means;
- an unsafe on every rep takes weight off.

The penalties live in `coach_engine` and the bands live in `plan_engine`, and
the two packages do not know about each other. `app/test/domain/form_score_test.dart`
is the only place they can be checked against one another, and it is the test
that fails if either is tuned without the other.

### No single angle sees everything

Depth and spinal position need the side view; left-right symmetry such as
knee valgus needs the front. So a camera config names every rule the exercise
has and says which ones each acceptable angle cannot evaluate. The invariants
the catalog validator enforces are therefore *not* "the recommended angle
supports every rule" — that is impossible — but:

- the recommended angle evaluates at least as many rules as any other
  acceptable angle, since it is what the setup screen asks the user for, and
- no rule is disabled at every acceptable angle, which would mean it can never
  fire.

This was corrected during M1: the original invariant was unsatisfiable by any
real exercise, and writing the catalog is what exposed it.

### Rules the engine names and does not evaluate

Four of the twenty-one are a `PendingRule`: an entry in the table that always
answers `notImplemented` and carries a sentence saying what has to change.
Entries rather than absences, because a missing id would make the catalog look
complete and the coach look thorough. They are counted by the validator,
printed by the harness report, and named on screen as things Spottr is not
watching.

Three of them — knee valgus, elbow flare, elbow path — need the front view,
where the joint travels across the camera instead of along it, and there is no
front-view fixture generator to test them against. The fourth, knee travel,
needs something more interesting: a signal that can name a side. Every
`PoseSignal` averages the two, which is right for the seven symmetrical launch
movements and wrong for a lunge, where one shin leans forwards and the other
leans back and the mean of the two is a number about nobody. M5's note about
bilateral averaging said a one-sided movement would have to name its side; the
lunge is the exercise that needs it, and it is also why the fixture generator
has no lunge in it.

### The spine is not visible, and its proxy is the rule most likely to be wrong

There is no landmark between the shoulders and the hips, so the trunk is a
straight line by construction and a rounded back cannot be seen directly. What
can be seen is the line getting shorter, measured against a bone whose length
does not change — the thigh. That ratio is `back_rounding`, the only `unsafe`
rule in the table, and it is a proxy with three known artefacts that shorten a
trunk without anybody's back moving: landmark jitter, a limb moving fast
enough for the one-euro filter to lag, and the fact that smoothing each
landmark on its own does not preserve the distance between two of them.
Rotating towards the camera does it too, and no fixture here can show that.

Its threshold is the one number in the file that is not a guess. The harness
was asked how far the ratio travels on every fixture in the suite: the ones
where nothing rounds reach eleven points at worst, and the two built with a
shortening trunk reach twenty and twenty-three. Fifteen sits between them with
four points of margin either side.

That is still a measurement about generated movement, so pairing the most
fragile signal in the engine with the only severity that interrupts a set is
deliberately uncomfortable — and it is why M7's cue arbitration has to make it
fire twice running before saying anything out loud.

### A sag and a pike are the same angle

A plank whose hips have dropped and a plank whose hips are in the air give the
hip the same angle: 180 minus the same number, whichever way it went. The only
thing that separates them is which side of the shoulder-to-knee line the hip
fell to, and that needs a signed perpendicular offset.

`perpendicularOffset` signs itself against gravity rather than against the
order of its arguments, so it reads the same whichever way the body is facing.
It returns nothing when the reference line is within fifteen degrees of
vertical, because "below the line" is not a sentence about a standing body and
a sign that flips with a wobble is worse than no reading. That is also why
knee valgus from the front cannot use it: there the reference line *is*
vertical.

### What the harness found this time

Three defects, in the order it found them, all fixed with tests of their own:

- **Rules judged attempts the counter had already refused**, inventing depth
  and range faults on movement nobody completed.
- **A lockout rule could not pass**, because the frame a rep ends on is not
  the frame the user is most extended in.
- **A travel bound written as `max - min` measured the noise.** Over sixty
  noisy frames the two furthest-apart samples are, with high probability, the
  two worst landmark errors in the set. It now reads the spread between the
  5th and 95th percentile, which on a short window degenerates to `max - min`
  — where there is nothing to trim, trimming nothing is right.

The third is the same shape as M5's smoothing-coefficient bug: a statistic
that is correct on clean data and measures an artefact on real data, passing
every unit test either way. It is worth noticing that this shape has now come
up twice, and that both times the thing that caught it was replaying the same
movement under two conditions rather than asserting a property of one.

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
  -> WeekTemplate         fullBody x2-3 | upperLower x4 | ppl+UL x5 | ppl x6
  -> viability check      fall back to full-body if a split would leave a day
                          without compound work
  -> weekday assignment   classic spread, shifted off run days, rotated to keep
                          leg work away from pre-run slots
  -> SlotSpec per day     {pattern, targetMuscle?, priority, sets}
  -> filter candidates    equipment available, difficulty <= level,
                          no contraindication against a declared injury
  -> rank                 difficulty fit, then camera support, then equipment
                          use, then variety
  -> fit to time budget   trim optional, then accessory, then set counts
  -> fill the time budget grow sets, compounds first, up to the caps
```

Generation is a pure function of the request and the catalog. No randomness, no
clock, no I/O, and ranking ties break on exercise id, so the same request always
produces the same plan — which is what makes the golden tests meaningful.

**Difficulty is a hard gate at or below the user's level**, not level+1.
Offering an advanced movement to a beginner is how people get hurt, and the
catalog carries enough beginner work in every pattern that bodyweight training
can cover.

### Ranking weights

Scores are additive and the constants are the policy, so they live together in
`PlanGenerator` where they can be read side by side:

| Factor | Weight | Why |
| --- | --- | --- |
| Difficulty step (primary slot) | 200 | Appropriate loading dominates everything |
| Difficulty step (accessory slot) | 0 | Nobody needs an advanced calf raise |
| Camera support | 200 | Worth exactly one level of progression |
| Each piece of equipment used | 10 | A gym member should not get bodyweight squats |
| Used earlier this week | −3 | Variety breaks ties only |
| Used recently | −5 | Variety breaks ties only |

Two of these came directly out of reviewing the golden output. Variety was
originally weighted at −40 and was downgrading a dumbbell owner to bodyweight
squats mid-week; the brief lists variety as the *last* criterion, so it now only
breaks ties. And difficulty applied to accessory slots was costing gym users
their camera-coached plank in favour of a hanging knee raise, which is why
accessory slots ignore difficulty entirely.

### Session length shapes the plan, it does not only cap it

A template describes the **longest sensible version** of its session. The time
budget decides how much of it the user actually gets, in both directions: a
short session gives work up, a long one grows into the time available.

Slots carry a priority, and it is the order things are given up in:

| Priority | Trimmed | Explained | Max sets |
| --- | --- | --- | --- |
| `primary` | last | yes | 5 |
| `accessory` | second | yes | 4 |
| `optional` | first | **no** | 3 |

Optional work is silent in both directions — a slot the catalog cannot fill,
or one the budget leaves out, says nothing, because its absence is the system
working rather than news. It also does not fall back to another muscle when
its own has nothing available; that fallback is what would put calf raises on
a push day.

Filling adds sets one at a time, compound work first, cycling through the
exercises so volume spreads rather than piling onto whichever lift happens to
be listed first. Two caps stop "use the time available" becoming junk volume:
the per-slot maximum above, and **32 working sets for the session**. The per
slot caps alone do not bound it — a nine-exercise gym day reaches all of them
at thirty-seven sets, which is a worse session, not a longer one. Optional
slots start at two sets for the same reason: starting full they spent the
budget before the compounds had theirs, leaving the squat on three sets and
the lateral raise on three.

Everything derives from `templateSets` and the budget, which is what keeps it
idempotent — a plan edit re-applies these rules, and an already-filled day
must come back unchanged rather than inflating a little more each time.

The estimate they work against includes a flat **60 seconds per exercise** for
getting set up. Without it the estimate is pure set arithmetic, which is how a
session billed as thirty minutes came to closer to forty in the gym; filling a
budget against a dishonest estimate would only have made that worse.

When a week still falls well short — bodyweight at home tops out near
forty-five minutes whatever the user asks for — a single
`sessionShorterThanBudget` note says so. Telling someone their hour produced
forty minutes of work is better than quietly handing them a short session, and
far better than padding it with volume that would not help.

This whole mechanism exists because the measurement was embarrassing: before
it, requests for 45, 60, 75 and 90 minutes produced **byte-identical weeks**.

### When a split is the wrong prescription

A split dedicates whole days to one pattern group, which assumes the user can
train that group. A bodyweight-only user has no pulling exercise at all, and a
user with wrist and shoulder injuries may have no available pressing movement —
either way the split hands them a day with no compound work in it.

So before scheduling, each day of the intended template is checked: if removing
the patterns this user cannot train would leave fewer than two primary slots,
the split is abandoned for full-body days and a `templateSimplified` note
records which patterns forced it. A split missing one pattern out of four is
fine and is simply noted; a split with a collapsed day is not.

This was found by the property tests, not by reasoning — see Testing below.

### Hybrid goal

Run days are marked and training is kept off them wherever the week has room; a
session only shares a day with a run when every other day is taken, which is
the honest outcome for six gym days and three runs.

Leg work is kept away from runs by two mechanisms. First, the template's day
order is **rotated** to put leg-heavy days on slots that are not the night
before a run — rotation rather than free reordering, so upper/lower alternation
can never collapse into two lower days back to back. Second, where placement
cannot avoid it, leg work is capped at two sets and a `legVolumeReducedForRun`
note explains why. The brief asks to avoid *heavy* leg work, not to skip legs,
so volume comes down rather than the session losing its purpose.

**What counts as leg work is a question for the catalog, not the slot.** The
rule originally capped leg-dominant *compound* slots, which was enough until
sessions started growing into their budget: the freed time then went on leg
extensions and calf raises, which fatigue the quads and calves more than the
squat sets that had just been removed. A leg extension fills an *isolation*
slot, so the slot cannot answer this — `DayRules` takes the catalog and asks
whether the exercise's primary muscles are leg muscles. That turns three
capped movements on a leg day into six, which is why the note is one per day
rather than one per exercise.

This was found by reviewing a regenerated golden file, not by a failing test.

Running output is a text suggestion keyed to experience. Spottr does not track
runs.

### Plan notes

The generator reports its own compromises rather than hiding them:
`unfilledSlot`, `templateSimplified`, `legVolumeReducedForRun`,
`trimmedForTime`, `dayUnderfilled`, `sessionShorterThanBudget`. Each carries a
machine-readable detail and an optional weekday, and the UI maps the kind to
prose. A short session should look explained, not broken.

The restraint matters as much as the reporting. Optional work says nothing
when it is dropped, the leg cap speaks once per day rather than once per
movement, and the shortfall note is emitted once for the week. A screen full
of notes explains nothing — it just looks broken in a more detailed way.

## Plan edits

Swap, reorder and move-day are pure functions returning a new plan.

The prescription rules — the pre-run leg cap and the time-budget trim — live in
`DayRules`, shared by the generator and every edit, so an edited plan is
indistinguishable from a generated one. They derive from
`PlannedExercise.templateSets` rather than the current set count, which makes
them idempotent and means a day moved onto the night before a run loses leg
volume while a day moved clear of one gets it back.

A swap is re-prescribed from scratch rather than inheriting the old targets,
because swapping a rep-counted exercise for a hold has to turn reps into
seconds. Swaps are validated against the same hard constraints as generation,
so a swap can never reintroduce something contraindicated.

Reordering deliberately does *not* re-apply the day rules: a day the user
trimmed by hand should not spring back to full volume because they dragged a
row.

## Progression

```
ProgressionInput{planned, completed(reps|seconds, weight, formScore),
                 sessionRating, painReported, priorLowFormSessions}
  -> ProgressionDecision{change, reason, nextWeight|nextReps|nextHold|nextExercise}
```

A decision table, read top to bottom, and the order of the branches is the
whole design:

| # | Condition | Decision |
| --- | --- | --- |
| 1 | pain reported | hold everything |
| 2 | fewer sets logged than prescribed | hold |
| 3 | mean form below 70, second session running | cut load 10%, or drop to the easier variant |
| 4 | mean form below 70, first time | hold, and say it was noticed |
| 5 | rated too hard | cut load 5% |
| 6 | any set short of the rep floor | cut load 5% |
| 7 | every set at the top of range, form 85+ or unjudged | add load, reps, or seconds |
| 8 | anything else | hold |

Safety outranks evidence, and evidence quality outranks ambition: a session
that looked perfect earns nothing if the pain button was pressed, and a
session that was not finished is not evidence about the weight at all.

**Progression owns intensity; the time budget owns volume.** There is
deliberately no `nextSets`. If progression could add a set it would quietly
push a session past the length the user asked for, which is the thing the
budget work in M2 existed to stop. So applying a decision does *not* re-run
`DayRules` either — re-running them could trim away the very exercise
progression just advanced, or spend the freed time on something else. The cost
is that a variant with a different tempo can move a session estimate by a
minute; a progression that deleted work to stay on budget would be far worse.

**A logged weight is what makes load the dial, not the catalog.** A push-up in
a weight vest progresses by load; the same exercise logged bare progresses by
reps, and then by the catalog's harder variant once reps stop being useful
around twenty. Asking the catalog whether an exercise is "weighted" would get
one of those two wrong.

**No form score is not a bad form score.** Every set logged by hand has a null
`formScore`, and that is every set until the camera lands in M5. Progression
treats absent form as no objection rather than as failure — a streak counter
that read "no data" as "bad form" would deload the entire app on its first
release. `priorLowFormSessions` is computed from finished sessions and is
therefore zero for everybody today, which the repository has a test for.

**A progression target the user cannot use is not a progression.** Variant
candidates are filtered by equipment, injuries and — climbing only — level,
so a home user who maxes out knee push-ups is offered push-ups rather than a
barbell bench press. Crossing between reps and seconds is refused outright:
a ladder that did would silently rewrite the prescription's units.

Every decision carries a `reason`, which is a **value, not a string**: the
plan engine holds no user-facing prose. `PlanStrings` turns change and reason
into one line — "62.5 kg next time — you hit all 12 on every set" — assembled
from two halves rather than written out per combination, because seven changes
times twelve reasons is eighty-four sentences nobody would keep correct.

### Finishing a session is a plan edit

`finish` closes the session, asks the engine what each exercise earned, and
writes the result through `PlanEdits.applyProgression` as a **new plan
revision**. Progression is therefore not a special path: it is the same
immutable-revision machinery a swap or a day move uses, which is what keeps a
plan somebody has trained from being rewritten underneath its own history.
A session that earned nothing writes no revision at all.

Exercises the user skipped entirely are left out of the decision list rather
than reported as incomplete. Telling somebody they did not do the thing they
did not do is noise.

## Persistence

Drift / SQLite, local-first. The MVP has no network at all.

Schema v1 already carries `updated_at`, `deleted_at` and `device_id` on every
table that will eventually replicate, so adding Supabase later is one
implementation class rather than a migration across nine tables. Deletes are
soft; a hard delete is invisible to a peer.

### Plans are immutable revisions

Saving an edited plan writes a **new** plan row and deactivates the previous
one, rather than rewriting the rows in place. A session log points at the exact
`plan_exercises` row it was performed against, so a plan somebody has trained
is never altered underneath its own history. The cost is a few dozen rows per
edit, which is nothing; what it buys is that "what was I asked to do that day"
stays answerable, and progression in M3 can read the prescription a set was
actually logged against.

It also makes the plan stream cheap: because every edit inserts a plan row, a
watch on the plans table re-emits on every edit without having to watch the day
and exercise tables too.

### Timestamps are stored as text, in UTC

Drift's default integer format stores unix *seconds* and says nothing about the
zone, so a UTC value written on one device reads back as a local one with its
sub-second part gone. For rows that will eventually be reconciled across
devices by comparing their timestamps, that is not a detail, so the database
uses `storeDateTimeAsText` and the domain normalizes to UTC on construction.
`DateTime` equality includes the zone flag, which is how this surfaced: a
profile that had been through storage would not compare equal to the one that
went in.

### What a stored row is allowed to cost

Decoding a row Spottr does not recognise is not one decision but two. An
unknown **injury** is an error: silently dropping it would put exercises back
into someone's week that were excluded for a reason. Unknown **equipment** is
skipped: the cost is one fewer option, which is recoverable, whereas refusing
to load costs the user the app. The asymmetry is deliberate and tested.

`rep_logs` and `form_events` are deliberately **local-only**: per-rep traces and
rule verdicts are thousands of rows per session, invaluable for debugging and
for generating harness fixtures, and of no use to another device.
`database_test.dart` asserts that every table is classified one way or the
other, so a new table cannot be added without that decision being made.

## App layer

Riverpod for wiring. Repositories and the catalog are providers so nothing in
the UI reaches into a global, and the three controllers — `ProfileController`,
`PlanController` and `SessionController` — are **interfaces** with
database-backed implementations.
That is not ceremony: it is what lets a widget test assert *what a screen asked
for* without a database underneath it. A widget test that waits on a real
SQLite read spends its life fighting the fake clock a widget test runs under,
and it would be testing the repositories, which have their own tests against a
real in-memory database.

### Identifiers never reach the screen

The catalog and the plan engine deal only in ids and ARB keys. `PlanStrings` is
the single seam where those become prose — exercise names, day labels, movement
patterns, muscles, equipment, injury sites, run suggestions, and the plan notes
with their details resolved. It takes no `BuildContext`, so the whole mapping
is unit testable, and the tests walk every enum and the entire catalog rather
than sampling: the failure this exists to prevent is a raw
`exercise_db_bent_over_row` appearing on screen.

The catalog's keys are snake_case because it derives them from ids; the ARB
keys are camelCase because the generated getters have to pass the analyzer.
One switch knows both spellings, and a test fails if a catalog entry has no
name.

### The disclaimer is a gate, not a page

Routing asks two questions: is there a profile, and did it clear the
disclaimer. A profile that exists without acceptance goes back through
onboarding. Until it is accepted, the only enabled control on screen is the one
that accepts it, and acceptance is stored as a timestamp rather than a flag —
"when did they agree, and to which wording" is the question worth being able to
answer.

### Which profile changes cost the user their plan

Regenerating discards every swap and reorder, so it happens only when an answer
the generator actually reads has changed: goal, days, session length, level,
location, equipment, injuries, and run days when either side of the change
runs. A different coach voice, a corrected body weight or a note typed into the
injury box rebuild nothing. `UserProfile.wouldChangePlan` is that rule, in one
place, tested.

Reordering is the mirror image: it deliberately does not re-apply the day
rules, because a session the user trimmed by hand should not spring back to
full volume because they dragged a row.

### A log has to name the prescription it was performed against

A `WeekPlan` is a pure engine value and carries no row ids, but a set log
points at the exact `plan_exercises` row it was trained against.
`PlanRepository.dayRef` is the one place that translates between the two, and
it reads the **active** revision, so a log can never attach itself to a plan
the user has already replaced. The row id is resolved per set rather than
cached for the session, because a plan edited mid-workout would otherwise
leave later sets pointing at a revision that is no longer current.

### One workout at a time

`SessionRepository.start` refuses while a session is open rather than guessing.
A workout is a thing you are in the middle of, and two open at once means two
answers to "which set am I on". The plan screen reads the open session to
decide whether a day card offers to start, to resume, or says that another
session is still running.

Logs are append-only, and `painReported` is one-way: there is no un-report.
The pain button is in a persistent bar beside Finish, not in a menu — a safety
control the user has to scroll an exercise list to reach is not one.

The session stream has to watch `set_logs` as well as `sessions`, and that is
the one place where the trick that makes the plan stream cheap does not
transfer. A plan edit always inserts a plan row, so watching one table is
enough; logging a set changes no column on the session row at all. A watch on
`sessions` alone compiles, passes every test that stubs the data layer, and
then silently drops every set the user logs. It took running the thing on a
phone to see it.

### Defaults are the conservative ones

A new draft starts as a beginner, at home, with no equipment, on three moderate
sessions. Someone who taps through the questions without reading them gets a
plan that is too easy, never one that hands a novice a barbell. That is the
right way round for the failure to happen.

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
- The catalog is hand-authored data, so a validator checks every
  cross-reference, ladder direction, alternative symmetry and camera angle
  declaration, and a test asserts it reports nothing. Separate tests pin the
  rep-counter and form-rule vocabularies in both directions, so a typo in a
  catalog entry and a planned rule that nothing uses both fail.
- Plan generation is checked by **property tests** over 300 randomized
  profiles, asserting invariants rather than outputs: correct day count, no
  contraditions of equipment, injury or level, no duplicate within a day, every
  day inside its budget, at least one compound per day, no heavy legs before a
  run, and never clashing with a run day when the week had room. The seed is
  fixed so failures reproduce, and the failing profile is printed. The same
  invariants are re-checked after a random swap, reorder and day move.
- Plan generation is **also** pinned by golden files for twelve representative
  profiles, regenerated with `UPDATE_GOLDENS=1`. Property tests prove what must
  always be true; goldens show what the generator actually decides, so a
  ranking change arrives as a readable diff.
- Progression is a decision table, so `progression_test.dart` is a truth table.
  Every case is named for the user it is about — "every rep at the top of the
  range raises the load", "pain stops progression dead, whatever else the
  session says" — rather than for the branch it covers, which is what makes a
  failure tell you which promise broke.
- Repositories are tested against a real in-memory SQLite, and the plan
  round-trip is one `expect(loaded, plan)` because the plan value objects have
  value equality. A round-trip test that compared a handful of fields would
  pass while silently dropping the rest — which is how the stored-timestamp
  zone bug was found.
- Widget tests stub the data layer and the controllers. They assert what a
  screen shows and what it asks for: that the disclaimer cannot be skipped,
  that every answer the user gives reaches the saved profile, that the run-days
  question appears only for the hybrid goal, that a day card marks the
  exercises the camera can coach, that tapping an alternative asks for that
  swap, and that rebuilding asks before discarding edits. Loading, empty, error
  and success are covered for both the router and the plan screen.
- The safety copy is pinned by tests. The disclaimer has to say "cannot
  guarantee" and "not medical advice" and point at a professional; the
  hybrid-goal and run-day text has to say Spottr does not track runs; the tough
  coach has to say it never tells anyone to push through pain. Softening any of
  those is a change of claim, not a change of copy, and should have to break a
  test.
- The pose pipeline is pure and tested from hand-written frames: the wire
  codec against a malformed message and a float-boundary visibility, the
  one-euro filter against jitter, a step, a repeated timestamp and a gap too
  long to smooth across, and the framing check as a decision table named for
  the user it is about — "says step back rather than naming the joints it
  lost", "judges a face-down body by its longer dimension".
- The camera itself is substituted at `PoseSource`, not at the frame stream
  above it, so the widget tests run the real smoothing and the real framing
  check underneath the screen. What they assert is what the screen does with
  what it is given: which advice it shows, which severity it paints, that it
  stops the camera when it is disposed and when the app is backgrounded, and
  that an error on the frame stream is shown rather than looking like an
  empty room.
- The skeleton painter is tested by counting what reached the canvas, not
  with an image golden. A golden would pin anti-aliasing and font rendering
  across platforms along with the thing under test; counting draw calls says
  exactly what the painter did — two bones and three dots for one leg, and a
  landmark at `0.45, 0.5` landing at `135, 200` in a 300 by 400 box.
- The native half has unit tests for the arithmetic Dart cannot see — the
  joint-ordinal offsets, the normalization and the rotation transpose — and
  **they do not run in CI**, because a Gradle unit test needs an example app
  to host it and this plugin has none. `docs/dev-loop.md` records what that
  leaves unverified and what to look at the first time a real body goes
  through the pipeline.
- The live coach is tested by driving `FakePoseCamera` through a recorded set
  and asserting the exact cue sequence.
- The rep counter is a decision table driven one angle at a time: a wobble
  at the top, a dip on the way up, a rep joined half way through, a bounce
  too fast to be real, a rep abandoned at the bottom, a tracking gap short
  enough to ride out and one that is not. The thresholds in it are the
  test's own, not the catalog's, because reading a state-machine test should
  not require knowing what a real squat's numbers happen to be this week.
- `counter_catalog_test` checks the launch counters the way the exercise
  catalog is checked: every camera-supported exercise resolves to a counter,
  every counter is referred to, and nothing in the table is internally
  impossible. A counter whose thresholds run backwards opens a camera, draws
  a skeleton and counts nothing for ever, which looks exactly like a broken
  model, so it is checked once where it can be seen.
- The accuracy harness gates CI from M5: the generated suite must come out
  exact, and it reports rep-count error per fixture with the ledger behind
  it. Per-rule precision and recall land with the rules in M6.
- The widget tests of the coach screen are driven by the harness's generated
  sets, so the screen is tested against a body rather than against a
  hand-written pose that happens to suit it.

Acceptance targets: rep count accuracy >= 95% at the recommended angle, form
warnings firing on labeled faults with a low false-positive rate. These are
measurements against labeled footage, not checkboxes — see `docs/dev-loop.md`
for where that footage comes from and what is honestly claimable without it.

The goldens have earned their keep twice over. Reviewing a regenerated file
is what caught the pre-run rule spending its freed time on leg extensions —
every test still passed, because every test was asserting what it had been
told to assert. A diff you read is the only check that catches a plan which
is valid and wrong.

The property tests have already earned their keep: they found that a
bodyweight-only user on a five or six day split was being handed a pull day
with no pull in it, and then that the same hole existed for pushing once
injuries were in play. Neither was reachable from the hand-written cases.
