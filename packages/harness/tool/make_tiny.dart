import 'package:harness/harness.dart';
import 'package:pose_core/pose_core.dart';

/// Writes the one fixture that is committed as a file rather than generated,
/// so the on-disk format is tested against a file and not only against the
/// writer that produced it.
void main() {
  final squat = syntheticSuite().firstWhere((f) => f.name == 'squat_clean_8');
  final frames = <PoseFrame>[];
  for (var i = 0; i < 4; i++) {
    final source = squat.frames[i * 10];
    final landmarks = {...source.landmarks};
    // One frame with a leg the model lost, because a fixture that never
    // says "nothing here" would not exercise the part of the format that
    // has to say it.
    if (i == 2) landmarks.remove(Joint.leftAnkle);
    frames.add(
      PoseFrame(
        frameId: i,
        t: Duration(milliseconds: i * 33),
        landmarks: landmarks,
        confidence: source.confidence,
      ),
    );
  }

  final file = writeFixture(
    PoseFixture(
      name: 'tiny_squat',
      exerciseId: 'bodyweight_squat',
      angle: CameraAngle.side,
      source: FixtureSource.synthetic,
      notes: 'four frames, one with an ankle the model lost. Committed so '
          'the loader is tested against a file.',
      expectedReps: 0,
      frames: frames,
    ),
    'test/fixtures',
  );
  print('wrote ${file.path} (${file.lengthSync()} bytes)');
}
