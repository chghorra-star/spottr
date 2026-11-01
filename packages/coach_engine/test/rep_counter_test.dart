import 'package:coach_engine/coach_engine.dart';
import 'package:test/test.dart';

import 'support/frames.dart';

/// A squat-shaped counter. Deliberately not the catalog's: these tests are
/// about the state machine, and reading them should not require knowing what
/// a real squat's thresholds happen to be this week.
const squat = RepCounterConfig(
  id: 'test_squat',
  signal: kneeSignal,
  direction: RepDirection.closing,
  topThreshold: 160,
  bottomThreshold: 100,
  minRangeOfMotion: 40,
  hysteresis: 8,
  minRepDuration: Duration(milliseconds: 500),
  maxRepDuration: Duration(seconds: 8),
);

/// Feeds one angle per 100ms. A null angle is a frame with nothing tracked.
List<RepTick> drive(
  RepCounter counter,
  List<double?> angles, {
  Duration step = const Duration(milliseconds: 100),
  Duration from = Duration.zero,
}) {
  final ticks = <RepTick>[];
  for (var i = 0; i < angles.length; i++) {
    final angle = angles[i];
    ticks.add(
      counter.update(
        frame(
          angle == null ? const {} : legs(angle),
          id: i,
          t: from + step * i,
        ),
      ),
    );
  }
  return ticks;
}

/// One rep: at the top, down to [bottom], and back up.
List<double> rep({double bottom = 95, double top = 160}) => [
      top,
      top,
      (top + bottom) / 2,
      bottom,
      bottom,
      (top + bottom) / 2,
      top,
    ];

List<RepEvent> completed(List<RepTick> ticks) =>
    [for (final tick in ticks) if (tick.completed != null) tick.completed!];

void main() {
  group('RepCounter', () {
    test('counts a full rep once it comes back to the top', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, rep());

      expect(counter.counted, 1);
      expect(completed(ticks), hasLength(1));
      expect(completed(ticks).single.outcome, RepOutcome.counted);
      expect(ticks.last.phase, RepPhase.top);
    });

    test('counts nothing while the user is still at the bottom', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [160, 160, 130, 95, 95, 95]);

      expect(counter.counted, 0);
      expect(completed(ticks), isEmpty);
      expect(ticks.last.phase, RepPhase.bottom);
    });

    test('counts two reps as two', () {
      final counter = RepCounter(squat);
      drive(counter, [...rep(), ...rep().skip(1)]);

      expect(counter.counted, 2);
      expect(counter.ledger.map((event) => event.index), [1, 2]);
    });

    test('does not count a rep it joined half way through', () {
      // The screen starts when the user taps start, which is not the same
      // moment they stand up. A machine that treated its first frame as the
      // top would hand out a free rep to anyone who began mid-squat.
      final counter = RepCounter(squat);
      final ticks = drive(counter, [95, 95, 130, 160, 160]);

      expect(counter.counted, 0);
      expect(completed(ticks), isEmpty);
      expect(ticks.last.phase, RepPhase.top);
    });

    test('counts the rep after the one it joined half way through', () {
      final counter = RepCounter(squat);
      drive(counter, [95, 130, 160, ...rep().skip(1)]);

      expect(counter.counted, 1);
    });

    test('reports a partial rep rather than swallowing it', () {
      // A counter that silently ignores a rep reads as broken, so every
      // attempt lands in the ledger with a reason.
      final counter = RepCounter(squat);
      final ticks = drive(counter, rep(bottom: 135));
      final event = completed(ticks).single;

      expect(counter.counted, 0);
      expect(event.outcome, RepOutcome.notCounted);
      expect(event.fault, RepFault.partialRange);
      expect(counter.ledger, hasLength(1));
    });

    test('counts a shallow rep and says it was shallow', () {
      // Past the acceptance bar but short of full depth: the three outcomes
      // are counted, counted with a warning, and not counted, and this is
      // the middle one.
      final counter = RepCounter(squat);
      final event = completed(drive(counter, rep(bottom: 115))).single;

      expect(counter.counted, 1);
      expect(event.outcome, RepOutcome.countedWithWarning);
      expect(event.fault, RepFault.shallow);
    });

    test('does not count a rep faster than a rep can be', () {
      final counter = RepCounter(squat);
      final event = completed(drive(counter, [160, 95, 160])).single;

      expect(event.outcome, RepOutcome.notCounted);
      expect(event.fault, RepFault.tooFast);
      expect(counter.counted, 0);
    });

    test('ignores a wobble at the top', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [160, 155, 160, 154, 160, 157]);

      expect(completed(ticks), isEmpty);
      expect(ticks.every((tick) => tick.phase == RepPhase.top), isTrue);
    });

    test('does not split one rep in two over a wobble on the way up', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [
        160,
        160,
        130,
        95,
        110,
        100,
        115,
        140,
        160,
      ]);

      expect(completed(ticks), hasLength(1));
      expect(counter.counted, 1);
    });

    test('abandons a rep nobody finished', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [160, 160, ...List.filled(100, 95.0)]);
      final event = completed(ticks).single;

      expect(event.outcome, RepOutcome.notCounted);
      expect(event.fault, RepFault.timedOut);
      expect(counter.counted, 0);
    });

    test('needs the top again after abandoning one', () {
      final counter = RepCounter(squat);
      drive(counter, [160, 160, ...List.filled(100, 95.0)]);
      // Still at the bottom. Standing up is not a rep.
      final after = drive(
        counter,
        [95, 130, 160],
        from: const Duration(seconds: 20),
      );

      expect(completed(after), isEmpty);
      expect(counter.counted, 0);
    });

    test('abandons a rep when it loses the joints it needs', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [
        160,
        160,
        130,
        95,
        null,
        null,
        null,
        null,
        null,
        null,
      ]);
      final event = completed(ticks).single;

      expect(event.outcome, RepOutcome.notCounted);
      expect(event.fault, RepFault.lostTracking);
    });

    test('rides out a gap too short to worry about', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [160, 160, 130, 95, null, 95, 130, 160]);

      expect(completed(ticks).single.outcome, RepOutcome.counted);
    });

    test('says nothing is tracked while nothing is tracked', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [null, null]);

      expect(ticks.every((tick) => tick.tracking), isFalse);
      expect(ticks.last.phase, RepPhase.idle);
    });

    test('moves through the phases in order', () {
      final counter = RepCounter(squat);
      final phases = drive(counter, rep()).map((tick) => tick.phase).toList();

      expect(phases.first, RepPhase.top);
      expect(phases, contains(RepPhase.descending));
      expect(phases, contains(RepPhase.bottom));
      expect(phases, contains(RepPhase.ascending));
      expect(
        phases.indexOf(RepPhase.descending),
        lessThan(phases.indexOf(RepPhase.bottom)),
      );
      expect(
        phases.indexOf(RepPhase.bottom),
        lessThan(phases.indexOf(RepPhase.ascending)),
      );
    });

    test('reports how far into the rep the user is', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [160, 130, 100]);

      expect(ticks.first.depth, closeTo(0, 1));
      expect(ticks[1].depth, closeTo(30, 1));
      expect(ticks.last.depth, closeTo(60, 1));
    });

    test('measures the rep it counted', () {
      final counter = RepCounter(squat);
      final event = completed(drive(counter, rep(bottom: 95))).single;

      expect(event.peakAngle, closeTo(95, 1));
      expect(event.rangeOfMotion, closeTo(65, 1));
      expect(event.duration, const Duration(milliseconds: 500));
      expect(event.descent + event.ascent, event.duration);
      expect(event.descent, const Duration(milliseconds: 300));
    });

    test('measures a rep that opens rather than closes', () {
      // A glute bridge's hip angle grows through the working phase. Nothing
      // in the machine knows which way round a movement is; the config does.
      const bridge = RepCounterConfig(
        id: 'test_bridge',
        signal: kneeSignal,
        direction: RepDirection.opening,
        topThreshold: 120,
        bottomThreshold: 170,
        minRangeOfMotion: 30,
        hysteresis: 8,
        minRepDuration: Duration(milliseconds: 500),
        maxRepDuration: Duration(seconds: 8),
      );
      final counter = RepCounter(bridge);
      final event = completed(
        drive(counter, [120, 120, 145, 170, 170, 145, 120]),
      ).single;

      expect(counter.counted, 1);
      expect(event.outcome, RepOutcome.counted);
      expect(event.peakAngle, closeTo(170, 1));
      expect(event.rangeOfMotion, closeTo(50, 1));
    });

    test('ignores a frame from before the one it just read', () {
      final counter = RepCounter(squat);
      drive(counter, [160, 160, 130]);
      final late = counter.update(
        frame(legs(95), id: 99, t: const Duration(milliseconds: 50)),
      );

      expect(late.depth, closeTo(30, 1));
      expect(late.phase, RepPhase.descending);
    });

    test('starts over on reset', () {
      final counter = RepCounter(squat);
      drive(counter, rep());
      counter.reset();

      expect(counter.counted, 0);
      expect(counter.ledger, isEmpty);
      expect(counter.tick.phase, RepPhase.idle);
    });

    test('keeps every attempt in the ledger, counted or not', () {
      final counter = RepCounter(squat);
      drive(counter, [
        ...rep(),
        ...rep(bottom: 135).skip(1),
        ...rep().skip(1),
      ]);

      expect(counter.counted, 2);
      expect(counter.ledger, hasLength(3));
      expect(
        counter.ledger.map((event) => event.outcome),
        [RepOutcome.counted, RepOutcome.notCounted, RepOutcome.counted],
      );
      expect(counter.ledger.map((event) => event.index), [1, 2, 3]);
    });

    test('measures travel from where the user was resting, not from the '
        'tolerance band', () {
      // The user stands at 175 and squats to 95: they travelled 80 degrees.
      // Measuring from the last frame judged "at the top" instead would
      // start the tape at the edge of the hysteresis band and quietly lose
      // it, which makes minRangeOfMotion mean something other than what it
      // says and pulls the shallow-rep boundary in with it.
      final counter = RepCounter(squat);
      final event = completed(
        drive(counter, [175, 175, 175, 135, 95, 95, 135, 175]),
      ).single;

      expect(event.rangeOfMotion, closeTo(80, 1));
      expect(event.outcome, RepOutcome.counted);
    });

    test('measures travel from the deepest rest, not the shallowest', () {
      // Somebody shifting their weight at the top rests at several depths.
      // The one the rep started from is the one they were standing at.
      final counter = RepCounter(squat);
      final event = completed(
        drive(counter, [175, 168, 172, 135, 95, 95, 135, 175]),
      ).single;

      expect(event.rangeOfMotion, closeTo(80, 2));
    });

    test('keeps the last attempt on the tick after the frame it finished on',
        () {
      // A screen rebuilt from the latest tick can miss the one frame an
      // attempt landed on: the camera runs at 30Hz and the UI redraws when
      // it gets round to it, so an edge-only report is a verdict the user
      // never sees. The edge stays for anything listening to every frame;
      // the standing value is for anything reading the newest one.
      final counter = RepCounter(squat);
      final ticks = drive(counter, [...rep(), 160, 160, 160]);
      final finishedOn = ticks.indexWhere((tick) => tick.completed != null);

      expect(finishedOn, isNot(-1));
      expect(ticks[finishedOn].last, ticks[finishedOn].completed);
      expect(ticks.last.completed, isNull);
      expect(ticks.last.last, isNotNull);
      expect(ticks.last.last!.outcome, RepOutcome.counted);
    });

    test('has no last attempt before the first one finishes', () {
      final counter = RepCounter(squat);
      final ticks = drive(counter, [160, 160, 130]);

      expect(ticks.last.last, isNull);
    });

    test('forgets the last attempt on reset', () {
      final counter = RepCounter(squat);
      drive(counter, rep());
      counter.reset();

      expect(counter.tick.last, isNull);
    });
  });
}
