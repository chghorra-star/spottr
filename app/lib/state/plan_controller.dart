import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';

import '../data/plan_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Applies the user's edits to the stored plan.
///
/// An interface, so a widget test can assert that tapping an alternative
/// asked for that swap without a database underneath it. Whether the swap
/// is legal is the plan engine's business and is tested there.
abstract interface class PlanController {
  /// Exercises that could take the place of [exerciseId] on [weekday].
  Future<List<Exercise>> alternativesFor({
    required int weekday,
    required String exerciseId,
  });

  Future<void> swap({
    required int weekday,
    required String exerciseId,
    required String replacementId,
  });

  Future<void> reorder({
    required int weekday,
    required int fromIndex,
    required int toIndex,
  });

  Future<void> moveDay({
    required int fromWeekday,
    required int toWeekday,
  });

  /// Builds a fresh week from the profile, discarding every edit.
  Future<void> regenerate();
}

/// The real one.
///
/// Every operation reads the current plan, hands it to [PlanEdits], and
/// writes the result as a new revision. The edit rules themselves live in
/// the plan engine, where they are tested without a database; this class
/// only moves plans between storage and those rules.
class DatabasePlanController implements PlanController {
  const DatabasePlanController({
    required this.profiles,
    required this.plans,
    required this.generator,
    required this.edits,
  });

  final ProfileRepository profiles;
  final PlanRepository plans;
  final PlanGenerator generator;
  final PlanEdits edits;

  /// Exercises that could take the place of [exerciseId] on [weekday].
  @override
  Future<List<Exercise>> alternativesFor({
    required int weekday,
    required String exerciseId,
  }) async {
    final context = await _load();
    return edits.alternativesFor(
      plan: context.plan,
      weekday: weekday,
      exerciseId: exerciseId,
      request: context.request,
    );
  }

  @override
  Future<void> swap({
    required int weekday,
    required String exerciseId,
    required String replacementId,
  }) async {
    final context = await _load();
    await _save(
      edits.swapExercise(
        plan: context.plan,
        weekday: weekday,
        exerciseId: exerciseId,
        replacementId: replacementId,
        request: context.request,
      ),
      context.profile,
    );
  }

  @override
  Future<void> reorder({
    required int weekday,
    required int fromIndex,
    required int toIndex,
  }) async {
    final context = await _load();
    await _save(
      edits.reorderExercise(
        plan: context.plan,
        weekday: weekday,
        fromIndex: fromIndex,
        toIndex: toIndex,
      ),
      context.profile,
    );
  }

  @override
  Future<void> moveDay({
    required int fromWeekday,
    required int toWeekday,
  }) async {
    final context = await _load();
    await _save(
      edits.moveDay(
        plan: context.plan,
        fromWeekday: fromWeekday,
        toWeekday: toWeekday,
        request: context.request,
      ),
      context.profile,
    );
  }

  /// Builds a fresh week from the profile, discarding every edit.
  ///
  /// Destructive, so the UI asks first.
  @override
  Future<void> regenerate() async {
    final profile = await _requireProfile();
    await _save(generator.generate(profile.toPlanRequest()), profile);
  }

  Future<void> _save(WeekPlan plan, UserProfile profile) =>
      plans.saveRevision(plan, profileId: profile.id);

  Future<UserProfile> _requireProfile() async {
    final profile = await profiles.load();
    if (profile == null) {
      throw StateError('No profile stored: onboarding has not run');
    }
    return profile;
  }

  Future<_EditContext> _load() async {
    final profile = await _requireProfile();
    final plan = await plans.loadActive(profileId: profile.id);
    if (plan == null) {
      throw StateError('No active plan to edit');
    }
    return _EditContext(profile, plan);
  }
}

/// The profile and plan an edit operates on, loaded together so that the
/// request an edit is validated against is the one the plan was built from.
class _EditContext {
  _EditContext(this.profile, this.plan) : request = profile.toPlanRequest();

  final UserProfile profile;
  final WeekPlan plan;
  final PlanRequest request;
}
