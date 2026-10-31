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

  /// JSON array of ISO weekday numbers the user runs on.
  ///
  /// Kept whatever the goal is, so that a user who switches to hybrid and
  /// back does not have to enter them twice. Only a hybrid goal actually
  /// feeds them to the generator.
  TextColumn get runDays => text().withDefault(const Constant('[]'))();

  /// When the safety disclaimer was accepted, or null if it has not been.
  ///
  /// A timestamp rather than a flag: this gates the whole app, and "when did
  /// they agree, and to which wording" is the question you want answerable.
  DateTimeColumn get disclaimerAcceptedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One revision of a generated week.
///
/// Plans are immutable: an edit writes a new revision and deactivates the
/// previous one rather than rewriting its rows. Session logs point at the
/// exact [PlanExercises] row they were performed against, so a plan the user
/// has trained is never altered underneath its own history.
@DataClassName('PlanRow')
class Plans extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get templateId => text()(); // full_body_3 | upper_lower_4 | ppl_6
  TextColumn get goal => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// Exactly one revision per profile is active at a time.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// JSON array of ISO weekdays the plan was scheduled around.
  TextColumn get runDays => text().withDefault(const Constant('[]'))();

  /// JSON array of ARB keys for the text running suggestions.
  TextColumn get runSuggestionKeys =>
      text().withDefault(const Constant('[]'))();

  /// JSON array of `{kind, detail, weekday}` objects: why the plan does not
  /// look like the plain template. Stored because the UI explains a short or
  /// simplified plan from them, and an edit rewrites them.
  TextColumn get notes => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PlanDayRow')
class PlanDays extends Table with SyncMeta {
  TextColumn get id => text()();
  TextColumn get planId => text().references(Plans, #id)();

  /// ISO weekday, 1 = Monday. The weekday is the identity of a session: the
  /// scheduler places days around run days, and moving a day changes this.
  IntColumn get weekday => integer()();

  /// `DayType` name, e.g. push. Needed to rebuild the day, since the label
  /// alone does not say what kind of session it is.
  TextColumn get dayType => text()();
  TextColumn get labelKey => text()(); // ARB key, e.g. day_push

  /// Whether a run falls the day after this one. Leg volume is capped on
  /// these days.
  BoolColumn get precedesRunDay =>
      boolean().withDefault(const Constant(false))();

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

  /// `MovementPattern` name of the slot this fills, which is not always the
  /// exercise's own pattern: an isolation fallback can fill an accessory
  /// slot. A swap has to keep the slot, so the slot is stored.
  TextColumn get slotPattern => text()();

  /// `SlotPriority` name. Decides what the time budget trims first.
  TextColumn get priority => text()();

  IntColumn get targetSets => integer()();

  /// Sets the template asked for, before the pre-run leg cap or any time
  /// trimming. Without it an edit cannot tell a deliberately trimmed day
  /// from a full one, and moving a day could not restore its volume.
  IntColumn get templateSets => integer()();

  /// `MetricType` name: reps or holdSeconds.
  TextColumn get metric => text()();

  IntColumn get restSeconds => integer()();
  RealColumn get secondsPerRep => real()();

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

  /// Timestamps are stored as ISO-8601 text, not as unix seconds.
  ///
  /// The integer format says nothing about the zone and truncates to the
  /// second, so a UTC value written on one device reads back as a local one
  /// with its sub-second part gone. For rows that will eventually be
  /// reconciled across devices by their timestamps, that is not a detail.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  int get schemaVersion => 1;
}
