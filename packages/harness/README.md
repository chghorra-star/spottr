# harness

The accuracy harness: replays labelled landmark fixtures through the real
coach engine and reports what it counted.

```bash
dart run harness                        # the generated suite
dart run harness --fixtures recorded/   # a directory of .json fixtures
dart run harness --synthetic -f recorded/
dart run harness --json                 # for a machine
dart run harness --no-smooth            # what the smoothing filter buys
```

Exit code 1 means a gate was missed, which is what makes it usable from CI.
`tool/check.ps1` runs the generated suite with the gate at 100 per cent:
generated movement has one right answer, so anything else is a regression in
the state machine, the thresholds or the filter.

## What a pass does and does not mean

The suite is generated, not recorded. Passing it shows that the state
machine, the catalog thresholds and the smoothing filter agree with each
other about movement of a known shape. It says **nothing** about accuracy on
a real body: there is no clothing here, no occlusion, no model error and no
camera.

The report always prints how many exercises have footage of a real body —
currently none — and never averages a synthetic result together with a
recorded one. `docs/dev-loop.md` has the rest of that argument.

## Fixtures

One JSON file per set, version 1:

```json
{
  "fixtureVersion": 1,
  "name": "squat_side_eight",
  "exerciseId": "bodyweight_squat",
  "angle": "side",
  "source": "recorded",
  "notes": "loose shorts, third rep is shallow",
  "expected": { "reps": 8 },
  "frames": [ { "frameId": 0, "tUs": 0, "confidence": 0.94,
                "landmarks": [ 0.5, 0.6, 0.0, 0.98, null, null, null, null ] } ]
}
```

`landmarks` is `PoseFrameCodec`'s flat buffer: 33 joints in BlazePose
ordinal order, four values each, with `null` for a joint the model did not
place. A hold uses `{ "holdMs": 30000 }` in place of `"reps"`.

The label is the fixture author's judgement, not the counter's: deriving it
from the thresholds would make the suite agree with the engine by
construction and measure nothing.

`tool/make_tiny.dart` writes `test/fixtures/tiny_squat.json`, the one fixture
committed as a file, so the reader is tested against a file on disk rather
than against the writer that produced it.
