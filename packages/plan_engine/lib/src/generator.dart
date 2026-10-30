import 'package:exercise_library/exercise_library.dart';

import 'day_rules.dart';
import 'goal.dart';
import 'plan_request.dart';
import 'scheduler.dart';
import 'templates.dart';
import 'week_plan.dart';

/// Builds a week of training from a request and the catalog.
///
/// Entirely deterministic and side-effect free: no randomness, no clock, no
/// I/O. Ranking ties break on exercise id, so the same request always yields
/// the same plan and golden tests are meaningful.
class PlanGenerator {
  const PlanGenerator(this.catalog);

  /// How much one level of progression is worth when ranking candidates for
  /// a primary slot.
  static const int difficultyWeight = 200;

  /// Difficulty carries no weight in an accessory slot.
  ///
  /// Progressive overload is what drives exercise choice for compound work,
  /// but an accessory slot is about reaching the muscle: nobody needs an
  /// advanced calf raise, and letting difficulty rule here cost gym users
  /// their camera-coached plank in favour of a hanging knee raise.
  static const int accessoryDifficultyWeight = 0;

  /// Camera support is worth exactly one level of progression: enough that a
  /// beginner gets the coached squat over an uncoached machine, not enough
  /// that an advanced lifter is handed bodyweight work.
  static const int cameraBonus = 200;

  /// A nudge towards using the equipment the user actually has, so a gym
  /// member is not prescribed bodyweight squats.
  static const int equipmentBonus = 10;

  /// Variety pressure, within the week and against recent sessions.
  ///
  /// Deliberately smaller than [equipmentBonus], and far smaller than
  /// [difficultyWeight]: variety is the last ranking criterion, so it breaks
  /// ties between equally suitable exercises but never downgrades the
  /// prescription. Without this, a dumbbell owner was handed bodyweight
  /// squats mid-week purely to avoid repeating the good option.
  static const int usedThisWeekPenalty = 3;
  static const int recentlyUsedPenalty = 5;

  /// Fewer primary exercises than this and the day is not a real session.
  static const int minimumPrimaryExercises = 2;

  final ExerciseCatalog catalog;

  WeekPlan generate(PlanRequest request) {
    request.validate();

    final notes = <PlanNote>[];

    final schedule = PlanScheduler.schedule(
      template: _chooseTemplate(request, notes),
      runWeekdays: request.runWeekdays,
    );

    final usedThisWeek = <String>{};

    final days = [
      for (final scheduled in schedule.days)
        _buildDay(
          scheduled: scheduled,
          request: request,
          usedThisWeek: usedThisWeek,
          notes: notes,
        ),
    ];

    return WeekPlan(
      templateId: schedule.templateId,
      goal: request.goal,
      days: days,
      runWeekdays: request.runWeekdays,
      runSuggestionKeys: _runSuggestions(request),
      notes: notes,
    );
  }

  PlannedDay _buildDay({
    required ScheduledDay scheduled,
    required PlanRequest request,
    required Set<String> usedThisWeek,
    required List<PlanNote> notes,
  }) {
    final usedToday = <String>{};
    final exercises = <PlannedExercise>[];

    for (final slot in scheduled.template.slots) {
      final choice = _pickForSlot(
        slot: slot,
        request: request,
        usedToday: usedToday,
        usedThisWeek: usedThisWeek,
      );

      if (choice == null) {
        notes.add(
          PlanNote(
            PlanNoteKind.unfilledSlot,
            slot.targetMuscle == null
                ? slot.pattern.name
                : '${slot.pattern.name}:${slot.targetMuscle!.name}',
            weekday: scheduled.weekday,
          ),
        );
        continue;
      }

      usedToday.add(choice.id);
      usedThisWeek.add(choice.id);
      exercises.add(
        DayRules.prescribe(
          exercise: choice,
          slotPattern: slot.pattern,
          priority: slot.priority,
          templateSets: slot.sets,
          request: request,
        ),
      );
    }

    final result = DayRules.apply(
      PlannedDay(
        weekday: scheduled.weekday,
        type: scheduled.type,
        labelKey: scheduled.labelKey,
        precedesRunDay: scheduled.precedesRunDay,
        exercises: exercises,
      ),
      request,
    );
    notes.addAll(result.notes);

    if (result.day.primaryExercises.length < minimumPrimaryExercises) {
      notes.add(
        PlanNote(
          PlanNoteKind.dayUnderfilled,
          scheduled.type.name,
          weekday: scheduled.weekday,
        ),
      );
    }

    return result.day;
  }

  /// The split for this request, falling back to full-body days when the
  /// frequency's usual split asks for work this user cannot do.
  ///
  /// A split dedicates whole days to one pattern group, so a user who cannot
  /// train that group gets a day with no compound work in it at all — a pull
  /// day with no pull, or a push day that every available pressing movement
  /// is contraindicated for. Full-body days spread the patterns out, so the
  /// loss of one leaves a session that still works.
  WeekTemplate _chooseTemplate(PlanRequest request, List<PlanNote> notes) {
    final preferred = WeekTemplate.forDays(request.daysPerWeek);
    final missing = _unTrainablePatterns(preferred, request);
    if (missing.isEmpty) return preferred;

    final fallback = WeekTemplate.fullBodyFor(request.daysPerWeek);
    if (fallback.id == preferred.id) return preferred;

    notes.add(
      PlanNote(
        PlanNoteKind.templateSimplified,
        (missing.map((p) => p.name).toList()..sort()).join(','),
      ),
    );
    return fallback;
  }

  /// Primary patterns [template] needs that this user has no exercise for,
  /// but only from days that would be left without enough compound work.
  ///
  /// A split is fine missing one pattern out of four; it is not fine when a
  /// whole day collapses.
  Set<MovementPattern> _unTrainablePatterns(
    WeekTemplate template,
    PlanRequest request,
  ) {
    final missing = <MovementPattern>{};
    for (final day in template.days) {
      final primary = day.slots.where((slot) => slot.isPrimary);
      final unfillable = primary
          .where((slot) => !_canFill(slot.pattern, request))
          .map((slot) => slot.pattern)
          .toSet();
      if (primary.length - unfillable.length < minimumPrimaryExercises) {
        missing.addAll(unfillable);
      }
    }
    return missing;
  }

  bool _canFill(MovementPattern pattern, PlanRequest request) => catalog
      .candidates(
        available: request.availableEquipment,
        injuries: request.injuries,
        level: request.level,
        pattern: pattern,
      )
      .isNotEmpty;

  /// The best exercise for [slot], or null if nothing fits.
  ///
  /// A slot that names a target muscle retries without it rather than being
  /// lost: an accessory the user can actually do beats an empty slot, and
  /// the unfilled-slot note still records that the intent was not met.
  Exercise? _pickForSlot({
    required SlotSpec slot,
    required PlanRequest request,
    required Set<String> usedToday,
    required Set<String> usedThisWeek,
  }) {
    // First pass honours the target muscle; the second drops it, and is only
    // reached when the narrowed search found nothing at all.
    for (final targetMuscle in [slot.targetMuscle, null]) {
      final candidates = catalog
          .candidates(
            available: request.availableEquipment,
            injuries: request.injuries,
            level: request.level,
            pattern: slot.pattern,
            targetMuscle: targetMuscle,
          )
          .where((exercise) => !usedToday.contains(exercise.id))
          .toList();

      if (candidates.isEmpty) continue;

      // `candidates` arrives id-ordered and this sort is stable, so ties
      // break on id and the result is reproducible.
      candidates.sort(
        (a, b) => score(b, request, usedThisWeek, priority: slot.priority)
            .compareTo(
          score(a, request, usedThisWeek, priority: slot.priority),
        ),
      );
      return candidates.first;
    }
    return null;
  }

  /// Ranking score for [exercise]; higher wins.
  ///
  /// Exposed so the weighting can be inspected directly in tests rather than
  /// inferred from which exercise came out on top.
  int score(
    Exercise exercise,
    PlanRequest request,
    Set<String> usedThisWeek, {
    SlotPriority priority = SlotPriority.primary,
  }) {
    final weight = priority == SlotPriority.primary
        ? difficultyWeight
        : accessoryDifficultyWeight;
    var value = exercise.difficulty.index * weight;
    if (exercise.isCameraSupported) value += cameraBonus;
    value += exercise.requiredEquipment.length * equipmentBonus;
    if (usedThisWeek.contains(exercise.id)) value -= usedThisWeekPenalty;
    if (request.recentExerciseIds.contains(exercise.id)) {
      value -= recentlyUsedPenalty;
    }
    return value;
  }

  /// Text running suggestions, scaled to experience.
  ///
  /// Hybrid goal only, and deliberately just ARB keys: Spottr schedules
  /// around runs and says something encouraging, but never tracks them.
  List<String> _runSuggestions(PlanRequest request) {
    if (request.goal != Goal.hybrid || request.runWeekdays.isEmpty) {
      return const [];
    }
    final key = switch (request.level) {
      Level.beginner => 'run_suggestion_easy_20',
      Level.intermediate => 'run_suggestion_steady_35',
      Level.advanced => 'run_suggestion_tempo_45',
    };
    return [for (var i = 0; i < request.runWeekdays.length; i++) key];
  }
}
