import 'package:coach_engine/coach_engine.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

import 'support/frames.dart';

const squat = RepCounterConfig(
  id: 'test_squat',
  signal: kneeSignal,
  direction: RepDirection.closing,
  topThreshold: 160,
  bottomThreshold: 100,
  minRangeOfMotion: 40,
  minRepDuration: Duration(milliseconds: 500),
);

Stream<PoseFrame> frames(List<double> angles) => Stream.fromIterable([
      for (var i = 0; i < angles.length; i++)
        frame(legs(angles[i]), id: i, t: Duration(milliseconds: i * 100)),
    ]);

const oneRep = <double>[160, 160, 130, 95, 95, 130, 160];

void main() {
  group('CounterStream', () {
    test('counts a set off a frame stream', () async {
      final ticks = await frames(oneRep)
          .transform(const CounterStream(squat))
          .cast<RepTick>()
          .toList();

      expect(ticks, hasLength(oneRep.length));
      expect(ticks.last.counted, 1);
      expect(
        ticks.where((tick) => tick.completed != null).single.completed!.outcome,
        RepOutcome.counted,
      );
    });

    test('gives every subscription its own set', () async {
      // Two listeners are two sets, not one set counted twice. The same
      // mistake in the smoothing filter would have every listener sharing
      // one filter's history.
      const transformer = CounterStream(squat);
      final first = await frames(oneRep).transform(transformer).toList();
      final second = await frames(oneRep).transform(transformer).toList();

      expect((first.last as RepTick).counted, 1);
      expect((second.last as RepTick).counted, 1);
    });

    test('runs a hold off the same seam', () async {
      const plank = HoldCounterConfig(
        id: 'test_plank',
        bands: [SignalBand(signal: hipSignal, min: 155)],
      );
      final held = Stream.fromIterable([
        for (var i = 0; i < 5; i++)
          frame(
            torso(tilt: 90, hipAngle: 178),
            id: i,
            t: Duration(milliseconds: i * 100),
          ),
      ]);

      final ticks = await held.transform(const CounterStream(plank)).toList();

      expect(
        (ticks.last as HoldTick).held,
        const Duration(milliseconds: 400),
      );
    });
  });
}
