/// Two-way replication of local records against a remote store.
///
/// Pure Dart: no Flutter, no database, no HTTP. The protocol is here and the
/// two ends are interfaces, which is what lets every rule about conflicts,
/// cursors and interrupted syncs be tested in milliseconds with nothing
/// running.
library;

export 'src/engine.dart';
export 'src/reconcile.dart';
export 'src/stores.dart';
export 'src/sync_record.dart';
export 'src/sync_report.dart';
