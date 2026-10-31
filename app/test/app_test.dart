import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/l10n/app_localizations.dart';
import 'package:spottr/theme/app_theme.dart';
import 'package:spottr/ui/onboarding/onboarding_screen.dart';

import 'support/pump.dart';

void main() {
  testWidgets('boots into onboarding with the real widget wiring',
      (tester) async {
    // A smoke test for the shell: localizations resolve, the theme applies,
    // and routing reaches a screen. What it deliberately does not cover is
    // opening the on-device database, which needs a real platform and is
    // substituted here; the repositories test that against SQLite.
    await pumpApp(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('resolves every string through the ARB bundle', (tester) async {
    // Guards the "all strings externalized" rule: if a key is dropped from
    // the ARB the generated getter disappears and this stops compiling.
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(l10n.appTitle, 'Spottr');
    expect(l10n.painButton, isNotEmpty);
    expect(l10n.disclaimerBody, contains('not medical advice'));
    expect(l10n.repsRemaining(1), 'Last one');
    expect(l10n.repsRemaining(3), '3 to go');
    expect(l10n.repsCounted(0), 'No reps counted');
    expect(l10n.repsCounted(1), '1 rep');
    expect(l10n.repsCounted(8), '8 reps');
    expect(l10n.formScoreLabel(92), 'Form 92%');
    expect(l10n.planDaySummary(1, 42), '1 exercise · about 42 min');
    expect(l10n.planDaySummary(5, 42), '5 exercises · about 42 min');
    expect(l10n.planSetsReps(3, 8, 12), '3 × 8–12');
    expect(l10n.planSetsHold(3, 45), '3 × 45s hold');
  });

  group('safety wording', () {
    /// These sentences are the product's position on what the camera coach
    /// does, and they are deliberately pinned. Softening "cannot guarantee"
    /// into a promise, or dropping the advice to see a professional, would
    /// be a change of claim rather than a change of copy.
    late AppLocalizations l10n;

    setUp(() => l10n = lookupAppLocalizations(const Locale('en')));

    test('the disclaimer promises feedback, never prevention', () {
      expect(l10n.disclaimerBody, contains('cannot guarantee'));
      expect(l10n.disclaimerBody, contains('not medical advice'));
      expect(l10n.disclaimerBody.toLowerCase(), isNot(contains('prevent injury')));
    });

    test('the disclaimer points at a professional', () {
      expect(
        l10n.disclaimerBody.toLowerCase(),
        anyOf(contains('doctor'), contains('physiotherapist')),
      );
    });

    test('the injury question repeats that this is not medical advice', () {
      expect(l10n.stepInjuriesBody, contains('not medical advice'));
    });

    test('the run-days question says Spottr does not track runs', () {
      expect(l10n.stepRunDaysBody.toLowerCase(), contains('never tracks'));
      expect(l10n.goalHybridDetail.toLowerCase(), contains('does not track'));
    });

    test('the tough coach is blunt but never tells anyone to push through '
        'pain', () {
      expect(l10n.coachStyleToughDetail, contains('Never'));
      expect(l10n.coachStyleToughDetail.toLowerCase(), contains('pain'));
    });
  });

  group('theme', () {
    test('both themes carry the form severity palette', () {
      // The camera HUD reads these by severity. A theme without the
      // extension would throw at the worst possible moment: mid-set.
      for (final theme in [AppTheme.dark, AppTheme.light]) {
        final colors = theme.extension<FormSeverityColors>();
        expect(colors, isNotNull, reason: 'missing FormSeverityColors');
        expect(colors!.good, isNot(colors.unsafe));
      }
    });

    test('severity colors are distinct from one another', () {
      final colors = AppTheme.dark.extension<FormSeverityColors>()!;
      final swatch = {colors.good, colors.minor, colors.major, colors.unsafe};
      expect(swatch.length, 4, reason: 'two severities share a color');
    });
  });
}
