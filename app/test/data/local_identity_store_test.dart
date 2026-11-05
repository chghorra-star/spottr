import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/local/local_identity_store.dart';

import '../support/test_database.dart';

/// Two strings about this device, neither of them a secret.
///
/// The install id is what makes the conflict rule's tie-break mean anything:
/// two edits claiming the same instant are separated by which device made
/// them, so if every install calls itself the same thing both copies resolve
/// to "keep mine" and stay different for ever. Until M10 every install
/// called itself `'local'`.
///
/// The owner is whose training this database holds. It is deliberately not
/// "who is signed in" — that is a question about the keychain — and it
/// survives a sign-out, because the rows here belong to that account and
/// letting a second account sign in over them would push one person's
/// training into another person's account.
void main() {
  late AppDatabase db;
  late LocalIdentityStore store;

  setUp(() {
    db = openTestDatabase();
    store = LocalIdentityStore(db, now: () => DateTime.utc(2026, 11, 5, 12));
  });
  tearDown(() => db.close());

  group('the install id', () {
    test('is created on first use', () async {
      final id = await store.installId();

      expect(id, isNotEmpty);
      expect(id.length, lessThanOrEqualTo(64), reason: 'the column is 64');
    });

    test('is the same one every time afterwards', () async {
      // Read on every launch. A new id per launch would make this device
      // look like a different device to itself, and every conflict it had
      // ever resolved would become re-resolvable the other way.
      final first = await store.installId();
      final second = await store.installId();
      final third = await LocalIdentityStore(db).installId();

      expect(second, first);
      expect(third, first);
    });

    test('is different on a different installation', () async {
      // Generated, not derived: two phones set up in the same minute have
      // to disagree, and a restored backup must not hand two installations
      // the same name.
      final other = openTestDatabase();
      addTearDown(other.close);

      final mine = await store.installId();
      final theirs = await LocalIdentityStore(other).installId();

      expect(theirs, isNot(mine));
    });

    test('leaves exactly one row behind, however often it is asked', () async {
      await store.installId();
      await store.installId();

      expect(await db.select(db.localIdentity).get(), hasLength(1));
    });

    test('survives being claimed and released', () async {
      final before = await store.installId();
      await store.claim(userId: 'user-1', email: 'a@example.com');

      await store.release();

      expect(await store.installId(), before);
    });
  });

  group('the owner', () {
    test('is nobody on a device that has never signed in', () async {
      await store.installId();

      expect(await store.owner(), isNull);
    });

    test('is remembered, so the app knows whose data this is', () async {
      await store.claim(userId: 'user-1', email: 'a@example.com');

      final owner = await store.owner();

      expect(owner!.userId, 'user-1');
      expect(owner.email, 'a@example.com');
      expect(owner.claimedAt, DateTime.utc(2026, 11, 5, 12));
    });

    test('can be claimed before anything has asked for an install id',
        () async {
      // Signing in on a fresh install happens before any sync has run, so
      // the row has to arrive complete rather than assuming it is there.
      await store.claim(userId: 'user-1', email: 'a@example.com');

      expect(await store.installId(), isNotEmpty);
      expect((await store.owner())!.userId, 'user-1');
    });

    test('claiming again by the same account is just a no-op', () async {
      // Signing back in after a sign-out, which is the common case.
      await store.claim(userId: 'user-1', email: 'a@example.com');

      await store.claim(userId: 'user-1', email: 'new@example.com');

      final owner = await store.owner();
      expect(owner!.userId, 'user-1');
      expect(owner.email, 'new@example.com', reason: 'an address can change');
      expect(owner.claimedAt, DateTime.utc(2026, 11, 5, 12));
    });

    test('claiming it for somebody else is refused', () async {
      // The rows on this device were written before anybody signed in, so
      // the first account to sign in adopts them — which is what makes
      // somebody's training follow them to a second device. A *second*
      // account adopting them would push one person's sessions into another
      // person's account, and there is no undo for that.
      await store.claim(userId: 'user-1', email: 'a@example.com');

      await expectLater(
        store.claim(userId: 'user-2', email: 'b@example.com'),
        throwsA(isA<ForeignAccount>()),
      );
      expect((await store.owner())!.userId, 'user-1');
    });

    test('and is still refused after a sign-out', () async {
      // Signing out does not release the data. This is the whole reason the
      // owner is not cleared with the session.
      await store.claim(userId: 'user-1', email: 'a@example.com');

      await expectLater(
        store.claim(userId: 'user-2'),
        throwsA(isA<ForeignAccount>()),
      );
    });

    test('releasing it lets another account in', () async {
      // The escape hatch, for a device being handed on. The caller is
      // responsible for having erased the training first; this only forgets
      // who it belonged to.
      await store.claim(userId: 'user-1', email: 'a@example.com');

      await store.release();

      expect(await store.owner(), isNull);
      await store.claim(userId: 'user-2', email: 'b@example.com');
      expect((await store.owner())!.userId, 'user-2');
    });
  });
}
