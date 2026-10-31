import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

/// Every rep-counter configuration the catalog is allowed to reference.
///
/// The coach engine implements these in M5. Listing them here means a typo in
/// a catalog entry fails this test instead of failing silently at runtime by
/// matching no counter at all.
const _knownRepCounters = {
  'squat_knee_angle',
  'pushup_elbow_angle',
  'lunge_knee_angle',
  'bridge_hip_angle',
  'hinge_hip_angle',
  'press_elbow_angle',
  'row_elbow_angle',
  'plank_hold',
};

/// Every form rule the catalog is allowed to reference. Implemented in M6.
const _knownFormRules = {
  'back_arch',
  'back_rounding',
  'bridge_lockout',
  'elbow_flare',
  'elbow_path',
  'heel_lift',
  'hinge_depth',
  'hip_pike',
  'hip_sag',
  'knee_bend',
  'knee_travel',
  'knee_valgus',
  'lockout',
  'lunge_depth',
  'neck_alignment',
  'rom',
  'squat_depth',
  'tempo',
  'torso_lean',
  'torso_swing',
};

/// The eight movements the live coach launches with.
const _launchMovements = {
  'bodyweight_squat',
  'goblet_squat',
  'push_up',
  'forward_lunge',
  'glute_bridge',
  'db_romanian_deadlift',
  'db_shoulder_press',
  'db_bent_over_row',
  'plank',
};

void main() {
  final catalog = standardCatalog;

  group('integrity', () {
    test('has no defects', () {
      // The single most valuable test in this package: it checks every
      // cross-reference, ladder direction, alternative symmetry and camera
      // angle declaration in hand-authored data.
      final problems = catalog.validate();
      expect(
        problems,
        isEmpty,
        reason: 'catalog defects:\n${problems.join('\n')}',
      );
    });

    test('ships a usable number of exercises', () {
      expect(catalog.length, greaterThanOrEqualTo(50));
      expect(catalog.length, standardExercises.length);
    });

    test('exposes exercises in a deterministic order', () {
      final ids = catalog.all.map((e) => e.id).toList();
      expect(ids, orderedEquals(List<String>.from(ids)..sort()));
    });

    test('every name is an ARB key, never user-facing prose', () {
      for (final exercise in catalog.all) {
        expect(
          exercise.nameKey,
          matches(RegExp(r'^exercise_[a-z0-9_]+$')),
          reason: '${exercise.id} has a suspicious nameKey',
        );
      }
    });

    test('the whole catalog survives a json round trip', () {
      for (final exercise in catalog.all) {
        expect(
          Exercise.fromJson(exercise.toJson()),
          equals(exercise),
          reason: '${exercise.id} does not round trip',
        );
      }
    });
  });

  group('camera coverage', () {
    test('covers exactly the launch movements', () {
      expect(
        catalog.cameraSupported.map((e) => e.id).toSet(),
        _launchMovements,
      );
    });

    test('references only rep counters the engine will implement', () {
      for (final exercise in catalog.cameraSupported) {
        expect(
          _knownRepCounters,
          contains(exercise.camera!.repCounterId),
          reason: '${exercise.id} references an unknown rep counter',
        );
      }
    });

    test('references only form rules the engine will implement', () {
      for (final exercise in catalog.cameraSupported) {
        final unknown = exercise.camera!.formRuleIds.difference(
          _knownFormRules,
        );
        expect(
          unknown,
          isEmpty,
          reason: '${exercise.id} references unknown rules: $unknown',
        );
      }
    });

    test('declares no form rule the engine would never be asked for', () {
      // Catches the reverse mistake: a rule we plan to build that nothing
      // actually uses.
      final used = <String>{
        for (final exercise in catalog.cameraSupported)
          ...exercise.camera!.formRuleIds,
      };
      expect(_knownFormRules.difference(used), isEmpty);
    });

    test('the hold-based launch exercise uses a hold counter', () {
      final plank = catalog.require('plank');
      expect(plank.metric, MetricType.holdSeconds);
      expect(plank.camera!.repCounterId, 'plank_hold');
    });

    test('every rep-counted camera exercise recommends the side view', () {
      // Depth, hinge and spinal position all need the side view, so a launch
      // exercise that recommended the front would be coaching blind.
      for (final exercise in catalog.cameraSupported) {
        expect(
          exercise.camera!.recommendedAngle,
          CameraAngle.side,
          reason: '${exercise.id} recommends an unexpected angle',
        );
      }
    });
  });

  group('reachability', () {
    /// Patterns a session template needs to be able to fill.
    const upperPull = {
      MovementPattern.horizontalPull,
      MovementPattern.verticalPull,
    };

    List<Exercise> available(
      TrainingLocation location,
      Level level,
      MovementPattern pattern,
    ) =>
        catalog.candidates(
          available: location.impliedEquipment,
          injuries: const {},
          level: level,
          pattern: pattern,
        );

    test('a full gym can fill every pattern at every level', () {
      for (final level in Level.values) {
        for (final pattern in MovementPattern.values) {
          if (pattern == MovementPattern.carry) continue; // nothing yet
          expect(
            available(TrainingLocation.fullGym, level, pattern),
            isNotEmpty,
            reason: 'fullGym/${level.name} cannot fill ${pattern.name}',
          );
        }
      }
    });

    test('bodyweight at home can fill the patterns it should', () {
      for (final pattern in [
        MovementPattern.squat,
        MovementPattern.hinge,
        MovementPattern.lunge,
        MovementPattern.horizontalPush,
        MovementPattern.core,
        MovementPattern.isolation,
      ]) {
        expect(
          available(TrainingLocation.homeNone, Level.beginner, pattern),
          isNotEmpty,
          reason: 'homeNone/beginner cannot fill ${pattern.name}',
        );
      }
    });

    test('bodyweight at home genuinely cannot train pulling', () {
      // Documented on purpose rather than papered over: there is no honest
      // bodyweight pull without a bar, so the generator has to cope with an
      // unfillable slot instead of inventing an exercise.
      for (final pattern in upperPull) {
        expect(
          available(TrainingLocation.homeNone, Level.advanced, pattern),
          isEmpty,
          reason: 'homeNone unexpectedly fills ${pattern.name}',
        );
      }
    });

    test('dumbbells at home unlock horizontal pulling for a beginner', () {
      expect(
        available(
          TrainingLocation.homeDumbbells,
          Level.beginner,
          MovementPattern.horizontalPull,
        ).map((e) => e.id),
        contains('db_single_arm_row'),
      );
    });

    test('dumbbells at home still cannot train vertical pulling', () {
      expect(
        available(
          TrainingLocation.homeDumbbells,
          Level.advanced,
          MovementPattern.verticalPull,
        ),
        isEmpty,
      );
    });

    test('the camera coach is reachable from every location and level', () {
      for (final location in TrainingLocation.values) {
        for (final level in Level.values) {
          final cameraReady = catalog
              .candidates(
                available: location.impliedEquipment,
                injuries: const {},
                level: level,
              )
              .where((e) => e.isCameraSupported);
          expect(
            cameraReady,
            isNotEmpty,
            reason: '${location.name}/${level.name} has no camera exercise',
          );
        }
      }
    });

    test('a beginner with every common injury still gets a session', () {
      // The four injuries onboarding exposes as checkboxes, all at once.
      final candidates = catalog.candidates(
        available: TrainingLocation.fullGym.impliedEquipment,
        injuries: {
          BodyPart.knees,
          BodyPart.lowerBack,
          BodyPart.shoulders,
          BodyPart.wrists,
        },
        level: Level.beginner,
      );
      expect(candidates.length, greaterThanOrEqualTo(8));
      expect(
        candidates.map((e) => e.pattern).toSet().length,
        greaterThanOrEqualTo(4),
        reason: 'not enough variety left to build a balanced session',
      );
    });
  });

  group('alternatives', () {
    test('every exercise with a clique offers reachable swaps', () {
      final withAlternatives =
          catalog.all.where((e) => e.alternativeIds.isNotEmpty);
      expect(withAlternatives, isNotEmpty);

      for (final exercise in withAlternatives) {
        final swaps = catalog.alternativesFor(
          exercise.id,
          available: TrainingLocation.fullGym.impliedEquipment,
          injuries: const {},
          level: Level.advanced,
        );
        expect(
          swaps,
          isNotEmpty,
          reason: '${exercise.id} has no usable alternative in a full gym',
        );
      }
    });

    test('filters swaps the user cannot perform', () {
      final swaps = catalog.alternativesFor(
        'bodyweight_squat',
        available: const {},
        injuries: const {},
        level: Level.beginner,
      );
      // Everything else in the squat clique needs equipment.
      expect(swaps, isEmpty);
    });

    test('a swap never reintroduces a contraindicated exercise', () {
      final swaps = catalog.alternativesFor(
        'goblet_squat',
        available: TrainingLocation.fullGym.impliedEquipment,
        injuries: {BodyPart.knees},
        level: Level.advanced,
      );
      expect(swaps.map((e) => e.id), isNot(contains('leg_press')));
      expect(swaps.map((e) => e.id), isNot(contains('barbell_back_squat')));
    });
  });

  group('progression ladders', () {
    test('every launch movement has somewhere to go', () {
      // Progression and regression are how M3 responds to good or breaking
      // form, so the camera exercises in particular need a ladder.
      for (final id in _launchMovements) {
        final exercise = catalog.require(id);
        expect(
          exercise.easierId != null || exercise.harderId != null,
          isTrue,
          reason: '$id is a dead end in both directions',
        );
      }
    });

    test('a ladder step never crosses into a different pattern', () {
      for (final exercise in catalog.all) {
        for (final id in [exercise.easierId, exercise.harderId]) {
          if (id == null) continue;
          expect(
            catalog.require(id).pattern,
            exercise.pattern,
            reason: '${exercise.id} ladders into a different pattern',
          );
        }
      }
    });
  });
}
