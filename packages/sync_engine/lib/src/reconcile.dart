import 'sync_record.dart';

/// Which copy of a row survives a conflict.
enum MergeChoice {
  /// Keep what this device has, and push it.
  keepLocal,

  /// Overwrite what this device has with the server's copy.
  takeRemote,
}

/// Last writer wins, over a **total order** on (updatedAt, deviceId).
///
/// The order is total on purpose. Two devices resolve the same conflict
/// without being able to ask each other, so the rule has to be a function of
/// the two records alone — "the newest, and otherwise the remote one" is not,
/// because each side's remote is the other side's local. Both sides would
/// take the other's copy and trade the row for ever.
///
/// What this cannot do is merge. The loser's edit is discarded whole, so two
/// people editing different fields of the same profile minute apart lose one
/// of the two changes. Spottr's rows are owned by one person on a handful of
/// their own devices and are almost always written in one place at a time,
/// which is the case last-writer-wins is for; a plan is immutable revisions
/// anyway, so the rows that change in place are few.
///
/// It also trusts the clock. A device whose clock is an hour behind loses
/// every conflict it takes part in, silently. That is the known cost of
/// timestamps over a logical clock, and the reason the report counts
/// conflicts rather than resolving them quietly.
MergeChoice reconcile(SyncRecord local, SyncRecord remote) {
  if (local.table != remote.table || local.id != remote.id) {
    throw ArgumentError(
      'reconcile compares two copies of one row, not '
      '${local.table}/${local.id} against ${remote.table}/${remote.id}',
    );
  }

  final byTime = remote.updatedAt.compareTo(local.updatedAt);
  if (byTime != 0) {
    return byTime > 0 ? MergeChoice.takeRemote : MergeChoice.keepLocal;
  }

  // The same instant, so the device id decides. Identical ids mean this is
  // our own row coming back to us, and keeping it skips a pointless write.
  return remote.deviceId.compareTo(local.deviceId) > 0
      ? MergeChoice.takeRemote
      : MergeChoice.keepLocal;
}
