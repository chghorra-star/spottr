/// Rep counting, form analysis, scoring, and coach cue arbitration.
///
/// Consumes a stream of `PoseFrame`s and emits rep events, form verdicts and
/// coach cues. Deliberately free of Flutter and of any camera dependency, so
/// the whole pipeline runs from recorded fixtures with no device attached.
///
/// Rep counting lands in M5, form rules in M6, cue arbitration in M7.
library;
