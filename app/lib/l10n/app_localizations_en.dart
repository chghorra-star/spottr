// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Spottr';

  @override
  String get disclaimerTitle => 'Before we start';

  @override
  String get disclaimerBody =>
      'Spottr gives you form feedback and flags movement that looks risky. It is not medical advice, and it cannot guarantee you will avoid injury. If you are injured or in pain, talk to a doctor or physiotherapist before training.';

  @override
  String get disclaimerAccept => 'I understand';

  @override
  String get painButton => 'I feel pain';

  @override
  String get setSummaryTitle => 'Set done';

  @override
  String repsCounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
      zero: 'No reps counted',
    );
    return '$_temp0';
  }

  @override
  String repsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to go',
      one: 'Last one',
    );
    return '$_temp0';
  }

  @override
  String formScoreLabel(int score) {
    return 'Form $score%';
  }

  @override
  String get cueTurnPhoneSideways =>
      'Turn the phone to the side so I can see your depth';

  @override
  String get cueTrackingLost => 'I lost you — step back into frame';

  @override
  String get coachStyleHype => 'Hype';

  @override
  String get coachStyleCalm => 'Calm';

  @override
  String get coachStyleTough => 'Tough';
}
