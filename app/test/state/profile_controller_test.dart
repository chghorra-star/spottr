import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/state/profile_controller.dart';

import '../support/profiles.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late ProfileController controller;

  setUp(() {
    db = openTestDatabase();
    addTearDown(db.close);
    container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    controller = container.read(profileControllerProvider);
  });

  Future<WeekPlan?> storedPlan() =>
      container.read(planRepositoryProvider).loadActive();

  test('saving the first profile builds a plan to go with it', () async {
    final profile = onboardedProfile();

    await controller.save(profile);

    expect(await container.read(profileRepositoryProvider).load(), profile);
    expect(
      await storedPlan(),
      PlanGenerator(standardCatalog).generate(profile.toPlanRequest()),
    );
  });

  test('changing a training answer rebuilds the week', () async {
    await controller.save(onboardedProfile(daysPerWeek: 4));
    final before = await storedPlan();

    await controller.save(onboardedProfile(daysPerWeek: 2));
    final after = await storedPlan();

    expect(before!.days, hasLength(4));
    expect(after!.days, hasLength(2));
  });

  test('changing injuries rebuilds the week', () async {
    // The whole reason for collecting injuries is that they change what is
    // prescribed, so this one must never be treated as cosmetic.
    await controller.save(onboardedProfile());
    await controller.save(onboardedProfile(injuries: {BodyPart.knees}));

    final plan = await storedPlan();
    for (final exercise in plan!.allExercises) {
      expect(
        standardCatalog.require(exercise.exerciseId).isSafeFor(
          const {BodyPart.knees},
        ),
        isTrue,
        reason: exercise.exerciseId,
      );
    }
  });

  test('changing only the coach voice keeps the week the user has', () async {
    // A cosmetic change must not silently discard swaps and reordering. The
    // coach style affects nothing about what is prescribed.
    await controller.save(onboardedProfile());
    final planId = (await db.select(db.plans).get()).single.id;

    await controller.save(onboardedProfile(coachStyle: CoachStyle.tough));

    final rows = await db.select(db.plans).get();
    expect(rows, hasLength(1), reason: 'no new revision was written');
    expect(rows.single.id, planId);
    expect(
      (await container.read(profileRepositoryProvider).load())!.coachStyle,
      CoachStyle.tough,
    );
  });

  test('changing only the optional measurements keeps the week', () async {
    await controller.save(onboardedProfile());

    await controller.save(
      onboardedProfile().copyWith(weightKg: 79, injuryNotes: 'stiff ankle'),
    );

    expect(await db.select(db.plans).get(), hasLength(1));
  });

  test('a profile with no plan gets one even without a change', () async {
    // Covers the recovery case: the profile saved but the plan write failed,
    // or a future migration dropped plans. Saving again must heal it.
    final profile = onboardedProfile();
    await container.read(profileRepositoryProvider).save(profile);
    expect(await storedPlan(), isNull);

    await controller.save(profile);

    expect(await storedPlan(), isNotNull);
  });

  test('an invalid profile is rejected and stores nothing', () async {
    await expectLater(
      controller.save(onboardedProfile(daysPerWeek: 9)),
      throwsArgumentError,
    );

    expect(await container.read(profileRepositoryProvider).load(), isNull);
    expect(await storedPlan(), isNull);
  });

  test('accepting the disclaimer is what the gate reads', () async {
    final notAccepted = testProfile();
    expect(notAccepted.hasAcceptedDisclaimer, isFalse);

    await controller.save(notAccepted.copyWith(
      disclaimerAcceptedAt: DateTime.utc(2026, 10, 31),
    ));

    final stored = await container.read(profileRepositoryProvider).load();
    expect(stored!.hasAcceptedDisclaimer, isTrue);
  });
}
