import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../common/choice_tile.dart';
import '../common/ui_keys.dart';

/// Moves a session to another weekday.
///
/// Days that already hold a session are shown but not selectable, and run
/// days are labelled, because moving a session onto one is allowed but
/// worth knowing about. The leg-volume rule is re-applied after the move by
/// the plan engine, not here.
Future<void> showMoveDaySheet(
  BuildContext context, {
  required int fromWeekday,
}) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _MoveDaySheet(fromWeekday: fromWeekday),
    );

class _MoveDaySheet extends ConsumerWidget {
  const _MoveDaySheet({required this.fromWeekday});

  final int fromWeekday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));
    final plan = ref.watch(activePlanProvider).value;

    if (plan == null) return const SizedBox.shrink();

    final day = plan.days.firstWhere((d) => d.weekday == fromWeekday);
    final taken = plan.days.map((d) => d.weekday).toSet();

    return SafeArea(
      child: Padding(
        key: UiKeys.moveDaySheet,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: QuestionSection(
            title: l10n.moveDayTitle(strings.day(day.labelKey)),
            body: l10n.moveDayBody,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                ChoiceTile(
                  key: UiKeys.moveDayOption(weekday),
                  title: strings.weekday(weekday),
                  detail: _detail(l10n, plan.runWeekdays, taken, weekday),
                  selected: weekday == fromWeekday,
                  onTap: taken.contains(weekday)
                      ? () {}
                      : () => _move(context, ref, weekday),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _detail(
    AppLocalizations l10n,
    Set<int> runDays,
    Set<int> taken,
    int weekday,
  ) {
    if (weekday != fromWeekday && taken.contains(weekday)) {
      return l10n.moveDayOccupied;
    }
    if (runDays.contains(weekday)) return l10n.moveDayIsRunDay;
    return null;
  }

  Future<void> _move(BuildContext context, WidgetRef ref, int to) async {
    final navigator = Navigator.of(context);
    await ref.read(planControllerProvider).moveDay(
          fromWeekday: fromWeekday,
          toWeekday: to,
        );
    if (navigator.canPop()) navigator.pop();
  }
}
