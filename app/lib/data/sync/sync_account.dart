import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sync_engine/sync_engine.dart';

import '../local/local_identity_store.dart';
import 'session_store.dart';
import 'supabase_auth.dart';
import 'supabase_remote_store.dart';

/// What a screen needs to know about the account.
///
/// Two separate facts, and conflating them is a bug waiting to happen.
/// [signedIn] is whether there is a live session; [owner] is whose training
/// this device holds, which outlives a sign-out.
@immutable
class AccountState {
  const AccountState({this.owner, this.signedIn = false});

  final DeviceOwner? owner;
  final bool signedIn;

  /// Signed out of an account this device still holds the training for.
  /// Worth telling apart from never having signed in: one is an invitation
  /// and the other is a return.
  bool get isReturning => !signedIn && owner != null;

  @override
  bool operator ==(Object other) =>
      other is AccountState &&
      other.owner == owner &&
      other.signedIn == signedIn;

  @override
  int get hashCode => Object.hash(owner, signedIn);

  @override
  String toString() => 'AccountState(${owner ?? 'nobody'}, '
      'signed ${signedIn ? 'in' : 'out'})';
}

/// Holds the session, renews it, and hands the sync its credentials.
///
/// Renewal is the whole of why this exists. GoTrue **rotates** the refresh
/// token on every use, so the one in hand is always the only live one: two
/// renewals at once spend it twice and the second answer is "signed out".
/// A sync walks seven tables and can ask for credentials more than once, so
/// that is a thing that happens rather than a thing that could.
///
/// The other rule worth stating: **only the server saying the credential is
/// invalid is allowed to end a session.** A rate limit or a bad gateway must
/// not, or the app signs people out of their training because a proxy had a
/// bad minute.
class SyncAccount {
  SyncAccount({
    required this.auth,
    required this.sessions,
    required this.identity,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SupabaseAuth auth;

  final SessionStore sessions;
  final LocalIdentityStore identity;

  final DateTime Function() _now;

  final StreamController<AccountState> _changes =
      StreamController<AccountState>.broadcast();

  AccountState _state = const AccountState();
  AuthSession? _session;
  Future<AuthSession>? _renewal;

  AccountState get state => _state;

  /// Every change, for whatever is on screen.
  Stream<AccountState> watch() => _changes.stream;

  /// Reads whatever the last launch left behind.
  Future<AccountState> load() async {
    _session = await sessions.read();
    return _publish();
  }

  Future<AccountState> signIn({
    required String email,
    required String password,
  }) async {
    return _adopt(await auth.signIn(email: email, password: password));
  }

  Future<AccountState> signUp({
    required String email,
    required String password,
  }) async {
    return _adopt(await auth.signUp(email: email, password: password));
  }

  /// Forgets the session. Keeps whose training this is.
  Future<AccountState> signOut() async {
    final session = _session;
    _session = null;
    await sessions.clear();

    // Told after the local state is already gone: the user tapped sign out,
    // and leaving them signed in because a request failed is the wrong way
    // round — especially if they are handing the phone to somebody.
    if (session != null) await auth.signOut(session.accessToken);

    return _publish();
  }

  /// What the remote store asks for before every request.
  ///
  /// Null means signed out, which is an ordinary state and not an error:
  /// the store turns it into `SyncUnauthorized` and the engine reports it.
  /// Renewal failures are thrown as the sync's own failures, so the engine
  /// can tell "try again later" from "ask them to sign in".
  Future<SupabaseCredentials?> credentials() async {
    var session = _session;
    if (session == null) return null;

    if (session.isExpired(_now())) session = await _renew(session);

    return SupabaseCredentials(
      accessToken: session.accessToken,
      userId: session.userId,
    );
  }

  Future<void> dispose() => _changes.close();

  Future<AccountState> _adopt(AuthSession session) async {
    try {
      await identity.claim(userId: session.userId, email: session.email);
    } on ForeignAccount {
      // Hand the token straight back. It was issued seconds ago for an
      // account this device is never going to sync, and leaving it live
      // would be a session nobody can see and nobody can end.
      await auth.signOut(session.accessToken);
      rethrow;
    }

    await sessions.write(session);
    _session = session;
    return _publish();
  }

  /// One renewal at a time, however many callers ask.
  Future<AuthSession> _renew(AuthSession stale) {
    final inFlight = _renewal;
    if (inFlight != null) return inFlight;

    final attempt = _refresh(stale);
    _renewal = attempt;
    return attempt.whenComplete(() => _renewal = null);
  }

  Future<AuthSession> _refresh(AuthSession stale) async {
    final AuthSession fresh;
    try {
      fresh = await auth.refresh(stale.refreshToken);
    } on AuthException catch (error) {
      if (error.kind == AuthErrorKind.invalidCredentials) {
        // The server has retired the token. Nothing can be done with the
        // session, so the only honest state is signed out.
        _session = null;
        await sessions.clear();
        await _publish();
        throw SyncUnauthorized(error.message);
      }
      // Everything else keeps the session. Offline, rate limited, a bad
      // gateway — none of those are evidence that the credential is dead,
      // and throwing it away would sign somebody out of their training over
      // a bad minute on somebody else's network.
      throw SyncOffline(error.message);
    }

    // Written before it is handed out. The old refresh token is dead the
    // moment this one exists, so a device that kept the old one would be
    // signed out on its next launch having been signed in the whole time.
    await sessions.write(fresh);
    _session = fresh;
    await _publish();
    return fresh;
  }

  Future<AccountState> _publish() async {
    _state = AccountState(
      owner: await identity.owner(),
      signedIn: _session != null,
    );
    if (!_changes.isClosed) _changes.add(_state);
    return _state;
  }
}
