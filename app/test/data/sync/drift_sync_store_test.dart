import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/sync/drift_sync_store.dart';
import 'package:spottr/data/sync/sync_tables.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../support/test_database.dart';

/// The store is the whole of what the protocol knows about SQLite, and it is
/// generic: it reads the column list out of drift's own metadata rather than
/// naming seven tables, so adding an eighth is one entry in
/// [spottrSyncTables] and no new code. The price of that is that the type
/// mapping is written by hand, which is what most of this file is about — a
/// boolean that crosses as 0 and a timestamp that crosses as a unix integer
/// are both rows PostgREST refuses, and neither is visible until a real
/// server says so.
void main() {
  late AppDatabase db;
  late DriftSyncStore store;
  var clock = DateTime.utc(2026, 11, 5, 12);

  setUp(() {
    db = openTestDatabase();
    store = DriftSyncStore(db, now: () => clock);
  });
  tearDown(() => db.close());

  Future<void> insertProfile({
    String id = 'p1',
    DateTime? updatedAt,
    String deviceId = 'this-phone',
  }) async {
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: id,
            goal: 'hybrid',
            daysPerWeek: 3,
            sessionMinutes: 45,
            level: 'beginner',
            location: 'homeDumbbells',
            coachPersonality: 'calm',
            deviceId: deviceId,
            updatedAt: Value(updatedAt ?? DateTime.utc(2026, 11, 5, 10)),
          ),
        );
  }

  SyncRecord profileRecord({
    String id = 'p1',
    int hour = 11,
    String deviceId = 'other-phone',
    String goal = 'muscleBuilding',
    DateTime? deletedAt,
    double? weightKg,
  }) {
    return SyncRecord(
      table: 'profiles',
      id: id,
      updatedAt: DateTime.utc(2026, 11, 5, hour),
      deletedAt: deletedAt,
      deviceId: deviceId,
      fields: {
        'goal': goal,
        'days_per_week': 4,
        'session_minutes': 60,
        'level': 'intermediate',
        'age_years': null,
        'height_cm': null,
        'weight_kg': weightKg,
        'sex': null,
        'injuries': '["knees"]',
        'injury_notes': null,
        'location': 'fullGym',
        'equipment': '[]',
        'coach_personality': 'hype',
        'run_days': '[]',
        'disclaimer_accepted_at': '2026-11-01T09:00:00.000Z',
      },
    );
  }

  group('what is waiting to go up', () {
    test('a row written on this device is offered', () async {
      await insertProfile();

      final pending = await store.pendingUpload('profiles');

      expect(pending, hasLength(1));
      expect(pending.single.id, 'p1');
      expect(pending.single.deviceId, 'this-phone');
      expect(pending.single.updatedAt, DateTime.utc(2026, 11, 5, 10));
    });

    test('a row the server has acknowledged is not', () async {
      await insertProfile();
      final sent = (await store.pendingUpload('profiles')).single;

      await store.markPushed('profiles', [sent]);

      expect(await store.pendingUpload('profiles'), isEmpty);
    });

    test('an edit after the acknowledgement is offered again', () async {
      await insertProfile();
      final sent = (await store.pendingUpload('profiles')).single;
      await store.markPushed('profiles', [sent]);

      await (db.update(db.profiles)..where((t) => t.id.equals('p1'))).write(
        ProfilesCompanion(
          goal: const Value('weightLoss'),
          updatedAt: Value(DateTime.utc(2026, 11, 5, 13)),
        ),
      );

      expect(await store.pendingUpload('profiles'), hasLength(1));
    });

    test('an edit made while the upload was in flight stays pending',
        () async {
      // Uploading is an await, and the user can change their profile during
      // it. Acknowledging whatever updated_at is in storage *now* would mark
      // an edit the server never saw as sent, and nothing would offer it
      // again.
      await insertProfile();
      final sent = (await store.pendingUpload('profiles')).single;

      await (db.update(db.profiles)..where((t) => t.id.equals('p1'))).write(
        ProfilesCompanion(updatedAt: Value(DateTime.utc(2026, 11, 5, 14))),
      );
      await store.markPushed('profiles', [sent]);

      final pending = await store.pendingUpload('profiles');
      expect(pending, hasLength(1));
      expect(pending.single.updatedAt, DateTime.utc(2026, 11, 5, 14));
    });

    test('a soft-deleted row is still offered, as a tombstone', () async {
      // The whole point of a soft delete is that the peer finds out.
      await insertProfile();
      await (db.update(db.profiles)..where((t) => t.id.equals('p1'))).write(
        ProfilesCompanion(
          deletedAt: Value(DateTime.utc(2026, 11, 5, 11)),
          updatedAt: Value(DateTime.utc(2026, 11, 5, 11)),
        ),
      );

      final pending = await store.pendingUpload('profiles');

      expect(pending.single.isDeleted, isTrue);
      expect(pending.single.deletedAt, DateTime.utc(2026, 11, 5, 11));
    });
  });

  group('the shape a row crosses in', () {
    test('the envelope is hoisted out of the payload', () async {
      await insertProfile();

      final record = (await store.pendingUpload('profiles')).single;

      expect(record.fields.keys, isNot(contains('id')));
      expect(record.fields.keys, isNot(contains('updated_at')));
      expect(record.fields.keys, isNot(contains('deleted_at')));
      expect(record.fields.keys, isNot(contains('device_id')));
    });

    test('pushed_at does not cross at all', () async {
      // It is this install's record of what it has uploaded. Sending it
      // would hand every other device this device's bookkeeping, and the
      // remote has no column for it.
      await insertProfile();

      final record = (await store.pendingUpload('profiles')).single;

      expect(record.fields.keys, isNot(contains('pushed_at')));
    });

    test('a boolean crosses as a boolean, not as 0 or 1', () async {
      // SQLite has no boolean type, so is_active comes out of the database
      // as an integer. PostgREST refuses `{"is_active": 1}` for a boolean
      // column, and the row is rejected with nothing in the app to say why.
      await insertProfile();
      await db.into(db.plans).insert(
            PlansCompanion.insert(
              id: 'pl1',
              profileId: 'p1',
              templateId: 'full_body_3',
              goal: 'hybrid',
              createdAt: DateTime.utc(2026, 11, 1),
              deviceId: 'this-phone',
              isActive: const Value(true),
            ),
          );

      final record = (await store.pendingUpload('plans')).single;

      expect(record.fields['is_active'], isA<bool>());
      expect(record.fields['is_active'], isTrue);
    });

    test('a timestamp in the payload crosses as an ISO-8601 string', () async {
      // created_at is a payload column rather than part of the envelope, so
      // it is the one that would quietly cross as whatever SQLite happens to
      // hold. A unix integer in a timestamptz column is the year 1970.
      await insertProfile();
      await db.into(db.plans).insert(
            PlansCompanion.insert(
              id: 'pl1',
              profileId: 'p1',
              templateId: 'full_body_3',
              goal: 'hybrid',
              createdAt: DateTime.utc(2026, 11, 1, 8, 30),
              deviceId: 'this-phone',
            ),
          );

      final record = (await store.pendingUpload('plans')).single;

      expect(record.fields['created_at'], '2026-11-01T08:30:00.000Z');
    });

    test('a timestamp is normalized to UTC, not passed through', () async {
      // Whatever is in the column, the wire carries UTC: two devices in two
      // time zones have to compare the same instant. Written in through raw
      // SQL because nothing in the app would store an offset — which is the
      // point, since a conversion that is a no-op for every value the app
      // writes is a conversion no test can tell is there.
      await insertProfile();
      await db.into(db.plans).insert(
            PlansCompanion.insert(
              id: 'pl1',
              profileId: 'p1',
              templateId: 'full_body_3',
              goal: 'hybrid',
              createdAt: DateTime.utc(2026, 11, 1),
              deviceId: 'this-phone',
            ),
          );
      await db.customStatement(
        "UPDATE plans SET created_at = '2026-11-01T09:30:00.000+01:00'",
      );

      final record = (await store.pendingUpload('plans')).single;

      expect(record.fields['created_at'], '2026-11-01T08:30:00.000Z');
    });

    test('a null column crosses as null rather than being left out', () async {
      // A payload missing a column cannot clear it on the other side: the
      // upsert would leave whatever was there, and a weight the user deleted
      // would come back.
      await insertProfile();

      final record = (await store.pendingUpload('profiles')).single;

      expect(record.fields.containsKey('weight_kg'), isTrue);
      expect(record.fields['weight_kg'], isNull);
    });
  });

  group('writing the server copy in', () {
    test('a row this device has never seen is inserted', () async {
      await store.applyRemote(profileRecord());

      final stored = await db.select(db.profiles).getSingle();
      expect(stored.goal, 'muscleBuilding');
      expect(stored.coachPersonality, 'hype');
      expect(stored.deviceId, 'other-phone');
      expect(stored.injuries, '["knees"]');
      expect(stored.disclaimerAcceptedAt, DateTime.utc(2026, 11, 1, 9));
    });

    test('it is written clean, so it is not pushed straight back', () async {
      await store.applyRemote(profileRecord());

      expect(await store.pendingUpload('profiles'), isEmpty);
    });

    test('a row that is already here is replaced, not merged', () async {
      // Every column, not only the ones that differ. A partial upsert leaves
      // stale values behind, so a field somebody cleared on one device comes
      // back from the other.
      await insertProfile();
      await (db.update(db.profiles)..where((t) => t.id.equals('p1'))).write(
        const ProfilesCompanion(weightKg: Value(82.5)),
      );

      await store.applyRemote(profileRecord(weightKg: null));

      final stored = await db.select(db.profiles).getSingle();
      expect(stored.weightKg, isNull);
      expect(stored.goal, 'muscleBuilding');
    });

    test('a tombstone arrives as a tombstone', () async {
      await insertProfile();

      await store.applyRemote(
        profileRecord(deletedAt: DateTime.utc(2026, 11, 5, 11)),
      );

      final stored = await db.select(db.profiles).getSingle();
      expect(stored.deletedAt, DateTime.utc(2026, 11, 5, 11));
    });

    test('it wakes up the streams the app is watching', () async {
      // The repositories hand the UI a watch(). A write that does not tell
      // drift which table it touched leaves the plan screen showing the old
      // plan until something else happens to change it.
      final seen = <int>[];
      final sub = db.select(db.profiles).watch().listen((r) => seen.add(r.length));
      await pumpEventQueue();

      await store.applyRemote(profileRecord());
      await pumpEventQueue();

      expect(seen, [0, 1]);
      await sub.cancel();
    });

    test('a column this app does not have is an error, not a shrug', () async {
      // A row from a newer version of the app. Dropping the column silently
      // would write a row that is not the row the server holds, and then
      // push it back as though it were.
      final record = SyncRecord(
        table: 'profiles',
        id: 'p1',
        updatedAt: DateTime.utc(2026, 11, 5, 11),
        deviceId: 'other-phone',
        fields: {...profileRecord().fields, 'favourite_colour': 'blue'},
      );

      expect(() => store.applyRemote(record), throwsStateError);
    });
  });

  group('the cursor', () {
    test('starts unset, so the first pull asks for everything', () async {
      expect(await store.cursor('profiles'), isNull);
    });

    test('round-trips, per table', () async {
      await store.setCursor('profiles', '2026-11-05T12:00:00Z');

      expect(await store.cursor('profiles'), '2026-11-05T12:00:00Z');
      expect(await store.cursor('sessions'), isNull);
    });

    test('is overwritten rather than duplicated', () async {
      await store.setCursor('profiles', 'one');
      await store.setCursor('profiles', 'two');

      expect(await store.cursor('profiles'), 'two');
      expect(await db.select(db.syncState).get(), hasLength(1));
    });

    test('records when the table was last synced, for telling the user',
        () async {
      clock = DateTime.utc(2026, 11, 5, 15, 30);

      await store.setCursor('profiles', 'one');

      final row = await db.select(db.syncState).getSingle();
      expect(row.syncedAt, DateTime.utc(2026, 11, 5, 15, 30));
    });
  });

  group('the table list', () {
    test('is exactly the tables the schema says replicate', () {
      expect(spottrSyncTables.toSet(), AppDatabase.syncableTableNames);
      expect(
        spottrSyncTables.length,
        AppDatabase.syncableTableNames.length,
        reason: 'a table listed twice is pushed twice',
      );
    });

    test('puts every table after the ones it points at', () async {
      // Asked of SQLite rather than written down, because the answer is in
      // the schema and a hand-kept order goes stale. It matters on the
      // remote, where the foreign keys are enforced: a child arriving before
      // its parent on a first sync is a rejected row.
      for (final table in spottrSyncTables) {
        final references = await db
            .customSelect('PRAGMA foreign_key_list("$table")')
            .get();

        for (final reference in references) {
          final parent = reference.read<String>('table');
          if (!spottrSyncTables.contains(parent) || parent == table) continue;

          expect(
            spottrSyncTables.indexOf(parent),
            lessThan(spottrSyncTables.indexOf(table)),
            reason: '$table references $parent, so $parent has to go first',
          );
        }
      }
    });

    test('every one of them round-trips through the store unchanged', () async {
      // Walks the whole list rather than sampling it. The type mapping is
      // written by hand, so the column that breaks it is the one nobody
      // thought to write a test for.
      for (final table in spottrSyncTables) {
        final info =
            db.allTables.firstWhere((t) => t.actualTableName == table);
        final sent = _syntheticRecord(table, info);

        await store.applyRemote(sent);
        // Applied clean, so make it dirty again to read it back out through
        // the same path a push would.
        await db.customStatement('UPDATE "$table" SET pushed_at = NULL');

        final readBack = (await store.pendingUpload(table)).single;
        expect(readBack, sent, reason: '$table did not survive the round trip');
      }
    });

    test('each of them is identified by a single id column', () async {
      // The upsert is built from the primary key. A composite one would need
      // a different statement, and getting that wrong writes duplicates
      // rather than failing.
      for (final table in spottrSyncTables) {
        final info =
            db.allTables.firstWhere((t) => t.actualTableName == table);
        expect(
          info.$primaryKey.map((c) => c.name),
          ['id'],
          reason: '$table is not keyed by a single id',
        );
      }
    });
  });
}

/// A record with a plausible value in every payload column, derived from the
/// table's own metadata so that a new column is covered the day it is added.
SyncRecord _syntheticRecord(String table, TableInfo<Table, dynamic> info) {
  final fields = <String, Object?>{};
  for (final column in info.$columns) {
    if (envelopeColumns.contains(column.name) || column.name == 'pushed_at') {
      continue;
    }
    fields[column.name] = switch (column.type) {
      DriftSqlType.bool => true,
      DriftSqlType.int => 7,
      DriftSqlType.bigInt => 7,
      DriftSqlType.double => 7.5,
      DriftSqlType.string => 'value',
      DriftSqlType.dateTime => '2026-11-02T07:15:00.000Z',
      DriftSqlType.blob => throw StateError('no blob column should sync'),
      DriftSqlType.any => throw StateError('no untyped column should sync'),
      _ => throw StateError('no ${column.type} column should sync'),
    };
  }

  return SyncRecord(
    table: table,
    id: 'row-1',
    updatedAt: DateTime.utc(2026, 11, 5, 10),
    deviceId: 'this-phone',
    fields: fields,
  );
}
