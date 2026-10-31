import 'package:coach_engine/coach_engine.dart';
import 'package:drift/drift.dart' show Value;
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/profile_repository.dart';
import 'package:spottr/domain/user_profile.dart';

import '../support/profiles.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository repository;

  setUp(() {
    db = openTestDatabase();
    repository = ProfileRepository(db);
  });

  tearDown(() => db.close());

  test('an empty database has no profile', () async {
    expect(await repository.load(), isNull);
  });

  test('round trips every field', () async {
    final profile = testProfile(
      goal: Goal.hybrid,
      daysPerWeek: 5,
      sessionMinutes: 75,
      level: Level.advanced,
      location: TrainingLocation.homeDumbbells,
      coachStyle: CoachStyle.tough,
      ageYears: 41,
      heightCm: 174.5,
      weightKg: 68.2,
      sex: Sex.female,
      injuries: {BodyPart.knees, BodyPart.lowerBack},
      injuryNotes: 'left knee aches on deep squats',
      extraEquipment: {Equipment.pullUpBar, Equipment.bench},
      runWeekdays: {2, 5},
      disclaimerAcceptedAt: DateTime.utc(2026, 10, 31, 8, 30),
    );

    await repository.save(profile);

    expect(await repository.load(), profile);
  });

  test('round trips a profile that gave no measurements', () async {
    final profile = testProfile(
      ageYears: null,
      heightCm: null,
      weightKg: null,
      sex: null,
      injuryNotes: null,
    );

    await repository.save(profile);

    expect(await repository.load(), profile);
  });

  test('saving again updates in place rather than adding a row', () async {
    await repository.save(testProfile());
    await repository.save(testProfile(daysPerWeek: 3));

    final rows = await db.select(db.profiles).get();
    expect(rows, hasLength(1));
    expect((await repository.load())!.daysPerWeek, 3);
  });

  test('a save stamps the row for sync', () async {
    final repository = ProfileRepository(db, deviceId: 'test-device');
    await repository.save(testProfile());

    final row = (await db.select(db.profiles).get()).single;
    expect(row.deviceId, 'test-device');
    expect(row.deletedAt, isNull);
  });

  test('watch emits the current profile and then every save', () async {
    final seen = <UserProfile?>[];
    final subscription = repository.watch().listen(seen.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    await repository.save(testProfile(daysPerWeek: 2));
    await pumpEventQueue();

    expect(seen.first, isNull);
    expect(seen.last!.daysPerWeek, 2);
  });

  test('a soft-deleted profile reads as absent', () async {
    await repository.save(testProfile());
    await db.update(db.profiles).write(
          ProfilesCompanion(deletedAt: Value(DateTime.utc(2026, 11))),
        );

    expect(await repository.load(), isNull);
  });

  group('decoding a row written by another version', () {
    Future<void> insertRaw({
      String injuries = '[]',
      String equipment = '[]',
      String goal = 'muscleBuilding',
      String coachPersonality = 'calm',
    }) =>
        db.into(db.profiles).insert(
              ProfilesCompanion.insert(
                id: UserProfile.localId,
                goal: goal,
                daysPerWeek: 4,
                sessionMinutes: 60,
                level: 'intermediate',
                location: 'fullGym',
                coachPersonality: coachPersonality,
                deviceId: 'test',
                injuries: Value(injuries),
                equipment: Value(equipment),
              ),
            );

    test('an unknown injury is an error, never a silent loss', () async {
      // Dropping an injury we do not recognise would hand the user exercises
      // that were excluded for a reason. Failing loudly is the safe failure.
      await insertRaw(injuries: '["knees","coccyx"]');

      await expectLater(repository.load(), throwsA(isA<FormatException>()));
    });

    test('unknown equipment is dropped', () async {
      // The cost of ignoring a machine we do not know about is one fewer
      // exercise option, which is recoverable; refusing to load is not.
      await insertRaw(equipment: '["pullUpBar","sled"]');

      expect((await repository.load())!.extraEquipment, {Equipment.pullUpBar});
    });

    test('an unknown goal is an error', () async {
      await insertRaw(goal: 'powerlifting');

      await expectLater(repository.load(), throwsA(isA<FormatException>()));
    });

    test('an unknown coach style is an error', () async {
      await insertRaw(coachPersonality: 'sarcastic');

      await expectLater(repository.load(), throwsA(isA<FormatException>()));
    });
  });
}
