import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'ui_keys.dart';

/// Renders an [AsyncValue] as one of loading, error, or data.
///
/// Local-first means reads are fast, not instant — the first frame after a
/// cold start has no profile yet. Routing that through one widget keeps the
/// three states consistent everywhere and keeps the "did we handle the
/// error case" question answerable by looking in one file.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  final AsyncValue<T> value;

  /// Invalidates whatever produced [value]. The error state is useless
  /// without a way out of it.
  final VoidCallback onRetry;

  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(
          key: UiKeys.loading,
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => ErrorPanel(
          error: error,
          onRetry: onRetry,
        ),
        data: (data) => builder(context, data),
      );
}

/// What the user sees when something the app needs could not be read.
///
/// The message shows the underlying error on purpose. The failures that
/// reach here are a corrupt row or a storage problem, and a bare "something
/// went wrong" would leave the one person who could report it with nothing
/// to report.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      key: UiKeys.errorPanel,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.planErrorTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: UiKeys.retry,
              onPressed: onRetry,
              child: Text(l10n.planErrorRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-screen "nothing here yet" state with one action.
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
