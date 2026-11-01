import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';

const MethodChannel _control = MethodChannel('spottr/pose_camera');
const EventChannel _frames = EventChannel('spottr/pose_camera/frames');

Map<Object?, Object?> _frameMessage({int frameId = 1, int tUs = 0}) {
  final landmarks = Float32List(PoseFrameCodec.bufferLength);
  for (final joint in Joint.values) {
    final base = joint.index * PoseFrameCodec.stride;
    landmarks[base] = 0.5;
    landmarks[base + 1] = joint.index / 33;
    landmarks[base + 3] = 1;
  }
  return <Object?, Object?>{
    'frameId': frameId,
    'tUs': tUs,
    'confidence': 0.9,
    'landmarks': landmarks,
  };
}

const Map<Object?, Object?> _startReply = <Object?, Object?>{
  'imageWidth': 480,
  'imageHeight': 640,
  'lens': 'back',
  'mirrored': false,
  'textureId': 11,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  late TestDefaultBinaryMessenger messenger;

  /// Answers the control channel. Returning a [PlatformException] makes the
  /// call fail the way a real failure does.
  void onControl(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(_control, (call) async {
      calls.add(call);
      final result = handler(call);
      if (result is PlatformException) throw result;
      return result;
    });
  }

  setUp(() {
    calls.clear();
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    onControl((call) => switch (call.method) {
          'permissionStatus' => 'granted',
          'requestPermission' => 'granted',
          'start' => _startReply,
          'stop' => null,
          _ => null,
        });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_control, null);
    messenger.setMockStreamHandler(_frames, null);
  });

  group('DevicePoseCamera permission', () {
    test('reports the status the platform gives', () async {
      final camera = DevicePoseCamera();
      expect(await camera.permissionStatus(), CameraPermissionStatus.granted);
      expect(calls.single.method, 'permissionStatus');
    });

    test('maps a refusal the user can be asked about again', () async {
      onControl((_) => 'denied');
      expect(
        await DevicePoseCamera().requestPermission(),
        CameraPermissionStatus.denied,
      );
    });

    test('maps a refusal that only Settings can undo', () async {
      // Worth a separate value: the screen has to stop offering a button
      // that can no longer do anything and point at Settings instead.
      onControl((_) => 'permanentlyDenied');
      expect(
        await DevicePoseCamera().requestPermission(),
        CameraPermissionStatus.permanentlyDenied,
      );
    });

    test('refuses to guess at a status it does not know', () async {
      // An unrecognised value means the two halves of the bridge disagree.
      // Treating it as "denied" would read as a permission bug forever.
      onControl((_) => 'maybe');
      expect(
        () => DevicePoseCamera().permissionStatus(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DevicePoseCamera start and stop', () {
    test('asks for the lens by name and returns the source geometry',
        () async {
      final info = await DevicePoseCamera().start(lens: CameraLens.front);

      expect(calls.single.method, 'start');
      expect(calls.single.arguments, {'lens': 'front'});
      expect(info.imageWidth, 480);
      expect(info.imageHeight, 640);
      expect(info.textureId, 11);
      expect(info.mirrored, isFalse);
      expect(info.aspectRatio, closeTo(0.75, 1e-9));
    });

    test('defaults to the back lens', () async {
      await DevicePoseCamera().start();
      expect(calls.single.arguments, {'lens': 'back'});
    });

    test('turns a platform failure into a typed error', () async {
      onControl(
        (_) => PlatformException(code: 'cameraInUse', message: 'busy'),
      );

      await expectLater(
        DevicePoseCamera().start(),
        throwsA(
          isA<PoseCameraException>()
              .having((e) => e.error, 'error', PoseCameraError.cameraInUse),
        ),
      );
    });

    test('maps a platform code it does not recognise to unknown', () async {
      onControl((_) => PlatformException(code: 'weird'));

      await expectLater(
        DevicePoseCamera().start(),
        throwsA(
          isA<PoseCameraException>()
              .having((e) => e.error, 'error', PoseCameraError.unknown)
              .having((e) => e.message, 'message', contains('weird')),
        ),
      );
    });

    test('reports a denied permission as such rather than as a crash', () async {
      onControl(
        (_) => PlatformException(code: 'permissionDenied'),
      );

      await expectLater(
        DevicePoseCamera().start(),
        throwsA(
          isA<PoseCameraException>().having(
            (e) => e.error,
            'error',
            PoseCameraError.permissionDenied,
          ),
        ),
      );
    });

    test('stops the camera', () async {
      await DevicePoseCamera().stop();
      expect(calls.single.method, 'stop');
    });
  });

  group('DevicePoseCamera frames', () {
    test('decodes what the event channel delivers', () async {
      messenger.setMockStreamHandler(
        _frames,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            sink
              ..success(_frameMessage(frameId: 1, tUs: 0))
              ..success(_frameMessage(frameId: 2, tUs: 33000))
              ..endOfStream();
          },
        ),
      );

      final frames = await DevicePoseCamera().frames.take(2).toList();

      expect(frames.map((frame) => frame.frameId), [1, 2]);
      expect(frames.last.t, const Duration(milliseconds: 33));
      expect(frames.first.landmarks, hasLength(Joint.values.length));
    });

    test('surfaces a malformed frame as a stream error', () async {
      // The alternative is an uncaught exception inside the channel
      // callback, which shows up as a red screen with no clue which frame
      // did it.
      messenger.setMockStreamHandler(
        _frames,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            sink
              ..success(<Object?, Object?>{'frameId': 'not a number'})
              ..endOfStream();
          },
        ),
      );

      await expectLater(
        DevicePoseCamera().frames,
        emitsError(isA<PoseCameraException>()),
      );
    });

    test('surfaces a camera failure raised mid-stream', () async {
      messenger.setMockStreamHandler(
        _frames,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            sink.error(code: 'modelFailed', message: 'inference died');
          },
        ),
      );

      await expectLater(
        DevicePoseCamera().frames,
        emitsError(
          isA<PoseCameraException>()
              .having((e) => e.error, 'error', PoseCameraError.modelFailed),
        ),
      );
    });

    test('serves more than one listener from one native subscription',
        () async {
      // The overlay, the framing banner and, from M5, the rep counter all
      // watch the same stream. A single-subscription stream would make the
      // second listener an error and a second native subscription would run
      // the camera twice.
      var listens = 0;
      MockStreamHandlerEventSink? native;
      messenger.setMockStreamHandler(
        _frames,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            listens++;
            native = sink;
          },
        ),
      );

      final camera = DevicePoseCamera();
      final first = camera.frames.first;
      final second = camera.frames.first;
      await pumpEventQueue();

      native!.success(_frameMessage());

      expect((await first).frameId, 1);
      expect((await second).frameId, 1);
      expect(listens, 1);
    });

    test('does not subscribe to the camera until something is watching',
        () async {
      var listens = 0;
      messenger.setMockStreamHandler(
        _frames,
        MockStreamHandler.inline(onListen: (arguments, sink) => listens++),
      );

      final camera = DevicePoseCamera();
      await pumpEventQueue();
      expect(listens, 0);

      final subscription = camera.frames.listen(null);
      await pumpEventQueue();
      expect(listens, 1);

      await subscription.cancel();
      await camera.dispose();
    });

    test('keeps delivering after one bad frame', () async {
      // One frame the decoder cannot read is a frame, not the end of a set.
      MockStreamHandlerEventSink? native;
      messenger.setMockStreamHandler(
        _frames,
        MockStreamHandler.inline(
          onListen: (arguments, sink) => native = sink,
        ),
      );

      final camera = DevicePoseCamera();
      final received = <Object>[];
      camera.frames.listen(received.add, onError: received.add);
      await pumpEventQueue();

      native!
        ..success(<Object?, Object?>{'frameId': 'not a number'})
        ..success(_frameMessage(frameId: 5));
      await pumpEventQueue();

      expect(received.first, isA<PoseCameraException>());
      expect((received.last as PoseFrame).frameId, 5);
    });
  });
}
