import 'dart:async';

import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:pose_camera/fake.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/domain/workout_session.dart';
import 'package:spottr/l10n/app_localizations_en.dart';
import 'package:spottr/l10n/plan_strings.dart';
import 'package:spottr/ui/common/ui_keys.dart';
import 'package:spottr/ui/session/session_screen.dart';

import '../support/fakes.dart';
import '../support/profiles.dart';
import '../support/pump.dart';

/// What the logging screen shows, and what a tap asks for. Whether the
/// request is then carried out correctly belongs to the controller's tests,
/// and what progression decides belongs to the plan engine's.
void main() {
  final l10n = AppLocalizationsEn();
  final strings = PlanStrings(l10n, standardCatalog);
  final plan = PlanGenerator(standardCatalog)
      .generate(onboardedProfile().toPlanRequest());
  final day = plan.days.first;
  final first = day.exercises.first;

  late RecordingSessionController controller;

  /// The session list's own scroll view. Every text field on the screen is
  /// a scrollable too, so `scrollUntilVisible` has to be told which one.
  final sessionScrollable = find
      .descendant(
        of: find.byKey(UiKeys.sessionScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  WorkoutSession sessionWith({
    List<LoggedSet> sets = const [],
    bool painReported = false,
    int? weekday,
  }) =>
      WorkoutSession(
        id: 'session_1',
        planDayId: 'plan_1_d${weekday ?? day.weekday}',
        weekday: weekday ?? day.weekday,
        startedAt: DateTime.utc(2026, 10, 31, 9),
        painReported: painReported,
        sets: sets,
      );

  LoggedSet logged(
    String exerciseId, {
    int index = 0,
    int? reps = 10,
    int? holdSeconds,
    double? weightKg,
  }) =>
      LoggedSet(
        id: 'set_$exerciseId$index',
        exerciseId: exerciseId,
        setIndex: index,
        reps: reps,
        holdSeconds: holdSeconds,
        weightKg: weightKg,
        completedAt: DateTime.utc(2026, 10, 31, 9, index),
      );

  Future<void> start(
    WidgetTester tester, {
    WorkoutSession? session,
    WeekPlan? withPlan,
    int? weekday,
    List<ProgressionDecision> decisions = const [],
    Stream<WorkoutSession?> Function()? sessionStream,
    Stream<WeekPlan?> Function()? planStream,
    bool settled = true,
  }) =>
      pumpScreen(
        tester,
        SessionScreen(weekday: weekday ?? day.weekday),
        plan: withPlan ?? plan,
        planStream: planStream,
        session: session ?? sessionWith(),
        sessionStream: sessionStream,
        settled: settled,
        overrides: [
          sessionControllerProvider.overrideWithValue(
            controller = RecordingSessionController(decisions: decisions),
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

    testWidgets('error, with a way out of it', (tester) async {
      await start(
        tester,
        planStream: () => Stream.error(StateError('no plan')),
      );

      expect(find.byKey(UiKeys.errorPanel), findsOneWidget);
      expect(find.byKey(UiKeys.retry), findsOneWidget);
    });

    testWidgets('a weekday the plan has no session for', (tester) async {
      final taken = plan.days.map((d) => d.weekday).toSet();
      final free = [1, 2, 3, 4, 5, 6, 7].firstWhere((d) => !taken.contains(d));

      await start(tester, weekday: free);

      expect(find.byKey(UiKeys.sessionEmpty), findsOneWidget);
      expect(find.byKey(UiKeys.sessionScreen), findsNothing);
    });

    testWidgets('a session that ended somewhere else', (tester) async {
      await start(tester, sessionStream: () => Stream.value(null));

      expect(find.byKey(UiKeys.sessionOver), findsOneWidget);
    });

    testWidgets('a live session lists the day', (tester) async {
      await start(tester);

      expect(find.byKey(UiKeys.sessionScreen), findsOneWidget);
      expect(
        find.text(strings.exercise(first.exerciseId)),
        findsOneWidget,
      );
      expect(find.byKey(UiKeys.sessionFinish), findsOneWidget);
    });
  });

  group('one exercise', () {
    testWidgets('shows what was asked for next to the fields', (tester) async {
      await start(tester);

      final card = find.byKey(UiKeys.sessionExercise(first.exerciseId));
      expect(card, findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining(strings.prescription(first)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining(l10n.sessionNoTarget),
        ),
        findsOneWidget,
        reason: 'no weight has been logged for it yet',
      );
    });

    testWidgets('shows the target weight once progression has set one',
        (tester) async {
      final progressed = plan.copyWith(
        days: [
          day.copyWith(
            exercises: [
              first.copyWith(targetWeightKg: 62.5),
              ...day.exercises.skip(1),
            ],
          ),
          ...plan.days.skip(1),
        ],
      );

      await start(tester, withPlan: progressed);

      expect(find.textContaining('62.5'), findsWidgets);
    });

    testWidgets('saving a set asks for the reps and the weight typed',
        (tester) async {
      await start(tester);

      await tester.enterText(
        find.byKey(UiKeys.sessionReps(first.exerciseId)),
        '9',
      );
      await tester.enterText(
        find.byKey(UiKeys.sessionWeight(first.exerciseId)),
        '62.5',
      );
      await scrollAndTap(
        tester,
        find.byKey(UiKeys.sessionSaveSet(first.exerciseId)),
        scrollable: sessionScrollable,
      );

      final call = controller.lastCallTo('logSet')!;
      expect(call.arguments['exerciseId'], first.exerciseId);
      expect(call.arguments['reps'], 9);
      expect(call.arguments['weightKg'], 62.5);
      expect(call.arguments['setIndex'], 0);
    });

    testWidgets('a blank weight logs bodyweight rather than nothing',
        (tester) async {
      await start(tester);

      await tester.enterText(
        find.byKey(UiKeys.sessionWeight(first.exerciseId)),
        '',
      );
      await scrollAndTap(
        tester,
        find.byKey(UiKeys.sessionSaveSet(first.exerciseId)),
        scrollable: sessionScrollable,
      );

      final call = controller.lastCallTo('logSet')!;
      expect(call.arguments['weightKg'], isNull);
      expect(call.arguments['reps'], first.repsMax);
    });

    testWidgets('a set with no reps is refused and says so', (tester) async {
      await start(tester);

      await tester.enterText(
        find.byKey(UiKeys.sessionReps(first.exerciseId)),
        '',
      );
      await scrollAndTap(
        tester,
        find.byKey(UiKeys.sessionSaveSet(first.exerciseId)),
        scrollable: sessionScrollable,
      );

      expect(controller.names, isNot(contains('logSet')));
      expect(find.text(l10n.sessionNumberRequired), findsOneWidget);
    });

    testWidgets('the next set is numbered after the ones already logged',
        (tester) async {
      await start(
        tester,
        session: sessionWith(
          sets: [
            logged(first.exerciseId, index: 0, weightKg: 60),
            logged(first.exerciseId, index: 1, weightKg: 60),
          ],
        ),
      );

      expect(find.text(l10n.sessionLogSet(3)), findsOneWidget);
      expect(
        find.text(l10n.sessionSetsDone(2, first.sets)),
        findsOneWidget,
      );

      await scrollAndTap(
        tester,
        find.byKey(UiKeys.sessionSaveSet(first.exerciseId)),
        scrollable: sessionScrollable,
      );
      expect(controller.lastCallTo('logSet')!.arguments['setIndex'], 2);
    });

    testWidgets('a finished exercise offers no more sets', (tester) async {
      await start(
        tester,
        session: sessionWith(
          sets: [
            for (var index = 0; index < first.sets; index++)
              logged(first.exerciseId, index: index),
          ],
        ),
      );

      expect(find.text(l10n.sessionExerciseDone), findsOneWidget);
      expect(
        find.byKey(UiKeys.sessionSaveSet(first.exerciseId)),
        findsNothing,
      );
    });

    testWidgets('a hold is logged in seconds, with no weight field',
        (tester) async {
      final held = plan.days
          .expand((d) => d.exercises)
          .firstWhere((e) => e.metric == MetricType.holdSeconds);
      final holdDay =
          plan.days.firstWhere((d) => d.exercises.contains(held));

      await start(
        tester,
        weekday: holdDay.weekday,
        session: sessionWith(weekday: holdDay.weekday),
      );

      await scrollAndTap(
        tester,
        find.byKey(UiKeys.sessionSaveSet(held.exerciseId)),
        scrollable: sessionScrollable,
      );

      final call = controller.lastCallTo('logSet')!;
      expect(call.arguments['holdSeconds'], held.holdSeconds);
      expect(call.arguments['reps'], isNull);
      expect(find.byKey(UiKeys.sessionWeight(held.exerciseId)), findsNothing);
    });
  });

  group('pain', () {
    testWidgets('the button is on screen without scrolling', (tester) async {
      await start(tester);

      expect(find.byKey(UiKeys.sessionPain), findsOneWidget);
    });

    testWidgets('confirming logs it', (tester) async {
      await start(tester);

      await tester.tap(find.byKey(UiKeys.sessionPain));
      await tester.pumpAndSettle();
      expect(find.text(l10n.sessionPainBody), findsOneWidget);

      await tester.tap(find.byKey(UiKeys.sessionPainConfirm));
      await tester.pumpAndSettle();

      expect(controller.names, contains('reportPain'));
    });

    testWidgets('backing out of the dialog logs nothing', (tester) async {
      await start(tester);

      await tester.tap(find.byKey(UiKeys.sessionPain));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.planCancel));
      await tester.pumpAndSettle();

      expect(controller.names, isEmpty);
    });

    testWidgets('a session with pain reported says so on screen',
        (tester) async {
      await start(tester, session: sessionWith(painReported: true));

      expect(find.byKey(UiKeys.sessionPainBadge), findsOneWidget);
    });
  });

  group('finishing', () {
    testWidgets('asks how it felt, then closes the session', (tester) async {
      await start(tester);

      await scrollAndTap(tester, find.byKey(UiKeys.sessionFinish));
      expect(find.byKey(UiKeys.sessionRatingSheet), findsOneWidget);

      await tester.tap(find.byKey(UiKeys.sessionRating('right')));
      await tester.pumpAndSettle();

      expect(
        controller.lastCallTo('finish')!.arguments['rating'],
        SessionRating.right,
      );
    });

    testWidgets('a skipped rating closes it with no opinion', (tester) async {
      await start(tester);

      await scrollAndTap(tester, find.byKey(UiKeys.sessionFinish));
      await tester.tap(find.byKey(UiKeys.sessionRatingSkip));
      await tester.pumpAndSettle();

      expect(controller.names, contains('finish'));
      expect(controller.lastCallTo('finish')!.arguments['rating'], isNull);
    });

    testWidgets('dismissing the question leaves the session open',
        (tester) async {
      await start(tester);

      await scrollAndTap(tester, find.byKey(UiKeys.sessionFinish));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(controller.names, isNot(contains('finish')));
      expect(find.byKey(UiKeys.sessionScreen), findsOneWidget);
    });

    testWidgets('the summary says what changed and why', (tester) async {
      final decision = ProgressionDecision(
        exerciseId: first.exerciseId,
        change: ProgressionChange.loadUp,
        reason: ProgressionReason.earnedLoad,
        nextWeightKg: 62.5,
        repsAchieved: first.repsMax,
      );

      await start(tester, decisions: [decision]);

      await scrollAndTap(tester, find.byKey(UiKeys.sessionFinish));
      await tester.tap(find.byKey(UiKeys.sessionRating('right')));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.sessionSummary), findsOneWidget);
      expect(find.text(strings.progression(decision)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(UiKeys.sessionSummary),
          matching: find.text(strings.exercise(first.exerciseId)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the summary is left over the week, not over the workout',
        (tester) async {
      // Finishing closes the session, which empties the stream the session
      // screen is built from — so the summary cannot be shown from that
      // screen's own context, and has to outlive the route. Showing it there
      // and popping afterwards dismisses the summary instead of the workout,
      // which is what happened on a device while every stubbed test passed.
      // Not a broadcast controller: Riverpod subscribes a frame or so after
      // the screen is pushed, and a broadcast stream would drop the session
      // added before that.
      final live = StreamController<WorkoutSession?>();
      addTearDown(live.close);
      final decision = ProgressionDecision(
        exerciseId: first.exerciseId,
        change: ProgressionChange.loadUp,
        reason: ProgressionReason.earnedLoad,
        nextWeightKg: 62.5,
        repsAchieved: first.repsMax,
      );

      await pumpScreen(
        tester,
        _Host(weekday: day.weekday),
        plan: plan,
        sessionStream: () => live.stream,
        settled: false,
        overrides: [
          sessionControllerProvider.overrideWithValue(
            controller = RecordingSessionController(
              decisions: [decision],
              onFinish: () async => live.add(null),
            ),
          ),
        ],
      );
      live.add(sessionWith());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_Host.open));
      await tester.pumpAndSettle();
      expect(find.byKey(UiKeys.sessionScreen), findsOneWidget);

      await scrollAndTap(tester, find.byKey(UiKeys.sessionFinish));
      await tester.tap(find.byKey(UiKeys.sessionRating('right')));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.sessionSummary), findsOneWidget);
      expect(find.text(strings.progression(decision)), findsOneWidget);
      expect(
        find.byKey(UiKeys.sessionOver),
        findsNothing,
        reason: 'the workout route is still behind the summary, which means '
            'dismissing the summary dismisses the workout instead',
      );
    });

    testWidgets('a session that changed nothing still gets a summary',
        (tester) async {
      await start(tester);

      await scrollAndTap(tester, find.byKey(UiKeys.sessionFinish));
      await tester.tap(find.byKey(UiKeys.sessionRating('tooHard')));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.sessionSummary), findsOneWidget);
      expect(find.text(l10n.sessionSummaryEmpty), findsOneWidget);
    });
  });

  group('discarding', () {
    testWidgets('asks first, then throws the session away', (tester) async {
      await start(tester);

      await tester.tap(find.byKey(UiKeys.sessionDiscard));
      await tester.pumpAndSettle();
      expect(find.text(l10n.sessionDiscardBody), findsOneWidget);

      await tester.tap(find.byKey(UiKeys.sessionDiscardConfirm));
      await tester.pumpAndSettle();

      expect(controller.names, contains('discard'));
    });

    testWidgets('backing out keeps the session', (tester) async {
      await start(tester);

      await tester.tap(find.byKey(UiKeys.sessionDiscard));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.planCancel));
      await tester.pumpAndSettle();

      expect(controller.names, isEmpty);
      expect(find.byKey(UiKeys.sessionScreen), findsOneWidget);
    });
  });

  group('the camera check', () {
    /// A day the generator fills with camera-coached movements, and one
    /// exercise on it the coach has no rules for.
    String coached() => day.exercises
        .map((exercise) => exercise.exerciseId)
        .firstWhere(
          (id) => standardCatalog.require(id).camera != null,
          orElse: () => '',
        );

    String uncoached() => day.exercises
        .map((exercise) => exercise.exerciseId)
        .firstWhere(
          (id) => standardCatalog.require(id).camera == null,
          orElse: () => '',
        );

    testWidgets('is offered on a movement the coach has rules for',
        (tester) async {
      await start(tester);
      final id = coached();
      expect(id, isNotEmpty, reason: 'the generated day has nothing coachable');

      await tester.scrollUntilVisible(
        find.byKey(UiKeys.sessionExercise(id)),
        120,
        scrollable: sessionScrollable,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.sessionCoach(id)), findsOneWidget);
    });

    testWidgets('is not offered on one it cannot judge', (tester) async {
      // Offering it would be a promise the next two milestones have to
      // break: there are no rules for a curl and there will not be.
      await start(tester);
      final id = uncoached();
      expect(id, isNotEmpty, reason: 'the generated day is all coachable');

      await tester.scrollUntilVisible(
        find.byKey(UiKeys.sessionExercise(id)),
        120,
        scrollable: sessionScrollable,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.sessionCoach(id)), findsNothing);
    });

    testWidgets('opens the check, and comes back to the session',
        (tester) async {
      final camera = FakePoseCamera();
      await pumpScreen(
        tester,
        SessionScreen(weekday: day.weekday),
        plan: plan,
        session: sessionWith(),
        camera: camera,
        overrides: [
          sessionControllerProvider.overrideWithValue(
            RecordingSessionController(),
          ),
        ],
      );

      final id = coached();
      await tester.scrollUntilVisible(
        find.byKey(UiKeys.sessionExercise(id)),
        120,
        scrollable: sessionScrollable,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.sessionCoach(id)));
      await tester.pumpAndSettle();
      expect(find.byKey(UiKeys.coachScreen), findsOneWidget);
      expect(camera.isRunning, isTrue);

      await tester.tap(find.byKey(UiKeys.coachDone));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.sessionScreen), findsOneWidget);
      // Leaving the check puts the camera down. Nothing else on the way
      // back through the session would.
      expect(camera.isRunning, isFalse);
    });
  });
}

/// Stands in for the plan screen: somewhere to come back to, so that
/// finishing can actually leave the session route.
class _Host extends StatelessWidget {
  const _Host({required this.weekday});

  static const Key open = Key('test.openSession');

  final int weekday;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            key: open,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => SessionScreen(weekday: weekday),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
}
