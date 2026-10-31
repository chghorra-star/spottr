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

**No single angle sees everything.** Depth and spinal position need the side
view; left-right symmetry such as knee valgus needs the front. So a camera
config names every rule the exercise has and says which ones each acceptable
angle cannot evaluate. The invariants the catalog validator enforces are
therefore *not* "the recommended angle supports every rule" — that is
impossible — but:

- the recommended angle evaluates at least as many rules as any other
  acceptable angle, since it is what the setup screen asks the user for, and
- no rule is disabled at every acceptable angle, which would mean it can never
  fire.

This was corrected during M1: the original invariant was unsatisfiable by any
real exercise, and writing the catalog is what exposed it.

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
  -> fit to time budget   sets x (reps x tempo + rest) <= sessionMinutes
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
cannot avoid it, leg-dominant compound slots are capped at two sets and a
`legVolumeReducedForRun` note explains why. The brief asks to avoid *heavy* leg
work, not to skip legs, so volume comes down rather than the session losing its
purpose.

Running output is a text suggestion keyed to experience. Spottr does not track
runs.

### Plan notes

The generator reports its own compromises rather than hiding them:
`unfilledSlot`, `templateSimplified`, `legVolumeReducedForRun`,
`trimmedForTime`, `dayUnderfilled`. Each carries a machine-readable detail and
an optional weekday, and the UI maps the kind to prose. A short session should
look explained, not broken.

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
the UI reaches into a global, and the two controllers — `ProfileController` and
`PlanController` — are **interfaces** with database-backed implementations.
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
- Progression is a decision table.
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
- The live coach is tested by driving `FakePoseCamera` through a recorded set
  and asserting the exact cue sequence.
- The accuracy harness reports rep-count error and per-rule precision and
  recall, and gates CI once it exists in M5.

Acceptance targets: rep count accuracy >= 95% at the recommended angle, form
warnings firing on labeled faults with a low false-positive rate. These are
measurements against labeled footage, not checkboxes — see `docs/dev-loop.md`
for where that footage comes from and what is honestly claimable without it.

The property tests have already earned their keep: they found that a
bodyweight-only user on a five or six day split was being handed a pull day
with no pull in it, and then that the same hole existed for pushing once
injuries were in play. Neither was reachable from the hand-written cases.
