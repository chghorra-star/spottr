import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/domain/user_profile.dart';

import '../support/profiles.dart';

void main() {
  group('toPlanRequest', () {
    test('carries every field the generator reads', () {
      final profile = testProfile(
        goal: Goal.muscleBuilding,
        daysPerWeek: 4,
        sessionMinutes: 60,
        level: Level.intermediate,
        location: TrainingLocation.homeDumbbells,
        extraEquipment: {Equipment.pullUpBar},
        injuries: {BodyPart.knees},
      );

      final request = profile.toPlanRequest(
        recentExerciseIds: const ['push_up'],
      );

      expect(request.goal, Goal.muscleBuilding);
      expect(request.daysPerWeek, 4);
      expect(request.sessionMinutes, 60);
      expect(request.level, Level.intermediate);
      expect(request.location, TrainingLocation.homeDumbbells);
      expect(request.extraEquipment, {Equipment.pullUpBar});
      expect(request.injuries, {BodyPart.knees});
      expect(request.recentExerciseIds, ['push_up']);
      expect(
        request.availableEquipment,
        {Equipment.dumbbells, Equipment.pullUpBar},
      );
    });

    test('hands run days to the generator for a hybrid goal', () {
      final profile = testProfile(goal: Goal.hybrid, runWeekdays: {3, 6});
      expect(profile.toPlanRequest().runWeekdays, {3, 6});
    });

    test('withholds run days for a goal that does not run', () {
      // Run days are kept on the profile so switching back to hybrid does
      // not lose them, but a weight-loss plan must not be silently shaped
      // around runs the user is no longer doing.
      final profile = testProfile(goal: Goal.weightLoss, runWeekdays: {3, 6});

      expect(profile.runWeekdays, {3, 6});
      expect(profile.toPlanRequest().runWeekdays, isEmpty);
    });

    test('produces a request the generator accepts', () {
      expect(testProfile().toPlanRequest().validate, returnsNormally);
    });
  });

  group('validate', () {
    test('accepts the supported training frequencies', () {
      for (var days = UserProfile.minDaysPerWeek;
          days <= UserProfile.maxDaysPerWeek;
          days++) {
        expect(testProfile(daysPerWeek: days).validate, returnsNormally);
      }
    });

    test('rejects a frequency no template covers', () {
      expect(testProfile(daysPerWeek: 1).validate, throwsArgumentError);
      expect(testProfile(daysPerWeek: 7).validate, throwsArgumentError);
    });

    test('rejects a session too short to program', () {
      expect(testProfile(sessionMinutes: 19).validate, throwsArgumentError);
      expect(testProfile(sessionMinutes: 20).validate, returnsNormally);
    });

    test('rejects a run day outside the ISO week', () {
      expect(testProfile(runWeekdays: {0}).validate, throwsArgumentError);
      expect(testProfile(runWeekdays: {8}).validate, throwsArgumentError);
    });

    test('rejects body measurements outside human range', () {
      expect(testProfile(ageYears: 9).validate, throwsArgumentError);
      expect(testProfile(ageYears: 121).validate, throwsArgumentError);
      expect(testProfile(heightCm: 40).validate, throwsArgumentError);
      expect(testProfile(weightKg: 5).validate, throwsArgumentError);
    });

    test('accepts a profile that gave no measurements at all', () {
      // Age, height, weight and sex are optional in the brief, and nothing
      // in plan generation reads them.
      final profile = testProfile(
        ageYears: null,
        heightCm: null,
        weightKg: null,
        sex: null,
      );
      expect(profile.validate, returnsNormally);
      expect(profile.toPlanRequest().validate, returnsNormally);
    });
  });

  group('disclaimer', () {
    test('a fresh profile has not accepted it', () {
      expect(testProfile().hasAcceptedDisclaimer, isFalse);
    });

    test('acceptance is recorded as a timestamp', () {
      final at = DateTime.utc(2026, 10, 31, 9);
      final accepted = testProfile().copyWith(disclaimerAcceptedAt: at);

      expect(accepted.hasAcceptedDisclaimer, isTrue);
      expect(accepted.disclaimerAcceptedAt, at);
    });
  });

  group('value semantics', () {
    test('identical profiles compare equal', () {
      expect(testProfile(), testProfile());
      expect(testProfile().hashCode, testProfile().hashCode);
    });

    test('copyWith changes only what it is given', () {
      final original = testProfile(injuries: {BodyPart.knees});
      final changed = original.copyWith(coachStyle: CoachStyle.tough);

      expect(changed.coachStyle, CoachStyle.tough);
      expect(changed.injuries, {BodyPart.knees});
      expect(changed, isNot(original));
      expect(original.copyWith(), original);
    });

    test('copyWith can clear the optional measurements', () {
      final original = testProfile(ageYears: 34, injuryNotes: 'left knee');
      final cleared = original.copyWith(
        ageYears: null,
        clearAgeYears: true,
        injuryNotes: null,
        clearInjuryNotes: true,
      );

      expect(cleared.ageYears, isNull);
      expect(cleared.injuryNotes, isNull);
    });

    test('collections are not shared with the caller', () {
      final injuries = {BodyPart.knees};
      final profile = testProfile(injuries: injuries);
      injuries.add(BodyPart.shoulders);

      expect(profile.injuries, {BodyPart.knees});
    });
  });
}
