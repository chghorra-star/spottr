import 'package:coach_engine/coach_engine.dart';
import 'package:collection/collection.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:pose_core/pose_core.dart';

import '../data/plan_repository.dart';
import '../data/profile_repository.dart';
import '../data/session_repository.dart';
import '../domain/user_profile.dart';
import '../domain/workout_session.dart';

/// Runs a workout: opening it, logging sets, ending it, and turning what
/// happened into next week's prescription.
///
/// An interface, so a widget test can assert that tapping "save set" asked
/// for that set without a database underneath it. What progression then
/// decides is the plan engine's business and is tested there.
abstract interface class SessionController {
  /// Opens a session against the plan's session on [weekday].
  Future<String> start(int weekday);

  /// Appends one completed set to the open session.
  ///
  /// [review] is what the camera made of it, when a camera watched: the
  /// form score progression reads, and the ledger of every attempt
  /// including the ones that were not counted.
  Future<void> logSet({
    required String exerciseId,
    required int setIndex,
    int? reps,
    int? holdSeconds,
    double? weightKg,
    SetReview? review,
    CameraAngle? cameraAngle,
  });

  /// Records that something hurt. Ends nothing by itself — the UI decides
  /// whether the user wants to stop — but it is never undone.
  Future<void> reportPain();

  /// Closes the session and writes what it earned into the plan.
  ///
  /// Returns one decision per exercise the user actually logged work for,
  /// so the UI can say what changed and why.
  Future<List<ProgressionDecision>> finish({SessionRating? rating});

  /// Throws the open session away.
  Future<void> discard();
}

/// The real one.
///
/// Everything interesting happens in [finish]: the session closes, the plan
/// engine decides what each exercise earned, and the result is saved as a new
/// plan revision. Progression is therefore just another plan edit, which is
/// why a plan the user has trained is never rewritten underneath its own
/// history.
class DatabaseSessionController implements SessionController {
  const DatabaseSessionController({
    required this.profiles,
    required this.plans,
    required this.sessions,
    required this.progression,
    required this.edits,
  });

  final ProfileRepository profiles;
  final PlanRepository plans;
  final SessionRepository sessions;
  final Progression progression;
  final PlanEdits edits;

  @override
  Future<String> start(int weekday) async {
    final day = await plans.dayRef(weekday: weekday);
    if (day == null) {
      throw StateError('No session is planned for weekday $weekday');
    }
    return sessions.start(day: day);
  }

  @override
  Future<void> logSet({
    required String exerciseId,
    required int setIndex,
    int? reps,
    int? holdSeconds,
    double? weightKg,
    SetReview? review,
    CameraAngle? cameraAngle,
  }) async {
    final session = await _requireActive();

    // The prescription this was performed against, when the plan has one.
    // Resolved per set rather than cached so that a plan edited mid-session
    // cannot leave a log pointing at a row that is no longer active.
    String? planExerciseId;
    final weekday = session.weekday;
    if (weekday != null) {
      final day = await plans.dayRef(weekday: weekday);
      planExerciseId = day?.exerciseRowIds[exerciseId];
    }

    await sessions.logSet(
      sessionId: session.id,
      exerciseId: exerciseId,
      setIndex: setIndex,
      planExerciseId: planExerciseId,
      reps: reps,
      holdSeconds: holdSeconds,
      weightKg: weightKg,
      formScore: review?.formScore,
      cameraAngle: cameraAngle,
      ledger: review?.reps ?? const [],
    );
  }

  @override
  Future<void> reportPain() async {
    final session = await _requireActive();
    await sessions.reportPain(session.id);
  }

  @override
  Future<List<ProgressionDecision>> finish({SessionRating? rating}) async {
    final session = await _requireActive();
    await sessions.finish(sessionId: session.id, rating: rating);

    final weekday = session.weekday;
    if (weekday == null) return const [];

    final profile = await profiles.load();
    final plan = await plans.loadActive();
    if (profile == null || plan == null) return const [];

    final day = plan.days.where((d) => d.weekday == weekday).firstOrNull;
    if (day == null) return const [];

    final inputs = <ProgressionInput>[];
    for (final exercise in day.exercises) {
      final logged = session.setsFor(exercise.exerciseId);
      // An exercise the user skipped entirely says nothing about what to
      // prescribe next. Feeding it in would produce a note explaining that
      // they did not do it, which they know.
      if (logged.isEmpty) continue;

      inputs.add(
        ProgressionInput(
          planned: exercise,
          completed: [for (final set in logged) set.toCompleted()],
          rating: rating,
          painReported: session.painReported,
          priorLowFormSessions: await sessions.lowFormStreakFor(
            exerciseId: exercise.exerciseId,
            excluding: session.id,
          ),
        ),
      );
    }
    if (inputs.isEmpty) return const [];

    final decisions = progression.decide(
      inputs: inputs,
      request: profile.toPlanRequest(),
    );

    if (decisions.any((decision) => decision.changesAnything)) {
      await _save(
        edits.applyProgression(
          plan: plan,
          weekday: weekday,
          decisions: decisions,
          request: profile.toPlanRequest(),
        ),
        profile,
      );
    }

    return decisions;
  }

  @override
  Future<void> discard() async {
    final session = await _requireActive();
    await sessions.discard(session.id);
  }

  Future<void> _save(WeekPlan plan, UserProfile profile) =>
      plans.saveRevision(plan, profileId: profile.id);

  Future<WorkoutSession> _requireActive() async {
    final session = await sessions.loadActive();
    if (session == null) {
      throw StateError('No session is open');
    }
    return session;
  }
}
