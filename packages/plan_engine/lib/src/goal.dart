import 'package:meta/meta.dart';

/// What the user is training for.
enum Goal {
  weightLoss,
  muscleBuilding,

  /// Gym work alongside running. Spottr never tracks the runs; it schedules
  /// around them and offers text suggestions only.
  hybrid,
}

/// Prescription defaults derived from the goal.
///
/// These are the knobs that make the same template produce a different
/// session for a fat-loss user and a hypertrophy user: rep ranges, rest, and
/// how long a hold should last.
@immutable
class GoalPrescription {
  const GoalPrescription({
    required this.compoundRepsMin,
    required this.compoundRepsMax,
    required this.accessoryRepsMin,
    required this.accessoryRepsMax,
    required this.restSeconds,
    required this.holdSeconds,
  });

  /// The prescription for [goal].
  factory GoalPrescription.of(Goal goal) => switch (goal) {
        // Shorter rest and higher reps keep the heart rate up.
        Goal.weightLoss => const GoalPrescription(
            compoundRepsMin: 12,
            compoundRepsMax: 15,
            accessoryRepsMin: 15,
            accessoryRepsMax: 20,
            restSeconds: 45,
            holdSeconds: 40,
          ),
        Goal.muscleBuilding => const GoalPrescription(
            compoundRepsMin: 8,
            compoundRepsMax: 12,
            accessoryRepsMin: 12,
            accessoryRepsMax: 15,
            restSeconds: 75,
            holdSeconds: 45,
          ),
        // Middle ground: enough rest to lift well, little enough to leave
        // something in the tank for running days.
        Goal.hybrid => const GoalPrescription(
            compoundRepsMin: 8,
            compoundRepsMax: 12,
            accessoryRepsMin: 12,
            accessoryRepsMax: 15,
            restSeconds: 60,
            holdSeconds: 45,
          ),
      };

  final int compoundRepsMin;
  final int compoundRepsMax;
  final int accessoryRepsMin;
  final int accessoryRepsMax;
  final int restSeconds;
  final int holdSeconds;

  /// Midpoint of the compound range, used when estimating session length.
  int get compoundRepsMid => (compoundRepsMin + compoundRepsMax) ~/ 2;

  /// Midpoint of the accessory range.
  int get accessoryRepsMid => (accessoryRepsMin + accessoryRepsMax) ~/ 2;
}
