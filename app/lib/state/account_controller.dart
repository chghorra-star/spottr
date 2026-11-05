import 'package:sync_engine/sync_engine.dart';

import '../data/sync/sync_account.dart';

/// What the account screen is allowed to ask for.
///
/// An interface, like the other three controllers, and for the same reason:
/// it lets a widget test assert *what a screen asked for* without a
/// keychain, a database or a network underneath it. Whether those requests
/// then work is the business of `SyncAccount`, `SyncEngine` and the two
/// stores, each of which has its own tests.
abstract class AccountController {
  /// The state as it stands, and every change to it.
  Stream<AccountState> watch();

  /// Reads whatever the last launch left behind.
  Future<AccountState> load();

  Future<AccountState> signIn({
    required String email,
    required String password,
  });

  Future<AccountState> signUp({
    required String email,
    required String password,
  });

  Future<AccountState> signOut();

  /// Replicates now, and says what happened.
  Future<SyncReport> syncNow();
}

/// The real one: an account holder and a sync engine side by side.
class SyncAccountController implements AccountController {
  const SyncAccountController({required this.account, required this.engine});

  final SyncAccount account;
  final SyncEngine engine;

  @override
  Stream<AccountState> watch() => account.watch();

  @override
  Future<AccountState> load() => account.load();

  @override
  Future<AccountState> signIn({
    required String email,
    required String password,
  }) =>
      account.signIn(email: email, password: password);

  @override
  Future<AccountState> signUp({
    required String email,
    required String password,
  }) =>
      account.signUp(email: email, password: password);

  @override
  Future<AccountState> signOut() => account.signOut();

  @override
  Future<SyncReport> syncNow() => engine.sync();
}
