import 'package:exercise_library/exercise_library.dart';
import 'package:meta/meta.dart';

/// The kind of session a training day is.
enum DayType { fullBody, upper, lower, push, pull, legs }

/// How hard a slot is to give up when a session has to fit a time budget.
enum SlotPriority {
  /// Compound work the session exists for. Dropped only as a last resort.
  primary,

  /// Accessory and core work. Trimmed first.
  accessory,
}

/// One position in a day template, expressed as a movement pattern rather
/// than a named exercise.
///
/// This indirection is what lets one template serve a bodyweight-at-home
/// beginner and a full-gym advanced lifter: the slot says "a horizontal
/// push goes here", and the generator finds the best one the user can do.
@immutable
class SlotSpec {
  const SlotSpec(
    this.pattern, {
    required this.sets,
    this.priority = SlotPriority.primary,
    this.targetMuscle,
  });

  final MovementPattern pattern;

  /// Narrows an isolation slot to a specific muscle, so an arms slot cannot
  /// be filled by a calf raise.
  final MuscleGroup? targetMuscle;

  final SlotPriority priority;
  final int sets;

  bool get isPrimary => priority == SlotPriority.primary;
}

/// A day's shape: what it is called and what goes in it.
@immutable
class DayTemplate {
  const DayTemplate(this.type, this.labelKey, this.slots);

  final DayType type;

  /// ARB key for the day's name.
  final String labelKey;

  final List<SlotSpec> slots;

  /// How much of this day's primary work loads the legs, from 0 to 1.
  ///
  /// Drives the hybrid-goal placement rule: a day with high leg emphasis
  /// should not land the day before a run.
  double get legEmphasis {
    final primary = slots.where((s) => s.isPrimary).toList();
    if (primary.isEmpty) return 0;
    final legs = primary.where((s) => s.pattern.isLegDominant).length;
    return legs / primary.length;
  }
}

/// A week's worth of day templates.
@immutable
class WeekTemplate {
  const WeekTemplate(this.id, this.days);

  /// The template for a given training frequency.
  ///
  /// Two or three days is full body, four alternates upper and lower, five
  /// is push/pull/legs plus an upper and a lower day, and six is a double
  /// push/pull/legs.
  factory WeekTemplate.forDays(int daysPerWeek) {
    if (daysPerWeek < 2 || daysPerWeek > 6) {
      throw ArgumentError.value(
        daysPerWeek,
        'daysPerWeek',
        'Supported training frequency is 2 to 6 days per week',
      );
    }
    return switch (daysPerWeek) {
      2 => const WeekTemplate('full_body_2', [_fullBody, _fullBody]),
      3 => const WeekTemplate('full_body_3', [_fullBody, _fullBody, _fullBody]),
      4 => const WeekTemplate('upper_lower_4', [_upper, _lower, _upper, _lower]),
      5 => const WeekTemplate('ppl_upper_lower_5', [
          _push,
          _pull,
          _legs,
          _upper,
          _lower,
        ]),
      _ => const WeekTemplate('ppl_6', [_push, _pull, _legs, _push, _pull, _legs]),
    };
  }

  /// Full-body days at any frequency.
  ///
  /// Used when the user cannot train upper-body pulling at all — bodyweight
  /// at home with no bar. An upper/lower or push/pull/legs split would hand
  /// them a pull day with nothing in it, so the split is abandoned in favour
  /// of days that are at least coherent sessions.
  factory WeekTemplate.fullBodyFor(int daysPerWeek) {
    if (daysPerWeek < 2 || daysPerWeek > 6) {
      throw ArgumentError.value(
        daysPerWeek,
        'daysPerWeek',
        'Supported training frequency is 2 to 6 days per week',
      );
    }
    return WeekTemplate('full_body_$daysPerWeek', [
      for (var i = 0; i < daysPerWeek; i++) _fullBody,
    ]);
  }

  final String id;
  final List<DayTemplate> days;

  int get daysPerWeek => days.length;

  /// The same template with its day order rotated by [offset].
  ///
  /// Rotation rather than free reordering is deliberate: it moves leg work
  /// away from pre-run days without ever collapsing upper/lower alternation
  /// into two lower days back to back.
  WeekTemplate rotated(int offset) {
    if (days.isEmpty) return this;
    final shift = offset % days.length;
    if (shift == 0) return this;
    return WeekTemplate(id, [
      ...days.sublist(shift),
      ...days.sublist(0, shift),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Day templates.
//
// Slot counts are chosen so that the longest sessions fit comfortably and the
// shortest ones trim accessories rather than losing their compound work.
// ---------------------------------------------------------------------------

const _fullBody = DayTemplate(DayType.fullBody, 'day_full_body', [
  SlotSpec(MovementPattern.squat, sets: 3),
  SlotSpec(MovementPattern.horizontalPush, sets: 3),
  SlotSpec(MovementPattern.horizontalPull, sets: 3),
  SlotSpec(MovementPattern.hinge, sets: 3),
  SlotSpec(
    MovementPattern.core,
    sets: 3,
    priority: SlotPriority.accessory,
  ),
]);

const _upper = DayTemplate(DayType.upper, 'day_upper', [
  SlotSpec(MovementPattern.horizontalPush, sets: 3),
  SlotSpec(MovementPattern.verticalPull, sets: 3),
  SlotSpec(MovementPattern.verticalPush, sets: 3),
  SlotSpec(MovementPattern.horizontalPull, sets: 3),
  SlotSpec(
    MovementPattern.isolation,
    sets: 2,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.biceps,
  ),
  SlotSpec(
    MovementPattern.isolation,
    sets: 2,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.triceps,
  ),
]);

const _lower = DayTemplate(DayType.lower, 'day_lower', [
  SlotSpec(MovementPattern.squat, sets: 3),
  SlotSpec(MovementPattern.hinge, sets: 3),
  SlotSpec(MovementPattern.lunge, sets: 3),
  SlotSpec(
    MovementPattern.isolation,
    sets: 3,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.calves,
  ),
  SlotSpec(
    MovementPattern.core,
    sets: 3,
    priority: SlotPriority.accessory,
  ),
]);

const _push = DayTemplate(DayType.push, 'day_push', [
  SlotSpec(MovementPattern.horizontalPush, sets: 4),
  SlotSpec(MovementPattern.verticalPush, sets: 3),
  SlotSpec(
    MovementPattern.isolation,
    sets: 3,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.triceps,
  ),
  SlotSpec(
    MovementPattern.isolation,
    sets: 3,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.shoulders,
  ),
  SlotSpec(
    MovementPattern.core,
    sets: 3,
    priority: SlotPriority.accessory,
  ),
]);

const _pull = DayTemplate(DayType.pull, 'day_pull', [
  SlotSpec(MovementPattern.verticalPull, sets: 4),
  SlotSpec(MovementPattern.horizontalPull, sets: 3),
  SlotSpec(
    MovementPattern.isolation,
    sets: 3,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.biceps,
  ),
  SlotSpec(
    MovementPattern.isolation,
    sets: 3,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.upperBack,
  ),
]);

const _legs = DayTemplate(DayType.legs, 'day_legs', [
  SlotSpec(MovementPattern.squat, sets: 4),
  SlotSpec(MovementPattern.hinge, sets: 3),
  SlotSpec(MovementPattern.lunge, sets: 3),
  SlotSpec(
    MovementPattern.isolation,
    sets: 3,
    priority: SlotPriority.accessory,
    targetMuscle: MuscleGroup.calves,
  ),
  SlotSpec(
    MovementPattern.core,
    sets: 3,
    priority: SlotPriority.accessory,
  ),
]);
