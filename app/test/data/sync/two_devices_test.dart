import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/data/sync/drift_sync_store.dart';
import 'package:spottr/data/sync/supabase_remote_store.dart';
import 'package:spottr/data/sync/sync_tables.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../support/test_database.dart';

/// Two phones and a server, all three of them real code: two separate
/// SQLite databases behind `DriftSyncStore`, the real `SyncEngine`, the real
/// `SupabaseRemoteStore` building real PostgREST requests, and a stand-in
/// server that answers them out of a map.
///
/// Every layer below has its own tests and they all pass in isolation, which
/// is exactly the condition under which an integration is still broken. A
/// boolean that leaves SQLite as 1, a timestamp that crosses as an integer,
/// a cursor read as a date — each of those passes a unit test on both sides
/// of the wire and loses somebody's training in the middle.
///
/// What this still cannot tell anybody is whether PostgREST answers the way
/// `_FakePostgrest` does. It is a reading of the documentation, not of a
/// server.
void main() {
  late _FakePostgrest server;
  late _Device alice;
  late _Device bob;

  setUp(() {
    server = _FakePostgrest();
    alice = _Device('alice-phone', server);
    bob = _Device('bob-tablet', server);
  });

  tearDown(() async {
    await alice.close();
    await bob.close();
  });

  group('one account on two phones', () {
    test('a profile made on one appears on the other', () async {
      await alice.writeProfile(goal: 'hybrid', weight: 78.5);

      final up = await alice.sync();
      final down = await bob.sync();

      expect(up.complete, isTrue);
      expect(up.pushed, 1);
      expect(down.applied, 1);

      final arrived = await bob.profile();
      expect(arrived.goal, 'hybrid');
      expect(arrived.weightKg, 78.5);
      expect(arrived.deviceId, 'alice-phone');
    });

    test('a boolean survives the journey as a boolean', () async {
      // SQLite has no boolean, PostgREST refuses 1 for one, and both halves
      // of that pass their own tests. This is the assertion that fails if
      // either side stops converting.
      await alice.writeProfile();
      await alice.writePlan(isActive: true);

      await alice.sync();
      await bob.sync();

      final plan = await bob.db.select(bob.db.plans).getSingle();
      expect(plan.isActive, isTrue);
      expect(plan.createdAt, DateTime.utc(2026, 11, 1, 8, 30));
    });

    test('a device sees its own push come back once, and then goes quiet',
        () async {
      // The ping-pong check, end to end, and the answer is "once" rather
      // than "never". Alice pushed before she had ever pulled, so her cursor
      // is unset and the server stamped her own row after it: her next pull
      // hands it back. She writes it over itself, which is a write and not a
      // change, and her cursor then sits past it for good.
      //
      // The alternative would be to advance the cursor to the sequence the
      // server assigned her batch, and that is not safe: another device's
      // row can be stamped in the middle of it, and skipping that row loses
      // it for ever. One redundant download beats that trade every time.
      await alice.writeProfile();
      await alice.sync();
      await bob.sync();

      final settling = await alice.sync();

      expect(settling.applied, 1, reason: 'her own row, coming back');
      expect(settling.pushed, 0, reason: 'nothing of hers is unsent');
      expect(settling.conflicts, 0);

      expect((await alice.sync()).idle, isTrue);
      // Bob never pushed, so he had nothing of his own to be handed back.
      expect((await bob.sync()).idle, isTrue);
    });

    test('a change made on the second phone comes back to the first',
        () async {
      await alice.writeProfile(goal: 'hybrid');
      await alice.sync();
      await bob.sync();

      await bob.editProfile(goal: 'muscleBuilding', at: 11);
      await bob.sync();
      final back = await alice.sync();

      expect(back.applied, 1);
      expect((await alice.profile()).goal, 'muscleBuilding');
      expect((await alice.profile()).deviceId, 'bob-tablet');
    });
  });

  group('the same row edited in two places', () {
    test('the later edit wins, and the loser stops trying', () async {
      await alice.writeProfile(goal: 'hybrid');
      await alice.sync();
      await bob.sync();

      // Both of them edit while offline. Bob's is later.
      await alice.editProfile(goal: 'weightLoss', at: 12);
      await bob.editProfile(goal: 'muscleBuilding', at: 13);

      await bob.sync();
      final resolved = await alice.sync();

      expect(resolved.conflicts, 1);
      expect(resolved.conflictsLostLocally, 1);
      expect((await alice.profile()).goal, 'muscleBuilding');

      // And the discarded edit is not offered again for ever.
      expect((await alice.sync()).idle, isTrue);
      expect((await bob.sync()).pushed, 0, reason: 'his own row, coming back');
      expect((await bob.sync()).idle, isTrue);
    });

    test('the earlier edit is not allowed to overwrite the later one',
        () async {
      // The same pair the other way round: Alice's local copy is newer, so
      // it survives the pull and is pushed on top of Bob's.
      await alice.writeProfile(goal: 'hybrid');
      await alice.sync();
      await bob.sync();

      await bob.editProfile(goal: 'muscleBuilding', at: 12);
      await bob.sync();
      await alice.editProfile(goal: 'weightLoss', at: 13);

      final kept = await alice.sync();
      await bob.sync();

      expect(kept.conflicts, 1);
      expect(kept.conflictsLostLocally, 0);
      expect((await alice.profile()).goal, 'weightLoss');
      expect((await bob.profile()).goal, 'weightLoss');
    });
  });

  group('a workout', () {
    test('reaches the other device with its plan and its sets', () async {
      // The whole chain in table order: a profile, a plan, its day, its
      // exercise, a session and a logged set, each pointing at the one
      // before it. On the server those are real foreign keys, so this is
      // also the test that the push order is right.
      await alice.writeProfile();
      await alice.writePlan();
      await alice.writeDay();
      await alice.writeExercise();
      await alice.writeSession();
      await alice.writeSetLog(reps: 8, weight: 60);

      final up = await alice.sync();
      final down = await bob.sync();

      expect(up.complete, isTrue);
      expect(up.pushed, 6);
      expect(down.applied, 6);

      final log = await bob.db.select(bob.db.setLogs).getSingle();
      expect(log.reps, 8);
      expect(log.weightKg, 60);
      expect(log.formScore, isNull);
      expect(log.completedAt, DateTime.utc(2026, 11, 5, 9, 45));
    });

    test('a session deleted on one phone is deleted on the other', () async {
      await alice.writeProfile();
      await alice.writeDay(withPlan: true);
      await alice.writeSession();
      await alice.sync();
      await bob.sync();

      await (alice.db.update(alice.db.sessions)
            ..where((row) => row.id.equals('se1')))
          .write(
        SessionsCompanion(
          updatedAt: Value(DateTime.utc(2026, 11, 5, 14)),
          deletedAt: Value(DateTime.utc(2026, 11, 5, 14)),
        ),
      );

      await alice.sync();
      await bob.sync();

      final stored = await bob.db.select(bob.db.sessions).getSingle();
      expect(
        stored.deletedAt,
        isNotNull,
        reason: 'a hard delete would be invisible to this device',
      );
    });
  });

  group('when the network is not there', () {
    test('the work is still local, and the next sync catches up', () async {
      await alice.writeProfile();
      server.offline = true;

      final failed = await alice.sync();

      expect(failed.complete, isFalse);
      expect(failed.error!.kind, SyncErrorKind.offline);
      expect(await alice.profile(), isNotNull, reason: 'training is local');

      server.offline = false;
      final caughtUp = await alice.sync();
      await bob.sync();

      expect(caughtUp.pushed, 1);
      expect(await bob.profile(), isNotNull);
    });

    test('a pull that drops half way resumes rather than starting again',
        () async {
      await alice.writeProfile();
      await alice.writePlan();
      await alice.writeDay();
      await alice.sync();

      server.failAfterReads = 2;
      final interrupted = await bob.sync(pageSize: 1);
      expect(interrupted.complete, isFalse);

      server.failAfterReads = null;
      final finished = await bob.sync(pageSize: 1);

      expect(finished.complete, isTrue);
      expect(await bob.db.select(bob.db.plans).get(), hasLength(1));
      expect(await bob.db.select(bob.db.planDays).get(), hasLength(1));
    });
  });
}

/// One phone: its own database, its own store, its own engine.
class _Device {
  _Device(this.id, _FakePostgrest server) : db = openTestDatabase() {
    store = DriftSyncStore(db, now: () => DateTime.utc(2026, 11, 5, 20));
    remote = SupabaseRemoteStore(
      projectUrl: Uri.parse('https://project.supabase.co'),
      anonKey: 'anon-key',
      credentials: () async => const SupabaseCredentials(
        accessToken: 'jwt',
        userId: 'user-1',
      ),
      client: server.client,
    );
  }

  final String id;
  final AppDatabase db;
  late final DriftSyncStore store;
  late final SupabaseRemoteStore remote;

  Future<SyncReport> sync({int pageSize = 100}) {
    return SyncEngine(
      local: store,
      remote: remote,
      tables: spottrSyncTables,
      pageSize: pageSize,
    ).sync();
  }

  Future<ProfileRow> profile() => db.select(db.profiles).getSingle();

  Future<void> writeProfile({String goal = 'hybrid', double? weight}) {
    return db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: 'p1',
            goal: goal,
            daysPerWeek: 3,
            sessionMinutes: 45,
            level: 'beginner',
            location: 'homeDumbbells',
            coachPersonality: 'calm',
            deviceId: id,
            weightKg: Value(weight),
            updatedAt: Value(DateTime.utc(2026, 11, 5, 10)),
          ),
        );
  }

  Future<void> editProfile({required String goal, required int at}) {
    return (db.update(db.profiles)..where((row) => row.id.equals('p1'))).write(
      ProfilesCompanion(
        goal: Value(goal),
        deviceId: Value(id),
        updatedAt: Value(DateTime.utc(2026, 11, 5, at)),
      ),
    );
  }

  Future<void> writePlan({bool isActive = true}) {
    return db.into(db.plans).insert(
          PlansCompanion.insert(
            id: 'pl1',
            profileId: 'p1',
            templateId: 'full_body_3',
            goal: 'hybrid',
            createdAt: DateTime.utc(2026, 11, 1, 8, 30),
            deviceId: id,
            isActive: Value(isActive),
            updatedAt: Value(DateTime.utc(2026, 11, 5, 10)),
          ),
        );
  }

  Future<void> writeDay({bool withPlan = false}) async {
    if (withPlan) await writePlan();
    await db.into(db.planDays).insert(
          PlanDaysCompanion.insert(
            id: 'pl1_d1',
            planId: 'pl1',
            weekday: 1,
            dayType: 'fullBody',
            labelKey: 'day_full_body',
            deviceId: id,
            updatedAt: Value(DateTime.utc(2026, 11, 5, 10)),
          ),
        );
  }

  Future<void> writeExercise() {
    return db.into(db.planExercises).insert(
          PlanExercisesCompanion.insert(
            id: 'pl1_d1_0',
            planDayId: 'pl1_d1',
            orderIndex: 0,
            exerciseId: 'back_squat',
            slotPattern: 'squat',
            priority: 'primary',
            targetSets: 3,
            templateSets: 3,
            metric: 'reps',
            restSeconds: 120,
            secondsPerRep: 3.5,
            deviceId: id,
            updatedAt: Value(DateTime.utc(2026, 11, 5, 10)),
          ),
        );
  }

  Future<void> writeSession() {
    return db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: 'se1',
            planDayId: const Value('pl1_d1'),
            startedAt: DateTime.utc(2026, 11, 5, 9, 30),
            deviceId: id,
            updatedAt: Value(DateTime.utc(2026, 11, 5, 10)),
          ),
        );
  }

  Future<void> writeSetLog({required int reps, required double weight}) {
    return db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            id: 'sl1',
            sessionId: 'se1',
            planExerciseId: const Value('pl1_d1_0'),
            exerciseId: 'back_squat',
            setIndex: 0,
            reps: reps,
            weightKg: Value(weight),
            completedAt: DateTime.utc(2026, 11, 5, 9, 45),
            deviceId: id,
            updatedAt: Value(DateTime.utc(2026, 11, 5, 10)),
          ),
        );
  }

  Future<void> close() => db.close();
}

/// Enough of PostgREST to answer the requests this app makes, and nothing
/// more: a select filtered by `synced_seq=gt.N` in `synced_seq.asc` order
/// with a limit, and an upsert resolving on (user_id, id).
///
/// Written from the documentation rather than from a server, which is the
/// honest limit of this whole file.
class _FakePostgrest {
  final Map<String, Map<String, Map<String, Object?>>> _tables = {};
  int _sequence = 0;

  /// Every request fails as though there were no network.
  bool offline = false;

  /// Fail once after this many reads, for testing a pull that drops.
  int? failAfterReads;
  int _reads = 0;

  late final http.Client client = MockClient((request) async {
    if (offline) throw http.ClientException('Connection closed');

    final table = request.url.pathSegments.last;
    if (request.method == 'GET') return _select(table, request);
    if (request.method == 'POST') return _upsert(table, request);
    return http.Response('unsupported ${request.method}', 405);
  });

  http.Response _select(String table, http.Request request) {
    _reads++;
    if (failAfterReads != null && _reads > failAfterReads!) {
      failAfterReads = null;
      throw http.ClientException('Connection closed');
    }

    final after = switch (request.url.queryParameters['synced_seq']) {
      final String filter => int.parse(filter.substring('gt.'.length)),
      _ => 0,
    };
    final limit = int.parse(request.url.queryParameters['limit']!);

    final rows = _rows(table).values
        .where((row) => (row['synced_seq']! as int) > after)
        .toList()
      ..sort(
        (a, b) => (a['synced_seq']! as int).compareTo(b['synced_seq']! as int),
      );

    return _json(rows.take(limit).toList());
  }

  http.Response _upsert(String table, http.Request request) {
    final incoming = jsonDecode(request.body) as List<Object?>;
    for (final row in incoming) {
      final record = {...row! as Map<String, Object?>};
      record['synced_seq'] = ++_sequence;
      // Keyed by the account and the row together, the way the schema is.
      _rows(table)['${record['user_id']}/${record['id']}'] = record;
    }
    return http.Response('', 201);
  }

  Map<String, Map<String, Object?>> _rows(String table) =>
      _tables.putIfAbsent(table, () => {});

  http.Response _json(Object? body) => http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
}
