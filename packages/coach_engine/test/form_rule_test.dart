import 'package:coach_engine/coach_engine.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

const _knee = JointAngle(
  from: Joint.leftHip,
  vertex: Joint.leftKnee,
  to: Joint.leftAnkle,
);

const _hipOffset = JointOffset(
  joint: Joint.leftHip,
  from: Joint.leftShoulder,
  to: Joint.leftKnee,
);

const _trunk = SegmentTilt(from: Joint.leftShoulder, to: Joint.leftHip);

/// A window over a rep, built from the series a rule reads rather than from
/// frames.
///
/// A rule is arithmetic over samples, so the tests give it samples. What
/// turns frames into samples is the analyzer, and it has tests of its own.
RuleWindow window(
  Map<PoseSignal, List<double?>> samples, {
  int? peak,
  RepEvent? event,
  List<RepEvent> set = const [],
}) {
  final length = samples.values
      .fold<int>(0, (longest, series) => series.length > longest ? series.length : longest);

  return RuleWindow(
    samples: samples,
    times: [
      for (var i = 0; i < length; i++) Duration(milliseconds: 33 * i),
    ],
    peakIndex: peak,
    event: event,
    set: set,
  );
}

RepEvent rep({
  int index = 1,
  RepOutcome outcome = RepOutcome.counted,
  RepFault? fault,
  double rangeOfMotion = 60,
  Duration duration = const Duration(milliseconds: 1800),
  Duration descent = const Duration(milliseconds: 900),
}) =>
    RepEvent(
      index: index,
      outcome: outcome,
      fault: fault,
      duration: duration,
      descent: descent,
      ascent: duration - descent,
      peakAngle: 100,
      rangeOfMotion: rangeOfMotion,
    );

void main() {
  group('SignalBoundRule', () {
    const depth = SignalBoundRule(
      id: 'squat_depth',
      severity: RuleSeverity.minor,
      signal: _knee,
      at: RepSample.peak,
      max: 100,
    );

    test('passes when the deepest point is inside the bound', () {
      final result = depth.evaluate(
        window({_knee: const [170, 140, 95, 140, 170]}, peak: 2),
      );

      expect(result, RuleOutcome.pass);
    });

    test('fails when the deepest point falls short of it', () {
      final result = depth.evaluate(
        window({_knee: const [170, 150, 128, 150, 170]}, peak: 2),
      );

      expect(result, RuleOutcome.fail);
    });

    test('reads the top of the rep when that is what it is told to read', () {
      const lockout = SignalBoundRule(
        id: 'lockout',
        severity: RuleSeverity.minor,
        signal: _knee,
        at: RepSample.top,
        min: 160,
      );

      // Back at the top, but never straightened out: the last frame is the
      // one the counter judged to be the end of the rep.
      final result = lockout.evaluate(
        window({_knee: const [170, 120, 95, 120, 148]}, peak: 2),
      );

      expect(result, RuleOutcome.fail);
    });

    test('cannot answer when the signal was never tracked', () {
      final result = depth.evaluate(
        window({_knee: const [null, null, null]}, peak: 1),
      );

      expect(result, RuleOutcome.notVisible);
    });

    test('cannot answer when the sample it needs is the one missing', () {
      // Tracked for most of the rep and lost at exactly the bottom, which
      // is the one frame this rule is about.
      final result = depth.evaluate(
        window({_knee: const [170, 140, null, 140, 170]}, peak: 2),
      );

      expect(result, RuleOutcome.notVisible);
    });

    test('cannot answer about a window with no deepest point', () {
      // A hold has no peak. A depth rule applied to one is a configuration
      // mistake, and saying "unchecked" is how it surfaces instead of
      // quietly passing.
      final result = depth.evaluate(
        window({_knee: const [170, 170, 170]}),
      );

      expect(result, RuleOutcome.notVisible);
    });
  });

  group('SignalHoldRule', () {
    const sag = SignalHoldRule(
      id: 'hip_sag',
      severity: RuleSeverity.major,
      signal: _hipOffset,
      max: 6,
    );

    test('passes when the signal stays inside the band all the way', () {
      expect(
        sag.evaluate(window({_hipOffset: const [1, 2, 3, 2, 1]})),
        RuleOutcome.pass,
      );
    });

    test('passes when a frame or two strays', () {
      // Landmark noise puts a frame outside any band eventually. A rule
      // that fired on one frame would fire on every rep.
      expect(
        sag.evaluate(
          window({
            _hipOffset: const [1, 2, 9, 2, 1, 2, 1, 2, 1, 2, 1, 2],
          }),
        ),
        RuleOutcome.pass,
      );
    });

    test('fails when the signal is outside the band for most of the rep', () {
      expect(
        sag.evaluate(
          window({_hipOffset: const [1, 9, 11, 12, 11, 9, 2]}),
        ),
        RuleOutcome.fail,
      );
    });

    test('judges only the frames it could see', () {
      // Eight tracked frames, every one of them in position, and four the
      // model lost. A dropout is not a violation.
      expect(
        sag.evaluate(
          window({
            _hipOffset: const [
              1, 2, 1, 2, 1, 2, 1, 2,
              null, null, null, null,
            ],
          }),
        ),
        RuleOutcome.pass,
      );
    });

    test('cannot answer when it saw too little of the rep', () {
      expect(
        sag.evaluate(
          window({
            _hipOffset: const [1, null, null, null, null, null],
          }),
        ),
        RuleOutcome.notVisible,
      );
    });

    test('a band open at the bottom still catches the top', () {
      const pike = SignalHoldRule(
        id: 'hip_pike',
        severity: RuleSeverity.minor,
        signal: _hipOffset,
        min: -8,
      );

      expect(
        pike.evaluate(window({_hipOffset: const [-12, -14, -13, -12]})),
        RuleOutcome.fail,
      );
      expect(
        pike.evaluate(window({_hipOffset: const [12, 14, 13, 12]})),
        RuleOutcome.pass,
      );
    });
  });

  group('SignalTravelRule', () {
    const swing = SignalTravelRule(
      id: 'torso_swing',
      severity: RuleSeverity.major,
      signal: _trunk,
      max: 15,
    );

    test('passes a signal that barely moves', () {
      expect(
        swing.evaluate(window({_trunk: const [120, 123, 119, 121]})),
        RuleOutcome.pass,
      );
    });

    test('fails a signal that swings further than the bound', () {
      expect(
        swing.evaluate(window({_trunk: const [120, 135, 150, 128]})),
        RuleOutcome.fail,
      );
    });

    test('measures travel, not position', () {
      // Bent right over and perfectly still. Where the torso is, is
      // another rule's business.
      expect(
        swing.evaluate(window({_trunk: const [95, 96, 95, 94]})),
        RuleOutcome.pass,
      );
    });

    test('cannot answer from one sample', () {
      expect(
        swing.evaluate(window({_trunk: const [120, null, null, null]})),
        RuleOutcome.notVisible,
      );
    });
  });

  group('RangeConsistencyRule', () {
    const rom = RangeConsistencyRule(
      id: 'rom',
      severity: RuleSeverity.major,
    );

    test('passes the first rep of a set', () {
      // Nothing to compare it with, so there is no evidence of anything
      // getting shorter. Not "unchecked": the rule ran and found nothing
      // wrong.
      expect(
        rom.evaluate(window(const {}, event: rep(rangeOfMotion: 40))),
        RuleOutcome.pass,
      );
    });

    test('passes a rep as long as the best one so far', () {
      expect(
        rom.evaluate(
          window(
            const {},
            event: rep(index: 4, rangeOfMotion: 62),
            set: [
              rep(rangeOfMotion: 60),
              rep(index: 2, rangeOfMotion: 64),
              rep(index: 3, rangeOfMotion: 61),
            ],
          ),
        ),
        RuleOutcome.pass,
      );
    });

    test('fails a rep much shorter than the user was managing', () {
      // The rule nobody has to tune: it compares the user with themselves
      // ten seconds ago, so it needs no threshold in degrees at all.
      expect(
        rom.evaluate(
          window(
            const {},
            event: rep(index: 4, rangeOfMotion: 44),
            set: [
              rep(rangeOfMotion: 60),
              rep(index: 2, rangeOfMotion: 64),
              rep(index: 3, rangeOfMotion: 61),
            ],
          ),
        ),
        RuleOutcome.fail,
      );
    });

    test('takes its reference from reps that counted', () {
      // A bounced attempt that travelled further than any real rep is not
      // the standard the real ones are held to.
      expect(
        rom.evaluate(
          window(
            const {},
            event: rep(index: 3, rangeOfMotion: 58),
            set: [
              rep(rangeOfMotion: 60),
              rep(
                index: 2,
                outcome: RepOutcome.notCounted,
                fault: RepFault.tooFast,
                rangeOfMotion: 90,
              ),
            ],
          ),
        ),
        RuleOutcome.pass,
      );
    });

    test('cannot answer about a window with no rep in it', () {
      expect(rom.evaluate(window(const {})), RuleOutcome.notVisible);
    });
  });

  group('DescentShareRule', () {
    const tempo = DescentShareRule(
      id: 'tempo',
      severity: RuleSeverity.minor,
    );

    test('passes a rep with a controlled way in', () {
      expect(
        tempo.evaluate(
          window(
            const {},
            event: rep(
              duration: const Duration(milliseconds: 2000),
              descent: const Duration(milliseconds: 900),
            ),
          ),
        ),
        RuleOutcome.pass,
      );
    });

    test('fails a rep that was dropped into', () {
      expect(
        tempo.evaluate(
          window(
            const {},
            event: rep(
              duration: const Duration(milliseconds: 2000),
              descent: const Duration(milliseconds: 300),
            ),
          ),
        ),
        RuleOutcome.fail,
      );
    });

    test('is a share and not a stopwatch', () {
      // A slow rep with a proportionally quick descent is still a rep that
      // was dropped into, and a fast rep with an even tempo is not.
      expect(
        tempo.evaluate(
          window(
            const {},
            event: rep(
              duration: const Duration(milliseconds: 900),
              descent: const Duration(milliseconds: 430),
            ),
          ),
        ),
        RuleOutcome.pass,
      );
    });

    test('cannot answer about a window with no rep in it', () {
      expect(tempo.evaluate(window(const {})), RuleOutcome.notVisible);
    });
  });

  group('PendingRule', () {
    const flare = PendingRule(
      id: 'elbow_flare',
      severity: RuleSeverity.major,
      reason: 'needs the front view, which has no fixtures yet',
    );

    test('never answers, whatever it is handed', () {
      expect(
        flare.evaluate(window({_knee: const [170, 95, 170]}, peak: 1)),
        RuleOutcome.notImplemented,
      );
    });

    test('reads no signals, so nothing samples for it', () {
      expect(flare.signals, isEmpty);
    });
  });

  group('windows and the top of a rep', () {
    const lockout = SignalBoundRule(
      id: 'lockout',
      severity: RuleSeverity.minor,
      signal: _knee,
      at: RepSample.top,
      min: 160,
    );

    test('reads the frame the analyzer called the top', () {
      // The counter ends a rep the instant the signal crosses back inside
      // its tolerance band, which is up to a whole hysteresis short of the
      // top. The window therefore carries the rest at the top and says
      // which frame in it was the straightest.
      final result = lockout.evaluate(
        const RuleWindow(
          samples: {_knee: [178, 177, 170, 120, 95, 120, 153]},
          times: [
            Duration.zero,
            Duration(milliseconds: 33),
            Duration(milliseconds: 66),
            Duration(milliseconds: 99),
            Duration(milliseconds: 132),
            Duration(milliseconds: 165),
            Duration(milliseconds: 198),
          ],
          peakIndex: 4,
          declaredTop: 0,
          event: null,
          set: [],
        ),
      );

      expect(result, RuleOutcome.pass);
    });

    test('falls back to the newest frame when no top was declared', () {
      // Which is right for a live window: where the user is now is the only
      // sensible answer to a question asked mid-set.
      final result = lockout.evaluate(
        window({_knee: const [178, 177, 170, 120]}, peak: 3),
      );

      expect(result, RuleOutcome.fail);
    });
  });

  group('SignalTravelRule robustness', () {
    const swing = SignalTravelRule(
      id: 'torso_swing',
      severity: RuleSeverity.major,
      signal: _trunk,
      max: 15,
    );

    test('a couple of wild samples do not become movement', () {
      // Thirty frames of a torso that barely moves, with two landmark
      // errors in it. max minus min over a noisy window measures the two
      // worst errors in the set; this is what the harness found on a
      // fixture of clean reps with jitter added.
      final noisy = <double?>[
        for (var i = 0; i < 30; i++) 120 + (i.isEven ? 1.0 : -1.0),
      ];
      noisy[7] = 145;
      noisy[21] = 96;

      expect(swing.evaluate(window({_trunk: noisy})), RuleOutcome.pass);
    });

    test('a real swing is still a swing', () {
      final sweep = <double?>[
        for (var i = 0; i < 30; i++) 110 + i * 1.2,
      ];

      expect(swing.evaluate(window({_trunk: sweep})), RuleOutcome.fail);
    });
  });
}
