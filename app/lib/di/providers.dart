import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';

import '../data/local/database.dart';
import '../data/plan_repository.dart';
import '../data/profile_repository.dart';
import '../data/session_repository.dart';
import '../domain/user_profile.dart';
import '../domain/workout_session.dart';
import '../state/plan_controller.dart';
import '../state/profile_controller.dart';
import '../state/session_controller.dart';

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

final Provider<Progression> progressionProvider =
    Provider<Progression>((ref) => Progression(ref.watch(catalogProvider)));

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final Provider<PlanRepository> planRepositoryProvider =
    Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(databaseProvider)),
);

final Provider<SessionRepository> sessionRepositoryProvider =
    Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
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

/// The workout in progress, or null when the user is not mid-session.
///
/// Null is what the plan screen watches to decide between offering a start
/// and offering to pick up where they left off.
final StreamProvider<WorkoutSession?> activeSessionProvider =
    StreamProvider<WorkoutSession?>(
  (ref) => ref.watch(sessionRepositoryProvider).watchActive(),
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

final Provider<SessionController> sessionControllerProvider =
    Provider<SessionController>(
  (ref) => DatabaseSessionController(
    profiles: ref.watch(profileRepositoryProvider),
    plans: ref.watch(planRepositoryProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    progression: ref.watch(progressionProvider),
    edits: ref.watch(planEditsProvider),
  ),
);

/// The camera and the pose model.
///
/// A provider so that tests — and the fixture replay the whole engine is
/// developed against — substitute `FakePoseCamera` here and exercise every
/// layer above it for real.
final Provider<PoseSource> poseSourceProvider = Provider<PoseSource>((ref) {
  final source = DevicePoseCamera();
  ref.onDispose(source.dispose);
  return source;
});

/// The smoothed landmark stream, smoothed exactly once.
///
/// Smoothing sits here rather than in the camera or in each consumer: raw
/// landmarks jitter by a couple of pixels even on a body that is holding
/// still, and the overlay, the framing check and the rep counter all want
/// the same steadied signal rather than three different ones.
///
/// Broadcast on purpose. A transformer builds a fresh filter per
/// subscription, so without this the overlay and the rep counter would each
/// run their own — started at different moments, and therefore disagreeing
/// about the same body for the first few frames. It would also mean the
/// counter in the app and the counter in the accuracy harness were fed
/// differently filtered signals, which is the one thing the harness exists
/// to rule out.
final Provider<Stream<PoseFrame>> poseFramesProvider =
    Provider<Stream<PoseFrame>>(
  (ref) => ref
      .watch(poseSourceProvider)
      .frames
      .transform(const PoseSmoothing())
      .asBroadcastStream(),
);

/// Smoothed landmark frames, for anything that reads one frame at a time.
final StreamProvider<PoseFrame> poseFrameProvider = StreamProvider<PoseFrame>(
  (ref) => ref.watch(poseFramesProvider),
);

/// What the rep counter makes of the stream, for one exercise.
///
/// A provider rather than something the screen owns, because a counter is
/// stateful and a widget that fed it from `build` would count a rebuild as a
/// rep. Family-scoped, so leaving the screen disposes it and the next set
/// starts from zero.
final StreamProviderFamily<CounterTick, String> counterTickProvider =
    StreamProvider.family<CounterTick, String>((ref, exerciseId) {
  final config = counterFor(ref.watch(catalogProvider).require(exerciseId));
  if (config == null) {
    throw ArgumentError.value(
      exerciseId,
      'exerciseId',
      'no rep counter for this exercise',
    );
  }
  return ref.watch(poseFramesProvider).transform(CounterStream(config));
});
