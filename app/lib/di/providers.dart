import 'package:coach_engine/coach_engine.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';
import 'package:sync_engine/sync_engine.dart';

import '../data/local/database.dart';
import '../data/local/local_identity_store.dart';
import '../data/local/training_eraser.dart';
import '../data/plan_repository.dart';
import '../data/profile_repository.dart';
import '../data/session_repository.dart';
import '../data/sync/drift_sync_store.dart';
import '../data/sync/session_store.dart';
import '../data/sync/supabase_auth.dart';
import '../data/sync/supabase_config.dart';
import '../data/sync/supabase_remote_store.dart';
import '../data/sync/sync_account.dart';
import '../data/sync/sync_tables.dart';
import '../domain/user_profile.dart';
import '../domain/workout_session.dart';
import '../state/account_controller.dart';
import '../state/erase_controller.dart';
import '../state/plan_controller.dart';
import '../state/profile_controller.dart';
import '../services/coach_voice.dart';
import '../state/session_controller.dart';

/// The app's single database handle.
///
/// Tests override this with an in-memory executor; see
/// `test/support/test_database.dart`.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(driftDatabase(name: 'spottr'));
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

/// This installation's own id, read once before the first frame.
///
/// No usable default, deliberately. Reading it is a database call and every
/// repository needs it synchronously, so `bootstrap()` reads it and
/// overrides this — and a scope that builds a repository without the
/// override would stamp somebody's training with the wrong device, which is
/// precisely what the sync's tie-break cannot survive. Better to fail where
/// the wiring is wrong than to fall back to a constant that is wrong on
/// every install at once.
final Provider<String> installIdProvider = Provider<String>((ref) {
  throw StateError(
    'installIdProvider was not overridden: the install id is read from the '
    'database by bootstrap() before the app starts. A test that builds a '
    'repository needs the same override.',
  );
});

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(databaseProvider),
    deviceId: ref.watch(installIdProvider),
  ),
);

final Provider<PlanRepository> planRepositoryProvider =
    Provider<PlanRepository>(
  (ref) => PlanRepository(
    ref.watch(databaseProvider),
    deviceId: ref.watch(installIdProvider),
  ),
);

final Provider<SessionRepository> sessionRepositoryProvider =
    Provider<SessionRepository>(
  (ref) => SessionRepository(
    ref.watch(databaseProvider),
    deviceId: ref.watch(installIdProvider),
  ),
);

/// The Supabase project this build was given, or null for a build without
/// one — in which case sync is simply not offered and everything else is
/// unchanged.
final Provider<SupabaseConfig?> supabaseConfigProvider =
    Provider<SupabaseConfig?>((ref) => SupabaseConfig.fromEnvironment());

/// Where the session is kept between launches.
///
/// The platform keychain. A provider because a widget test cannot reach one
/// — it is a method channel — and because the in-memory store is what the
/// app's own tests sync against.
final Provider<SessionStore> sessionStoreProvider =
    Provider<SessionStore>((ref) => KeychainSessionStore());

final Provider<LocalIdentityStore> localIdentityProvider =
    Provider<LocalIdentityStore>(
  (ref) => LocalIdentityStore(ref.watch(databaseProvider)),
);

/// Taking one person's training off this device.
///
/// Independent of whether this build has a Supabase project: the training
/// is on the device either way, and this is the only way out of a device
/// that already holds somebody's.
final Provider<TrainingEraser> trainingEraserProvider =
    Provider<TrainingEraser>(
  (ref) => TrainingEraser(
    database: ref.watch(databaseProvider),
    identity: ref.watch(localIdentityProvider),
    sessions: ref.watch(sessionStoreProvider),
  ),
);

/// The account, the sync, and nothing when this build has no project.
///
/// Null rather than throwing, because "no sync in this build" is a state
/// the screen has a sentence for, not a fault.
final Provider<AccountController?> accountControllerProvider =
    Provider<AccountController?>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (config == null) return null;

  final auth = SupabaseAuth(projectUrl: config.url, anonKey: config.anonKey);
  final account = SyncAccount(
    auth: auth,
    sessions: ref.watch(sessionStoreProvider),
    identity: ref.watch(localIdentityProvider),
    eraser: ref.watch(trainingEraserProvider),
  );
  ref.onDispose(account.dispose);

  return SyncAccountController(
    account: account,
    engine: SyncEngine(
      local: DriftSyncStore(ref.watch(databaseProvider)),
      remote: SupabaseRemoteStore(
        projectUrl: config.url,
        anonKey: config.anonKey,
        // Asked on every request rather than held, so a token renewed
        // between two tables is the one the second table uses.
        credentials: account.credentials,
      ),
      tables: spottrSyncTables,
    ),
  );
});

/// Deleting everything this device holds, for somebody who wants it gone.
///
/// Separate from the account controller, and deliberately: this one exists
/// on every build, including the ones with no Supabase project at all. The
/// account screen's erase is the same mechanism behind a different door,
/// worded for somebody handing a phone to another person.
final Provider<EraseController> eraseControllerProvider =
    Provider<EraseController>(
  (ref) => DeviceEraseController(ref.watch(trainingEraserProvider)),
);

/// The account as it stands, and every change to it.
///
/// Reads the stored session first so the screen has an answer on its first
/// frame, then follows the controller.
final StreamProvider<AccountState> accountProvider =
    StreamProvider<AccountState>((ref) async* {
  final controller = ref.watch(accountControllerProvider);
  if (controller == null) {
    yield const AccountState();
    return;
  }
  yield await controller.load();
  yield* controller.watch();
});

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

/// What the coach makes of the stream, for one exercise: the count and the
/// form rules in one object.
///
/// A provider rather than something the screen owns, because the analyzer is
/// stateful and a widget that fed it from `build` would count a rebuild as a
/// rep. Family-scoped, so leaving the screen disposes it and the next set
/// starts from zero.
///
/// One analyzer rather than a counter and a rule engine side by side: a rule
/// window is defined by the rep boundaries the counter found, and two
/// components deciding separately where a rep began are two components that
/// can disagree.
final StreamProviderFamily<CoachTick, CoachRequest> coachTickProvider =
    StreamProvider.family<CoachTick, CoachRequest>((ref, request) {
  final exercise = ref.watch(catalogProvider).require(request.exerciseId);
  if (counterFor(exercise) == null) {
    throw ArgumentError.value(
      request.exerciseId,
      'exerciseId',
      'no rep counter for this exercise',
    );
  }
  return ref.watch(poseFramesProvider).transform(
        CoachStream(
          exercise: exercise,
          targetReps: request.targetReps,
          targetHold: request.targetHold,
        ),
      );
});

/// The coach's voice.
///
/// A provider so that a widget test gets silence rather than an audio
/// channel, and so that muting is a property of the session rather than of
/// the device. Text-to-speech is lazy inside the speaker: nothing opens an
/// audio session until something is actually said.
final Provider<CoachSpeaker> coachSpeakerProvider = Provider<CoachSpeaker>(
  (ref) {
    final speaker = TtsCoachSpeaker();
    ref.onDispose(speaker.dispose);
    return speaker;
  },
);

/// One set to coach: which movement, and what it was prescribed.
///
/// A value rather than a bare id because it is a provider family key, and
/// because the target is what lets the coach say "that's your set" at the
/// right moment. Two sets of the same exercise with the same target share
/// an analyzer, which is correct: they are the same set until the screen
/// invalidates it.
@immutable
class CoachRequest {
  const CoachRequest({
    required this.exerciseId,
    this.targetReps,
    this.targetHold,
    this.run = 0,
  });

  final String exerciseId;
  final int? targetReps;
  final Duration? targetHold;

  /// Which attempt at this set is being watched.
  ///
  /// Part of the key so that starting a set again is a different provider
  /// rather than the same one invalidated. Invalidating is not enough: a
  /// refreshed stream keeps its previous value until the next frame
  /// arrives, so for a moment the new set would show the old set's count.
  final int run;

  @override
  bool operator ==(Object other) =>
      other is CoachRequest &&
      other.exerciseId == exerciseId &&
      other.targetReps == targetReps &&
      other.targetHold == targetHold &&
      other.run == run;

  @override
  int get hashCode => Object.hash(exerciseId, targetReps, targetHold, run);

  @override
  String toString() => 'CoachRequest($exerciseId, '
      'reps=$targetReps, hold=$targetHold, run=$run)';
}
