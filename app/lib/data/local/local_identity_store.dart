import 'dart:math';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'database.dart';

/// Thrown when a second account tries to adopt a device's training.
class ForeignAccount implements Exception {
  const ForeignAccount({required this.owner, required this.attempted});

  /// The account whose training this device holds.
  final String owner;

  /// The account that tried to sign in over it.
  final String attempted;

  @override
  String toString() =>
      'ForeignAccount(this device holds $owner training, not $attempted)';
}

/// Whose training a device holds.
@immutable
class DeviceOwner {
  const DeviceOwner({required this.userId, this.email, this.claimedAt});

  /// The Supabase account id. What every replicated row is stamped with on
  /// the server, and what makes one person's rows not another's.
  final String userId;

  final String? email;
  final DateTime? claimedAt;

  @override
  bool operator ==(Object other) =>
      other is DeviceOwner &&
      other.userId == userId &&
      other.email == email &&
      other.claimedAt == claimedAt;

  @override
  int get hashCode => Object.hash(userId, email, claimedAt);

  @override
  String toString() => 'DeviceOwner($userId, ${email ?? 'no email'})';
}

/// Who this device is, and whose training it holds.
///
/// The install id is the half that matters to the sync. The conflict rule
/// separates two edits claiming the same instant by which device made them,
/// so every installation needs a name that is stable for its whole life and
/// distinct from every other installation. Until M10 that name was the
/// constant `'local'` on every install, which meant the tie-break could not
/// break anything: both sides answered "keep mine" and stayed different.
///
/// Neither value here is a secret, and the refresh token is deliberately
/// not among them — that belongs in the platform keychain.
class LocalIdentityStore {
  LocalIdentityStore(this._db, {DateTime Function()? now, Random? random})
      : _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  final AppDatabase _db;
  final DateTime Function() _now;
  final Random _random;

  /// This installation's id, generated the first time it is asked for.
  ///
  /// Generated rather than derived. A hash of something about the device
  /// would be reproducible, which sounds like a feature until a restored
  /// backup gives two installations the same name — and the entire job of
  /// this string is to tell two installations apart.
  Future<String> installId() {
    return _db.transaction(() async {
      final existing = await _row();
      if (existing != null) return existing.installId;

      final id = _generate();
      await _db.into(_db.localIdentity).insert(
            LocalIdentityCompanion.insert(installId: id),
          );
      return id;
    });
  }

  /// Whose training this database holds, or null if nobody has signed in.
  Future<DeviceOwner?> owner() async {
    final row = await _row();
    final userId = row?.userId;
    if (userId == null) return null;

    return DeviceOwner(
      userId: userId,
      email: row!.email,
      claimedAt: row.claimedAt,
    );
  }

  /// Records that this device's training belongs to [userId].
  ///
  /// The first account to sign in adopts whatever is already here, which is
  /// what makes somebody's existing training follow them to a second device.
  /// A *different* account doing the same would push one person's sessions
  /// into another person's account, so it is refused: there is no undo for
  /// that, and no way to tell afterwards which rows were whose.
  ///
  /// The same account claiming again is the ordinary case — signing back in
  /// after a sign-out — and only updates the address, which can change.
  Future<void> claim({required String userId, String? email}) {
    return _db.transaction(() async {
      // A fresh install may have nothing in the table at all yet.
      await installId();

      final current = await owner();
      if (current != null && current.userId != userId) {
        throw ForeignAccount(owner: current.userId, attempted: userId);
      }

      await _db.update(_db.localIdentity).write(
            LocalIdentityCompanion(
              userId: Value(userId),
              email: Value(email),
              // Kept from the first claim: it answers "since when has this
              // device held this person's training", and signing back in
              // does not change the answer.
              claimedAt: Value(current?.claimedAt ?? _now()),
            ),
          );
    });
  }

  /// Forgets whose training this is, keeping the installation's own name.
  ///
  /// For a device being handed on. The caller is responsible for having
  /// erased the training first — this only forgets who it belonged to, and
  /// releasing without erasing is how one person's sessions end up in
  /// another person's account.
  Future<void> release() async {
    await _db.update(_db.localIdentity).write(
          const LocalIdentityCompanion(
            userId: Value<String?>(null),
            email: Value<String?>(null),
            claimedAt: Value<DateTime?>(null),
          ),
        );
  }

  Future<LocalIdentityRow?> _row() =>
      _db.select(_db.localIdentity).getSingleOrNull();

  /// Eight random bytes as hex: short enough to read in a log, long enough
  /// that two installations colliding is not a thing that happens.
  String _generate() {
    return [
      for (var i = 0; i < 8; i++)
        _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
