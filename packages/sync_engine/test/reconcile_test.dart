import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

/// Two devices that cannot talk to each other have to resolve the same
/// conflict the same way, or they swap the row back and forth for ever.
/// That is the whole reason this is a total order over (updatedAt, deviceId)
/// rather than "the newest one, and otherwise the remote".
///
/// The tests are named for what happened to the user, not for the branch
/// they cover, because the failure worth recognising is "the edit I made on
/// the train disappeared" rather than "case three".
void main() {
  SyncRecord at(
    String isoHour, {
    String deviceId = 'device-a',
    bool deleted = false,
    Map<String, Object?> fields = const {},
  }) {
    final updatedAt = DateTime.utc(2026, 11, 5, int.parse(isoHour));
    return SyncRecord(
      table: 'sessions',
      id: 's1',
      updatedAt: updatedAt,
      deletedAt: deleted ? updatedAt : null,
      deviceId: deviceId,
      fields: fields,
    );
  }

  test('the edit made later wins, whichever device made it', () {
    expect(reconcile(at('10'), at('11', deviceId: 'device-b')),
        MergeChoice.takeRemote);
    expect(reconcile(at('11'), at('10', deviceId: 'device-b')),
        MergeChoice.keepLocal);
  });

  test('a delete is just a later edit, not a special case', () {
    // deletedAt is a column, so a tombstone competes on its timestamp like
    // anything else. Deleting a session on the phone and renaming it on the
    // tablet a minute later leaves it renamed, which is what the clock says
    // happened.
    expect(
      reconcile(at('10'), at('11', deviceId: 'device-b', deleted: true)),
      MergeChoice.takeRemote,
    );
    expect(
      reconcile(at('11', deleted: true), at('10', deviceId: 'device-b')),
      MergeChoice.keepLocal,
    );
  });

  group('two edits at the same instant', () {
    test('resolve by device id, so neither device needs to ask the other', () {
      expect(reconcile(at('10', deviceId: 'device-a'),
          at('10', deviceId: 'device-b')), MergeChoice.takeRemote);
      expect(reconcile(at('10', deviceId: 'device-b'),
          at('10', deviceId: 'device-a')), MergeChoice.keepLocal);
    });

    test('and the two devices agree about which of them won', () {
      // The same pair of records, seen from each side. If both sides said
      // "take the remote" the row would ping-pong for ever; if both said
      // "keep mine" they would stay permanently different.
      final a = at('10', deviceId: 'device-a', fields: {'notes': 'from a'});
      final b = at('10', deviceId: 'device-b', fields: {'notes': 'from b'});

      final onDeviceA = reconcile(a, b) == MergeChoice.takeRemote ? b : a;
      final onDeviceB = reconcile(b, a) == MergeChoice.takeRemote ? a : b;

      expect(onDeviceA, onDeviceB);
    });
  });

  test('the same row twice is left alone rather than rewritten', () {
    // Our own push comes back on the next pull, because the server stamped
    // it after our cursor. Writing it again would be harmless and pointless;
    // saying so here is what lets the engine skip the write.
    expect(reconcile(at('10'), at('10')), MergeChoice.keepLocal);
  });

  test('comparing two different rows is a programming error, not a merge', () {
    final mine = at('10');
    final other = SyncRecord(
      table: 'sessions',
      id: 's2',
      updatedAt: DateTime.utc(2026, 11, 5, 11),
      deviceId: 'device-b',
    );

    expect(() => reconcile(mine, other), throwsArgumentError);
    expect(
      () => reconcile(
        mine,
        SyncRecord(
          table: 'set_logs',
          id: 's1',
          updatedAt: DateTime.utc(2026, 11, 5, 11),
          deviceId: 'device-b',
        ),
      ),
      throwsArgumentError,
    );
  });
}
