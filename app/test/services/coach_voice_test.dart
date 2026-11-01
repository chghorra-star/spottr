import 'dart:async';

import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/l10n/app_localizations_en.dart';
import 'package:spottr/l10n/plan_strings.dart';
import 'package:spottr/services/coach_voice.dart';

final _strings = PlanStrings(AppLocalizationsEn(), standardCatalog);
final _l10n = AppLocalizationsEn();

/// A speaker that finishes when the test says so.
///
/// The whole point of the voice is what it does while the previous phrase
/// is still coming out, so the tests have to be able to hold one open.
class FakeSpeaker implements CoachSpeaker {
  final List<String> said = [];
  int stops = 0;
  Completer<void>? _current;

  bool get busy => _current != null;

  void finish() {
    final current = _current;
    _current = null;
    current?.complete();
  }

  @override
  Future<void> say(String text) {
    said.add(text);
    return (_current = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    finish();
  }

  @override
  Future<void> dispose() async {}
}

CoachTick tick({required Duration at, Cue? cue}) => CoachTick(
      t: at,
      counter: const RepTick(
        phase: RepPhase.top,
        counted: 0,
        attempts: 0,
        depth: 0,
        tracking: true,
      ),
      live: FormVerdict.nothing,
      review: const SetReview(exerciseId: 'bodyweight_squat', reps: []),
      cue: cue,
    );

RuleCue rule(String id, RuleSeverity severity, Duration at) =>
    RuleCue(ruleId: id, severity: severity, at: at);

void main() {
  late FakeSpeaker speaker;
  late CoachVoice voice;

  setUp(() {
    speaker = FakeSpeaker();
    voice = CoachVoice(
      speaker: speaker,
      strings: _strings,
      style: CoachStyle.calm,
    );
  });

  group('CoachVoice', () {
    test('says a cue when the voice is free', () async {
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule('hip_sag', RuleSeverity.major, const Duration(seconds: 2)),
        ),
      );
      await pumpEventQueue();

      expect(speaker.said, [_l10n.coachAdviceHipSag]);
    });

    test('says nothing on a frame with nothing to say', () async {
      voice.onTick(tick(at: const Duration(seconds: 2)));
      await pumpEventQueue();

      expect(speaker.said, isEmpty);
    });

    test('holds a cue while it is still talking, and says it after',
        () async {
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule('hip_sag', RuleSeverity.major, const Duration(seconds: 2)),
        ),
      );
      await pumpEventQueue();

      voice.onTick(
        tick(
          at: const Duration(seconds: 3),
          cue: rule(
            'squat_depth',
            RuleSeverity.minor,
            const Duration(seconds: 3),
          ),
        ),
      );
      await pumpEventQueue();
      expect(speaker.said, hasLength(1), reason: 'still on the first one');

      speaker.finish();
      await pumpEventQueue();

      expect(speaker.said, [
        _l10n.coachAdviceHipSag,
        _l10n.coachAdviceSquatDepth,
      ]);
    });

    test('drops a held cue that went stale waiting', () async {
      // Said four seconds late, a correction is about the wrong rep.
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule('hip_sag', RuleSeverity.major, const Duration(seconds: 2)),
        ),
      );
      await pumpEventQueue();

      voice.onTick(
        tick(
          at: const Duration(seconds: 3),
          cue: rule(
            'squat_depth',
            RuleSeverity.minor,
            const Duration(seconds: 3),
          ),
        ),
      );
      // Time passes with the voice still busy.
      voice.onTick(tick(at: const Duration(seconds: 9)));
      speaker.finish();
      await pumpEventQueue();

      expect(speaker.said, [_l10n.coachAdviceHipSag]);
    });

    test('keeps only one cue waiting, and prefers the urgent one', () async {
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule(
            'squat_depth',
            RuleSeverity.minor,
            const Duration(seconds: 2),
          ),
        ),
      );
      await pumpEventQueue();

      voice.onTick(
        tick(
          at: const Duration(seconds: 3),
          cue: rule('hip_sag', RuleSeverity.major, const Duration(seconds: 3)),
        ),
      );
      voice.onTick(
        tick(
          at: const Duration(milliseconds: 3200),
          cue: rule(
            'back_rounding',
            RuleSeverity.unsafe,
            const Duration(milliseconds: 3200),
          ),
        ),
      );
      speaker.finish();
      await pumpEventQueue();

      expect(speaker.said, [
        _l10n.coachAdviceSquatDepth,
        _l10n.coachAdviceBackRounding,
      ]);
    });

    test('a correction does not displace something risky', () async {
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule(
            'squat_depth',
            RuleSeverity.minor,
            const Duration(seconds: 2),
          ),
        ),
      );
      await pumpEventQueue();

      voice.onTick(
        tick(
          at: const Duration(seconds: 3),
          cue: rule(
            'back_rounding',
            RuleSeverity.unsafe,
            const Duration(seconds: 3),
          ),
        ),
      );
      voice.onTick(
        tick(
          at: const Duration(milliseconds: 3200),
          cue: rule(
            'hip_sag',
            RuleSeverity.major,
            const Duration(milliseconds: 3200),
          ),
        ),
      );
      speaker.finish();
      await pumpEventQueue();

      expect(speaker.said.last, _l10n.coachAdviceBackRounding);
    });

    test('says nothing while muted', () async {
      voice.enabled = false;
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule('hip_sag', RuleSeverity.major, const Duration(seconds: 2)),
        ),
      );
      await pumpEventQueue();

      expect(speaker.said, isEmpty);
    });

    test('shuts up mid-sentence when muted', () async {
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule('hip_sag', RuleSeverity.major, const Duration(seconds: 2)),
        ),
      );
      await pumpEventQueue();
      expect(speaker.busy, isTrue);

      voice.enabled = false;
      await pumpEventQueue();

      expect(speaker.stops, 1);
    });

    test('speaks the target in the style the user chose', () async {
      final tough = CoachVoice(
        speaker: speaker,
        strings: _strings,
        style: CoachStyle.tough,
      );
      tough.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: const TargetCue(at: Duration(seconds: 2)),
        ),
      );
      await pumpEventQueue();

      expect(speaker.said, [_l10n.coachTargetTough]);
    });

    test('stopping forgets what was waiting', () async {
      voice.onTick(
        tick(
          at: const Duration(seconds: 2),
          cue: rule('hip_sag', RuleSeverity.major, const Duration(seconds: 2)),
        ),
      );
      await pumpEventQueue();
      voice.onTick(
        tick(
          at: const Duration(seconds: 3),
          cue: rule(
            'squat_depth',
            RuleSeverity.minor,
            const Duration(seconds: 3),
          ),
        ),
      );

      await voice.stop();
      await pumpEventQueue();

      expect(speaker.said, [_l10n.coachAdviceHipSag]);
    });
  });
}
