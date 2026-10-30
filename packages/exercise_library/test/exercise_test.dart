import 'package:exercise_library/exercise_library.dart';
import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('Level', () {
    test('orders beginner below advanced', () {
      expect(Level.beginner.isAtMost(Level.advanced), isTrue);
      expect(Level.advanced.isAtMost(Level.beginner), isFalse);
      expect(Level.intermediate.isAtMost(Level.intermediate), isTrue);
    });
  });

  group('TrainingLocation', () {
    test('home with no equipment implies bodyweight only', () {
      expect(TrainingLocation.homeNone.impliedEquipment, isEmpty);
    });

    test('home with dumbbells implies exactly dumbbells', () {
      expect(
        TrainingLocation.homeDumbbells.impliedEquipment,
        {Equipment.dumbbells},
      );
    });

    test('a full gym implies everything in the catalog vocabulary', () {
      expect(
        TrainingLocation.fullGym.impliedEquipment,
        Equipment.values.toSet(),
      );
    });
  });

  group('MovementPattern', () {
    test('knows which patterns load the legs', () {
      expect(MovementPattern.squat.isLegDominant, isTrue);
      expect(MovementPattern.hinge.isLegDominant, isTrue);
      expect(MovementPattern.lunge.isLegDominant, isTrue);
      expect(MovementPattern.horizontalPush.isLegDominant, isFalse);
      expect(MovementPattern.core.isLegDominant, isFalse);
    });

    test('distinguishes compound work from accessory work', () {
      expect(MovementPattern.squat.isCompound, isTrue);
      expect(MovementPattern.verticalPull.isCompound, isTrue);
      expect(MovementPattern.isolation.isCompound, isFalse);
      expect(MovementPattern.core.isCompound, isFalse);
    });
  });

  group('Exercise availability', () {
    test('a bodyweight exercise is available everywhere', () {
      final pushUp = exercise('push_up');
      expect(pushUp.isAvailableWith(const {}), isTrue);
      expect(pushUp.isAvailableWith({Equipment.barbell}), isTrue);
    });

    test('needs every piece of its required equipment, not just one', () {
      final benchPress = exercise(
        'barbell_bench_press',
        requiredEquipment: {Equipment.barbell, Equipment.bench},
      );
      expect(benchPress.isAvailableWith({Equipment.barbell}), isFalse);
      expect(benchPress.isAvailableWith({Equipment.bench}), isFalse);
      expect(
        benchPress.isAvailableWith({Equipment.barbell, Equipment.bench}),
        isTrue,
      );
    });
  });

  group('Exercise safety', () {
    test('is unsafe when any contraindication matches a declared injury', () {
      final squat = exercise(
        'barbell_back_squat',
        contraindications: {BodyPart.knees, BodyPart.lowerBack},
      );
      expect(squat.isSafeFor(const {}), isTrue);
      expect(squat.isSafeFor({BodyPart.shoulders}), isTrue);
      expect(squat.isSafeFor({BodyPart.knees}), isFalse);
      expect(squat.isSafeFor({BodyPart.shoulders, BodyPart.knees}), isFalse);
    });
  });

  group('Exercise level fit', () {
    test('an exercise is offered only at or below the user level', () {
      final advanced = exercise('pistol_squat', difficulty: Level.advanced);
      expect(advanced.suitsLevel(Level.beginner), isFalse);
      expect(advanced.suitsLevel(Level.intermediate), isFalse);
      expect(advanced.suitsLevel(Level.advanced), isTrue);

      final beginner = exercise('box_squat');
      expect(beginner.suitsLevel(Level.beginner), isTrue);
      expect(beginner.suitsLevel(Level.advanced), isTrue);
    });
  });

  group('CameraSupport', () {
    test('an exercise without camera support reports it', () {
      expect(exercise('leg_press').isCameraSupported, isFalse);
      expect(
        exercise('goblet_squat', camera: cameraSupport()).isCameraSupported,
        isTrue,
      );
    });

    test('enables every rule at an angle with no exclusions', () {
      final support = cameraSupport(
        formRuleIds: {'squat_depth', 'knee_valgus'},
      );
      expect(
        support.rulesEnabledAt(CameraAngle.side),
        {'squat_depth', 'knee_valgus'},
      );
    });

    test('drops only the rules the angle cannot support', () {
      // The core of the angle-gating design: a degraded angle disables the
      // rules it cannot see rather than disabling the whole exercise.
      final support = cameraSupport(
        acceptableAngles: {CameraAngle.side, CameraAngle.front},
        formRuleIds: {'squat_depth', 'knee_valgus', 'back_rounding'},
        rulesDisabledAt: {
          CameraAngle.front: {'squat_depth', 'back_rounding'},
        },
      );

      expect(
        support.rulesEnabledAt(CameraAngle.side),
        {'squat_depth', 'knee_valgus', 'back_rounding'},
      );
      expect(support.rulesEnabledAt(CameraAngle.front), {'knee_valgus'});
    });

    test('enables nothing at an unacceptable angle', () {
      final support = cameraSupport(acceptableAngles: {CameraAngle.side});
      expect(support.rulesEnabledAt(CameraAngle.front), isEmpty);
    });

    test('the recommended angle is the one that sees the most', () {
      // No angle sees everything: depth needs the side, valgus needs the
      // front. The invariant is only that nothing beats the recommendation.
      final support = cameraSupport(
        acceptableAngles: {CameraAngle.side, CameraAngle.front},
        formRuleIds: {'squat_depth', 'back_rounding', 'knee_valgus', 'rom'},
        rulesDisabledAt: {
          CameraAngle.front: {'squat_depth', 'back_rounding'},
          CameraAngle.side: {'knee_valgus'},
        },
      );

      expect(support.enabledRuleCountAt(CameraAngle.side), 3);
      expect(support.enabledRuleCountAt(CameraAngle.front), 2);
      expect(support.recommendedAngleIsBest, isTrue);
    });

    test('spots a recommendation that is beaten by another angle', () {
      final support = cameraSupport(
        recommendedAngle: CameraAngle.front,
        acceptableAngles: {CameraAngle.side, CameraAngle.front},
        formRuleIds: {'squat_depth', 'back_rounding', 'rom'},
        rulesDisabledAt: {
          CameraAngle.front: {'squat_depth', 'back_rounding'},
        },
      );
      expect(support.recommendedAngleIsBest, isFalse);
    });

    test('reports rules that no acceptable angle can evaluate', () {
      final support = cameraSupport(
        acceptableAngles: {CameraAngle.side},
        formRuleIds: {'squat_depth', 'knee_valgus'},
        rulesDisabledAt: {
          CameraAngle.side: {'knee_valgus'},
        },
      );
      expect(support.deadRules, {'knee_valgus'});
    });

    test('has no dead rules when every rule is reachable somewhere', () {
      final support = cameraSupport(
        acceptableAngles: {CameraAngle.side, CameraAngle.front},
        formRuleIds: {'squat_depth', 'knee_valgus'},
        rulesDisabledAt: {
          CameraAngle.front: {'squat_depth'},
          CameraAngle.side: {'knee_valgus'},
        },
      );
      expect(support.deadRules, isEmpty);
    });
  });

  group('json round trip', () {
    test('survives a full exercise with camera support', () {
      final original = exercise(
        'db_romanian_deadlift',
        primaryMuscles: {MuscleGroup.hamstrings, MuscleGroup.glutes},
        secondaryMuscles: {MuscleGroup.lowerBack},
        requiredEquipment: {Equipment.dumbbells},
        difficulty: Level.intermediate,
        pattern: MovementPattern.hinge,
        contraindications: {BodyPart.lowerBack},
        metric: MetricType.reps,
        camera: cameraSupport(
          acceptableAngles: {CameraAngle.side, CameraAngle.front},
          repCounterId: 'hinge_hip_angle',
          formRuleIds: {'back_rounding', 'rom'},
          rulesDisabledAt: {
            CameraAngle.front: {'back_rounding'},
          },
        ),
        alternativeIds: ['barbell_romanian_deadlift'],
        easierId: 'glute_bridge',
        harderId: 'barbell_romanian_deadlift',
        secondsPerRep: 4,
      );

      final restored = Exercise.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('survives a bodyweight hold with no camera support', () {
      final original = exercise(
        'side_plank',
        metric: MetricType.holdSeconds,
        pattern: MovementPattern.core,
      );
      expect(Exercise.fromJson(original.toJson()), equals(original));
    });

    test('rejects an unknown enum value with a useful message', () {
      final json = exercise('push_up').toJson();
      json['pattern'] = 'moonwalk';
      expect(
        () => Exercise.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('moonwalk'), contains('pattern')),
          ),
        ),
      );
    });
  });
}
