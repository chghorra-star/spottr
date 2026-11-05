import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:sync_engine/sync_engine.dart';

/// Who is asking, as far as the remote is concerned.
@immutable
class SupabaseCredentials {
  const SupabaseCredentials({required this.accessToken, required this.userId});

  /// A JWT that has not expired. Refreshing it belongs to whoever supplies
  /// these, not here: a store that could sign in would be a store that had
  /// to be told the password.
  final String accessToken;

  /// The account every row is stamped with.
  final String userId;
}

/// Where the current credentials come from, asked for on every request
/// rather than held, so a token refreshed between two pages is used.
typedef SupabaseCredentialsSource = Future<SupabaseCredentials?> Function();

/// The remote half of the sync, over PostgREST.
///
/// No Supabase SDK. The whole protocol is JSON over HTTPS, and a plain
/// `http.Client` buys three things: every request is testable on its own, the
/// iOS build gains no pod that a Windows machine cannot compile, and there
/// is no second opinion about what a conflict or a cursor means.
///
/// What is not here is retrying. A failed sync is reported, the next one
/// resumes from the cursor, and the engine's job is to make that cheap —
/// a store that retried internally would hide how often it has to.
class SupabaseRemoteStore implements SyncRemoteStore {
  SupabaseRemoteStore({
    required Uri projectUrl,
    required this.anonKey,
    required this.credentials,
    http.Client? client,
  })  : _rest = projectUrl.replace(path: '/rest/v1'),
        _client = client ?? http.Client();

  /// The project's public key. Not a secret: it identifies the project, and
  /// row level security is what protects the data.
  final String anonKey;

  /// Asked on every request rather than held, so a token refreshed between
  /// two pages is the one the second page uses.
  final SupabaseCredentialsSource credentials;

  final Uri _rest;
  final http.Client _client;

  @override
  Future<RemotePage> changesSince(
    String table, {
    String? cursor,
    required int limit,
  }) async {
    final credentials = await _require();

    // One row more than the page, which is how "is there more" gets answered
    // without a second round trip and without `count=exact`, which Postgres
    // pays for by scanning the whole table.
    final url = _rest.replace(
      path: '${_rest.path}/$table',
      queryParameters: {
        'select': '*',
        'order': 'synced_seq.asc',
        'limit': '${limit + 1}',
        // Absent on a first sync rather than `gt.0`. The cursor's shape
        // belongs to the server; this side never invents a value for it.
        if (cursor != null) 'synced_seq': 'gt.$cursor',
      },
    );

    final response = await _send(
      () => _client.get(url, headers: _headers(credentials)),
    );
    final rows = _rowsOf(response, table);

    if (rows.isEmpty) return const RemotePage.empty();

    final hasMore = rows.length > limit;
    final page = hasMore ? rows.sublist(0, limit) : rows;

    return RemotePage(
      records: [for (final row in page) _toRecord(table, row)],
      // The last row handed over, never the one that was only peeked at: a
      // cursor past a record the engine has not applied loses that record.
      cursor: '${page.last['synced_seq']}',
      hasMore: hasMore,
    );
  }

  @override
  Future<void> upsert(String table, List<SyncRecord> records) async {
    final credentials = await _require();

    // The primary key is (user_id, id), so the conflict target has to be
    // both. Naming only id makes PostgREST insert instead of update, which
    // then fails the primary key and rejects the whole batch.
    final url = _rest.replace(
      path: '${_rest.path}/$table',
      queryParameters: {'on_conflict': 'user_id,id'},
    );

    final body = [
      for (final record in records) _toJson(record, credentials.userId),
    ];

    await _send(
      () => _client.post(
        url,
        headers: {
          ..._headers(credentials),
          'content-type': 'application/json',
          // return=minimal because the rows are already here. Returning them
          // would double the traffic of every push, and the next pull brings
          // them anyway.
          'prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Map<String, String> _headers(SupabaseCredentials credentials) {
    return {
      // Both, always. PostgREST needs the anon key to route the request to
      // the project at all, and the account's token to decide what it may
      // see. One without the other is a 401 or everybody's data.
      'apikey': anonKey,
      'authorization': 'Bearer ${credentials.accessToken}',
      'accept': 'application/json',
    };
  }

  Future<SupabaseCredentials> _require() async {
    final current = await credentials();
    if (current == null) {
      // Before the request rather than after a 401, because there is nothing
      // to ask with and the answer to the user is the same either way.
      throw const SyncUnauthorized('nobody is signed in on this device');
    }
    return current;
  }

  /// Runs a request and turns every way it can go wrong into one of the
  /// three failures the protocol has a name for.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } on SocketException catch (error) {
      throw SyncOffline(error.message);
    } on http.ClientException catch (error) {
      // A connection that dropped part way through. Indistinguishable from
      // no network as far as what to do about it.
      throw SyncOffline(error.message);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final detail = _detail(response);
    return switch (response.statusCode) {
      // 401 is an expired or missing token; 403 is row level security
      // refusing this account. Neither is worth retrying and both are
      // answered by signing in, so they are reported the same way.
      401 || 403 => throw SyncUnauthorized(detail),
      // Not this app being wrong, and the next sync may well work. Reported
      // as offline so it lands on the retry path instead of in front of the
      // user as a rejected row.
      >= 500 => throw SyncOffline('the server answered $detail'),
      _ => throw SyncRejected(detail),
    };
  }

  String _detail(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String) return message;
      }
    } on FormatException {
      // Not JSON. The body itself is the best thing to say.
    }
    return response.body.isEmpty
        ? 'HTTP ${response.statusCode}'
        : response.body;
  }

  List<Map<String, Object?>> _rowsOf(http.Response response, String table) {
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      // The protocol has no name for this, so it is left loud: "sync failed,
      // try again" would hide a changed API behind a retry button for ever.
      throw StateError(
        'asked $table for rows and got ${decoded.runtimeType}: '
        '${response.body}',
      );
    }
    return [for (final row in decoded) row as Map<String, Object?>];
  }

  SyncRecord _toRecord(String table, Map<String, Object?> row) {
    final fields = {...row}
      ..remove('id')
      ..remove('updated_at')
      ..remove('deleted_at')
      ..remove('device_id')
      // The server's own columns. The app has no place for either, and
      // applying them would be rejected as version skew.
      ..remove('user_id')
      ..remove('synced_seq');

    return SyncRecord(
      table: table,
      id: row['id']! as String,
      // Postgres hands these back with a `+00:00` offset where the app
      // writes `Z`. Parsed to an instant, which is what the conflict rule
      // compares; the payload's own timestamps are left as the server
      // spelled them, since nothing but SQLite reads those and it parses.
      updatedAt: DateTime.parse(row['updated_at']! as String),
      deletedAt: switch (row['deleted_at']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      deviceId: row['device_id']! as String,
      fields: fields,
    );
  }

  Map<String, Object?> _toJson(SyncRecord record, String userId) {
    return {
      // Sent explicitly rather than left to the column's `auth.uid()`
      // default: without it in the body the upsert cannot find the row it
      // conflicts with. Row level security still refuses anything but this
      // account, so this is a convenience and not a trust.
      'user_id': userId,
      'id': record.id,
      'updated_at': record.updatedAt.toIso8601String(),
      'deleted_at': record.deletedAt?.toIso8601String(),
      'device_id': record.deviceId,
      ...record.fields,
    };
  }
}
