import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../common/ui_keys.dart';

/// Drag the exercises of one day into the order the user wants.
///
/// Reordering deliberately does not re-apply the day rules: a session the
/// user trimmed by hand should not grow back to full volume because they
/// dragged a row. The copy says so.
class ReorderDayScreen extends ConsumerWidget {
  const ReorderDayScreen({required this.weekday, super.key});

  final int weekday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));
    final plan = ref.watch(activePlanProvider).value;
    final day = plan?.days.where((d) => d.weekday == weekday).firstOrNull;

    if (day == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.planActionReorder)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.weekday(weekday)} · ${strings.day(day.labelKey)}'),
        actions: [
          TextButton(
            key: UiKeys.planReorderDone,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.planReorderDone),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.planReorderHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: day.exercises.length,
              itemBuilder: (context, index) {
                final exercise = day.exercises[index];
                return ListTile(
                  key: ValueKey(exercise.exerciseId),
                  title: Text(strings.exercise(exercise.exerciseId)),
                  subtitle: Text(strings.prescription(exercise)),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                );
              },
              // onReorderItem, rather than the older onReorder: it hands
              // over a destination index that already accounts for the
              // row having been lifted out, so there is no off-by-one to
              // get wrong here.
              onReorderItem: (from, to) =>
                  ref.read(planControllerProvider).reorder(
                        weekday: weekday,
                        fromIndex: from,
                        toIndex: to,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
