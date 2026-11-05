import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// The columns the protocol reads rather than carries.
///
/// They live beside the payload in storage and on the wire, but they are
/// hoisted out of [SyncRecord.fields] because the engine and the conflict
/// rule are written in terms of them. A copy left in the payload would be
/// written back over the hoisted one by whichever applier iterated the map
/// last, which is a bug with no symptom until two devices disagree.
const Set<String> envelopeColumns = {
  'id',
  'updated_at',
  'deleted_at',
  'device_id',
};

/// One row of one syncable table, as it crosses between two devices.
///
/// [updatedAt] is the **author's** clock, not the server's: it is what the
/// conflict rule compares, so it has to travel unchanged from the device
/// that made the edit. The server's own replication stamp is a separate
/// thing and never reaches here — it is the opaque cursor in [RemotePage].
@immutable
class SyncRecord {
  SyncRecord({
    required this.table,
    required this.id,
    required DateTime updatedAt,
    required this.deviceId,
    DateTime? deletedAt,
    this.fields = const {},
  })  : updatedAt = updatedAt.toUtc(),
        deletedAt = deletedAt?.toUtc() {
    if (table.isEmpty) {
      throw ArgumentError.value(table, 'table', 'must name a table');
    }
    if (id.isEmpty) {
      // An id is how two devices agree they are talking about the same row.
      // Upserting a blank one merges every blank-id row into a single row.
      throw ArgumentError.value(id, 'id', 'must identify a row');
    }
    if (deviceId.isEmpty) {
      // The tie-break has to mean the same thing on both sides, or the order
      // two devices resolve a conflict in depends on which one is asking.
      throw ArgumentError.value(deviceId, 'deviceId', 'must identify a device');
    }
    final reserved = fields.keys.where(envelopeColumns.contains).toList();
    if (reserved.isNotEmpty) {
      throw ArgumentError.value(
        reserved,
        'fields',
        'belong to the envelope, not to the payload',
      );
    }
  }

  final String table;
  final String id;

  /// When the device that made this edit says it made it. The key the
  /// conflict rule sorts on, always UTC.
  final DateTime updatedAt;

  /// Set when the row has been deleted. Deletes are soft: a hard delete is
  /// invisible to a peer, which would resurrect the row on the next sync.
  final DateTime? deletedAt;

  /// Which install wrote this revision. The tie-break for two edits that
  /// claim the same instant.
  final String deviceId;

  /// Everything else, JSON-ready: the columns the protocol does not read.
  final Map<String, Object?> fields;

  bool get isDeleted => deletedAt != null;

  static const DeepCollectionEquality _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return other is SyncRecord &&
        other.table == table &&
        other.id == id &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt &&
        other.deviceId == deviceId &&
        _deep.equals(other.fields, fields);
  }

  @override
  int get hashCode => Object.hash(
        table,
        id,
        updatedAt,
        deletedAt,
        deviceId,
        _deep.hash(fields),
      );

  @override
  String toString() {
    final state = isDeleted ? 'deleted' : 'live';
    return 'SyncRecord($table/$id @ ${updatedAt.toIso8601String()} '
        'by $deviceId, $state)';
  }
}
