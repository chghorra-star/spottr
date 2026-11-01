import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness/harness.dart';
import 'package:pose_camera/fake.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';
import 'package:spottr/l10n/app_localizations_en.dart';
import 'package:spottr/ui/coach/camera_check_screen.dart';
import 'package:spottr/ui/coach/skeleton_overlay.dart';
import 'package:spottr/ui/common/ui_keys.dart';

import '../support/pump.dart';

/// A squat: camera-supported, recommended from the side.
const _coached = 'bodyweight_squat';

/// A curl: the coach has no rules for it.
const _uncoached = 'db_curl';

final _l10n = AppLocalizationsEn();

Landmark _lm(double x, double y, {double visibility = 1}) =>
    Landmark(x: x, y: y, z: 0, visibility: visibility);

/// Somebody standing well inside the frame.
PoseFrame _wellFramed({int id = 1}) => PoseFrame(
      frameId: id,
      t: Duration(milliseconds: id * 33),
      landmarks: {
        Joint.leftShoulder: _lm(0.44, 0.10),
        Joint.rightShoulder: _lm(0.56, 0.10),
        Joint.leftHip: _lm(0.44, 0.46),
        Joint.rightHip: _lm(0.56, 0.46),
        Joint.leftKnee: _lm(0.44, 0.68),
        Joint.rightKnee: _lm(0.56, 0.68),
        Joint.leftAnkle: _lm(0.44, 0.90),
        Joint.rightAnkle: _lm(0.56, 0.90),
      },
      confidence: 0.9,
    );

PoseFrame _nobody({int id = 1}) => PoseFrame(
      frameId: id,
      t: Duration(milliseconds: id * 33),
      landmarks: const {},
      confidence: 0,
    );

Future<FakePoseCamera> _open(
  WidgetTester tester, {
  String exerciseId = _coached,
  CameraPermissionStatus permission = CameraPermissionStatus.granted,
  PoseCameraException? failStartWith,
}) async {
  final camera = FakePoseCamera(
    permission: permission,
    failStartWith: failStartWith,
  );
  await pumpScreen(
    tester,
    CameraCheckScreen(exerciseId: exerciseId),
    camera: camera,
  );
  return camera;
}

void main() {
  group('CameraCheckScreen permission', () {
    testWidgets('explains why it needs the camera when it has been refused',
        (tester) async {
      await _open(tester, permission: CameraPermissionStatus.denied);

      expect(find.byKey(UiKeys.coachPermission), findsOneWidget);
      expect(find.byKey(UiKeys.coachPermissionAllow), findsOneWidget);
    });

    testWidgets('promises on screen that video stays on the device',
        (tester) async {
      // The brief is explicit that nothing is uploaded, and the moment to
      // say so is the moment the user is deciding whether to allow it.
      final body = _l10n.coachPermissionBody.toLowerCase();

      expect(body, contains('never'));
      expect(body, anyOf(contains('uploaded'), contains('leaves')));

      await _open(tester, permission: CameraPermissionStatus.denied);
      expect(find.text(_l10n.coachPermissionBody), findsOneWidget);
    });

    testWidgets('asks, and starts when the answer is yes', (tester) async {
      final camera = await _open(
        tester,
        permission: CameraPermissionStatus.granted,
      );

      // Granted up front, so it never asks.
      expect(camera.permissionRequests, 0);
      expect(camera.isRunning, isTrue);
    });

    testWidgets('offers no button once only Settings can help', (tester) async {
      // A button that cannot do anything makes the app look broken rather
      // than the setting look wrong.
      await _open(tester, permission: CameraPermissionStatus.permanentlyDenied);

      expect(find.byKey(UiKeys.coachBlocked), findsOneWidget);
      expect(find.byKey(UiKeys.coachPermissionAllow), findsNothing);
    });

    testWidgets('does not open the camera without permission', (tester) async {
      final camera = await _open(
        tester,
        permission: CameraPermissionStatus.denied,
      );

      expect(camera.startedWith, isEmpty);
    });
  });

  group('CameraCheckScreen setup advice', () {
    testWidgets('says where to put the phone for this exercise',
        (tester) async {
      await _open(tester);

      // The squat is coached from the side.
      expect(find.textContaining(_l10n.coachAngleSide), findsOneWidget);
    });

    testWidgets('says what it does not promise', (tester) async {
      await _open(tester);

      expect(find.text(_l10n.coachClaim), findsOneWidget);
    });

    testWidgets('refuses an exercise the coach has no rules for',
        (tester) async {
      await _open(tester, exerciseId: _uncoached);

      expect(find.byKey(UiKeys.coachNotSupported), findsOneWidget);
      expect(find.byKey(UiKeys.coachFraming), findsNothing);
    });
  });

  group('CameraCheckScreen framing', () {
    testWidgets('says it cannot see anybody before a frame arrives',
        (tester) async {
      await _open(tester);

      expect(find.text(_l10n.coachFramingNoPerson), findsOneWidget);
    });

    testWidgets('confirms a well framed body', (tester) async {
      final camera = await _open(tester);

      camera.emit(_wellFramed());
      await tester.pumpAndSettle();

      expect(find.text(_l10n.coachFramingGood), findsOneWidget);
    });

    testWidgets('says so when there is nobody in the frame', (tester) async {
      final camera = await _open(tester);

      camera.emit(_nobody());
      await tester.pumpAndSettle();

      expect(find.text(_l10n.coachFramingNoPerson), findsOneWidget);
    });

    testWidgets('tells somebody standing too near to step back',
        (tester) async {
      final camera = await _open(tester);

      camera.emit(
        PoseFrame(
          frameId: 1,
          t: Duration.zero,
          landmarks: {
            Joint.leftShoulder: _lm(0.44, 0.15),
            Joint.rightShoulder: _lm(0.56, 0.15),
            Joint.leftHip: _lm(0.44, 0.60),
            Joint.rightHip: _lm(0.56, 0.60),
            Joint.leftKnee: _lm(0.44, 0.90),
            Joint.rightKnee: _lm(0.56, 0.90),
            Joint.leftAnkle: _lm(0.44, 1.14),
            Joint.rightAnkle: _lm(0.56, 1.14),
          },
          confidence: 0.9,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_l10n.coachFramingTooClose), findsOneWidget);
    });

    testWidgets('names the body part it has lost', (tester) async {
      final camera = await _open(tester);

      camera.emit(
        PoseFrame(
          frameId: 1,
          t: Duration.zero,
          landmarks: {
            Joint.leftShoulder: _lm(0.44, 0.10),
            Joint.rightShoulder: _lm(0.56, 0.10),
            Joint.leftHip: _lm(0.44, 0.46),
            Joint.rightHip: _lm(0.56, 0.46),
            Joint.leftKnee: _lm(0.44, 0.68),
            Joint.rightKnee: _lm(0.56, 0.68),
          },
          confidence: 0.9,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_l10n.coachFramingMissingAnkles), findsOneWidget);
    });

    testWidgets('draws the skeleton it is tracking', (tester) async {
      // The only honest answer to "is it working": a verdict in words can
      // be right about a body it has mislocated.
      final camera = await _open(tester);
      expect(
        tester.widget<SkeletonOverlay>(find.byType(SkeletonOverlay)).frame,
        isNull,
      );

      camera.emit(_wellFramed());
      await tester.pumpAndSettle();

      final overlay =
          tester.widget<SkeletonOverlay>(find.byType(SkeletonOverlay));
      expect(overlay.frame, isNotNull);
      expect(overlay.severity, FramingSeverity.good);
    });

    testWidgets('colours the figure by how usable the framing is',
        (tester) async {
      // Both directions, because "blocked" is also what the screen shows
      // before any frame has arrived — a test that only checked the
      // blocked case would pass without the camera being wired up at all.
      final camera = await _open(tester);

      camera.emit(_wellFramed());
      await tester.pumpAndSettle();
      expect(
        tester.widget<SkeletonOverlay>(find.byType(SkeletonOverlay)).severity,
        FramingSeverity.good,
      );

      camera.emit(_nobody(id: 2));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SkeletonOverlay>(find.byType(SkeletonOverlay)).severity,
        FramingSeverity.blocked,
      );
    });
  });

  group('CameraCheckScreen failures', () {
    testWidgets('says when the frame stream fails part way through',
        (tester) async {
      // Without this, a pose model that fails to load looks exactly like
      // an empty room: a preview that works and a bar that says it cannot
      // see anybody, for ever.
      final camera = await _open(tester);

      camera.emitError(
        const PoseCameraException(PoseCameraError.modelFailed),
      );
      await tester.pumpAndSettle();

      expect(find.text(_l10n.coachErrorModel), findsOneWidget);
      expect(find.text(_l10n.coachFramingNoPerson), findsNothing);
    });

    testWidgets('goes back to normal once frames resume', (tester) async {
      final camera = await _open(tester);

      camera.emitError(
        const PoseCameraException(PoseCameraError.modelFailed),
      );
      await tester.pumpAndSettle();
      camera.emit(_wellFramed(id: 2));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.coachFramingGood), findsOneWidget);
    });

    testWidgets('explains a camera that will not open', (tester) async {
      await _open(
        tester,
        failStartWith: const PoseCameraException(PoseCameraError.cameraInUse),
      );

      expect(find.byKey(UiKeys.coachError), findsOneWidget);
      expect(find.text(_l10n.coachErrorInUse), findsOneWidget);
    });

    testWidgets('offers a way out of the error', (tester) async {
      final camera = FakePoseCamera(
        failStartWith: const PoseCameraException(PoseCameraError.cameraInUse),
      );
      await pumpScreen(
        tester,
        const CameraCheckScreen(exerciseId: _coached),
        camera: camera,
      );

      expect(camera.startedWith, hasLength(1));
      await tester.tap(find.widgetWithText(FilledButton, _l10n.coachErrorRetry));
      await tester.pumpAndSettle();

      expect(camera.startedWith, hasLength(2));
    });
  });

  group('CameraCheckScreen lifecycle', () {
    testWidgets('closes the camera when the screen goes away', (tester) async {
      final camera = await _open(tester);
      expect(camera.isRunning, isTrue);

      await pumpScreen(tester, const SizedBox(), camera: camera);

      expect(camera.isRunning, isFalse);
      expect(camera.stopCount, greaterThan(0));
    });

    testWidgets('closes the camera when the app is backgrounded',
        (tester) async {
      // A camera left running behind another app is somebody's battery and
      // somebody's privacy, in that order of how fast they notice.
      final camera = await _open(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(camera.isRunning, isFalse);
    });

    testWidgets('opens it again on the way back', (tester) async {
      final camera = await _open(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(camera.isRunning, isTrue);
      expect(camera.startedWith, hasLength(2));
    });

    testWidgets('leaves by the done button, and closes the camera',
        (tester) async {
      final camera = FakePoseCamera();
      await pumpScreen(tester, const _Host(), camera: camera);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(camera.isRunning, isTrue);

      await tester.tap(find.byKey(UiKeys.coachDone));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.coachScreen), findsNothing);
      expect(camera.isRunning, isFalse);
    });
  });
  group('CameraCheckScreen counting', () {
    /// A set of [count] reps, generated by the accuracy harness so the
    /// screen is driven by the same bodies the accuracy suite replays.
    List<PoseFrame> squatSet(int count, {double depth = 1}) => syntheticReps(
          name: 'widget_set',
          exerciseId: _coached,
          top: squatTop,
          bottom: squatBottom,
          reps: List.filled(count, SyntheticRep(depth: depth)),
          expectedReps: count,
        ).frames;

    Future<FakePoseCamera> perform(
      WidgetTester tester,
      List<PoseFrame> frames, {
      String exerciseId = _coached,
    }) async {
      final camera = await _open(tester, exerciseId: exerciseId);
      for (final frame in frames) {
        camera.emit(frame);
      }
      await tester.pumpAndSettle();
      return camera;
    }

    testWidgets('counts the reps it was shown', (tester) async {
      await perform(tester, squatSet(3));

      expect(find.byKey(UiKeys.coachCount), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachCount)).data,
        '3',
      );
    });

    testWidgets('counts nothing before the set starts', (tester) async {
      await _open(tester);

      expect(find.byKey(UiKeys.coachCount), findsNothing);
    });

    testWidgets('says what became of the last rep, after it is over',
        (tester) async {
      // The counter reports a finished attempt on exactly one frame. A
      // verdict that vanished with it would be unreadable, so the screen
      // holds the last one — and the set ends with the user standing still.
      await perform(tester, squatSet(2));

      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachVerdict)).data,
        _l10n.coachRepGood,
      );
    });

    testWidgets('says a shallow rep counted and was shallow', (tester) async {
      await perform(tester, squatSet(2, depth: 0.65));

      expect(tester.widget<Text>(find.byKey(UiKeys.coachCount)).data, '2');
      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachVerdict)).data,
        _l10n.coachRepShallow,
      );
    });

    testWidgets('shows a rep it refused, and the reason', (tester) async {
      // The requirement this screen exists to meet: a rejected rep is
      // surfaced, never swallowed.
      await perform(
        tester,
        syntheticReps(
          name: 'widget_mixed',
          exerciseId: _coached,
          top: squatTop,
          bottom: squatBottom,
          reps: const [SyntheticRep(), SyntheticRep(depth: 0.45)],
          expectedReps: 1,
        ).frames,
      );

      expect(tester.widget<Text>(find.byKey(UiKeys.coachCount)).data, '1');
      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachVerdict)).data,
        _l10n.coachRepPartial,
      );
      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachLedger)).data,
        _l10n.coachRepsNotCounted(1),
      );
    });

    testWidgets('keeps no ledger line while every rep has counted',
        (tester) async {
      await perform(tester, squatSet(2));

      expect(find.byKey(UiKeys.coachLedger), findsNothing);
    });

    testWidgets('times a plank instead of counting it', (tester) async {
      await perform(
        tester,
        syntheticHold(
          name: 'widget_plank',
          exerciseId: 'plank',
          posture: plankHeld,
          duration: const Duration(seconds: 10),
          expectedHold: const Duration(seconds: 10),
        ).frames,
        exerciseId: 'plank',
      );

      expect(tester.widget<Text>(find.byKey(UiKeys.coachCount)).data, '0:09');
      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachVerdict)).data,
        _l10n.coachHoldRunning,
      );
    });

    testWidgets('stops the clock when the hold breaks, and says so',
        (tester) async {
      await perform(
        tester,
        syntheticHold(
          name: 'widget_plank_broken',
          exerciseId: 'plank',
          posture: plankHeld,
          broken: plankSagging,
          duration: const Duration(seconds: 10),
          breakFrom: const Duration(seconds: 8),
          breakFor: const Duration(seconds: 2),
          expectedHold: const Duration(seconds: 8),
        ).frames,
        exerciseId: 'plank',
      );

      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachVerdict)).data,
        _l10n.coachHoldOutOfPosition,
      );
      // Eight seconds of hold, not seven: the hips drop at the eight second
      // mark and the smoothing filter takes a couple of frames to follow
      // them down, so the clock runs a fraction past the break. That is the
      // filter doing its job, not the hold misreading one.
      expect(tester.widget<Text>(find.byKey(UiKeys.coachCount)).data, '0:08');
    });

    testWidgets('admits its form checks have never been measured', (tester) async {
      await _open(tester);

      expect(find.text(_l10n.coachFormUntested), findsOneWidget);
      expect(find.text(_l10n.coachClaim), findsOneWidget);
    });

    testWidgets('keeps counting while the framing is poor', (tester) async {
      // Framing advice and counting are separate judgements. Somebody a
      // little too far away is still training, and a counter that stopped
      // would look broken rather than careful.
      final frames = squatSet(2)
          .map(
            (frame) => PoseFrame(
              frameId: frame.frameId,
              t: frame.t,
              landmarks: {
                for (final entry in frame.landmarks.entries)
                  entry.key: Landmark(
                    x: 0.5 + (entry.value.x - 0.5) * 0.4,
                    y: 0.5 + (entry.value.y - 0.5) * 0.4,
                    z: entry.value.z,
                    visibility: entry.value.visibility,
                  ),
              },
              confidence: frame.confidence,
            ),
          )
          .toList();
      await perform(tester, frames);

      expect(tester.widget<Text>(find.byKey(UiKeys.coachCount)).data, '2');
    });
  });

  group('CameraCheckScreen form', () {
    Future<void> perform(
      WidgetTester tester,
      List<PoseFrame> frames, {
      String exerciseId = _coached,
    }) async {
      final camera = await _open(tester, exerciseId: exerciseId);
      for (final frame in frames) {
        camera.emit(frame);
      }
      await tester.pumpAndSettle();
    }

    List<PoseFrame> squats({
      required int count,
      SideOnPose bottom = squatBottom,
      double depth = 1,
    }) =>
        syntheticReps(
          name: 'widget_form_set',
          exerciseId: _coached,
          top: squatTop,
          bottom: bottom,
          reps: List.filled(count, SyntheticRep(depth: depth)),
          expectedReps: count,
        ).frames;

    String formText(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(UiKeys.coachForm)).data!;

    testWidgets('says nothing is wrong when nothing is wrong', (tester) async {
      await perform(tester, squats(count: 3));

      expect(formText(tester), _l10n.coachFormGood);
    });

    testWidgets('gives the advice for the rule that fired', (tester) async {
      await perform(tester, squats(count: 3, depth: 0.65));

      expect(formText(tester), _l10n.coachAdviceSquatDepth);
    });

    testWidgets('says to stop the set when the movement looked unsafe',
        (tester) async {
      // The only rule serious enough to interrupt a set, and the only one
      // whose advice is an instruction to stop rather than an adjustment.
      await perform(tester, squats(count: 3, bottom: squatRoundedBottom));

      expect(formText(tester), _l10n.coachAdviceBackRounding);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('shows the score the progression table would read',
        (tester) async {
      await perform(tester, squats(count: 3));

      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachFormScore)).data,
        _l10n.coachFormScore(100),
      );
    });

    testWidgets('a flagged set scores below a clean one', (tester) async {
      await perform(tester, squats(count: 3, depth: 0.65));

      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachFormScore)).data,
        isNot(_l10n.coachFormScore(100)),
      );
    });

    testWidgets('names what it is not watching', (tester) async {
      // The requirement that is easiest to leave out: a coach that says
      // nothing about the user's knees is making a claim, and from the side
      // it cannot see them fall inwards at all.
      await perform(tester, squats(count: 1));

      expect(
        tester.widget<Text>(find.byKey(UiKeys.coachFormUnchecked)).data,
        contains(_l10n.coachRuleKneeValgus),
      );
    });

    testWidgets('has no form panel at all before the first frame',
        (tester) async {
      // There is nothing to be silent about yet. The panel appears with the
      // first frame, and a score only once a rule has answered.
      await _open(tester);

      expect(find.byKey(UiKeys.coachForm), findsNothing);
      expect(find.byKey(UiKeys.coachFormScore), findsNothing);
    });

    testWidgets('does not judge an attempt the counter refused',
        (tester) async {
      // Two dips too shallow to be reps. The counter says why, and the form
      // panel has nothing to add about a movement that did not happen.
      await perform(tester, squats(count: 2, depth: 0.45));

      expect(tester.widget<Text>(find.byKey(UiKeys.coachCount)).data, '0');
      expect(formText(tester), _l10n.coachFormWatching);
      expect(find.byKey(UiKeys.coachFormScore), findsNothing);
    });

    testWidgets('a plank says the hips are dropping while they are',
        (tester) async {
      // A hold has no reps, so the panel reads the live window: it has to
      // say something during the hold rather than after it.
      await perform(
        tester,
        syntheticHold(
          name: 'widget_plank_sagging',
          exerciseId: 'plank',
          posture: plankHeld,
          broken: plankSagging,
          duration: const Duration(seconds: 10),
          breakFrom: const Duration(seconds: 5),
          breakFor: const Duration(seconds: 5),
          expectedHold: const Duration(seconds: 5),
        ).frames,
        exerciseId: 'plank',
      );

      expect(formText(tester), _l10n.coachAdviceHipSag);
    });
  });
}

/// Somewhere to come back to, so a pop is a real pop.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    const CameraCheckScreen(exerciseId: _coached),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
}
