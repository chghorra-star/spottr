import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

/// Which camera to run the coach from.
///
/// The back lens is the default: the phone is propped up facing the user,
/// who is too far away to reach it, and the back lens is the better of the
/// two on every handset.
enum CameraLens { front, back }

/// Whether the app may use the camera.
enum CameraPermissionStatus {
  granted,

  /// Refused, but the user can be asked again.
  denied,

  /// Refused in a way only the system settings can undo. Separate from
  /// [denied] because a button that asks again does nothing here, and
  /// offering it makes the app look broken.
  permanentlyDenied,
}

/// What went wrong with the camera.
enum PoseCameraError {
  permissionDenied,

  /// No usable camera on the device, or the requested lens is missing.
  noCamera,

  /// Another app holds the camera.
  cameraInUse,

  /// The pose model failed to load or to run.
  modelFailed,

  /// A frame the Dart side could not read, which means the two halves of
  /// the bridge disagree about the wire format.
  badFrame,

  unknown,
}

/// A camera or pose failure, typed so the UI can say something useful.
class PoseCameraException implements Exception {
  const PoseCameraException(this.error, [this.message = '']);

  final PoseCameraError error;
  final String message;

  @override
  String toString() =>
      'PoseCameraException(${error.name}${message.isEmpty ? '' : ': $message'})';
}

/// The shape of what a running source produces.
///
/// Returned by [PoseSource.start] rather than sent with every frame: an
/// image size and a lens do not change thirty times a second, and a
/// [PoseFrame] that carried them would stop being a pose and start being a
/// camera reading — which the harness, replaying a fixture, has no business
/// inventing.
@immutable
class PoseSourceInfo {
  const PoseSourceInfo({
    required this.imageWidth,
    required this.imageHeight,
    required this.lens,
    required this.mirrored,
    this.textureId,
  });

  factory PoseSourceInfo.fromMessage(Object? message) {
    if (message is! Map) {
      throw FormatException(
        'start: expected a map, got ${message.runtimeType}',
      );
    }
    return PoseSourceInfo(
      imageWidth: _int(message, 'imageWidth'),
      imageHeight: _int(message, 'imageHeight'),
      lens: _lens(message['lens']),
      mirrored: message['mirrored'] == true,
      textureId: message['textureId'] is int
          ? message['textureId']! as int
          : null,
    );
  }

  /// Width of the frames the model was given, after rotation to upright.
  final int imageWidth;

  /// Height of the frames the model was given, after rotation to upright.
  final int imageHeight;

  final CameraLens lens;

  /// Whether the preview and the landmark x axis are both flipped.
  ///
  /// The front lens is shown mirrored, the way a mirror in a gym is, so the
  /// native side flips the landmark x to match. Joint *names* stay
  /// anatomical either way — ML Kit labels a left knee a left knee — so a
  /// rule comparing left to right is unaffected, and only a rule that
  /// inferred a facing direction from screen position would need to know.
  final bool mirrored;

  /// The Flutter texture the preview renders, or null for a source with no
  /// pixels — a replayed fixture, which has landmarks and nothing to show.
  final int? textureId;

  /// Width over height, for laying the preview out.
  double get aspectRatio => imageWidth / imageHeight;

  static int _int(Map<Object?, Object?> message, String key) {
    final value = message[key];
    if (value is int) return value;
    throw FormatException('start.$key: expected an int, got ${value.runtimeType}');
  }

  static CameraLens _lens(Object? raw) => switch (raw) {
        'front' => CameraLens.front,
        'back' => CameraLens.back,
        _ => throw FormatException('start.lens: unknown lens "$raw"'),
      };

  @override
  String toString() => 'PoseSourceInfo(${imageWidth}x$imageHeight, '
      '${lens.name}${mirrored ? ', mirrored' : ''}, texture=$textureId)';
}

/// Something that produces [PoseFrame]s.
///
/// The seam the whole camera stack is built on. The device implementation
/// runs a camera and a pose model; the fake replays a recorded set. Every
/// layer above this one — the overlay, the framing banner, and from M5 the
/// rep counter and the form rules — is written against this interface and
/// therefore testable with no device, no camera and no model.
///
/// There is deliberately no `PlatformInterface` here. That pattern exists so
/// a third party can supply another platform's implementation of a published
/// plugin; this plugin is private to one app and ships both platforms
/// itself, so the registration dance would buy nothing and the useful seam
/// is this one.
abstract class PoseSource {
  /// Landmark frames, for as many listeners as want them.
  ///
  /// A broadcast stream: the overlay, the framing banner and the rep
  /// counter all watch it at once, and running the camera once per listener
  /// is not an option.
  Stream<PoseFrame> get frames;

  /// Whether the camera may be used, without asking the user anything.
  Future<CameraPermissionStatus> permissionStatus();

  /// Asks the user, if they have not permanently refused.
  Future<CameraPermissionStatus> requestPermission();

  /// Opens the camera and starts inference.
  ///
  /// Throws [PoseCameraException] if the camera cannot be opened.
  Future<PoseSourceInfo> start({CameraLens lens});

  /// Closes the camera. Safe to call when it is not running.
  Future<void> stop();

  /// Releases everything, including the frame stream.
  Future<void> dispose();
}
