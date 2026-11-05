import 'package:meta/meta.dart';

/// What stopped a sync.
enum SyncErrorKind {
  /// No usable connection. Try again later; nothing is wrong.
  offline,

  /// No valid session. Nothing will work until somebody signs in.
  unauthorized,

  /// The server understood and refused.
  rejected,
}

@immutable
class SyncError {
  const SyncError({
    required this.kind,
    required this.table,
    required this.message,
  });

  final SyncErrorKind kind;

  /// The table the sync stopped on. Everything before it in the order
  /// finished; everything after it was not attempted.
  final String table;

  final String message;

  @override
  String toString() => 'SyncError(${kind.name} on $table: $message)';
}

@immutable
class TableSyncReport {
  const TableSyncReport({
    required this.table,
    required this.pulled,
    required this.applied,
    required this.pushed,
    required this.conflicts,
    required this.conflictsLostLocally,
  });

  final String table;

  /// Rows the server handed over.
  final int pulled;

  /// Rows written into local storage. Fewer than [pulled] when this device
  /// held a later edit.
  final int applied;

  final int pushed;

  /// Pulled rows that collided with an unsent local edit. Counted rather
  /// than hidden: last-writer-wins discards the loser's work, and a user who
  /// cannot see that it happened cannot tell us about it.
  final int conflicts;

  /// Conflicts this device lost, which is the number of local edits thrown
  /// away.
  final int conflictsLostLocally;
}

@immutable
class SyncReport {
  const SyncReport({required this.tables, this.error});

  final List<TableSyncReport> tables;

  /// Null when every table finished.
  final SyncError? error;

  bool get complete => error == null;

  int get pulled => _total((t) => t.pulled);
  int get applied => _total((t) => t.applied);
  int get pushed => _total((t) => t.pushed);
  int get conflicts => _total((t) => t.conflicts);
  int get conflictsLostLocally => _total((t) => t.conflictsLostLocally);

  /// True when the sync finished and moved nothing, which is what a sync
  /// looks like almost every time it runs.
  bool get idle => complete && applied == 0 && pushed == 0;

  int _total(int Function(TableSyncReport) field) =>
      tables.fold(0, (sum, table) => sum + field(table));

  @override
  String toString() {
    final head = 'pulled $pulled, applied $applied, pushed $pushed, '
        'conflicts $conflicts ($conflictsLostLocally lost here)';
    return error == null ? 'SyncReport($head)' : 'SyncReport($head, $error)';
  }
}
