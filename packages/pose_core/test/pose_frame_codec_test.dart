import 'dart:typed_data';

import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

/// A wire buffer with every landmark at a distinct, recognisable position.
Float32List _buffer({
  double visibility = 1,
  Map<Joint, List<double>> overrides = const {},
}) {
  final buffer = Float32List(PoseFrameCodec.bufferLength);
  for (final joint in Joint.values) {
    final base = joint.index * PoseFrameCodec.stride;
    final values = overrides[joint] ??
        [joint.index / 100, joint.index / 50, joint.index / 200, visibility];
    for (var i = 0; i < PoseFrameCodec.stride; i++) {
      buffer[base + i] = values[i];
    }
  }
  return buffer;
}

Map<Object?, Object?> _message({
  int frameId = 7,
  int tUs = 1500000,
  Object confidence = 0.9,
  Object? landmarks,
}) =>
    <Object?, Object?>{
      'frameId': frameId,
      'tUs': tUs,
      'confidence': confidence,
      'landmarks': landmarks ?? _buffer(),
    };

void main() {
  group('PoseFrameCodec wire shape', () {
    test('the buffer is 33 landmarks of 4 values each', () {
      expect(PoseFrameCodec.stride, 4);
      expect(PoseFrameCodec.bufferLength, Joint.values.length * 4);
      expect(PoseFrameCodec.bufferLength, 132);
    });

    test('reads landmarks at their BlazePose ordinal', () {
      final frame = PoseFrameCodec.decode(_message());

      // leftKnee is joint 25, so its x sits at 25 * 4.
      expect(frame.landmarks[Joint.leftKnee]!.x, closeTo(0.25, 1e-6));
      expect(frame.landmarks[Joint.leftKnee]!.y, closeTo(0.50, 1e-6));
      expect(frame.landmarks[Joint.nose]!.x, closeTo(0, 1e-6));
      expect(frame.landmarks[Joint.rightFootIndex]!.x, closeTo(0.32, 1e-6));
    });

    test('carries the frame id, timestamp and confidence', () {
      final frame = PoseFrameCodec.decode(
        _message(frameId: 42, tUs: 2500000, confidence: 0.75),
      );

      expect(frame.frameId, 42);
      expect(frame.t, const Duration(milliseconds: 2500));
      expect(frame.confidence, closeTo(0.75, 1e-9));
    });

    test('round-trips through encode', () {
      final original = PoseFrameCodec.decode(_message());
      final again = PoseFrameCodec.decode(PoseFrameCodec.encode(original));

      expect(again.frameId, original.frameId);
      expect(again.t, original.t);
      expect(again.confidence, closeTo(original.confidence, 1e-6));
      expect(again.landmarks.keys, original.landmarks.keys);
      for (final joint in original.landmarks.keys) {
        expect(
          again.landmarks[joint]!.x,
          closeTo(original.landmarks[joint]!.x, 1e-6),
        );
        expect(
          again.landmarks[joint]!.y,
          closeTo(original.landmarks[joint]!.y, 1e-6),
        );
      }
    });

    test('encodes a buffer of exactly the contract length', () {
      final frame = PoseFrameCodec.decode(_message());
      final encoded = PoseFrameCodec.encode(frame);

      expect(encoded['landmarks'], isA<Float32List>());
      expect(
        (encoded['landmarks']! as Float32List).length,
        PoseFrameCodec.bufferLength,
      );
    });
  });

  group('PoseFrameCodec absent landmarks', () {
    test('a NaN position means the model placed no landmark there', () {
      final frame = PoseFrameCodec.decode(
        _message(
          landmarks: _buffer(
            overrides: {
              Joint.leftAnkle: [double.nan, double.nan, 0, 0],
            },
          ),
        ),
      );

      expect(frame.landmarks.containsKey(Joint.leftAnkle), isFalse);
      expect(frame.landmarks.containsKey(Joint.rightAnkle), isTrue);
      expect(frame.point(Joint.leftAnkle), isNull);
    });

    test('a low-confidence landmark is still reported, not dropped', () {
      // Dropping it here would take the decision away from the caller:
      // form rules choose their own visibility floor, and a rule that wants
      // to know a joint is being tracked badly cannot ask if it is gone.
      final frame = PoseFrameCodec.decode(
        _message(
          landmarks: _buffer(
            overrides: {
              Joint.leftAnkle: [0.3, 0.9, 0, 0.05],
            },
          ),
        ),
      );

      expect(frame.landmarks[Joint.leftAnkle]!.visibility, closeTo(0.05, 1e-6));
      expect(frame.point(Joint.leftAnkle), isNull);
    });
  });

  group('PoseFrameCodec tolerates the float boundary', () {
    test('clamps a visibility that arrives just outside 0..1', () {
      // Float32 rounding and ML Kit's own arithmetic both produce values a
      // hair outside the documented range. Landmark asserts on it, so an
      // unclamped decoder would kill the stream on a perfectly good frame.
      final frame = PoseFrameCodec.decode(
        _message(
          landmarks: _buffer(
            overrides: {
              Joint.leftWrist: [0.2, 0.3, 0, 1.0000002],
              Joint.rightWrist: [0.8, 0.3, 0, -0.0000002],
            },
          ),
        ),
      );

      expect(frame.landmarks[Joint.leftWrist]!.visibility, 1.0);
      expect(frame.landmarks[Joint.rightWrist]!.visibility, 0.0);
    });

    test('clamps pose confidence the same way', () {
      expect(
        PoseFrameCodec.decode(_message(confidence: 1.0000002)).confidence,
        1.0,
      );
    });
  });

  group('PoseFrameCodec accepts what the channels actually deliver', () {
    test('a Map<Object?, Object?>, which is what Android sends', () {
      // The platform channel hands over Map<Object?, Object?>, never
      // Map<String, dynamic>. A decoder typed for the latter compiles and
      // then throws at runtime on the first frame.
      final Map<Object?, Object?> raw = _message();
      expect(PoseFrameCodec.decode(raw).frameId, 7);
    });

    test('a Float64List, which is what a 64-bit sender would send', () {
      final wide = Float64List.fromList(_buffer());
      expect(
        PoseFrameCodec.decode(_message(landmarks: wide))
            .landmarks[Joint.leftKnee]!
            .x,
        closeTo(0.25, 1e-6),
      );
    });

    test('a plain List<num>, which is what a JSON fixture decodes to', () {
      final list = _buffer().toList();
      expect(
        PoseFrameCodec.decode(_message(landmarks: list))
            .landmarks[Joint.leftKnee]!
            .x,
        closeTo(0.25, 1e-6),
      );
    });

    test('a confidence sent as an int', () {
      expect(PoseFrameCodec.decode(_message(confidence: 1)).confidence, 1.0);
    });
  });

  group('PoseFrameCodec rejects a malformed frame', () {
    test('a buffer of the wrong length', () {
      expect(
        () => PoseFrameCodec.decode(_message(landmarks: Float32List(100))),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('132'), contains('100')),
          ),
        ),
      );
    });

    test('a missing key', () {
      final raw = _message()..remove('frameId');
      expect(
        () => PoseFrameCodec.decode(raw),
        throwsA(
          isA<FormatException>()
              .having((e) => e.message, 'message', contains('frameId')),
        ),
      );
    });

    test('a value of the wrong type', () {
      final raw = _message()..['landmarks'] = 'nope';
      expect(() => PoseFrameCodec.decode(raw), throwsFormatException);
    });

    test('a non-finite confidence', () {
      // A NaN threshold comparison is always false, so a NaN confidence
      // would quietly make every "is the pose good enough" check fail open.
      final raw = _message()..['confidence'] = double.nan;
      expect(() => PoseFrameCodec.decode(raw), throwsFormatException);
    });
  });
}
