import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/sync/session_store.dart';
import 'package:spottr/data/sync/supabase_auth.dart';

/// The keychain itself cannot be tested here — it is a method channel, and
/// this machine answers with a `MissingPluginException`. So the part that
/// could actually corrupt somebody's sign-in is a class of its own, and this
/// is it: the encoding, and what happens to a blob this build cannot read.
void main() {
  const codec = AuthSessionCodec();

  AuthSession session({String? email = 'a@example.com'}) => AuthSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
        email: email,
        expiresAt: DateTime.utc(2026, 11, 5, 13),
      );

  group('a stored session', () {
    test('comes back exactly as it went in', () async {
      expect(codec.decode(codec.encode(session())), session());
    });

    test('including an account with no address on it', () async {
      // An account created by some other means may have no email, and a
      // decoder that insisted on one would sign that person out for ever.
      expect(codec.decode(codec.encode(session(email: null))), session(email: null));
    });

    test('keeps the expiry to the instant', () async {
      // The expiry decides whether the next sync renews first. Rounded to
      // the second it would still work; dropped entirely it would not, and
      // a text format is the one that loses the zone quietly.
      final stored = codec.decode(codec.encode(session()))!;

      expect(stored.expiresAt, DateTime.utc(2026, 11, 5, 13));
      expect(stored.expiresAt.isUtc, isTrue);
    });
  });

  group('a blob this build cannot read', () {
    test('is no session rather than a crash', () async {
      // A stored session is not user data: the worst a bad one costs is one
      // sign-in. Throwing would be an app that will not open until somebody
      // clears its storage, which is the worse failure by a long way.
      expect(codec.decode('not json at all'), isNull);
      expect(codec.decode('[]'), isNull);
      expect(codec.decode('{}'), isNull);
    });

    test('is no session when a field it needs is missing', () async {
      expect(
        codec.decode(
          '{"access_token":"a","refresh_token":"r","expires_at":'
          '"2026-11-05T13:00:00.000Z"}',
        ),
        isNull,
        reason: 'no account id, so nothing could be stamped with it',
      );
    });

    test('is no session when the expiry is not a date', () async {
      expect(
        codec.decode(
          '{"access_token":"a","refresh_token":"r","user_id":"u",'
          '"expires_at":"soon"}',
        ),
        isNull,
      );
    });
  });

  group('the in-memory store', () {
    test('holds what it is given, and lets go of it', () async {
      final store = InMemorySessionStore();
      expect(await store.read(), isNull);

      await store.write(session());
      expect(await store.read(), session());

      await store.clear();
      expect(await store.read(), isNull);
    });

    test('can be seeded, as though a previous launch had stored it', () async {
      final store = InMemorySessionStore()..seed(session());

      expect(await store.read(), session());
    });
  });
}
