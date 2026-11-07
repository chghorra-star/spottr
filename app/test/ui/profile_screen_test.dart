import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/data/local/local_identity_store.dart';
import 'package:spottr/data/sync/sync_account.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/l10n/app_localizations.dart';
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
  late RecordingEraseController eraser;

  /// Opens the profile screen the way the user does: from the plan.
  Future<void> openProfile(
    WidgetTester tester, {
    UserProfile? profile,
    Object? saveError,
    Object? eraseError,
    DeviceOwner? owner,
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
        eraseControllerProvider.overrideWithValue(
          eraser = RecordingEraseController(
            onErase: eraseError == null ? null : () async => throw eraseError,
          ),
        ),
        accountProvider.overrideWith(
          (ref) => Stream.value(AccountState(owner: owner)),
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

  group('deleting everything on this device', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    /// Drags the form to its true end.
    ///
    /// Not `scrollUntilVisible`, which needs the thing it is looking for to
    /// exist: the test that the control is *absent* has to reach the bottom
    /// without it. And not a fixed number of drags either — a `ListView`
    /// does not build children below the viewport, so an assertion that
    /// stopped short would pass whether the button was there or not. This
    /// stops only when the scroll position is at `maxScrollExtent`, which
    /// is the one place where "not in the tree" means "not offered".
    Future<void> dragToEnd(WidgetTester tester) async {
      final position = tester.state<ScrollableState>(profileScroll).position;
      while (position.pixels < position.maxScrollExtent) {
        final before = position.pixels;
        await tester.drag(profileScroll, const Offset(0, -500));
        await tester.pumpAndSettle();
        if (position.pixels <= before) break;
      }
      expect(
        position.pixels,
        position.maxScrollExtent,
        reason: 'the assertions below are about the bottom of the form',
      );
    }

    testWidgets('a device nobody has signed in on offers it', (tester) async {
      // The gap this closes. A build with no Supabase project never claims
      // an owner, so its account screen offers no erase — and before this
      // there was no other way to delete anything from inside the app.
      await openProfile(tester);
      await dragToEnd(tester);

      expect(find.byKey(UiKeys.profileDelete), findsOneWidget);
    });

    testWidgets("a device that holds an account's training does not",
        (tester) async {
      // Not because deleting is wrong there, but because the sentence here
      // would be: whatever synced is still in the account, which is the
      // account screen's door and its wording.
      await openProfile(
        tester,
        owner: const DeviceOwner(userId: 'user-1', email: 'a@example.com'),
      );
      await dragToEnd(tester);

      expect(find.byKey(UiKeys.profileDelete), findsNothing);
      expect(find.text(l10n.profileDeleteTitle), findsNothing);
    });

    testWidgets('asks first, and says there is no copy of it anywhere',
        (tester) async {
      await openProfile(tester);
      await dragToEnd(tester);
      await tester.tap(find.byKey(UiKeys.profileDelete));
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileDeleteConfirmBody), findsOneWidget);
      expect(eraser.erases, 0, reason: 'nothing until it is confirmed');
      // Pinned, not decoration. This control is shown only on a device
      // nobody has signed in on, which is exactly the case where nothing
      // has ever left the phone — so the question can say so, and has to.
      expect(l10n.profileDeleteConfirmBody, contains('no copy'));
      expect(l10n.profileDeleteConfirmBody, contains('no undo'));
    });

    testWidgets('keeping it deletes nothing', (tester) async {
      await openProfile(tester);
      await dragToEnd(tester);
      await tester.tap(find.byKey(UiKeys.profileDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UiKeys.profileDeleteCancel));
      await tester.pumpAndSettle();

      expect(eraser.erases, 0);
      expect(find.byKey(UiKeys.profileScreen), findsOneWidget);
    });

    testWidgets('deleting it erases everything and leaves the screen',
        (tester) async {
      // Leaving rather than reporting: the form it was on has nothing left
      // to show, and the router underneath is already on its way to
      // onboarding now the profile row is gone.
      await openProfile(tester);
      await dragToEnd(tester);
      await tester.tap(find.byKey(UiKeys.profileDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UiKeys.profileDeleteConfirm));
      await tester.pumpAndSettle();

      expect(eraser.erases, 1);
      expect(find.byKey(UiKeys.profileScreen), findsNothing);
    });

    testWidgets('a delete that failed says the training is still here',
        (tester) async {
      await openProfile(tester, eraseError: StateError('database is locked'));
      await dragToEnd(tester);
      await tester.tap(find.byKey(UiKeys.profileDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UiKeys.profileDeleteConfirm));
      await tester.pumpAndSettle();

      // Still here, and said so where the button is rather than at the top
      // of a form the user has scrolled to the bottom of.
      expect(find.byKey(UiKeys.profileScreen), findsOneWidget);
      expect(find.byKey(UiKeys.profileDeleteError), findsOneWidget);
      expect(find.text(l10n.profileDeleteFailed), findsOneWidget);
    });
  });
}
