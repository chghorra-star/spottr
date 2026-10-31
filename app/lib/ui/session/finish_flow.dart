import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../common/ui_keys.dart';

/// Asks how the session felt, closes it, and shows what it earned.
///
/// The rating is asked before the summary because it feeds the decisions in
/// it: the user's own verdict outranks the rep count, and asking afterwards
/// would mean showing them numbers and then changing them.
///
/// Leaves the session screen behind on the way, and does nothing at all if
/// the user backs out of the question.
/// Nothing here touches [ref] after an `await`. By the time the session is
/// closed the screen that owns the ref is being torn down, and Riverpod
/// rightly refuses to be read through a dead widget — so everything this
/// flow needs is taken out of it up front.
Future<void> runFinishFlow(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context);
  final catalog = ref.read(catalogProvider);
  final sessions = ref.read(sessionControllerProvider);

  final rating = await _askRating(context, catalog);
  if (rating == null) return;

  final decisions = await sessions.finish(rating: rating.value);

  // The session screen goes first, and the summary is shown from the
  // navigator rather than from it. Closing the session empties the stream
  // that screen is built from, so its own context is already gone by the
  // time there is anything to show — and the week is a better place to read
  // "next time" than a workout that is over.
  await navigator.maybePop();
  if (!navigator.mounted) return;
  await _showSummary(navigator.context, catalog, decisions);
}

/// A rating, or the explicit refusal to give one.
///
/// Wrapped rather than nullable so that "rather not say" is distinguishable
/// from dismissing the sheet — one closes the session with no opinion, the
/// other leaves it open.
class _Answer {
  const _Answer(this.value);

  final SessionRating? value;
}

Future<_Answer?> _askRating(BuildContext context, ExerciseCatalog catalog) {
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet<_Answer>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final strings = PlanStrings.of(context, catalog);

      return SafeArea(
        key: UiKeys.sessionRatingSheet,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.sessionRatingTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.sessionRatingBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final rating in SessionRating.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: UiKeys.sessionRating(rating.name),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(strings.rating(rating)),
                    subtitle: Text(strings.ratingDetail(rating)),
                    onTap: () => Navigator.of(context).pop(_Answer(rating)),
                  ),
                ),
              TextButton(
                key: UiKeys.sessionRatingSkip,
                onPressed: () => Navigator.of(context).pop(const _Answer(null)),
                child: Text(l10n.sessionRatingSkip),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// What changes next time, one line per exercise.
///
/// Every decision is shown, including the ones that changed nothing: a
/// summary that only listed increases would make a steady session look like
/// a session the app ignored.
Future<void> _showSummary(
  BuildContext context,
  ExerciseCatalog catalog,
  List<ProgressionDecision> decisions,
) {
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final strings = PlanStrings.of(context, catalog);

      return SafeArea(
        key: UiKeys.sessionSummary,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.sessionSummaryTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              if (decisions.isEmpty)
                Text(
                  l10n.sessionSummaryEmpty,
                  style: theme.textTheme.bodyMedium,
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final decision in decisions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.exercise(decision.exerciseId),
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.progression(decision),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: decision.changesAnything
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                key: UiKeys.sessionSummaryDone,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.sessionSummaryDone),
              ),
            ],
          ),
        ),
      );
    },
  );
}
