import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

/// A record is the unit that crosses between two devices, so its identity
/// has to survive a round trip through storage and a wire format. Every
/// test here is about one of the three ways that identity could rot: a
/// timestamp that means something different on the other side, a row that
/// compares unequal to itself after storage, and a row with no id at all.
void main() {
  SyncRecord record({
    String id = 'p1',
    DateTime? updatedAt,
    DateTime? deletedAt,
    String deviceId = 'device-a',
    Map<String, Object?> fields = const {'goal': 'hybrid'},
  }) {
    return SyncRecord(
      table: 'profiles',
      id: id,
      updatedAt: updatedAt ?? DateTime.utc(2026, 11, 5, 10),
      deletedAt: deletedAt,
      deviceId: deviceId,
      fields: fields,
    );
  }

  group('timestamps', () {
    test('a local time is normalized to UTC', () {
      // DateTime equality includes the zone flag, so a record built from a
      // local time would never compare equal to the same record read back
      // out of storage. That is the bug the stored-timestamp work in M3
      // found, arriving here by a different door.
      final local = DateTime(2026, 11, 5, 10);
      final subject = record(updatedAt: local, deletedAt: local);

      expect(subject.updatedAt.isUtc, isTrue);
      expect(subject.updatedAt, local.toUtc());
      expect(subject.deletedAt!.isUtc, isTrue);
    });

    test('a record with no deletedAt is not deleted', () {
      expect(record().isDeleted, isFalse);
      expect(record(deletedAt: DateTime.utc(2026)).isDeleted, isTrue);
    });
  });

  group('identity', () {
    test('two records with the same contents are equal', () {
      expect(record(), record());
      expect(record().hashCode, record().hashCode);
    });

    test('fields are compared by value, not by reference', () {
      // The round trip builds a fresh map every time. A record that compared
      // maps by identity would report a conflict on every single row.
      expect(
        record(fields: {'goal': 'hybrid', 'days': 4}),
        record(fields: {'goal': 'hybrid', 'days': 4}),
      );
      expect(
        record(fields: {'goal': 'hybrid'}),
        isNot(record(fields: {'goal': 'muscleBuilding'})),
      );
    });

    test('a nested list in fields is compared by value too', () {
      // injuries and equipment are stored as JSON arrays, so the decoded
      // payload is nested by construction.
      expect(
        record(fields: {'injuries': ['knees']}),
        record(fields: {'injuries': ['knees']}),
      );
      expect(
        record(fields: {'injuries': ['knees']}),
        isNot(record(fields: {'injuries': ['knees', 'lowerBack']})),
      );
    });

    test('the timestamp is part of the identity', () {
      expect(
        record(updatedAt: DateTime.utc(2026, 11, 5, 10)),
        isNot(record(updatedAt: DateTime.utc(2026, 11, 5, 11))),
      );
    });
  });

  group('a row that cannot be replicated is rejected on construction', () {
    test('an empty id', () {
      // An id is how two devices agree they are talking about the same row.
      // A blank one from the wire is a corrupt row, and upserting it would
      // merge every blank-id row in the table into one.
      expect(() => record(id: ''), throwsArgumentError);
    });

    test('an empty table name', () {
      expect(
        () => SyncRecord(
          table: '',
          id: 'p1',
          updatedAt: DateTime.utc(2026),
          deviceId: 'device-a',
        ),
        throwsArgumentError,
      );
    });

    test('an empty device id', () {
      // The device id is the tie-break that makes two devices resolve the
      // same conflict the same way. Blank on one side and set on the other
      // would make the order depend on which device is asking.
      expect(() => record(deviceId: ''), throwsArgumentError);
    });

    test('a reserved column in the payload', () {
      // updated_at, deleted_at and device_id are hoisted out of the payload
      // because the protocol reads them. A copy left in fields would be
      // written back over the hoisted one by the applier, silently and in
      // whichever order the map happened to iterate.
      for (final column in ['updated_at', 'deleted_at', 'device_id', 'id']) {
        expect(
          () => record(fields: {column: 'x'}),
          throwsArgumentError,
          reason: '$column is part of the envelope, not of the payload',
        );
      }
    });
  });
}
