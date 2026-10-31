import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:plan_engine/plan_engine.dart';

import '../domain/user_profile.dart';
import 'local/codecs.dart';
import 'local/database.dart';
import 'profile_repository.dart';

/// Stores generated and edited week plans.
///
/// Plans are immutable revisions: saving writes a new one and deactivates
/// the previous, rather than rewriting rows in place. That costs a few dozen
/// rows per edit and buys two things worth more than the space — a session
/// log always points at the exact prescription it was performed against, and
/// the history of what the user was asked to do stays intact.
class PlanRepository {
  PlanRepository(
    this._db, {
    this.deviceId = ProfileRepository.defaultDeviceId,
    String Function()? newRevisionId,
    DateTime Function()? now,
  })  : _newRevisionId = newRevisionId ?? _timeOrderedId,
        _now = now ?? DateTime.now;

  final AppDatabase _db;
  final String deviceId;
  final String Function() _newRevisionId;
  final DateTime Function() _now;

  /// The active plan, and every revision that replaces it.
  ///
  /// Emits null while there is none. Because an edit inserts a new plan row,
  /// this re-emits on every edit without having to watch the day and
  /// exercise tables as well.
  Stream<WeekPlan?> watchActive({String profileId = UserProfile.localId}) =>
      _activeQuery(profileId)
          .watchSingleOrNull()
          .asyncMap((row) => row == null ? Future.value() : _hydrate(row));

  Future<WeekPlan?> loadActive({String profileId = UserProfile.localId}) async {
    final row = await _activeQuery(profileId).getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  /// Writes [plan] as the new active revision and returns its id.
  Future<String> saveRevision(
    WeekPlan plan, {
    String profileId = UserProfile.localId,
  }) =>
      _db.transaction(() async {
        final timestamp = _now();
        final planId = _newRevisionId();

        await (_db.update(_db.plans)
              ..where(
                (row) =>
                    row.profileId.equals(profileId) & row.isActive.equals(true),
              ))
            .write(
          PlansCompanion(
            isActive: const Value(false),
            updatedAt: Value(timestamp),
            deviceId: Value(deviceId),
          ),
        );

        await _db.into(_db.plans).insert(
              PlansCompanion.insert(
                id: planId,
                profileId: profileId,
                templateId: plan.templateId,
                goal: plan.goal.name,
                createdAt: timestamp,
                deviceId: deviceId,
                isActive: const Value(true),
                runDays: Value(encodeIntSet(plan.runWeekdays)),
                runSuggestionKeys:
                    Value(encodeStringList(plan.runSuggestionKeys)),
                notes: Value(_encodeNotes(plan.notes)),
                updatedAt: Value(timestamp),
              ),
            );

        for (final day in plan.days) {
          // Ids are derived from the revision rather than random, so a row
          // in the database says which plan and which day it belongs to.
          final dayId = '${planId}_d${day.weekday}';
          await _db.into(_db.planDays).insert(
                PlanDaysCompanion.insert(
                  id: dayId,
                  planId: planId,
                  weekday: day.weekday,
                  dayType: day.type.name,
                  labelKey: day.labelKey,
                  deviceId: deviceId,
                  precedesRunDay: Value(day.precedesRunDay),
                  updatedAt: Value(timestamp),
                ),
              );

          for (var index = 0; index < day.exercises.length; index++) {
            final exercise = day.exercises[index];
            await _db.into(_db.planExercises).insert(
                  PlanExercisesCompanion.insert(
                    id: '${dayId}_$index',
                    planDayId: dayId,
                    orderIndex: index,
                    exerciseId: exercise.exerciseId,
                    slotPattern: exercise.slotPattern.name,
                    priority: exercise.priority.name,
                    targetSets: exercise.sets,
                    templateSets: exercise.templateSets,
                    metric: exercise.metric.name,
                    restSeconds: exercise.restSeconds,
                    secondsPerRep: exercise.secondsPerRep,
                    deviceId: deviceId,
                    targetRepsMin: Value(exercise.repsMin),
                    targetRepsMax: Value(exercise.repsMax),
                    targetHoldSeconds: Value(exercise.holdSeconds),
                    updatedAt: Value(timestamp),
                  ),
                );
          }
        }

        return planId;
      });

  SingleOrNullSelectable<PlanRow> _activeQuery(String profileId) =>
      _db.select(_db.plans)
        ..where(
          (row) =>
              row.profileId.equals(profileId) &
              row.isActive.equals(true) &
              row.deletedAt.isNull(),
        )
        ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
        ..limit(1);

  Future<WeekPlan> _hydrate(PlanRow plan) async {
    final dayRows = await (_db.select(_db.planDays)
          ..where((row) => row.planId.equals(plan.id) & row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.asc(row.weekday)]))
        .get();

    final days = <PlannedDay>[];
    for (final dayRow in dayRows) {
      final exerciseRows = await (_db.select(_db.planExercises)
            ..where(
              (row) =>
                  row.planDayId.equals(dayRow.id) & row.deletedAt.isNull(),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)]))
          .get();

      days.add(
        PlannedDay(
          weekday: dayRow.weekday,
          type: enumByName(
            DayType.values,
            dayRow.dayType,
            column: 'plan_days.day_type',
          ),
          labelKey: dayRow.labelKey,
          precedesRunDay: dayRow.precedesRunDay,
          exercises: [
            for (final row in exerciseRows)
              PlannedExercise(
                exerciseId: row.exerciseId,
                slotPattern: enumByName(
                  MovementPattern.values,
                  row.slotPattern,
                  column: 'plan_exercises.slot_pattern',
                ),
                priority: enumByName(
                  SlotPriority.values,
                  row.priority,
                  column: 'plan_exercises.priority',
                ),
                sets: row.targetSets,
                templateSets: row.templateSets,
                metric: enumByName(
                  MetricType.values,
                  row.metric,
                  column: 'plan_exercises.metric',
                ),
                restSeconds: row.restSeconds,
                secondsPerRep: row.secondsPerRep,
                repsMin: row.targetRepsMin,
                repsMax: row.targetRepsMax,
                holdSeconds: row.targetHoldSeconds,
              ),
          ],
        ),
      );
    }

    return WeekPlan(
      templateId: plan.templateId,
      goal: enumByName(Goal.values, plan.goal, column: 'plans.goal'),
      days: days,
      runWeekdays: decodeIntSet(plan.runDays, column: 'plans.run_days'),
      runSuggestionKeys: decodeStringList(
        plan.runSuggestionKeys,
        column: 'plans.run_suggestion_keys',
      ),
      notes: _decodeNotes(plan.notes),
    );
  }

  static String _encodeNotes(List<PlanNote> notes) => jsonEncode([
        for (final note in notes)
          <String, Object?>{
            'kind': note.kind.name,
            'detail': note.detail,
            if (note.weekday != null) 'weekday': note.weekday,
          },
      ]);

  static List<PlanNote> _decodeNotes(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const FormatException('Column plans.notes is not a JSON array');
    }
    return [
      for (final element in decoded)
        if (element is Map<String, Object?>)
          PlanNote(
            enumByName(
              PlanNoteKind.values,
              element['kind']! as String,
              column: 'plans.notes.kind',
            ),
            element['detail']! as String,
            weekday: element['weekday'] as int?,
          )
        else
          throw const FormatException('Column plans.notes holds a non-object'),
    ];
  }

  /// A readable, sortable id with enough entropy for one device.
  ///
  /// Revisions are only ever created by the user tapping something, so
  /// microsecond resolution is more than enough to keep them distinct.
  static String _timeOrderedId() =>
      'plan_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}
