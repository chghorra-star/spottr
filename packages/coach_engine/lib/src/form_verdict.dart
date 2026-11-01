import 'package:meta/meta.dart';

import 'form_rule.dart';
import 'rep_event.dart';

/// What a violated rule costs a rep's score.
///
/// The numbers are chosen against the bands `Progression` already uses, not
/// picked for feel. Progression asks two questions of a set's mean form
/// score: is it at or above the ceiling, which earns more weight, and is it
/// below the floor, which takes weight off after a second session. So:
///
/// * a **minor** on every rep has to leave the set earning weight, because a
///   coaching point is not a reason to stall somebody's training;
/// * a **major** on every rep has to hold the weight where it is, which is
///   what "the cue fires every time and the rep still counts" means;
/// * an **unsafe** on every rep has to take weight off, which is the only
///   lever this engine has and the reason it is reached for once and not
///   twice.
///
/// `app/test/domain/form_score_test.dart` pins those three sentences against
/// the real progression table, because the two sets of constants live in
/// packages that do not know about each other.
abstract final class FormScore {
  /// A perfect rep.
  static const double full = 100;

  static const double perMinor = 4;
  static const double perMajor = 18;
  static const double perUnsafe = 35;

  static double penalty(RuleSeverity severity) => switch (severity) {
        RuleSeverity.minor => perMinor,
        RuleSeverity.major => perMajor,
        RuleSeverity.unsafe => perUnsafe,
      };

  /// [full] less the cost of every violation, never below zero.
  static double of(Iterable<RuleSeverity> violations) {
    var score = full;
    for (final severity in violations) {
      score -= penalty(severity);
    }
    return score.clamp(0, full);
  }
}

/// One rule that fired.
@immutable
class FormViolation {
  const FormViolation({required this.ruleId, required this.severity});

  /// The catalog id, never prose. Which words the user sees is the app's
  /// business and the ARB file's.
  final String ruleId;

  final RuleSeverity severity;

  @override
  bool operator ==(Object other) =>
      other is FormViolation &&
      other.ruleId == ruleId &&
      other.severity == severity;

  @override
  int get hashCode => Object.hash(ruleId, severity);

  @override
  String toString() => '$ruleId(${severity.name})';
}

/// What the rules made of one attempt, or of one window of a hold.
///
/// It records what was **not** checked as carefully as what failed. A coach
/// that cannot see the user's heels and says nothing about them is making a
/// claim, and the three reasons it might be silent — the signal was lost,
/// the angle cannot see it, the engine does not do it yet — are three
/// different things to tell somebody.
@immutable
class FormVerdict {
  const FormVerdict({
    this.violations = const [],
    this.passed = 0,
    this.notVisible = const {},
    this.notImplemented = const {},
    this.blind = const {},
  });

  /// Empty: nothing was looked at, which is not the same as nothing being
  /// wrong.
  static const FormVerdict nothing = FormVerdict();

  /// Rules that fired, worst first.
  final List<FormViolation> violations;

  /// How many rules were evaluated and found nothing.
  final int passed;

  /// Rules whose signals were not tracked for enough of the window.
  final Set<String> notVisible;

  /// Rules the engine does not evaluate yet.
  final Set<String> notImplemented;

  /// Rules the camera angle in use cannot see.
  final Set<String> blind;

  /// Rules that produced an answer, either way.
  int get checked => passed + violations.length;

  /// Every rule that did not produce one.
  Set<String> get unchecked => {...notVisible, ...notImplemented, ...blind};

  /// The most serious thing that fired, or `null` if nothing did.
  RuleSeverity? get worst {
    RuleSeverity? worst;
    for (final violation in violations) {
      if (worst == null || violation.severity.index > worst.index) {
        worst = violation.severity;
      }
    }
    return worst;
  }

  /// Whether the coach is willing to interrupt the set over this.
  bool get unsafe => worst == RuleSeverity.unsafe;

  /// Something was checked and nothing fired.
  bool get clean => checked > 0 && violations.isEmpty;

  /// 0 to 100, or `null` when no rule could be evaluated at all.
  ///
  /// `null` rather than 100. A set run with the phone face down would score
  /// perfectly otherwise, and `Progression` already treats a missing form
  /// score as no objection rather than as approval.
  double? get score =>
      checked == 0 ? null : FormScore.of(violations.map((v) => v.severity));

  @override
  String toString() => 'FormVerdict($checked checked, '
      '${violations.length} fired, ${unchecked.length} unchecked)';
}

/// One attempt and what the rules made of it.
@immutable
class RepReview {
  const RepReview({required this.event, required this.verdict});

  final RepEvent event;
  final FormVerdict verdict;

  /// The score this rep contributes, or `null` if it contributes none —
  /// either because nothing was checked or because it was not a rep.
  double? get score => event.counted ? verdict.score : null;

  @override
  String toString() => 'RepReview(${event.index}, $verdict)';
}

/// The whole set: every attempt, what fired, and the one number the
/// progression table reads.
@immutable
class SetReview {
  const SetReview({
    required this.exerciseId,
    required this.reps,
    this.hold,
  });

  final String exerciseId;

  /// Every attempt in order. Empty for a hold.
  final List<RepReview> reps;

  /// A hold's rules over the whole hold. `null` for a rep-counted set.
  final FormVerdict? hold;

  /// Reps that counted.
  int get counted => reps.where((rep) => rep.event.counted).length;

  /// Mean form score over the reps that counted, or the hold's own score.
  ///
  /// `null` when there is nothing to score, which `Progression` reads as no
  /// objection rather than as failure. An attempt that was not counted is
  /// left out: it was not a rep, and scoring it would punish the same
  /// half-rep twice — once by refusing it and once in the number that
  /// decides next week's weight.
  double? get formScore {
    if (reps.isEmpty) return hold?.score;

    var sum = 0.0;
    var scored = 0;
    for (final rep in reps) {
      final score = rep.score;
      if (score == null) continue;
      sum += score;
      scored++;
    }
    return scored == 0 ? null : sum / scored;
  }

  /// How many times each rule fired across the set.
  Map<String, int> get firings {
    final counts = <String, int>{};
    for (final verdict in _verdicts) {
      for (final violation in verdict.violations) {
        counts[violation.ruleId] = (counts[violation.ruleId] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Rules that produced an answer on no rep of the set.
  ///
  /// Checked on one rep and not another is a signal that came and went,
  /// which is tracking and nothing to report. Never checked at all is a
  /// claim the coach should not have made, and this is the list the screen
  /// shows at the end of a set.
  /// A rule that is missing from one verdict's unchecked list answered on
  /// that rep, whether it passed or fired, so the intersection across every
  /// verdict is exactly the set that never answered at all.
  Set<String> get neverChecked {
    final verdicts = _verdicts.toList();
    if (verdicts.isEmpty) return const {};

    var common = verdicts.first.unchecked;
    for (final verdict in verdicts.skip(1)) {
      common = common.intersection(verdict.unchecked);
    }
    return common;
  }

  /// The worst thing that fired anywhere in the set.
  RuleSeverity? get worst {
    RuleSeverity? worst;
    for (final verdict in _verdicts) {
      final candidate = verdict.worst;
      if (candidate == null) continue;
      if (worst == null || candidate.index > worst.index) worst = candidate;
    }
    return worst;
  }

  Iterable<FormVerdict> get _verdicts => [
        for (final rep in reps) rep.verdict,
        ?hold,
      ];

  @override
  String toString() => 'SetReview($exerciseId, $counted counted, '
      'score=${formScore?.toStringAsFixed(0) ?? '-'})';
}
