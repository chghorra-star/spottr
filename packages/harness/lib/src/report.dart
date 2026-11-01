import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';

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
  if (report.cues > 0) {
    lines.add(
      '  said        ${report.cues} times across the run, one every '
      '${report.secondsPerCue.toStringAsFixed(0)}s of movement',
    );
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
  lines.add(renderExercises(report, ExerciseCatalog(standardExercises)));

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

/// The per-exercise table, and what the acceptance targets can be said to
/// have met.
///
/// Separate from [renderReport] so that it can be asked for on its own, and
/// because it is the part a reader should take away: an aggregate over the
/// exercises that happen to have fixtures is a number about those, quoted as
/// though it were about the app.
String renderExercises(HarnessReport report, ExerciseCatalog catalog) {
  final rows = report.byExercise(catalog);
  final width = rows
      .map((row) => row.exerciseId.length)
      .fold(8, (a, b) => a > b ? a : b);

  final lines = <String>[
    'Per exercise',
    '  ${'exercise'.padRight(width)}  fixtures   reps  accuracy  '
        'rules  footage',
  ];

  for (final row in rows) {
    final reps = row.expectedReps == 0
        ? (row.holds > 0 ? '${row.holdsWithin}/${row.holds} held' : '-')
        : '${row.countedReps}/${row.expectedReps}';
    final accuracy = row.accuracy == null
        ? '-'
        : '${(row.accuracy! * 100).toStringAsFixed(0)}%';
    lines.add(
      '  ${row.exerciseId.padRight(width)}  '
      '${row.fixtures.toString().padLeft(8)}  '
      '${reps.padLeft(9)}  '
      '${accuracy.padLeft(6)}  '
      '${'${row.rulesDemonstrated}/${row.rulesEvaluated}'.padLeft(5)}  '
      '${row.recorded ? 'recorded' : 'none'}',
    );
  }

  final uncovered = rows.where((row) => !row.covered).toList();
  final recorded = rows.where((row) => row.recorded).toList();

  lines.addAll([
    '',
    '  accuracy is reps counted against reps labelled, on generated '
        'movement.',
    '  rules is how many of the rules this exercise is coached by have a '
        'fixture',
    '  built to trip them. Two of them, rom and tempo, read the rep rather '
        'than',
    '  the pose, so one fixture anywhere demonstrates them everywhere and '
        'this',
    '  column reads low for every exercise but the squat.',
  ]);

  if (uncovered.isNotEmpty) {
    lines.add(
      '  ${uncovered.length} of ${rows.length} exercises have no fixture at '
      'all: ${uncovered.map((row) => row.exerciseId).join(', ')}.',
    );
  }

  lines.addAll([
    '',
    'Acceptance targets',
    '  rep accuracy >= 95% at the recommended angle',
    '    ${recorded.isEmpty ? 'UNMEASURED' : 'see the recorded rows above'}. '
        'The accuracy column is generated movement,',
    '    which shows the engine agrees with itself and is not the same '
        'claim.',
    '  form warnings fire on labelled faults, with few false alarms',
    '    ${(report.faultDetection * 100).toStringAsFixed(0)}% of labelled '
        'faults fired and '
        '${report.faultFailures.where((r) => r.unexpectedFaults.isNotEmpty).length} '
        'fixtures fired something they were',
    '    not labelled for, on generated movement. On a real body: '
        'UNMEASURED.',
  ]);

  return lines.join('\n');
}
