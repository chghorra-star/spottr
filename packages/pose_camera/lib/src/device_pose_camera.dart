import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pose_core/pose_core.dart';

import 'pose_source.dart';

/// The real camera: native capture, native inference, landmarks over a
/// channel.
///
/// Two channels rather than one. Control calls — permission, start, stop —
/// are request and reply and belong on a [MethodChannel]. Frames are a
/// one-way firehose at camera rate and belong on an [EventChannel], where
/// they cost one message each instead of a call and a reply.
class DevicePoseCamera implements PoseSource {
  DevicePoseCamera({
    MethodChannel control = const MethodChannel('spottr/pose_camera'),
    EventChannel frames = const EventChannel('spottr/pose_camera/frames'),
  })  : _controlChannel = control,
        _frameChannel = frames;

  final MethodChannel _controlChannel;
  final EventChannel _frameChannel;

  late final StreamController<PoseFrame> _controller =
      StreamController<PoseFrame>.broadcast(onListen: _attach);
  StreamSubscription<Object?>? _native;

  @override
  Stream<PoseFrame> get frames => _controller.stream;

  @override
  Future<CameraPermissionStatus> permissionStatus() =>
      _permission('permissionStatus');

  @override
  Future<CameraPermissionStatus> requestPermission() =>
      _permission('requestPermission');

  @override
  Future<PoseSourceInfo> start({CameraLens lens = CameraLens.back}) async {
    try {
      final reply = await _controlChannel.invokeMethod<Object?>(
        'start',
        {'lens': lens.name},
      );
      return PoseSourceInfo.fromMessage(reply);
    } on PlatformException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _controlChannel.invokeMethod<void>('stop');
    } on PlatformException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<void> dispose() async {
    await _native?.cancel();
    _native = null;
    await _controller.close();
  }

  /// Subscribes to the native frame stream the first time anything listens.
  ///
  /// Once attached it stays attached until [dispose]. Detaching when the
  /// last listener leaves would mean tearing down and rebuilding the native
  /// subscription every time the UI rebuilt its watchers, and dropping
  /// whatever arrived in between.
  void _attach() {
    if (_native != null) return;
    _native = _frameChannel.receiveBroadcastStream().listen(
      (message) {
        if (_controller.isClosed) return;
        try {
          _controller.add(
            PoseFrameCodec.decode(message as Map<Object?, Object?>),
          );
        } on Object catch (error) {
          // One unreadable frame is a frame, not the end of the set, so the
          // error goes to the listeners and the stream stays open. An
          // exception thrown out of a channel callback instead becomes an
          // unhandled error with no clue which frame caused it.
          _controller.addError(
            PoseCameraException(PoseCameraError.badFrame, '$error'),
          );
        }
      },
      onError: (Object error) {
        if (_controller.isClosed) return;
        _controller.addError(
          error is PlatformException
              ? _translate(error)
              : PoseCameraException(PoseCameraError.unknown, '$error'),
        );
      },
    );
  }

  Future<CameraPermissionStatus> _permission(String method) async {
    try {
      final reply = await _controlChannel.invokeMethod<String>(method);
      return switch (reply) {
        'granted' => CameraPermissionStatus.granted,
        'denied' => CameraPermissionStatus.denied,
        'permanentlyDenied' => CameraPermissionStatus.permanentlyDenied,
        // Not defaulted to "denied": an unrecognised value means the native
        // and Dart halves disagree, and failing closed would read as a
        // permission problem forever instead of as the version skew it is.
        _ => throw FormatException('$method: unknown status "$reply"'),
      };
    } on PlatformException catch (error) {
      throw _translate(error);
    }
  }

  static PoseCameraException _translate(PlatformException error) {
    final kind = switch (error.code) {
      'permissionDenied' => PoseCameraError.permissionDenied,
      'noCamera' => PoseCameraError.noCamera,
      'cameraInUse' => PoseCameraError.cameraInUse,
      'modelFailed' => PoseCameraError.modelFailed,
      _ => PoseCameraError.unknown,
    };
    // The code is kept in the message for the unknown case, because that is
    // the one where the name of the thing that happened is all there is.
    return PoseCameraException(
      kind,
      kind == PoseCameraError.unknown
          ? '${error.code}${error.message == null ? '' : ': ${error.message}'}'
          : error.message ?? '',
    );
  }
}
