import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/l10n/app_localizations_en.dart';
import 'package:spottr/l10n/plan_strings.dart';
import 'package:spottr/ui/common/ui_keys.dart';

import '../support/fakes.dart';
import '../support/profiles.dart';
import '../support/pump.dart';

void main() {
  final generator = PlanGenerator(standardCatalog);
  final strings = PlanStrings(AppLocalizationsEn(), standardCatalog);

  WeekPlan planFor(UserProfile profile) =>
      generator.generate(profile.toPlanRequest());

  late RecordingPlanController controller;

  Future<void> start(
    WidgetTester tester, {
    UserProfile? profile,
    WeekPlan? plan,
    List<Exercise> alternatives = const [],
    Stream<WeekPlan?> Function()? planStream,
    bool settled = true,
  }) =>
      pumpApp(
        tester,
        profile: profile ?? onboardedProfile(),
        plan: plan,
        planStream: planStream,
        settled: settled,
        overrides: [
          planControllerProvider.overrideWithValue(
            controller = RecordingPlanController(alternatives: alternatives),
          ),
        ],
      );

  group('states', () {
    testWidgets('loading', (tester) async {
      await start(
        tester,
        planStream: () => const Stream.empty(),
        settled: false,
      );

      expect(find.byKey(UiKeys.loading), findsOneWidget);
    });

    testWidgets('empty, with a way to build a week', (tester) async {
      await start(tester);

      expect(find.byKey(UiKeys.planEmpty), findsOneWidget);
      expect(find.byKey(UiKeys.planScreen), findsNothing);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(controller.names, ['regenerate']);
    });

    testWidgets('error, with a way out of it', (tester) async {
      await start(
        tester,
        planStream: () => Stream<WeekPlan?>.error(
          const FormatException('bad note json'),
        ),
      );

      expect(find.byKey(UiKeys.errorPanel), findsOneWidget);
      expect(find.byKey(UiKeys.retry), findsOneWidget);
    });

    testWidgets('success', (tester) async {
      final profile = onboardedProfile();
      final plan = planFor(profile);
      await start(tester, profile: profile, plan: plan);

      expect(find.byKey(UiKeys.planScreen), findsOneWidget);
      for (final day in plan.days) {
        // The day list is lazy, so a card further down the week only exists
        // once it has been scrolled to.
        final card = find.byKey(UiKeys.planDay(day.weekday));
        await tester.scrollUntilVisible(card, 300, maxScrolls: 60);
        expect(
          card,
          findsOneWidget,
          reason: 'no card for weekday ${day.weekday}',
        );
      }
    });
  });

  group('a day card', () {
    testWidgets('names every exercise and what to do with it',
        (tester) async {
      final profile = onboardedProfile();
      final plan = planFor(profile);
      await start(tester, profile: profile, plan: plan);

      final day = plan.days.first;
      for (final exercise in day.exercises) {
        expect(
          find.text(strings.exercise(exercise.exerciseId)),
          findsOneWidget,
          reason: exercise.exerciseId,
        );
      }
      expect(
        find.textContaining(strings.prescription(day.exercises.first)),
        findsWidgets,
      );
    });

    testWidgets('warns when a run follows the next day', (tester) async {
      final profile = onboardedProfile(
        goal: Goal.hybrid,
        daysPerWeek: 4,
        runWeekdays: {3, 7},
      );
      final plan = planFor(profile);
      final preRun = plan.days.where((d) => d.precedesRunDay);
      expect(preRun, isNotEmpty, reason: 'premise: a day precedes a run');

      await start(tester, profile: profile, plan: plan);

      expect(
        find.text(AppLocalizationsEn().planPreRunBadge),
        findsNWidgets(preRun.length),
      );
    });

    testWidgets('marks the exercises the camera can coach', (tester) async {
      final profile = onboardedProfile();
      final plan = planFor(profile);
      final coached = plan.days.first.exercises.where(
        (e) => standardCatalog.require(e.exerciseId).isCameraSupported,
      );
      expect(coached, isNotEmpty, reason: 'premise: a coached exercise');

      await start(tester, profile: profile, plan: plan);

      expect(
        find.descendant(
          of: find.byKey(UiKeys.planDay(plan.days.first.weekday)),
          matching: find.byIcon(Icons.videocam_outlined),
        ),
        findsNWidgets(coached.length),
      );
    });
  });

  group('explaining the week', () {
    testWidgets('shows the notes as prose when there are any',
        (tester) async {
      final profile = onboardedProfile(
        daysPerWeek: 6,
        sessionMinutes: 25,
        location: TrainingLocation.homeNone,
        level: Level.beginner,
      );
      final plan = planFor(profile);
      expect(plan.notes, isNotEmpty, reason: 'premise: this week has notes');

      await start(tester, profile: profile, plan: plan);
      await tester.scrollUntilVisible(
        find.byKey(UiKeys.planNotes),
        200,
        maxScrolls: 60,
      );

      expect(find.byKey(UiKeys.planNotes), findsOneWidget);
      expect(find.text(strings.note(plan.notes.first)), findsOneWidget);
    });

    testWidgets('says nothing when there is nothing to explain',
        (tester) async {
      final profile = onboardedProfile();
      final plan = planFor(profile);
      expect(plan.notes, isEmpty, reason: 'premise: a clean week');

      await start(tester, profile: profile, plan: plan);

      expect(find.byKey(UiKeys.planNotes), findsNothing);
    });

    testWidgets('shows a running suggestion against each run day',
        (tester) async {
      // The generator emits the same suggestion once per run day, so the
      // day has to be on the line: otherwise the section is one sentence
      // printed twice, which is what it looked like on a device.
      final profile = onboardedProfile(goal: Goal.hybrid, runWeekdays: {3, 6});
      final plan = planFor(profile);
      expect(plan.runSuggestionKeys, hasLength(2));

      await start(tester, profile: profile, plan: plan);
      await tester.scrollUntilVisible(
        find.byKey(UiKeys.planRunSuggestions),
        200,
        maxScrolls: 60,
      );

      expect(find.byKey(UiKeys.planRunSuggestions), findsOneWidget);
      for (final weekday in [3, 6]) {
        expect(
          find.text(
            '${strings.weekday(weekday)} · '
            '${strings.runSuggestion(plan.runSuggestionKeys.first)}',
          ),
          findsOneWidget,
          reason: 'no suggestion against weekday $weekday',
        );
      }
    });

    testWidgets('shows no running section for a gym-only week',
        (tester) async {
      final profile = onboardedProfile();
      await start(tester, profile: profile, plan: planFor(profile));

      expect(find.byKey(UiKeys.planRunSuggestions), findsNothing);
    });
  });

  group('swapping an exercise', () {
    testWidgets('offers the alternatives and applies the one tapped',
        (tester) async {
      final profile = onboardedProfile();
      final plan = planFor(profile);
      final day = plan.days.first;
      final target = day.exercises.first.exerciseId;
      final alternative = standardCatalog.require('db_bench_press');

      await start(
        tester,
        profile: profile,
        plan: plan,
        alternatives: [alternative],
      );

      await tester.tap(
        find.byKey(UiKeys.planExerciseMenu(day.weekday, target)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.swapSheet), findsOneWidget);
      expect(
        controller.lastCallTo('alternativesFor')!.arguments,
        {'weekday': day.weekday, 'exerciseId': target},
      );
      expect(find.byKey(UiKeys.swapOption(alternative.id)), findsOneWidget);

      await tester.tap(find.byKey(UiKeys.swapOption(alternative.id)));
      await tester.pumpAndSettle();

      expect(
        controller.lastCallTo('swap')!.arguments,
        {
          'weekday': day.weekday,
          'exerciseId': target,
          'replacementId': alternative.id,
        },
      );
      expect(find.byKey(UiKeys.swapSheet), findsNothing);
    });

    testWidgets('says so when the catalog has nothing to offer',
        (tester) async {
      final profile = onboardedProfile();
      final plan = planFor(profile);
      final day = plan.days.first;

      await start(tester, profile: profile, plan: plan);

      await tester.tap(
        find.byKey(
          UiKeys.planExerciseMenu(day.weekday, day.exercises.first.exerciseId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.swapEmpty), findsOneWidget);
      expect(
        find.text(AppLocalizationsEn().swapNoAlternatives),
        findsOneWidget,
      );
    });
  });

  group('moving a day', () {
    testWidgets('moves it to a free weekday', (tester) async {
      final profile = onboardedProfile(daysPerWeek: 2);
      final plan = planFor(profile);
      final from = plan.days.first.weekday;
      final taken = plan.days.map((d) => d.weekday).toSet();
      final free = [1, 2, 3, 4, 5, 6, 7].firstWhere((d) => !taken.contains(d));

      await start(tester, profile: profile, plan: plan);

      await tester.tap(
        find.descendant(
          of: find.byKey(UiKeys.planDay(from)),
          matching: find.byIcon(Icons.calendar_today_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(UiKeys.moveDaySheet), findsOneWidget);

      await scrollAndTap(tester, find.byKey(UiKeys.moveDayOption(free)));

      expect(
        controller.lastCallTo('moveDay')!.arguments,
        {'fromWeekday': from, 'toWeekday': free},
      );
    });

    testWidgets('will not move it onto a day that already has a session',
        (tester) async {
      final profile = onboardedProfile(daysPerWeek: 2);
      final plan = planFor(profile);
      final from = plan.days.first.weekday;
      final occupied = plan.days.last.weekday;

      await start(tester, profile: profile, plan: plan);
      await tester.tap(
        find.descendant(
          of: find.byKey(UiKeys.planDay(from)),
          matching: find.byIcon(Icons.calendar_today_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizationsEn().moveDayOccupied),
        findsOneWidget,
      );

      await scrollAndTap(
        tester,
        find.byKey(UiKeys.moveDayOption(occupied)),
      );

      expect(controller.names, isNot(contains('moveDay')));
    });
  });

  group('reordering a day', () {
    testWidgets('passes the drag straight through to the plan',
        (tester) async {
      // `onReorderItem` already accounts for the dragged row having been
      // lifted out, so the screen must not adjust the index itself. The
      // older `onReorder` did not, and an app that silently re-derives the
      // destination would move rows to the wrong place in one direction
      // only — which is exactly the sort of thing a drag simulation would
      // be too coarse to catch.
      final profile = onboardedProfile();
      final plan = planFor(profile);
      final day = plan.days.first;

      await start(tester, profile: profile, plan: plan);
      await tester.tap(
        find.descendant(
          of: find.byKey(UiKeys.planDay(day.weekday)),
          matching: find.byIcon(Icons.swap_vert),
        ),
      );
      await tester.pumpAndSettle();

      final list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );

      list.onReorderItem!(0, 2);
      expect(
        controller.lastCallTo('reorder')!.arguments,
        {'weekday': day.weekday, 'fromIndex': 0, 'toIndex': 2},
      );

      list.onReorderItem!(3, 0);
      expect(
        controller.lastCallTo('reorder')!.arguments,
        {'weekday': day.weekday, 'fromIndex': 3, 'toIndex': 0},
      );
    });
  });

  group('rebuilding the week', () {
    testWidgets('asks before discarding the edits', (tester) async {
      final profile = onboardedProfile();
      await start(tester, profile: profile, plan: planFor(profile));

      await tester.tap(find.byKey(UiKeys.planRebuild));
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizationsEn().planRegenerateBody),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().planCancel));
      await tester.pumpAndSettle();

      expect(controller.names, isNot(contains('regenerate')));
    });

    testWidgets('rebuilds once confirmed', (tester) async {
      final profile = onboardedProfile();
      await start(tester, profile: profile, plan: planFor(profile));

      await tester.tap(find.byKey(UiKeys.planRebuild));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(UiKeys.planRebuildConfirm));
      await tester.pumpAndSettle();

      expect(controller.names, contains('regenerate'));
    });
  });
}
