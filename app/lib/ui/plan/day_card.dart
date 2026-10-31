import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../common/ui_keys.dart';
import 'move_day_sheet.dart';
import 'reorder_day_screen.dart';
import 'swap_sheet.dart';

/// One training day: what it is, how long it should take, and what is in it.
class DayCard extends ConsumerWidget {
  const DayCard({required this.day, required this.strings, super.key});

  final PlannedDay day;
  final PlanStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      key: UiKeys.planDay(day.weekday),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.weekday(day.weekday)} · '
                          '${strings.day(day.labelKey)}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.planDaySummary(
                            day.exercises.length,
                            day.estimatedMinutes,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (day.precedesRunDay) ...[
                          const SizedBox(height: 6),
                          _Badge(
                            label: l10n.planPreRunBadge,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_vert),
                    tooltip: l10n.planActionReorder,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            ReorderDayScreen(weekday: day.weekday),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    tooltip: l10n.planActionMoveDay,
                    onPressed: () => showMoveDaySheet(
                      context,
                      fromWeekday: day.weekday,
                    ),
                  ),
                ],
              ),
            ),
            for (final exercise in day.exercises)
              _ExerciseRow(
                day: day,
                exercise: exercise,
                strings: strings,
                cameraSupported: ref
                    .watch(catalogProvider)
                    .require(exercise.exerciseId)
                    .isCameraSupported,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.day,
    required this.exercise,
    required this.strings,
    required this.cameraSupported,
  });

  final PlannedDay day;
  final PlannedExercise exercise;
  final PlanStrings strings;
  final bool cameraSupported;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      title: Row(
        children: [
          Expanded(child: Text(strings.exercise(exercise.exerciseId))),
          if (cameraSupported)
            Tooltip(
              message: l10n.planCameraCoachedDetail,
              child: Icon(
                Icons.videocam_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${strings.prescription(exercise)} · '
        '${l10n.planRestBetweenSets(exercise.restSeconds)}',
      ),
      trailing: IconButton(
        key: UiKeys.planExerciseMenu(day.weekday, exercise.exerciseId),
        icon: const Icon(Icons.swap_horiz),
        tooltip: l10n.planActionSwap,
        onPressed: () => showSwapSheet(
          context,
          weekday: day.weekday,
          exerciseId: exercise.exerciseId,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      );
}
