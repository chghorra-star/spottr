import 'package:coach_engine/coach_engine.dart';
import 'package:test/test.dart';

import 'support/frames.dart';

/// A plank-shaped hold: hips in line, body horizontal.
const plank = HoldCounterConfig(
  id: 'test_plank',
  bands: [
    SignalBand(signal: hipSignal, min: 155),
    SignalBand(signal: trunkSignal, min: 60, max: 120),
  ],
);

/// Frames at 100ms intervals. A null posture is a frame with nothing in it.
List<HoldTick> drive(
  HoldCounter counter,
  List<({double tilt, double hip})?> postures, {
  Duration step = const Duration(milliseconds: 100),
}) {
  final ticks = <HoldTick>[];
  for (var i = 0; i < postures.length; i++) {
    final posture = postures[i];
    ticks.add(
      counter.update(
        frame(
          posture == null
              ? const {}
              : torso(tilt: posture.tilt, hipAngle: posture.hip),
          id: i,
          t: step * i,
        ),
      ),
    );
  }
  return ticks;
}

const held = (tilt: 90.0, hip: 178.0);
const sagging = (tilt: 90.0, hip: 140.0);
const standing = (tilt: 180.0, hip: 178.0);

void main() {
  group('HoldCounter', () {
    test('does not start the clock on the frame it first sees', () {
      // One frame is a position, not a duration.
      final counter = HoldCounter(plank);
      final ticks = drive(counter, [held]);

      expect(ticks.single.held, Duration.zero);
      expect(ticks.single.accumulating, isTrue);
    });

    test('accumulates the time between frames in position', () {
      final counter = HoldCounter(plank);
      final ticks = drive(counter, List.filled(10, held));

      expect(ticks.last.held, const Duration(milliseconds: 900));
    });

    test('stops the clock when the posture breaks, and says why', () {
      final counter = HoldCounter(plank);
      final ticks = drive(counter, [held, held, sagging]);

      expect(ticks.last.accumulating, isFalse);
      expect(ticks.last.pause, HoldPause.outOfPosition);
      expect(ticks.last.tracking, isTrue);
    });

    test('keeps what it has already held through a break', () {
      final counter = HoldCounter(plank);
      final ticks = drive(counter, [held, held, sagging, held]);

      expect(ticks.last.held, const Duration(milliseconds: 100));
    });

    test('does not count the interval that spans a break', () {
      final counter = HoldCounter(plank);
      final ticks = drive(counter, [held, held, sagging, held, held]);

      // 0 to 100 and 300 to 400, never 100 to 300.
      expect(ticks.last.held, const Duration(milliseconds: 200));
    });

    test('stops the clock when it cannot see the body', () {
      final counter = HoldCounter(plank);
      final ticks = drive(counter, [held, held, null]);

      expect(ticks.last.pause, HoldPause.untracked);
      expect(ticks.last.tracking, isFalse);
      expect(ticks.last.held, const Duration(milliseconds: 100));
    });

    test('does not accumulate across a gap it would have to guess across', () {
      final counter = HoldCounter(plank);
      counter.update(frame(torso(tilt: 90, hipAngle: 178)));
      counter.update(
        frame(
          torso(tilt: 90, hipAngle: 178),
          t: const Duration(milliseconds: 100),
        ),
      );
      final afterGap = counter.update(
        frame(
          torso(tilt: 90, hipAngle: 178),
          t: const Duration(milliseconds: 600),
        ),
      );

      expect(afterGap.held, const Duration(milliseconds: 100));
      expect(afterGap.accumulating, isTrue);
    });

    test('tells a plank from somebody standing still', () {
      // The hip angle is the same for both. Without the trunk band, a hold
      // would run while the user stood there reading their phone.
      final counter = HoldCounter(plank);
      final ticks = drive(counter, [standing, standing]);

      expect(ticks.last.held, Duration.zero);
      expect(ticks.last.pause, HoldPause.outOfPosition);
    });

    test('ignores a frame from before the one it just read', () {
      final counter = HoldCounter(plank);
      drive(counter, [held, held]);
      final late = counter.update(
        frame(
          torso(tilt: 90, hipAngle: 178),
          t: const Duration(milliseconds: 50),
        ),
      );

      expect(late.held, const Duration(milliseconds: 100));
    });

    test('starts over on reset', () {
      final counter = HoldCounter(plank);
      drive(counter, List.filled(5, held));
      counter.reset();

      expect(counter.held, Duration.zero);
      expect(counter.tick.held, Duration.zero);
    });
  });

  group('SetCounter.of', () {
    test('builds the counter the configuration asks for', () {
      expect(SetCounter.of(plank), isA<HoldCounter>());
      expect(
        SetCounter.of(
          const RepCounterConfig(
            id: 'test_rep',
            signal: kneeSignal,
            direction: RepDirection.closing,
            topThreshold: 160,
            bottomThreshold: 100,
            minRangeOfMotion: 40,
          ),
        ),
        isA<RepCounter>(),
      );
    });
  });
}
