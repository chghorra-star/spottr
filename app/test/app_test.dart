import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/app.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/l10n/app_localizations.dart';
import 'package:spottr/theme/app_theme.dart';

import 'support/test_database.dart';

void main() {
  testWidgets('boots and renders its localized title', (tester) async {
    final db = openTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const SpottrApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spottr'), findsWidgets);
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
