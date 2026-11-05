import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine/testing.dart';
import 'package:test/test.dart';

/// The engine is the part that has to be right when the network is not.
/// Half of these tests are about a sync that did not finish, because a sync
/// that finishes is the easy case and the one that stops half way is the one
/// that loses somebody's training log.
///
/// Every test drives the real engine against in-memory stores, so what is
/// under test is the protocol rather than SQLite or PostgREST. The two
/// adapters have their own tests; this file is why they only have to be
/// adapters.
void main() {
  const tables = ['profiles', 'sessions'];

  late InMemoryLocalStore local;
  late InMemoryRemoteStore remote;

  setUp(() {
    local = InMemoryLocalStore();
    remote = InMemoryRemoteStore();
  });

  SyncEngine engine({
    List<String> only = tables,
    int pageSize = 100,
    int uploadBatchSize = 100,
  }) {
    return SyncEngine(
      local: local,
      remote: remote,
      tables: only,
      pageSize: pageSize,
      uploadBatchSize: uploadBatchSize,
    );
  }

  SyncRecord record(
    String id, {
    String table = 'sessions',
    int hour = 10,
    String deviceId = 'device-a',
    bool deleted = false,
    Map<String, Object?> fields = const {},
  }) {
    final updatedAt = DateTime.utc(2026, 11, 5, hour);
    return SyncRecord(
      table: table,
      id: id,
      updatedAt: updatedAt,
      deletedAt: deleted ? updatedAt : null,
      deviceId: deviceId,
      fields: fields,
    );
  }

  group('a fresh install', () {
    test('takes the whole remote copy and remembers where it got to', () async {
      remote.seed(record('p1', table: 'profiles'));
      remote.seed(record('s1'));
      remote.seed(record('s2'));

      final report = await engine().sync();

      expect(report.complete, isTrue);
      expect(local.ids('profiles'), ['p1']);
      expect(local.ids('sessions'), ['s1', 's2']);
      expect(await local.cursor('sessions'), isNotNull);
      expect(report.pulled, 3);
      expect(report.applied, 3);
      expect(report.conflicts, 0);
    });

    test('syncs again without writing anything', () async {
      remote.seed(record('s1'));
      await engine().sync();

      local.resetCounts();
      remote.resetCounts();
      final report = await engine().sync();

      expect(report.applied, 0);
      expect(report.pushed, 0);
      expect(local.applyCount, 0);
      expect(remote.upsertCount, 0, reason: 'nothing changed to push');
    });
  });

  group('a row written on this device', () {
    test('reaches the server and stops being pending', () async {
      local.seed(record('s1'), pending: true);

      final report = await engine().sync();

      expect(report.pushed, 1);
      expect(remote.ids('sessions'), ['s1']);
      expect(await local.pendingUpload('sessions'), isEmpty);
    });

    test('is not sent back the next time the server returns it', () async {
      // Our own push comes back on the next pull: the server stamped it
      // after the cursor we had. If applying it left the row pending, two
      // devices would trade the same row for ever and the log would fill
      // with syncs that changed nothing.
      local.seed(record('s1'), pending: true);
      await engine().sync();

      remote.resetCounts();
      final second = await engine().sync();

      expect(second.pushed, 0);
      expect(remote.upsertCount, 0);
    });

    test('is pushed in batches rather than in one request', () async {
      for (var i = 0; i < 5; i++) {
        local.seed(record('s$i'), pending: true);
      }

      final report = await engine(uploadBatchSize: 2).sync();

      expect(report.pushed, 5);
      expect(remote.upsertCount, 3, reason: '2 + 2 + 1');
      expect(remote.ids('sessions').length, 5);
    });
  });

  group('an edit made somewhere else', () {
    test('replaces a row this device has not touched', () async {
      local.seed(
        record('s1', hour: 10, fields: {'notes': 'mine'}),
        pending: false,
      );
      remote.seed(
        record(
          's1',
          hour: 11,
          deviceId: 'device-b',
          fields: {'notes': 'theirs'},
        ),
      );

      final report = await engine().sync();

      expect(local.row('sessions', 's1')!.fields['notes'], 'theirs');
      expect(
        report.conflicts,
        0,
        reason: 'a clean local row is the server copy we were last given, '
            'so being handed a newer one is an update, not a conflict',
      );
    });

    test('loses to a later edit made here, which is then pushed', () async {
      local.seed(
        record('s1', hour: 12, fields: {'notes': 'mine'}),
        pending: true,
      );
      remote.seed(
        record(
          's1',
          hour: 11,
          deviceId: 'device-b',
          fields: {'notes': 'theirs'},
        ),
      );

      final report = await engine().sync();

      expect(local.row('sessions', 's1')!.fields['notes'], 'mine');
      expect(remote.row('sessions', 's1')!.fields['notes'], 'mine');
      expect(report.conflicts, 1);
      expect(report.conflictsLostLocally, 0);
      expect(report.pushed, 1);
    });

    test('wins over an earlier edit here, which is then given up on', () async {
      // The losing side has to be marked clean as well as overwritten.
      // Left pending it would be pushed on the next sync, lose again on the
      // one after, and go round for ever — a device that never stops
      // uploading, over a row nobody is editing.
      local.seed(
        record('s1', hour: 10, fields: {'notes': 'mine'}),
        pending: true,
      );
      remote.seed(
        record(
          's1',
          hour: 11,
          deviceId: 'device-b',
          fields: {'notes': 'theirs'},
        ),
      );

      final report = await engine().sync();

      expect(local.row('sessions', 's1')!.fields['notes'], 'theirs');
      expect(report.conflicts, 1);
      expect(report.conflictsLostLocally, 1);
      expect(report.pushed, 0);
      expect(await local.pendingUpload('sessions'), isEmpty);

      remote.resetCounts();
      await engine().sync();
      expect(remote.upsertCount, 0, reason: 'the loser is not retried');
    });
  });

  group('deletes', () {
    test(
      'a session deleted elsewhere is tombstoned here, not dropped',
      () async {
        local.seed(record('s1'), pending: false);
        remote.seed(
          record('s1', hour: 11, deviceId: 'device-b', deleted: true),
        );

        await engine().sync();

        final row = local.row('sessions', 's1');
        expect(row, isNotNull, reason: 'a hard delete is invisible to a peer');
        expect(row!.isDeleted, isTrue);
      },
    );

    test('a delete made here reaches the server as a tombstone', () async {
      local.seed(record('s1', hour: 11, deleted: true), pending: true);

      await engine().sync();

      expect(remote.row('sessions', 's1')!.isDeleted, isTrue);
    });
  });

  group('order', () {
    test('a table is pushed only after the tables it points at', () async {
      // set_logs reference sessions and sessions reference plan_days. On a
      // first sync to an empty server, a child arriving before its parent is
      // a foreign key violation on the remote — and the order is also the
      // order the tables are declared in, so it is one list to get right
      // rather than a rule every caller has to remember.
      local.seed(record('p1', table: 'profiles'), pending: true);
      local.seed(record('s1'), pending: true);

      await engine().sync();

      expect(remote.upsertedTables, ['profiles', 'sessions']);
    });
  });

  group('a pull that does not fit in one page', () {
    test('leaves nothing behind', () async {
      for (var i = 0; i < 5; i++) {
        remote.seed(record('s$i'));
      }

      final report = await engine(pageSize: 2).sync();

      expect(local.ids('sessions').length, 5);
      expect(report.pulled, 5);
    });

    test('resumes from the last page it finished, not from the start',
        () async {
      for (var i = 0; i < 5; i++) {
        remote.seed(record('s$i'));
      }
      remote.failOnPage(2, const SyncOffline('no route to host'));

      final first = await engine(pageSize: 2).sync();

      expect(first.complete, isFalse);
      expect(first.error!.kind, SyncErrorKind.offline);
      expect(
        local.ids('sessions'),
        ['s0', 's1'],
        reason: 'the first page was applied and kept',
      );

      final second = await engine(pageSize: 2).sync();

      expect(second.complete, isTrue);
      expect(local.ids('sessions').length, 5);
      expect(second.pulled, 3, reason: 'it did not fetch the first page again');
    });
  });

  group('when something goes wrong', () {
    test('a table whose pull failed is not pushed', () async {
      // The local row might be the loser. Pushing it before the pull has
      // been resolved would overwrite a newer remote edit with an older
      // local one, which is the one outcome last-writer-wins exists to
      // prevent.
      local.seed(record('s1'), pending: true);
      remote.failOnPage(1, const SyncOffline('no route to host'));

      final report = await engine(only: ['sessions']).sync();

      expect(report.complete, isFalse);
      expect(report.pushed, 0);
      expect(remote.upsertCount, 0);
    });

    test('the tables after it are left alone', () async {
      // Not an optimization: profiles comes before plans for a reason, and
      // carrying on past a failed parent sends children that reference a
      // row the server has not been given.
      remote.failOnPage(1, const SyncOffline('no route to host'));
      local.seed(record('s1'), pending: true);

      final report = await engine(only: ['profiles', 'sessions']).sync();

      expect(report.tables.map((t) => t.table), ['profiles']);
      expect(remote.upsertedTables, isEmpty);
    });

    test('a push that failed leaves the row pending for the next attempt',
        () async {
      local.seed(record('s1'), pending: true);
      remote.failOnUpsert(const SyncOffline('no route to host'));

      final report = await engine(only: ['sessions']).sync();

      expect(report.complete, isFalse);
      expect(report.pushed, 0);
      expect(await local.pendingUpload('sessions'), hasLength(1));
    });

    test('no connection is a report, not an exception', () async {
      // Being offline is the normal state of a phone in a gym basement. A
      // thrown exception would make every caller write the same try/catch
      // and would read, in a crash log, like a defect.
      remote.failOnPage(1, const SyncOffline('no route to host'));

      final report = await engine().sync();

      expect(report.error!.kind, SyncErrorKind.offline);
      expect(report.error!.table, 'profiles');
    });

    test('an expired sign-in asks for a sign-in rather than retrying',
        () async {
      remote.failOnPage(1, const SyncUnauthorized('JWT expired'));

      final report = await engine().sync();

      expect(report.error!.kind, SyncErrorKind.unauthorized);
    });

    test('a row the server refused is reported and does not block the sync',
        () async {
      remote.failOnUpsert(const SyncRejected('violates row level security'));
      local.seed(record('s1'), pending: true);

      final report = await engine(only: ['sessions']).sync();

      expect(report.error!.kind, SyncErrorKind.rejected);
    });

    test('a store that fails in an unexpected way is not swallowed', () async {
      // An error the protocol has no name for is version skew or a bug in
      // an adapter, and reporting it as "sync failed, try again" would hide
      // it behind a retry button for ever.
      remote.failOnPage(1, StateError('bad JSON from PostgREST'));

      expect(engine().sync(), throwsStateError);
    });
  });

  group('the report', () {
    test('says what it did, per table', () async {
      remote.seed(record('p1', table: 'profiles'));
      local.seed(record('s1'), pending: true);

      final report = await engine().sync();

      final profiles = report.tables.firstWhere((t) => t.table == 'profiles');
      final sessions = report.tables.firstWhere((t) => t.table == 'sessions');
      expect(profiles.pulled, 1);
      expect(profiles.applied, 1);
      expect(profiles.pushed, 0);
      expect(sessions.pulled, 0);
      expect(sessions.pushed, 1);
      expect(report.pushed, 1);
      expect(report.applied, 1);
    });
  });
}
