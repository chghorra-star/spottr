import '../sync/session_store.dart';
import 'database.dart';
import 'local_identity_store.dart';

/// Takes one person's training off this device, so the next person can use
/// it — or so the same person can sign in as somebody else.
///
/// This is the only way out of [ForeignAccount]. A device that has held one
/// account's training refuses to adopt another's, because once two people's
/// rows are mixed there is no way to tell afterwards which were whose, and
/// the sync would push one person's sessions into the other's account. The
/// refusal is right; being stuck with it is not.
///
/// **A hard delete, deliberately, and the only one in the app.** Everywhere
/// else a delete is a tombstone, because a row that simply vanished would be
/// invisible to the other device and come straight back. Here that
/// machinery is precisely the hazard: a tombstone per row is a deletion
/// queued for the departing person's *other* phone, and the next sync would
/// empty it. So the rows go, and nothing is left pending.
///
/// What this does not do is delete anything from the server. It cannot, and
/// it should not pretend to: whatever has already synced belongs to that
/// account and is still theirs on their other devices. Erasing a phone is
/// not closing an account, and the confirmation says so.
class TrainingEraser {
  const TrainingEraser({
    required this.database,
    required this.identity,
    required this.sessions,
  });

  final AppDatabase database;
  final LocalIdentityStore identity;
  final SessionStore sessions;

  /// Erases every row about a person and forgets whose device this was.
  ///
  /// The order is the interesting part, because a failure half way through
  /// has to leave something sensible behind:
  ///
  /// 1. The session goes first. A live session on a phone being handed over
  ///    is the one outcome that is worse than not having erased at all —
  ///    the next person would open the app already signed in as somebody
  ///    else.
  /// 2. Then the rows, in one transaction, children before parents.
  /// 3. The owner is released **last**, so a failure anywhere above leaves
  ///    the device still owned, still refusing a second account, and still
  ///    able to try again. Releasing first would hand a half-erased device
  ///    to the next account, which is the mixing this whole mechanism
  ///    exists to prevent.
  Future<void> erase() async {
    await sessions.clear();

    await database.transaction(() async {
      // Derived from the schema rather than listed, so a table added later
      // is covered without anyone remembering to come back here.
      // `database_test.dart` keeps the three name sets exhaustive, which is
      // what makes the one exclusion below safe to state by name.
      for (final table in database.allTables.toList().reversed) {
        if (table.actualTableName == database.localIdentity.actualTableName) {
          continue;
        }
        await database.delete(table).go();
      }

      // Kept: the installation's own name. It says nothing about the person
      // who is leaving, and it is this device's identity in the conflict
      // tie-break for the person who arrives.
      await identity.release();
    });
  }
}
