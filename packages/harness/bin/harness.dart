import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:harness/harness.dart';

/// Replays labelled landmark fixtures through the coach engine.
///
/// ```
/// dart run harness                       # the synthetic suite
/// dart run harness --fixtures recorded/  # a directory of .json fixtures
/// dart run harness --json                # for a machine
/// ```
///
/// Exit code 1 means a gate was missed, which is what makes this usable from
/// CI. The synthetic gate is 100 per cent because synthetic movement has one
/// right answer; the recorded gate is the MVP's acceptance target, and it
/// only applies once there is footage to apply it to.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'fixtures',
      abbr: 'f',
      help: 'A fixture file, or a directory of them. Defaults to the '
          'generated suite.',
    )
    ..addFlag(
      'synthetic',
      help: 'Include the generated suite as well as any --fixtures path.',
      negatable: false,
    )
    ..addFlag('json', help: 'Print the report as JSON.', negatable: false)
    ..addFlag(
      'smooth',
      help: 'Run the smoothing filter, as the app does. Off shows what the '
          'filter contributes.',
      defaultsTo: true,
    )
    ..addOption(
      'fail-under',
      help: 'Minimum rep accuracy over synthetic fixtures, in per cent.',
      defaultsTo: '100',
    )
    ..addOption(
      'fail-under-recorded',
      help: 'Minimum rep accuracy over recorded fixtures, in per cent.',
      defaultsTo: '95',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(parser.usage);
    exit(64);
  }

  if (options.flag('help')) {
    stdout.writeln('Replays pose fixtures through the coach engine.');
    stdout.writeln(parser.usage);
    return;
  }

  final path = options.option('fixtures');
  // Nothing named means the generated suite; a path means that path, plus
  // the suite only if it was asked for.
  final includeSynthetic = options.flag('synthetic') || path == null;

  final fixtures = <PoseFixture>[
    if (includeSynthetic) ...syntheticSuite(),
    if (path != null) ...loadFixtures(path),
  ];

  if (fixtures.isEmpty) {
    stderr.writeln('No fixtures to run.');
    exit(64);
  }

  final HarnessReport report;
  try {
    report = runFixtures(fixtures, smooth: options.flag('smooth'));
  } on ArgumentError catch (error) {
    stderr.writeln('Could not run: ${error.message}');
    exit(65);
  }

  if (options.flag('json')) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(report.toJson()),
    );
  } else {
    stdout.writeln(renderReport(report));
  }

  final gates = <(String, double, double)>[
    (
      'synthetic',
      report.accuracy(source: FixtureSource.synthetic) * 100,
      double.parse(options.option('fail-under')!),
    ),
    if (report.recorded.isNotEmpty)
      (
        'recorded',
        report.accuracy(source: FixtureSource.recorded) * 100,
        double.parse(options.option('fail-under-recorded')!),
      ),
  ];

  var failed = false;
  for (final (name, accuracy, gate) in gates) {
    if (accuracy + 1e-9 < gate) {
      stderr.writeln(
        '$name rep accuracy ${accuracy.toStringAsFixed(1)}% is below the '
        '${gate.toStringAsFixed(0)}% gate',
      );
      failed = true;
    }
  }

  // Holds are not in the rep accuracy figure and would otherwise slip
  // through a gate that only reads it.
  for (final result in report.holdResults) {
    if (result.countedRight) continue;
    stderr.writeln(
      'hold ${result.fixture.name} came out at ${result.actual} '
      'against ${result.expectation}',
    );
    failed = true;
  }

  // Form rules are gated by agreement with the label rather than by a
  // percentage, and in both directions. A rule that does not fire on the
  // fault it was written for is useless; a rule that fires on a fixture
  // nothing is wrong with will fire on every set anybody ever performs,
  // and that is the worse of the two.
  for (final result in report.faultFailures) {
    if (result.fixture.source != FixtureSource.synthetic) {
      // Recorded movement is allowed to disagree: that disagreement is the
      // measurement, and M8 is what turns it into thresholds.
      continue;
    }
    if (result.missedFaults.isNotEmpty) {
      stderr.writeln(
        '${result.fixture.name} was labelled '
        '${result.missedFaults.join(', ')} and nothing fired',
      );
    }
    if (result.unexpectedFaults.isNotEmpty) {
      stderr.writeln(
        '${result.fixture.name} fired '
        '${result.unexpectedFaults.join(', ')} and was not labelled for it',
      );
    }
    failed = true;
  }

  if (failed) exit(1);
}
