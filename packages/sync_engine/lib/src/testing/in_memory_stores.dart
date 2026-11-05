import '../stores.dart';
import '../sync_record.dart';

/// A [SyncLocalStore] in a map, with the same pending rule the Drift store
/// implements: a row is pending until it has been acknowledged at its
/// current `updated_at`.
///
/// This ships in `lib/` rather than living in `test/` because the app's
/// widget tests need a sync that works with no database and no network, and
/// because the engine's own tests are only worth anything if the thing they
/// run against behaves like the real store. The two rules that matter —
/// `applyRemote` marks a row clean, `markPushed` uses the row's own
/// timestamp — are asserted of this class directly.
class InMemoryLocalStore implements SyncLocalStore {
  final Map<String, Map<String, _Stored>> _tables = {};
  final Map<String, String> _cursors = {};

  /// How many rows have been written in from the remote. For asserting that
  /// an unchanged sync writes nothing at all.
  int applyCount = 0;

  /// Put a row in as though it had been written here, or pulled.
  void seed(SyncRecord record, {bool pending = true}) {
    _rows(record.table)[record.id] = _Stored(
      record,
      pushedAt: pending ? null : record.updatedAt,
    );
  }

  /// Every row id in the table, tombstones included, in insertion order.
  List<String> ids(String table) => _rows(table).keys.toList();

  SyncRecord? row(String table, String id) => _rows(table)[id]?.record;

  void resetCounts() => applyCount = 0;

  @override
  Future<List<SyncRecord>> pendingUpload(String table) async {
    return [
      for (final stored in _rows(table).values)
        if (stored.isPending) stored.record,
    ];
  }

  @override
  Future<void> applyRemote(SyncRecord record) async {
    applyCount++;
    _rows(record.table)[record.id] =
        _Stored(record, pushedAt: record.updatedAt);
  }

  @override
  Future<void> markPushed(String table, List<SyncRecord> records) async {
    for (final pushed in records) {
      final stored = _rows(table)[pushed.id];
      if (stored == null) continue;
      // The timestamp that was uploaded, not the one in storage now: an edit
      // made during the upload has a later one and has to stay pending.
      _rows(table)[pushed.id] =
          _Stored(stored.record, pushedAt: pushed.updatedAt);
    }
  }

  @override
  Future<String?> cursor(String table) async => _cursors[table];

  @override
  Future<void> setCursor(String table, String cursor) async {
    _cursors[table] = cursor;
  }

  Map<String, _Stored> _rows(String table) =>
      _tables.putIfAbsent(table, () => {});
}

class _Stored {
  _Stored(this.record, {this.pushedAt});

  final SyncRecord record;
  final DateTime? pushedAt;

  bool get isPending =>
      pushedAt == null || pushedAt!.isBefore(record.updatedAt);
}

/// A [SyncRemoteStore] in a map, stamping every write with a monotonic
/// sequence so that the cursor behaves the way a server's does.
///
/// The stamp is deliberately not the record's `updatedAt`. A row written by
/// a device whose clock is behind still has to reach every peer, and keeping
/// the two apart here is what lets the engine's tests say so.
class InMemoryRemoteStore implements SyncRemoteStore {
  final Map<String, Map<String, _Stamped>> _tables = {};
  final Map<String, int> _pageCalls = {};

  int _sequence = 0;
  Object? _upsertError;
  final Map<String, _PageFailure> _pageFailures = {};

  /// Upsert requests received, batches included.
  int upsertCount = 0;

  /// The distinct tables upserted, in the order they were first written.
  final List<String> upsertedTables = [];

  void seed(SyncRecord record) {
    _rows(record.table)[record.id] = _Stamped(record, ++_sequence);
  }

  List<String> ids(String table) => _rows(table).keys.toList();

  SyncRecord? row(String table, String id) => _rows(table)[id]?.record;

  /// Make the [page]th call to [changesSince] **for that table** fail, once.
  ///
  /// Per table rather than overall, because the engine walks several tables
  /// per sync and a test about the second page of one of them should not
  /// have to count the empty pulls in front of it. Once rather than for ever,
  /// because the test that matters is what the *next* sync recovers.
  void failOnPage(int page, Object error, {String? table}) {
    _pageFailures[table ?? _anyTable] = _PageFailure(page, error);
  }

  void failOnUpsert(Object error) => _upsertError = error;

  void resetCounts() {
    upsertCount = 0;
    upsertedTables.clear();
  }

  @override
  Future<RemotePage> changesSince(
    String table, {
    String? cursor,
    required int limit,
  }) async {
    final call = (_pageCalls[table] ?? 0) + 1;
    _pageCalls[table] = call;

    final key = _pageFailures.containsKey(table) ? table : _anyTable;
    final failure = _pageFailures[key];
    if (failure != null && failure.page == call) {
      _pageFailures.remove(key);
      throw failure.error;
    }

    final after = cursor == null ? 0 : int.parse(cursor);
    final matching = _rows(table).values.where((s) => s.stamp > after).toList()
      ..sort((a, b) => a.stamp.compareTo(b.stamp));

    if (matching.isEmpty) return const RemotePage.empty();

    final page = matching.take(limit).toList();
    return RemotePage(
      records: [for (final stamped in page) stamped.record],
      cursor: page.last.stamp.toString(),
      hasMore: matching.length > page.length,
    );
  }

  @override
  Future<void> upsert(String table, List<SyncRecord> records) async {
    final error = _upsertError;
    if (error != null) throw error;

    upsertCount++;
    if (!upsertedTables.contains(table)) upsertedTables.add(table);
    for (final record in records) {
      _rows(table)[record.id] = _Stamped(record, ++_sequence);
    }
  }

  Map<String, _Stamped> _rows(String table) =>
      _tables.putIfAbsent(table, () => {});

  static const String _anyTable = '*';
}

class _Stamped {
  _Stamped(this.record, this.stamp);

  final SyncRecord record;
  final int stamp;
}

class _PageFailure {
  _PageFailure(this.page, this.error);

  final int page;
  final Object error;
}
