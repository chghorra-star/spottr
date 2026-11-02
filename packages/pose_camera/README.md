# pose_camera

Camera capture and on-device pose inference, behind one Dart interface.

**No pixel buffer crosses the bridge.** The preview goes from the camera
straight into a Flutter texture and the analysis frames are released as soon
as the model has read them. What reaches Dart is thirty-three joints as a
flat `Float32` buffer, in `pose_core`'s `PoseFrameCodec` format.

## The seam

`PoseSource` is the whole public surface: a broadcast stream of `PoseFrame`s,
three control calls, and typed errors. `DevicePoseCamera` runs a real camera;
`FakePoseCamera` replays a recorded set. Everything above this — the overlay,
the framing check, the rep counter, the form rules, the coach — is written
against the interface and is therefore testable with no device, no camera and
no model.

There is deliberately no `PlatformInterface`. That pattern exists so a third
party can supply another platform's implementation of a published plugin;
this plugin is private to one app and ships both platforms itself.

## Both platforms, one contract

| | Android | iOS |
| --- | --- | --- |
| Capture | CameraX | AVFoundation |
| Model | ML Kit Pose Detection | ML Kit Pose Detection |
| Preview | `SurfaceProducer` (push) | `FlutterTexture` (pull) |
| Rotation | ML Kit rotates | the capture connection rotates |
| Landmark identity | already a BlazePose index | a string constant, mapped by hand |

The same model on both, on purpose. Apple's Vision framework needs no pod and
reports nineteen joints instead of thirty-three, with no heel and no toe — so
`heel_lift` would silently stop existing on iOS and every threshold in the
coach engine would mean something different depending on the handset. The
architecture above `PoseSource` assumes the two platforms are
indistinguishable, and a second model would make that false in a way no test
here could see.

## Status

The Android half has run on an emulator. The iOS half, added in M9, **has
never been compiled** — this project is developed on Windows. The CI jobs in
`.github/workflows/ci.yml` are what will compile it; `docs/dev-loop.md` lists
the specific things most likely to be wrong.

## Tests

`flutter test` covers the Dart side: the channel contract, the fake, and the
preview widget.

Native arithmetic — the landmark packing, where an off-by-one silently remaps
every joint in the app — is covered on both platforms and runs on one.
`LandmarkPackerTests.swift` lives in the Runner's test target, which CI
builds. `LandmarkPackerTest.kt` has no host: a Gradle unit test needs an
example app and this plugin has none.
