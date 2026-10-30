import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

/// Collects the problem kinds a catalog reports, which is what the assertions
/// below care about far more than the human-readable details.
Set<CatalogProblemKind> kinds(ExerciseCatalog catalog) =>
    catalog.validate().map((p) => p.kind).toSet();

void main() {
  group('lookup', () {
    final catalog = ExerciseCatalog([exercise('a'), exercise('b')]);

    test('finds an exercise by id', () {
      expect(catalog['a']!.id, 'a');
    });

    test('returns null for an unknown id', () {
      expect(catalog['nope'], isNull);
    });

    test('require names the missing id so a typo is obvious', () {
      expect(
        () => catalog.require('gobblet_squat'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('gobblet_squat'),
          ),
        ),
      );
    });

    test('exposes exercises in a stable order', () {
      final shuffled = ExerciseCatalog([
        exercise('c'),
        exercise('a'),
        exercise('b'),
      ]);
      expect(shuffled.all.map((e) => e.id), ['a', 'b', 'c']);
    });
  });

  group('candidates', () {
    final catalog = ExerciseCatalog([
      exercise('bodyweight_squat'),
      exercise(
        'goblet_squat',
        requiredEquipment: {Equipment.dumbbells},
        difficulty: Level.intermediate,
      ),
      exercise(
        'barbell_back_squat',
        requiredEquipment: {Equipment.barbell},
        difficulty: Level.advanced,
        contraindications: {BodyPart.knees, BodyPart.lowerBack},
      ),
      exercise(
        'push_up',
        primaryMuscles: {MuscleGroup.chest},
        pattern: MovementPattern.horizontalPush,
      ),
      exercise(
        'db_curl',
        primaryMuscles: {MuscleGroup.biceps},
        pattern: MovementPattern.isolation,
        requiredEquipment: {Equipment.dumbbells},
      ),
      exercise(
        'calf_raise',
        primaryMuscles: {MuscleGroup.calves},
        pattern: MovementPattern.isolation,
      ),
    ]);

    test('filters by movement pattern', () {
      final found = catalog.candidates(
        pattern: MovementPattern.horizontalPush,
        available: Equipment.values.toSet(),
        injuries: const {},
        level: Level.advanced,
      );
      expect(found.map((e) => e.id), ['push_up']);
    });

    test('excludes exercises whose equipment is unavailable', () {
      final found = catalog.candidates(
        pattern: MovementPattern.squat,
        available: const {},
        injuries: const {},
        level: Level.advanced,
      );
      expect(found.map((e) => e.id), ['bodyweight_squat']);
    });

    test('excludes exercises contraindicated by an injury', () {
      final found = catalog.candidates(
        pattern: MovementPattern.squat,
        available: Equipment.values.toSet(),
        injuries: {BodyPart.knees},
        level: Level.advanced,
      );
      expect(found.map((e) => e.id), ['bodyweight_squat', 'goblet_squat']);
    });

    test('excludes exercises above the user level', () {
      final found = catalog.candidates(
        pattern: MovementPattern.squat,
        available: Equipment.values.toSet(),
        injuries: const {},
        level: Level.beginner,
      );
      expect(found.map((e) => e.id), ['bodyweight_squat']);
    });

    test('narrows isolation work by target muscle', () {
      final found = catalog.candidates(
        pattern: MovementPattern.isolation,
        targetMuscle: MuscleGroup.biceps,
        available: Equipment.values.toSet(),
        injuries: const {},
        level: Level.advanced,
      );
      expect(found.map((e) => e.id), ['db_curl']);
    });

    test('returns an empty list rather than throwing when nothing fits', () {
      final found = catalog.candidates(
        pattern: MovementPattern.verticalPull,
        available: const {},
        injuries: const {},
        level: Level.beginner,
      );
      expect(found, isEmpty);
    });
  });

  group('validate', () {
    test('accepts a well-formed catalog', () {
      final catalog = ExerciseCatalog([
        exercise('bodyweight_squat', alternativeIds: ['goblet_squat']),
        exercise(
          'goblet_squat',
          difficulty: Level.intermediate,
          alternativeIds: ['bodyweight_squat'],
          easierId: 'bodyweight_squat',
        ),
      ]);
      expect(catalog.validate(), isEmpty);
    });

    test('reports a duplicate id', () {
      final catalog = ExerciseCatalog([exercise('a'), exercise('a')]);
      expect(kinds(catalog), contains(CatalogProblemKind.duplicateId));
    });

    test('reports an alternative that does not exist', () {
      final catalog = ExerciseCatalog([
        exercise('a', alternativeIds: ['ghost']),
      ]);
      expect(kinds(catalog), contains(CatalogProblemKind.unknownReference));
    });

    test('reports an exercise listing itself as an alternative', () {
      final catalog = ExerciseCatalog([exercise('a', alternativeIds: ['a'])]);
      expect(kinds(catalog), contains(CatalogProblemKind.selfReference));
    });

    test('reports a ladder reference that does not exist', () {
      final catalog = ExerciseCatalog([exercise('a', easierId: 'ghost')]);
      expect(kinds(catalog), contains(CatalogProblemKind.unknownReference));
    });

    test('reports a ladder that runs the wrong way', () {
      // An "easier" variant that is harder than the exercise itself would
      // make the regression path escalate load instead of reducing it.
      final catalog = ExerciseCatalog([
        exercise('a', difficulty: Level.beginner, easierId: 'b'),
        exercise('b', difficulty: Level.advanced),
      ]);
      expect(kinds(catalog), contains(CatalogProblemKind.ladderOutOfOrder));
    });

    test('reports an exercise with no primary muscle', () {
      final catalog = ExerciseCatalog([
        exercise('a', primaryMuscles: const {}),
      ]);
      expect(kinds(catalog), contains(CatalogProblemKind.emptyPrimaryMuscles));
    });

    test('reports a one-way alternative', () {
      // Swapping should be reversible: if A offers B, B must offer A, or the
      // user can swap into a dead end.
      final catalog = ExerciseCatalog([
        exercise('a', alternativeIds: ['b']),
        exercise('b'),
      ]);
      expect(
        kinds(catalog),
        contains(CatalogProblemKind.asymmetricAlternative),
      );
    });

    test('reports an alternative that trains something else', () {
      final catalog = ExerciseCatalog([
        exercise(
          'a',
          primaryMuscles: {MuscleGroup.quads},
          pattern: MovementPattern.squat,
          alternativeIds: ['b'],
        ),
        exercise(
          'b',
          primaryMuscles: {MuscleGroup.biceps},
          pattern: MovementPattern.isolation,
          alternativeIds: ['a'],
        ),
      ]);
      expect(
        kinds(catalog),
        contains(CatalogProblemKind.alternativeMismatch),
      );
    });

    test('reports a recommended angle that is not acceptable', () {
      final catalog = ExerciseCatalog([
        exercise(
          'a',
          camera: cameraSupport(
            recommendedAngle: CameraAngle.front,
            acceptableAngles: {CameraAngle.side},
          ),
        ),
      ]);
      expect(
        kinds(catalog),
        contains(CatalogProblemKind.recommendedAngleNotAcceptable),
      );
    });

    test('reports a recommendation that another angle beats', () {
      // The setup screen asks the user for the recommended placement, so a
      // recommendation that sees less than an alternative is a curation bug.
      final catalog = ExerciseCatalog([
        exercise(
          'a',
          camera: cameraSupport(
            recommendedAngle: CameraAngle.front,
            acceptableAngles: {CameraAngle.side, CameraAngle.front},
            formRuleIds: {'squat_depth', 'knee_valgus'},
            rulesDisabledAt: {
              CameraAngle.front: {'squat_depth'},
            },
          ),
        ),
      ]);
      expect(
        kinds(catalog),
        contains(CatalogProblemKind.recommendedAngleNotBest),
      );
    });

    test('reports a rule that no acceptable angle can evaluate', () {
      final catalog = ExerciseCatalog([
        exercise(
          'a',
          camera: cameraSupport(
            acceptableAngles: {CameraAngle.side},
            formRuleIds: {'squat_depth', 'knee_valgus'},
            rulesDisabledAt: {
              CameraAngle.side: {'knee_valgus'},
            },
          ),
        ),
      ]);
      expect(kinds(catalog), contains(CatalogProblemKind.deadFormRule));
    });

    test('reports rules disabled at an angle the exercise never accepts', () {
      final catalog = ExerciseCatalog([
        exercise(
          'a',
          camera: cameraSupport(
            acceptableAngles: {CameraAngle.side},
            formRuleIds: {'squat_depth'},
            rulesDisabledAt: {
              CameraAngle.front: {'squat_depth'},
            },
          ),
        ),
      ]);
      expect(
        kinds(catalog),
        contains(CatalogProblemKind.disabledAngleNotAcceptable),
      );
    });

    test('reports a disabled rule that is not in the rule set', () {
      final catalog = ExerciseCatalog([
        exercise(
          'a',
          camera: cameraSupport(
            acceptableAngles: {CameraAngle.side, CameraAngle.front},
            formRuleIds: {'squat_depth'},
            rulesDisabledAt: {
              CameraAngle.front: {'typo_rule'},
            },
          ),
        ),
      ]);
      expect(kinds(catalog), contains(CatalogProblemKind.unknownRuleReference));
    });

    test('reports camera support with no rep counter', () {
      final catalog = ExerciseCatalog([
        exercise('a', camera: cameraSupport(repCounterId: '')),
      ]);
      expect(kinds(catalog), contains(CatalogProblemKind.emptyRepCounterId));
    });

    test('reports camera support that carries no form rules', () {
      final catalog = ExerciseCatalog([
        exercise('a', camera: cameraSupport(formRuleIds: const {})),
      ]);
      expect(kinds(catalog), contains(CatalogProblemKind.emptyFormRules));
    });

    test('names the offending exercise in every problem', () {
      final catalog = ExerciseCatalog([
        exercise('the_bad_one', alternativeIds: ['ghost']),
      ]);
      expect(
        catalog.validate().every((p) => p.exerciseId == 'the_bad_one'),
        isTrue,
      );
    });
  });
}
