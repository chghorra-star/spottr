import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';

import 'goal.dart';

/// Everything the generator needs to build a week.
///
/// Deliberately a plain value: generation is a pure function of this request
/// plus the catalog, so the same request always yields the same plan.
@immutable
class PlanRequest {
  const PlanRequest({
    required this.goal,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.level,
    required this.location,
    this.extraEquipment = const {},
    this.injuries = const {},
    this.runWeekdays = const {},
    this.recentExerciseIds = const [],
  });

  final Goal goal;
  final int daysPerWeek;
  final int sessionMinutes;
  final Level level;
  final TrainingLocation location;

  /// Equipment the user owns beyond what [location] implies, e.g. a pull-up
  /// bar in a home gym.
  final Set<Equipment> extraEquipment;

  final Set<BodyPart> injuries;

  /// ISO weekdays the user runs on. Only meaningful for [Goal.hybrid];
  /// Spottr never tracks the runs themselves.
  final Set<int> runWeekdays;

  /// Exercises from recent sessions, deprioritized for variety.
  final List<String> recentExerciseIds;

  /// Everything the user can train with.
  Set<Equipment> get availableEquipment => {
        ...location.impliedEquipment,
        ...extraEquipment,
      };

  /// The prescription implied by the goal.
  GoalPrescription get prescription => GoalPrescription.of(goal);

  /// Throws if the request cannot produce a sensible plan.
  void validate() {
    if (sessionMinutes < 20) {
      throw ArgumentError.value(
        sessionMinutes,
        'sessionMinutes',
        'A session needs at least 20 minutes to be worth programming',
      );
    }
    for (final weekday in runWeekdays) {
      if (weekday < 1 || weekday > 7) {
        throw ArgumentError.value(
          weekday,
          'runWeekdays',
          'Run days are ISO weekdays, 1 (Monday) to 7 (Sunday)',
        );
      }
    }
  }
}
