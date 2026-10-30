import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'enums.dart';
import 'exercise.dart';

/// Kinds of defect the catalog validator can report.
///
/// The catalog is hand-authored data, so these checks exist to catch
/// authoring slips at test time rather than at runtime in front of a user
/// mid-workout.
enum CatalogProblemKind {
  /// Two entries share an id.
  duplicateId,

  /// An alternative or ladder id that no entry provides.
  unknownReference,

  /// An entry points at itself.
  selfReference,

  /// An "easier" variant that is harder, or a "harder" one that is easier.
  ladderOutOfOrder,

  /// An entry that trains nothing in particular.
  emptyPrimaryMuscles,

  /// A offers B as an alternative but B does not offer A, so swapping into B
  /// is a dead end.
  asymmetricAlternative,

  /// An alternative that does a different job, so swapping would silently
  /// change what the session trains.
  alternativeMismatch,

  /// The recommended camera angle is not in the acceptable set.
  recommendedAngleNotAcceptable,

  /// Rules are disabled at an angle the exercise never accepts.
  disabledAngleNotAcceptable,

  /// A disabled rule id is not part of the exercise's rule set, which almost
  /// always means a typo.
  unknownRuleReference,

  /// Camera support without a rep counter cannot count anything.
  emptyRepCounterId,

  /// Another acceptable angle evaluates more rules than the recommended one,
  /// so the setup screen would ask for the wrong placement.
  recommendedAngleNotBest,

  /// A rule that is disabled at every acceptable angle, so it can never fire.
  deadFormRule,

  /// Camera support with no form rules offers no coaching.
  emptyFormRules,
}

/// One defect found in the catalog.
@immutable
class CatalogProblem {
  const CatalogProblem(this.exerciseId, this.kind, this.detail);

  /// The entry at fault.
  final String exerciseId;
  final CatalogProblemKind kind;

  /// Human-readable specifics, written to be actionable in a test failure.
  final String detail;

  @override
  String toString() => '[$exerciseId] ${kind.name}: $detail';
}

/// The curated exercise library.
///
/// Lookup, filtering, and integrity validation. Ranking is deliberately not
/// here: which candidate is *best* depends on the plan being built, so it
/// belongs to the plan engine.
class ExerciseCatalog {
  ExerciseCatalog(Iterable<Exercise> exercises)
      : _source = List<Exercise>.unmodifiable(exercises) {
    for (final exercise in _source) {
      _byId.putIfAbsent(exercise.id, () => exercise);
    }
    _sorted = _byId.values.sortedBy((e) => e.id);
  }

  final List<Exercise> _source;
  final Map<String, Exercise> _byId = {};
  late final List<Exercise> _sorted;

  /// Every exercise, ordered by id so output is reproducible.
  List<Exercise> get all => List<Exercise>.unmodifiable(_sorted);

  /// Exercises the camera coach can judge.
  List<Exercise> get cameraSupported =>
      _sorted.where((e) => e.isCameraSupported).toList();

  int get length => _byId.length;

  /// Looks up by id, or null.
  Exercise? operator [](String id) => _byId[id];

  /// Looks up by id, throwing a message that names the id when it is missing.
  Exercise require(String id) {
    final found = _byId[id];
    if (found == null) {
      throw ArgumentError.value(id, 'id', 'No exercise with id "$id"');
    }
    return found;
  }

  /// Exercises that fit all of the given constraints, ordered by id.
  ///
  /// Every filter is a hard constraint: nothing here is a preference. A user
  /// who cannot do an exercise safely should never see it ranked low, they
  /// should never see it at all.
  List<Exercise> candidates({
    required Set<Equipment> available,
    required Set<BodyPart> injuries,
    required Level level,
    MovementPattern? pattern,
    MuscleGroup? targetMuscle,
    MetricType? metric,
  }) =>
      _sorted.where((exercise) {
        if (pattern != null && exercise.pattern != pattern) return false;
        if (metric != null && exercise.metric != metric) return false;
        if (targetMuscle != null &&
            !exercise.primaryMuscles.contains(targetMuscle)) {
          return false;
        }
        if (!exercise.isAvailableWith(available)) return false;
        if (!exercise.isSafeFor(injuries)) return false;
        if (!exercise.suitsLevel(level)) return false;
        return true;
      }).toList();

  /// Curated swaps for [id] that the user can actually do right now.
  List<Exercise> alternativesFor(
    String id, {
    required Set<Equipment> available,
    required Set<BodyPart> injuries,
    required Level level,
  }) {
    final exercise = require(id);
    return exercise.alternativeIds
        .map((altId) => _byId[altId])
        .whereType<Exercise>()
        .where(
          (alt) =>
              alt.isAvailableWith(available) &&
              alt.isSafeFor(injuries) &&
              alt.suitsLevel(level),
        )
        .sortedBy((e) => e.id);
  }

  /// Every defect in the catalog. An empty result is the shipping condition,
  /// asserted by `standard_catalog_test.dart`.
  List<CatalogProblem> validate() {
    final problems = <CatalogProblem>[];

    final seen = <String>{};
    for (final exercise in _source) {
      if (!seen.add(exercise.id)) {
        problems.add(
          CatalogProblem(
            exercise.id,
            CatalogProblemKind.duplicateId,
            'appears more than once',
          ),
        );
      }
    }

    for (final exercise in _sorted) {
      problems.addAll(_validateEntry(exercise));
    }

    return problems;
  }

  Iterable<CatalogProblem> _validateEntry(Exercise exercise) {
    final problems = <CatalogProblem>[];
    final id = exercise.id;

    if (exercise.primaryMuscles.isEmpty) {
      problems.add(
        CatalogProblem(
          id,
          CatalogProblemKind.emptyPrimaryMuscles,
          'has no primary muscle group',
        ),
      );
    }

    for (final altId in exercise.alternativeIds) {
      if (altId == id) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.selfReference,
            'lists itself as an alternative',
          ),
        );
        continue;
      }
      final alt = _byId[altId];
      if (alt == null) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.unknownReference,
            'alternative "$altId" does not exist',
          ),
        );
        continue;
      }
      if (!alt.alternativeIds.contains(id)) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.asymmetricAlternative,
            'offers "$altId" but "$altId" does not offer it back',
          ),
        );
      }
      final sharesJob = alt.pattern == exercise.pattern &&
          alt.primaryMuscles.intersection(exercise.primaryMuscles).isNotEmpty;
      if (!sharesJob) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.alternativeMismatch,
            'alternative "$altId" is ${alt.pattern.name} for '
            '${alt.primaryMuscles.map((m) => m.name).join('/')}, '
            'not ${exercise.pattern.name} for '
            '${exercise.primaryMuscles.map((m) => m.name).join('/')}',
          ),
        );
      }
    }

    problems.addAll(
      _validateLadder(exercise, exercise.easierId, isEasier: true),
    );
    problems.addAll(
      _validateLadder(exercise, exercise.harderId, isEasier: false),
    );

    final camera = exercise.camera;
    if (camera != null) {
      if (camera.repCounterId.isEmpty) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.emptyRepCounterId,
            'has camera support but no rep counter config',
          ),
        );
      }
      if (camera.formRuleIds.isEmpty) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.emptyFormRules,
            'has camera support but no form rules',
          ),
        );
      }
      if (!camera.acceptableAngles.contains(camera.recommendedAngle)) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.recommendedAngleNotAcceptable,
            'recommends ${camera.recommendedAngle.name} but accepts only '
            '${camera.acceptableAngles.map((a) => a.name).join(', ')}',
          ),
        );
      }
      if (!camera.recommendedAngleIsBest) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.recommendedAngleNotBest,
            'recommends ${camera.recommendedAngle.name} '
            '(${camera.enabledRuleCountAt(camera.recommendedAngle)} rules) '
            'while another acceptable angle evaluates more',
          ),
        );
      }
      final dead = camera.deadRules;
      if (dead.isNotEmpty) {
        problems.add(
          CatalogProblem(
            id,
            CatalogProblemKind.deadFormRule,
            'rules ${dead.join(', ')} are disabled at every acceptable angle, '
            'so they would never fire',
          ),
        );
      }
      for (final entry in camera.rulesDisabledAt.entries) {
        if (!camera.acceptableAngles.contains(entry.key)) {
          problems.add(
            CatalogProblem(
              id,
              CatalogProblemKind.disabledAngleNotAcceptable,
              'disables rules at ${entry.key.name}, which is not an '
              'acceptable angle',
            ),
          );
        }
        final unknown = entry.value.difference(camera.formRuleIds);
        if (unknown.isNotEmpty) {
          problems.add(
            CatalogProblem(
              id,
              CatalogProblemKind.unknownRuleReference,
              'disables ${unknown.join(', ')} at ${entry.key.name}, which is '
              'not in its rule set',
            ),
          );
        }
      }
    }

    return problems;
  }

  Iterable<CatalogProblem> _validateLadder(
    Exercise exercise,
    String? targetId, {
    required bool isEasier,
  }) {
    if (targetId == null) return const [];
    final label = isEasier ? 'easierId' : 'harderId';
    final id = exercise.id;

    if (targetId == id) {
      return [
        CatalogProblem(
          id,
          CatalogProblemKind.selfReference,
          '$label points at itself',
        ),
      ];
    }

    final target = _byId[targetId];
    if (target == null) {
      return [
        CatalogProblem(
          id,
          CatalogProblemKind.unknownReference,
          '$label "$targetId" does not exist',
        ),
      ];
    }

    final ordered = isEasier
        ? target.difficulty.isAtMost(exercise.difficulty)
        : exercise.difficulty.isAtMost(target.difficulty);
    if (!ordered) {
      return [
        CatalogProblem(
          id,
          CatalogProblemKind.ladderOutOfOrder,
          '$label "$targetId" is ${target.difficulty.name} while this is '
          '${exercise.difficulty.name}',
        ),
      ];
    }
    return const [];
  }

  /// Rules the coach can evaluate for [id] at [angle]. Empty when the
  /// exercise has no camera support or the angle is unusable.
  Set<String> rulesFor(String id, CameraAngle angle) =>
      require(id).camera?.rulesEnabledAt(angle) ?? const {};
}
