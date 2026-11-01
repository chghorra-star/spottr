import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:pose_core/pose_core.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/state/plan_controller.dart';
import 'package:spottr/state/profile_controller.dart';
import 'package:spottr/state/session_controller.dart';

/// Records what a screen asked for, instead of doing it.
///
/// Widget tests use these so that what is under test is the screen: which
/// answers it collected, which edit a tap asked for. Whether those requests
/// are then carried out correctly is the controllers' and repositories'
/// business, and is covered by their own tests against a real database.
class RecordingProfileController implements ProfileController {
  RecordingProfileController({this.onSave});

  /// Lets a test make the save fail, to check the screen shows it.
  final Future<void> Function(UserProfile profile)? onSave;

  final List<UserProfile> saved = [];

  @override
  Future<void> save(UserProfile profile) async {
    saved.add(profile);
    if (onSave != null) await onSave!(profile);
  }
}

class RecordingSessionController implements SessionController {
  RecordingSessionController({
    this.decisions = const [],
    this.onStart,
    this.onFinish,
    this.onLogSet,
  });

  /// What [finish] reports back, so a test can check the summary renders it.
  final List<ProgressionDecision> decisions;

  /// Lets a test make starting fail, to check the screen shows it.
  final Future<void> Function(int weekday)? onStart;

  /// Lets a test end the session the screen is watching, which is what the
  /// real one does — and what the screen has to survive.
  final Future<void> Function()? onFinish;

  /// Lets a test make saving fail, which the coach screen has to show
  /// rather than swallow.
  final Future<void> Function()? onLogSet;

  final List<PlanEditCall> calls = [];

  @override
  Future<String> start(int weekday) async {
    calls.add(PlanEditCall('start', {'weekday': weekday}));
    if (onStart != null) await onStart!(weekday);
    return 'session_1';
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
    if (onLogSet != null) await onLogSet!();
    calls.add(
      PlanEditCall('logSet', {
        'exerciseId': exerciseId,
        'setIndex': setIndex,
        'reps': reps,
        'holdSeconds': holdSeconds,
        'weightKg': weightKg,
        'formScore': review?.formScore,
        'ledger': review?.reps.length,
        'cameraAngle': cameraAngle?.name,
      }),
    );
  }

  @override
  Future<void> reportPain() async => calls.add(PlanEditCall('reportPain'));

  @override
  Future<List<ProgressionDecision>> finish({SessionRating? rating}) async {
    calls.add(PlanEditCall('finish', {'rating': rating}));
    if (onFinish != null) await onFinish!();
    return decisions;
  }

  @override
  Future<void> discard() async => calls.add(PlanEditCall('discard'));

  List<String> get names => [for (final call in calls) call.name];

  PlanEditCall? lastCallTo(String name) {
    for (final call in calls.reversed) {
      if (call.name == name) return call;
    }
    return null;
  }
}

/// One recorded edit request.
class PlanEditCall {
  PlanEditCall(this.name, [this.arguments = const {}]);

  final String name;
  final Map<String, Object?> arguments;

  @override
  String toString() => '$name($arguments)';
}

class RecordingPlanController implements PlanController {
  RecordingPlanController({this.alternatives = const []});

  /// What [alternativesFor] returns, whatever it is asked about.
  final List<Exercise> alternatives;

  final List<PlanEditCall> calls = [];

  @override
  Future<List<Exercise>> alternativesFor({
    required int weekday,
    required String exerciseId,
  }) async {
    calls.add(
      PlanEditCall('alternativesFor', {
        'weekday': weekday,
        'exerciseId': exerciseId,
      }),
    );
    return alternatives;
  }

  @override
  Future<void> swap({
    required int weekday,
    required String exerciseId,
    required String replacementId,
  }) async {
    calls.add(
      PlanEditCall('swap', {
        'weekday': weekday,
        'exerciseId': exerciseId,
        'replacementId': replacementId,
      }),
    );
  }

  @override
  Future<void> reorder({
    required int weekday,
    required int fromIndex,
    required int toIndex,
  }) async {
    calls.add(
      PlanEditCall('reorder', {
        'weekday': weekday,
        'fromIndex': fromIndex,
        'toIndex': toIndex,
      }),
    );
  }

  @override
  Future<void> moveDay({
    required int fromWeekday,
    required int toWeekday,
  }) async {
    calls.add(
      PlanEditCall('moveDay', {
        'fromWeekday': fromWeekday,
        'toWeekday': toWeekday,
      }),
    );
  }

  @override
  Future<void> regenerate() async => calls.add(PlanEditCall('regenerate'));

  /// The names of the edits that were asked for, in order.
  List<String> get names => [for (final call in calls) call.name];

  PlanEditCall? lastCallTo(String name) {
    for (final call in calls.reversed) {
      if (call.name == name) return call;
    }
    return null;
  }
}
