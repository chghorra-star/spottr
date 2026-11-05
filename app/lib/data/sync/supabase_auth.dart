import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// What went wrong, in terms a screen can turn into a sentence.
///
/// Four of these are the user's situation rather than a fault, and telling
/// them apart is the whole job: "something went wrong" is the wrong answer
/// to a mistyped password, to an email that already has an account, and to
/// a train going through a tunnel.
enum AuthErrorKind {
  /// Wrong email or password — or, on a refresh, a token the server has
  /// retired. Both mean the same thing to the app: ask them to sign in.
  invalidCredentials,

  emailTaken,

  /// The project's password rule refused it. The message is the server's,
  /// because the rule is the server's.
  weakPassword,

  /// Signed up, or tried to sign in, and the address needs confirming
  /// first. The fix is in their inbox, not in the password field.
  confirmationRequired,

  /// No connection, or the auth server having a bad day. Worth trying again.
  offline,

  /// The server understood and refused for some other reason.
  rejected,
}

@immutable
class AuthException implements Exception {
  const AuthException(this.kind, this.message);

  final AuthErrorKind kind;

  /// The server's own words where it had any. Repeating them beats
  /// inventing a sentence that is wrong the day a project setting changes.
  final String message;

  @override
  String toString() => 'AuthException(${kind.name}: $message)';
}

/// A signed-in session: the tokens, who it belongs to, and when to renew.
@immutable
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.expiresAt,
    this.email,
  });

  /// The JWT the sync sends. Short-lived.
  final String accessToken;

  /// Traded for a new pair when the access token runs out. GoTrue rotates
  /// it on every use, so the one in hand is always the only live one —
  /// which is why two refreshes at once sign the user out, and why
  /// `SyncAccount` lets only one happen at a time.
  final String refreshToken;

  final String userId;
  final String? email;

  /// On **this** device's clock.
  ///
  /// Computed from `expires_in` rather than read from the server's
  /// `expires_at`, because the decision it drives is local — renew before
  /// using the token — and a clock an hour out would either renew on every
  /// call or never.
  final DateTime expiresAt;

  /// How early a token counts as spent.
  ///
  /// A token good for another ten seconds is not worth starting a sync
  /// with: the pull would succeed and the push would 401 half way through,
  /// which is a sync that half happened rather than one that did not.
  static const Duration renewalMargin = Duration(minutes: 2);

  bool isExpired(DateTime now, {Duration margin = renewalMargin}) =>
      !now.isBefore(expiresAt.subtract(margin));

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.userId == userId &&
      other.email == email &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      Object.hash(accessToken, refreshToken, userId, email, expiresAt);

  @override
  String toString() => 'AuthSession($userId, expires $expiresAt)';
}

/// Supabase auth over GoTrue's HTTP API.
///
/// No SDK, for the same reasons as the sync: the protocol is JSON over
/// HTTPS, a plain client keeps every request testable, and an iOS build
/// this machine cannot compile gains no native code.
///
/// This class holds nothing. It turns credentials into a session and a
/// session into a newer one; remembering any of it is [SyncAccount]'s job.
class SupabaseAuth {
  SupabaseAuth({
    required Uri projectUrl,
    required this.anonKey,
    http.Client? client,
    DateTime Function()? now,
  })  : _auth = projectUrl.replace(path: '/auth/v1'),
        _client = client ?? http.Client(),
        _now = now ?? DateTime.now;

  final String anonKey;

  final Uri _auth;
  final http.Client _client;
  final DateTime Function() _now;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final body = await _post(
      'token',
      query: {'grant_type': 'password'},
      body: {'email': email, 'password': password},
    );
    return _sessionFrom(body, whenAbsent: AuthErrorKind.rejected);
  }

  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    final body = await _post(
      'signup',
      body: {'email': email, 'password': password},
    );
    // A project with email confirmation on answers 200 with a user and no
    // tokens. Read as a session with missing fields that is a crash; read
    // properly it is the one thing the screen has to say.
    return _sessionFrom(body, whenAbsent: AuthErrorKind.confirmationRequired);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final body = await _post(
      'token',
      query: {'grant_type': 'refresh_token'},
      body: {'refresh_token': refreshToken},
    );
    return _sessionFrom(body, whenAbsent: AuthErrorKind.rejected);
  }

  /// Best effort, deliberately.
  ///
  /// The user tapped sign out. Whatever the server says, this device is
  /// signing out: leaving them signed in because a request failed is
  /// surprising, and if they are handing the phone to somebody it is the
  /// wrong way round.
  Future<void> signOut(String accessToken) async {
    try {
      await _post('logout', headers: {'authorization': 'Bearer $accessToken'});
    } on AuthException {
      // Revoking it server-side was a courtesy; forgetting it here is the
      // part that matters, and the caller does that regardless.
    }
  }

  Future<Map<String, Object?>> _post(
    String path, {
    Map<String, String> query = const {},
    Map<String, Object?> body = const {},
    Map<String, String> headers = const {},
  }) async {
    final url = _auth.replace(
      path: '${_auth.path}/$path',
      queryParameters: query.isEmpty ? null : query,
    );

    final http.Response response;
    try {
      response = await _client.post(
        url,
        headers: {
          'apikey': anonKey,
          'content-type': 'application/json',
          ...headers,
        },
        body: jsonEncode(body),
      );
    } on SocketException catch (error) {
      throw AuthException(AuthErrorKind.offline, error.message);
    } on http.ClientException catch (error) {
      throw AuthException(AuthErrorKind.offline, error.message);
    }

    final decoded = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw _failure(response, decoded);
  }

  Map<String, Object?> _decode(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      // Not JSON — a gateway's error page, most likely. The status code is
      // the only thing worth reading out of it.
      return const {};
    }
  }

  AuthException _failure(http.Response response, Map<String, Object?> body) {
    final message = _messageOf(body, response);

    if (response.statusCode >= 500) {
      return AuthException(
        AuthErrorKind.offline,
        'the auth server answered ${response.statusCode}: $message',
      );
    }

    final code = switch (body['error_code'] ?? body['error']) {
      final String value => value,
      _ => null,
    };

    final kind = switch (code) {
      'invalid_credentials' ||
      'invalid_grant' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' =>
        AuthErrorKind.invalidCredentials,
      'email_not_confirmed' => AuthErrorKind.confirmationRequired,
      'user_already_exists' || 'email_exists' => AuthErrorKind.emailTaken,
      'weak_password' => AuthErrorKind.weakPassword,
      // Older GoTrue sent no machine-readable code at all, so the message is
      // all there is. A fallback rather than the rule: a project on a recent
      // version never reaches this.
      _ => _kindFromMessage(message),
    };

    return AuthException(kind, message);
  }

  AuthErrorKind _kindFromMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid refresh token')) {
      return AuthErrorKind.invalidCredentials;
    }
    if (lower.contains('not confirmed')) {
      return AuthErrorKind.confirmationRequired;
    }
    if (lower.contains('already registered')) return AuthErrorKind.emailTaken;
    if (lower.contains('password should be')) {
      return AuthErrorKind.weakPassword;
    }
    return AuthErrorKind.rejected;
  }

  String _messageOf(Map<String, Object?> body, http.Response response) {
    for (final key in ['msg', 'error_description', 'message', 'error']) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return response.body.isEmpty
        ? 'HTTP ${response.statusCode}'
        : response.body;
  }

  AuthSession _sessionFrom(
    Map<String, Object?> body, {
    required AuthErrorKind whenAbsent,
  }) {
    final accessToken = body['access_token'];
    final refreshToken = body['refresh_token'];
    if (accessToken is! String || refreshToken is! String) {
      throw AuthException(
        whenAbsent,
        whenAbsent == AuthErrorKind.confirmationRequired
            ? 'confirm the address from the email before signing in'
            : 'the auth server answered without a session',
      );
    }

    // On signup the account sits at the top level; on a token grant it is
    // nested under `user`.
    final user = body['user'];
    final nested = user is Map<String, Object?> ? user : body;

    final userId = nested['id'];
    if (userId is! String) {
      throw const AuthException(
        AuthErrorKind.rejected,
        'the auth server answered without an account id',
      );
    }

    final expiresIn = body['expires_in'];
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: switch (nested['email']) {
        final String value => value,
        _ => null,
      },
      // An hour if the server did not say. Guessing long is safe here: an
      // access token that is dead sooner comes back as a 401, which the
      // sync reports as unauthorized and the account holder answers by
      // renewing. Guessing is the backstop, not the mechanism.
      expiresAt: _now().toUtc().add(
            Duration(seconds: expiresIn is num ? expiresIn.toInt() : 3600),
          ),
    );
  }
}
