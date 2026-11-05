import 'reconcile.dart';
import 'stores.dart';
import 'sync_record.dart';
import 'sync_report.dart';

/// Two-way replication of a fixed list of tables, last writer wins.
///
/// One table at a time, in the order given, pulling before pushing.
///
/// **Pull first.** A conflict is then decided here, against the newest
/// remote state, before anything is sent — rather than being decided by
/// whichever request happened to arrive at the server last.
///
/// **Stop at the first failure.** The table order is parents before
/// children, so carrying on past a table that did not finish sends rows
/// referencing a parent the server was never given. A half-finished sync is
/// resumable; a sync that scattered children across a server that cannot
/// hold them is not.
class SyncEngine {
  SyncEngine({
    required this.local,
    required this.remote,
    required List<String> tables,
    this.pageSize = 200,
    this.uploadBatchSize = 200,
  }) : _tables = List.unmodifiable(tables) {
    if (pageSize < 1 || uploadBatchSize < 1) {
      throw ArgumentError('a page of zero rows never finishes a sync');
    }
  }

  final SyncLocalStore local;
  final SyncRemoteStore remote;
  final List<String> _tables;

  /// How many rows to pull at once. The cursor advances per page, so this is
  /// also how much work an interrupted sync repeats.
  final int pageSize;

  final int uploadBatchSize;

  Future<SyncReport> sync() async {
    final reports = <TableSyncReport>[];

    for (final table in _tables) {
      final progress = _TableProgress(table);
      try {
        await _syncTable(table, progress);
        reports.add(progress.toReport());
      } on SyncException catch (error) {
        // The table that stopped is reported with what it managed, because
        // "stopped on set_logs having pulled forty of them" is a different
        // situation from "never reached set_logs".
        reports.add(progress.toReport());
        return SyncReport(
          tables: reports,
          error: SyncError(
            kind: switch (error) {
              SyncOffline() => SyncErrorKind.offline,
              SyncUnauthorized() => SyncErrorKind.unauthorized,
              SyncRejected() => SyncErrorKind.rejected,
            },
            table: table,
            message: error.message,
          ),
        );
      }
    }

    return SyncReport(tables: reports);
  }

  Future<void> _syncTable(String table, _TableProgress progress) async {
    // Read the unsent edits once, before the pull. Everything else in local
    // storage is the server's own last answer, so an incoming row only has
    // to be reconciled when its id is in here.
    final pending = {
      for (final record in await local.pendingUpload(table)) record.id: record,
    };

    var cursor = await local.cursor(table);
    var hasMore = true;
    while (hasMore) {
      final page =
          await remote.changesSince(table, cursor: cursor, limit: pageSize);

      for (final incoming in page.records) {
        progress.pulled++;
        final mine = pending[incoming.id];

        if (mine == null) {
          await local.applyRemote(incoming);
          progress.applied++;
          continue;
        }

        progress.conflicts++;
        if (reconcile(mine, incoming) == MergeChoice.takeRemote) {
          // Applying marks the row clean, which is what stops the losing
          // edit being pushed, losing again, and going round for ever.
          await local.applyRemote(incoming);
          progress.applied++;
          progress.lost++;
          pending.remove(incoming.id);
        }
      }

      // Per page, not per sync: an interruption then costs one page rather
      // than everything pulled so far. An empty page carries no cursor, so
      // "nothing new" cannot move it past something that arrived in between.
      if (page.cursor != null) {
        cursor = page.cursor;
        await local.setCursor(table, page.cursor!);
      }
      hasMore = page.hasMore;
    }

    await _push(table, pending.values.toList(), progress);
  }

  Future<void> _push(
    String table,
    List<SyncRecord> records,
    _TableProgress progress,
  ) async {
    for (var start = 0; start < records.length; start += uploadBatchSize) {
      final end = (start + uploadBatchSize).clamp(0, records.length);
      final batch = records.sublist(start, end);

      await remote.upsert(table, batch);
      // Only after the server has taken them. Marking first would lose the
      // batch on a dropped connection: clean rows are never offered again.
      await local.markPushed(table, batch);
      progress.pushed += batch.length;
    }
  }
}

class _TableProgress {
  _TableProgress(this.table);

  final String table;
  int pulled = 0;
  int applied = 0;
  int pushed = 0;
  int conflicts = 0;
  int lost = 0;

  TableSyncReport toReport() => TableSyncReport(
        table: table,
        pulled: pulled,
        applied: applied,
        pushed: pushed,
        conflicts: conflicts,
        conflictsLostLocally: lost,
      );
}
