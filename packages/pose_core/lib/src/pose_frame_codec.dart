import 'dart:typed_data';

import 'joint.dart';
import 'landmark.dart';
import 'pose_frame.dart';

/// The wire form of a [PoseFrame].
///
/// One shape, two senders: the native camera bridge emits it over an
/// `EventChannel` at camera frame rate, and the offline video extractor
/// writes the same thing into fixture files. Keeping the format here rather
/// than inside the plugin is what lets the harness read a recorded set
/// without depending on Flutter.
///
/// Landmarks travel as **one flat buffer indexed by BlazePose ordinal**,
/// four values per joint: `x, y, z, visibility`. A map of named joints would
/// be far friendlier to read and would also box 33 strings and 132 doubles
/// thirty times a second. The flat buffer crosses the channel as raw bytes.
///
/// The price of a fixed-length buffer is that "no landmark here" needs a
/// value rather than an absence, and that value is [absent] — `NaN` in the
/// position. It is the one bit pattern that cannot be mistaken for a place
/// on the body.
abstract final class PoseFrameCodec {
  /// Values per landmark: `x`, `y`, `z`, `visibility`.
  static const int stride = 4;

  /// Length of the landmark buffer: every joint, always, in ordinal order.
  static const int bufferLength = 33 * stride;

  /// Written into `x` and `y` for a joint the model did not place.
  static const double absent = double.nan;

  /// Rebuilds a frame from one channel message or one fixture entry.
  ///
  /// Throws [FormatException] on anything malformed. The only producers are
  /// our own native code and our own fixtures, so a bad message means a
  /// version skew between the two halves of the bridge — which should be
  /// loud, not silently decoded into a frame with a missing leg.
  static PoseFrame decode(Map<Object?, Object?> message) {
    final landmarks = _landmarkBuffer(message['landmarks']);
    final decoded = <Joint, Landmark>{};

    for (final joint in Joint.values) {
      final base = joint.index * stride;
      final x = landmarks[base];
      final y = landmarks[base + 1];
      // Either coordinate being non-finite means the model placed nothing
      // here. Absent rather than present-at-zero, because (0, 0) is the top
      // left corner of the image and a rule cannot tell the difference.
      if (!x.isFinite || !y.isFinite) continue;

      decoded[joint] = Landmark(
        x: x,
        y: y,
        z: landmarks[base + 2].isFinite ? landmarks[base + 2] : 0,
        // Clamped, not asserted. Float32 rounding and ML Kit's own
        // arithmetic both land a hair outside the documented 0..1, and
        // Landmark's assert would take the whole stream down over a frame
        // that is otherwise perfectly good.
        visibility: landmarks[base + 3].clamp(0.0, 1.0),
      );
    }

    return PoseFrame(
      frameId: _int(message, 'frameId'),
      t: Duration(microseconds: _int(message, 'tUs')),
      landmarks: decoded,
      confidence: _finiteDouble(message, 'confidence').clamp(0.0, 1.0),
    );
  }

  /// The wire form of [frame], ready to send or to serialise.
  static Map<String, Object?> encode(PoseFrame frame) {
    final landmarks = Float32List(bufferLength);
    for (final joint in Joint.values) {
      final base = joint.index * stride;
      final landmark = frame.landmarks[joint];
      if (landmark == null) {
        landmarks[base] = absent;
        landmarks[base + 1] = absent;
        continue;
      }
      landmarks[base] = landmark.x;
      landmarks[base + 1] = landmark.y;
      landmarks[base + 2] = landmark.z;
      landmarks[base + 3] = landmark.visibility;
    }

    return <String, Object?>{
      'frameId': frame.frameId,
      'tUs': frame.t.inMicroseconds,
      'confidence': frame.confidence,
      'landmarks': landmarks,
    };
  }

  /// The same frame as plain JSON types, for a fixture file.
  ///
  /// Identical to [encode] but for absence: JSON has no `NaN`, so a joint
  /// the model did not place is written as `null`. A format that cannot say
  /// "nothing here" cannot record a set where a limb left the frame, which
  /// is most of the sets worth recording.
  static Map<String, Object?> encodeJson(PoseFrame frame) {
    final landmarks = List<Object?>.filled(bufferLength, null);
    for (final joint in Joint.values) {
      final base = joint.index * stride;
      final landmark = frame.landmarks[joint];
      if (landmark == null) continue;
      landmarks[base] = landmark.x;
      landmarks[base + 1] = landmark.y;
      landmarks[base + 2] = landmark.z;
      landmarks[base + 3] = landmark.visibility;
    }

    return <String, Object?>{
      'frameId': frame.frameId,
      'tUs': frame.t.inMicroseconds,
      'confidence': frame.confidence,
      'landmarks': landmarks,
    };
  }

  /// Accepts every float list the two senders can produce.
  ///
  /// Android's `StandardMessageCodec` delivers a `Float32List`, a 64-bit
  /// sender a `Float64List`, and a JSON fixture a list of numbers and
  /// `null`s. All three are the same contract, so all three decode: a `null`
  /// means the same as [absent], because a JSON file cannot write `NaN`.
  static Float64List _landmarkBuffer(Object? raw) {
    final List<num> values;
    if (raw is Float32List) {
      values = raw;
    } else if (raw is Float64List) {
      values = raw;
    } else if (raw is List) {
      values = [
        for (final value in raw)
          if (value == null)
            absent
          else if (value is num)
            value
          else
            throw FormatException(
              'landmarks: expected numbers, found ${value.runtimeType}',
            ),
      ];
    } else {
      throw FormatException(
        'landmarks: expected a float list, got ${raw.runtimeType}',
      );
    }

    if (values.length != bufferLength) {
      throw FormatException(
        'landmarks: expected $bufferLength values '
        '(33 joints x $stride), got ${values.length}',
      );
    }
    return Float64List.fromList([for (final value in values) value.toDouble()]);
  }

  static int _int(Map<Object?, Object?> message, String key) {
    final value = message[key];
    if (value is int) return value;
    throw FormatException('$key: expected an int, got ${value.runtimeType}');
  }

  static double _finiteDouble(Map<Object?, Object?> message, String key) {
    final value = message[key];
    if (value is num && value.isFinite) return value.toDouble();
    // NaN is singled out because every threshold comparison against it is
    // false, so a NaN confidence would quietly make "is this pose good
    // enough" answer no forever instead of failing.
    throw FormatException(
      '$key: expected a finite number, got ${value is num ? value : value.runtimeType}',
    );
  }
}
