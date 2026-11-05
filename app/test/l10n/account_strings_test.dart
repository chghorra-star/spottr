import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/local/local_identity_store.dart';
import 'package:spottr/data/sync/supabase_auth.dart';
import 'package:spottr/l10n/account_strings.dart';
import 'package:spottr/l10n/app_localizations.dart';
import 'package:sync_engine/sync_engine.dart';

/// Walks every value rather than sampling, the way the other strings tests
/// do. A missing case here is a blank line on screen at the moment somebody
/// is trying to work out why they cannot sign in.
void main() {
  late AccountStrings strings;

  setUp(() => strings = AccountStrings(lookupAppLocalizations(const Locale('en'))));

  group('a sign-in that did not work', () {
    test('has something to say about every reason', () {
      final sentences = <String>[];
      for (final kind in AuthErrorKind.values) {
        final sentence = strings.authError(
          AuthException(kind, 'at least 8 characters'),
        );
        expect(sentence, isNotEmpty, reason: '$kind has no sentence');
        sentences.add(sentence);
      }

      expect(
        sentences.toSet().length,
        AuthErrorKind.values.length,
        reason: 'two reasons share a sentence, so one of them is wrong',
      );
    });

    test('tells a wrong password apart from an address already in use', () {
      // The two most common, and the two that are useless if swapped.
      final wrong = strings.authError(
        const AuthException(AuthErrorKind.invalidCredentials, 'nope'),
      );
      final taken = strings.authError(
        const AuthException(AuthErrorKind.emailTaken, 'nope'),
      );

      expect(wrong.toLowerCase(), contains('do not match'));
      expect(taken.toLowerCase(), contains('already'));
    });

    test('repeats the server words where the rule is the server', () {
      // The password minimum is a project setting. A sentence invented here
      // would be wrong the day somebody changes it.
      final sentence = strings.authError(
        const AuthException(
          AuthErrorKind.weakPassword,
          'Password should be at least 8 characters',
        ),
      );

      expect(sentence, contains('at least 8 characters'));
    });

    test('says plainly why a second account is refused', () {
      // The one failure here that is not an auth failure, and the one most
      // likely to look like a bug rather than a decision.
      final sentence = strings.authError(
        const ForeignAccount(owner: 'user-1', attempted: 'user-2'),
      );

      expect(sentence.toLowerCase(), contains('another account'));
      expect(sentence, isNot(contains('user-1')), reason: 'no raw ids');
    });

    test('and has something to say about anything else at all', () {
      expect(strings.authError(StateError('odd')), isNotEmpty);
    });
  });

  group('a finished sync', () {
    SyncReport report({
      int pushed = 0,
      int applied = 0,
      int conflicts = 0,
      SyncError? error,
    }) {
      return SyncReport(
        tables: [
          TableSyncReport(
            table: 'profiles',
            pulled: applied,
            applied: applied,
            pushed: pushed,
            conflicts: conflicts,
            conflictsLostLocally: conflicts,
          ),
        ],
        error: error,
      );
    }

    test('says so when there was nothing to do', () {
      // Which is what a sync looks like almost every time it runs, so the
      // line has to read as success rather than as an absence.
      expect(strings.syncResult(report()), [
        isNot(contains('0')),
      ]);
    });

    test('says what moved when something did', () {
      final lines = strings.syncResult(report(pushed: 3, applied: 2));

      expect(lines, hasLength(1));
      expect(lines.single, contains('3'));
      expect(lines.single, contains('2'));
    });

    test('says out loud when an edit was discarded', () {
      // Last-writer-wins throws the loser's work away. Somebody who cannot
      // see that happen cannot tell us it happened to them.
      final one = strings.syncResult(report(applied: 1, conflicts: 1));
      final many = strings.syncResult(report(applied: 4, conflicts: 3));

      expect(one, hasLength(2));
      expect(one.last.toLowerCase(), contains('two places'));
      expect(many.last, contains('3'));
    });

    test('has something to say about every way it can stop', () {
      final sentences = <String>[];
      for (final kind in SyncErrorKind.values) {
        final lines = strings.syncResult(
          report(
            pushed: 1,
            error: SyncError(
              kind: kind,
              table: 'set_logs',
              message: 'violates foreign key constraint',
            ),
          ),
        );
        expect(lines, hasLength(2), reason: '$kind said nothing');
        sentences.add(lines.last);
      }

      expect(sentences.toSet().length, SyncErrorKind.values.length);
    });

    test('a sync that stopped still reports what it managed', () {
      // Half a sync is not a failed sync: what it moved is kept and the
      // next one resumes. Leading with the failure would read as though the
      // work had been lost.
      final lines = strings.syncResult(
        report(
          pushed: 5,
          error: const SyncError(
            kind: SyncErrorKind.offline,
            table: 'sessions',
            message: 'no route to host',
          ),
        ),
      );

      expect(lines.first, contains('5'));
      expect(lines.last.toLowerCase(), contains('no connection'));
    });

    test('an expired sign-in asks for a sign-in', () {
      final lines = strings.syncResult(
        report(
          error: const SyncError(
            kind: SyncErrorKind.unauthorized,
            table: 'profiles',
            message: 'JWT expired',
          ),
        ),
      );

      expect(lines.last.toLowerCase(), contains('sign in'));
    });
  });
}
