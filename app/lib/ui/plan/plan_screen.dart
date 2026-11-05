import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../account/account_screen.dart';
import '../common/async_view.dart';
import '../common/ui_keys.dart';
import '../profile/profile_screen.dart';
import 'day_card.dart';

/// The week, as the user sees it.
///
/// The plan notes get their own section rather than being hidden: a week
/// that is short because the catalog could not fill a slot, or that is
/// full-body because a split would have collapsed, should look explained
/// instead of looking broken.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider);
    final l10n = AppLocalizations.of(context);

    return AsyncView<WeekPlan?>(
      value: plan,
      onRetry: () => ref.invalidate(activePlanProvider),
      builder: (context, data) => data == null
          ? EmptyPanel(
              key: UiKeys.planEmpty,
              title: l10n.planEmptyTitle,
              body: l10n.planEmptyBody,
              actionLabel: l10n.planEmptyAction,
              onAction: () =>
                  ref.read(planControllerProvider).regenerate(),
            )
          : _PlanBody(plan: data),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.plan});

  final WeekPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    return CustomScrollView(
      key: UiKeys.planScreen,
      slivers: [
        SliverAppBar.large(
          title: Text(l10n.planTitle),
          actions: [
            IconButton(
              key: UiKeys.planOpenProfile,
              icon: const Icon(Icons.person_outline),
              tooltip: l10n.profileTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ProfileScreen(),
                ),
              ),
            ),
            IconButton(
              key: UiKeys.planOpenAccount,
              icon: const Icon(Icons.cloud_outlined),
              tooltip: l10n.accountTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AccountScreen(),
                ),
              ),
            ),
            IconButton(
              key: UiKeys.planRebuild,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.planRegenerate,
              onPressed: () => _confirmRebuild(context, ref),
            ),
          ],
        ),
        SliverList.builder(
          itemCount: plan.days.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 8, 16, 8),
            child: DayCard(day: plan.days[index], strings: strings),
          ),
        ),
        if (plan.runSuggestionKeys.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              key: UiKeys.planRunSuggestions,
              title: l10n.planRunSuggestionsTitle,
              lines: _runLines(strings),
            ),
          ),
        if (plan.notes.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              key: UiKeys.planNotes,
              title: l10n.planNotesTitle,
              lines: [for (final note in plan.notes) strings.note(note)],
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  /// One line per run day, each naming its day.
  ///
  /// The generator emits one suggestion per run day and, at a given
  /// experience level, they are the same suggestion — so without the day in
  /// front of it the section reads as the same sentence printed twice.
  List<String> _runLines(PlanStrings strings) {
    final days = plan.runWeekdays.toList()..sort();
    return [
      for (var index = 0; index < plan.runSuggestionKeys.length; index++)
        if (index < days.length)
          '${strings.weekday(days[index])} · '
              '${strings.runSuggestion(plan.runSuggestionKeys[index])}'
        else
          strings.runSuggestion(plan.runSuggestionKeys[index]),
    ];
  }

  /// Rebuilding discards every swap and reorder, so it asks first.
  Future<void> _confirmRebuild(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planRegenerate),
        content: Text(l10n.planRegenerateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.planCancel),
          ),
          FilledButton(
            key: UiKeys.planRebuildConfirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.planRegenerateConfirm),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(planControllerProvider).regenerate();
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines, super.key});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(line, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
