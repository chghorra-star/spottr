import 'package:flutter/widgets.dart';

/// Widget keys the tests depend on.
///
/// Collected in one place because the alternative — tests looking for
/// user-facing text — makes every copy change break a test for no reason,
/// and makes a test that asserts "an error is shown" indistinguishable from
/// one that asserts a particular sentence.
abstract final class UiKeys {
  static const Key loading = Key('spottr.loading');
  static const Key errorPanel = Key('spottr.error');
  static const Key retry = Key('spottr.retry');

  static const Key onboarding = Key('spottr.onboarding');
  static const Key onboardingNext = Key('spottr.onboarding.next');
  static const Key onboardingBack = Key('spottr.onboarding.back');
  static const Key disclaimerAccept = Key('spottr.onboarding.disclaimer');

  static const Key questionGoal = Key('spottr.question.goal');
  static const Key questionSchedule = Key('spottr.question.schedule');
  static const Key questionLevel = Key('spottr.question.level');
  static const Key questionBody = Key('spottr.question.body');
  static const Key questionInjuries = Key('spottr.question.injuries');
  static const Key questionLocation = Key('spottr.question.location');
  static const Key questionRunDays = Key('spottr.question.runDays');
  static const Key questionCoach = Key('spottr.question.coach');

  static const Key daysSlider = Key('spottr.question.schedule.days');
  static const Key minutesSlider = Key('spottr.question.schedule.minutes');
  static const Key ageField = Key('spottr.question.body.age');
  static const Key heightField = Key('spottr.question.body.height');
  static const Key weightField = Key('spottr.question.body.weight');
  static const Key injuryNotesField = Key('spottr.question.injuries.notes');

  static const Key planScreen = Key('spottr.plan');
  static const Key planEmpty = Key('spottr.plan.empty');
  static const Key planNotes = Key('spottr.plan.notes');
  static const Key planRunSuggestions = Key('spottr.plan.runSuggestions');
  static const Key planRebuild = Key('spottr.plan.rebuild');
  static const Key planRebuildConfirm = Key('spottr.plan.rebuild.confirm');
  static const Key planOpenProfile = Key('spottr.plan.profile');
  static const Key planReorderDone = Key('spottr.plan.reorder.done');

  static const Key swapSheet = Key('spottr.swap');
  static const Key swapEmpty = Key('spottr.swap.empty');
  static const Key moveDaySheet = Key('spottr.moveDay');

  static const Key profileScreen = Key('spottr.profile');
  static const Key profileSave = Key('spottr.profile.save');

  static const Key sessionScreen = Key('spottr.session');
  static const Key sessionEmpty = Key('spottr.session.empty');
  static const Key sessionOver = Key('spottr.session.over');
  static const Key sessionPain = Key('spottr.session.pain');
  static const Key sessionPainConfirm = Key('spottr.session.pain.confirm');
  static const Key sessionPainBadge = Key('spottr.session.painBadge');
  static const Key sessionFinish = Key('spottr.session.finish');
  static const Key sessionDiscard = Key('spottr.session.discard');
  static const Key sessionDiscardConfirm =
      Key('spottr.session.discard.confirm');
  static const Key sessionRatingSheet = Key('spottr.session.rating');
  static const Key sessionRatingSkip = Key('spottr.session.rating.skip');
  static const Key sessionSummary = Key('spottr.session.summary');
  static const Key sessionSummaryDone = Key('spottr.session.summary.done');

  static const Key coachScreen = Key('spottr.coach');
  static const Key coachNotSupported = Key('spottr.coach.notSupported');
  static const Key coachPermission = Key('spottr.coach.permission');
  static const Key coachPermissionAllow = Key('spottr.coach.permission.allow');
  static const Key coachBlocked = Key('spottr.coach.permission.blocked');
  static const Key coachError = Key('spottr.coach.error');
  static const Key coachFraming = Key('spottr.coach.framing');
  static const Key coachDone = Key('spottr.coach.done');
  static const Key coachCount = Key('spottr.coach.count');
  static const Key coachVerdict = Key('spottr.coach.verdict');
  static const Key coachLedger = Key('spottr.coach.ledger');

  /// A choice within a question, e.g. one goal or one injury site.

  static Key choice(String question, String value) =>
      Key('spottr.choice.$question.$value');

  /// Starting or resuming the session on one weekday.
  static Key planDayStart(int weekday) =>
      Key('spottr.plan.day.$weekday.start');

  /// One exercise being logged, and the fields and button inside it.
  static Key sessionExercise(String exerciseId) =>
      Key('spottr.session.exercise.$exerciseId');
  static Key sessionReps(String exerciseId) =>
      Key('spottr.session.reps.$exerciseId');
  static Key sessionWeight(String exerciseId) =>
      Key('spottr.session.weight.$exerciseId');
  static Key sessionSaveSet(String exerciseId) =>
      Key('spottr.session.save.$exerciseId');
  static Key sessionCoach(String exerciseId) =>
      Key('spottr.session.coach.$exerciseId');

  /// One answer to "how did that feel", by [SessionRating] name.
  static Key sessionRating(String rating) =>
      Key('spottr.session.rating.$rating');

  /// A day card on the plan screen, by ISO weekday.
  static Key planDay(int weekday) => Key('spottr.plan.day.$weekday');

  /// The menu button on one prescribed exercise.
  static Key planExerciseMenu(int weekday, String exerciseId) =>
      Key('spottr.plan.exercise.$weekday.$exerciseId');

  /// One alternative offered in the swap sheet.
  static Key swapOption(String exerciseId) => Key('spottr.swap.$exerciseId');

  /// One target weekday offered in the move-day sheet.
  static Key moveDayOption(int weekday) => Key('spottr.moveDay.$weekday');
}
