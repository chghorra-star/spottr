import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/database.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('opens at schema version 3', () {
    expect(db.schemaVersion, 3);
  });

  test('round-trips a profile', () async {
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: 'p1',
            goal: 'muscleBuilding',
            daysPerWeek: 4,
            sessionMinutes: 60,
            level: 'beginner',
            location: 'fullGym',
            coachPersonality: 'calm',
            deviceId: 'test-device',
          ),
        );

    final stored = await db.select(db.profiles).getSingle();
    expect(stored.id, 'p1');
    expect(stored.daysPerWeek, 4);
    expect(stored.coachPersonality, 'calm');
    // Defaults that the onboarding flow relies on.
    expect(stored.injuries, '[]');
    expect(stored.disclaimerAcceptedAt, isNull);
    expect(stored.deletedAt, isNull);
  });

  test('a timestamp is stored as text, not as a unix integer', () async {
    // Asked of SQLite rather than of drift, because drift would answer from
    // the same option that decided it. The zone and the sub-second part are
    // what two devices reconcile by, and the integer format keeps neither.
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: 'p1',
            goal: 'hybrid',
            daysPerWeek: 3,
            sessionMinutes: 45,
            level: 'beginner',
            location: 'homeNone',
            coachPersonality: 'calm',
            deviceId: 'test-device',
          ),
        );

    final row = await db
        .customSelect('SELECT typeof(updated_at) AS kind FROM profiles')
        .getSingle();
    expect(row.read<String>('kind'), 'text');
  });

  group('sync contract', () {
    /// Adding these columns later would mean a migration touching every
    /// table, so v1 carries them and this test keeps them there.
    const required = {'updated_at', 'deleted_at', 'device_id'};

    test('every syncable table carries the sync columns', () {
      for (final name in AppDatabase.syncableTableNames) {
        final table = db.allTables.firstWhere((t) => t.actualTableName == name);
        final columns = table.$columns.map((c) => c.name).toSet();
        expect(
          columns,
          containsAll(required),
          reason: '$name is syncable but is missing sync columns',
        );
      }
    });

    test('high-volume diagnostic tables are deliberately local-only', () {
      // Rep traces and rule verdicts exist for debugging and for generating
      // harness fixtures. Syncing them would push thousands of rows per
      // session for no user-visible benefit.
      for (final name in AppDatabase.localOnlyTableNames) {
        final table = db.allTables.firstWhere((t) => t.actualTableName == name);
        final columns = table.$columns.map((c) => c.name).toSet();
        expect(
          columns.intersection(required),
          isEmpty,
          reason: '$name is local-only but declares sync columns',
        );
      }
    });

    test('every table is classified, one way or another', () {
      final classified = {
        ...AppDatabase.syncableTableNames,
        ...AppDatabase.localOnlyTableNames,
        ...AppDatabase.deviceStateTableNames,
      };
      final actual = db.allTables.map((t) => t.actualTableName).toSet();
      expect(
        actual.difference(classified),
        isEmpty,
        reason: 'new table added without deciding whether it syncs',
      );
      expect(
        classified.difference(actual),
        isEmpty,
        reason: 'a table is classified that no longer exists',
      );
    });

    test('every syncable table can say whether it has been pushed', () {
      // pushed_at is the one sync column that is *not* replicated: it is
      // this install's record of what the server has acknowledged. Without
      // it the dirty set has to be guessed by comparing updated_at against
      // a watermark, which loses an edit made by a device whose clock is
      // behind — the failure mode being offline makes most likely.
      for (final name in AppDatabase.syncableTableNames) {
        final table = db.allTables.firstWhere((t) => t.actualTableName == name);
        expect(
          table.$columns.map((c) => c.name),
          contains('pushed_at'),
          reason: '$name is syncable but cannot say whether it is pending',
        );
      }
    });

    test('a diagnostic table is not asked to track pushes either', () {
      for (final name in AppDatabase.localOnlyTableNames) {
        final table = db.allTables.firstWhere((t) => t.actualTableName == name);
        expect(table.$columns.map((c) => c.name), isNot(contains('pushed_at')));
      }
    });

    test('a newly written row is pending, because nothing has seen it', () async {
      // The default has to be null rather than "now". A row stamped as
      // already pushed is a row the first sync skips, and nobody ever finds
      // out: it is simply missing from the other device.
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(
              id: 'p1',
              goal: 'hybrid',
              daysPerWeek: 3,
              sessionMinutes: 45,
              level: 'beginner',
              location: 'homeNone',
              coachPersonality: 'calm',
              deviceId: 'test-device',
            ),
          );

      final stored = await db.select(db.profiles).getSingle();
      expect(stored.pushedAt, isNull);
    });

    test('deletes are soft, so a peer can learn about them', () async {
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(
              id: 'p1',
              goal: 'hybrid',
              daysPerWeek: 3,
              sessionMinutes: 45,
              level: 'intermediate',
              location: 'homeDumbbells',
              coachPersonality: 'hype',
              deviceId: 'test-device',
            ),
          );

      await (db.update(db.profiles)..where((t) => t.id.equals('p1'))).write(
        ProfilesCompanion(deletedAt: Value(DateTime.utc(2026, 1, 1))),
      );

      final stored = await db.select(db.profiles).getSingle();
      expect(stored.deletedAt, isNotNull);
    });
  });
}
