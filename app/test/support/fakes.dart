import 'package:exercise_library/exercise_library.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/state/plan_controller.dart';
import 'package:spottr/state/profile_controller.dart';

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
