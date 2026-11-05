import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'supabase_auth.dart';

/// Where a session lives between launches.
///
/// An interface because the real one is the platform keychain, which a unit
/// test cannot reach: it is a method channel, and a widget test gets a
/// `MissingPluginException` rather than a keychain. Everything above this is
/// therefore tested against [InMemorySessionStore], and the keychain class
/// is kept thin enough that what is left untested is the glue.
abstract class SessionStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

/// The session as JSON, separately from where it is kept.
///
/// Its own class because the keychain cannot be unit tested and this can:
/// the part that could silently corrupt somebody's sign-in is the encoding,
/// not the `write` call around it.
class AuthSessionCodec {
  const AuthSessionCodec();

  String encode(AuthSession session) {
    return jsonEncode({
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      'user_id': session.userId,
      'email': session.email,
      'expires_at': session.expiresAt.toIso8601String(),
    });
  }

  /// Null for anything this build cannot read.
  ///
  /// A stored session is not user data: the worst a bad one costs is one
  /// sign-in, and the alternative — throwing on startup — is an app that
  /// will not open until somebody clears its storage.
  AuthSession? decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;

    final accessToken = decoded['access_token'];
    final refreshToken = decoded['refresh_token'];
    final userId = decoded['user_id'];
    final expiresAt = decoded['expires_at'];
    if (accessToken is! String ||
        refreshToken is! String ||
        userId is! String ||
        expiresAt is! String) {
      return null;
    }

    final expiry = DateTime.tryParse(expiresAt);
    if (expiry == null) return null;

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: switch (decoded['email']) {
        final String value => value,
        _ => null,
      },
      expiresAt: expiry.toUtc(),
    );
  }
}

/// The platform keychain: Keychain on iOS, EncryptedSharedPreferences on
/// Android.
///
/// The refresh token is a long-lived credential for somebody's account, so
/// it belongs here rather than in the SQLite file next to their training. A
/// database row would be readable from an unencrypted device backup and from
/// any process that can read the app's sandbox; the keychain is the thing the
/// operating system provides for exactly this.
///
/// None of this has run. It is a method channel, so a test on this machine
/// gets a `MissingPluginException` — which is why the encoding is a separate,
/// tested class and this is twenty lines of glue over it.
class KeychainSessionStore implements SessionStore {
  KeychainSessionStore({
    FlutterSecureStorage? storage,
    this.codec = const AuthSessionCodec(),
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                // Not restored onto a new device from a backup. A session
                // belongs to an installation, and the install id beside it
                // does too: two devices waking up as the same installation
                // is the one thing the conflict tie-break cannot survive.
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const String _key = 'spottr.session';

  final AuthSessionCodec codec;

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;

    final session = codec.decode(raw);
    if (session == null) {
      // Written by a build that spelled it differently, or damaged. Throw
      // it away rather than reading it again on every launch.
      await clear();
    }
    return session;
  }

  @override
  Future<void> write(AuthSession session) =>
      _storage.write(key: _key, value: codec.encode(session));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// A session in a field. Ships in `lib/` because the widget tests and the
/// app's own test wiring both need a store that works with no platform.
class InMemorySessionStore implements SessionStore {
  AuthSession? _session;

  /// Puts a session in as though a previous launch had stored it.
  void seed(AuthSession session) => _session = session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
