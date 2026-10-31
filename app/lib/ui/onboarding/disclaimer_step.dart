import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../common/ui_keys.dart';

/// The safety disclaimer, shown before anything else and impossible to get
/// past without accepting.
///
/// The wording is the product's position, not boilerplate: Spottr gives
/// form feedback and flags movement that looks risky, and it says plainly
/// that it is not medical advice and cannot promise to prevent injury.
/// Nothing in this screen may be softened into a claim it does not make.
class DisclaimerStep extends StatelessWidget {
  const DisclaimerStep({
    required this.accepted,
    required this.onAccept,
    super.key,
  });

  final bool accepted;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.disclaimerTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(l10n.disclaimerBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 32),
        Material(
          color: accepted
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: UiKeys.disclaimerAccept,
            onTap: onAccept,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    accepted
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: accepted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.disclaimerAccept,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!accepted) ...[
          const SizedBox(height: 12),
          Text(
            l10n.disclaimerRequired,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
