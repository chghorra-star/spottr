import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/ui/common/ui_keys.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

void main() {
  late RecordingProfileController controller;

  Future<void> start(WidgetTester tester, {Object? saveError}) => pumpApp(
        tester,
        overrides: [
          profileControllerProvider.overrideWithValue(
            controller = RecordingProfileController(
              onSave: saveError == null
                  ? null
                  : (profile) async => throw saveError,
            ),
          ),
        ],
      );

  Future<void> next(WidgetTester tester) =>
      scrollAndTap(tester, find.byKey(UiKeys.onboardingNext));

  Future<void> choose(WidgetTester tester, String question, String value) =>
      scrollAndTap(tester, find.byKey(UiKeys.choice(question, value)));

  group('the disclaimer gate', () {
    testWidgets('is the first thing shown', (tester) async {
      await start(tester);

      expect(find.byKey(UiKeys.disclaimerAccept), findsOneWidget);
      expect(find.text('Spottr'), findsNothing);
    });

    testWidgets('blocks the flow until it is accepted', (tester) async {
      // Nothing about this screen may be skippable. The only way forward is
      // through the acceptance control.
      await start(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(UiKeys.onboardingNext),
      );
      expect(button.onPressed, isNull, reason: 'Next is not available yet');

      await tester.tap(find.byKey(UiKeys.disclaimerAccept));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(UiKeys.onboardingNext))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('records when it was accepted', (tester) async {
      await start(tester);
      await tester.tap(find.byKey(UiKeys.disclaimerAccept));
      await tester.pumpAndSettle();

      for (var step = 0; step < 8; step++) {
        await next(tester);
      }

      expect(controller.saved, hasLength(1));
      expect(controller.saved.single.hasAcceptedDisclaimer, isTrue);
      expect(controller.saved.single.disclaimerAcceptedAt!.isUtc, isTrue);
    });
  });

  group('answers', () {
    testWidgets('every answer the user gives reaches the saved profile',
        (tester) async {
      await start(tester);
      await tester.tap(find.byKey(UiKeys.disclaimerAccept));
      await tester.pumpAndSettle();
      await next(tester);

      // Goal, then the run days step the hybrid goal brings with it.
      await choose(tester, 'goal', Goal.hybrid.name);
      await next(tester);
      await choose(tester, 'runDay', '6');
      await next(tester);

      // Schedule, left at its defaults.
      expect(find.byKey(UiKeys.questionSchedule), findsOneWidget);
      await next(tester);

      await choose(tester, 'level', Level.advanced.name);
      await next(tester);

      expect(find.byKey(UiKeys.questionBody), findsOneWidget);
      await tester.enterText(find.byKey(UiKeys.ageField), '41');
      await tester.pumpAndSettle();
      await next(tester);

      await choose(tester, 'injury', BodyPart.knees.name);
      await next(tester);

      await choose(tester, 'location', TrainingLocation.fullGym.name);
      await next(tester);

      await choose(tester, 'coach', CoachStyle.tough.name);
      await next(tester);

      expect(controller.saved, hasLength(1));
      final saved = controller.saved.single;
      expect(saved.goal, Goal.hybrid);
      expect(saved.runWeekdays, {6});
      expect(saved.level, Level.advanced);
      expect(saved.ageYears, 41);
      expect(saved.injuries, {BodyPart.knees});
      expect(saved.location, TrainingLocation.fullGym);
      expect(saved.coachStyle, CoachStyle.tough);
    });

    testWidgets('the run days question appears only for the hybrid goal',
        (tester) async {
      await start(tester);
      await tester.tap(find.byKey(UiKeys.disclaimerAccept));
      await tester.pumpAndSettle();
      await next(tester);

      await choose(tester, 'goal', Goal.weightLoss.name);
      await next(tester);
      expect(find.byKey(UiKeys.questionRunDays), findsNothing);
      expect(find.byKey(UiKeys.questionSchedule), findsOneWidget);
    });

    testWidgets('abandoning the hybrid goal removes the run days step',
        (tester) async {
      // The step list is derived from the draft, so going back and changing
      // the goal has to shorten it without leaving the flow on a step that
      // no longer exists.
      await start(tester);
      await tester.tap(find.byKey(UiKeys.disclaimerAccept));
      await tester.pumpAndSettle();
      await next(tester);

      await choose(tester, 'goal', Goal.hybrid.name);
      await next(tester);
      expect(find.byKey(UiKeys.questionRunDays), findsOneWidget);

      await scrollAndTap(tester, find.byKey(UiKeys.onboardingBack));
      await choose(tester, 'goal', Goal.muscleBuilding.name);
      await next(tester);

      expect(find.byKey(UiKeys.questionRunDays), findsNothing);
      expect(find.byKey(UiKeys.questionSchedule), findsOneWidget);
    });

    testWidgets('equipment the location already implies is not offered',
        (tester) async {
      // Offering a full-gym member a pull-up bar is noise; offering a
      // bodyweight-at-home user a cable machine is a lie.
      await start(tester);
      await tester.tap(find.byKey(UiKeys.disclaimerAccept));
      await tester.pumpAndSettle();
      // disclaimer, goal, schedule, level, body, injuries, then location.
      for (var step = 0; step < 6; step++) {
        await next(tester);
      }

      expect(find.byKey(UiKeys.questionLocation), findsOneWidget);
      expect(
        find.byKey(UiKeys.choice('equipment', Equipment.pullUpBar.name)),
        findsOneWidget,
        reason: 'the default location is home with nothing',
      );

      await choose(tester, 'location', TrainingLocation.fullGym.name);

      expect(
        find.byKey(UiKeys.choice('equipment', Equipment.pullUpBar.name)),
        findsNothing,
      );
    });
  });

  group('navigation', () {
    testWidgets('there is no way back from the first step', (tester) async {
      await start(tester);

      expect(find.byKey(UiKeys.onboardingBack), findsNothing);
    });

    testWidgets('back returns to the previous question', (tester) async {
      await start(tester);
      await tester.tap(find.byKey(UiKeys.disclaimerAccept));
      await tester.pumpAndSettle();
      await next(tester);
      expect(find.byKey(UiKeys.questionGoal), findsOneWidget);

      await scrollAndTap(tester, find.byKey(UiKeys.onboardingBack));

      expect(find.byKey(UiKeys.disclaimerAccept), findsOneWidget);
      expect(find.byKey(UiKeys.questionGoal), findsNothing);
    });
  });

  testWidgets('a failed save is shown and the user stays put', (tester) async {
    await start(tester, saveError: ArgumentError('storage is full'));
    await tester.tap(find.byKey(UiKeys.disclaimerAccept));
    await tester.pumpAndSettle();
    for (var step = 0; step < 8; step++) {
      await next(tester);
    }

    expect(find.textContaining('storage is full'), findsOneWidget);
    expect(find.byKey(UiKeys.onboarding), findsOneWidget);
  });
}
