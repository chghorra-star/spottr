import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spottr/data/sync/supabase_auth.dart';

/// GoTrue over the same plain `http.Client` the sync uses, for the same
/// reason: no SDK, no pod, and every request visible.
///
/// Most of this file is about what the user is told. "Something went wrong"
/// is the wrong answer to a mistyped password, to an email that is already
/// registered, and to a plane with no wifi, and those three arrive as very
/// similar HTTP. GoTrue has also changed the shape of its error bodies
/// between versions, so both shapes are read.
void main() {
  late List<http.Request> sent;

  MockClient answering(Object? body, {int status = 200}) {
    return MockClient((request) async {
      sent.add(request);
      return http.Response(
        body is String ? body : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  SupabaseAuth auth(http.Client client) {
    return SupabaseAuth(
      projectUrl: Uri.parse('https://project.supabase.co'),
      anonKey: 'anon-key',
      client: client,
      now: () => DateTime.utc(2026, 11, 5, 12),
    );
  }

  Map<String, Object?> session({
    String accessToken = 'access-1',
    String refreshToken = 'refresh-1',
    int expiresIn = 3600,
  }) {
    return {
      'access_token': accessToken,
      'token_type': 'bearer',
      'expires_in': expiresIn,
      'refresh_token': refreshToken,
      'user': {'id': 'user-1', 'email': 'a@example.com'},
    };
  }

  setUp(() => sent = []);

  group('signing in', () {
    test('asks for a token with the password grant', () async {
      final client = answering(session());

      await auth(client).signIn(email: 'a@example.com', password: 'hunter2');

      final request = sent.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'password');
      expect(request.headers['apikey'], 'anon-key');

      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['email'], 'a@example.com');
      expect(body['password'], 'hunter2');
    });

    test('comes back with everything the sync needs', () async {
      final client = answering(session());

      final result =
          await auth(client).signIn(email: 'a@example.com', password: 'x');

      expect(result.accessToken, 'access-1');
      expect(result.refreshToken, 'refresh-1');
      expect(result.userId, 'user-1');
      expect(result.email, 'a@example.com');
    });

    test('dates the expiry from this clock, not the server one', () async {
      // `expires_in` is a duration and `expires_at` is an instant on the
      // server's clock. The decision this expiry drives is local — refresh
      // before using the token — so it has to be on the clock that makes it.
      final client = answering(session(expiresIn: 3600));

      final result =
          await auth(client).signIn(email: 'a@example.com', password: 'x');

      expect(result.expiresAt, DateTime.utc(2026, 11, 5, 13));
    });

    test('a wrong password says so, in both of GoTrue error shapes', () async {
      for (final body in [
        {
          'code': 400,
          'error_code': 'invalid_credentials',
          'msg': 'Invalid login credentials',
        },
        {
          'error': 'invalid_grant',
          'error_description': 'Invalid login credentials',
        },
      ]) {
        await expectLater(
          auth(answering(body, status: 400))
              .signIn(email: 'a@example.com', password: 'wrong'),
          throwsA(
            isA<AuthException>()
                .having((e) => e.kind, 'kind', AuthErrorKind.invalidCredentials),
          ),
          reason: 'shape ${body.keys.first}',
        );
      }
    });

    test('an unconfirmed email is its own answer, not a wrong password',
        () async {
      // Telling somebody their password is wrong when it is right, and the
      // fix is in their inbox, is the most annoying error message an app can
      // produce.
      final client = answering(
        {'code': 400, 'error_code': 'email_not_confirmed', 'msg': 'Email not confirmed'},
        status: 400,
      );

      await expectLater(
        auth(client).signIn(email: 'a@example.com', password: 'right'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.kind,
            'kind',
            AuthErrorKind.confirmationRequired,
          ),
        ),
      );
    });
  });

  group('signing up', () {
    test('posts to signup', () async {
      final client = answering(session());

      await auth(client).signUp(email: 'a@example.com', password: 'hunter2');

      expect(sent.single.url.path, '/auth/v1/signup');
    });

    test('a project that confirms by email says so instead of a session',
        () async {
      // With confirmations on, GoTrue answers 200 with a user and no token.
      // Read as a session that happens to be missing its fields, that is a
      // crash; read correctly, it is the one thing the screen has to say.
      final client = answering({
        'id': 'user-1',
        'email': 'a@example.com',
        'confirmation_sent_at': '2026-11-05T12:00:00Z',
      });

      await expectLater(
        auth(client).signUp(email: 'a@example.com', password: 'hunter2'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.kind,
            'kind',
            AuthErrorKind.confirmationRequired,
          ),
        ),
      );
    });

    test('an email that already has an account says so', () async {
      final client = answering(
        {
          'code': 422,
          'error_code': 'user_already_exists',
          'msg': 'User already registered',
        },
        status: 422,
      );

      await expectLater(
        auth(client).signUp(email: 'a@example.com', password: 'hunter2'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.kind, 'kind', AuthErrorKind.emailTaken),
        ),
      );
    });

    test('a password the project will not take says what it wants', () async {
      // The message is the server's, because the rule is the server's: the
      // minimum length is a project setting, and a message invented here
      // would be wrong the day somebody changes it.
      final client = answering(
        {
          'code': 422,
          'error_code': 'weak_password',
          'msg': 'Password should be at least 8 characters',
        },
        status: 422,
      );

      await expectLater(
        auth(client).signUp(email: 'a@example.com', password: 'x'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.kind, 'kind', AuthErrorKind.weakPassword)
              .having((e) => e.message, 'message', contains('8 characters')),
        ),
      );
    });
  });

  group('refreshing', () {
    test('trades the refresh token for a new pair', () async {
      final client = answering(
        session(accessToken: 'access-2', refreshToken: 'refresh-2'),
      );

      final result = await auth(client).refresh('refresh-1');

      final request = sent.single;
      expect(request.url.queryParameters['grant_type'], 'refresh_token');
      expect(
        (jsonDecode(request.body) as Map<String, Object?>)['refresh_token'],
        'refresh-1',
      );
      expect(result.accessToken, 'access-2');
      expect(
        result.refreshToken,
        'refresh-2',
        reason: 'GoTrue rotates it, and the old one is now dead',
      );
    });

    test('a refresh token the server has retired means signed out', () async {
      // Nothing can be done with it and nothing should be retried. The only
      // honest next step is to ask the user to sign in again.
      final client = answering(
        {'code': 400, 'error_code': 'refresh_token_not_found', 'msg': 'Invalid Refresh Token'},
        status: 400,
      );

      await expectLater(
        auth(client).refresh('refresh-1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.kind,
            'kind',
            AuthErrorKind.invalidCredentials,
          ),
        ),
      );
    });
  });

  group('signing out', () {
    test('tells the server, with the token it is revoking', () async {
      final client = answering('', status: 204);

      await auth(client).signOut('access-1');

      expect(sent.single.url.path, '/auth/v1/logout');
      expect(sent.single.headers['authorization'], 'Bearer access-1');
    });

    test('is not blocked by a server that cannot be reached', () async {
      // The user tapped sign out. Whatever the server says, this device is
      // signing out — leaving them signed in because a request failed is
      // both surprising and, if they are handing the phone to somebody, the
      // wrong way round.
      final client = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      await auth(client).signOut('access-1');
    });

    test('is not blocked by a token the server has already forgotten',
        () async {
      final client = answering({'msg': 'Invalid token'}, status: 401);

      await auth(client).signOut('access-1');
    });
  });

  group('when the network is not there', () {
    test('no connection is its own answer, on every call', () async {
      final client = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      await expectLater(
        auth(client).signIn(email: 'a@example.com', password: 'x'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.kind, 'kind', AuthErrorKind.offline),
        ),
      );
    });

    test('the auth server having a bad day is worth trying again later',
        () async {
      final client = answering('bad gateway', status: 502);

      await expectLater(
        auth(client).signIn(email: 'a@example.com', password: 'x'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.kind, 'kind', AuthErrorKind.offline),
        ),
      );
    });

    test('anything else the server refuses is passed on with its message',
        () async {
      final client = answering(
        {'code': 429, 'error_code': 'over_request_rate_limit', 'msg': 'Too many requests'},
        status: 429,
      );

      await expectLater(
        auth(client).signIn(email: 'a@example.com', password: 'x'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.kind, 'kind', AuthErrorKind.rejected)
              .having((e) => e.message, 'message', 'Too many requests'),
        ),
      );
    });
  });

  group('a session that is about to expire', () {
    AuthSession at(int hour) => AuthSession(
          accessToken: 'a',
          refreshToken: 'r',
          userId: 'user-1',
          expiresAt: DateTime.utc(2026, 11, 5, hour),
        );

    test('counts as expired early, by a margin', () async {
      // A token that is valid for another ten seconds is not worth starting
      // a sync with: the pull would succeed and the push would 401 half way
      // through. The margin is what makes a sync either work or not.
      expect(at(13).isExpired(DateTime.utc(2026, 11, 5, 12)), isFalse);
      expect(at(13).isExpired(DateTime.utc(2026, 11, 5, 12, 59)), isTrue);
      expect(at(13).isExpired(DateTime.utc(2026, 11, 5, 14)), isTrue);
    });
  });
}
