import 'package:drift/drift.dart';
import 'package:sync_engine/sync_engine.dart';

import '../local/database.dart';

/// The local half of the sync, over the app's own Drift database.
///
/// Generic over the table name: the column list, the types and the primary
/// key all come out of drift's own metadata, so adding an eighth syncable
/// table is one entry in [spottrSyncTables] and no new code here. What that
/// costs is a type mapping written by hand, which is the part worth reading
/// — SQLite has no boolean and may hold a timestamp either way, and both of
/// those cross the wire into a Postgres column that cares.
class DriftSyncStore implements SyncLocalStore {
  DriftSyncStore(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Local bookkeeping, not a column of the shared row. Never sent.
  static const String _pushedAt = 'pushed_at';

  @override
  Future<List<SyncRecord>> pendingUpload(String table) async {
    final info = _info(table);

    // The dirty rule, in one place: written here and not acknowledged at the
    // timestamp it currently carries. Comparing the two columns rather than
    // a column against a watermark is what makes it immune to the clock.
    final rows = await _db.customSelect(
      'SELECT * FROM "$table" '
      'WHERE $_pushedAt IS NULL OR $_pushedAt < updated_at '
      'ORDER BY updated_at',
      readsFrom: {info},
    ).get();

    return [for (final row in rows) _toRecord(table, info, row.data)];
  }

  @override
  Future<void> applyRemote(SyncRecord record) async {
    final info = _info(record.table);
    final payload = _payloadColumns(info);
    _rejectSkew(record, payload);

    final values = <String, Variable<Object>>{
      'id': Variable<String>(record.id),
      'updated_at': Variable<DateTime>(record.updatedAt),
      'deleted_at': Variable<DateTime>(record.deletedAt),
      'device_id': Variable<String>(record.deviceId),
      // Clean, at the timestamp that came down. This is the one line that
      // stops the row being pushed straight back, losing the same conflict
      // again, and keeping two devices talking for ever.
      _pushedAt: Variable<DateTime>(record.updatedAt),
    };
    for (final column in payload) {
      values[column.name] = _toSql(column, record.fields[column.name]);
    }

    final names = info.$columns.map((c) => '"${c.name}"').join(', ');
    final placeholders = List.filled(info.$columns.length, '?').join(', ');
    final assignments = info.$columns
        .where((c) => c.name != 'id')
        .map((c) => '"${c.name}" = excluded."${c.name}"')
        .join(', ');

    // ON CONFLICT DO UPDATE, not INSERT OR REPLACE. REPLACE deletes the
    // conflicting row before inserting the new one, so with foreign keys
    // enforced it either takes the row's children with it or fails outright
    // — over an edit to a plan somebody is in the middle of training.
    //
    // Every column is assigned, including the ones the record left null. A
    // partial upsert leaves stale values behind, and a weight the user
    // cleared on one device would come back from the other.
    await _db.customInsert(
      'INSERT INTO "${record.table}" ($names) VALUES ($placeholders) '
      'ON CONFLICT("id") DO UPDATE SET $assignments',
      variables: [for (final column in info.$columns) values[column.name]!],
      // Without this the write is invisible to every watch() in the app, and
      // the plan screen goes on showing the plan from before the sync until
      // something else happens to touch the table.
      updates: {info},
    );
  }

  @override
  Future<void> markPushed(String table, List<SyncRecord> records) async {
    final info = _info(table);

    await _db.transaction(() async {
      for (final record in records) {
        // The timestamp that was sent, not the one in the row now. The
        // upload is an await and the user can log a set during it; marking
        // clean at the current value would acknowledge an edit the server
        // never saw, and nothing would offer it again.
        await _db.customUpdate(
          'UPDATE "$table" SET $_pushedAt = ? WHERE id = ?',
          variables: [
            Variable<DateTime>(record.updatedAt),
            Variable<String>(record.id),
          ],
          updates: {info},
        );
      }
    });
  }

  @override
  Future<String?> cursor(String table) async {
    final row = await (_db.select(_db.syncState)
          ..where((row) => row.targetTable.equals(table)))
        .getSingleOrNull();
    return row?.cursor;
  }

  @override
  Future<void> setCursor(String table, String cursor) async {
    await _db.into(_db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(
            targetTable: table,
            cursor: Value(cursor),
            syncedAt: Value(_now()),
          ),
        );
  }

  TableInfo<Table, dynamic> _info(String table) {
    return _db.allTables.firstWhere(
      (candidate) => candidate.actualTableName == table,
      orElse: () =>
          throw StateError('$table is not a table in this database'),
    );
  }

  List<GeneratedColumn<Object>> _payloadColumns(
    TableInfo<Table, dynamic> info,
  ) {
    return [
      for (final column in info.$columns)
        if (!envelopeColumns.contains(column.name) && column.name != _pushedAt)
          column,
    ];
  }

  /// A record whose payload does not match this table's columns came from a
  /// different version of the app.
  ///
  /// Both directions are errors. An unknown column dropped silently writes a
  /// row that is not the row the server holds and then pushes it back as
  /// though it were; a missing one would be written as null, which for a
  /// column somebody added means losing it on every device still running
  /// this build.
  void _rejectSkew(SyncRecord record, List<GeneratedColumn<Object>> payload) {
    final expected = {for (final column in payload) column.name};
    final actual = record.fields.keys.toSet();

    final unknown = actual.difference(expected);
    final missing = expected.difference(actual);
    if (unknown.isEmpty && missing.isEmpty) return;

    throw StateError(
      'the row ${record.table}/${record.id} does not match this app: '
      '${unknown.isEmpty ? '' : 'unknown ${unknown.join(', ')}; '}'
      '${missing.isEmpty ? '' : 'missing ${missing.join(', ')}; '}'
      'the app that wrote it is a different version',
    );
  }

  /// A SQL value from a wire value.
  Variable<Object> _toSql(GeneratedColumn<Object> column, Object? wire) {
    return switch (column.type) {
      DriftSqlType.bool => Variable<bool>(wire as bool?),
      DriftSqlType.int => Variable<int>((wire as num?)?.toInt()),
      DriftSqlType.bigInt =>
        Variable<BigInt>(wire == null ? null : BigInt.from((wire as num).toInt())),
      DriftSqlType.double => Variable<double>((wire as num?)?.toDouble()),
      DriftSqlType.string => Variable<String>(wire as String?),
      DriftSqlType.dateTime => Variable<DateTime>(_readTimestamp(wire)),
      DriftSqlType.blob => throw StateError(
          'a blob column (${column.name}) cannot cross the wire',
        ),
      DriftSqlType.any => throw StateError(
          'an untyped column (${column.name}) cannot cross the wire',
        ),
      // A wildcard because drift's column types are not just an enum:
      // custom and dialect-aware types sit beside it, so exhaustiveness is
      // not available. Everything this app declares is one of the cases
      // above, and anything else fails here by name rather than crossing as
      // whatever its toString happens to be.
      _ => throw StateError(
          'column ${column.name} has type ${column.type}, which this store '
          'does not know how to put on the wire',
        ),
    };
  }

  /// A wire value from whatever SQLite handed back.
  Object? _toWire(GeneratedColumn<Object> column, Object? raw) {
    if (raw == null) return null;

    return switch (column.type) {
      // SQLite has no boolean, so this arrives as 0 or 1 — and PostgREST
      // refuses `{"is_active": 1}` for a boolean column, with nothing in the
      // app to say which row it threw away.
      DriftSqlType.bool => raw == true || raw == 1,
      DriftSqlType.int => (raw as num).toInt(),
      DriftSqlType.bigInt => (raw as num).toInt(),
      DriftSqlType.double => (raw as num).toDouble(),
      DriftSqlType.string => raw as String,
      // Always ISO-8601, whichever way this database stores timestamps. A
      // unix integer in a timestamptz column is the year 1970.
      DriftSqlType.dateTime => _readTimestamp(raw)!.toIso8601String(),
      DriftSqlType.blob => throw StateError(
          'a blob column (${column.name}) cannot cross the wire',
        ),
      DriftSqlType.any => throw StateError(
          'an untyped column (${column.name}) cannot cross the wire',
        ),
      // A wildcard because drift's column types are not just an enum:
      // custom and dialect-aware types sit beside it, so exhaustiveness is
      // not available. Everything this app declares is one of the cases
      // above, and anything else fails here by name rather than crossing as
      // whatever its toString happens to be.
      _ => throw StateError(
          'column ${column.name} has type ${column.type}, which this store '
          'does not know how to put on the wire',
        ),
    };
  }

  SyncRecord _toRecord(
    String table,
    TableInfo<Table, dynamic> info,
    Map<String, Object?> data,
  ) {
    return SyncRecord(
      table: table,
      id: data['id']! as String,
      updatedAt: _readTimestamp(data['updated_at'])!,
      deletedAt: _readTimestamp(data['deleted_at']),
      deviceId: data['device_id']! as String,
      fields: {
        for (final column in _payloadColumns(info))
          column.name: _toWire(column, data[column.name]),
      },
    );
  }

  /// Reads a timestamp and normalizes it to UTC.
  ///
  /// Text only, deliberately. These columns are declared TEXT, so SQLite's
  /// type affinity converts anything written into them — a unix integer from
  /// some older build included — into text on the way in, and text is the
  /// only thing that can come back. Handling an integer here would be a
  /// branch nothing can reach, guessing at seconds against milliseconds.
  ///
  /// The zone is normalized rather than trusted: the wire format is UTC
  /// whatever the column happens to hold, so two devices in two time zones
  /// compare the same instant.
  DateTime? _readTimestamp(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.parse(raw).toUtc();
    throw StateError(
      'a timestamp came back from SQLite as ${raw.runtimeType}: $raw',
    );
  }
}
