import 'dart:async';

import 'package:drift/drift.dart';
import 'package:plan_engine/plan_engine.dart';

import '../domain/workout_session.dart';
import 'local/codecs.dart';
import 'local/database.dart';
import 'plan_repository.dart';
import 'profile_repository.dart';

/// Stores what the user actually did.
///
/// One session at a time, by design: a workout is a thing you are in the
/// middle of, and two open at once would mean two answers to "which set am I
/// on". [start] refuses rather than guessing.
///
/// Logs are append-only. A set the user wants gone is corrected by the UI
/// before it is written; once written it is evidence, and progression is
/// entitled to trust that it happened.
class SessionRepository {
  SessionRepository(
    this._db, {
    this.deviceId = ProfileRepository.defaultDeviceId,
    String Function()? newId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _newId = newId ?? _sequentialId;
  }

  final AppDatabase _db;
  final String deviceId;
  final DateTime Function() _now;
  late final String Function() _newId;
  int _sequence = 0;

  /// Mean form under this is a bad session; see [Progression.formFloor].
  static double get formFloor => Progression.formFloor;

  /// The session in progress, and every change to it.
  ///
  /// Emits null when there is none, which is what the plan screen watches to
  /// decide between "start" and "resume".
  ///
  /// Watches the set logs as well as the session row, and that is the whole
  /// point of writing it by hand. Logging a set does not touch the `sessions`
  /// row, so a watch on that table alone never fires — the plan repository
  /// gets away with one table only because every plan edit inserts a plan
  /// row. Here it meant a logged set vanished until the screen was rebuilt
  /// for some other reason, which is exactly what it looked like on a phone.
  Stream<WorkoutSession?> watchActive() {
    late StreamController<WorkoutSession?> controller;
    StreamSubscription<void>? changes;
    var queue = Future<void>.value();

    // Re-reads are chained rather than fired off in parallel: two updates in
    // quick succession would otherwise race, and the older read could be the
    // one delivered last.
    void reread() {
      queue = queue.then((_) async {
        if (controller.isClosed) return;
        final session = await loadActive();
        if (!controller.isClosed) controller.add(session);
      });
    }

    controller = StreamController<WorkoutSession?>(
      onListen: () {
        changes = _db
            .tableUpdates(
              TableUpdateQuery.onAllTables([_db.sessions, _db.setLogs]),
            )
            .listen((_) => reread());
        reread();
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  Future<WorkoutSession?> loadActive() async {
    final row = await _activeQuery().getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  Future<WorkoutSession?> load(String id) async {
    final row = await (_db.select(_db.sessions)
          ..where((row) => row.id.equals(id) & row.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  /// Opens a session against one day of the active plan revision.
  ///
  /// Throws if one is already open: the caller has to decide whether to
  /// resume it or throw it away, and that is not a choice to make silently.
  Future<String> start({PlanDayRef? day}) async {
    final existing = await _activeQuery().getSingleOrNull();
    if (existing != null) {
      throw StateError(
        'A session started at ${existing.startedAt} is still open',
      );
    }

    final id = _newId();
    await _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            id: id,
            planDayId: Value(day?.dayId),
            startedAt: _now(),
            deviceId: deviceId,
            updatedAt: Value(_now()),
          ),
        );
    return id;
  }

  /// Appends one completed set.
  ///
  /// [planExerciseId] is the prescription it was performed against. Null is
  /// legitimate — work done off-plan — but when the plan knows the row, it
  /// is passed, because that pointer is what lets progression read what was
  /// asked for rather than guessing from the catalog.
  Future<String> logSet({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
    String? planExerciseId,
    int? reps,
    int? holdSeconds,
    double? weightKg,
    double? formScore,
  }) async {
    if (reps == null && holdSeconds == null) {
      throw ArgumentError('A logged set is either reps or a hold');
    }

    final id = _newId();
    await _db.into(_db.setLogs).insert(
          SetLogsCompanion.insert(
            id: id,
            sessionId: sessionId,
            exerciseId: exerciseId,
            setIndex: setIndex,
            reps: reps ?? 0,
            completedAt: _now(),
            deviceId: deviceId,
            planExerciseId: Value(planExerciseId),
            weightKg: Value(weightKg),
            holdSeconds: Value(holdSeconds),
            formScore: Value(formScore),
            updatedAt: Value(_now()),
          ),
        );
    return id;
  }

  /// Records that something hurt.
  ///
  /// One-way: there is no un-report. The flag stops progression adding load
  /// and it stays on the session as the record of why.
  Future<void> reportPain(String sessionId) async {
    await (_db.update(_db.sessions)..where((row) => row.id.equals(sessionId)))
        .write(
      SessionsCompanion(
        painReported: const Value(true),
        updatedAt: Value(_now()),
        deviceId: Value(deviceId),
      ),
    );
  }

  /// Closes the session. [rating] may be null if the user skipped the
  /// question, which progression treats as no opinion rather than "fine".
  Future<void> finish({
    required String sessionId,
    SessionRating? rating,
    String? notes,
  }) async {
    await (_db.update(_db.sessions)..where((row) => row.id.equals(sessionId)))
        .write(
      SessionsCompanion(
        endedAt: Value(_now()),
        rating: Value(rating?.name),
        notes: Value(notes),
        updatedAt: Value(_now()),
        deviceId: Value(deviceId),
      ),
    );
  }

  /// Throws the session away: an accidental start, or a workout abandoned
  /// before anything worth keeping happened.
  ///
  /// Soft, like every delete here, so a peer eventually learns about it.
  Future<void> discard(String sessionId) async {
    final timestamp = _now();
    await _db.transaction(() async {
      await (_db.update(_db.setLogs)
            ..where((row) => row.sessionId.equals(sessionId)))
          .write(
        SetLogsCompanion(
          deletedAt: Value(timestamp),
          updatedAt: Value(timestamp),
          deviceId: Value(deviceId),
        ),
      );
      await (_db.update(_db.sessions)..where((row) => row.id.equals(sessionId)))
          .write(
        SessionsCompanion(
          deletedAt: Value(timestamp),
          updatedAt: Value(timestamp),
          deviceId: Value(deviceId),
        ),
      );
    });
  }

  /// Finished sessions that included [exerciseId], newest first.
  Future<List<WorkoutSession>> recentFor({
    required String exerciseId,
    int limit = 10,
  }) async {
    final rows = await (_db.select(_db.sessions)
          ..where((row) => row.deletedAt.isNull() & row.endedAt.isNotNull())
          ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
        .get();

    final sessions = <WorkoutSession>[];
    for (final row in rows) {
      if (sessions.length == limit) break;
      final session = await _hydrate(row);
      if (session.setsFor(exerciseId).isNotEmpty) sessions.add(session);
    }
    return sessions;
  }

  /// How many finished sessions in a row came in under [formFloor] on
  /// [exerciseId], not counting [excluding].
  ///
  /// Until the camera lands every form score is null, so this is zero for
  /// everybody — which is the point. A streak counter that treated "no data"
  /// as "bad form" would regress every user in the app.
  Future<int> lowFormStreakFor({
    required String exerciseId,
    String? excluding,
  }) async {
    final history = await recentFor(exerciseId: exerciseId);
    var streak = 0;
    for (final session in history) {
      if (session.id == excluding) continue;
      final mean = session.meanFormFor(exerciseId);
      if (mean == null || mean >= formFloor) break;
      streak++;
    }
    return streak;
  }

  SingleOrNullSelectable<SessionRow> _activeQuery() => _db.select(_db.sessions)
    ..where((row) => row.endedAt.isNull() & row.deletedAt.isNull())
    ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
    ..limit(1);

  Future<WorkoutSession> _hydrate(SessionRow row) async {
    final setRows = await (_db.select(_db.setLogs)
          ..where(
            (log) => log.sessionId.equals(row.id) & log.deletedAt.isNull(),
          )
          ..orderBy([
            (log) => OrderingTerm.asc(log.completedAt),
            // Two sets saved inside one clock tick would otherwise come back
            // in whatever order SQLite felt like.
            (log) => OrderingTerm.asc(log.setIndex),
          ]))
        .get();

    int? weekday;
    final planDayId = row.planDayId;
    if (planDayId != null) {
      final day = await (_db.select(_db.planDays)
            ..where((d) => d.id.equals(planDayId))
            ..limit(1))
          .getSingleOrNull();
      weekday = day?.weekday;
    }

    return WorkoutSession(
      id: row.id,
      planDayId: planDayId,
      weekday: weekday,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      rating: enumByNameOrNull(
        SessionRating.values,
        row.rating,
        column: 'sessions.rating',
      ),
      painReported: row.painReported,
      notes: row.notes,
      sets: [
        for (final log in setRows)
          LoggedSet(
            id: log.id,
            exerciseId: log.exerciseId,
            planExerciseId: log.planExerciseId,
            setIndex: log.setIndex,
            reps: log.holdSeconds == null ? log.reps : null,
            holdSeconds: log.holdSeconds,
            weightKg: log.weightKg,
            formScore: log.formScore,
            completedAt: log.completedAt,
          ),
      ],
    );
  }

  /// Readable and sortable, with a counter behind the clock.
  ///
  /// The plan repository gets away with a bare timestamp because revisions
  /// are minutes apart. Sets are not: three sets saved in a loop can land
  /// inside one clock tick, and on Windows that tick is a millisecond
  /// however many microseconds it claims to count.
  String _sequentialId() => 'log_'
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}_'
      '${(_sequence++).toRadixString(36)}';
}
