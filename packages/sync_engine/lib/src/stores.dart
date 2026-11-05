import 'package:meta/meta.dart';

import 'sync_record.dart';

/// The device's own copy of the syncable tables.
///
/// There is deliberately **no `find`**. A row that is not pending is, by
/// construction, the last thing the server gave us — anything written here
/// since is pending — so a pulled row only has to be reconciled when the
/// same id is in [pendingUpload]. That is what turns "compare every incoming
/// row against local state" into one query per table, and it is why this
/// interface is five methods rather than a database.
abstract class SyncLocalStore {
  /// Rows written on this device and not yet acknowledged by the server.
  ///
  /// The implementation decides what pending means; in Spottr it is
  /// `pushed_at IS NULL OR pushed_at < updated_at`, so the only thing a
  /// local write has to remember is to bump `updated_at` — which it already
  /// has to do for the conflict rule.
  Future<List<SyncRecord>> pendingUpload(String table);

  /// Write the server's copy in, replacing whatever is here, and mark it
  /// **clean**.
  ///
  /// Clean is the load-bearing half. A row applied as pending would be
  /// pushed straight back, lose or win the same conflict again, and keep two
  /// devices talking about a row nobody is editing.
  Future<void> applyRemote(SyncRecord record);

  /// Mark these rows as acknowledged **at the `updated_at` that was sent**.
  ///
  /// The records rather than their ids, and their own timestamp rather than
  /// "now", because the user can write to the database during the `await` on
  /// the upload. Marking clean at the current `updated_at` would then
  /// acknowledge an edit the server never saw, and that edit would never be
  /// offered again.
  Future<void> markPushed(String table, List<SyncRecord> records);

  /// The opaque cursor this device last pulled up to, or null for never.
  Future<String?> cursor(String table);

  Future<void> setCursor(String table, String cursor);
}

/// The shared copy, behind whatever the remote happens to be.
abstract class SyncRemoteStore {
  /// Rows the server stamped after [cursor], oldest stamp first.
  ///
  /// The stamp is the server's replication order and is **not** the record's
  /// `updatedAt`: a row written by a device whose clock is behind still has
  /// to reach every peer. The engine never parses a cursor, so a server is
  /// free to express it as a timestamp, a sequence or a token.
  Future<RemotePage> changesSince(
    String table, {
    String? cursor,
    required int limit,
  });

  /// Insert or replace, by primary key.
  Future<void> upsert(String table, List<SyncRecord> records);
}

/// One page of remote changes.
@immutable
class RemotePage {
  const RemotePage({
    required this.records,
    required this.cursor,
    required this.hasMore,
  });

  const RemotePage.empty()
      : records = const [],
        cursor = null,
        hasMore = false;

  final List<SyncRecord> records;

  /// Where to resume from, or null when the page is empty.
  ///
  /// Null rather than the cursor that was passed in, because "nothing new"
  /// must not move the cursor — a server that returned an empty page and a
  /// stale cursor would skip whatever arrived in between.
  final String? cursor;

  final bool hasMore;
}

/// The failures the protocol has names for.
///
/// A store raises one of these three and the engine turns it into a
/// [SyncError] in the report. Anything else is version skew or a defect in
/// an adapter and is left to propagate: a bug reported as "sync failed, try
/// again" lives behind a retry button for ever.
sealed class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No usable connection. The normal state of a phone in a gym basement.
class SyncOffline extends SyncException {
  const SyncOffline(super.message);
}

/// There is no valid session. Retrying cannot help; signing in can.
class SyncUnauthorized extends SyncException {
  const SyncUnauthorized(super.message);
}

/// The server understood and refused — a constraint, a policy, a bad row.
class SyncRejected extends SyncException {
  const SyncRejected(super.message);
}
