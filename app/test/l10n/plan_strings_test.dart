import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/domain/user_profile.dart';
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
