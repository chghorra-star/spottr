/// How the coach talks.
///
/// Chosen at onboarding and changeable at any time, so nothing about a plan
/// or a session may depend on it: the style selects wording and intensity of
/// cues, never what is prescribed or what counts as a rep.
enum CoachStyle {
  /// Energetic and loud.
  hype,

  /// Technical and encouraging, lower volume, more about position.
  calm,

  /// Direct and blunt. Still never tells anyone to push through pain.
  tough;

  /// The default for a new profile.
  ///
  /// Calm is the honest default for a product whose first job is form: it is
  /// the style that says what to fix rather than how hard to go.
  static const CoachStyle fallback = CoachStyle.calm;
}
