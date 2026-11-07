# Spottr

Adaptive gym plans, plus a live form coach through the phone camera: it counts
reps, flags risky technique, and coaches out loud while you train.

All pose processing happens on the device. **Video never leaves the phone, and
nothing is uploaded.**

Spottr gives form feedback and flags movement that looks risky. It is not
medical advice and does not prevent injury.

## Status

M10 is code-complete: Spottr can replicate. `packages/sync_engine` is the whole
protocol as pure Dart — last writer wins over a total order, soft deletes as
tombstones, a cursor that survives an interrupted pull — with both ends
behind interfaces, so every rule in it is tested with no database and no
network. The app supplies those ends over the real SQLite database and over
PostgREST, and one test runs the real engine between two real databases and
a stand-in server, because that is the only place a boolean leaving SQLite
as `1` gets caught.

**Everything still works with no account.** The sync is additive; the plan,
the coach and the log are local and stay local. `rep_logs` and `form_events`
never leave the device, and the remote schema has nowhere to put a frame, a
landmark or a video.

There is a sign-in, and the account screen leads with the sentence above
rather than with a wall. A build given no Supabase project says so and
offers no form, because that is the ordinary local-first app rather than an
error. Every install now has a name of its own, which is what makes the
conflict tie-break able to break anything at all — before M10 they all
called themselves `local`.

**A device that holds one person's training refuses the next account**, and
can now be handed on. The refusal is right — once two people's rows are
mixed there is no telling afterwards whose were whose — but it needed a way
out, and erasing this device is it. It is the only hard delete in the app,
deliberately: every other delete is a tombstone that replicates, so an
erase through the ordinary path would queue a deletion for every row and
empty the departing person's *other* phone. Nothing is touched on the
server; what had synced is still theirs, and the confirmation says so.

**And a build with no account at all can still delete everything.** The
erase above is on the account screen, which a build with no Supabase
project does not really have — so the same mechanism is at the bottom of
the profile screen on any device nobody has signed in on, where the
confirmation can say the stronger thing: nothing here has been sent
anywhere, so there is no copy to restore it from.

What is not done: **none of it has met a server.** The remote schema in
`supabase/`, like the Podfile before M9, has never been run. A test reads it
and checks it against drift's own metadata column by column, which is the
difference between finding a missing column now and finding it after
somebody signs in — but it is not a substitute for `supabase db push`, and
`docs/dev-loop.md` lists the five things the first real sync will find out.

M9 done and green in CI at
[github.com/chghorra-star/spottr](https://github.com/chghorra-star/spottr).
The iOS half of the plugin — AVFoundation capture, the same ML Kit model
Android runs, the same flat buffer over the same two channels — now
compiles, links, and passes its native tests on a simulator, having been
written on Windows and never once run locally.

**The landmark ordinal table is verified, order included.** On iOS a
landmark's type is a string constant rather than BlazePose's index, so the
order is written out by hand, which made it the one file that could remap
every joint in the app while looking perfectly reasonable. Thirteen native
tests ran on an x86_64 iPhone 16 Pro simulator and one of them checks every
index, so the skeleton reaching Dart on iOS is the skeleton Android sends.

**The same model on both platforms, on purpose.** Apple's Vision framework
needs no pod and reports nineteen joints instead of thirty-three, with no
heel and no toe, so one form rule would silently stop existing on iOS and
every threshold would mean something different depending on the handset.

Nine CI runs to get there. One real bug in the Swift — ML Kit hands iOS an
array of poses where it hands Android a single one — and seven separate
pieces of build configuration that were wrong, none of which a Windows
machine could have discovered. `packages/harness/test/workflow_test.dart`
pins every one of them, with the reason beside it, because each looks
arbitrary and removable until somebody removes it.

CI runs the accuracy harness too, which had gated the local check since M5
while a stale comment in the workflow promised it would be wired in "once
the harness exists". And the app had no camera usage description, which
would have terminated it the moment it opened the camera on an iPhone.

Before that, M8 made it know what it does not know. The harness now publishes a
per-exercise table instead of one aggregate, and two new sweeps say how much
its own evidence is worth. 1032 tests green, analyzer clean.

**78 numbers in the engine; one of them has ever been measured.** 28 can be
changed without any fixture noticing, 10 of those because nothing exercises
them at all. That is not permission to change them — it is the measurement of
how little generated movement constrains a threshold built from the same
assumptions.

The sweeps also found the error that actually costs reps: a tracker that
**wanders** breaks counting at a third of the amplitude that uncorrelated
noise needs, and wander is exactly what a low-pass filter cannot remove. The
first version of that sweep only tested noise, never broke anything, and was
measuring the smoothing filter.

The per-exercise table says UNMEASURED where it is unmeasured. All nine
camera exercises still have an empty footage column, and no rule's
false-positive rate on a real body is known.

Before that, M7 made it coach a set. The camera screen now runs the set: it
counts, judges, talks, and writes what it watched into the log, with a pain
button on screen for the whole of it.

**The hard part of a talking coach is refusing to say things.** A rule has to
fire on two consecutive reps before it is spoken, a coaching point is made
once a set, nothing is said within two and a half seconds of the last thing,
and anything still waiting when the voice frees up is dropped rather than
spoken late. The accuracy harness reports how much the coach would have
talked over every fixture in the suite: currently one thing said every
twenty-two seconds of deliberately faulty movement.

A set logged from the coach carries the form score, the camera angle, and
the ledger of **every** attempt including the refused ones — the only record
of what somebody did that the app declined to count.

Before that, M6 taught it to judge form. Seventeen rules, each an id, a
severity, a signal and a number, run against every rep the counter accepts:
the coach screen says what to fix, scores the set, and names the checks it
is **not** running.

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
| M7 | Live coach UX, voice, safety | done |
| M8 | Dataset validation and tuning | done |
| M9 | iOS parity, cloud CI, TestFlight | done, green in CI |
| M10 | Supabase sync | engine, schema, both adapters and sign-in done; never run against a server |

## Layout

```
app/                    Flutter app
packages/pose_core/     pose primitives and geometry      [pure Dart]
packages/exercise_library/  curated exercise catalog      [pure Dart]
packages/coach_engine/  counting, form rules, scoring     [pure Dart]
packages/plan_engine/   plan generation, progression      [pure Dart]
packages/harness/       accuracy harness CLI              [pure Dart]
packages/sync_engine/   two-way replication protocol      [pure Dart]
packages/pose_camera/   native camera + pose inference    [Flutter plugin]
```

This is a Dart pub workspace: one lockfile, and `flutter pub get` runs from the
repo root, never inside a package.

The six pure-Dart packages must never import Flutter. That constraint is
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
