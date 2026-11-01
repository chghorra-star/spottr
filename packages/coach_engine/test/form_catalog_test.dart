import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

/// The real catalog, which is what these rules are configuration for.
final catalog = ExerciseCatalog(standardExercises);

/// Problems the validator found about one rule, and nothing about any other.
///
/// A one-entry table is missing every other rule the exercise catalog names,
/// so a test about one rule has to ignore the rest.
List<RuleProblem> problemsFor(String id, Map<String, FormRule> rules) =>
    validateRules(catalog, rules: rules)
        .where((problem) => problem.ruleId == id)
        .toList();

const _knee = JointAngle(
  from: Joint.leftHip,
  vertex: Joint.leftKnee,
  to: Joint.leftAnkle,
);

void main() {
  group('the shipping table', () {
    test('has no problems', () {
      expect(validateRules(catalog), isEmpty);
    });

    test('implements every rule the catalog names, or says it does not', () {
      final named = <String>{
        for (final exercise in catalog.cameraSupported)
          ...exercise.camera!.formRuleIds,
      };

      expect(formCatalog.keys.toSet(), named);
    });

    test('files every rule under its own id', () {
      for (final entry in formCatalog.entries) {
        expect(entry.value.id, entry.key);
      }
    });

    test('the rules it does not evaluate yet are named and explained', () {
      // The honest gap, kept countable. Three of these need the front view,
      // which has no fixtures and no synthetic generator; the fourth needs a
      // signal that can name a side, which `PoseSignal` deliberately cannot
      // because every other launch movement is symmetrical.
      final pending = {
        for (final rule in formCatalog.values)
          if (rule is PendingRule) rule.id: rule.reason,
      };

      expect(pending.keys, {
        'knee_valgus',
        'elbow_flare',
        'elbow_path',
        'knee_travel',
      });
      for (final reason in pending.values) {
        expect(reason, isNotEmpty);
      }
    });

    test('every rule it does evaluate reads a signal or a rep', () {
      for (final rule in formCatalog.values) {
        if (rule is PendingRule) continue;
        final readsPose = rule.signals.isNotEmpty;
        final readsRep =
            rule is RangeConsistencyRule || rule is DescentShareRule;
        expect(
          readsPose || readsRep,
          isTrue,
          reason: '${rule.id} reads nothing, so it can never fire',
        );
      }
    });

    test('one rule is severe enough to stop a set, and it is the spine', () {
      // Not a popularity contest: back rounding under load is the fault that
      // hurts people, and it is the only one the coach is willing to
      // interrupt a set over.
      final unsafe = [
        for (final rule in formCatalog.values)
          if (rule.severity == RuleSeverity.unsafe) rule.id,
      ];

      expect(unsafe, ['back_rounding']);
    });
  });

  group('rulesFor', () {
    test('gives a side-view squat everything the side view can see', () {
      final selection = rulesFor(catalog.require('bodyweight_squat'));

      expect(
        selection.active.map((rule) => rule.id),
        containsAll(['squat_depth', 'back_rounding', 'heel_lift', 'rom']),
      );
      // The one the side view cannot evaluate, which the catalog already
      // knew: a knee falling inwards is invisible side on.
      expect(selection.blind, {'knee_valgus'});
      expect(selection.pending, isEmpty);
    });

    test('drops the rules an acceptable angle cannot evaluate', () {
      final selection = rulesFor(
        catalog.require('bodyweight_squat'),
        angle: CameraAngle.front,
      );

      expect(
        selection.active.map((rule) => rule.id),
        isNot(contains('squat_depth')),
      );
      expect(
        selection.blind,
        containsAll(['squat_depth', 'back_rounding', 'heel_lift']),
      );
    });

    test('separates what it cannot see from what it cannot do', () {
      // From the front a squat loses depth to the angle and knee valgus to
      // the engine, and those are different sentences to say to a user.
      final selection = rulesFor(
        catalog.require('bodyweight_squat'),
        angle: CameraAngle.front,
      );

      expect(selection.pending.map((rule) => rule.id), ['knee_valgus']);
      expect(selection.blind, isNot(contains('knee_valgus')));
    });

    test('runs nothing at an angle the exercise does not accept', () {
      final selection = rulesFor(
        catalog.require('plank'),
        angle: CameraAngle.front,
      );

      expect(selection.active, isEmpty);
      expect(selection.pending, isEmpty);
      expect(selection.blind, catalog.require('plank').camera!.formRuleIds);
    });

    test('is empty for an exercise the camera does not coach', () {
      final selection = rulesFor(catalog.require('barbell_back_squat'));

      expect(selection.active, isEmpty);
      expect(selection.blind, isEmpty);
    });

    test('knows whether it is watching everything', () {
      expect(rulesFor(catalog.require('plank')).complete, isTrue);
      expect(
        rulesFor(catalog.require('bodyweight_squat')).complete,
        isFalse,
      );
    });

    test('every camera exercise has something to check at its best angle', () {
      // A coached exercise with no evaluable rule would show a form panel
      // that never says anything, which reads as a broken coach rather than
      // as an unwatched exercise.
      for (final exercise in catalog.cameraSupported) {
        expect(
          rulesFor(exercise).active,
          isNotEmpty,
          reason: '${exercise.id} has no rule the engine can evaluate',
        );
      }
    });

    test('declares its signals so the analyzer knows what to sample', () {
      final selection = rulesFor(catalog.require('push_up'));

      expect(selection.signals, isNotEmpty);
      for (final rule in selection.active) {
        expect(selection.signals, containsAll(rule.signals));
      }
    });
  });

  group('validateRules', () {
    test('reports a rule the catalog names and the table does not have', () {
      final problems = validateRules(catalog, rules: const {});

      expect(
        problems.map((problem) => problem.kind),
        contains(RuleProblemKind.missingRule),
      );
    });

    test('reports a rule nothing refers to', () {
      final problems = problemsFor('invented', {
        ...formCatalog,
        'invented': const DescentShareRule(
          id: 'invented',
          severity: RuleSeverity.minor,
        ),
      });

      expect(
        problems.map((problem) => problem.kind),
        [RuleProblemKind.unreferenced],
      );
    });

    test('reports an entry filed under the wrong key', () {
      final problems = validateRules(
        catalog,
        rules: {'tempo': const DescentShareRule(id: 'rom', severity: RuleSeverity.minor)},
      ).where((problem) => problem.kind == RuleProblemKind.idMismatch);

      expect(problems, isNotEmpty);
    });

    test('reports a bound that can never be satisfied', () {
      final problems = problemsFor('rom', {
        'rom': const SignalBoundRule(
          id: 'rom',
          severity: RuleSeverity.minor,
          signal: _knee,
          at: RepSample.peak,
          min: 150,
          max: 100,
        ),
      });

      expect(
        problems.map((problem) => problem.kind),
        contains(RuleProblemKind.backwardsBounds),
      );
    });

    test('reports a band that can never be satisfied', () {
      final problems = problemsFor('rom', {
        'rom': const SignalHoldRule(
          id: 'rom',
          severity: RuleSeverity.minor,
          signal: _knee,
          min: 150,
          max: 100,
        ),
      });

      expect(
        problems.map((problem) => problem.kind),
        contains(RuleProblemKind.backwardsBounds),
      );
    });

    test('reports a tolerance that would pass anything', () {
      final problems = problemsFor('rom', {
        'rom': const SignalHoldRule(
          id: 'rom',
          severity: RuleSeverity.minor,
          signal: _knee,
          min: 150,
          tolerance: 1,
        ),
      });

      expect(
        problems.map((problem) => problem.kind),
        contains(RuleProblemKind.toothlessTolerance),
      );
    });

    test('reports a travel bound that no movement could stay inside', () {
      final problems = problemsFor('rom', {
        'rom': const SignalTravelRule(
          id: 'rom',
          severity: RuleSeverity.minor,
          signal: _knee,
          max: 0,
        ),
      });

      expect(
        problems.map((problem) => problem.kind),
        contains(RuleProblemKind.impossibleTravel),
      );
    });

    test('reports a fraction outside the range a fraction can take', () {
      final problems = problemsFor('rom', {
        'rom': const RangeConsistencyRule(
          id: 'rom',
          severity: RuleSeverity.minor,
          minFraction: 1.4,
        ),
      });

      expect(
        problems.map((problem) => problem.kind),
        contains(RuleProblemKind.impossibleFraction),
      );
    });

    test('reports a pending rule with no reason given', () {
      final problems = problemsFor('rom', {
        'rom': const PendingRule(
          id: 'rom',
          severity: RuleSeverity.minor,
          reason: '',
        ),
      });

      expect(
        problems.map((problem) => problem.kind),
        contains(RuleProblemKind.unexplainedGap),
      );
    });

    test('says which rule and what about it, because a test reads this', () {
      final problems = validateRules(catalog, rules: const {});

      expect(problems.first.toString(), contains(problems.first.ruleId));
      expect(problems.first.detail, isNotEmpty);
    });
  });
}
