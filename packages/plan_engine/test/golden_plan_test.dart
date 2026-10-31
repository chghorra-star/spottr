import 'dart:io';

import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

/// Twelve representative profiles, with their plans pinned to a golden file.
///
/// Property tests prove the invariants hold; these show what the generator
/// actually decides, so a change in ranking or prescription shows up as a
/// readable diff instead of passing silently.
///
/// To accept a deliberate change:
///
///     UPDATE_GOLDENS=1 dart test test/golden_plan_test.dart
///
/// Then read the diff before committing it. A golden you did not look at is
/// worse than no golden at all.
const _goldenPath = 'test/golden/week_plans.txt';

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class Profile {
  const Profile(this.label, this.request);

  final String label;
  final PlanRequest request;
}

final _profiles = <Profile>[
  const Profile(
    '01 fat loss, bodyweight at home, 3 days',
    PlanRequest(
      goal: Goal.weightLoss,
      daysPerWeek: 3,
      sessionMinutes: 45,
      level: Level.beginner,
      location: TrainingLocation.homeNone,
    ),
  ),
  const Profile(
    '02 muscle, dumbbells at home, 3 days',
    PlanRequest(
      goal: Goal.muscleBuilding,
      daysPerWeek: 3,
      sessionMinutes: 45,
      level: Level.beginner,
      location: TrainingLocation.homeDumbbells,
    ),
  ),
  const Profile(
    '03 muscle, full gym, beginner, 3 days',
    PlanRequest(
      goal: Goal.muscleBuilding,
      daysPerWeek: 3,
      sessionMinutes: 60,
      level: Level.beginner,
      location: TrainingLocation.fullGym,
    ),
  ),
  const Profile(
    '04 muscle, full gym, intermediate, 4 days',
    PlanRequest(
      goal: Goal.muscleBuilding,
      daysPerWeek: 4,
      sessionMinutes: 60,
      level: Level.intermediate,
      location: TrainingLocation.fullGym,
    ),
  ),
  const Profile(
    '05 fat loss, dumbbells at home, intermediate, 4 days',
    PlanRequest(
      goal: Goal.weightLoss,
      daysPerWeek: 4,
      sessionMinutes: 45,
      level: Level.intermediate,
      location: TrainingLocation.homeDumbbells,
    ),
  ),
  const Profile(
    '06 muscle, full gym, advanced, 5 days',
    PlanRequest(
      goal: Goal.muscleBuilding,
      daysPerWeek: 5,
      sessionMinutes: 75,
      level: Level.advanced,
      location: TrainingLocation.fullGym,
    ),
  ),
  const Profile(
    '07 muscle, full gym, advanced, 6 days',
    PlanRequest(
      goal: Goal.muscleBuilding,
      daysPerWeek: 6,
      sessionMinutes: 90,
      level: Level.advanced,
      location: TrainingLocation.fullGym,
    ),
  ),
  const Profile(
    '08 hybrid, full gym, runs Tue/Thu/Sun, 4 days',
    PlanRequest(
      goal: Goal.hybrid,
      daysPerWeek: 4,
      sessionMinutes: 60,
      level: Level.intermediate,
      location: TrainingLocation.fullGym,
      runWeekdays: {2, 4, 7},
    ),
  ),
  const Profile(
    '09 fat loss, bodyweight, 2 days, 30 minutes',
    PlanRequest(
      goal: Goal.weightLoss,
      daysPerWeek: 2,
      sessionMinutes: 30,
      level: Level.beginner,
      location: TrainingLocation.homeNone,
    ),
  ),
  const Profile(
    '10 muscle, full gym, bad knees, 3 days',
    PlanRequest(
      goal: Goal.muscleBuilding,
      daysPerWeek: 3,
      sessionMinutes: 60,
      level: Level.intermediate,
      location: TrainingLocation.fullGym,
      injuries: {BodyPart.knees},
    ),
  ),
  const Profile(
    '11 muscle, full gym, bad back and shoulders, 4 days',
    PlanRequest(
      goal: Goal.muscleBuilding,
      daysPerWeek: 4,
      sessionMinutes: 60,
      level: Level.advanced,
      location: TrainingLocation.fullGym,
      injuries: {BodyPart.lowerBack, BodyPart.shoulders},
    ),
  ),
  const Profile(
    '12 hybrid, dumbbells and a bar, runs Mon/Fri, 3 days',
    PlanRequest(
      goal: Goal.hybrid,
      daysPerWeek: 3,
      sessionMinutes: 60,
      level: Level.beginner,
      location: TrainingLocation.homeDumbbells,
      extraEquipment: {Equipment.pullUpBar},
      runWeekdays: {1, 5},
    ),
  ),
];

String _renderExercise(PlannedExercise exercise) {
  final target = exercise.metric == MetricType.holdSeconds
      ? '${exercise.holdSeconds}s hold'
      : '${exercise.repsMin}-${exercise.repsMax} reps';
  return '    ${exercise.exerciseId.padRight(26)}'
      '${exercise.priority.name.padRight(10)}'
      '${exercise.sets} x ${target.padRight(13)}'
      'rest ${exercise.restSeconds}s';
}

String _renderPlan(Profile profile) {
  final plan = PlanGenerator(standardCatalog).generate(profile.request);
  final lines = <String>[
    '=== ${profile.label} ===',
    'template: ${plan.templateId}',
  ];

  if (plan.runWeekdays.isNotEmpty) {
    final runs = (plan.runWeekdays.toList()..sort())
        .map((w) => _weekdayNames[w - 1])
        .join(', ');
    lines.add('runs: $runs');
  }
  if (plan.runSuggestionKeys.isNotEmpty) {
    lines.add('run advice: ${plan.runSuggestionKeys.first}');
  }

  for (final day in plan.days) {
    lines.add(
      '${_weekdayNames[day.weekday - 1]} ${day.labelKey}'
      '${day.precedesRunDay ? '  [run tomorrow]' : ''}'
      '  ~${day.estimatedMinutes} min',
    );
    for (final exercise in day.exercises) {
      lines.add(_renderExercise(exercise));
    }
  }

  if (plan.notes.isNotEmpty) {
    lines.add('notes:');
    for (final note in plan.notes) {
      final where =
          note.weekday == null ? '' : ' (${_weekdayNames[note.weekday! - 1]})';
      lines.add('    ${note.kind.name}: ${note.detail}$where');
    }
  }

  return lines.join('\n');
}

void main() {
  test('generated plans match the golden file', () {
    final rendered = '${_profiles.map(_renderPlan).join('\n\n')}\n';
    final file = File(_goldenPath);

    if (Platform.environment['UPDATE_GOLDENS'] == '1') {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(rendered);
      printOnFailure('goldens rewritten');
    }

    expect(
      file.existsSync(),
      isTrue,
      reason: 'missing $_goldenPath; regenerate with UPDATE_GOLDENS=1',
    );
    expect(
      file.readAsStringSync().replaceAll('\r\n', '\n'),
      rendered,
      reason: 'plan output changed; review the diff, then regenerate with '
          'UPDATE_GOLDENS=1 if the change is intended',
    );
  });

  test('every golden profile produces a plan worth doing', () {
    // A golden file records whatever the generator did, including something
    // useless. These assertions keep the recorded plans honest.
    for (final profile in _profiles) {
      final plan = PlanGenerator(standardCatalog).generate(profile.request);
      expect(
        plan.days.length,
        profile.request.daysPerWeek,
        reason: profile.label,
      );
      for (final day in plan.days) {
        expect(
          day.primaryExercises,
          isNotEmpty,
          reason: '${profile.label}: ${day.labelKey} has no compound work',
        );
        expect(
          day.estimatedSeconds,
          lessThanOrEqualTo(profile.request.sessionMinutes * 60),
          reason: profile.label,
        );
      }
    }
  });
}
