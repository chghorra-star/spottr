import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

final catalog = ExerciseCatalog(standardExercises);

const _knee = JointAngle(
  from: Joint.leftHip,
  vertex: Joint.leftKnee,
  to: Joint.leftAnkle,
);

void main() {
  group('counterKnobs', () {
    const squat = RepCounterConfig(
      id: 'squat_knee_angle',
      signal: _knee,
      direction: RepDirection.closing,
      topThreshold: 160,
      bottomThreshold: 100,
      minRangeOfMotion: 40,
    );

    Knob<CounterConfig> knob(CounterConfig config, String id) =>
        counterKnobs(config).firstWhere((knob) => knob.id == id);

    test('names every number a rep counter was given', () {
      expect(
        counterKnobs(squat).map((knob) => knob.id),
        containsAll([
          'squat_knee_angle.topThreshold',
          'squat_knee_angle.bottomThreshold',
          'squat_knee_angle.minRangeOfMotion',
          'squat_knee_angle.hysteresis',
          'squat_knee_angle.minRepDuration',
          'squat_knee_angle.maxRepDuration',
          'squat_knee_angle.maxTrackingGap',
        ]),
      );
    });

    test('reads the value that is actually in the config', () {
      expect(knob(squat, 'squat_knee_angle.topThreshold').value, 160);
      expect(knob(squat, 'squat_knee_angle.minRangeOfMotion').value, 40);
    });

    test('turning a knob changes that number and nothing else', () {
      final turned =
          knob(squat, 'squat_knee_angle.topThreshold').apply(150)
              as RepCounterConfig;

      expect(turned.topThreshold, 150);
      expect(turned.bottomThreshold, squat.bottomThreshold);
      expect(turned.minRangeOfMotion, squat.minRangeOfMotion);
      expect(turned.hysteresis, squat.hysteresis);
      expect(turned.signal, squat.signal);
      expect(turned.direction, squat.direction);
      expect(turned.id, squat.id);
    });

    test('a turned knob reads back as turned', () {
      // The round trip a sweep depends on: set a value, and the same knob
      // on the result reports it.
      final turned = knob(squat, 'squat_knee_angle.hysteresis').apply(12);

      expect(knob(turned, 'squat_knee_angle.hysteresis').value, 12);
    });

    test('a duration knob is in milliseconds', () {
      final duration = knob(squat, 'squat_knee_angle.minRepDuration');

      expect(duration.unit, 'ms');
      expect(duration.value, 600);

      final turned = duration.apply(900) as RepCounterConfig;
      expect(turned.minRepDuration, const Duration(milliseconds: 900));
    });

    test('names each band of a hold separately', () {
      const plank = HoldCounterConfig(
        id: 'plank_hold',
        bands: [
          SignalBand(signal: _knee, min: 155),
          SignalBand(signal: _knee, min: 55, max: 125),
        ],
      );

      expect(
        counterKnobs(plank).map((knob) => knob.id),
        containsAll([
          'plank_hold.band0.min',
          'plank_hold.band1.min',
          'plank_hold.band1.max',
          'plank_hold.maxTrackingGap',
        ]),
      );
      // A band with no ceiling has no ceiling to turn.
      expect(
        counterKnobs(plank).map((knob) => knob.id),
        isNot(contains('plank_hold.band0.max')),
      );
    });

    test('turning one band leaves the other alone', () {
      const plank = HoldCounterConfig(
        id: 'plank_hold',
        bands: [
          SignalBand(signal: _knee, min: 155),
          SignalBand(signal: _knee, min: 55, max: 125),
        ],
      );
      final turned = counterKnobs(plank)
          .firstWhere((knob) => knob.id == 'plank_hold.band1.max')
          .apply(140) as HoldCounterConfig;

      expect(turned.bands[0].min, 155);
      expect(turned.bands[1].min, 55);
      expect(turned.bands[1].max, 140);
    });
  });

  group('ruleKnobs', () {
    test('names the bound of a bound rule', () {
      const depth = SignalBoundRule(
        id: 'squat_depth',
        severity: RuleSeverity.minor,
        signal: _knee,
        at: RepSample.peak,
        max: 100,
      );

      expect(ruleKnobs(depth).map((knob) => knob.id), ['squat_depth.max']);
      expect(
        (ruleKnobs(depth).single.apply(90) as SignalBoundRule).max,
        90,
      );
    });

    test('names a band and its tolerance', () {
      const sag = SignalHoldRule(
        id: 'hip_sag',
        severity: RuleSeverity.major,
        signal: _knee,
        max: 6,
      );

      expect(
        ruleKnobs(sag).map((knob) => knob.id),
        ['hip_sag.max', 'hip_sag.tolerance'],
      );
      final turned = ruleKnobs(sag)
          .firstWhere((knob) => knob.id == 'hip_sag.tolerance')
          .apply(0.2) as SignalHoldRule;
      expect(turned.tolerance, 0.2);
      expect(turned.max, 6);
    });

    test('names the share a rep rule compares against', () {
      const rom = RangeConsistencyRule(id: 'rom', severity: RuleSeverity.major);
      const tempo = DescentShareRule(id: 'tempo', severity: RuleSeverity.minor);

      expect(ruleKnobs(rom).single.id, 'rom.minFraction');
      expect(ruleKnobs(rom).single.unit, 'x');
      expect(ruleKnobs(tempo).single.id, 'tempo.minShare');
    });

    test('a rule the engine does not evaluate has nothing to turn', () {
      const pending = PendingRule(
        id: 'knee_valgus',
        severity: RuleSeverity.major,
        reason: 'front view',
      );

      expect(ruleKnobs(pending), isEmpty);
    });
  });

  group('every number in the engine', () {
    final knobs = engineKnobs();

    test('is reachable, and there are a lot of them', () {
      expect(knobs.length, greaterThan(40));
    });

    test('is named once', () {
      final ids = knobs.map((knob) => knob.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('says what it is measured in', () {
      for (final knob in knobs) {
        expect(
          knob.unit,
          anyOf('deg', '%', 'ms', 'x'),
          reason: '${knob.id} has no unit anybody could tune it in',
        );
      }
    });

    test('is almost all guesswork, and says so', () {
      // The number this milestone exists to make countable. Every threshold
      // in this engine was chosen by somebody being plausible about anatomy;
      // exactly one of them has ever been compared against anything.
      final measured = knobs.where((knob) => knob.measured).toList();

      expect(measured.map((knob) => knob.id), ['back_rounding.max']);
      expect(measured.length / knobs.length, lessThan(0.05));
    });

    test('names a knob for a number the shipping catalogs really have', () {
      expect(
        knobs.firstWhere((knob) => knob.id == 'squat_knee_angle.topThreshold')
            .value,
        160,
      );
      expect(
        knobs.firstWhere((knob) => knob.id == 'back_rounding.max').value,
        15,
      );
    });

    test('every id it claims is measured is an id it has', () {
      expect(
        measuredKnobs.difference(knobs.map((knob) => knob.id).toSet()),
        isEmpty,
      );
    });
  });
}
