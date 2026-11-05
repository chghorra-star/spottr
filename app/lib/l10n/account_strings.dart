import 'package:flutter/widgets.dart';
import 'package:sync_engine/sync_engine.dart';

import '../data/local/local_identity_store.dart';
import '../data/sync/supabase_auth.dart';
import 'app_localizations.dart';

/// Turns what the sync and the auth client report into sentences.
///
/// The same seam `PlanStrings` is: everything below the UI deals in values —
/// an [AuthErrorKind], a [SyncReport] — and never in prose, so this is the
/// one place they become words. Free of `BuildContext`, so a test can walk
/// every value and prove none of them comes out blank.
///
/// What makes this worth a file of its own is that most of these sentences
/// are the difference between an app that looks broken and one that
/// explains itself. "Something went wrong" is the wrong answer to a
/// mistyped password, to an email that already has an account, and to a
/// train going through a tunnel.
@immutable
class AccountStrings {
  const AccountStrings(this.l10n);

  factory AccountStrings.of(BuildContext context) =>
      AccountStrings(AppLocalizations.of(context));

  final AppLocalizations l10n;

  /// Why a sign-in or a sign-up did not work.
  ///
  /// Takes an [Object] rather than an [AuthException] because the one thing
  /// that is not an auth failure — this device already holding somebody
  /// else's training — reaches the screen the same way and is the single
  /// most important of these sentences to get right.
  String authError(Object error) {
    if (error is ForeignAccount) return l10n.authErrorForeignAccount;

    if (error is AuthException) {
      return switch (error.kind) {
        AuthErrorKind.invalidCredentials => l10n.authErrorInvalidCredentials,
        AuthErrorKind.emailTaken => l10n.authErrorEmailTaken,
        // The server's own words: the minimum length is a project setting,
        // and a sentence invented here would be wrong the day it changes.
        AuthErrorKind.weakPassword =>
          l10n.authErrorWeakPassword(error.message),
        AuthErrorKind.confirmationRequired =>
          l10n.authErrorConfirmationRequired,
        AuthErrorKind.offline => l10n.authErrorOffline,
        AuthErrorKind.rejected => l10n.authErrorRejected(error.message),
      };
    }

    return l10n.authErrorRejected('$error');
  }

  /// What a finished sync actually did, as lines.
  ///
  /// Lines rather than a sentence, because up to three separate things are
  /// worth saying and only one of them is usually true: what moved, whether
  /// anything was resolved in favour of one device, and whether it stopped
  /// early. A sync that stopped half way is not a failed sync — what it
  /// managed is kept, and the next one resumes — so the counts come first
  /// and the reason it stopped comes after them.
  List<String> syncResult(SyncReport report) {
    final lines = <String>[
      if (report.applied == 0 && report.pushed == 0)
        l10n.accountSyncedNothing
      else
        l10n.accountSyncedCounts(report.pushed, report.applied),
    ];

    // Said out loud, because last-writer-wins discards the loser's edit and
    // a user who cannot see that it happened cannot tell us about it.
    if (report.conflicts > 0) {
      lines.add(l10n.accountSyncConflicts(report.conflicts));
    }

    final error = report.error;
    if (error != null) {
      lines.add(switch (error.kind) {
        SyncErrorKind.offline => l10n.accountSyncStoppedOffline,
        SyncErrorKind.unauthorized => l10n.accountSyncStoppedUnauthorized,
        SyncErrorKind.rejected =>
          l10n.accountSyncStoppedRejected(error.message),
      });
    }

    return lines;
  }
}
