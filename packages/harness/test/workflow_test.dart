import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// The CI workflow is the one thing in this repository that nothing else
/// checks. It is not compiled, not analyzed, and — until there is a remote —
/// never run, so a mistake in it is invisible until a push, and the worst
/// mistakes are invisible even then: a job that silently never runs, or a
/// gate that passes because it tested nothing.
///
/// M9 shipped two of exactly that shape. These tests pin both.
///
/// Runner labels are pinned rather than fetched, which means this file goes
/// stale the way the images do. A stale pin fails loudly here; a stale label
/// fails on a push with "the runner image is retired", after the queue.
void main() {
  late Directory root;
  late String workflowText;
  late YamlMap workflow;
  late YamlMap jobs;

  setUpAll(() {
    root = _repoRoot();
    final file = File('${root.path}/.github/workflows/ci.yml');
    workflowText = file.readAsStringSync();
    workflow = loadYaml(workflowText) as YamlMap;
    jobs = workflow['jobs'] as YamlMap;
  });

  group('triggers', () {
    test('every event a job tests for is an event the workflow listens to', () {
      final triggers = _triggers(workflow);
      final pattern = RegExp(r"github\.event_name\s*==\s*'([a-z_]+)'");

      for (final entry in jobs.entries) {
        final condition = (entry.value as YamlMap)['if'] as String?;
        if (condition == null) continue;

        for (final match in pattern.allMatches(condition)) {
          final event = match.group(1)!;
          expect(
            triggers,
            contains(event),
            reason:
                'job "${entry.key}" only runs on $event, which is not in the '
                'workflow\'s on: block, so it can never run at all',
          );
        }
      }
    });
  });

  group('runners', () {
    // Dates are GitHub's. An image is removed, not deprecated: a job asking
    // for one of these fails after it has queued.
    const retired = {
      'macos-11': 'removed 2023-06-28',
      'macos-12': 'removed 2024-12-03',
      'macos-13': 'removed 2025-12-04',
      'macos-14': 'removed 2026-11-02',
      'ubuntu-18.04': 'removed 2023-04-03',
      'ubuntu-20.04': 'removed 2025-04-15',
    };

    test('no job asks for a runner image that no longer exists', () {
      for (final entry in jobs.entries) {
        final label = (entry.value as YamlMap)['runs-on'] as String;
        expect(
          retired.keys,
          isNot(contains(label)),
          reason: 'job "${entry.key}" runs on $label, '
              '${retired[label]} — use macos-15-intel for x86_64',
        );
      }
    });

    test('the only x86_64 macOS runner is asked for by name', () {
      // ML Kit's pods ship no arm64 simulator slice, so the native tests
      // cannot run on an Apple Silicon runner at all. That makes the Intel
      // image load-bearing rather than incidental, and it is itself retiring
      // in Fall 2027, after which these tests need a real device.
      final simulatorJobs = jobs.entries.where((entry) {
        final steps = (entry.value as YamlMap)['steps'] as YamlList;
        return steps.any((step) =>
            ((step as YamlMap)['run'] as String? ?? '').contains('iOS Simulator'));
      });

      expect(simulatorJobs, isNotEmpty,
          reason: 'nothing runs the native tests any more');

      for (final entry in simulatorJobs) {
        expect((entry.value as YamlMap)['runs-on'], 'macos-15-intel',
            reason: 'job "${entry.key}" runs a simulator, which needs x86_64');
      }
    });
  });

  group('dependencies', () {
    test('every needs: names a job that exists', () {
      for (final entry in jobs.entries) {
        final needs = (entry.value as YamlMap)['needs'];
        if (needs == null) continue;

        for (final dependency in needs is YamlList ? needs : [needs]) {
          expect(jobs.keys, contains(dependency),
              reason: 'job "${entry.key}" waits for "$dependency", '
                  'which is not a job in this workflow');
        }
      }
    });
  });

  group('parity with the local gate', () {
    // The M9 bug: the accuracy harness gated tool/check.ps1 from M5 and
    // gated nothing on a push, so CI was weaker than somebody's laptop for
    // four milestones. Anything worth blocking a commit locally is worth
    // blocking a merge.
    test('every gate in tool/check.ps1 also runs in CI', () {
      final gate = File('${root.path}/tool/check.ps1').readAsStringSync();
      final runs = jobs.values
          .expand((job) => (job as YamlMap)['steps'] as YamlList)
          .map((step) => (step as YamlMap)['run'] as String? ?? '')
          .join('\n');

      for (final package in _pureDartPackages(gate)) {
        expect(runs, contains(package),
            reason: 'tool/check.ps1 runs dart test in packages/$package '
                'and CI never mentions it');
      }

      expect(runs, contains('bin/harness.dart'),
          reason: 'the local gate runs the accuracy harness and CI does not');
      expect(runs, contains('flutter analyze'));
    });
  });

  group('the destinations are resolved, not guessed', () {
    test('no xcodebuild destination names a simulator model', () {
      // A runner image carries whichever simulators its Xcode shipped with.
      // Naming one is a guess that goes stale silently in the direction that
      // fails the build, and loudly in the direction that skips the tests.
      expect(workflowText, isNot(contains('Simulator,name=')),
          reason: 'pick the destination from simctl at run time instead');
      expect(workflowText, isNot(matches(RegExp(r'name=iPhone\s*\d'))),
          reason: 'pick the destination from simctl at run time instead');
    });
  });
}

Set<String> _triggers(YamlMap workflow) {
  // YAML 1.1 reads a bare `on` as true; package:yaml follows 1.2 and keeps it
  // a string. Accept either, so this test does not depend on which.
  final on = workflow['on'] ?? workflow[true];
  if (on is YamlMap) return on.keys.cast<String>().toSet();
  if (on is YamlList) return on.cast<String>().toSet();
  return {on as String};
}

/// The `$pureDartPackages` array at the top of tool/check.ps1.
Iterable<String> _pureDartPackages(String gate) {
  final block = RegExp(r'pureDartPackages\s*=\s*@\(([^)]*)\)', dotAll: true)
      .firstMatch(gate);
  expect(block, isNotNull, reason: 'tool/check.ps1 no longer lists packages');
  return RegExp("'([a-z_]+)'")
      .allMatches(block!.group(1)!)
      .map((match) => match.group(1)!);
}

Directory _repoRoot() {
  var directory = Directory.current;
  while (!Directory('${directory.path}/.github').existsSync()) {
    final parent = directory.parent;
    expect(parent.path, isNot(directory.path),
        reason: 'no .github above ${Directory.current.path}');
    directory = parent;
  }
  return directory;
}
