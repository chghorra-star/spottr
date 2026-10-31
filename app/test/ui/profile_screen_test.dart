import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/ui/common/ui_keys.dart';
import 'package:spottr/ui/plan/plan_screen.dart';

import '../support/fakes.dart';
import '../support/profiles.dart';
import '../support/pump.dart';

void main() {
  final generator = PlanGenerator(standardCatalog);

  /// The profile form's own scroll view.
  ///
  /// Scoped and then narrowed to the first match: the plan screen stays
  /// mounted under the pushed route with a scroll view of its own, and the
  /// text fields in the form each bring an inner one. The form's list is
  /// the first scrollable inside the screen.
  final profileScroll = find
      .descendant(
        of: find.byKey(UiKeys.profileScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  late RecordingProfileController controller;

  /// Opens the profile screen the way the user does: from the plan.
  Future<void> openProfile(
    WidgetTester tester, {
    UserProfile? profile,
    Object? saveError,
  }) async {
    final stored = profile ?? onboardedProfile();
    await pumpApp(
      tester,
      profile: stored,
      plan: generator.generate(stored.toPlanRequest()),
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

    await tester.tap(find.byKey(UiKeys.planOpenProfile));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the questions with the stored answers selected',
      (tester) async {
    await openProfile(
      tester,
      profile: onboardedProfile(
        goal: Goal.hybrid,
        level: Level.advanced,
        runWeekdays: {4},
      ),
    );

    expect(find.byKey(UiKeys.profileScreen), findsOneWidget);
    expect(find.byKey(UiKeys.questionGoal), findsOneWidget);
    // Run days are only part of the form while the goal still runs.
    expect(find.byKey(UiKeys.questionRunDays), findsOneWidget);

    final selected = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(UiKeys.choice('goal', Goal.hybrid.name)),
        matching: find.byType(Icon),
      ),
    );
    expect(selected.icon, Icons.radio_button_checked);
  });

  testWidgets('hides the run days question for a goal that does not run',
      (tester) async {
    await openProfile(tester, profile: onboardedProfile());

    expect(find.byKey(UiKeys.questionRunDays), findsNothing);
  });

  testWidgets('saving is unavailable until something changes', (tester) async {
    await openProfile(tester);

    expect(
      tester.widget<TextButton>(find.byKey(UiKeys.profileSave)).onPressed,
      isNull,
    );

    await scrollAndTap(tester, find.byKey(UiKeys.choice('coach', CoachStyle.tough.name)), scrollable: profileScroll);

    expect(
      tester.widget<TextButton>(find.byKey(UiKeys.profileSave)).onPressed,
      isNotNull,
    );
  });

  testWidgets('a changed answer is what gets saved', (tester) async {
    await openProfile(tester, profile: onboardedProfile(daysPerWeek: 4));

    await scrollAndTap(tester, find.byKey(UiKeys.choice('level', Level.beginner.name)), scrollable: profileScroll);
    await tester.tap(find.byKey(UiKeys.profileSave));
    await tester.pumpAndSettle();

    expect(controller.saved, hasLength(1));
    expect(controller.saved.single.level, Level.beginner);
    expect(
      controller.saved.single.daysPerWeek,
      4,
      reason: 'answers the user did not touch are untouched',
    );
  });

  testWidgets('saving returns to the plan', (tester) async {
    await openProfile(tester);

    await scrollAndTap(tester, find.byKey(UiKeys.choice('coach', CoachStyle.hype.name)), scrollable: profileScroll);
    await tester.tap(find.byKey(UiKeys.profileSave));
    await tester.pumpAndSettle();

    expect(find.byKey(UiKeys.profileScreen), findsNothing);
    expect(find.byType(PlanScreen), findsOneWidget);
  });

  testWidgets('a failed save is shown and nothing is lost', (tester) async {
    await openProfile(tester, saveError: ArgumentError('disk is full'));

    await scrollAndTap(tester, find.byKey(UiKeys.choice('level', Level.beginner.name)), scrollable: profileScroll);
    await tester.tap(find.byKey(UiKeys.profileSave));
    await tester.pumpAndSettle();

    expect(find.byKey(UiKeys.profileScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('disk is full'),
      -200,
      scrollable: profileScroll,
      maxScrolls: 60,
    );
    expect(find.textContaining('disk is full'), findsOneWidget);
  });

  testWidgets('declaring an injury is part of the same form', (tester) async {
    // The profile screen is the only way to correct an injury answer after
    // onboarding, and getting that wrong is the one change in here that can
    // put a contraindicated exercise back in someone's week.
    await openProfile(tester);

    await scrollAndTap(tester, find.byKey(UiKeys.choice('injury', BodyPart.lowerBack.name)), scrollable: profileScroll);
    await tester.tap(find.byKey(UiKeys.profileSave));
    await tester.pumpAndSettle();

    expect(controller.saved.single.injuries, {BodyPart.lowerBack});
  });
}
