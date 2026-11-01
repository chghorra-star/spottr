import 'dart:io';

import 'package:exercise_library/exercise_library.dart';
import 'package:harness/harness.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

PoseFixture _relabelled(String name, int reps) {
  final clean = syntheticSuite().firstWhere((f) => f.name == 'squat_clean_8');
  return PoseFixture(
    name: name,
    exerciseId: clean.exerciseId,
    angle: clean.angle,
    source: clean.source,
    notes: 'eight reps, labelled $reps',
    expectedReps: reps,
    frames: clean.frames,
  );
}

void main() {
  group('renderReport', () {
    final report = runFixtures(syntheticSuite());
    final text = renderReport(report);

    test('names every fixture and what it did', () {
      for (final fixture in syntheticSuite()) {
        expect(text, contains(fixture.name));
      }
      expect(text, contains('PASS'));
      expect(text, contains('100.0%'));
    });

    test('attributes the accuracy figure to the kind of fixture it is', () {
      // Never a bare accuracy number: the first thing anybody does with one
      // is quote it without the word "synthetic" next to it.
      expect(text, contains('synthetic  rep accuracy'));
    });

    test('says plainly that nothing has been measured on a real body', () {
      expect(text, contains('recorded    none'));
      expect(text, contains('says nothing about'));
      expect(text, contains('docs/dev-loop.md'));
    });

    test('lists the exercises with no fixture at all', () {
      expect(text, contains('no fixture'));
      expect(text, contains('forward_lunge'));
    });

    test('shows the ledger for a fixture that failed', () {
      final failing = renderReport(runFixtures([_relabelled('mislabelled', 9)]));

      expect(failing, contains('FAIL'));
      expect(failing, contains('88.9%'));
      expect(failing, contains('RepEvent'));
      expect(failing, contains('eight reps, labelled 9'));
    });

    test('counts a hold separately from a rep count', () {
      expect(text, contains('holds        4 of 4 within tolerance'));
    });
  });

  group('the report as JSON', () {
    test('carries the numbers a CI job would gate on', () {
      final json = runFixtures(syntheticSuite()).toJson();

      expect(json['repAccuracy'], 1);
      expect(json['fixtures'], syntheticSuite().length);
      expect(json['passed'], syntheticSuite().length);
      expect(json['faultDetection'], 1);
      final coverage = json['coverage']! as Map<String, Object?>;
      expect(coverage['recorded'], isEmpty);
      expect(coverage['cameraExercises'], 9);
    });
  });

  group('loadFixtures', () {
    test('reads a fixture from disk', () {
      // Against a committed file, not against something this test wrote: a
      // change to the format has to break here rather than agreeing with
      // itself.
      final fixtures = loadFixtures('test/fixtures');

      expect(fixtures, hasLength(1));
      expect(fixtures.single.name, 'tiny_squat');
      expect(fixtures.single.frames, hasLength(4));
      expect(
        fixtures.single.frames[2].landmarks.containsKey(Joint.leftAnkle),
        isFalse,
      );
      expect(
        fixtures.single.frames[1].landmarks.containsKey(Joint.leftAnkle),
        isTrue,
      );
    });

    test('reads a single file by path', () {
      final fixtures = loadFixtures('test/fixtures/tiny_squat.json');

      expect(fixtures.single.name, 'tiny_squat');
    });

    test('names the file when a fixture will not decode', () {
      final directory = Directory.systemTemp.createTempSync('spottr_fixture');
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/broken.json').writeAsStringSync('{"a": 1}');

      expect(
        () => loadFixtures(directory.path),
        throwsA(
          isA<FormatException>()
              .having((e) => e.message, 'message', contains('broken.json')),
        ),
      );
    });

    test('says so when there is nothing at the path', () {
      expect(
        () => loadFixtures('test/fixtures/nowhere'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('round-trips a fixture through a file', () {
      final directory = Directory.systemTemp.createTempSync('spottr_fixture');
      addTearDown(() => directory.deleteSync(recursive: true));

      final written = writeFixture(_relabelled('written', 8), directory.path);
      final read = loadFixture(written);

      expect(read.name, 'written');
      expect(read.expectedReps, 8);
      expect(read.frames, hasLength(_relabelled('written', 8).frames.length));
    });
  });

  group('the report on form rules', () {
    final report = runFixtures(syntheticSuite());
    final text = renderReport(report);

    test('says how many labelled faults fired', () {
      expect(text, contains('labelled    18 of 18 fired (100%)'));
    });

    test('lists what fired and how often', () {
      expect(text, contains('back_rounding x12'));
      expect(text, contains('hip_pike x1'));
    });

    test('names the rules nothing in the suite trips', () {
      expect(text, contains('lunge_depth'));
      expect(text, contains('nothing here says whether they would fire'));
    });

    test('names the rules the engine does not evaluate, and why', () {
      expect(text, contains('not built'));
      expect(text, contains('knee_valgus'));
      expect(text, contains('needs the front view'));
      expect(text, contains('needs a signal that can name a side'));
    });

    test('says which rule disagreed when a fixture fails on form', () {
      final clean = syntheticSuite()
          .firstWhere((fixture) => fixture.name == 'squat_clean_8');
      final mislabelled = PoseFixture(
        name: 'mislabelled_faults',
        exerciseId: clean.exerciseId,
        angle: clean.angle,
        source: clean.source,
        notes: 'eight clean reps, labelled as a rounded back',
        expectedReps: clean.expectedReps,
        expectedFaults: const {'back_rounding'},
        frames: clean.frames,
      );

      final failing = renderReport(runFixtures([mislabelled]));

      expect(failing, contains('FAIL'));
      expect(failing, contains('labelled and did not fire: back_rounding'));
    });
  });

  group('per exercise', () {
    final catalog = ExerciseCatalog(standardExercises);
    final report = runFixtures(syntheticSuite());
    final rows = report.byExercise(catalog);

    test('has a row for every exercise the app would coach', () {
      expect(
        rows.map((row) => row.exerciseId).toSet(),
        report.cameraExercises,
      );
    });

    test('an exercise with no fixture says so rather than being left out', () {
      // The whole point of the table. An aggregate over the seven that have
      // fixtures, quoted as though it were about all nine, is the number
      // this milestone exists to stop anybody printing.
      final lunge =
          rows.firstWhere((row) => row.exerciseId == 'forward_lunge');

      expect(lunge.covered, isFalse);
      expect(lunge.accuracy, isNull);
      expect(lunge.fixtures, 0);
    });

    test('counts reps against the labels, per exercise', () {
      final squat =
          rows.firstWhere((row) => row.exerciseId == 'bodyweight_squat');

      expect(squat.accuracy, 1);
      expect(squat.expectedReps, greaterThan(0));
      expect(squat.repError, 0);
    });

    test('a hold has no rep accuracy and is counted as a hold', () {
      final plank = rows.firstWhere((row) => row.exerciseId == 'plank');

      expect(plank.accuracy, isNull);
      expect(plank.holds, 4);
      expect(plank.holdsWithin, 4);
    });

    test('says how many of an exercise rules anything demonstrates', () {
      final squat =
          rows.firstWhere((row) => row.exerciseId == 'bodyweight_squat');
      final row = rows.firstWhere((r) => r.exerciseId == 'db_bent_over_row');

      expect(squat.rulesDemonstrated, squat.rulesEvaluated);
      expect(row.rulesDemonstrated, lessThan(row.rulesEvaluated));
    });

    test('nothing in the suite is footage of a real body', () {
      expect(rows.every((row) => !row.recorded), isTrue);
    });
  });

  group('the acceptance targets block', () {
    final text = renderExercises(
      runFixtures(syntheticSuite()),
      ExerciseCatalog(standardExercises),
    );

    test('prints the table with every exercise in it', () {
      expect(text, contains('forward_lunge'));
      expect(text, contains('goblet_squat'));
      expect(text, contains('2 of 9 exercises have no fixture'));
    });

    test('calls the rep accuracy target unmeasured, because it is', () {
      expect(text, contains('rep accuracy >= 95%'));
      expect(text, contains('UNMEASURED'));
      expect(text, contains('not the same claim'));
    });

    test('reports the form target in both directions', () {
      expect(text, contains('labelled faults'));
      expect(text, contains('false alarms'));
    });
  });
}
