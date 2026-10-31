import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'ui/app_router.dart';

/// Root widget. Expects to be mounted inside a `ProviderScope`.
class SpottrApp extends StatelessWidget {
  const SpottrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AppRouter(),
    );
  }
}
