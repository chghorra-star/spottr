import 'dart:io';

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
      expect(text, contains('holds        2 of 2 within tolerance'));
    });
  });

  group('the report as JSON', () {
    test('carries the numbers a CI job would gate on', () {
      final json = runFixtures(syntheticSuite()).toJson();

      expect(json['repAccuracy'], 1);
      expect(json['fixtures'], 11);
      expect(json['passed'], 11);
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
}
