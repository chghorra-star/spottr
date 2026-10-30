import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Columns every table that will eventually sync to Supabase must carry.
///
/// They are present from schema v1 on purpose: bolting sync on later would
/// otherwise mean a migration touching every table at once. [AppDatabase]
/// has a test that keeps this contract honest.
mixin SyncMeta on Table {
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  TextColumn get deviceId => text().withLength(max: 64)();
}

@DataClassName('ProfileRow')
class Profiles extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get goal => text()(); // weightLoss | muscleBuilding | hybrid
  IntColumn get daysPerWeek => integer()();
  IntColumn get sessionMinutes => integer()();
  TextColumn get level => text()(); // beginner | intermediate | advanced
  IntColumn get ageYears => integer().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get sex => text().nullable()();

  /// JSON array of body parts, e.g. ["knees","lowerBack"].
  TextColumn get injuries => text().withDefault(const Constant('[]'))();
  TextColumn get injuryNotes => text().nullable()();

  TextColumn get location => text()(); // homeNone | homeDumbbells | fullGym

  /// JSON array of available equipment beyond what [location] implies.
  TextColumn get equipment => text().withDefault(const Constant('[]'))();

  TextColumn get coachPersonality => text()(); // hype | calm | tough

  /// JSON array of ISO weekday numbers the user runs on (hybrid goal only).
  TextColumn get runDays => text().withDefault(const Constant('[]'))();

  BoolColumn get disclaimerAccepted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get units => text().withDefault(const Constant('metric'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PlanRow')
class Plans extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get templateId => text()(); // fullBody3 | upperLower4 | ppl6 ...
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PlanDayRow')
class PlanDays extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get planId => text().references(Plans, #id)();

  /// Position in the week, 0-based. Not a weekday: the user can move days.
  IntColumn get dayIndex => integer()();
  TextColumn get labelKey => text()(); // ARB key, e.g. day_push
  BoolColumn get isRunDay => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PlanExerciseRow')
class PlanExercises extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get planDayId => text().references(PlanDays, #id)();
  IntColumn get orderIndex => integer()();

  /// Catalog id from the exercise_library package, not a foreign key.
  TextColumn get exerciseId => text()();

  IntColumn get targetSets => integer()();
  IntColumn get targetRepsMin => integer().nullable()();
  IntColumn get targetRepsMax => integer().nullable()();
  IntColumn get targetHoldSeconds => integer().nullable()();
  RealColumn get targetWeightKg => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SessionRow')
class Sessions extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get planDayId => text().nullable().references(PlanDays, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Post-session rating that feeds progression: tooEasy | right | tooHard.
  TextColumn get rating => text().nullable()();

  /// Set by the pain button. Never overwritten by progression.
  BoolColumn get painReported => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SetLogRow')
class SetLogs extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get planExerciseId =>
      text().nullable().references(PlanExercises, #id)();
  TextColumn get exerciseId => text()();
  IntColumn get setIndex => integer()();

  /// Reps the counter accepted. Rejected reps live in [RepLogs].
  IntColumn get reps => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get holdSeconds => integer().nullable()();

  /// 0..100, mean over counted reps. Null when the set ran without camera.
  RealColumn get formScore => real().nullable()();
  TextColumn get cameraAngle => text().nullable()(); // side | front | none
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RepLogRow')
class RepLogs extends Table {
  TextColumn get id => text()();
  TextColumn get setLogId => text().references(SetLogs, #id)();
  IntColumn get repIndex => integer()();

  /// Whether this rep counted, and if not why — the user-facing ledger.
  BoolColumn get counted => boolean()();
  TextColumn get rejectionReason => text().nullable()();

  IntColumn get durationMs => integer()();
  RealColumn get peakAngle => real().nullable()();
  RealColumn get rangeOfMotion => real().nullable()();
  RealColumn get formScore => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FormEventRow')
class FormEvents extends Table {
  TextColumn get id => text()();
  TextColumn get setLogId => text().references(SetLogs, #id)();
  IntColumn get repIndex => integer().nullable()();

  /// Rule id from the exercise catalog, e.g. squat_depth.
  TextColumn get ruleId => text()();
  TextColumn get severity => text()(); // minor | major | unsafe
  RealColumn get magnitude => real()();
  IntColumn get atMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PersonalRecordRow')
class PersonalRecords extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get exerciseId => text()();

  /// maxWeight | estimated1Rm | maxVolume | maxHold
  TextColumn get kind => text()();
  RealColumn get value => real()();
  DateTimeColumn get achievedAt => dateTime()();
  TextColumn get sessionId => text().nullable().references(Sessions, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Profiles,
    Plans,
    PlanDays,
    PlanExercises,
    Sessions,
    SetLogs,
    RepLogs,
    FormEvents,
    PersonalRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'spottr'));

  AppDatabase.forTesting(super.e);

  /// Tables that will replicate once the sync milestone lands.
  static const Set<String> syncableTableNames = {
    'profiles',
    'plans',
    'plan_days',
    'plan_exercises',
    'sessions',
    'set_logs',
    'personal_records',
  };

  /// Diagnostic tables that stay on the device. These hold per-rep traces and
  /// rule verdicts — valuable for debugging and for building harness
  /// fixtures, but thousands of rows per session and of no use to a peer.
  static const Set<String> localOnlyTableNames = {
    'rep_logs',
    'form_events',
  };

  @override
  int get schemaVersion => 1;
}
