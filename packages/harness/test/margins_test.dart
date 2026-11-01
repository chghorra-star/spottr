import 'package:coach_engine/coach_engine.dart';
import 'package:harness/harness.dart';
import 'package:test/test.dart';

PoseFixture _named(String name) =>
    syntheticSuite().firstWhere((fixture) => fixture.name == name);

/// One squat counter and one squat rule, so a sweep in a test finishes in a
/// test's worth of time.
const _counters = {'squat_knee_angle': _squat};
const _rules = {'squat_depth': _depth, 'rom': _rom, 'tempo': _tempo};

const _squat = RepCounterConfig(
  id: 'squat_knee_angle',
  signal: kneeAngle,
  direction: RepDirection.closing,
  topThreshold: 160,
  bottomThreshold: 100,
  minRangeOfMotion: 40,
);

const _depth = SignalBoundRule(
  id: 'squat_depth',
  severity: RuleSeverity.minor,
  signal: kneeAngle,
  at: RepSample.peak,
  max: 100,
);

const _rom = RangeConsistencyRule(id: 'rom', severity: RuleSeverity.major);
const _tempo = DescentShareRule(id: 'tempo', severity: RuleSeverity.minor);

List<KnobMargin> sweep(List<PoseFixture> suite) => measureMargins(
      suite: suite,
      counters: _counters,
      rules: _rules,
    );

KnobMargin of(List<KnobMargin> margins, String id) =>
    margins.firstWhere((margin) => margin.id == id);

void main() {
  group('measureMargins', () {
    final margins = sweep([_named('squat_clean_8')]);

    test('reports every number the configs were given', () {
      expect(
        margins.map((margin) => margin.id),
        containsAll([
          'squat_knee_angle.topThreshold',
          'squat_knee_angle.minRangeOfMotion',
          'squat_depth.max',
          'rom.minFraction',
          'tempo.minShare',
        ]),
      );
    });

    test('finds the point where a threshold starts miscounting', () {
      // The top of a squat is 160 degrees and the fixture stands up to 180.
      // Push the threshold far enough past that and the counter never sees
      // a top, so nothing is counted at all.
      final top = of(margins, 'squat_knee_angle.topThreshold');

      expect(top.value, 160);
      expect(top.up, lessThan(top.ladder));
      expect(top.unconstrained, isFalse);
    });

    test('says when nothing in the suite would notice a change', () {
      // Nothing in a clean set of eight ordinary reps comes anywhere near
      // the longest a rep is allowed to take.
      final longest = of(margins, 'squat_knee_angle.maxRepDuration');

      expect(longest.unconstrained, isTrue);
      expect(longest.summary, startsWith('>='));
    });

    test('a clean set bounds a rule from one side only', () {
      // The fixture squats to about 95 degrees against a bound of 100. The
      // bound can be loosened as far as the ladder reaches without anybody
      // noticing, and tightening it past 95 makes the rule fire on a set
      // with nothing wrong with it.
      final depth = of(margins, 'squat_depth.max');

      expect(depth.up, depth.ladder);
      expect(depth.down, lessThan(depth.ladder));
      expect(depth.unconstrained, isFalse);
    });

    test('a fixture built to trip a rule constrains that rule', () {
      final shallow = sweep([_named('squat_shallow_6')]);
      final depth = of(shallow, 'squat_depth.max');

      // The fixture stops at about 125 degrees against a bound of 100, so
      // the bound has room to move down and not much room to move up.
      expect(depth.up, lessThan(depth.ladder));
      expect(depth.unconstrained, isFalse);
    });

    test('a number nothing in the suite touches is marked as such', () {
      final lunge = measureMargins(
        suite: [_named('squat_clean_8')],
        counters: const {
          'lunge_knee_angle': RepCounterConfig(
            id: 'lunge_knee_angle',
            signal: kneeAngle,
            direction: RepDirection.closing,
            topThreshold: 160,
            bottomThreshold: 105,
            minRangeOfMotion: 40,
          ),
        },
        rules: const {},
      );

      expect(lunge.every((margin) => margin.fixtures == 0), isTrue);
      expect(lunge.first.summary, 'no fixture');
    });

    test('carries which numbers were ever measured', () {
      final rounding = measureMargins(
        suite: [_named('squat_rounded_6')],
        counters: _counters,
        rules: const {
          'back_rounding': SignalTravelRule(
            id: 'back_rounding',
            severity: RuleSeverity.unsafe,
            signal: trunkRatio,
            max: 15,
          ),
        },
      );

      expect(of(rounding, 'back_rounding.max').measured, isTrue);
      expect(of(rounding, 'squat_knee_angle.hysteresis').measured, isFalse);
    });

    test('never reports a margin it did not try', () {
      for (final margin in margins) {
        final ladder = offsetLadders[margin.unit]!;
        expect(margin.down, anyOf(0, isIn(ladder)));
        expect(margin.up, anyOf(0, isIn(ladder)));
      }
    });
  });

  group('renderMargins', () {
    final text = renderMargins(sweep([_named('squat_clean_8')]));

    test('counts the guesses', () {
      expect(text, contains('numbers in the engine'));
      expect(text, contains('measured'));
    });

    test('says what a wide margin does and does not mean', () {
      expect(text, contains('without any fixture noticing'));
      expect(text, contains('not a licence to change them'));
      expect(text, contains('built from the'));
    });

    test('names every number it looked at', () {
      expect(text, contains('squat_knee_angle.topThreshold'));
      expect(text, contains('tempo.minShare'));
    });
  });
}
