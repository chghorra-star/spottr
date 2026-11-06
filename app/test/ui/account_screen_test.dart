import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/local_identity_store.dart';
import 'package:spottr/data/sync/supabase_auth.dart';
import 'package:spottr/data/sync/supabase_config.dart';
import 'package:spottr/data/sync/sync_account.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/l10n/app_localizations.dart';
import 'package:spottr/ui/account/account_screen.dart';
import 'package:spottr/ui/common/ui_keys.dart';
import 'package:sync_engine/sync_engine.dart';

import '../support/fakes.dart';
import '../support/pump.dart';
import '../support/profiles.dart';

/// What the screen shows and what it asks for. Whether signing in works is
/// `SyncAccount`'s business, against a fake HTTP client; whether a sync
/// moves anything is the engine's.
///
/// The claim at the top of the screen is pinned here on purpose. Spottr
/// works without an account and nothing from the camera is ever uploaded,
/// and a screen that stopped saying so would be a change of position rather
/// than a change of copy.
void main() {
  final config = SupabaseConfig(
    url: Uri.parse('https://project.supabase.co'),
    anonKey: 'anon-key',
  );

  const signedOut = AccountState();
  const returning = AccountState(
    owner: DeviceOwner(userId: 'user-1', email: 'a@example.com'),
  );
  const signedIn = AccountState(
    owner: DeviceOwner(userId: 'user-1', email: 'a@example.com'),
    signedIn: true,
  );

  Future<RecordingAccountController> open(
    WidgetTester tester, {
    AccountState initial = signedOut,
    Future<void> Function(String email, String password)? onSignIn,
    Future<void> Function(String email, String password)? onSignUp,
    Future<SyncReport> Function()? onSync,
    Future<void> Function()? onErase,
  }) async {
    final controller = RecordingAccountController(
      initial: initial,
      onSignIn: onSignIn,
      onSignUp: onSignUp,
      onSync: onSync,
      onErase: onErase,
    );
    await pumpScreen(
      tester,
      const AccountScreen(),
      profile: testProfile(),
      overrides: [
        supabaseConfigProvider.overrideWithValue(config),
        accountControllerProvider.overrideWithValue(controller),
      ],
    );
    return controller;
  }

  /// The erase section sits below the sign-in form, which on a signed-out
  /// device puts it off the bottom of a test viewport — and a `ListView`
  /// does not build what it is not showing. Dragging rather than
  /// `scrollUntilVisible`, which cannot tell the list apart from the two
  /// text fields' own scroll views.
  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  group('the states every screen has', () {
    testWidgets('loading, while the stored session is read', (tester) async {
      await pumpScreen(
        tester,
        const AccountScreen(),
        profile: testProfile(),
        settled: false,
        overrides: [
          supabaseConfigProvider.overrideWithValue(config),
          accountProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );

      expect(find.byKey(UiKeys.loading), findsOneWidget);
    });

    testWidgets('an error, with a way out of it', (tester) async {
      await pumpScreen(
        tester,
        const AccountScreen(),
        profile: testProfile(),
        overrides: [
          supabaseConfigProvider.overrideWithValue(config),
          accountProvider.overrideWith(
            (ref) => Stream<AccountState>.error(StateError('keychain')),
          ),
        ],
      );

      expect(find.byKey(UiKeys.errorPanel), findsOneWidget);
      expect(find.byKey(UiKeys.retry), findsOneWidget);
    });

    testWidgets('a build with no project says so, and offers no form',
        (tester) async {
      // Not an error state. A build without a Supabase project is the
      // ordinary local-first app, and a sign-in form that could never work
      // would be worse than none.
      await pumpScreen(
        tester,
        const AccountScreen(),
        profile: testProfile(),
        overrides: [supabaseConfigProvider.overrideWithValue(null)],
      );

      expect(find.byKey(UiKeys.accountUnavailable), findsOneWidget);
      expect(find.byKey(UiKeys.accountEmail), findsNothing);
      expect(find.byKey(UiKeys.accountSignIn), findsNothing);
    });
  });

  group('what the screen claims', () {
    testWidgets('says the app does not need an account, before any field',
        (tester) async {
      await open(tester);
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(find.text(l10n.accountLocalFirstBody), findsOneWidget);
      expect(l10n.accountLocalFirstBody, contains('without an account'));
      expect(l10n.accountLocalFirstBody.toLowerCase(), contains('camera'));
    });

    testWidgets('and keeps saying it once somebody is signed in',
        (tester) async {
      await open(tester, initial: signedIn);
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(find.text(l10n.accountLocalFirstBody), findsOneWidget);
    });
  });

  group('signed out', () {
    testWidgets('asks for an email and a password', (tester) async {
      await open(tester);

      expect(find.byKey(UiKeys.accountEmail), findsOneWidget);
      expect(find.byKey(UiKeys.accountPassword), findsOneWidget);
      expect(find.byKey(UiKeys.accountSignIn), findsOneWidget);
      expect(find.byKey(UiKeys.accountSignUp), findsOneWidget);
      expect(find.byKey(UiKeys.accountSignOut), findsNothing);
    });

    testWidgets('signs in with what was typed', (tester) async {
      final controller = await open(tester);

      await tester.enterText(find.byKey(UiKeys.accountEmail), ' a@b.com ');
      await tester.enterText(find.byKey(UiKeys.accountPassword), 'hunter2');
      await tester.tap(find.byKey(UiKeys.accountSignIn));
      await tester.pumpAndSettle();

      expect(
        controller.signedIn,
        ['a@b.com'],
        reason: 'trimmed: a stray space is not a different account',
      );
    });

    testWidgets('and then syncs, without being asked twice', (tester) async {
      // Somebody who has just signed in did it to get their training onto
      // this device. A screen that sat there waiting to be told to sync
      // reads as not having worked.
      final controller = await open(tester);

      await tester.enterText(find.byKey(UiKeys.accountEmail), 'a@b.com');
      await tester.enterText(find.byKey(UiKeys.accountPassword), 'hunter2');
      await tester.tap(find.byKey(UiKeys.accountSignIn));
      await tester.pumpAndSettle();

      expect(controller.syncs, 1);
    });

    testWidgets('creating an account is a different button', (tester) async {
      final controller = await open(tester);

      await tester.enterText(find.byKey(UiKeys.accountEmail), 'a@b.com');
      await tester.enterText(find.byKey(UiKeys.accountPassword), 'hunter2');
      await tester.tap(find.byKey(UiKeys.accountSignUp));
      await tester.pumpAndSettle();

      expect(controller.signedUp, ['a@b.com']);
      expect(controller.signedIn, isEmpty);
    });

    testWidgets('an empty field is answered here, not by the server',
        (tester) async {
      final controller = await open(tester);

      await tester.tap(find.byKey(UiKeys.accountSignIn));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.accountError), findsOneWidget);
      expect(controller.signedIn, isEmpty, reason: 'nothing was sent');
    });

    testWidgets('a wrong password is said in words', (tester) async {
      final controller = await open(
        tester,
        onSignIn: (email, password) async => throw const AuthException(
          AuthErrorKind.invalidCredentials,
          'Invalid login credentials',
        ),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.enterText(find.byKey(UiKeys.accountEmail), 'a@b.com');
      await tester.enterText(find.byKey(UiKeys.accountPassword), 'wrong');
      await tester.tap(find.byKey(UiKeys.accountSignIn));
      await tester.pumpAndSettle();

      expect(find.text(l10n.authErrorInvalidCredentials), findsOneWidget);
      expect(controller.syncs, 0, reason: 'there was nothing to sync with');
      expect(find.byKey(UiKeys.accountEmail), findsOneWidget);
    });

    testWidgets('a second account is refused in words it explains',
        (tester) async {
      // The one failure here that is a decision rather than a fault, and
      // the one most likely to be read as a bug.
      await open(
        tester,
        onSignIn: (email, password) async =>
            throw const ForeignAccount(owner: 'user-1', attempted: 'user-2'),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.enterText(find.byKey(UiKeys.accountEmail), 'b@b.com');
      await tester.enterText(find.byKey(UiKeys.accountPassword), 'hunter2');
      await tester.tap(find.byKey(UiKeys.accountSignIn));
      await tester.pumpAndSettle();

      expect(find.text(l10n.authErrorForeignAccount), findsOneWidget);
    });

    testWidgets('a device that has signed in before says whose it is',
        (tester) async {
      // Reassurance rather than decoration: the training is still here, and
      // a bare sign-in form would not say so.
      await open(tester, initial: returning);
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(
        find.text(l10n.accountSignedOutOf('a@example.com')),
        findsOneWidget,
      );
    });
  });

  group('signed in', () {
    testWidgets('says who, and offers a sync and a way out', (tester) async {
      await open(tester, initial: signedIn);
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(
        find.text(l10n.accountSignedInAs('a@example.com')),
        findsOneWidget,
      );
      expect(find.byKey(UiKeys.accountSyncNow), findsOneWidget);
      expect(find.byKey(UiKeys.accountSignOut), findsOneWidget);
      expect(find.byKey(UiKeys.accountEmail), findsNothing);
    });

    testWidgets('syncing says what it did', (tester) async {
      final controller = await open(
        tester,
        initial: signedIn,
        onSync: () async => const SyncReport(
          tables: [
            TableSyncReport(
              table: 'profiles',
              pulled: 2,
              applied: 2,
              pushed: 3,
              conflicts: 0,
              conflictsLostLocally: 0,
            ),
          ],
        ),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.tap(find.byKey(UiKeys.accountSyncNow));
      await tester.pumpAndSettle();

      expect(controller.syncs, 1);
      expect(find.byKey(UiKeys.accountResult), findsOneWidget);
      expect(find.text(l10n.accountSyncedCounts(3, 2)), findsOneWidget);
    });

    testWidgets('a sync that stopped half way says both halves',
        (tester) async {
      // What it managed, then why it stopped. Leading with the failure
      // would read as though the work had been lost.
      await open(
        tester,
        initial: signedIn,
        onSync: () async => const SyncReport(
          tables: [
            TableSyncReport(
              table: 'profiles',
              pulled: 0,
              applied: 0,
              pushed: 1,
              conflicts: 0,
              conflictsLostLocally: 0,
            ),
          ],
          error: SyncError(
            kind: SyncErrorKind.offline,
            table: 'plans',
            message: 'no route to host',
          ),
        ),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.tap(find.byKey(UiKeys.accountSyncNow));
      await tester.pumpAndSettle();

      expect(find.text(l10n.accountSyncedCounts(1, 0)), findsOneWidget);
      expect(find.text(l10n.accountSyncStoppedOffline), findsOneWidget);
    });

    testWidgets('signing out brings the form back', (tester) async {
      final controller = await open(tester, initial: signedIn);

      await tester.tap(find.byKey(UiKeys.accountSignOut));
      await tester.pumpAndSettle();

      expect(controller.signOuts, 1);
      expect(find.byKey(UiKeys.accountEmail), findsOneWidget);
      expect(find.byKey(UiKeys.accountSyncNow), findsNothing);
    });
  });

  group('handing the phone on', () {
    testWidgets('a signed-in device offers it', (tester) async {
      await open(tester, initial: signedIn);

      expect(find.byKey(UiKeys.accountErase), findsOneWidget);
    });

    testWidgets('and so does one that is signed out but still owned',
        (tester) async {
      // The state somebody is in the moment the refusal happens, and the
      // one they most need it from. Below the sign-in form rather than
      // above it: it is the destructive thing on this screen and signing in
      // is what almost everybody came to do.
      await open(tester, initial: returning);
      await scrollToBottom(tester);

      expect(find.byKey(UiKeys.accountErase), findsOneWidget);
    });

    testWidgets('a device nobody has ever signed in on does not',
        (tester) async {
      // There is nothing to hand over and nobody is stuck: an erase button
      // here would be a delete-everything button on a screen about sync.
      await open(tester);

      expect(find.byKey(UiKeys.accountErase), findsNothing);
    });

    testWidgets('the refusal and the way out are on screen together',
        (tester) async {
      // The whole point of the feature. A refusal with no way past it is
      // what this closed.
      final controller = await open(
        tester,
        initial: returning,
        onSignIn: (email, password) async =>
            throw const ForeignAccount(owner: 'user-1', attempted: 'user-2'),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.enterText(find.byKey(UiKeys.accountEmail), 'b@b.com');
      await tester.enterText(find.byKey(UiKeys.accountPassword), 'hunter2');
      await tester.tap(find.byKey(UiKeys.accountSignIn));
      await tester.pumpAndSettle();

      expect(find.text(l10n.authErrorForeignAccount), findsOneWidget);
      await scrollToBottom(tester);
      expect(find.byKey(UiKeys.accountErase), findsOneWidget);
      expect(controller.erases, 0);
    });

    testWidgets('asks first, and says what it does and does not do',
        (tester) async {
      final controller = await open(tester, initial: signedIn);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.tap(find.byKey(UiKeys.accountErase));
      await tester.pumpAndSettle();

      expect(find.text(l10n.accountEraseConfirmBody), findsOneWidget);
      expect(controller.erases, 0, reason: 'nothing until it is confirmed');
      // Pinned, not decoration. Somebody doing this is deleting their
      // training off a phone, and the two things they need to know are that
      // this device cannot undo it and that their account still has it.
      expect(l10n.accountEraseConfirmBody, contains('no undo'));
      expect(l10n.accountEraseConfirmBody, contains('stays in the account'));
    });

    testWidgets('cancelling erases nothing', (tester) async {
      final controller = await open(tester, initial: signedIn);

      await tester.tap(find.byKey(UiKeys.accountErase));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UiKeys.accountEraseCancel));
      await tester.pumpAndSettle();

      expect(controller.erases, 0);
      expect(find.byKey(UiKeys.accountEraseConfirm), findsNothing);
      expect(find.byKey(UiKeys.accountSyncNow), findsOneWidget);
    });

    testWidgets('confirming erases it, and the screen says so',
        (tester) async {
      final controller = await open(tester, initial: signedIn);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.tap(find.byKey(UiKeys.accountErase));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UiKeys.accountEraseConfirm));
      await tester.pumpAndSettle();

      expect(controller.erases, 1);
      expect(find.text(l10n.accountErased), findsOneWidget);
      // Back to an empty device offering a sign-in: nobody is signed in,
      // nobody owns it, and there is nothing left to erase.
      expect(find.byKey(UiKeys.accountEmail), findsOneWidget);
      expect(find.byKey(UiKeys.accountErase), findsNothing);
    });

    testWidgets('an erase that failed says the training is still here',
        (tester) async {
      // Not a cosmetic difference. The owner is released last, so a failure
      // leaves the device owned and still refusing the other account —
      // which is recoverable, and only if the screen says so.
      await open(
        tester,
        initial: signedIn,
        onErase: () async => throw StateError('database is locked'),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.tap(find.byKey(UiKeys.accountErase));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UiKeys.accountEraseConfirm));
      await tester.pumpAndSettle();

      expect(find.text(l10n.accountEraseFailed), findsOneWidget);
      expect(find.byKey(UiKeys.accountErase), findsOneWidget);
    });
  });

  group('getting to it', () {
    testWidgets('the plan screen has a way in', (tester) async {
      final profile = onboardedProfile();
      await pumpApp(
        tester,
        profile: profile,
        plan: PlanGenerator(standardCatalog).generate(profile.toPlanRequest()),
        overrides: [
          supabaseConfigProvider.overrideWithValue(config),
          accountControllerProvider.overrideWithValue(
            RecordingAccountController(),
          ),
        ],
      );

      await tester.tap(find.byKey(UiKeys.planOpenAccount));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.accountScreen), findsOneWidget);
    });
  });
}
