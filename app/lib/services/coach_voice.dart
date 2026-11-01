import 'dart:async';

import 'package:coach_engine/coach_engine.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/plan_strings.dart';

/// How long a cue may wait to be spoken before it is dropped.
///
/// A correction delivered four seconds after the rep it was about is worse
/// than silence, because the user applies it to the rep they are in the
/// middle of.
const Duration defaultCueMaxAge = Duration(seconds: 3);

/// Something that can say a short phrase out loud.
///
/// An interface because the real one is a platform channel: widget tests
/// get [SilentCoachSpeaker] and the set runner gets text-to-speech, and
/// neither of them is the thing being tested when the other is in use.
abstract interface class CoachSpeaker {
  /// Says [text], completing when it has finished speaking.
  Future<void> say(String text);

  /// Stops mid-sentence.
  Future<void> stop();

  Future<void> dispose();
}

/// Says nothing, immediately.
///
/// The default. A coach that has not been asked to speak should not, and a
/// test that has not asked for a voice should not open an audio channel.
class SilentCoachSpeaker implements CoachSpeaker {
  const SilentCoachSpeaker();

  @override
  Future<void> say(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// The device's text-to-speech engine.
class TtsCoachSpeaker implements CoachSpeaker {
  TtsCoachSpeaker({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> _prepare() async {
    if (_ready) return;
    _ready = true;
    // A gym is loud and a phone is two metres away, so the defaults are
    // wrong in both directions: a little slower than conversational, so a
    // short cue survives the room, and full volume.
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1);
    await _tts.setPitch(1);
    // Without this the future returns the moment speech is queued, and the
    // voice would talk over itself.
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> say(String text) async {
    await _prepare();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
  }
}

/// Turns cues into speech, and refuses to let them pile up.
///
/// Cues are raised at up to thirty a second and speech runs at roughly one
/// short phrase every second and a half. The engine's budget keeps the
/// *rate* sane; this keeps the *queue* sane, which is a different problem:
/// anything still waiting when the voice frees up is spoken only if it is
/// still about something recent.
///
/// It holds at most one pending cue, because a queue of two is already a
/// coach talking about the rep before last.
class CoachVoice {
  CoachVoice({
    required this.speaker,
    required this.strings,
    required this.style,
    this.maxAge = defaultCueMaxAge,
  });

  final CoachSpeaker speaker;
  final PlanStrings strings;
  final CoachStyle style;
  final Duration maxAge;

  bool _enabled = true;
  bool _speaking = false;
  Duration _now = Duration.zero;
  Cue? _pending;

  /// Whether the coach is allowed to speak.
  bool get enabled => _enabled;

  /// Whether it is speaking right now.
  bool get speaking => _speaking;

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) {
      _pending = null;
      unawaited(speaker.stop());
    }
  }

  /// Offers one frame to the voice.
  ///
  /// Takes the whole tick rather than the cue alone because the clock comes
  /// from the frames: the voice has to know what time it is when it frees
  /// up, and it must not read a real one — a set replayed from a fixture
  /// and a set performed in a gym have to behave the same.
  void onTick(CoachTick tick) {
    _now = tick.t;
    final cue = tick.cue;
    if (cue == null || !_enabled) return;

    if (_speaking) {
      // The newer of the two, unless the one already waiting is more
      // urgent. Two cues waiting is a coach discussing the rep before last.
      final waiting = _pending;
      if (waiting == null || cue.priority.index >= waiting.priority.index) {
        _pending = cue;
      }
      return;
    }
    unawaited(_say(cue));
  }

  /// Stops talking and forgets anything waiting.
  Future<void> stop() async {
    _pending = null;
    await speaker.stop();
  }

  Future<void> dispose() async {
    _pending = null;
    await speaker.dispose();
  }

  Future<void> _say(Cue cue) async {
    _speaking = true;
    try {
      await speaker.say(strings.cue(cue, style));
    } finally {
      _speaking = false;
    }

    final next = _pending;
    _pending = null;
    if (next == null || !_enabled) return;
    // Stale at dequeue time is dropped rather than spoken late.
    if (_now - next.at > maxAge) return;
    unawaited(_say(next));
  }
}
