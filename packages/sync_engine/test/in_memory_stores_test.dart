import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine/testing.dart';
import 'package:test/test.dart';

/// These two stores ship in `lib/`, not in `test/`, because the app's widget
/// tests need a sync that works without a database or a network. That makes
/// them code, and it makes every engine test downstream of them: a fake that
/// is wrong in the same direction as the engine agrees with it and proves
/// nothing.
///
/// So the parts the engine leans on are pinned here — the cursor is
/// monotonic and opaque, a page is ordered and says whether there is more,
/// and "pending" means written locally and not yet acknowledged.
void main() {
  SyncRecord record(
    String id, {
    String table = 'sessions',
    int hour = 10,
    Map<String, Object?> fields = const {},
  }) {
    return SyncRecord(
      table: table,
      id: id,
      updatedAt: DateTime.utc(2026, 11, 5, hour),
      deviceId: 'device-a',
      fields: fields,
    );
  }

  group('the remote store', () {
    late InMemoryRemoteStore remote;

    setUp(() => remote = InMemoryRemoteStore());

    test('returns rows in the order it was given them', () async {
      remote.seed(record('s2'));
      remote.seed(record('s1'));

      final page = await remote.changesSince('sessions', limit: 10);

      expect(page.records.map((r) => r.id), ['s2', 's1']);
      expect(page.hasMore, isFalse);
      expect(page.cursor, isNotNull);
    });

    test('an empty table returns no cursor to advance to', () async {
      final page = await remote.changesSince('sessions', limit: 10);

      expect(page.records, isEmpty);
      expect(page.cursor, isNull);
      expect(page.hasMore, isFalse);
    });

    test('a page says when there is more behind it', () async {
      for (var i = 0; i < 3; i++) {
        remote.seed(record('s$i'));
      }

      final first = await remote.changesSince('sessions', limit: 2);
      expect(first.records.map((r) => r.id), ['s0', 's1']);
      expect(first.hasMore, isTrue);

      final second =
          await remote.changesSince('sessions', cursor: first.cursor, limit: 2);
      expect(second.records.map((r) => r.id), ['s2']);
      expect(second.hasMore, isFalse);
    });

    test('an upsert re-stamps the row, so a peer sees it as new', () async {
      // The stamp is the server's replication order, not the author's clock.
      // A row edited after a peer's cursor has to come back to that peer
      // even though its updatedAt may be older than rows it already has.
      remote.seed(record('s1'));
      remote.seed(record('s2'));
      final caughtUp = await remote.changesSince('sessions', limit: 10);

      await remote.upsert('sessions', [record('s1', hour: 12)]);
      final page = await remote.changesSince(
        'sessions',
        cursor: caughtUp.cursor,
        limit: 10,
      );

      expect(page.records.map((r) => r.id), ['s1']);
      expect(page.records.single.updatedAt.hour, 12);
      expect(remote.ids('sessions').length, 2, reason: 'replaced, not added');
    });

    test('one table cannot see another table rows', () async {
      remote.seed(record('p1', table: 'profiles'));

      final page = await remote.changesSince('sessions', limit: 10);

      expect(page.records, isEmpty);
    });
  });

  group('the local store', () {
    late InMemoryLocalStore local;

    setUp(() => local = InMemoryLocalStore());

    test('a row seeded as pending is offered for upload', () async {
      local.seed(record('s1'), pending: true);
      local.seed(record('s2'), pending: false);

      expect(
        (await local.pendingUpload('sessions')).map((r) => r.id),
        ['s1'],
      );
    });

    test('a pushed row stops being pending', () async {
      final pushed = record('s1');
      local.seed(pushed, pending: true);

      await local.markPushed('sessions', [pushed]);

      expect(await local.pendingUpload('sessions'), isEmpty);
      expect(local.row('sessions', 's1'), isNotNull);
    });

    test('an edit made while the upload was in flight stays pending',
        () async {
      // The upload is an await, and the user can log a set during it.
      // Marking the row clean at whatever updated_at is in storage *now*
      // would acknowledge an edit the server never saw, and nothing would
      // ever offer it again.
      final sent = record('s1', hour: 10);
      local.seed(sent, pending: true);
      local.seed(record('s1', hour: 11), pending: true);

      await local.markPushed('sessions', [sent]);

      expect(
        (await local.pendingUpload('sessions')).single.updatedAt.hour,
        11,
      );
    });

    test('a remote row is applied clean, not pending', () async {
      // This is the property the whole ping-pong question rests on, so it is
      // asserted of the fake as well as of the engine.
      await local.applyRemote(record('s1'));

      expect(local.row('sessions', 's1'), isNotNull);
      expect(await local.pendingUpload('sessions'), isEmpty);
    });

    test('applying over a local row replaces its payload', () async {
      local.seed(record('s1', fields: {'notes': 'mine'}), pending: true);

      await local.applyRemote(record('s1', hour: 11, fields: {'notes': 'theirs'}));

      expect(local.row('sessions', 's1')!.fields['notes'], 'theirs');
      expect(await local.pendingUpload('sessions'), isEmpty);
    });

    test('a cursor is remembered per table', () async {
      expect(await local.cursor('sessions'), isNull);

      await local.setCursor('sessions', '7');

      expect(await local.cursor('sessions'), '7');
      expect(await local.cursor('profiles'), isNull);
    });
  });
}
