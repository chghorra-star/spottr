import 'package:meta/meta.dart';

import 'templates.dart';

/// One training day placed on a weekday.
@immutable
class ScheduledDay {
  const ScheduledDay({
    required this.weekday,
    required this.type,
    required this.labelKey,
    required this.template,
    required this.precedesRunDay,
  });

  /// ISO weekday, 1 = Monday through 7 = Sunday.
  final int weekday;

  final DayType type;
  final String labelKey;
  final DayTemplate template;

  /// Whether a run is scheduled for the following day.
  ///
  /// The generator lightens leg work on these days when placement alone
  /// could not avoid the clash.
  final bool precedesRunDay;
}

/// A week of training days, ordered by weekday.
@immutable
class WeekSchedule {
  const WeekSchedule(this.templateId, this.days);

  final String templateId;
  final List<ScheduledDay> days;
}

/// Places a week template onto actual weekdays.
///
/// Two jobs: keep sessions off the user's run days where the week has room,
/// and rotate the template so that leg-heavy days avoid the slot immediately
/// before a run.
abstract final class PlanScheduler {
  /// Classic spreads that leave the most recovery between sessions.
  static const Map<int, List<int>> _basePattern = {
    2: [1, 4],
    3: [1, 3, 5],
    4: [1, 2, 4, 5],
    5: [1, 2, 3, 5, 6],
    6: [1, 2, 3, 4, 5, 6],
  };

  static WeekSchedule schedule({
    required WeekTemplate template,
    required Set<int> runWeekdays,
  }) {
    final weekdays = _assignWeekdays(template.daysPerWeek, runWeekdays);
    final precedesRun = [
      for (final weekday in weekdays) runWeekdays.contains(_nextDay(weekday)),
    ];

    final rotated = template.rotated(
      _bestRotation(template, precedesRun),
    );

    return WeekSchedule(template.id, [
      for (var i = 0; i < weekdays.length; i++)
        ScheduledDay(
          weekday: weekdays[i],
          type: rotated.days[i].type,
          labelKey: rotated.days[i].labelKey,
          template: rotated.days[i],
          precedesRunDay: precedesRun[i],
        ),
    ]);
  }

  /// Weekdays for [daysPerWeek] sessions, avoiding [runWeekdays] where the
  /// week has a free day to move to.
  ///
  /// A session only ends up sharing a day with a run when every non-run day
  /// is already taken, which is the honest outcome for six gym days and
  /// three run days.
  static List<int> _assignWeekdays(int daysPerWeek, Set<int> runWeekdays) {
    final base = _basePattern[daysPerWeek]!;
    final chosen = base.toList();
    final used = chosen.toSet();

    for (var i = 0; i < chosen.length; i++) {
      final weekday = chosen[i];
      if (!runWeekdays.contains(weekday)) continue;

      final replacement = _nearestFreeDay(
        from: weekday,
        used: used.difference({weekday}),
        runWeekdays: runWeekdays,
      );
      if (replacement == null) continue; // week is full; share the day

      used.remove(weekday);
      used.add(replacement);
      chosen[i] = replacement;
    }

    return chosen..sort();
  }

  /// The closest weekday to [from] that is neither used nor a run day.
  ///
  /// Ties break later in the week, which keeps the spread wider.
  static int? _nearestFreeDay({
    required int from,
    required Set<int> used,
    required Set<int> runWeekdays,
  }) {
    int? best;
    var bestDistance = 99;
    // Ascending iteration plus `<=` means an equally close later day wins.
    for (var weekday = 1; weekday <= 7; weekday++) {
      if (used.contains(weekday) || runWeekdays.contains(weekday)) continue;
      final distance = (weekday - from).abs();
      if (best == null || distance <= bestDistance) {
        best = weekday;
        bestDistance = distance;
      }
    }
    return best;
  }

  /// The rotation that puts the least leg work on pre-run days.
  ///
  /// Ties break to the smallest rotation so that a week with no runs keeps
  /// the template's natural order.
  static int _bestRotation(WeekTemplate template, List<bool> precedesRun) {
    if (!precedesRun.contains(true)) return 0;

    var bestRotation = 0;
    var bestConflict = double.infinity;
    for (var rotation = 0; rotation < template.daysPerWeek; rotation++) {
      final candidate = template.rotated(rotation);
      var conflict = 0.0;
      for (var i = 0; i < precedesRun.length; i++) {
        if (precedesRun[i]) conflict += candidate.days[i].legEmphasis;
      }
      if (conflict < bestConflict) {
        bestConflict = conflict;
        bestRotation = rotation;
      }
    }
    return bestRotation;
  }

  /// The weekday after [weekday], wrapping Sunday to Monday.
  static int _nextDay(int weekday) => (weekday % 7) + 1;
}
