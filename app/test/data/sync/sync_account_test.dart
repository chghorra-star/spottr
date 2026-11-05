import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/local/local_identity_store.dart';
import 'package:spottr/data/sync/session_store.dart';
import 'package:spottr/data/sync/supabase_auth.dart';
import 'package:spottr/data/sync/sync_account.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../support/test_database.dart';

/// The piece that holds a session and decides when to renew it.
///
/// Most of this file is about renewal, because GoTrue **rotates** the
/// refresh token on every use: the one in hand is always the only live one,
/// so two refreshes at once spend it twice and the second answer is "signed
/// out". Two tables syncing is two callers asking for credentials at the
/// same moment, which makes that a thing that happens rather than a thing
/// that could.
///
/// The other half is which failures are allowed to sign somebody out. Only
/// the server saying the credential is invalid. A rate limit or a bad
/// gateway must not, or the app logs people out of their training because a
/// proxy had a bad minute.
void main() {
  late AppDatabase db;
  late LocalIdentityStore identity;
  late InMemorySessionStore sessions;
  late DateTime clock;
  late List<http.Request> sent;

  setUp(() {
    db = openTestDatabase();
    identity = LocalIdentityStore(db, now: () => DateTime.utc(2026, 11, 5, 12));
    sessions = InMemorySessionStore();
    clock = DateTime.utc(2026, 11, 5, 12);
    sent = [];
  });
  tearDown(() => db.close());

  /// Answers every auth request with a session, or with [failWith] for
  /// refreshes once [failRefreshes] is set.
  MockClient server({
    String userId = 'user-1',
    String email = 'a@example.com',
    int expiresIn = 3600,
    Object? failRefreshWith,
    int failRefreshStatus = 400,
  }) {
    // Numbered by renewal, so `access-2` is the first renewed token however
    // many times the fake has been asked for anything else.
    var renewals = 0;
    return MockClient((request) async {
      sent.add(request);
      final isRefresh =
          request.url.queryParameters['grant_type'] == 'refresh_token';

      if (isRefresh && failRefreshWith != null) {
        return http.Response(
          jsonEncode(failRefreshWith),
          failRefreshStatus,
          headers: {'content-type': 'application/json'},
        );
      }
      if (isRefresh) renewals++;

      final generation = renewals + 1;
      return http.Response(
        jsonEncode({
          'access_token': isRefresh ? 'access-$generation' : 'access-1',
          'refresh_token': isRefresh ? 'refresh-$generation' : 'refresh-1',
          'expires_in': expiresIn,
          'user': {'id': userId, 'email': email},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  SyncAccount account(http.Client client) {
    final auth = SupabaseAuth(
      projectUrl: Uri.parse('https://project.supabase.co'),
      anonKey: 'anon-key',
      client: client,
      now: () => clock,
    );
    final subject = SyncAccount(
      auth: auth,
      sessions: sessions,
      identity: identity,
      now: () => clock,
    );
    addTearDown(subject.dispose);
    return subject;
  }

  int refreshCount() => sent
      .where((r) => r.url.queryParameters['grant_type'] == 'refresh_token')
      .length;

  group('a device nobody has signed in on', () {
    test('holds no account and offers no credentials', () async {
      final subject = account(server());

      final state = await subject.load();

      expect(state.signedIn, isFalse);
      expect(state.owner, isNull);
      expect(await subject.credentials(), isNull);
    });

    test('offering no credentials is not an error', () async {
      // The remote store turns null into "nobody is signed in", which the
      // engine reports and the screen shows as an invitation. Throwing here
      // would make a perfectly ordinary state look like a fault.
      final subject = account(server());
      await subject.load();

      expect(subject.credentials(), completes);
    });
  });

  group('signing in', () {
    test('keeps the session and adopts the training already here', () async {
      final subject = account(server());

      final state = await subject.signIn(
        email: 'a@example.com',
        password: 'hunter2',
      );

      expect(state.signedIn, isTrue);
      expect(state.owner!.userId, 'user-1');
      expect(state.owner!.email, 'a@example.com');
      expect(await sessions.read(), isNotNull);
      expect((await identity.owner())!.userId, 'user-1');
    });

    test('hands the sync a token and an account to stamp rows with',
        () async {
      final subject = account(server());
      await subject.signIn(email: 'a@example.com', password: 'x');

      final credentials = await subject.credentials();

      expect(credentials!.accessToken, 'access-1');
      expect(credentials.userId, 'user-1');
    });

    test('a second account is refused, and not left signed in server-side',
        () async {
      // The rows here were adopted by the first account. A second one
      // adopting them would push one person's sessions into another
      // person's account, and there is no undo. The session that was just
      // created is given back rather than left live for an account this
      // device will not sync.
      await identity.claim(userId: 'user-1', email: 'a@example.com');
      final subject =
          account(server(userId: 'user-2', email: 'b@example.com'));

      await expectLater(
        subject.signIn(email: 'b@example.com', password: 'x'),
        throwsA(isA<ForeignAccount>()),
      );

      expect(await sessions.read(), isNull);
      expect(subject.state.signedIn, isFalse);
      expect(
        sent.any((r) => r.url.path == '/auth/v1/logout'),
        isTrue,
        reason: 'the token it just issued was handed back',
      );
    });

    test('is remembered across a restart without asking the network',
        () async {
      final first = account(server());
      await first.signIn(email: 'a@example.com', password: 'x');

      sent.clear();
      final second = account(server());
      final state = await second.load();

      expect(state.signedIn, isTrue);
      expect((await second.credentials())!.accessToken, 'access-1');
      expect(sent, isEmpty, reason: 'the session was on the device');
    });
  });

  group('renewing', () {
    test('an expired token is renewed before the sync sees it', () async {
      final subject = account(server(expiresIn: 3600));
      await subject.signIn(email: 'a@example.com', password: 'x');

      clock = DateTime.utc(2026, 11, 5, 14);
      final credentials = await subject.credentials();

      expect(credentials!.accessToken, 'access-2');
      expect(refreshCount(), 1);
    });

    test('the renewed pair is kept, so a restart does not renew again',
        () async {
      // GoTrue retires the old refresh token when it issues a new one. A
      // device that stored the old one would be signed out on its next
      // launch, having been signed in the whole time.
      final subject = account(server());
      await subject.signIn(email: 'a@example.com', password: 'x');
      clock = DateTime.utc(2026, 11, 5, 14);
      await subject.credentials();

      final stored = await sessions.read();
      expect(stored!.refreshToken, 'refresh-2');
      expect(stored.accessToken, 'access-2');
    });

    test('two callers at once renew once, not twice', () async {
      // Two tables syncing is two callers. Spending the refresh token twice
      // makes the second answer "signed out", and the user is logged out
      // mid-sync for no reason they could possibly discover.
      final subject = account(server());
      await subject.signIn(email: 'a@example.com', password: 'x');
      clock = DateTime.utc(2026, 11, 5, 14);

      final both = await Future.wait([
        subject.credentials(),
        subject.credentials(),
      ]);

      expect(refreshCount(), 1);
      expect(both.first!.accessToken, both.last!.accessToken);
    });

    test('and renews again later, rather than being stuck on one attempt',
        () async {
      final subject = account(server());
      await subject.signIn(email: 'a@example.com', password: 'x');

      clock = DateTime.utc(2026, 11, 5, 14);
      await subject.credentials();
      clock = DateTime.utc(2026, 11, 5, 16);
      await subject.credentials();

      expect(refreshCount(), 2);
    });

    test('a token still good for a while is used as it is', () async {
      final subject = account(server());
      await subject.signIn(email: 'a@example.com', password: 'x');

      clock = DateTime.utc(2026, 11, 5, 12, 30);
      await subject.credentials();

      expect(refreshCount(), 0);
    });
  });

  group('when renewing fails', () {
    test('a retired refresh token signs the device out', () async {
      // Nothing can be done with it, so the only honest state is signed
      // out, and the only honest next step is to ask.
      final subject = account(
        server(
          failRefreshWith: {
            'code': 400,
            'error_code': 'refresh_token_not_found',
            'msg': 'Invalid Refresh Token',
          },
        ),
      );
      await subject.signIn(email: 'a@example.com', password: 'x');
      clock = DateTime.utc(2026, 11, 5, 14);

      await expectLater(
        subject.credentials(),
        throwsA(isA<SyncUnauthorized>()),
      );

      expect(await sessions.read(), isNull);
      expect(subject.state.signedIn, isFalse);
      expect(
        subject.state.owner!.userId,
        'user-1',
        reason: 'the training here still belongs to them',
      );
    });

    test('no connection keeps the session, and says to try again', () async {
      // Reported as offline so the engine puts it on the retry path. A
      // session thrown away here is somebody signed out by a tunnel.
      final client = MockClient((request) async {
        sent.add(request);
        throw http.ClientException('Connection closed');
      });
      sessions.seed(
        AuthSession(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          userId: 'user-1',
          email: 'a@example.com',
          expiresAt: DateTime.utc(2026, 11, 5, 13),
        ),
      );
      await identity.claim(userId: 'user-1', email: 'a@example.com');

      final subject = account(client);
      await subject.load();
      clock = DateTime.utc(2026, 11, 5, 14);

      await expectLater(subject.credentials(), throwsA(isA<SyncOffline>()));

      expect(await sessions.read(), isNotNull);
      expect(subject.state.signedIn, isTrue);
    });

    test('being rate limited does not sign anybody out either', () async {
      // The refresh token is fine; the server is busy. Only the server
      // saying the credential is invalid is allowed to end a session.
      final subject = account(
        server(
          failRefreshStatus: 429,
          failRefreshWith: {
            'code': 429,
            'error_code': 'over_request_rate_limit',
            'msg': 'Too many requests',
          },
        ),
      );
      await subject.signIn(email: 'a@example.com', password: 'x');
      clock = DateTime.utc(2026, 11, 5, 14);

      await expectLater(subject.credentials(), throwsA(isA<SyncOffline>()));

      expect(subject.state.signedIn, isTrue);
      expect(await sessions.read(), isNotNull);
    });
  });

  group('signing out', () {
    test('forgets the session and keeps whose training this is', () async {
      final subject = account(server());
      await subject.signIn(email: 'a@example.com', password: 'x');

      final state = await subject.signOut();

      expect(state.signedIn, isFalse);
      expect(await sessions.read(), isNull);
      expect(state.owner!.userId, 'user-1');
      expect(await subject.credentials(), isNull);
    });

    test('tells the server, but is not blocked by it', () async {
      final client = MockClient((request) async {
        sent.add(request);
        if (request.url.path == '/auth/v1/logout') {
          throw http.ClientException('Connection closed');
        }
        return http.Response(
          jsonEncode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 3600,
            'user': {'id': 'user-1', 'email': 'a@example.com'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final subject = account(client);
      await subject.signIn(email: 'a@example.com', password: 'x');

      final state = await subject.signOut();

      expect(state.signedIn, isFalse);
      expect(await sessions.read(), isNull);
    });
  });

  group('what the screen watches', () {
    test('every change in state reaches it', () async {
      final subject = account(server());
      final seen = <bool>[];
      final sub = subject.watch().listen((state) => seen.add(state.signedIn));

      await subject.load();
      await subject.signIn(email: 'a@example.com', password: 'x');
      await subject.signOut();
      await pumpEventQueue();

      expect(seen, [false, true, false]);
      await sub.cancel();
    });
  });
}
