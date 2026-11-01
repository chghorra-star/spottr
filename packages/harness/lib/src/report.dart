import 'package:coach_engine/coach_engine.dart';

import 'fixture.dart';
import 'replay.dart';

/// The report, as something a person reads.
///
/// Two rules about this text. It never prints one aggregate accuracy number
/// over fixtures of different kinds, and it always says how many exercises
/// have footage of a real body — which is currently none. An accuracy
/// figure with neither of those next to it is a claim the suite cannot
/// support, and it is the exact claim somebody will quote later.
String renderReport(HarnessReport report) {
  final lines = <String>[];
  final sources = {for (final r in report.results) r.fixture.source};

  lines.add('Spottr accuracy harness');
  lines.add(
    '${report.results.length} fixtures, '
    '${report.covered.length} of ${report.cameraExercises.length} '
    'camera exercises, ${report.recorded.length} with recorded footage',
  );
  lines.add('');

  final nameWidth = report.results
      .map((result) => result.fixture.name.length)
      .fold(4, (a, b) => a > b ? a : b);
  final exerciseWidth = report.results
      .map((result) => result.fixture.exerciseId.length)
      .fold(8, (a, b) => a > b ? a : b);

  for (final result in report.results) {
    final fixture = result.fixture;
    lines.add(
      '  ${result.passed ? 'PASS' : 'FAIL'}  '
      '${fixture.name.padRight(nameWidth)}  '
      '${fixture.exerciseId.padRight(exerciseWidth)}  '
      '${fixture.angle.name.padRight(5)}  '
      '${fixture.source.name.padRight(9)}  '
      '${result.actual.padLeft(6)} of ${result.expectation.padLeft(6)}'
      '${_faults(result)}',
    );
    if (!result.passed) {
      lines.add('        ${fixture.notes}');
      if (result.missedFaults.isNotEmpty) {
        lines.add(
          '        labelled and did not fire: '
          '${_list(result.missedFaults)}',
        );
      }
      if (result.unexpectedFaults.isNotEmpty) {
        lines.add(
          '        fired and was not labelled: '
          '${_list(result.unexpectedFaults)}',
        );
      }
      if (!result.countedRight) {
        for (final event in result.ledger) {
          lines.add('        $event');
        }
      }
      if (result.framesTracked < result.framesSeen) {
        lines.add(
          '        ${result.framesSeen - result.framesTracked} of '
          '${result.framesSeen} frames had nothing to measure',
        );
      }
    }
  }

  lines.add('');
  for (final source in FixtureSource.values) {
    if (!sources.contains(source)) continue;
    final reps = report.repResults
        .where((result) => result.fixture.source == source)
        .toList();
    final holds = report.holdResults
        .where((result) => result.fixture.source == source)
        .toList();

    if (reps.isNotEmpty) {
      final accuracy = report.accuracy(source: source);
      lines.add(
        '${source.name.padRight(10)} rep accuracy '
        '${(accuracy * 100).toStringAsFixed(1)}% '
        '(${report.countedRepsIn(source)} counted of '
        '${report.expectedRepsIn(source)} expected, '
        '${report.repErrorIn(source)} miscounted)',
      );
    }
    if (holds.isNotEmpty) {
      final passed = holds.where((result) => result.countedRight).length;
      lines.add(
        '${source.name.padRight(10)} holds        '
        '$passed of ${holds.length} within tolerance',
      );
    }
  }

  lines.add('');
  lines.add('Form rules');
  final labelled = report.results.fold<int>(
    0,
    (sum, result) => sum + result.fixture.expectedFaults.length,
  );
  if (labelled > 0) {
    final missed = report.results
        .fold<int>(0, (sum, result) => sum + result.missedFaults.length);
    lines.add(
      '  labelled    ${labelled - missed} of $labelled fired '
      '(${(report.faultDetection * 100).toStringAsFixed(0)}%)',
    );
  }
  final firings = report.firings;
  if (firings.isNotEmpty) {
    final parts = [
      for (final entry in (firings.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))))
        '${entry.key} x${entry.value}',
    ];
    lines.add('  fired       ${parts.join(', ')}');
  }
  final unexpected = {
    for (final result in report.results) ...result.unexpectedFaults,
  };
  if (unexpected.isNotEmpty) {
    lines.add('  unlabelled  ${_list(unexpected)}');
  }
  if (report.rulesUnexercised.isNotEmpty) {
    lines.add(
      '  no fixture  ${_list(report.rulesUnexercised)}',
    );
    lines.add(
      '              evaluated, and nothing in the suite is built to trip '
      'them, so',
    );
    lines.add(
      '              nothing here says whether they would fire or when.',
    );
  }
  if (report.rulesPending.isNotEmpty) {
    lines.add('  not built   ${_list(report.rulesPending.keys.toSet())}');
    for (final entry in (report.rulesPending.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))) {
      lines.add('              ${entry.key}: ${_wrap(entry.value, 60)}');
    }
  }

  lines.add('');
  lines.add('Coverage');
  lines.add('  measured    ${_list(report.covered)}');
  if (report.uncovered.isNotEmpty) {
    lines.add('  no fixture  ${_list(report.uncovered)}');
  }
  if (report.recorded.isEmpty) {
    lines.add(
      '  recorded    none. Every number above comes from generated '
      'movement, which',
    );
    lines.add(
      '              shows the engine agrees with itself and says nothing '
      'about',
    );
    lines.add(
      '              accuracy on a real body. See docs/dev-loop.md.',
    );
  } else {
    lines.add('  recorded    ${_list(report.recorded)}');
  }

  return lines.join('\n');
}

String _faults(FixtureResult result) {
  final counts = <RepFault, int>{};
  for (final event in result.ledger) {
    final fault = event.fault;
    if (fault == null) continue;
    counts[fault] = (counts[fault] ?? 0) + 1;
  }
  if (counts.isEmpty) return '';
  final parts = [
    for (final entry in counts.entries) '${entry.key.name} x${entry.value}',
  ]..sort();
  return '   ${parts.join(', ')}';
}

String _list(Set<String> ids) => (ids.toList()..sort()).join(', ');

/// Breaks [text] at [width], continuing on indented lines.
String _wrap(String text, int width) {
  final lines = <String>[];
  var line = '';
  for (final word in text.split(' ')) {
    if (line.isEmpty) {
      line = word;
    } else if (line.length + 1 + word.length <= width) {
      line = '$line $word';
    } else {
      lines.add(line);
      line = word;
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines.join('\n                  ');
}
