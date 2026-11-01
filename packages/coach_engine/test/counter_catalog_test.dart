import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

import 'support/frames.dart';

void main() {
  final catalog = ExerciseCatalog(standardExercises);

  group('counterCatalog', () {
    test('has a counter for every camera-supported exercise', () {
      // The thing that breaks when somebody adds a ninth camera exercise and
      // forgets the counter: the screen would open, the preview would run,
      // and nothing would ever count.
      final missing = [
        for (final exercise in catalog.all)
          if (exercise.camera != null &&
              !counterCatalog.containsKey(exercise.camera!.repCounterId))
            '${exercise.id} -> ${exercise.camera!.repCounterId}',
      ];

      expect(missing, isEmpty);
    });

    test('has no counter nothing refers to', () {
      final referenced = {
        for (final exercise in catalog.all)
          if (exercise.camera != null) exercise.camera!.repCounterId,
      };

      expect(counterCatalog.keys.toSet().difference(referenced), isEmpty);
    });

    test('keys its entries by their own ids', () {
      for (final entry in counterCatalog.entries) {
        expect(entry.value.id, entry.key);
      }
    });

    test('is valid', () {
      expect(validateCounters(catalog), isEmpty);
    });

    test('resolves a counter by exercise', () {
      expect(counterFor(catalog.require('bodyweight_squat')), isNotNull);
      expect(counterFor(catalog.require('plank')), isA<HoldCounterConfig>());
    });

    test('has no counter for an exercise the camera does not coach', () {
      final uncoached = catalog.all.firstWhere((e) => e.camera == null);

      expect(counterFor(uncoached), isNull);
    });
  });

  group('validateCounters', () {
    const signal = JointAngle(
      from: Joint.leftHip,
      vertex: Joint.leftKnee,
      to: Joint.leftAnkle,
    );

    /// The first thing wrong with [config] itself.
    ///
    /// A table holding one counter is missing the other seven, so the
    /// problems about this one are the ones that name it.
    CounterProblem? problemIn(CounterConfig config) =>
        validateCounters(catalog, counters: {config.id: config})
            .where((problem) => problem.counterId == config.id)
            .firstOrNull;

    test('rejects thresholds that contradict the direction', () {
      // A closing movement whose bottom is a larger angle than its top
      // measures negative depth all the way down and counts nothing. The
      // state machine has no way to notice; this is the only thing that can.
      final problem = problemIn(
        const RepCounterConfig(
          id: 'squat_knee_angle',
          signal: signal,
          direction: RepDirection.closing,
          topThreshold: 100,
          bottomThreshold: 160,
          minRangeOfMotion: 40,
        ),
      );

      expect(problem?.kind, CounterProblemKind.backwardsThresholds);
    });

    test('rejects a range of motion no rep could reach', () {
      final problem = problemIn(
        const RepCounterConfig(
          id: 'squat_knee_angle',
          signal: signal,
          direction: RepDirection.closing,
          topThreshold: 160,
          bottomThreshold: 100,
          minRangeOfMotion: 80,
        ),
      );

      expect(problem?.kind, CounterProblemKind.unreachableRange);
    });

    test('rejects a range of motion inside the noise floor', () {
      final problem = problemIn(
        const RepCounterConfig(
          id: 'squat_knee_angle',
          signal: signal,
          direction: RepDirection.closing,
          topThreshold: 160,
          bottomThreshold: 100,
          minRangeOfMotion: 6,
          hysteresis: 8,
        ),
      );

      expect(problem?.kind, CounterProblemKind.rangeBelowHysteresis);
    });

    test('rejects durations in the wrong order', () {
      final problem = problemIn(
        const RepCounterConfig(
          id: 'squat_knee_angle',
          signal: signal,
          direction: RepDirection.closing,
          topThreshold: 160,
          bottomThreshold: 100,
          minRangeOfMotion: 40,
          minRepDuration: Duration(seconds: 5),
          maxRepDuration: Duration(seconds: 2),
        ),
      );

      expect(problem?.kind, CounterProblemKind.backwardsDurations);
    });

    test('rejects a hold that holds everything', () {
      final problem = problemIn(
        const HoldCounterConfig(id: 'plank_hold', bands: []),
      );

      expect(problem?.kind, CounterProblemKind.noBands);
    });

    test('rejects a band that cannot be satisfied', () {
      final problem = problemIn(
        const HoldCounterConfig(
          id: 'plank_hold',
          bands: [SignalBand(signal: signal, min: 170, max: 150)],
        ),
      );

      expect(problem?.kind, CounterProblemKind.emptyBand);
    });

    test('reports a counter no exercise uses', () {
      final problem = problemIn(
        const HoldCounterConfig(
          id: 'handstand_hold',
          bands: [SignalBand(signal: signal, min: 150)],
        ),
      );

      expect(problem?.kind, CounterProblemKind.unreferenced);
    });
  });

  group('the launch counters', () {
    test('count a plausible rep of the exercise they are for', () {
      // Not an accuracy claim — that needs footage, and the harness says so.
      // This is the sanity check that a threshold pair nobody has tuned yet
      // is at least the right way round and reachable.
      for (final entry in counterCatalog.entries) {
        final config = entry.value;
        if (config is! RepCounterConfig) continue;

        final counter = RepCounter(config);
        final top = config.topThreshold;
        final bottom = config.bottomThreshold;
        var t = Duration.zero;
        for (final value in [
          top,
          top,
          (top + bottom) / 2,
          bottom,
          bottom,
          (top + bottom) / 2,
          top,
        ]) {
          counter.update(syntheticFrame(config.signal, value, t));
          t += const Duration(milliseconds: 150);
        }

        expect(
          counter.counted,
          1,
          reason: '${entry.key} did not count a full-range rep: '
              '${counter.ledger}',
        );
      }
    });
  });
}
