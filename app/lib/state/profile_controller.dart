import 'package:plan_engine/plan_engine.dart';

import '../data/plan_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Saves the profile and keeps the plan consistent with it.
///
/// An interface, so that a widget test can assert what a screen asked for
/// without a database underneath it. Screens are tested for the answers
/// they collect; whether those answers reach SQLite is [ProfileRepository]'s
/// business and is tested there.
abstract interface class ProfileController {
  /// Stores [profile], rebuilding the week if the change calls for it.
  Future<void> save(UserProfile profile);
}

/// The real one.
///
/// The only interesting decision here is when a profile change costs the
/// user their plan. Regenerating throws away every swap and reorder they
/// made, so it happens when an answer the generator actually reads changed,
/// and not when they picked a different coach voice.
class DatabaseProfileController implements ProfileController {
  const DatabaseProfileController({
    required this.profiles,
    required this.plans,
    required this.generator,
  });

  final ProfileRepository profiles;
  final PlanRepository plans;
  final PlanGenerator generator;

  /// Validation runs before anything is written, so a rejected profile
  /// leaves no half-saved state behind.
  @override
  Future<void> save(UserProfile profile) async {
    profile.validate();

    final previous = await profiles.load();
    await profiles.save(profile);

    final needsPlan = previous == null ||
        previous.wouldChangePlan(profile) ||
        await plans.loadActive(profileId: profile.id) == null;

    if (needsPlan) {
      await plans.saveRevision(
        generator.generate(profile.toPlanRequest()),
        profileId: profile.id,
      );
    }
  }
}
