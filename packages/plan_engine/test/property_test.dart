import 'dart:math';

import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

/// Randomized profiles, checked against invariants rather than against a
/// known answer.
///
/// Golden tests pin what the generator produces today; these pin what must be
/// true of anything it ever produces. The seed is fixed so a failure is
/// reproducible, and the failing request is printed in the reason.
const _seed = 20261030;
const _cases = 300;

final _generator = PlanGenerator(standardCatalog);
final _edits = PlanEdits(standardCatalog);

const _sessionLengths = [20, 30, 45, 60, 75, 90];

PlanRequest _randomRequest(Random random) {
  final injuries = <BodyPart>{};
  final injuryCount = random.nextInt(3);
  for (var i = 0; i < injuryCount; i++) {
    injuries.add(BodyPart.values[random.nextInt(BodyPart.values.length)]);
  }

  final runWeekdays = <int>{};
  final runCount = random.nextInt(4);
  for (var i = 0; i < runCount; i++) {
    runWeekdays.add(random.nextInt(7) + 1);
  }

  final extras = <Equipment>{};
  if (random.nextBool()) {
    extras.add(Equipment.values[random.nextInt(Equipment.values.length)]);
  }

  return PlanRequest(
    goal: Goal.values[random.nextInt(Goal.values.length)],
    daysPerWeek: 2 + random.nextInt(5),
    sessionMinutes: _sessionLengths[random.nextInt(_sessionLengths.length)],
    level: Level.values[random.nextInt(Level.values.length)],
    location:
        TrainingLocation.values[random.nextInt(TrainingLocation.values.length)],
    extraEquipment: extras,
    injuries: injuries,
    runWeekdays: runWeekdays,
  );
}

String _describe(PlanRequest request) => '${request.goal.name} / '
    '${request.level.name} / ${request.location.name} / '
    '${request.daysPerWeek}d / ${request.sessionMinutes}min / '
    'injuries=${request.injuries.map((i) => i.name).toList()} / '
    'runs=${request.runWeekdays.toList()..sort()}';

/// Everything that must hold for any plan, however the request was built.
void _checkInvariants(WeekPlan plan, PlanRequest request) {
  final context = _describe(request);

  expect(plan.days.length, request.daysPerWeek, reason: context);

  final weekdays = plan.days.map((d) => d.weekday).toList();
  expect(weekdays.toSet().length, weekdays.length, reason: context);
  expect(
    weekdays,
    orderedEquals(List<int>.from(weekdays)..sort()),
    reason: context,
  );
  for (final weekday in weekdays) {
    expect(weekday, inInclusiveRange(1, 7), reason: context);
  }

  for (final day in plan.days) {
    expect(day.exercises, isNotEmpty, reason: '$context day ${day.weekday}');
    expect(
      day.primaryExercises,
      isNotEmpty,
      reason: '$context day ${day.weekday} has no compound work',
    );
    expect(
      day.estimatedSeconds,
      lessThanOrEqualTo(request.sessionMinutes * 60),
      reason: '$context day ${day.weekday} overruns',
    );

    expect(
      day.exercises.fold(0, (sum, e) => sum + e.sets),
      lessThanOrEqualTo(DayRules.maxWorkingSetsPerDay),
      reason: '$context day ${day.weekday} is more volume than a session '
          'should carry',
    );

    final ids = day.exercises.map((e) => e.exerciseId).toList();
    expect(ids.toSet().length, ids.length, reason: '$context duplicate: $ids');

    for (final planned in day.exercises) {
      final exercise = standardCatalog.require(planned.exerciseId);

      expect(
        exercise.isSafeFor(request.injuries),
        isTrue,
        reason: '$context prescribed ${exercise.id} against an injury',
      );
      expect(
        exercise.isAvailableWith(request.availableEquipment),
        isTrue,
        reason: '$context prescribed ${exercise.id} without the equipment',
      );
      expect(
        exercise.suitsLevel(request.level),
        isTrue,
        reason: '$context prescribed ${exercise.id} above level',
      );

      expect(planned.sets, greaterThan(0), reason: context);
      // Sets move in both directions around the template's baseline: down
      // to fit a short session, up to use a long one. What must hold is the
      // cap, which is what keeps "use the time available" from becoming
      // junk volume.
      expect(
        planned.sets,
        lessThanOrEqualTo(DayRules.maxSetsFor(planned.priority)),
        reason: '$context prescribed more sets than the slot allows',
      );

      if (planned.metric == MetricType.reps) {
        expect(planned.repsMin, isNotNull, reason: context);
        expect(planned.repsMax, isNotNull, reason: context);
        expect(planned.repsMin!, lessThanOrEqualTo(planned.repsMax!));
        expect(planned.holdSeconds, isNull, reason: context);
      } else {
        expect(planned.holdSeconds, isNotNull, reason: context);
        expect(planned.repsMin, isNull, reason: context);
      }

      // The pre-run rule: never heavy leg work the night before a run.
      if (day.precedesRunDay &&
          planned.isPrimary &&
          planned.slotPattern.isLegDominant) {
        expect(
          planned.sets,
          lessThanOrEqualTo(DayRules.preRunLegSetCap),
          reason: '$context left heavy legs before a run',
        );
      }
    }
  }

  // A session is never scheduled on a run day unless the week has no room.
  final clashes = plan.days
      .map((d) => d.weekday)
      .toSet()
      .intersection(request.runWeekdays);
  if (clashes.isNotEmpty) {
    expect(
      request.daysPerWeek + request.runWeekdays.length,
      greaterThan(7),
      reason: '$context clashed with a run day despite having room',
    );
  }

  for (final note in plan.notes) {
    if (note.weekday != null) {
      expect(note.weekday, inInclusiveRange(1, 7), reason: context);
    }
    expect(note.detail, isNotEmpty, reason: context);
  }

  if (request.goal != Goal.hybrid) {
    expect(plan.runSuggestionKeys, isEmpty, reason: context);
  }
}

void main() {
  test('every generated plan satisfies the invariants', () {
    final random = Random(_seed);
    for (var i = 0; i < _cases; i++) {
      final request = _randomRequest(random);
      _checkInvariants(_generator.generate(request), request);
    }
  });

  test('generation is reproducible for the same request', () {
    final random = Random(_seed);
    for (var i = 0; i < 50; i++) {
      final request = _randomRequest(random);
      final first = _generator.generate(request);
      final second = _generator.generate(request);
      expect(
        second.allExercises.map((e) => '${e.exerciseId}x${e.sets}').toList(),
        first.allExercises.map((e) => '${e.exerciseId}x${e.sets}').toList(),
        reason: _describe(request),
      );
    }
  });

  test('a swap leaves the plan valid', () {
    final random = Random(_seed + 1);
    var swapsExercised = 0;

    for (var i = 0; i < 100; i++) {
      final request = _randomRequest(random);
      final plan = _generator.generate(request);
      final day = plan.days[random.nextInt(plan.days.length)];
      final target = day.exercises[random.nextInt(day.exercises.length)];

      final options = _edits.alternativesFor(
        plan: plan,
        weekday: day.weekday,
        exerciseId: target.exerciseId,
        request: request,
      );
      if (options.isEmpty) continue;

      final swapped = _edits.swapExercise(
        plan: plan,
        weekday: day.weekday,
        exerciseId: target.exerciseId,
        replacementId: options[random.nextInt(options.length)].id,
        request: request,
      );
      _checkInvariants(swapped, request);
      swapsExercised++;
    }

    expect(swapsExercised, greaterThan(20), reason: 'too few swaps tested');
  });

  test('a reorder leaves the plan valid', () {
    final random = Random(_seed + 2);
    for (var i = 0; i < 100; i++) {
      final request = _randomRequest(random);
      final plan = _generator.generate(request);
      final day = plan.days[random.nextInt(plan.days.length)];
      if (day.exercises.length < 2) continue;

      final reordered = _edits.reorderExercise(
        plan: plan,
        weekday: day.weekday,
        fromIndex: random.nextInt(day.exercises.length),
        toIndex: random.nextInt(day.exercises.length),
      );
      _checkInvariants(reordered, request);
      expect(
        reordered.days
            .firstWhere((d) => d.weekday == day.weekday)
            .exercises
            .map((e) => e.exerciseId)
            .toSet(),
        day.exercises.map((e) => e.exerciseId).toSet(),
        reason: 'reorder changed which exercises are prescribed',
      );
    }
  });

  test('a day move leaves the plan valid', () {
    final random = Random(_seed + 3);
    var movesExercised = 0;

    for (var i = 0; i < 150; i++) {
      final request = _randomRequest(random);
      final plan = _generator.generate(request);
      final occupied = plan.days.map((d) => d.weekday).toSet();
      final free = [
        for (var weekday = 1; weekday <= 7; weekday++)
          if (!occupied.contains(weekday)) weekday,
      ];
      if (free.isEmpty) continue;

      final moved = _edits.moveDay(
        plan: plan,
        fromWeekday: plan.days[random.nextInt(plan.days.length)].weekday,
        toWeekday: free[random.nextInt(free.length)],
        request: request,
      );

      // A deliberate move can legitimately land on a run day, so the
      // no-clash invariant does not apply here; everything else does.
      expect(moved.days.length, request.daysPerWeek);
      for (final day in moved.days) {
        expect(day.exercises, isNotEmpty);
        expect(
          day.estimatedSeconds,
          lessThanOrEqualTo(request.sessionMinutes * 60),
        );
        for (final planned in day.exercises) {
          if (day.precedesRunDay &&
              planned.isPrimary &&
              planned.slotPattern.isLegDominant) {
            expect(
              planned.sets,
              lessThanOrEqualTo(DayRules.preRunLegSetCap),
              reason: 'moving a day left heavy legs before a run',
            );
          }
        }
      }
      movesExercised++;
    }

    expect(movesExercised, greaterThan(50), reason: 'too few moves tested');
  });
}
