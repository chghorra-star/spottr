import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/sync/sync_tables.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../support/test_database.dart';

/// `supabase/migrations/0001_init.sql` is the third file in this project that
/// nothing checks, after the CI workflow and the Podfile, and it is the worst
/// of the three. It cannot be compiled, it cannot be analyzed, it only ever
/// runs on somebody else's infrastructure — and two of its mistakes are
/// silent. A forgotten column rejects one table's rows with nothing on the
/// phone to say which. A forgotten `enable row level security` publishes a
/// stranger's training log.
///
/// So this test reads the SQL and compares it against drift's own metadata,
/// column by column and type by type, and refuses to pass on a line it could
/// not parse. It is not a substitute for running the migration. It is the
/// difference between finding the mistake here and finding it after somebody
/// has signed in.
void main() {
  late AppDatabase db;
  late String sql;
  late Map<String, String> tableBodies;

  setUpAll(() {
    final file = File('${_repoRoot().path}/supabase/migrations/0001_init.sql');
    // Comments are stripped before anything is searched for, because the
    // comments in that file talk about the things these tests check are
    // absent — a plain text search would find the sentence saying there is
    // no video table and call it a video table.
    sql = file
        .readAsLinesSync()
        .map((line) => line.replaceAll(RegExp(r'--.*$'), ''))
        .join('\n');

    tableBodies = {
      for (final match
          in RegExp(r'create table public\.(\w+) \(([\s\S]*?)\n\);')
              .allMatches(sql))
        match.group(1)!: match.group(2)!,
    };
  });

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  group('what is on the server', () {
    test('is exactly the tables the app says replicate', () {
      expect(tableBodies.keys.toSet(), AppDatabase.syncableTableNames);
    });

    test('does not include the diagnostic tables, anywhere', () {
      // Per-rep traces and rule verdicts stay on the phone. The strongest
      // form of that promise is that there is nowhere to put them.
      for (final table in AppDatabase.localOnlyTableNames) {
        expect(
          sql,
          isNot(contains(table)),
          reason: '$table is local-only and must not exist on the server',
        );
      }
    });

    test('has nowhere to put a frame, a landmark or a pose', () {
      // Video never leaves the device, and under this design it is never
      // stored at all. Nothing in the sync carries frames, images or
      // landmark traces, and this is the test that says so out loud.
      for (final word in ['landmark', 'frame', 'pose', 'video', 'image']) {
        expect(
          sql.toLowerCase(),
          isNot(contains(word)),
          reason: 'nothing to do with $word belongs on the server',
        );
      }
    });

    test('does not carry this device bookkeeping', () {
      // pushed_at is what *this* install has uploaded. Another device's copy
      // of it is meaningless, and the app never sends it.
      expect(sql, isNot(contains('pushed_at')));
    });
  });

  group('every column the app has', () {
    test('is on the server, with a type that will accept it', () {
      for (final table in spottrSyncTables) {
        final info = db.allTables.firstWhere((t) => t.actualTableName == table);
        final remote = _columns(table, tableBodies[table]!);

        final expected = {
          for (final column in info.$columns)
            if (column.name != 'pushed_at') column.name,
          // Added by the server side of the protocol, not by the app.
          'user_id',
          'synced_seq',
        };

        expect(
          remote.keys.toSet(),
          expected,
          reason: 'the columns of $table do not match the app',
        );

        for (final column in info.$columns) {
          if (column.name == 'pushed_at') continue;
          final declared = remote[column.name]!;

          expect(
            declared.type,
            _postgresType(column),
            reason: '$table.${column.name} is ${column.type} in the app',
          );
          expect(
            declared.nullable,
            column.$nullable,
            reason: '$table.${column.name} disagrees about being optional: '
                'a column the app may leave null and the server may not is a '
                'rejected row, and the other way round is a crash on read',
          );
        }
      }
    });

    test('and the envelope is there on all of them', () {
      for (final table in spottrSyncTables) {
        final remote = _columns(table, tableBodies[table]!);
        for (final column in envelopeColumns) {
          expect(remote.keys, contains(column), reason: '$table needs $column');
        }
      }
    });
  });

  group('identity', () {
    test('every row is keyed by the account as well as by the row', () {
      // The app's ids are generated on the device and are unique within one
      // person's data only. Keyed by id alone, one user's session log would
      // collide with another's.
      for (final table in spottrSyncTables) {
        expect(
          tableBodies[table],
          contains('primary key (user_id, id)'),
          reason: '$table is not keyed by (user_id, id)',
        );
      }
    });

    test('every foreign key keeps a child in its parent account', () {
      final keys = RegExp(r'foreign key \(([^)]*)\)').allMatches(sql);
      expect(keys, isNotEmpty);
      for (final key in keys) {
        expect(
          key.group(1),
          startsWith('user_id, '),
          reason: 'a child row must only ever point at its own account',
        );
      }
    });
  });

  group('row level security', () {
    test('is applied to the same list of tables the app syncs', () {
      // Applied in a loop rather than seven times over, because the failure
      // mode of repetition is missing one table — which reads as nothing at
      // all until somebody can see a stranger's sessions. This test checks
      // the loop's list.
      final array = RegExp(r'foreach target in array array\[([\s\S]*?)\]')
          .firstMatch(sql);
      expect(array, isNotNull, reason: 'the security loop has gone');

      final listed = RegExp("'([a-z_]+)'")
          .allMatches(array!.group(1)!)
          .map((m) => m.group(1)!)
          .toSet();

      expect(listed, AppDatabase.syncableTableNames);
    });

    test('is enabled, and reads and writes are the owner only', () {
      expect(sql, contains('enable row level security'));
      expect(sql, contains('for select'));
      expect(sql, contains("using (user_id = auth.uid())"));
      // with check, not using: this is the half that stops a client writing
      // a row stamped with somebody else's account.
      expect(sql, contains('for insert'));
      expect(sql, contains('with check (user_id = auth.uid())'));
      expect(sql, contains('for update'));
    });

    test('nothing can be hard deleted, by policy and by grant', () {
      // Spottr's deletes are soft so that a peer finds out. A hard delete is
      // invisible to a device that has not synced since, which resurrects
      // the row on the next sync. The server refusing is that rule made
      // structural rather than merely intended.
      expect(
        sql,
        isNot(contains('for delete')),
        reason: 'a delete policy would allow a row to vanish',
      );
      expect(sql, contains('revoke all on table public.%I from anon'));
      expect(sql, contains('grant select, insert, update'));
      expect(
        sql,
        isNot(contains('grant select, insert, update, delete')),
        reason: 'authenticated must not hold delete',
      );
    });

    test('an unauthenticated client gets nothing', () {
      expect(sql, contains('from anon'));
      expect(sql, isNot(contains('to anon')));
    });
  });

  group('the cursor', () {
    test('is a sequence stamped by a trigger, not a timestamp', () {
      // `now()` is the transaction start time, so a batch of upserted rows
      // all share it — and a client paging through them would move its
      // cursor to that timestamp, ask for rows strictly after it, and never
      // see the rest of the batch. Somebody's training missing from their
      // second device, with every sync reporting success.
      expect(sql, contains('create sequence'));
      expect(sql, contains("nextval('public.sync_seq')"));
      expect(
        sql,
        isNot(contains('synced_at timestamptz')),
        reason: 'the replication order must not be a clock',
      );
    });

    test('advances on an update as well as an insert', () {
      // A row edited on one device has to reach a peer whose cursor is
      // already past the value it had when it was first written. A column
      // default alone would not do that.
      expect(sql, contains('before insert or update'));
    });

    test('is indexed the way the pull asks for it', () {
      expect(sql, contains('(user_id, synced_seq)'));
    });
  });
}

/// One column as the SQL declares it.
class _Column {
  const _Column(this.type, {required this.nullable});

  final String type;
  final bool nullable;
}

/// Every column in a `create table` body.
///
/// Refuses to skip a line it does not recognise. A parser that shrugged at
/// an unexpected line would quietly stop checking the column underneath it,
/// which is the failure this whole file exists to prevent.
Map<String, _Column> _columns(String table, String body) {
  const constraintKeywords = {
    'primary',
    'foreign',
    'unique',
    'check',
    'constraint',
  };
  final declaration = RegExp(
    r'^\s+([a-z_]+)\s+'
    r'(uuid|text|integer|bigint|boolean|timestamptz|double precision)\b'
    r'(.*)$',
  );

  final columns = <String, _Column>{};
  for (final line in body.split('\n')) {
    if (line.trim().isEmpty) continue;
    if (constraintKeywords.contains(line.trim().split(' ').first)) continue;

    final match = declaration.firstMatch(line);
    expect(
      match,
      isNotNull,
      reason: 'this test cannot read "$line" in $table, so it is not '
          'checking whatever that line declares',
    );

    columns[match!.group(1)!] = _Column(
      match.group(2)!,
      nullable: !match.group(3)!.contains('not null'),
    );
  }
  return columns;
}

String? _postgresType(GeneratedColumn<Object> column) {
  return switch (column.type) {
    DriftSqlType.string => 'text',
    DriftSqlType.int => 'integer',
    DriftSqlType.bigInt => 'bigint',
    DriftSqlType.double => 'double precision',
    DriftSqlType.bool => 'boolean',
    DriftSqlType.dateTime => 'timestamptz',
    _ => null,
  };
}

/// Walks up from wherever the test runner started to the repository root.
Directory _repoRoot() {
  var directory = Directory.current;
  while (!Directory('${directory.path}/supabase').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('no supabase/ directory above ${Directory.current}');
    }
    directory = parent;
  }
  return directory;
}
