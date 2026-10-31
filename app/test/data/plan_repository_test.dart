import 'package:drift/drift.dart' as drift;
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/plan_repository.dart';
import 'package:spottr/data/profile_repository.dart';
import 'package:spottr/domain/user_profile.dart';

import '../support/profiles.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late PlanRepository repository;
  var revision = 0;

  final generator = PlanGenerator(standardCatalog);

  setUp(() async {
    revision = 0;
    db = openTestDatabase();
    // Plans reference a profile row, so every test needs one saved first.
    await ProfileRepository(db).save(onboardedProfile());
    repository = PlanRepository(
      db,
      newRevisionId: () => 'rev${++revision}',
    );
  });

  tearDown(() => db.close());

  WeekPlan generate(UserProfile profile) =>
      generator.generate(profile.toPlanRequest());

  test('an empty database has no active plan', () async {
    expect(await repository.loadActive(), isNull);
  });

  test('round trips a generated plan exactly', () async {
    final plan = generate(onboardedProfile());

    await repository.saveRevision(plan);

    expect(await repository.loadActive(), plan);
  });

  test('round trips the notes, run days and running suggestions', () async {
    // A hybrid week on a short session budget is the case that produces all
    // three: run days to schedule around, trimming notes, and text run
    // suggestions. A roomy 60-minute week has nothing to explain.
    final profile = onboardedProfile(
      goal: Goal.hybrid,
      daysPerWeek: 5,
      sessionMinutes: 30,
      runWeekdays: {3, 6},
    );
    final plan = generate(profile);

    expect(plan.notes, isNotEmpty, reason: 'premise: this plan has notes');
    expect(plan.runSuggestionKeys, isNotEmpty);

    await repository.saveRevision(plan);
    final loaded = await repository.loadActive();

    expect(loaded, plan);
    expect(loaded!.notes, plan.notes);
    expect(loaded.runWeekdays, {3, 6});
  });

  test('round trips a hold prescription as seconds, not reps', () async {
    final plan = generate(onboardedProfile());
    final holds = plan.allExercises
        .where((e) => e.metric == MetricType.holdSeconds)
        .toList();
    expect(holds, isNotEmpty, reason: 'premise: this plan has a hold');

    await repository.saveRevision(plan);
    final loaded = await repository.loadActive();

    final loadedHolds = loaded!.allExercises
        .where((e) => e.metric == MetricType.holdSeconds)
        .toList();
    expect(loadedHolds, holds);
    expect(loadedHolds.first.repsMin, isNull);
    expect(loadedHolds.first.holdSeconds, isNotNull);
  });

  test('round trips a plan whose split was simplified', () async {
    // Bodyweight at home on six days: the generator abandons the split, and
    // the note explaining why has to survive persistence or the plan screen
    // looks broken for no reason.
    final plan = generate(
      onboardedProfile(
        daysPerWeek: 6,
        location: TrainingLocation.homeNone,
        level: Level.beginner,
      ),
    );
    expect(
      plan.notes.map((n) => n.kind),
      contains(PlanNoteKind.templateSimplified),
      reason: 'premise: this plan was simplified',
    );

    await repository.saveRevision(plan);

    expect(await repository.loadActive(), plan);
  });

  group('revisions', () {
    test('a second save deactivates the first and wins', () async {
      final first = generate(onboardedProfile());
      final second = generate(onboardedProfile(daysPerWeek: 3));

      await repository.saveRevision(first);
      await repository.saveRevision(second);

      expect(await repository.loadActive(), second);

      final rows = await db.select(db.plans).get();
      expect(rows, hasLength(2), reason: 'the old revision is kept');
      expect(rows.where((r) => r.isActive), hasLength(1));
    });

    test('an edit is a new revision, leaving the old rows untouched',
        () async {
      // Session logs point at a plan exercise row. Rewriting a plan the user
      // has trained would rewrite its own history, so edits append.
      final edits = PlanEdits(standardCatalog);
      final profile = onboardedProfile();
      final plan = generate(profile);
      await repository.saveRevision(plan);

      final before = await db.select(db.planExercises).get();

      final day = plan.days.first;
      final target = day.exercises.first.exerciseId;
      final alternative = edits
          .alternativesFor(
            plan: plan,
            weekday: day.weekday,
            exerciseId: target,
            request: profile.toPlanRequest(),
          )
          .first;
      final edited = edits.swapExercise(
        plan: plan,
        weekday: day.weekday,
        exerciseId: target,
        replacementId: alternative.id,
        request: profile.toPlanRequest(),
      );

      await repository.saveRevision(edited);

      expect(await repository.loadActive(), edited);
      final after = await db.select(db.planExercises).get();
      expect(
        after.where((row) => before.any((old) => old.id == row.id)).map(
              (row) => row.exerciseId,
            ),
        before.map((row) => row.exerciseId),
        reason: 'the previous revision rows are unchanged',
      );
    });

    test('exercise rows keep the order the plan prescribes', () async {
      final plan = generate(onboardedProfile());
      await repository.saveRevision(plan);

      final day = plan.days.first;
      final dayRow = (await db.select(db.planDays).get())
          .firstWhere((row) => row.weekday == day.weekday);
      final rows = await (db.select(db.planExercises)
            ..where((t) => t.planDayId.equals(dayRow.id))
            ..orderBy([(t) => drift.OrderingTerm.asc(t.orderIndex)]))
          .get();

      expect(
        rows.map((r) => r.exerciseId),
        day.exercises.map((e) => e.exerciseId),
      );
    });
  });

  test('watchActive emits nothing, then each revision', () async {
    final seen = <WeekPlan?>[];
    final subscription = repository.watchActive().listen(seen.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    final plan = generate(onboardedProfile());
    await repository.saveRevision(plan);
    await pumpEventQueue();

    expect(seen.first, isNull);
    expect(seen.last, plan);
  });

  test('a save stamps every row for sync', () async {
    final repository = PlanRepository(
      db,
      deviceId: 'test-device',
      newRevisionId: () => 'rev1',
    );
    await repository.saveRevision(generate(onboardedProfile()));

    expect(
      (await db.select(db.plans).get()).map((r) => r.deviceId),
      everyElement('test-device'),
    );
    expect(
      (await db.select(db.planDays).get()).map((r) => r.deviceId),
      everyElement('test-device'),
    );
    expect(
      (await db.select(db.planExercises).get()).map((r) => r.deviceId),
      everyElement('test-device'),
    );
  });
}
