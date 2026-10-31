import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../data/local/database.dart';
import '../data/plan_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';
import '../state/plan_controller.dart';
import '../state/profile_controller.dart';

/// The app's single database handle.
///
/// Tests override this with an in-memory executor; see
/// `test/support/test_database.dart`.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// The curated exercise catalog.
///
/// A provider rather than a direct reference so a test can substitute a
/// small catalog, and so nothing in the UI reaches into the library's
/// globals.
final Provider<ExerciseCatalog> catalogProvider =
    Provider<ExerciseCatalog>((ref) => standardCatalog);

final Provider<PlanGenerator> planGeneratorProvider =
    Provider<PlanGenerator>((ref) => PlanGenerator(ref.watch(catalogProvider)));

final Provider<PlanEdits> planEditsProvider =
    Provider<PlanEdits>((ref) => PlanEdits(ref.watch(catalogProvider)));

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final Provider<PlanRepository> planRepositoryProvider =
    Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(databaseProvider)),
);

/// The stored profile, or null while there is none.
///
/// Null is what routes the user into onboarding, so it is a legitimate
/// value rather than an error.
final StreamProvider<UserProfile?> profileProvider =
    StreamProvider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).watch(),
);

/// The active plan revision, or null while there is none.
final StreamProvider<WeekPlan?> activePlanProvider = StreamProvider<WeekPlan?>(
  (ref) => ref.watch(planRepositoryProvider).watchActive(),
);

final Provider<ProfileController> profileControllerProvider =
    Provider<ProfileController>(
  (ref) => DatabaseProfileController(
    profiles: ref.watch(profileRepositoryProvider),
    plans: ref.watch(planRepositoryProvider),
    generator: ref.watch(planGeneratorProvider),
  ),
);

final Provider<PlanController> planControllerProvider =
    Provider<PlanController>(
  (ref) => DatabasePlanController(
    profiles: ref.watch(profileRepositoryProvider),
    plans: ref.watch(planRepositoryProvider),
    generator: ref.watch(planGeneratorProvider),
    edits: ref.watch(planEditsProvider),
  ),
);
