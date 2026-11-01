import 'dart:async';

import 'package:pose_core/pose_core.dart';

import 'pose_source.dart';

/// A [PoseSource] with no camera behind it.
///
/// This is the layer-one development loop in one class: the overlay, the
/// framing banner and, from M5, the rep counter and form rules can all be
/// driven through their real code paths from frames a test wrote by hand or
/// a fixture recorded earlier.
///
/// Two ways to use it. [emit] pushes one frame, which is what a widget test
/// wants — no timers, no clock, nothing to settle. [FakePoseCamera.replaying]
/// plays a recorded set back on a timer, which is what a demo or an
/// integration test wants.
class FakePoseCamera implements PoseSource {
  FakePoseCamera({
    PoseSourceInfo? info,
    this.permission = CameraPermissionStatus.granted,
    this.failStartWith,
  }) : info = info ?? const PoseSourceInfo(
              imageWidth: 480,
              imageHeight: 640,
              lens: CameraLens.back,
              mirrored: false,
            );

  /// Plays [frames] back one every [interval] once started.
  factory FakePoseCamera.replaying(
    List<PoseFrame> frames, {
    Duration interval = const Duration(milliseconds: 33),
    PoseSourceInfo? info,
  }) =>
      FakePoseCamera(info: info).._replay = (frames, interval);

  /// What [start] reports. A fake has no pixels, so [PoseSourceInfo.textureId]
  /// is null unless a caller says otherwise — which is what makes the
  /// preview widget's no-texture path the one tests exercise.
  final PoseSourceInfo info;

  /// What the permission calls answer, so the refused paths can be tested.
  final CameraPermissionStatus permission;

  /// Makes [start] fail, for the error states of the screen above.
  final PoseCameraException? failStartWith;

  final StreamController<PoseFrame> _controller =
      StreamController<PoseFrame>.broadcast();

  (List<PoseFrame>, Duration)? _replay;
  Timer? _timer;
  var _next = 0;

  /// Every lens [start] was called with, in order.
  final List<CameraLens> startedWith = [];

  var _running = false;
  var stopCount = 0;
  var permissionRequests = 0;

  bool get isRunning => _running;

  @override
  Stream<PoseFrame> get frames => _controller.stream;

  @override
  Future<CameraPermissionStatus> permissionStatus() async => permission;

  @override
  Future<CameraPermissionStatus> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<PoseSourceInfo> start({CameraLens lens = CameraLens.back}) async {
    startedWith.add(lens);
    final failure = failStartWith;
    if (failure != null) throw failure;

    _running = true;
    final replay = _replay;
    if (replay != null) {
      final (frames, interval) = replay;
      _timer = Timer.periodic(interval, (timer) {
        if (_next >= frames.length) {
          timer.cancel();
          return;
        }
        emit(frames[_next++]);
      });
    }
    return info;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  /// Delivers one frame to whatever is listening.
  void emit(PoseFrame frame) {
    if (!_running) {
      // A test that emits without starting is testing a path the real
      // camera cannot take, and the resulting silence is hard to read.
      throw StateError('FakePoseCamera.emit before start');
    }
    if (!_controller.isClosed) _controller.add(frame);
  }

  /// Delivers a failure the way the device source would.
  void emitError(Object error) {
    if (!_controller.isClosed) _controller.addError(error);
  }
}
