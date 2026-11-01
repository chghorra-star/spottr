import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';
import 'package:spottr/l10n/app_localizations_en.dart';
import 'package:spottr/l10n/plan_strings.dart';

final PlanStrings _strings = PlanStrings(AppLocalizationsEn(), standardCatalog);

FramingVerdict _verdict({
  Set<FramingIssue> issues = const {},
  Set<Joint> missing = const {},
}) =>
    FramingVerdict(
      issues: issues,
      missing: missing,
      bodyBox: const BodyBox(left: 0.4, top: 0.1, right: 0.6, bottom: 0.9),
    );

void main() {
  group('PlanStrings.cameraAngle', () {
    test('tells the user where to put the phone for every angle', () {
      for (final angle in CameraAngle.values) {
        expect(_strings.cameraAngle(angle), isNotEmpty, reason: angle.name);
      }
    });

    test('asks for a side view and a front view by name', () {
      expect(_strings.cameraAngle(CameraAngle.side).toLowerCase(),
          contains('side'));
      expect(_strings.cameraAngle(CameraAngle.front).toLowerCase(),
          contains('front'));
    });
  });

  group('PlanStrings.framingAdvice', () {
    test('says something for every issue', () {
      for (final issue in FramingIssue.values) {
        expect(
          _strings.framingAdvice(_verdict(issues: {issue})),
          isNotEmpty,
          reason: issue.name,
        );
      }
    });

    test('confirms when nothing is wrong', () {
      expect(_strings.framingAdvice(_verdict()), isNotEmpty);
    });

    test('names the one body part it cannot see', () {
      expect(
        _strings
            .framingAdvice(
              _verdict(
                issues: {FramingIssue.jointsOutOfView},
                missing: {Joint.leftAnkle, Joint.rightAnkle},
              ),
            )
            .toLowerCase(),
        contains('ankles'),
      );
      expect(
        _strings
            .framingAdvice(
              _verdict(
                issues: {FramingIssue.jointsOutOfView},
                missing: {Joint.leftKnee},
              ),
            )
            .toLowerCase(),
        contains('knees'),
      );
    });

    test('stops naming parts once several are missing', () {
      // Listing four body parts is a list nobody reads. One instruction
      // fixes all of them.
      final advice = _strings.framingAdvice(
        _verdict(
          issues: {FramingIssue.jointsOutOfView},
          missing: {Joint.leftAnkle, Joint.leftShoulder, Joint.leftHip},
        ),
      );

      expect(advice.toLowerCase(), isNot(contains('ankles')));
      expect(advice, isNotEmpty);
    });

    test('says the primary thing, not all of them', () {
      // Too close and joints out of view are both true when somebody
      // stands near the phone, and only one of them is an instruction.
      final advice = _strings.framingAdvice(
        _verdict(
          issues: {FramingIssue.tooClose, FramingIssue.jointsOutOfView},
          missing: {Joint.leftAnkle},
        ),
      );

      expect(advice, _strings.framingAdvice(
        _verdict(issues: {FramingIssue.tooClose}),
      ));
    });
  });

  group('PlanStrings.cameraError', () {
    test('explains every failure the bridge can report', () {
      for (final error in PoseCameraError.values) {
        final message = _strings.cameraError(error);
        expect(message, isNotEmpty, reason: error.name);
        // A raw enum name on screen is the failure this seam prevents.
        expect(message, isNot(contains(error.name)), reason: error.name);
      }
    });
  });

  group('the camera claim', () {
    test('states its limits rather than promising prevention', () {
      // The brief is explicit: form feedback that flags risky movement,
      // never a guarantee of safety. Pinned as the words that have to be
      // there rather than words that must not be, because "cannot
      // guarantee" and "guarantees" differ by one token and a forbidden
      // substring cannot tell them apart.
      final claim = AppLocalizationsEn().coachClaim.toLowerCase();

      expect(claim, contains('risky'));
      expect(claim, contains('cannot guarantee'));
      expect(claim, contains('cannot see everything'));
    });
  });

  group('PlanStrings.repVerdict', () {
    RepEvent event(RepOutcome outcome, RepFault? fault) => RepEvent(
          index: 1,
          outcome: outcome,
          fault: fault,
          duration: const Duration(milliseconds: 1500),
          descent: const Duration(milliseconds: 800),
          ascent: const Duration(milliseconds: 700),
          peakAngle: 95,
          rangeOfMotion: 80,
        );

    test('says something about every outcome a rep can have', () {
      final faults = <RepFault?>[null, ...RepFault.values];

      for (final fault in faults) {
        final message = _strings.repVerdict(
          event(
            fault == null ? RepOutcome.counted : RepOutcome.notCounted,
            fault,
          ),
        );
        expect(message, isNotEmpty, reason: '${fault?.name}');
        expect(message, isNot(contains(fault?.name ?? 'counted')));
      }
    });

    test('says a rejected rep was not counted, in those words', () {
      // The user felt themselves do a rep. If the screen does not say it was
      // not counted and why, the only conclusion available to them is that
      // the app is broken.
      for (final fault in [
        RepFault.partialRange,
        RepFault.tooFast,
        RepFault.timedOut,
        RepFault.lostTracking,
      ]) {
        expect(
          _strings.repVerdict(event(RepOutcome.notCounted, fault)),
          contains('Not counted'),
          reason: fault.name,
        );
      }
    });

    test('says a shallow rep did count', () {
      final message = _strings.repVerdict(
        event(RepOutcome.countedWithWarning, RepFault.shallow),
      );

      expect(message, contains('Counted'));
      expect(message, isNot(contains('Not counted')));
    });
  });

  group('PlanStrings.holdState', () {
    HoldTick tick(HoldPause? pause) =>
        HoldTick(held: const Duration(seconds: 12), pause: pause, tracking: true);

    test('says why the clock is not running, for every reason', () {
      for (final pause in <HoldPause?>[null, ...HoldPause.values]) {
        final message = _strings.holdState(tick(pause));
        expect(message, isNotEmpty, reason: '${pause?.name}');
        expect(message, isNot(contains(pause?.name ?? 'running')));
      }
    });

    test('distinguishes losing the position from losing sight of them', () {
      expect(
        _strings.holdState(tick(HoldPause.outOfPosition)),
        isNot(_strings.holdState(tick(HoldPause.untracked))),
      );
    });
  });

  group('what the coach admits it is not doing yet', () {
    test('says the form checks have never been measured', () {
      // M6 judges technique, so the M5 line about not judging it had to
      // go. What replaces it is the thing that is still true: every
      // threshold behind every rule is a plausible guess, and none of them
      // has been compared against video of anybody training.
      final line = AppLocalizationsEn().coachFormUntested.toLowerCase();

      expect(line, contains('form'));
      expect(line, contains('not been measured'));
      expect(line, contains('footage'));
    });

    test('names every rule the catalog has, including the unbuilt ones', () {
      // The screen lists what it is not watching by name. A rule with no
      // name would have to be left out of that list, which would make the
      // list wrong in the one direction that matters.
      final strings = PlanStrings(
        AppLocalizationsEn(),
        ExerciseCatalog(standardExercises),
      );

      for (final entry in formCatalog.entries) {
        expect(
          strings.ruleName(entry.key),
          isNotEmpty,
          reason: 'no name for ',
        );
        if (entry.value is PendingRule) continue;
        expect(
          strings.ruleAdvice(entry.key),
          isNotEmpty,
          reason: 'no advice for ',
        );
      }
    });
  });
}
