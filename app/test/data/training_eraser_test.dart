import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/local/local_identity_store.dart';
import 'package:spottr/data/local/training_eraser.dart';
import 'package:spottr/data/sync/drift_sync_store.dart';
import 'package:spottr/data/sync/session_store.dart';
import 'package:spottr/data/sync/supabase_auth.dart';

import '../support/test_database.dart';

/// Handing the phone on.
///
/// Until this existed, a device that had held one account's training held it
/// for good: a second account signing in was refused — correctly, because
/// there is no way to tell afterwards whose rows were whose — and there was
/// nothing the person holding the phone could do about it from inside the
/// app. This is the way out, and the only one, so what it leaves behind is
/// worth being exact about.
///
/// Two of these tests are the whole point. A soft delete would be a
/// catastrophe: every row Spottr deletes is a tombstone that replicates, so
/// an erase that went through the ordinary delete path would sync somebody's
/// entire training history into the bin on their *other* devices, which is
/// the opposite of what the button says. And a cursor left behind would make
/// the next account's first sync skip everything the server had already
/// stamped.
void main() {
  late AppDatabase db;
  late InMemorySessionStore sessions;
  late LocalIdentityStore identity;
  late TrainingEraser eraser;

  setUp(() {
    db = openTestDatabase();
    sessions = InMemorySessionStore();
    identity = LocalIdentityStore(db);
    eraser = TrainingEraser(
      database: db,
      identity: identity,
      sessions: sessions,
    );
  });

  tearDown(() => db.close());

  /// One row in every table that holds anything about a person, with the
  /// foreign keys between them satisfied, plus a cursor per syncable table.
  Future<void> seedADeviceInUse() async {
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: 'p1',
            goal: 'hybrid',
            daysPerWeek: 3,
            sessionMinutes: 45,
            level: 'beginner',
            location: 'fullGym',
            coachPersonality: 'calm',
            deviceId: 'this-phone',
          ),
        );
    await db.into(db.plans).insert(
          PlansCompanion.insert(
            id: 'pl1',
            profileId: 'p1',
            templateId: 'full_body_3',
            goal: 'hybrid',
            createdAt: DateTime.utc(2026, 11, 1, 8),
            deviceId: 'this-phone',
          ),
        );
    await db.into(db.planDays).insert(
          PlanDaysCompanion.insert(
            id: 'd1',
            planId: 'pl1',
            weekday: 1,
            dayType: 'fullBody',
            labelKey: 'day_full_body',
            deviceId: 'this-phone',
          ),
        );
    await db.into(db.planExercises).insert(
          PlanExercisesCompanion.insert(
            id: 'px1',
            planDayId: 'd1',
            orderIndex: 0,
            exerciseId: 'barbell_back_squat',
            slotPattern: 'squat',
            priority: 'primary',
            targetSets: 3,
            templateSets: 3,
            metric: 'reps',
            restSeconds: 120,
            secondsPerRep: 3,
            deviceId: 'this-phone',
          ),
        );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: 's1',
            startedAt: DateTime.utc(2026, 11, 2, 18),
            planDayId: const Value('d1'),
            deviceId: 'this-phone',
          ),
        );
    await db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            id: 'sl1',
            sessionId: 's1',
            exerciseId: 'barbell_back_squat',
            setIndex: 0,
            reps: 8,
            completedAt: DateTime.utc(2026, 11, 2, 18, 10),
            planExerciseId: const Value('px1'),
            deviceId: 'this-phone',
          ),
        );
    await db.into(db.repLogs).insert(
          RepLogsCompanion.insert(
            id: 'r1',
            setLogId: 'sl1',
            repIndex: 0,
            counted: true,
            durationMs: 2400,
          ),
        );
    await db.into(db.formEvents).insert(
          FormEventsCompanion.insert(
            id: 'f1',
            setLogId: 'sl1',
            ruleId: 'squat_depth',
            severity: 'minor',
            magnitude: 4.5,
            atMs: 1200,
          ),
        );
    await db.into(db.personalRecords).insert(
          PersonalRecordsCompanion.insert(
            id: 'pr1',
            exerciseId: 'barbell_back_squat',
            kind: 'topSetWeight',
            value: 80,
            achievedAt: DateTime.utc(2026, 11, 2, 18, 10),
            deviceId: 'this-phone',
          ),
        );

    final store = DriftSyncStore(db);
    for (final table in AppDatabase.syncableTableNames) {
      await store.setCursor(table, '41');
    }

    await identity.claim(userId: 'user-1', email: 'a@example.com');
    sessions.seed(
      AuthSession(
        accessToken: 'jwt',
        refreshToken: 'refresh',
        userId: 'user-1',
        email: 'a@example.com',
        expiresAt: DateTime.utc(2026, 11, 2, 19),
      ),
    );
  }

  Future<int> rowsIn(TableInfo<Table, dynamic> table) async {
    final count = countAll();
    final row = await (db.selectOnly(table)..addColumns([count]))
        .map((row) => row.read(count))
        .getSingle();
    return row ?? 0;
  }

  group('what is left afterwards', () {
    test('every table that holds a person is empty', () async {
      await seedADeviceInUse();
      for (final table in db.allTables) {
        expect(
          await rowsIn(table),
          greaterThan(0),
          reason: '${table.actualTableName} was not seeded, so this test '
              'would pass whether or not the erase covers it',
        );
      }

      await eraser.erase();

      for (final table in db.allTables) {
        if (table.actualTableName == db.localIdentity.actualTableName) continue;
        expect(
          await rowsIn(table),
          0,
          reason: '${table.actualTableName} still holds rows',
        );
      }
    });

    test('the installation keeps its own name', () async {
      // The install id is this device's name in the conflict tie-break, and
      // it is not the departing person's — nothing about it identifies them.
      // Generating a new one would be harmless and pointless; losing it
      // while rows elsewhere still referred to it would not be.
      await seedADeviceInUse();
      final before = await identity.installId();

      await eraser.erase();

      expect(await identity.installId(), before);
      expect(await rowsIn(db.localIdentity), 1);
    });

    test('nobody owns the device', () async {
      await seedADeviceInUse();

      await eraser.erase();

      expect(await identity.owner(), isNull);
    });

    test('and so the next account is no longer refused', () async {
      // The reason this exists. Before the erase this throws.
      await seedADeviceInUse();

      await eraser.erase();
      await identity.claim(userId: 'user-2', email: 'b@example.com');

      expect((await identity.owner())?.userId, 'user-2');
    });

    test('the stored session is gone', () async {
      await seedADeviceInUse();

      await eraser.erase();

      expect(await sessions.read(), isNull);
    });

    test('every sync cursor is gone', () async {
      // A cursor is a position in the server's own replication order, and
      // that order is shared. The next account's rows can sit *behind* the
      // number this device stopped at, so a cursor that survived would make
      // their first sync skip their training and report success.
      await seedADeviceInUse();

      await eraser.erase();

      final store = DriftSyncStore(db);
      for (final table in AppDatabase.syncableTableNames) {
        expect(await store.cursor(table), isNull, reason: table);
      }
    });
  });

  group('what it must not do', () {
    test('leaves nothing for the next sync to upload', () async {
      // The one that matters most. Every delete in Spottr is a tombstone
      // that replicates: an erase that went through the ordinary delete
      // path would push a deletion for every row this device ever held, and
      // the departing person's other phone would obediently empty itself.
      await seedADeviceInUse();

      await eraser.erase();

      final store = DriftSyncStore(db);
      for (final table in AppDatabase.syncableTableNames) {
        expect(await store.pendingUpload(table), isEmpty, reason: table);
      }
    });

    test('leaves no tombstone behind at all', () async {
      // Said again at the level below, because `pendingUpload` only looks at
      // `pushed_at`: a row deleted *and* marked as pushed would satisfy the
      // test above and still be a tombstone waiting for the next device to
      // pull it.
      await seedADeviceInUse();

      await eraser.erase();

      for (final table in AppDatabase.syncableTableNames) {
        final rows = await db
            .customSelect('SELECT COUNT(*) AS n FROM $table')
            .map((row) => row.read<int>('n'))
            .getSingle();
        expect(rows, 0, reason: table);
      }
    });
  });

  group('a device that has nothing to erase', () {
    test('erases anyway, without complaining', () async {
      // A fresh install that has never signed in, and a second erase
      // straight after the first. Neither is a state the button should
      // refuse: somebody tapping it twice wants it gone, not an error.
      await eraser.erase();
      await seedADeviceInUse();
      await eraser.erase();
      await eraser.erase();

      expect(await identity.owner(), isNull);
      expect(await rowsIn(db.profiles), 0);
    });

    test('a device nobody signed in to still gets its training erased',
        () async {
      // No owner, no session: an account was never involved, and the
      // training is still somebody's.
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(
              id: 'p1',
              goal: 'hybrid',
              daysPerWeek: 3,
              sessionMinutes: 45,
              level: 'beginner',
              location: 'fullGym',
              coachPersonality: 'calm',
              deviceId: 'this-phone',
            ),
          );

      await eraser.erase();

      expect(await rowsIn(db.profiles), 0);
    });
  });
}
