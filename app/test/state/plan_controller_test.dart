import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/state/plan_controller.dart';

import '../support/profiles.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late PlanController controller;

  Future<void> start([UserProfile? profile]) async {
    db = openTestDatabase();
    addTearDown(db.close);
    container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await container
        .read(profileControllerProvider)
        .save(profile ?? onboardedProfile());
    controller = container.read(planControllerProvider);
  }

  Future<WeekPlan> plan() async =>
      (await container.read(planRepositoryProvider).loadActive())!;

  group('swap', () {
    test('offers only alternatives that fit and are not already there',
        () async {
      await start(onboardedProfile(location: TrainingLocation.homeDumbbells));
      final current = await plan();
      final day = current.days.first;
      final target = day.exercises.first.exerciseId;

      final alternatives = await controller.alternativesFor(
        weekday: day.weekday,
        exerciseId: target,
      );

      expect(alternatives, isNotEmpty);
      final idsToday = day.exercises.map((e) => e.exerciseId).toSet();
      for (final alternative in alternatives) {
        expect(idsToday, isNot(contains(alternative.id)));
        expect(
          alternative.isAvailableWith(const {Equipment.dumbbells}),
          isTrue,
          reason: alternative.id,
        );
      }
    });

    test('replaces the exercise and keeps the slot', () async {
      await start();
      final before = await plan();
      final day = before.days.first;
      final target = day.exercises.first;

      final alternative = (await controller.alternativesFor(
        weekday: day.weekday,
        exerciseId: target.exerciseId,
      ))
          .first;

      await controller.swap(
        weekday: day.weekday,
        exerciseId: target.exerciseId,
        replacementId: alternative.id,
      );

      final after = await plan();
      final swapped = after.days.first.exercises.first;
      expect(swapped.exerciseId, alternative.id);
      expect(swapped.slotPattern, target.slotPattern);
      expect(swapped.priority, target.priority);
      expect(swapped.templateSets, target.templateSets);
    });

    test('a swap survives as a new revision', () async {
      await start();
      final before = await plan();
      final day = before.days.first;
      final target = before.days.first.exercises.first.exerciseId;
      final alternative = (await controller.alternativesFor(
        weekday: day.weekday,
        exerciseId: target,
      ))
          .first;

      await controller.swap(
        weekday: day.weekday,
        exerciseId: target,
        replacementId: alternative.id,
      );

      expect(await db.select(db.plans).get(), hasLength(2));
      expect((await plan()).exerciseIds, isNot(contains(target)));
    });
  });

  group('reorder', () {
    test('moves the exercise and leaves the prescription alone', () async {
      await start();
      final before = await plan();
      final day = before.days.first;
      expect(day.exercises.length, greaterThan(2));

      await controller.reorder(
        weekday: day.weekday,
        fromIndex: 0,
        toIndex: 2,
      );

      final after = (await plan()).days.first;
      expect(after.exercises[2], day.exercises[0]);
      expect(after.exercises[0], day.exercises[1]);
      expect(after.exercises.length, day.exercises.length);
    });

    test('does not restore volume the time budget took away', () async {
      // A user who accepted a trimmed 30-minute session should not have it
      // grow back because they dragged a row.
      await start(onboardedProfile(sessionMinutes: 30));
      final before = await plan();
      final day = before.days.first;

      await controller.reorder(
        weekday: day.weekday,
        fromIndex: 0,
        toIndex: 1,
      );

      final after = (await plan()).days.first;
      expect(after.exercises.length, day.exercises.length);
      expect(
        after.exercises.map((e) => e.sets).toList()..sort(),
        day.exercises.map((e) => e.sets).toList()..sort(),
      );
    });
  });

  group('move day', () {
    test('moves the session to a free weekday', () async {
      await start();
      final before = await plan();
      final from = before.days.first.weekday;
      final taken = before.days.map((d) => d.weekday).toSet();
      final to = [1, 2, 3, 4, 5, 6, 7].firstWhere((d) => !taken.contains(d));

      await controller.moveDay(fromWeekday: from, toWeekday: to);

      final after = await plan();
      expect(after.days.map((d) => d.weekday), contains(to));
      expect(after.days.map((d) => d.weekday), isNot(contains(from)));
      expect(
        after.days.map((d) => d.weekday).toList(),
        after.days.map((d) => d.weekday).toList()..sort(),
        reason: 'days stay in weekday order',
      );
    });

    test('re-applies the pre-run leg cap after the move', () async {
      // Moving a leg day onto the night before a run has to cut its volume,
      // and moving it away has to give the volume back. Both directions.
      await start(
        onboardedProfile(
          goal: Goal.hybrid,
          daysPerWeek: 2,
          runWeekdays: {7},
        ),
      );
      final before = await plan();
      final legWork = before.days
          .expand((d) => d.exercises)
          .firstWhere((e) => e.isPrimary && e.slotPattern.isLegDominant);
      expect(legWork.sets, legWork.templateSets, reason: 'premise: uncapped');

      final from = before.days.first.weekday;
      await controller.moveDay(fromWeekday: from, toWeekday: 6);

      final moved = (await plan()).days.firstWhere((d) => d.weekday == 6);
      expect(moved.precedesRunDay, isTrue);
      for (final exercise in moved.exercises) {
        if (exercise.isPrimary && exercise.slotPattern.isLegDominant) {
          expect(exercise.sets, lessThanOrEqualTo(DayRules.preRunLegSetCap));
        }
      }

      await controller.moveDay(fromWeekday: 6, toWeekday: from);
      final returned =
          (await plan()).days.firstWhere((d) => d.weekday == from);
      expect(returned.precedesRunDay, isFalse);
      for (final exercise in returned.exercises) {
        expect(exercise.sets, exercise.templateSets);
      }
    });

    test('refuses a weekday that already has a session', () async {
      await start();
      final days = (await plan()).days.map((d) => d.weekday).toList();

      await expectLater(
        controller.moveDay(fromWeekday: days.first, toWeekday: days.last),
        throwsArgumentError,
      );
      expect(await db.select(db.plans).get(), hasLength(1));
    });
  });

  group('regenerate', () {
    test('returns the week to what the profile would generate', () async {
      await start();
      final profile = onboardedProfile();
      final day = (await plan()).days.first;
      final target = day.exercises.first.exerciseId;
      final alternative = (await controller.alternativesFor(
        weekday: day.weekday,
        exerciseId: target,
      ))
          .first;
      await controller.swap(
        weekday: day.weekday,
        exerciseId: target,
        replacementId: alternative.id,
      );

      await controller.regenerate();

      expect(
        await plan(),
        PlanGenerator(standardCatalog).generate(profile.toPlanRequest()),
      );
    });

    test('fails clearly when there is no profile to generate from', () async {
      db = openTestDatabase();
      addTearDown(db.close);
      container = ProviderContainer.test(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      await expectLater(
        container.read(planControllerProvider).regenerate(),
        throwsStateError,
      );
    });
  });

  test('an edit with no stored plan fails rather than inventing one',
      () async {
    db = openTestDatabase();
    addTearDown(db.close);
    container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await container.read(profileRepositoryProvider).save(onboardedProfile());

    await expectLater(
      container.read(planControllerProvider).reorder(
            weekday: 1,
            fromIndex: 0,
            toIndex: 1,
          ),
      throwsStateError,
    );
  });
}
