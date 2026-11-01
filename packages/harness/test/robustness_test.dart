import 'package:harness/harness.dart';
import 'package:test/test.dart';

RobustnessSweep of(List<RobustnessSweep> sweeps, String name) =>
    sweeps.firstWhere((sweep) => sweep.name == name);

void main() {
  group('sweepJitter', () {
    test('a clean set counts correctly with no noise on it at all', () {
      final sweeps = sweepJitter(ladder: const [0]);

      for (final sweep in sweeps) {
        expect(
          sweep.points.single.passed,
          isTrue,
          reason: '${sweep.name} is wrong before anything is done to it',
        );
      }
      expect(sweeps.map((sweep) => sweep.name), contains('squat'));
    });

    test('enough noise does break it', () {
      // A sweep whose ladder never breaks has measured nothing, which is
      // what the first version of this did.
      final squat = of(sweepJitter(ladder: const [0, 0.5]), 'squat');

      expect(squat.limit, 0);
      expect(squat.unbroken, isFalse);
    });

    test('the limit stops at the first failure, not the last success', () {
      // An engine that gets it right again after getting it wrong has not
      // earned the higher number, it has got lucky with a fixture.
      const sweep = RobustnessSweep(
        name: 'squat',
        parameter: 'jitter',
        unit: '',
        points: [
          RobustnessPoint(setting: 0, counted: 8, expected: 8, passed: true),
          RobustnessPoint(setting: 1, counted: 8, expected: 8, passed: true),
          RobustnessPoint(setting: 2, counted: 7, expected: 8, passed: false),
          RobustnessPoint(setting: 3, counted: 8, expected: 8, passed: true),
        ],
      );

      expect(sweep.limit, 1);
    });
  });

  group('sweepDrift', () {
    test('a tracker that wanders breaks counting sooner than one that is '
        'merely noisy', () {
      // The finding this sweep was added for. Landmark error is correlated
      // in time, a low-pass filter removes the uncorrelated kind, and the
      // kind it cannot remove is the kind that costs reps — so the suite
      // has to contain both or it is measuring the filter.
      const ladder = [0.0, 0.016, 0.032, 0.048, 0.064, 0.096, 0.128];
      final noisy = of(sweepJitter(ladder: ladder), 'push_up').limit!;
      final wandering = of(sweepDrift(ladder: ladder), 'push_up').limit!;

      expect(wandering, lessThan(noisy));
    });

    test('a clean set survives a wander it should not notice', () {
      final squat = of(sweepDrift(ladder: const [0, 0.004]), 'squat');

      expect(squat.limit, 0.004);
      expect(squat.unbroken, isTrue);
    });
  });

  group('sweepFrameRate', () {
    test('counting works at the rate the camera layer asks for', () {
      for (final sweep in sweepFrameRate(ladder: const [33])) {
        expect(sweep.points.single.passed, isTrue, reason: sweep.name);
      }
    });

    test('and goes on working well below it', () {
      // Worth knowing because nothing in this project has ever measured
      // what a real phone delivers, and the emulator manages three.
      final squat = of(sweepFrameRate(ladder: const [33, 100, 200]), 'squat');

      expect(squat.limit, 200);
    });
  });

  group('renderRobustness', () {
    final text = renderRobustness(
      sweepJitter(ladder: const [0, 0.004]),
      sweepDrift(ladder: const [0, 0.004]),
      sweepFrameRate(ladder: const [33, 100]),
    );

    test('reports all three, and says what they are not', () {
      expect(text, contains('Landmark noise'));
      expect(text, contains('Correlated wander'));
      expect(text, contains('Frame interval'));
      expect(text, contains('not a measurement of'));
      expect(text, contains('headroom'));
    });

    test('names every set it degraded', () {
      for (final name in cleanSets().keys) {
        expect(text, contains(name));
      }
    });
  });
}
