import 'package:coach_engine/coach_engine.dart';
import 'package:drift/drift.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';

import '../domain/user_profile.dart';
import 'local/codecs.dart';
import 'local/database.dart';

/// Reads and writes the one profile this device holds.
class ProfileRepository {
  ProfileRepository(
    this._db, {
    this.deviceId = defaultDeviceId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// What a repository built without an install id calls itself.
  ///
  /// The real one comes from `LocalIdentityStore` through
  /// `installIdProvider`, read once at startup — and it has to, because a
  /// constant shared by every installation is a tie-break that cannot break
  /// anything. Two edits claiming the same instant would resolve to "keep
  /// mine" on both devices and stay different for ever.
  ///
  /// This stays as the convenient default for a repository constructed
  /// directly in a test, where one device is the only device. It is also
  /// what every row written before M10 carries, and those rows keep it:
  /// rewriting them to this install's new id would be a claim about who
  /// wrote them that a second device would contradict.
  static const String defaultDeviceId = 'local';

  final AppDatabase _db;
  final String deviceId;
  final DateTime Function() _now;

  /// The stored profile, and every later version of it.
  ///
  /// Emits null while there is none, which is how the app knows to show
  /// onboarding.
  Stream<UserProfile?> watch() => _query().watchSingleOrNull().map(_decode);

  Future<UserProfile?> load() async => _decode(await _query().getSingleOrNull());

  Future<void> save(UserProfile profile) async {
    profile.validate();
    await _db.into(_db.profiles).insertOnConflictUpdate(_encode(profile));
  }

  SingleOrNullSelectable<ProfileRow> _query() => _db.select(_db.profiles)
    ..where((row) => row.deletedAt.isNull())
    ..limit(1);

  ProfilesCompanion _encode(UserProfile profile) => ProfilesCompanion(
        id: Value(profile.id),
        goal: Value(profile.goal.name),
        daysPerWeek: Value(profile.daysPerWeek),
        sessionMinutes: Value(profile.sessionMinutes),
        level: Value(profile.level.name),
        ageYears: Value(profile.ageYears),
        heightCm: Value(profile.heightCm),
        weightKg: Value(profile.weightKg),
        sex: Value(profile.sex?.name),
        injuries: Value(
          encodeEnumSet(profile.injuries, BodyPart.values),
        ),
        injuryNotes: Value(profile.injuryNotes),
        location: Value(profile.location.name),
        equipment: Value(
          encodeEnumSet(profile.extraEquipment, Equipment.values),
        ),
        coachPersonality: Value(profile.coachStyle.name),
        runDays: Value(encodeIntSet(profile.runWeekdays)),
        disclaimerAcceptedAt: Value(profile.disclaimerAcceptedAt),
        updatedAt: Value(_now()),
        deletedAt: const Value(null),
        deviceId: Value(deviceId),
      );

  UserProfile? _decode(ProfileRow? row) {
    if (row == null) return null;
    return UserProfile(
      id: row.id,
      goal: enumByName(Goal.values, row.goal, column: 'profiles.goal'),
      daysPerWeek: row.daysPerWeek,
      sessionMinutes: row.sessionMinutes,
      level: enumByName(Level.values, row.level, column: 'profiles.level'),
      location: enumByName(
        TrainingLocation.values,
        row.location,
        column: 'profiles.location',
      ),
      coachStyle: enumByName(
        CoachStyle.values,
        row.coachPersonality,
        column: 'profiles.coach_personality',
      ),
      ageYears: row.ageYears,
      heightCm: row.heightCm,
      weightKg: row.weightKg,
      sex: enumByNameOrNull(Sex.values, row.sex, column: 'profiles.sex'),
      // An injury we cannot decode must not be silently dropped: the whole
      // point of collecting it is to keep exercises out of the plan.
      injuries: decodeEnumSet(
        row.injuries,
        BodyPart.values,
        column: 'profiles.injuries',
      ),
      injuryNotes: row.injuryNotes,
      // Equipment is the opposite case. Ignoring a machine we do not know
      // about costs one option; refusing to load costs the user the app.
      extraEquipment: decodeEnumSet(
        row.equipment,
        Equipment.values,
        column: 'profiles.equipment',
        skipUnknown: true,
      ),
      runWeekdays: decodeIntSet(row.runDays, column: 'profiles.run_days'),
      disclaimerAcceptedAt: row.disclaimerAcceptedAt,
    );
  }
}
