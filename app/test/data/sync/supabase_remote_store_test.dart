import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spottr/data/sync/supabase_remote_store.dart';
import 'package:sync_engine/sync_engine.dart';

/// The remote half, against a fake HTTP client rather than a project.
///
/// There is no Supabase SDK here. The whole protocol is PostgREST — JSON
/// over HTTPS — and a plain `http.Client` keeps it testable request by
/// request, keeps the iOS build free of another pod a Windows machine cannot
/// compile, and means the thing under test is the request that goes out
/// rather than somebody else's client.
///
/// What it cannot test is whether PostgREST agrees. Every URL and header in
/// here is a claim about an API this project has never called.
void main() {
  late List<http.Request> sent;

  /// A client that records what it was asked for and answers with [body].
  MockClient answering(
    Object? body, {
    int status = 200,
    Map<String, String> headers = const {},
  }) {
    return MockClient((request) async {
      sent.add(request);
      return http.Response(
        body is String ? body : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json', ...headers},
      );
    });
  }

  SupabaseRemoteStore store(
    http.Client client, {
    String? token = 'jwt-token',
    String userId = 'user-1',
  }) {
    return SupabaseRemoteStore(
      projectUrl: Uri.parse('https://project.supabase.co'),
      anonKey: 'anon-key',
      credentials: () async => token == null
          ? null
          : SupabaseCredentials(accessToken: token, userId: userId),
      client: client,
    );
  }

  Map<String, Object?> remoteRow({
    String id = 's1',
    int seq = 11,
    String updatedAt = '2026-11-05T10:00:00+00:00',
    String? deletedAt,
    String deviceId = 'other-phone',
  }) {
    return {
      'user_id': 'user-1',
      'id': id,
      'synced_seq': seq,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'device_id': deviceId,
      'started_at': '2026-11-05T09:00:00+00:00',
      'pain_reported': false,
      'notes': null,
    };
  }

  SyncRecord record({String id = 's1', int hour = 10}) {
    return SyncRecord(
      table: 'sessions',
      id: id,
      updatedAt: DateTime.utc(2026, 11, 5, hour),
      deviceId: 'this-phone',
      fields: {'pain_reported': true, 'notes': 'felt strong'},
    );
  }

  setUp(() => sent = []);

  group('asking for what is new', () {
    test('asks for this table in replication order, after the cursor',
        () async {
      final client = answering([remoteRow()]);

      await store(client).changesSince('sessions', cursor: '7', limit: 2);

      final url = sent.single.url;
      expect(url.path, '/rest/v1/sessions');
      expect(url.queryParameters['select'], '*');
      expect(url.queryParameters['order'], 'synced_seq.asc');
      expect(url.queryParameters['synced_seq'], 'gt.7');
    });

    test('a first sync asks with no cursor at all', () async {
      // Not `gt.0`: the cursor is opaque to the engine and the server owns
      // its shape, so "never pulled" is the absence of a filter rather than
      // a value this side invented.
      final client = answering(<Object?>[]);

      await store(client).changesSince('sessions', limit: 2);

      expect(sent.single.url.queryParameters.containsKey('synced_seq'), isFalse);
    });

    test('sends both the project key and the account token', () async {
      // PostgREST wants the anon key as `apikey` to route the request at
      // all, and the user's JWT as the bearer to decide what they can see.
      // One without the other is either a 401 or everybody's data.
      final client = answering(<Object?>[]);

      await store(client).changesSince('sessions', limit: 2);

      expect(sent.single.headers['apikey'], 'anon-key');
      expect(sent.single.headers['authorization'], 'Bearer jwt-token');
    });

    test('asks for one row more than the page, and does not pass it on',
        () async {
      // How "is there more" is answered without a second round trip or an
      // exact count, which Postgres pays for by scanning.
      final client = answering([
        remoteRow(id: 's1', seq: 11),
        remoteRow(id: 's2', seq: 12),
        remoteRow(id: 's3', seq: 13),
      ]);

      final page = await store(client).changesSince('sessions', limit: 2);

      expect(sent.single.url.queryParameters['limit'], '3');
      expect(page.records.map((r) => r.id), ['s1', 's2']);
      expect(page.hasMore, isTrue);
      expect(
        page.cursor,
        '12',
        reason: 'the cursor is the last row handed over, not the one peeked',
      );
    });

    test('a short page is the last page', () async {
      final client = answering([remoteRow(seq: 11)]);

      final page = await store(client).changesSince('sessions', limit: 2);

      expect(page.hasMore, isFalse);
      expect(page.cursor, '11');
    });

    test('nothing new moves nothing', () async {
      final client = answering(<Object?>[]);

      final page = await store(client).changesSince('sessions', limit: 2);

      expect(page.records, isEmpty);
      expect(page.cursor, isNull);
      expect(page.hasMore, isFalse);
    });
  });

  group('the shape a row comes back in', () {
    test('the envelope is hoisted and the server columns are dropped',
        () async {
      // user_id and synced_seq belong to the server. The app has no column
      // for either, and applying them would fail as version skew.
      final client = answering([remoteRow()]);

      final page = await store(client).changesSince('sessions', limit: 2);
      final row = page.records.single;

      expect(row.table, 'sessions');
      expect(row.id, 's1');
      expect(row.deviceId, 'other-phone');
      expect(row.updatedAt, DateTime.utc(2026, 11, 5, 10));
      expect(row.fields.keys, isNot(contains('user_id')));
      expect(row.fields.keys, isNot(contains('synced_seq')));
      expect(row.fields['pain_reported'], false);
      expect(row.fields.containsKey('notes'), isTrue);
    });

    test('a timestamp with an offset is still the same instant', () async {
      // Postgres hands back `+00:00` where the app writes `Z`. The conflict
      // rule compares instants, so this is the parse that has to be right.
      final client =
          answering([remoteRow(updatedAt: '2026-11-05T11:30:00+01:00')]);

      final page = await store(client).changesSince('sessions', limit: 2);

      expect(page.records.single.updatedAt, DateTime.utc(2026, 11, 5, 10, 30));
      expect(page.records.single.updatedAt.isUtc, isTrue);
    });

    test('a tombstone comes back as a tombstone', () async {
      final client =
          answering([remoteRow(deletedAt: '2026-11-05T10:00:00+00:00')]);

      final page = await store(client).changesSince('sessions', limit: 2);

      expect(page.records.single.isDeleted, isTrue);
    });
  });

  group('sending rows up', () {
    test('upserts on the account and the row together', () async {
      // The primary key is (user_id, id), so the conflict target has to be
      // both. Naming only id makes PostgREST insert a duplicate rather than
      // update, which fails the primary key and rejects the whole batch.
      final client = answering('', status: 201);

      await store(client).upsert('sessions', [record()]);

      final request = sent.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/sessions');
      expect(request.url.queryParameters['on_conflict'], 'user_id,id');
      expect(request.headers['prefer'], contains('resolution=merge-duplicates'));
    });

    test('stamps every row with the account it belongs to', () async {
      // Sent explicitly rather than left to the column default, because the
      // upsert cannot find the conflicting row without it. Row level
      // security still refuses anything but this account's own id, so this
      // is a convenience and not a trust.
      final client = answering('', status: 201);

      await store(client).upsert('sessions', [record(id: 's1'), record(id: 's2')]);

      final body = jsonDecode(sent.single.body) as List<Object?>;
      expect(body, hasLength(2));
      for (final row in body) {
        expect((row! as Map<String, Object?>)['user_id'], 'user-1');
      }
    });

    test('sends the envelope flattened back into the row', () async {
      final client = answering('', status: 201);

      await store(client).upsert('sessions', [record()]);

      final row = (jsonDecode(sent.single.body) as List<Object?>).single!
          as Map<String, Object?>;
      expect(row['id'], 's1');
      expect(row['updated_at'], '2026-11-05T10:00:00.000Z');
      expect(row['deleted_at'], isNull);
      expect(row['device_id'], 'this-phone');
      expect(row['notes'], 'felt strong');
      expect(
        row.containsKey('synced_seq'),
        isFalse,
        reason: 'the server stamps the replication order, not the client',
      );
    });

    test('asks for nothing back', () async {
      // The rows are already here. Returning them would double the traffic
      // of every push, and the next pull brings them anyway.
      final client = answering('', status: 201);

      await store(client).upsert('sessions', [record()]);

      expect(sent.single.headers['prefer'], contains('return=minimal'));
    });
  });

  group('when it does not work', () {
    test('nobody signed in is not a request at all', () async {
      final client = answering(<Object?>[]);

      await expectLater(
        store(client, token: null).changesSince('sessions', limit: 2),
        throwsA(isA<SyncUnauthorized>()),
      );
      expect(sent, isEmpty, reason: 'there was nothing to ask with');
    });

    test('an expired token asks for a sign-in rather than a retry', () async {
      final client = answering({'message': 'JWT expired'}, status: 401);

      await expectLater(
        store(client).changesSince('sessions', limit: 2),
        throwsA(isA<SyncUnauthorized>()),
      );
    });

    test('a policy refusing the row is the same answer', () async {
      // 403 from row level security means this account may not touch that
      // row. Retrying cannot help and the token may simply be the wrong
      // one, so it is reported the same way.
      final client = answering({'message': 'new row violates policy'},
          status: 403);

      await expectLater(
        store(client).upsert('sessions', [record()]),
        throwsA(isA<SyncUnauthorized>()),
      );
    });

    test('a row the server will not take says why', () async {
      final client = answering(
        {'message': 'violates foreign key constraint "set_logs_session_fkey"'},
        status: 409,
      );

      await expectLater(
        store(client).upsert('sessions', [record()]),
        throwsA(
          isA<SyncRejected>().having(
            (e) => e.message,
            'message',
            contains('set_logs_session_fkey'),
          ),
        ),
      );
    });

    test('the server having a bad day is worth trying again', () async {
      // A 5xx is not this app being wrong, and the next sync may well work.
      // Reported as offline so it lands on the retry path rather than in
      // front of the user as a rejected row.
      final client = answering('upstream timeout', status: 503);

      await expectLater(
        store(client).changesSince('sessions', limit: 2),
        throwsA(isA<SyncOffline>()),
      );
    });

    test('no network is offline, not an unhandled exception', () async {
      final client = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      await expectLater(
        store(client).changesSince('sessions', limit: 2),
        throwsA(isA<SyncOffline>()),
      );
    });

    test('a dropped connection is offline too', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection closed before full header');
      });

      await expectLater(
        store(client).upsert('sessions', [record()]),
        throwsA(isA<SyncOffline>()),
      );
    });

    test('an answer that is not a list of rows is not swallowed', () async {
      // Reported as a bug rather than as a failed sync: the protocol has no
      // name for it, and "try again" would hide a changed API behind a retry
      // button for ever.
      final client = answering({'message': 'hello'});

      await expectLater(
        store(client).changesSince('sessions', limit: 2),
        throwsA(isA<StateError>()),
      );
    });
  });
}
