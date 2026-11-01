import 'package:flutter_test/flutter_test.dart';
import 'package:pose_camera/fake.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';

PoseFrame _frame(int id) => PoseFrame(
      frameId: id,
      t: Duration(milliseconds: id * 33),
      landmarks: {
        Joint.leftKnee: Landmark(x: 0.4, y: 0.6, z: 0, visibility: 1),
      },
      confidence: 0.9,
    );

void main() {
  test('delivers emitted frames to its listeners', () async {
    final camera = FakePoseCamera();
    await camera.start();

    final received = <PoseFrame>[];
    camera.frames.listen(received.add);
    await pumpEventQueue();

    camera.emit(_frame(1));
    camera.emit(_frame(2));
    await pumpEventQueue();

    expect(received.map((frame) => frame.frameId), [1, 2]);
    await camera.dispose();
  });

  test('records which lens it was started with', () async {
    final camera = FakePoseCamera();
    await camera.start(lens: CameraLens.front);

    expect(camera.startedWith, [CameraLens.front]);
    expect(camera.isRunning, isTrue);
    await camera.dispose();
  });

  test('reports the source geometry it was given', () async {
    final camera = FakePoseCamera(
      info: const PoseSourceInfo(
        imageWidth: 720,
        imageHeight: 1280,
        lens: CameraLens.front,
        mirrored: true,
      ),
    );

    final info = await camera.start();
    expect(info.aspectRatio, closeTo(0.5625, 1e-9));
    expect(info.mirrored, isTrue);
    // No pixels behind a fake, so nothing to show: this is the path the
    // preview widget's placeholder exists for.
    expect(info.textureId, isNull);
    await camera.dispose();
  });

  test('fails to start when told to', () async {
    final camera = FakePoseCamera(
      failStartWith: const PoseCameraException(PoseCameraError.cameraInUse),
    );

    await expectLater(camera.start(), throwsA(isA<PoseCameraException>()));
    expect(camera.isRunning, isFalse);
  });

  test('answers the permission calls with what it was configured for',
      () async {
    final camera = FakePoseCamera(
      permission: CameraPermissionStatus.permanentlyDenied,
    );

    expect(
      await camera.permissionStatus(),
      CameraPermissionStatus.permanentlyDenied,
    );
    expect(
      await camera.requestPermission(),
      CameraPermissionStatus.permanentlyDenied,
    );
    expect(camera.permissionRequests, 1);
  });

  test('refuses to emit before it was started', () async {
    // Emitting without starting exercises a path the real camera has no
    // way to take, and the silence that follows is hard to debug.
    expect(() => FakePoseCamera().emit(_frame(1)), throwsStateError);
  });

  test('stops emitting once stopped', () async {
    final camera = FakePoseCamera();
    await camera.start();
    await camera.stop();

    expect(camera.stopCount, 1);
    expect(() => camera.emit(_frame(1)), throwsStateError);
  });

  test('passes an error through the way the device source does', () async {
    final camera = FakePoseCamera();
    await camera.start();

    final errors = <Object>[];
    camera.frames.listen(null, onError: errors.add);
    await pumpEventQueue();

    camera.emitError(const PoseCameraException(PoseCameraError.modelFailed));
    await pumpEventQueue();

    expect(errors.single, isA<PoseCameraException>());
    await camera.dispose();
  });

  testWidgets('replays a recorded set on the clock', (tester) async {
    final camera = FakePoseCamera.replaying(
      [_frame(1), _frame(2), _frame(3)],
      interval: const Duration(milliseconds: 40),
    );
    final received = <PoseFrame>[];
    camera.frames.listen(received.add);

    await camera.start();
    await tester.pump(const Duration(milliseconds: 40));
    expect(received.map((frame) => frame.frameId), [1]);

    await tester.pump(const Duration(milliseconds: 80));
    expect(received.map((frame) => frame.frameId), [1, 2, 3]);

    // And then it stops rather than looping or throwing.
    await tester.pump(const Duration(milliseconds: 200));
    expect(received, hasLength(3));
    await camera.dispose();
  });
}
