/// Rep counting, form analysis, scoring, and coach cue arbitration.
///
/// Consumes a stream of `PoseFrame`s and emits rep events, form verdicts and
/// coach cues. Deliberately free of Flutter and of any camera dependency, so
/// the whole pipeline runs from recorded fixtures with no device attached.
///
/// Rep counting lands in M5, form rules in M6, cue arbitration in M7. The
/// coach style is here from M2 because onboarding has to collect it.
library;

export 'src/coach_style.dart';
export 'src/pose_signal.dart';
export 'src/counter_config.dart';
export 'src/rep_event.dart';
export 'src/set_counter.dart';
export 'src/counter_catalog.dart';
export 'src/form_rule.dart';
export 'src/form_catalog.dart';
export 'src/form_verdict.dart';
export 'src/form_analyzer.dart';
export 'src/cue_engine.dart';
