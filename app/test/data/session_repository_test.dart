import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/plan_repository.dart';
import 'package:spottr/data/profile_repository.dart';
import 'package:spottr/data/session_repository.dart';

import '../support/profiles.dart';
import '../support/test_database.dart';

/// Against a real in-memory database, because what these tests are about is
/// storage: that a set comes back the way it went in, that a session cannot
/// be opened twice, and that a pain report cannot be lost.
void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late PlanRepository plans;

  setUp(() async {
    db = openTestDatabase();
    addTearDown(db.close);
    plans = PlanRepository(db);
    // A clock that always moves. Sessions and sets are ordered by when they
    // happened, and the real clock does not reliably advance between two
    // inserts — which would make "newest first" mean nothing in a test.
    var tick = DateTime.utc(2026, 10, 31, 9);
    sessions = SessionRepository(
      db,
      now: () {
        tick = tick.add(const Duration(minutes: 1));
        return tick;
      },
    );
    await ProfileRepository(db).save(onboardedProfile());
  });

  /// A stored plan, so that a session has a real day to attach itself to.
  Future<PlanDayRef> storedDay() async {
    final profile = onboardedProfile();
    final plan =
        PlanGenerator(standardCatalog).generate(profile.toPlanRequest());
    await plans.saveRevision(plan, profileId: profile.id);
    final ref = await plans.dayRef(weekday: plan.days.first.weekday);
    return ref!;
  }

  group('starting and finishing', () {
    test('a started session is the active one', () async {
      final day = await storedDay();
      final id = await sessions.start(day: day);

      final active = await sessions.loadActive();
      expect(active, isNotNull);
      expect(active!.id, id);
      expect(active.isActive, isTrue);
      expect(active.planDayId, day.dayId);
      expect(active.weekday, day.weekday);
      expect(active.sets, isEmpty);
    });

    test('a second session is refused while one is open', () async {
      await sessions.start(day: await storedDay());

      await expectLater(sessions.start(), throwsStateError);
      expect(await db.select(db.sessions).get(), hasLength(1));
    });

    test('finishing closes it and records the rating', () async {
      final id = await sessions.start(day: await storedDay());
      await sessions.finish(sessionId: id, rating: SessionRating.right);

      expect(await sessions.loadActive(), isNull);
      final finished = await sessions.load(id);
      expect(finished!.isActive, isFalse);
      expect(finished.endedAt, isNotNull);
      expect(finished.rating, SessionRating.right);
    });

    test('a skipped rating stays unanswered rather than becoming "fine"',
        () async {
      final id = await sessions.start();
      await sessions.finish(sessionId: id);

      expect((await sessions.load(id))!.rating, isNull);
    });

    test('once one is finished another can start', () async {
      final first = await sessions.start();
      await sessions.finish(sessionId: first);

      final second = await sessions.start();
      expect(second, isNot(first));
      expect((await sessions.loadActive())!.id, second);
    });

    test('an unknown session is null, not an error', () async {
      expect(await sessions.load('log_nothing'), isNull);
    });

    test('the stream reports a set the moment it is logged', () async {
      // Logging a set changes no column on the session row. A stream that
      // only watched that row would leave the set off the screen until
      // something else happened to rebuild it.
      final counts = <int>[];
      final subscription = sessions
          .watchActive()
          .listen((session) => counts.add(session?.sets.length ?? -1));
      await pumpEventQueue();

      final id = await sessions.start();
      await pumpEventQueue();
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'push_up',
        setIndex: 0,
        reps: 10,
      );
      await pumpEventQueue();

      expect(counts.last, 1);
      await subscription.cancel();
    });

    test('the stream reports a pain report', () async {
      final flags = <bool>[];
      final subscription = sessions
          .watchActive()
          .listen((session) => flags.add(session?.painReported ?? false));
      await pumpEventQueue();

      final id = await sessions.start();
      await pumpEventQueue();
      await sessions.reportPain(id);
      await pumpEventQueue();

      expect(flags.last, isTrue);
      await subscription.cancel();
    });

    test('the active session stream follows the session', () async {
      final emissions = <String?>[];
      final subscription = sessions
          .watchActive()
          .listen((session) => emissions.add(session?.id));
      await pumpEventQueue();

      final id = await sessions.start();
      await pumpEventQueue();
      await sessions.finish(sessionId: id);
      await pumpEventQueue();

      expect(emissions.first, isNull);
      expect(emissions, contains(id));
      expect(emissions.last, isNull);
      await subscription.cancel();
    });
  });

  group('logging sets', () {
    test('a set comes back exactly as it went in', () async {
      final day = await storedDay();
      final id = await sessions.start(day: day);
      final exerciseId = day.exerciseRowIds.keys.first;

      await sessions.logSet(
        sessionId: id,
        exerciseId: exerciseId,
        planExerciseId: day.exerciseRowIds[exerciseId],
        setIndex: 0,
        reps: 9,
        weightKg: 62.5,
      );

      final logged = (await sessions.loadActive())!.sets.single;
      expect(logged.exerciseId, exerciseId);
      expect(logged.planExerciseId, day.exerciseRowIds[exerciseId]);
      expect(logged.setIndex, 0);
      expect(logged.reps, 9);
      expect(logged.weightKg, 62.5);
      expect(logged.holdSeconds, isNull);
      expect(logged.formScore, isNull);
    });

    test('a hold is stored as seconds, never as reps', () async {
      final id = await sessions.start();
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'plank',
        setIndex: 0,
        holdSeconds: 45,
      );

      final logged = (await sessions.loadActive())!.sets.single;
      expect(logged.holdSeconds, 45);
      expect(logged.reps, isNull);
      expect(logged.toCompleted().achieved, 45);
    });

    test('a set that is neither reps nor a hold is refused', () async {
      final id = await sessions.start();
      await expectLater(
        sessions.logSet(sessionId: id, exerciseId: 'plank', setIndex: 0),
        throwsArgumentError,
      );
    });

    test('sets keep the order they were performed in', () async {
      final id = await sessions.start();
      for (var index = 0; index < 3; index++) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'push_up',
          setIndex: index,
          reps: 12 - index,
        );
      }

      final session = (await sessions.loadActive())!;
      expect(session.sets.map((s) => s.setIndex), [0, 1, 2]);
      expect(session.sets.map((s) => s.reps), [12, 11, 10]);
      expect(session.completedCountFor('push_up'), 3);
    });

    test('three sets saved in a loop get three distinct ids', () async {
      // A timestamp alone is not an id: on Windows the clock does not move
      // between two inserts in the same tick.
      final id = await sessions.start();
      for (var index = 0; index < 3; index++) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'push_up',
          setIndex: index,
          reps: 10,
        );
      }

      final ids = (await sessions.loadActive())!.sets.map((s) => s.id).toSet();
      expect(ids, hasLength(3));
    });

    test('work off the plan is allowed and points at nothing', () async {
      final id = await sessions.start();
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'db_curl',
        setIndex: 0,
        reps: 12,
        weightKg: 14,
      );

      expect((await sessions.loadActive())!.sets.single.planExerciseId, isNull);
    });

    test('the top weight of an exercise is the heaviest set', () async {
      final id = await sessions.start();
      for (final weight in [60.0, 70.0, 65.0]) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_back_squat',
          setIndex: 0,
          reps: 8,
          weightKg: weight,
        );
      }

      expect(
        (await sessions.loadActive())!.topWeightFor('barbell_back_squat'),
        70.0,
      );
    });
  });

  group('pain', () {
    test('a pain report sticks, and finishing does not clear it', () async {
      final id = await sessions.start();
      await sessions.reportPain(id);

      expect((await sessions.loadActive())!.painReported, isTrue);

      await sessions.finish(sessionId: id, rating: SessionRating.tooHard);
      expect((await sessions.load(id))!.painReported, isTrue);
    });

    test('reporting pain twice is not an error', () async {
      final id = await sessions.start();
      await sessions.reportPain(id);
      await sessions.reportPain(id);

      expect((await sessions.load(id))!.painReported, isTrue);
    });

    test('a session with no pain says so', () async {
      final id = await sessions.start();
      expect((await sessions.load(id))!.painReported, isFalse);
    });
  });

  group('discarding', () {
    test('a discarded session is gone from the app and tombstoned in the db',
        () async {
      final id = await sessions.start();
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'push_up',
        setIndex: 0,
        reps: 10,
      );

      await sessions.discard(id);

      expect(await sessions.loadActive(), isNull);
      expect(await sessions.load(id), isNull);
      // Soft, so a peer eventually learns the row went away.
      final row = (await db.select(db.sessions).get()).single;
      expect(row.deletedAt, isNotNull);
      expect(
        (await db.select(db.setLogs).get()).single.deletedAt,
        isNotNull,
      );
    });

    test('a discarded session frees the slot for a new one', () async {
      final first = await sessions.start();
      await sessions.discard(first);

      expect(await sessions.start(), isNot(first));
    });
  });

  group('history', () {
    Future<String> finishedSessionWith({
      required String exerciseId,
      double? formScore,
      int reps = 10,
    }) async {
      final id = await sessions.start();
      await sessions.logSet(
        sessionId: id,
        exerciseId: exerciseId,
        setIndex: 0,
        reps: reps,
        formScore: formScore,
      );
      await sessions.finish(sessionId: id, rating: SessionRating.right);
      return id;
    }

    test('recent sessions are newest first and finished only', () async {
      final first = await finishedSessionWith(exerciseId: 'push_up');
      final second = await finishedSessionWith(exerciseId: 'push_up');
      final open = await sessions.start();
      await sessions.logSet(
        sessionId: open,
        exerciseId: 'push_up',
        setIndex: 0,
        reps: 10,
      );

      final history = await sessions.recentFor(exerciseId: 'push_up');
      expect(history.map((s) => s.id), [second, first]);
    });

    test('only sessions that included the exercise count', () async {
      await finishedSessionWith(exerciseId: 'push_up');
      await finishedSessionWith(exerciseId: 'plank');

      expect(await sessions.recentFor(exerciseId: 'plank'), hasLength(1));
    });

    test('no form data is not a low-form streak', () async {
      // The whole of M3 logs by hand, so every score is null. A streak
      // counter that read that as bad form would deload the entire app.
      await finishedSessionWith(exerciseId: 'push_up');
      await finishedSessionWith(exerciseId: 'push_up');

      expect(await sessions.lowFormStreakFor(exerciseId: 'push_up'), 0);
    });

    test('consecutive bad sessions build a streak', () async {
      await finishedSessionWith(exerciseId: 'push_up', formScore: 55);
      await finishedSessionWith(exerciseId: 'push_up', formScore: 61);

      expect(await sessions.lowFormStreakFor(exerciseId: 'push_up'), 2);
    });

    test('one good session breaks the streak', () async {
      await finishedSessionWith(exerciseId: 'push_up', formScore: 55);
      await finishedSessionWith(exerciseId: 'push_up', formScore: 90);
      await finishedSessionWith(exerciseId: 'push_up', formScore: 60);

      expect(await sessions.lowFormStreakFor(exerciseId: 'push_up'), 1);
    });

    test('the session being decided is left out of its own history', () async {
      await finishedSessionWith(exerciseId: 'push_up', formScore: 55);
      final current =
          await finishedSessionWith(exerciseId: 'push_up', formScore: 50);

      expect(
        await sessions.lowFormStreakFor(
          exerciseId: 'push_up',
          excluding: current,
        ),
        1,
      );
    });
  });
}
