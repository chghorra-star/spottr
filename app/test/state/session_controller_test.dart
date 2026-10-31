import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/state/session_controller.dart';

import '../support/profiles.dart';
import '../support/test_database.dart';

/// The controller is the seam where a logged session becomes next week's
/// plan, so these tests are mostly about that: what the user did, then what
/// the plan says afterwards.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late SessionController controller;

  Future<void> start([UserProfile? profile]) async {
    db = openTestDatabase();
    addTearDown(db.close);
    container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await container
        .read(profileControllerProvider)
        .save(profile ?? onboardedProfile());
    controller = container.read(sessionControllerProvider);
  }

  Future<WeekPlan> plan() async =>
      (await container.read(planRepositoryProvider).loadActive())!;

  Future<PlannedDay> firstDay() async => (await plan()).days.first;

  /// Logs every prescribed set of [exercise] at [reps], which is how a user
  /// who finished the session looks to progression.
  Future<void> logAll(
    PlannedExercise exercise, {
    required int reps,
    double? weightKg,
  }) async {
    for (var index = 0; index < exercise.sets; index++) {
      await controller.logSet(
        exerciseId: exercise.exerciseId,
        setIndex: index,
        reps: exercise.metric == MetricType.reps ? reps : null,
        holdSeconds: exercise.metric == MetricType.reps ? null : reps,
        weightKg: weightKg,
      );
    }
  }

  group('starting', () {
    test('opens a session against the planned day', () async {
      await start();
      final day = await firstDay();

      await controller.start(day.weekday);

      final active =
          await container.read(sessionRepositoryProvider).loadActive();
      expect(active, isNotNull);
      expect(active!.weekday, day.weekday);
    });

    test('a weekday with no session planned is refused', () async {
      await start();
      final taken = (await plan()).days.map((d) => d.weekday).toSet();
      final free = [1, 2, 3, 4, 5, 6, 7].firstWhere((d) => !taken.contains(d));

      await expectLater(controller.start(free), throwsStateError);
    });

    test('logging without an open session fails rather than inventing one',
        () async {
      await start();

      await expectLater(
        controller.logSet(exerciseId: 'push_up', setIndex: 0, reps: 10),
        throwsStateError,
      );
    });
  });

  group('logging', () {
    test('a set points at the prescription it was performed against',
        () async {
      await start();
      final day = await firstDay();
      await controller.start(day.weekday);
      final exercise = day.exercises.first;

      await controller.logSet(
        exerciseId: exercise.exerciseId,
        setIndex: 0,
        reps: 10,
        weightKg: 60,
      );

      final active =
          (await container.read(sessionRepositoryProvider).loadActive())!;
      final logged = active.sets.single;
      final ref = await container
          .read(planRepositoryProvider)
          .dayRef(weekday: day.weekday);
      expect(logged.planExerciseId, ref!.exerciseRowIds[exercise.exerciseId]);
    });

    test('a hold is logged as seconds', () async {
      await start();
      final plan_ = await plan();
      final day = plan_.days.firstWhere(
        (d) => d.exercises.any((e) => e.metric == MetricType.holdSeconds),
      );
      await controller.start(day.weekday);
      final held = day.exercises
          .firstWhere((e) => e.metric == MetricType.holdSeconds);

      await controller.logSet(
        exerciseId: held.exerciseId,
        setIndex: 0,
        holdSeconds: held.holdSeconds,
      );

      final active =
          (await container.read(sessionRepositoryProvider).loadActive())!;
      expect(active.sets.single.holdSeconds, held.holdSeconds);
      expect(active.sets.single.reps, isNull);
    });
  });

  group('finishing', () {
    test('a session the user completed raises the load next time', () async {
      await start();
      final day = await firstDay();
      final exercise = day.exercises.first;
      await controller.start(day.weekday);
      await logAll(exercise, reps: exercise.repsMax!, weightKg: 60);

      final decisions = await controller.finish(rating: SessionRating.right);

      final decision = decisions.firstWhere(
        (d) => d.exerciseId == exercise.exerciseId,
      );
      expect(decision.change, ProgressionChange.loadUp);

      final after = (await plan()).days.firstWhere(
            (d) => d.weekday == day.weekday,
          );
      final updated = after.exercises.firstWhere(
        (e) => e.exerciseId == exercise.exerciseId,
      );
      expect(updated.targetWeightKg, decision.nextWeightKg);
      expect(updated.targetWeightKg, greaterThan(60));
    });

    test('the next prescription is a new revision, not a rewrite', () async {
      await start();
      final day = await firstDay();
      await controller.start(day.weekday);
      await logAll(day.exercises.first,
          reps: day.exercises.first.repsMax!, weightKg: 60);

      await controller.finish(rating: SessionRating.right);

      expect(await db.select(db.plans).get(), hasLength(2));
      // The session log still points at the revision it was trained
      // against, which is the whole reason revisions are immutable.
      final logged = (await db.select(db.setLogs).get()).first;
      expect(logged.planExerciseId, startsWith('plan_'));
    });

    test('a session that earned nothing does not touch the plan', () async {
      await start();
      final day = await firstDay();
      final exercise = day.exercises.first;
      await controller.start(day.weekday);
      await logAll(exercise, reps: exercise.repsMin!, weightKg: 60);

      final decisions = await controller.finish(rating: SessionRating.right);

      expect(
        decisions.map((d) => d.change),
        everyElement(ProgressionChange.hold),
      );
      expect(await db.select(db.plans).get(), hasLength(1));
    });

    test('an exercise the user skipped is not commented on', () async {
      await start();
      final day = await firstDay();
      final trained = day.exercises.first;
      await controller.start(day.weekday);
      await logAll(trained, reps: trained.repsMax!, weightKg: 60);

      final decisions = await controller.finish();

      expect(decisions.map((d) => d.exerciseId), [trained.exerciseId]);
    });

    test('pain reported during the session blocks every increase', () async {
      await start();
      final day = await firstDay();
      final exercise = day.exercises.first;
      await controller.start(day.weekday);
      await logAll(exercise, reps: exercise.repsMax!, weightKg: 60);
      await controller.reportPain();

      final decisions = await controller.finish(rating: SessionRating.tooEasy);

      expect(
        decisions.map((d) => d.reason),
        everyElement(ProgressionReason.painReported),
      );
      // Nothing changed, so there is no new revision either.
      expect(await db.select(db.plans).get(), hasLength(1));
      final after = (await plan()).days.firstWhere(
            (d) => d.weekday == day.weekday,
          );
      expect(
        after.exercises.map((e) => e.targetWeightKg),
        everyElement(isNull),
      );
    });

    test('a missed session drops the load next time', () async {
      await start();
      final day = await firstDay();
      final exercise = day.exercises.first;
      await controller.start(day.weekday);
      await logAll(exercise, reps: exercise.repsMin! - 2, weightKg: 60);

      final decisions = await controller.finish(rating: SessionRating.tooHard);

      final decision = decisions.single;
      expect(decision.change, ProgressionChange.loadDown);

      final after = (await plan()).days.firstWhere(
            (d) => d.weekday == day.weekday,
          );
      expect(
        after.exercises
            .firstWhere((e) => e.exerciseId == exercise.exerciseId)
            .targetWeightKg,
        lessThan(60),
      );
    });

    test('progression never changes how long the session takes to do',
        () async {
      await start();
      final before = await firstDay();
      await controller.start(before.weekday);
      for (final exercise in before.exercises) {
        await logAll(
          exercise,
          reps: exercise.metric == MetricType.reps
              ? exercise.repsMax!
              : exercise.holdSeconds!,
          weightKg: 40,
        );
      }

      await controller.finish(rating: SessionRating.right);

      final after = (await plan()).days.firstWhere(
            (d) => d.weekday == before.weekday,
          );
      expect(after.exercises.map((e) => e.sets),
          before.exercises.map((e) => e.sets));
      expect(after.exercises.length, before.exercises.length);
    });

    test('finishing with nothing open fails rather than doing nothing',
        () async {
      await start();

      await expectLater(controller.finish(), throwsStateError);
    });

    test('a discarded session leaves no trace in the plan', () async {
      await start();
      final day = await firstDay();
      await controller.start(day.weekday);
      await logAll(day.exercises.first,
          reps: day.exercises.first.repsMax!, weightKg: 60);

      await controller.discard();

      expect(
        await container.read(sessionRepositoryProvider).loadActive(),
        isNull,
      );
      expect(await db.select(db.plans).get(), hasLength(1));
    });
  });
}
