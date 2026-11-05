import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/local/local_identity_store.dart';

import '../support/test_database.dart';
import 'generated_migrations/schema.dart';

/// Migrations are the one piece of code here that only ever runs on a
/// database this machine does not have — somebody else's phone, with their
/// training in it. That puts them in the same category as the CI workflow
/// and the Podfile, and M9 is recent enough to make the category worth
/// taking seriously.
///
/// Each snapshot in `drift_schemas/` was dumped from the code that declared
/// that version, before the next one was written, so the databases these
/// tests start from are the schemas that actually shipped rather than
/// hand-written guesses at them.
///
/// Two questions per step, and the second is the one that costs data. Does
/// the migration run? And does what was already in there survive it in a
/// state the rest of the app will accept?
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    configureSqliteForTests();
    verifier = SchemaVerifier(GeneratedHelper());
  });

  /// A v1 profile, written through raw SQL because the v1 Dart classes are
  /// gone. Everything a real install would have had.
  Future<void> insertV1Profile(InitializedSchema schema) async {
    schema.rawDatabase.execute('''
      INSERT INTO profiles (
        id, goal, days_per_week, session_minutes, level, injuries,
        location, equipment, coach_personality, run_days,
        updated_at, device_id
      ) VALUES (
        'p1', 'hybrid', 3, 45, 'beginner', '[]',
        'homeDumbbells', '[]', 'calm', '[]',
        '2026-11-05T10:00:00.000Z', 'old-phone'
      )
    ''');
  }

  group('every step', () {
    test('a v1 database arrives at exactly the schema v3 declares', () async {
      // migrateAndValidate compares the migrated database against the
      // schema the generated code expects, column by column and constraint
      // by constraint. A migration that runs without error and leaves a
      // column off is the shape of bug that surfaces later as a query
      // failing on one person's phone and nobody else's.
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());

      await verifier.migrateAndValidate(db, 3);

      await db.close();
    });

    test('and so does a v2 one, which is where most installs will be',
        () async {
      // v2 never shipped to anybody — it and v3 are both M10 — but the step
      // has to work on its own, because the next version will migrate from
      // v3 and the chain is only as good as its weakest link.
      final schema = await verifier.schemaAt(2);
      final db = AppDatabase(schema.newConnection());

      await verifier.migrateAndValidate(db, 3);

      await db.close();
    });
  });

  group('what survives it', () {
    test('training logged before sync existed is pending afterwards',
        () async {
      // Every row on the device predates the first sync, so every row has
      // to go up. `pushed_at` is added nullable with no default precisely so
      // that the answer to "has the server seen this?" is no for all of it.
      //
      // The alternative — backfilling it to the migration time — would mark
      // somebody's entire training history as already uploaded. The first
      // sync would push nothing, report success, and the second device would
      // show an empty app.
      final schema = await verifier.schemaAt(1);
      await insertV1Profile(schema);

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);

      final stored = await db.select(db.profiles).getSingle();
      expect(stored.goal, 'hybrid', reason: 'the row survived the migration');
      expect(stored.deviceId, 'old-phone');
      expect(stored.pushedAt, isNull, reason: 'nothing has uploaded it yet');

      await db.close();
    });

    test('the cursor table starts empty, so the first pull takes everything',
        () async {
      // A cursor that migrated in with a value would skip everything the
      // server already holds, which is the same bug from the other side.
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);

      expect(await db.select(db.syncState).get(), isEmpty);

      await db.close();
    });

    test('an upgraded install has no name yet, and gets one when asked',
        () async {
      // Nothing backfills the install id: the migration creates an empty
      // table and the id is generated the first time something asks. An
      // upgraded install therefore picks one up on its next launch and
      // keeps it, rather than the migration having to invent one inside a
      // transaction it cannot retry.
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);

      expect(await db.select(db.localIdentity).get(), isEmpty);
      expect(await LocalIdentityStore(db).installId(), isNotEmpty);

      await db.close();
    });

    test('the rows the old device wrote still say which device wrote them',
        () async {
      // The old rows carry `device_id = 'local'`, the constant every install
      // used before v3. They keep it: rewriting them to this install's new
      // id would be a claim about who wrote them, and on a second device the
      // same rows would claim something different.
      final schema = await verifier.schemaAt(1);
      await insertV1Profile(schema);

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);

      final stored = await db.select(db.profiles).getSingle();
      expect(stored.deviceId, 'old-phone');

      await db.close();
    });
  });
}
