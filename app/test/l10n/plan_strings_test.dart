import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/domain/workout_session.dart';
import 'package:spottr/l10n/app_localizations_en.dart';
import 'package:spottr/l10n/plan_strings.dart';

/// The catalog and the plan engine deal in identifiers; the UI needs prose.
/// This is the only place that maps between them, so it is the only place a
/// missing string can hide. Every test here enumerates a whole enum or the
/// whole catalog rather than sampling, because the failure mode is one
/// forgotten value showing a raw key to the user.
void main() {
  final strings = PlanStrings(AppLocalizationsEn(), standardCatalog);

  group('exercise names', () {
    test('every catalog entry has one', () {
      for (final exercise in standardCatalog.all) {
        expect(
          strings.exercise(exercise.id),
          isNotEmpty,
          reason: 'no name for ${exercise.id}',
        );
      }
    });

    test('no two entries share a name', () {
      // A copy-pasted ARB value is invisible until two rows in a plan read
      // the same and the user cannot tell them apart.
      final byName = <String, List<String>>{};
      for (final exercise in standardCatalog.all) {
        byName.putIfAbsent(strings.exercise(exercise.id), () => []).add(
              exercise.id,
            );
      }
      final collisions = byName.entries.where((e) => e.value.length > 1);
      expect(collisions, isEmpty, reason: '$collisions');
    });

    test('an unknown key fails loudly and names itself', () {
      expect(
        () => strings.exerciseByKey('exercise_nonsense'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('exercise_nonsense'),
          ),
        ),
      );
    });
  });

  group('plan vocabulary', () {
    test('every day label a template can produce resolves', () {
      final labels = <String>{};
      for (var days = UserProfile.minDaysPerWeek;
          days <= UserProfile.maxDaysPerWeek;
          days++) {
        for (final template in [
          WeekTemplate.forDays(days),
          WeekTemplate.fullBodyFor(days),
        ]) {
          labels.addAll(template.days.map((day) => day.labelKey));
        }
      }
      expect(labels, isNotEmpty);
      for (final label in labels) {
        expect(strings.day(label), isNotEmpty, reason: label);
      }
    });

    test('every day type resolves', () {
      for (final type in DayType.values) {
        expect(strings.dayType(type), isNotEmpty, reason: type.name);
      }
    });

    test('every movement pattern resolves', () {
      for (final pattern in MovementPattern.values) {
        expect(strings.pattern(pattern), isNotEmpty, reason: pattern.name);
      }
    });

    test('every muscle group resolves', () {
      for (final muscle in MuscleGroup.values) {
        expect(strings.muscle(muscle), isNotEmpty, reason: muscle.name);
      }
    });

    test('every weekday resolves, and nothing else does', () {
      for (var weekday = 1; weekday <= 7; weekday++) {
        expect(strings.weekday(weekday), isNotEmpty);
      }
      expect(() => strings.weekday(0), throwsA(isA<RangeError>()));
      expect(() => strings.weekday(8), throwsA(isA<RangeError>()));
    });

    test('every run suggestion the generator can emit resolves', () {
      final generator = PlanGenerator(standardCatalog);
      final keys = <String>{};
      for (final level in Level.values) {
        final plan = generator.generate(
          PlanRequest(
            goal: Goal.hybrid,
            daysPerWeek: 3,
            sessionMinutes: 60,
            level: level,
            location: TrainingLocation.fullGym,
            runWeekdays: const {6},
          ),
        );
        keys.addAll(plan.runSuggestionKeys);
      }

      expect(keys, hasLength(Level.values.length));
      for (final key in keys) {
        expect(strings.runSuggestion(key), isNotEmpty, reason: key);
      }
    });
  });

  group('onboarding vocabulary', () {
    test('every choice the user can make has a label and an explanation', () {
      for (final goal in Goal.values) {
        expect(strings.goal(goal), isNotEmpty, reason: goal.name);
        expect(strings.goalDetail(goal), isNotEmpty, reason: goal.name);
      }
      for (final level in Level.values) {
        expect(strings.level(level), isNotEmpty, reason: level.name);
        expect(strings.levelDetail(level), isNotEmpty, reason: level.name);
      }
      for (final location in TrainingLocation.values) {
        expect(strings.location(location), isNotEmpty, reason: location.name);
        expect(
          strings.locationDetail(location),
          isNotEmpty,
          reason: location.name,
        );
      }
      for (final style in CoachStyle.values) {
        expect(strings.coachStyle(style), isNotEmpty, reason: style.name);
        expect(strings.coachStyleDetail(style), isNotEmpty, reason: style.name);
      }
    });

    test('every equipment item, injury site and sex resolves', () {
      for (final item in Equipment.values) {
        expect(strings.equipment(item), isNotEmpty, reason: item.name);
      }
      for (final part in BodyPart.values) {
        expect(strings.bodyPart(part), isNotEmpty, reason: part.name);
      }
      for (final value in Sex.values) {
        expect(strings.sex(value), isNotEmpty, reason: value.name);
      }
    });
  });

  group('plan notes', () {
    test('every kind renders prose, with its detail resolved', () {
      final cases = <PlanNote, Matcher>{
        const PlanNote(PlanNoteKind.unfilledSlot, 'horizontalPull'):
            contains(strings.pattern(MovementPattern.horizontalPull)),
        const PlanNote(PlanNoteKind.unfilledSlot, 'isolation:biceps'):
            contains(strings.muscle(MuscleGroup.biceps)),
        const PlanNote(PlanNoteKind.legVolumeReducedForRun, 'lower',
            weekday: 1): contains(strings.weekday(1)),
        // The same note without a weekday still has to read as a sentence.
        const PlanNote(PlanNoteKind.legVolumeReducedForRun, 'lower'):
            contains(strings.dayType(DayType.lower)),
        const PlanNote(PlanNoteKind.trimmedForTime, 'plank'):
            contains(strings.exercise('plank')),
        const PlanNote(PlanNoteKind.templateSimplified, 'horizontalPull,verticalPull'):
            contains(strings.pattern(MovementPattern.verticalPull)),
        const PlanNote(PlanNoteKind.dayUnderfilled, 'pull'):
            contains(strings.dayType(DayType.pull)),
        const PlanNote(PlanNoteKind.sessionShorterThanBudget, '45'):
            contains('45'),
      };

      for (final entry in cases.entries) {
        final prose = strings.note(entry.key);
        expect(prose, isNotEmpty, reason: '${entry.key}');
        expect(prose, entry.value, reason: '${entry.key}');
      }

      expect(
        cases.keys.map((note) => note.kind).toSet(),
        PlanNoteKind.values.toSet(),
        reason: 'a note kind with no prose would render as nothing',
      );
    });

    test('every note a real plan produces renders', () {
      // The constructed cases above pin the wording; this one proves the
      // detail formats the generator actually emits are the ones parsed.
      final generator = PlanGenerator(standardCatalog);
      final notes = <PlanNote>[];
      for (final location in TrainingLocation.values) {
        for (final days in [2, 4, 6]) {
          for (final minutes in [20, 30, 60]) {
            notes.addAll(
              generator
                  .generate(
                    PlanRequest(
                      goal: Goal.hybrid,
                      daysPerWeek: days,
                      sessionMinutes: minutes,
                      level: Level.beginner,
                      location: location,
                      injuries: const {BodyPart.shoulders},
                      runWeekdays: const {3, 6},
                    ),
                  )
                  .notes,
            );
          }
        }
      }

      expect(notes, isNotEmpty);
      for (final note in notes) {
        expect(strings.note(note), isNotEmpty, reason: '$note');
      }
    });
  });

  group('progression', () {
    /// A decision of every shape, keyed by the change it carries, so that
    /// the enum check below can prove none was forgotten.
    final byChange = <ProgressionChange, ProgressionDecision>{
      ProgressionChange.loadUp: const ProgressionDecision(
        exerciseId: 'barbell_back_squat',
        change: ProgressionChange.loadUp,
        reason: ProgressionReason.earnedLoad,
        nextWeightKg: 62.5,
        repsAchieved: 12,
      ),
      ProgressionChange.loadDown: const ProgressionDecision(
        exerciseId: 'barbell_back_squat',
        change: ProgressionChange.loadDown,
        reason: ProgressionReason.missedReps,
        nextWeightKg: 55,
        repsAchieved: 6,
      ),
      ProgressionChange.repsUp: const ProgressionDecision(
        exerciseId: 'push_up',
        change: ProgressionChange.repsUp,
        reason: ProgressionReason.earnedReps,
        nextRepsMin: 10,
        nextRepsMax: 14,
      ),
      ProgressionChange.holdUp: const ProgressionDecision(
        exerciseId: 'plank',
        change: ProgressionChange.holdUp,
        reason: ProgressionReason.earnedHold,
        nextHoldSeconds: 50,
      ),
      ProgressionChange.harderVariant: const ProgressionDecision(
        exerciseId: 'knee_push_up',
        change: ProgressionChange.harderVariant,
        reason: ProgressionReason.earnedHarderVariant,
        nextExerciseId: 'push_up',
      ),
      ProgressionChange.easierVariant: const ProgressionDecision(
        exerciseId: 'push_up',
        change: ProgressionChange.easierVariant,
        reason: ProgressionReason.formBreakingDown,
        nextExerciseId: 'knee_push_up',
      ),
      ProgressionChange.hold: const ProgressionDecision(
        exerciseId: 'plank',
        change: ProgressionChange.hold,
        reason: ProgressionReason.holdingSteady,
      ),
    };

    test('every kind of change reads as a sentence', () {
      expect(
        byChange.keys.toSet(),
        ProgressionChange.values.toSet(),
        reason: 'a change with no prose would render as nothing',
      );
      for (final entry in byChange.entries) {
        expect(
          strings.progression(entry.value),
          isNotEmpty,
          reason: entry.key.name,
        );
      }
    });

    test('every reason reads as a sentence', () {
      for (final reason in ProgressionReason.values) {
        final prose = strings.progression(
          ProgressionDecision(
            exerciseId: 'plank',
            change: ProgressionChange.hold,
            reason: reason,
            repsAchieved: 8,
          ),
        );
        expect(prose, isNotEmpty, reason: reason.name);
      }
    });

    test('a reason that quotes a number works without one too', () {
      // Holds have seconds rather than reps, so the rep count is absent and
      // the sentence has to stand up without it.
      for (final reason in [
        ProgressionReason.earnedLoad,
        ProgressionReason.missedReps,
      ]) {
        final prose = strings.progression(
          ProgressionDecision(
            exerciseId: 'plank',
            change: ProgressionChange.hold,
            reason: reason,
          ),
        );
        expect(prose, isNotEmpty, reason: reason.name);
        expect(prose, isNot(contains('null')));
      }
    });

    test('a decision names the change and the reason, in that order', () {
      final prose = strings.progression(byChange[ProgressionChange.loadUp]!);

      expect(prose, contains('62.5'));
      expect(prose, contains('12'));
      expect(prose.indexOf('62.5'), lessThan(prose.indexOf('12')));
    });

    test('a variant change names the exercise it moves to, not from', () {
      final prose =
          strings.progression(byChange[ProgressionChange.harderVariant]!);

      expect(prose, contains(strings.exercise('push_up')));
      expect(prose, isNot(contains(strings.exercise('knee_push_up'))));
    });

    test('a form score joins the reason once there is one to report', () {
      final without = strings.progression(
        byChange[ProgressionChange.loadUp]!,
      );
      final with_ = strings.progression(
        const ProgressionDecision(
          exerciseId: 'barbell_back_squat',
          change: ProgressionChange.loadUp,
          reason: ProgressionReason.earnedLoad,
          nextWeightKg: 62.5,
          repsAchieved: 12,
          meanFormScore: 91.6,
        ),
      );

      expect(without, isNot(contains('%')));
      expect(with_, contains('92'));
    });

    test('a weight reads the way a person writes it', () {
      expect(strings.weight(60), '60');
      expect(strings.weight(62.5), '62.5');
    });

    test('every rating has a label and an explanation', () {
      for (final value in SessionRating.values) {
        expect(strings.rating(value), isNotEmpty, reason: value.name);
        expect(strings.ratingDetail(value), isNotEmpty, reason: value.name);
      }
    });

    test('a logged set reads in whatever unit it was logged in', () {
      final completedAt = DateTime.utc(2026, 10, 31);
      expect(
        strings.loggedSet(
          LoggedSet(
            id: 'a',
            exerciseId: 'push_up',
            setIndex: 0,
            reps: 12,
            completedAt: completedAt,
          ),
        ),
        contains('12'),
      );
      expect(
        strings.loggedSet(
          LoggedSet(
            id: 'b',
            exerciseId: 'barbell_back_squat',
            setIndex: 0,
            reps: 8,
            weightKg: 62.5,
            completedAt: completedAt,
          ),
        ),
        contains('62.5'),
      );
      final held = strings.loggedSet(
        LoggedSet(
          id: 'c',
          exerciseId: 'plank',
          setIndex: 0,
          holdSeconds: 45,
          completedAt: completedAt,
        ),
      );
      expect(held, contains('45'));
      expect(held, isNot(contains('reps')));
    });

    test('every decision a real session produces renders', () {
      // The constructed cases pin the wording; this one proves the decisions
      // the engine actually emits are the ones handled.
      final plan = PlanGenerator(standardCatalog).generate(
        const PlanRequest(
          goal: Goal.muscleBuilding,
          daysPerWeek: 3,
          sessionMinutes: 60,
          level: Level.beginner,
          location: TrainingLocation.homeNone,
        ),
      );
      final progression = Progression(standardCatalog);

      for (final rating in [null, ...SessionRating.values]) {
        for (final reps in [2, 12, 25]) {
          for (final weightKg in [null, 40.0]) {
            final decisions = progression.decide(
              inputs: [
                for (final exercise in plan.days.first.exercises)
                  ProgressionInput(
                    planned: exercise,
                    completed: [
                      for (var i = 0; i < exercise.sets; i++)
                        CompletedSet(
                          reps: exercise.metric == MetricType.reps ? reps : null,
                          holdSeconds: exercise.metric == MetricType.reps
                              ? null
                              : reps * 4,
                          weightKg: weightKg,
                        ),
                    ],
                    rating: rating,
                  ),
              ],
              request: const PlanRequest(
                goal: Goal.muscleBuilding,
                daysPerWeek: 3,
                sessionMinutes: 60,
                level: Level.beginner,
                location: TrainingLocation.homeNone,
              ),
            );

            for (final decision in decisions) {
              final prose = strings.progression(decision);
              expect(prose, isNotEmpty, reason: '$decision');
              expect(prose, isNot(contains('null')), reason: '$decision');
            }
          }
        }
      }
    });
  });

  group('prescriptions', () {
    final generator = PlanGenerator(standardCatalog);
    final plan = generator.generate(
      const PlanRequest(
        goal: Goal.muscleBuilding,
        daysPerWeek: 4,
        sessionMinutes: 60,
        level: Level.intermediate,
        location: TrainingLocation.fullGym,
      ),
    );

    test('a rep prescription reads as sets by reps', () {
      final reps = plan.allExercises
          .firstWhere((e) => e.metric == MetricType.reps);
      expect(
        strings.prescription(reps),
        '${reps.sets} × ${reps.repsMin}–${reps.repsMax}',
      );
    });

    test('a hold prescription reads as seconds, never reps', () {
      final hold = plan.allExercises
          .firstWhere((e) => e.metric == MetricType.holdSeconds);
      final prose = strings.prescription(hold);
      expect(prose, contains('${hold.holdSeconds}'));
      expect(prose, isNot(contains('–')));
    });

    test('every exercise in a real plan renders a prescription', () {
      for (final exercise in plan.allExercises) {
        expect(
          strings.prescription(exercise),
          isNotEmpty,
          reason: exercise.exerciseId,
        );
      }
    });
  });
}
