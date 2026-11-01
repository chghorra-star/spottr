import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';

import 'fixture.dart';
import 'replay.dart';

/// How far a number is nudged, in the units it is written in.
///
/// A ladder rather than a binary search, because nothing guarantees that a
/// threshold breaks monotonically: a counter can start miscounting at five
/// degrees and go back to agreeing at ten for reasons that are about the
/// fixture rather than about the number. A ladder reports what was actually
/// tried.
const Map<String, List<double>> offsetLadders = {
  'deg': [1, 2, 5, 10, 20, 40],
  '%': [1, 2, 5, 10, 20, 40],
  'ms': [25, 50, 100, 200, 400, 800],
  'x': [0.02, 0.05, 0.1, 0.2, 0.4],
};

/// What the fixture suite has to say about one number.
@immutable
class KnobMargin {
  const KnobMargin({
    required this.id,
    required this.value,
    required this.unit,
    required this.measured,
    required this.down,
    required this.up,
    required this.ladder,
    required this.fixtures,
  });

  final String id;
  final double value;
  final String unit;

  /// Whether this number came from a measurement rather than a guess.
  final bool measured;

  /// The largest nudge in each direction that still left every fixture
  /// agreeing with its label.
  ///
  /// Zero means the smallest step on the ladder broke something: the suite
  /// pins this number exactly, which is a warning rather than a
  /// reassurance — a real body will not land on it.
  final double down;
  final double up;

  /// The largest nudge the search tried.
  final double ladder;

  /// How many fixtures could say anything about this number at all.
  final int fixtures;

  /// The suite pins it: it cannot move at all without breaking something.
  bool get pinned => fixtures > 0 && (down == 0 || up == 0);

  /// The suite says nothing about it, either because nothing exercises it
  /// or because it survived every nudge the ladder had.
  bool get unconstrained =>
      fixtures == 0 || (down >= ladder && up >= ladder);

  /// How it reads in a table: `+-5`, `>=+-40`, or `pinned`.
  String get summary {
    if (fixtures == 0) return 'no fixture';
    if (unconstrained) return '>=+-${_number(ladder)}';
    if (pinned) return 'pinned';
    return '-${_number(down)} +${_number(up)}';
  }

  @override
  String toString() => '$id = ${_number(value)}$unit  $summary';
}

String _number(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : value.toString();

/// Every number in the engine, and how far the suite lets it move.
///
/// This is the measurement the milestone is for. The engine is full of
/// numbers somebody chose by being plausible about anatomy, and until there
/// is footage the only question that can be asked of them is whether
/// anything in the suite would notice them changing. Mostly the answer is
/// no, and that is worth knowing precisely rather than vaguely.
List<KnobMargin> measureMargins({
  required List<PoseFixture> suite,
  ExerciseCatalog? catalog,
  Map<String, CounterConfig> counters = counterCatalog,
  Map<String, FormRule> rules = formCatalog,
  void Function(String id)? onProgress,
}) {
  final library = catalog ?? ExerciseCatalog(standardExercises);
  final margins = <KnobMargin>[];

  /// Fixtures that could notice this counter changing.
  List<PoseFixture> usingCounter(String counterId) => [
        for (final fixture in suite)
          if (library[fixture.exerciseId]?.camera?.repCounterId == counterId)
            fixture,
      ];

  /// Fixtures for an exercise that has this rule.
  List<PoseFixture> usingRule(String ruleId) => [
        for (final fixture in suite)
          if (library[fixture.exerciseId]
                  ?.camera
                  ?.formRuleIds
                  .contains(ruleId) ??
              false)
            fixture,
      ];

  bool agrees(
    List<PoseFixture> fixtures,
    Map<String, CounterConfig> withCounters,
    Map<String, FormRule> withRules,
  ) {
    for (final fixture in fixtures) {
      final result = replay(
        fixture,
        catalog: library,
        counters: withCounters,
        rules: withRules,
      );
      if (!result.passed) return false;
    }
    return true;
  }

  KnobMargin measure({
    required String id,
    required double value,
    required String unit,
    required List<PoseFixture> fixtures,
    required bool Function(double value) holds,
  }) {
    final ladder = offsetLadders[unit] ?? offsetLadders['x']!;
    double furthest(double sign) {
      var safe = 0.0;
      for (final offset in ladder) {
        if (!holds(value + sign * offset)) break;
        safe = offset;
      }
      return safe;
    }

    onProgress?.call(id);
    return KnobMargin(
      id: id,
      value: value,
      unit: unit,
      measured: measuredKnobs.contains(id),
      down: fixtures.isEmpty ? 0 : furthest(-1),
      up: fixtures.isEmpty ? 0 : furthest(1),
      ladder: ladder.last,
      fixtures: fixtures.length,
    );
  }

  for (final entry in counters.entries) {
    final fixtures = usingCounter(entry.key);
    for (final knob in counterKnobs(entry.value)) {
      margins.add(
        measure(
          id: knob.id,
          value: knob.value,
          unit: knob.unit,
          fixtures: fixtures,
          holds: (value) => agrees(
            fixtures,
            {...counters, entry.key: knob.apply(value)},
            rules,
          ),
        ),
      );
    }
  }

  for (final entry in rules.entries) {
    final fixtures = usingRule(entry.key);
    for (final knob in ruleKnobs(entry.value)) {
      margins.add(
        measure(
          id: knob.id,
          value: knob.value,
          unit: knob.unit,
          fixtures: fixtures,
          holds: (value) => agrees(
            fixtures,
            counters,
            {...rules, entry.key: knob.apply(value)},
          ),
        ),
      );
    }
  }

  return margins;
}

/// The report, as something a person reads.
String renderMargins(List<KnobMargin> margins) {
  final lines = <String>[
    'What the suite pins down',
    '',
    '${margins.length} numbers in the engine, '
        '${margins.where((m) => m.measured).length} of them measured.',
    '',
  ];

  final width = margins
      .map((margin) => margin.id.length)
      .fold(4, (a, b) => a > b ? a : b);

  for (final margin in margins) {
    lines.add(
      '  ${margin.id.padRight(width)}  '
      '${_number(margin.value).padLeft(6)}${margin.unit.padRight(4)}'
      '${margin.summary}'
      '${margin.measured ? '   (measured)' : ''}',
    );
  }

  final unconstrained = margins.where((m) => m.unconstrained).toList();
  final pinned = margins.where((m) => m.pinned).toList();
  final noFixture = margins.where((m) => m.fixtures == 0).toList();

  lines.addAll([
    '',
    'Summary',
    '  ${unconstrained.length} of ${margins.length} numbers could be '
        'changed without any fixture noticing,',
    '  ${noFixture.length} of them because nothing in the suite exercises '
        'them at all.',
    '  That is not a licence to change them. It is the measurement of how '
        'little',
    '  generated movement constrains a threshold: every fixture is built '
        'from the',
    '  same anatomy the thresholds were guessed from, so of course it '
        'agrees.',
  ]);

  if (pinned.isNotEmpty) {
    lines.addAll([
      '',
      '  ${pinned.length} are pinned — the smallest nudge the ladder has '
          'breaks a fixture:',
      for (final margin in pinned) '    ${margin.id}',
      '  A pinned number is a fixture passing by a hair, which a real body '
          'will not.',
    ]);
  }

  return lines.join('\n');
}
