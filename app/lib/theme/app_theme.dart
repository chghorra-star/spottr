import 'package:flutter/material.dart';

/// Colors that encode how a rep or a cue should be read.
///
/// These live in the theme rather than in the camera widgets because the same
/// severity scale appears in the live HUD, the per-rep ledger, the set
/// summary, and the history screens. Keeping them in one place is what stops
/// "major" from being amber in one screen and red in another.
@immutable
class FormSeverityColors extends ThemeExtension<FormSeverityColors> {
  const FormSeverityColors({
    required this.good,
    required this.minor,
    required this.major,
    required this.unsafe,
  });

  /// Clean rep, no rule fired.
  final Color good;

  /// Worth mentioning once; never blocks a rep.
  final Color minor;

  /// Cue fires every time, but the rep still counts.
  final Color major;

  /// Rep is not counted and the coach says to drop the weight.
  final Color unsafe;

  @override
  FormSeverityColors copyWith({
    Color? good,
    Color? minor,
    Color? major,
    Color? unsafe,
  }) =>
      FormSeverityColors(
        good: good ?? this.good,
        minor: minor ?? this.minor,
        major: major ?? this.major,
        unsafe: unsafe ?? this.unsafe,
      );

  @override
  FormSeverityColors lerp(FormSeverityColors? other, double t) {
    if (other == null) return this;
    return FormSeverityColors(
      good: Color.lerp(good, other.good, t)!,
      minor: Color.lerp(minor, other.minor, t)!,
      major: Color.lerp(major, other.major, t)!,
      unsafe: Color.lerp(unsafe, other.unsafe, t)!,
    );
  }
}

/// Spottr's visual language: dark-first, high contrast, built to stay legible
/// at arm's length on a phone propped against a water bottle.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF00C2A8);

  static const FormSeverityColors _severityDark = FormSeverityColors(
    good: Color(0xFF35D07F),
    minor: Color(0xFFFFD166),
    major: Color(0xFFFFB020),
    unsafe: Color(0xFFFF4D4F),
  );

  static const FormSeverityColors _severityLight = FormSeverityColors(
    good: Color(0xFF128A4E),
    minor: Color(0xFFB07A00),
    major: Color(0xFFCC7A00),
    unsafe: Color(0xFFC62828),
  );

  static final ThemeData dark = _build(Brightness.dark, _severityDark);
  static final ThemeData light = _build(Brightness.light, _severityLight);

  static ThemeData _build(Brightness brightness, FormSeverityColors severity) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [severity],
    );
  }
}
