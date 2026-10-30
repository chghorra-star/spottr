import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'camera_support.dart';
import 'enums.dart';
import 'json.dart';

const _deep = DeepCollectionEquality.unordered();

/// One entry in the curated exercise catalog.
///
/// The plan generator may only pick exercises from the catalog, and the camera
/// coach reads its thresholds and rules from [camera]. Adding an exercise is
/// therefore a data change, not a code change.
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.nameKey,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.requiredEquipment,
    required this.difficulty,
    required this.pattern,
    required this.contraindications,
    required this.isUnilateral,
    required this.metric,
    required this.camera,
    required this.alternativeIds,
    required this.easierId,
    required this.harderId,
    required this.secondsPerRep,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final cameraRaw = json['camera'];
    return Exercise(
      id: parseString(json['id'], 'id'),
      nameKey: parseString(json['nameKey'], 'nameKey'),
      primaryMuscles: parseEnumSet(
        MuscleGroup.values,
        json['primaryMuscles'],
        'primaryMuscles',
      ),
      secondaryMuscles: parseEnumSet(
        MuscleGroup.values,
        json['secondaryMuscles'],
        'secondaryMuscles',
      ),
      requiredEquipment: parseEnumSet(
        Equipment.values,
        json['requiredEquipment'],
        'requiredEquipment',
      ),
      difficulty: parseEnum(Level.values, json['difficulty'], 'difficulty'),
      pattern: parseEnum(MovementPattern.values, json['pattern'], 'pattern'),
      contraindications: parseEnumSet(
        BodyPart.values,
        json['contraindications'],
        'contraindications',
      ),
      isUnilateral: parseBool(json['isUnilateral'], 'isUnilateral'),
      metric: parseEnum(MetricType.values, json['metric'], 'metric'),
      camera: cameraRaw == null
          ? null
          : CameraSupport.fromJson(
              Map<String, dynamic>.from(cameraRaw as Map),
            ),
      alternativeIds: parseStringList(json['alternativeIds'], 'alternativeIds'),
      easierId: json['easierId'] == null
          ? null
          : parseString(json['easierId'], 'easierId'),
      harderId: json['harderId'] == null
          ? null
          : parseString(json['harderId'], 'harderId'),
      secondsPerRep: parseDouble(
        json['secondsPerRep'],
        'secondsPerRep',
        fallback: 3,
      ),
    );
  }

  /// Stable identifier. Referenced by plans, logs, and personal records, so it
  /// must never change once shipped.
  final String id;

  /// ARB key for the display name. The catalog holds no user-facing prose.
  final String nameKey;

  final Set<MuscleGroup> primaryMuscles;
  final Set<MuscleGroup> secondaryMuscles;

  /// Everything needed to perform it. Empty means bodyweight.
  final Set<Equipment> requiredEquipment;

  final Level difficulty;
  final MovementPattern pattern;

  /// Injury sites that rule this exercise out.
  final Set<BodyPart> contraindications;

  /// Whether it trains one side at a time, which affects rep counting and
  /// the side-imbalance check.
  final bool isUnilateral;

  final MetricType metric;

  /// Camera coaching configuration, or null if the camera cannot judge it.
  final CameraSupport? camera;

  /// Curated swaps for the same job. Symmetric by contract: if A offers B,
  /// B offers A, so swapping is never a dead end.
  final List<String> alternativeIds;

  /// Regression target when form breaks down repeatedly.
  final String? easierId;

  /// Progression target when the exercise becomes too easy.
  final String? harderId;

  /// Typical seconds for one controlled rep, used to fit a session into its
  /// time budget. Holds use it as seconds per second, i.e. ignore it.
  final double secondsPerRep;

  bool get isCameraSupported => camera != null;

  /// Whether every required piece of equipment is in [available].
  bool isAvailableWith(Set<Equipment> available) =>
      requiredEquipment.difference(available).isEmpty;

  /// Whether nothing this exercise loads is on the user's injury list.
  bool isSafeFor(Set<BodyPart> injuries) =>
      contraindications.intersection(injuries).isEmpty;

  /// Whether this exercise is at or below the user's experience level.
  ///
  /// Deliberately not "level or one above": offering an advanced movement to
  /// a beginner is how people get hurt, and the catalog carries enough
  /// beginner work that there is no need to stretch.
  bool suitsLevel(Level level) => difficulty.isAtMost(level);

  /// Whether this trains any of [muscles] as a primary target.
  bool targetsAny(Set<MuscleGroup> muscles) =>
      primaryMuscles.intersection(muscles).isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameKey': nameKey,
        'primaryMuscles': _names(MuscleGroup.values, primaryMuscles),
        if (secondaryMuscles.isNotEmpty)
          'secondaryMuscles': _names(MuscleGroup.values, secondaryMuscles),
        if (requiredEquipment.isNotEmpty)
          'requiredEquipment': _names(Equipment.values, requiredEquipment),
        'difficulty': difficulty.name,
        'pattern': pattern.name,
        if (contraindications.isNotEmpty)
          'contraindications': _names(BodyPart.values, contraindications),
        if (isUnilateral) 'isUnilateral': true,
        'metric': metric.name,
        if (camera != null) 'camera': camera!.toJson(),
        if (alternativeIds.isNotEmpty) 'alternativeIds': alternativeIds,
        if (easierId != null) 'easierId': easierId,
        if (harderId != null) 'harderId': harderId,
        'secondsPerRep': secondsPerRep,
      };

  /// Enum names in declaration order, so serialized output is stable.
  static List<String> _names<T extends Enum>(List<T> all, Set<T> selected) => [
        for (final value in all)
          if (selected.contains(value)) value.name,
      ];

  @override
  bool operator ==(Object other) =>
      other is Exercise &&
      other.id == id &&
      other.nameKey == nameKey &&
      _deep.equals(other.primaryMuscles, primaryMuscles) &&
      _deep.equals(other.secondaryMuscles, secondaryMuscles) &&
      _deep.equals(other.requiredEquipment, requiredEquipment) &&
      other.difficulty == difficulty &&
      other.pattern == pattern &&
      _deep.equals(other.contraindications, contraindications) &&
      other.isUnilateral == isUnilateral &&
      other.metric == metric &&
      other.camera == camera &&
      const ListEquality<String>().equals(other.alternativeIds, alternativeIds) &&
      other.easierId == easierId &&
      other.harderId == harderId &&
      other.secondsPerRep == secondsPerRep;

  @override
  int get hashCode => Object.hashAll([
        id,
        nameKey,
        _deep.hash(primaryMuscles),
        _deep.hash(secondaryMuscles),
        _deep.hash(requiredEquipment),
        difficulty,
        pattern,
        _deep.hash(contraindications),
        isUnilateral,
        metric,
        camera,
        const ListEquality<String>().hash(alternativeIds),
        easierId,
        harderId,
        secondsPerRep,
      ]);

  @override
  String toString() => 'Exercise($id, ${pattern.name}, '
      '${difficulty.name}${isCameraSupported ? ', camera' : ''})';
}
