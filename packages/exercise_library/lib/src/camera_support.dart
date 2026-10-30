import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pose_core/pose_core.dart';

import 'json.dart';

const _deep = DeepCollectionEquality.unordered();

/// How the live camera coach handles one exercise.
///
/// This is the configuration that lets a new exercise be added without
/// touching engine code: it names a rep-counter config, names the form rules
/// that apply, and says which of those rules a given camera angle cannot see.
@immutable
class CameraSupport {
  const CameraSupport({
    required this.recommendedAngle,
    required this.acceptableAngles,
    required this.repCounterId,
    required this.formRuleIds,
    this.rulesDisabledAt = const {},
  });

  factory CameraSupport.fromJson(Map<String, dynamic> json) {
    final disabledRaw = json['rulesDisabledAt'];
    final disabled = <CameraAngle, Set<String>>{};
    if (disabledRaw != null) {
      if (disabledRaw is! Map) {
        throw FormatException(
          'camera.rulesDisabledAt: expected a map, got ${disabledRaw.runtimeType}',
        );
      }
      for (final entry in disabledRaw.entries) {
        final angle = parseEnum(
          CameraAngle.values,
          entry.key,
          'camera.rulesDisabledAt key',
        );
        disabled[angle] = parseStringList(
          entry.value,
          'camera.rulesDisabledAt.${angle.name}',
        ).toSet();
      }
    }

    return CameraSupport(
      recommendedAngle: parseEnum(
        CameraAngle.values,
        json['recommendedAngle'],
        'camera.recommendedAngle',
      ),
      acceptableAngles: parseEnumSet(
        CameraAngle.values,
        json['acceptableAngles'],
        'camera.acceptableAngles',
      ),
      repCounterId: parseString(json['repCounterId'], 'camera.repCounterId'),
      formRuleIds:
          parseStringList(json['formRuleIds'], 'camera.formRuleIds').toSet(),
      rulesDisabledAt: disabled,
    );
  }

  /// The angle that supports the full rule set. The setup screen asks for
  /// this one.
  final CameraAngle recommendedAngle;

  /// Angles the coach will run at. An angle outside this set means reps are
  /// not counted at all, and the setup screen refuses to start.
  final Set<CameraAngle> acceptableAngles;

  /// Which rep-counter configuration drives the state machine.
  final String repCounterId;

  /// Every form rule that applies to this exercise at its best angle.
  final Set<String> formRuleIds;

  /// Rules that a given acceptable angle cannot evaluate.
  ///
  /// This is what keeps the two safety requirements from contradicting each
  /// other: a rep is only ever rejected as unsafe by a rule that was enabled
  /// at the angle in use, so a blind spot can never cost the user a rep.
  final Map<CameraAngle, Set<String>> rulesDisabledAt;

  /// Rules that can actually be evaluated at [angle].
  ///
  /// Empty when the angle is not acceptable at all.
  Set<String> rulesEnabledAt(CameraAngle angle) {
    if (!acceptableAngles.contains(angle)) return const {};
    final disabled = rulesDisabledAt[angle] ?? const <String>{};
    return formRuleIds.difference(disabled);
  }

  /// Whether the recommended angle really does support everything. A
  /// recommendation that disables a rule is a curation error, and the catalog
  /// validator reports it.
  int enabledRuleCountAt(CameraAngle angle) => rulesEnabledAt(angle).length;

  /// Whether the recommended angle really is the most informative one.
  ///
  /// No single angle can evaluate every rule — depth needs the side view and
  /// knee valgus needs the front — so the invariant is not that the
  /// recommendation sees everything, only that nothing else sees more.
  bool get recommendedAngleIsBest {
    final best = enabledRuleCountAt(recommendedAngle);
    return acceptableAngles.every((angle) => enabledRuleCountAt(angle) <= best);
  }

  /// Rules that no acceptable angle can evaluate.
  ///
  /// A rule listed here would never fire, which means either the rule is
  /// pointless for this exercise or an angle is missing from
  /// [acceptableAngles].
  Set<String> get deadRules {
    final reachable = <String>{
      for (final angle in acceptableAngles) ...rulesEnabledAt(angle),
    };
    return formRuleIds.difference(reachable);
  }

  Map<String, dynamic> toJson() => {
        'recommendedAngle': recommendedAngle.name,
        'acceptableAngles': [
          for (final angle in CameraAngle.values)
            if (acceptableAngles.contains(angle)) angle.name,
        ],
        'repCounterId': repCounterId,
        'formRuleIds': formRuleIds.toList()..sort(),
        if (rulesDisabledAt.isNotEmpty)
          'rulesDisabledAt': {
            for (final angle in CameraAngle.values)
              if (rulesDisabledAt[angle]?.isNotEmpty ?? false)
                angle.name: rulesDisabledAt[angle]!.toList()..sort(),
          },
      };

  @override
  bool operator ==(Object other) =>
      other is CameraSupport &&
      other.recommendedAngle == recommendedAngle &&
      _deep.equals(other.acceptableAngles, acceptableAngles) &&
      other.repCounterId == repCounterId &&
      _deep.equals(other.formRuleIds, formRuleIds) &&
      _deep.equals(other.rulesDisabledAt, rulesDisabledAt);

  @override
  int get hashCode => Object.hash(
        recommendedAngle,
        _deep.hash(acceptableAngles),
        repCounterId,
        _deep.hash(formRuleIds),
        _deep.hash(rulesDisabledAt),
      );

  @override
  String toString() => 'CameraSupport($repCounterId, '
      'best=${recommendedAngle.name}, ${formRuleIds.length} rules)';
}
