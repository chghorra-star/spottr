import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// The CI workflow and the Podfile are the two files here that nothing else
/// checks. Neither is compiled or analyzed; one is committed rather than
/// generated and the other only ever runs on somebody else's machine. So a
/// mistake in either is invisible locally, and the worst kind is invisible
/// on a push too: a job that silently never runs, or a gate that passes
/// because it tested nothing.
///
/// M9 shipped two of that shape and the Podfile cost the first CI run both
/// of its macOS jobs before a line of Swift was reached. These tests pin
/// what each failure taught, with the reason next to it, because every one
/// of these values looks arbitrary and removable until it is removed.
///
/// Runner labels and ML Kit's constraints are pinned rather than fetched,
/// which means this file goes stale the way they do. That is the trade: a
/// stale pin fails here in a second, with a reason. A stale label fails on
/// a runner after a queue, and a wrong linkage mode fails in CocoaPods'
/// stack trace.
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

  group('the Podfile', () {
    // Committed rather than generated, which means nothing regenerates it
    // when it is wrong, and nothing here compiles it. The first CI run
    // failed on it twice before a line of Swift was reached.
    late String podfile;

    setUpAll(() {
      podfile = File('${root.path}/app/ios/Podfile').readAsStringSync();
    });

    test('frameworks are linked statically', () {
      // ML Kit drags in GoogleUtilitiesComponents, which ships as a static
      // binary. A plain `use_frameworks!` asks for dynamic linkage, and
      // CocoaPods refuses the combination outright:
      //   The 'Pods-Runner' target has transitive dependencies that include
      //   statically linked binaries: (GoogleUtilitiesComponents)
      // Static linkage drops the dynamic requirement ML Kit cannot satisfy.
      // It does not bring module maps with it — see the next test.
      expect(podfile, contains('use_frameworks!'),
          reason: 'the plugin is Swift and needs module maps');
      expect(
        podfile,
        matches(RegExp(r'use_frameworks!\s*:linkage\s*=>\s*:static')),
        reason: 'ML Kit ships static transitive dependencies; dynamic '
            'linkage fails pod install before anything compiles',
      );
    });

    test('every pod gets a module map', () {
      // Static linkage is not free: GeneratedPluginRegistrant.m is
      // Objective-C and reaches Flutter plugins with `@import`, which needs
      // a module, and a static framework does not reliably produce one.
      // Run 2 failed on exactly that, in the simulator build only:
      //   Parse Issue (Xcode): Module 'flutter_tts' not found
      // The usual advice is to go back to dynamic frameworks, which ML Kit
      // forbids, so the remaining combination is static plus explicit
      // module maps for everything.
      expect(podfile, contains('use_modular_headers!'),
          reason: 'static frameworks + an Objective-C registrant needs '
              'module maps; without them a Swift plugin is invisible to '
              '@import and the simulator build fails at the registrant');
    });

    test('the deployment target is the one ML Kit requires', () {
      expect(podfile, contains("platform :ios, '15.0'"),
          reason: 'below 15 ML Kit will not install; above it, nothing here '
              'needs the newer floor');
    });

    test('the simulator cannot be asked for arm64', () {
      expect(podfile, contains('EXCLUDED_ARCHS[sdk=iphonesimulator*]'),
          reason: 'ML Kit has no arm64 simulator slice, so Apple Silicon '
              'cannot link a simulator build');
    });

    test('the test target can link the plugin', () {
      expect(podfile, contains("target 'RunnerTests'"));
      expect(podfile, contains('inherit! :search_paths'),
          reason: 'without this the XCTest target cannot see the pod, and '
              'the only native tests in the project do not build');
    });
  });

  group('the Xcode project agrees with the Podfile', () {
    test('every configuration targets the version the pods require', () {
      // Two files state the minimum iOS version and nothing reconciles
      // them. The Podfile's platform governs the pods; the Xcode project
      // governs the app and its test target. Run 3 found them apart:
      //   compiling for iOS 13.0, but module 'pose_camera' has a minimum
      //   deployment target of 15.0
      // Swift refuses to import a module built for a newer floor, so the
      // app compiled and the tests did not — the Flutter template's 13.0
      // against ML Kit's 15.0.
      final podfile = File('${root.path}/app/ios/Podfile').readAsStringSync();
      final platform =
          RegExp(r"platform :ios, '([\d.]+)'").firstMatch(podfile)?.group(1);
      expect(platform, isNotNull, reason: 'the Podfile declares no platform');

      final project = File(
        '${root.path}/app/ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);')
          .allMatches(project)
          .map((match) => match.group(1))
          .toSet();

      expect(targets, isNotEmpty,
          reason: 'the project sets no deployment target at all');
      expect(targets, {platform},
          reason: 'the Xcode project targets $targets while the pods are '
              'built for $platform; Swift will not import across that gap');
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
