import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/database.dart';

import '../support/test_database.dart';
import 'generated_migrations/schema.dart';

/// The app's first migration, and the first thing in it that nothing else
/// could check: a migration only ever runs on a database this machine does
/// not have — somebody else's phone, with their training in it.
///
/// `drift_schemas/drift_schema_v1.json` was dumped from the v1 code before
/// the sync columns were added, so the v1 database these tests start from is
/// the schema that actually shipped rather than a hand-written guess at it.
///
/// Two separate questions, and the second is the one that costs data. Does
/// the migration run? And does what was already in there survive it in a
/// state the first sync will actually upload?
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    configureSqliteForTests();
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('a v1 database arrives at exactly the schema v2 declares', () async {
    // migrateAndValidate compares the migrated database against the schema
    // the generated code expects, column by column. A migration that runs
    // without error and leaves a column off is the shape of bug that shows
    // up later as a query failing on one user's phone and nobody else's.
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase.forTesting(schema.newConnection());

    await verifier.migrateAndValidate(db, 2);

    await db.close();
  });

  test('training logged before sync existed is pending afterwards', () async {
    // Every row on the device predates the first sync, so every row has to
    // go up. pushed_at is added nullable with no default precisely so that
    // the answer to "has the server seen this?" is no for all of it.
    //
    // The alternative — backfilling pushed_at to the migration time — would
    // mark the user's entire training history as already uploaded. The first
    // sync would then push nothing, report success, and the second device
    // would show an empty app.
    final schema = await verifier.schemaAt(1);
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

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

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
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

    expect(await db.select(db.syncState).get(), isEmpty);

    await db.close();
  });
}
