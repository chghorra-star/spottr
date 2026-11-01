import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

/// The fixture format version.
///
/// Bumped when the shape changes in a way an older reader would get wrong.
/// The joint ordering inside each frame is the codec's contract and is not
/// versioned here.
const int fixtureVersion = 1;

/// Where a fixture's landmarks came from.
///
/// This is the most important field in the file. A suite that passes on
/// synthetic data has proved that the engine is internally consistent and
/// **nothing whatsoever** about accuracy on a real body, so the report
/// counts the two separately and never adds them together.
enum FixtureSource {
  /// Generated. No noise anybody did not ask for, no occlusion, no loose
  /// clothing, no tracking dropout except where a case puts it there.
  synthetic,

  /// Extracted from video of somebody actually training.
  recorded,
}

/// One labelled landmark sequence: a set, and what should have been counted.
@immutable
class PoseFixture {
  PoseFixture({
    required this.name,
    required this.exerciseId,
    required this.angle,
    required this.source,
    required this.notes,
    required this.frames,
    this.expectedReps,
    this.expectedHold,
  })  : assert(
          (expectedReps == null) != (expectedHold == null),
          'a fixture expects reps or a hold, never both and never neither',
        ),
        assert(frames.isNotEmpty, 'a fixture with no frames proves nothing');

  factory PoseFixture.fromJson(Map<String, Object?> json) {
    final version = json['fixtureVersion'];
    if (version != fixtureVersion) {
      throw FormatException(
        'fixtureVersion: expected $fixtureVersion, got $version. A fixture '
        'from another version may not order its landmarks the way this '
        'reader does.',
      );
    }

    final expected = json['expected'];
    if (expected is! Map) {
      throw const FormatException(
        'expected: a fixture has to say what should have been counted',
      );
    }
    final reps = expected['reps'];
    final holdMs = expected['holdMs'];
    if ((reps == null) == (holdMs == null)) {
      throw FormatException(
        'expected: one of reps or holdMs, got reps=$reps holdMs=$holdMs',
      );
    }

    final rawFrames = json['frames'];
    if (rawFrames is! List || rawFrames.isEmpty) {
      throw const FormatException('frames: a fixture needs frames');
    }

    final frames = <PoseFrame>[];
    for (final raw in rawFrames) {
      if (raw is! Map) {
        throw FormatException('frames: expected maps, got ${raw.runtimeType}');
      }
      final frame = PoseFrameCodec.decode(raw);
      if (frames.isNotEmpty && frame.t < frames.last.t) {
        throw FormatException(
          'frames: frame ${frame.frameId} at ${frame.t} comes after '
          '${frames.last.t}. Replay reads a fixture in order and the '
          'counters ignore a frame older than the last one, so a shuffled '
          'fixture would measure nothing and still report a number.',
        );
      }
      frames.add(frame);
    }

    return PoseFixture(
      name: _string(json, 'name'),
      exerciseId: _string(json, 'exerciseId'),
      angle: _enum(CameraAngle.values, json['angle'], 'angle'),
      source: _enum(FixtureSource.values, json['source'], 'source'),
      notes: json['notes'] as String? ?? '',
      expectedReps: reps == null ? null : (reps as num).toInt(),
      expectedHold: holdMs == null
          ? null
          : Duration(milliseconds: (holdMs as num).toInt()),
      frames: frames,
    );
  }

  /// Short, filename-shaped, and unique within a suite.
  final String name;

  /// The catalog entry this is a set of, which is what decides the counter.
  final String exerciseId;

  /// Where the phone was. A fixture recorded from the front is not a
  /// counter-example for a rule that needs the side.
  final CameraAngle angle;

  final FixtureSource source;

  /// What a human watching the video would want said about it: the fault
  /// being demonstrated, the clothing, the lighting, whatever explains a
  /// disagreement later.
  final String notes;

  /// The number of reps that should be counted, or `null` for a hold.
  final int? expectedReps;

  /// The time that should be accumulated, or `null` for a rep count.
  final Duration? expectedHold;

  final List<PoseFrame> frames;

  bool get isHold => expectedHold != null;

  /// Wall-clock length of the set.
  Duration get span => frames.last.t - frames.first.t;

  Map<String, Object?> toJson() => <String, Object?>{
        'fixtureVersion': fixtureVersion,
        'name': name,
        'exerciseId': exerciseId,
        'angle': angle.name,
        'source': source.name,
        'notes': notes,
        'expected': <String, Object?>{
          if (expectedReps != null) 'reps': expectedReps,
          if (expectedHold != null) 'holdMs': expectedHold!.inMilliseconds,
        },
        'frames': [
          for (final frame in frames) PoseFrameCodec.encodeJson(frame),
        ],
      };

  @override
  String toString() => 'PoseFixture($name, $exerciseId, ${angle.name}, '
      '${source.name}, ${frames.length} frames)';
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$key: expected a non-empty string, got $value');
}

T _enum<T extends Enum>(List<T> values, Object? raw, String key) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException(
    '$key: expected one of ${values.map((v) => v.name).join(', ')}, '
    'got $raw',
  );
}
