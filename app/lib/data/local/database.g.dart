// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pushedAt = GeneratedColumn<DateTime>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysPerWeekMeta = const VerificationMeta(
    'daysPerWeek',
  );
  @override
  late final GeneratedColumn<int> daysPerWeek = GeneratedColumn<int>(
    'days_per_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionMinutesMeta = const VerificationMeta(
    'sessionMinutes',
  );
  @override
  late final GeneratedColumn<int> sessionMinutes = GeneratedColumn<int>(
    'session_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageYearsMeta = const VerificationMeta(
    'ageYears',
  );
  @override
  late final GeneratedColumn<int> ageYears = GeneratedColumn<int>(
    'age_years',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _injuriesMeta = const VerificationMeta(
    'injuries',
  );
  @override
  late final GeneratedColumn<String> injuries = GeneratedColumn<String>(
    'injuries',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _injuryNotesMeta = const VerificationMeta(
    'injuryNotes',
  );
  @override
  late final GeneratedColumn<String> injuryNotes = GeneratedColumn<String>(
    'injury_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _coachPersonalityMeta = const VerificationMeta(
    'coachPersonality',
  );
  @override
  late final GeneratedColumn<String> coachPersonality = GeneratedColumn<String>(
    'coach_personality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runDaysMeta = const VerificationMeta(
    'runDays',
  );
  @override
  late final GeneratedColumn<String> runDays = GeneratedColumn<String>(
    'run_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _disclaimerAcceptedAtMeta =
      const VerificationMeta('disclaimerAcceptedAt');
  @override
  late final GeneratedColumn<DateTime> disclaimerAcceptedAt =
      GeneratedColumn<DateTime>(
        'disclaimer_accepted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    goal,
    daysPerWeek,
    sessionMinutes,
    level,
    ageYears,
    heightCm,
    weightKg,
    sex,
    injuries,
    injuryNotes,
    location,
    equipment,
    coachPersonality,
    runDays,
    disclaimerAcceptedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMeta);
    }
    if (data.containsKey('days_per_week')) {
      context.handle(
        _daysPerWeekMeta,
        daysPerWeek.isAcceptableOrUnknown(
          data['days_per_week']!,
          _daysPerWeekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_daysPerWeekMeta);
    }
    if (data.containsKey('session_minutes')) {
      context.handle(
        _sessionMinutesMeta,
        sessionMinutes.isAcceptableOrUnknown(
          data['session_minutes']!,
          _sessionMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionMinutesMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('age_years')) {
      context.handle(
        _ageYearsMeta,
        ageYears.isAcceptableOrUnknown(data['age_years']!, _ageYearsMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('injuries')) {
      context.handle(
        _injuriesMeta,
        injuries.isAcceptableOrUnknown(data['injuries']!, _injuriesMeta),
      );
    }
    if (data.containsKey('injury_notes')) {
      context.handle(
        _injuryNotesMeta,
        injuryNotes.isAcceptableOrUnknown(
          data['injury_notes']!,
          _injuryNotesMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('coach_personality')) {
      context.handle(
        _coachPersonalityMeta,
        coachPersonality.isAcceptableOrUnknown(
          data['coach_personality']!,
          _coachPersonalityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coachPersonalityMeta);
    }
    if (data.containsKey('run_days')) {
      context.handle(
        _runDaysMeta,
        runDays.isAcceptableOrUnknown(data['run_days']!, _runDaysMeta),
      );
    }
    if (data.containsKey('disclaimer_accepted_at')) {
      context.handle(
        _disclaimerAcceptedAtMeta,
        disclaimerAcceptedAt.isAcceptableOrUnknown(
          data['disclaimer_accepted_at']!,
          _disclaimerAcceptedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pushed_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      daysPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_per_week'],
      )!,
      sessionMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_minutes'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      ageYears: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age_years'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      injuries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}injuries'],
      )!,
      injuryNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}injury_notes'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      coachPersonality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coach_personality'],
      )!,
      runDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_days'],
      )!,
      disclaimerAcceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}disclaimer_accepted_at'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final DateTime updatedAt;

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  final DateTime? deletedAt;

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  final String deviceId;

  /// The [updatedAt] the server last acknowledged, or null for never.
  ///
  /// The one sync column that is **not** replicated: it is this install's
  /// record of what has been uploaded, and it is what makes the dirty set
  /// exact. A row is pending while `pushed_at IS NULL OR pushed_at <
  /// updated_at`, so the only thing a local write has to remember is to bump
  /// `updated_at` — which it already must do for the conflict rule, rather
  /// than being a second piece of bookkeeping to forget.
  ///
  /// The alternative, comparing `updated_at` against a single watermark,
  /// silently drops an edit made by a device whose clock is behind. Added in
  /// v2: the three columns v1 chose were the right ones for resolving a
  /// conflict and not enough for noticing there was something to resolve.
  final DateTime? pushedAt;
  final String id;
  final String goal;
  final int daysPerWeek;
  final int sessionMinutes;
  final String level;
  final int? ageYears;
  final double? heightCm;
  final double? weightKg;
  final String? sex;

  /// JSON array of body parts, e.g. ["knees","lowerBack"].
  final String injuries;
  final String? injuryNotes;
  final String location;

  /// JSON array of available equipment beyond what [location] implies.
  final String equipment;
  final String coachPersonality;

  /// JSON array of ISO weekday numbers the user runs on.
  ///
  /// Kept whatever the goal is, so that a user who switches to hybrid and
  /// back does not have to enter them twice. Only a hybrid goal actually
  /// feeds them to the generator.
  final String runDays;

  /// When the safety disclaimer was accepted, or null if it has not been.
  ///
  /// A timestamp rather than a flag: this gates the whole app, and "when did
  /// they agree, and to which wording" is the question you want answerable.
  final DateTime? disclaimerAcceptedAt;
  const ProfileRow({
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.pushedAt,
    required this.id,
    required this.goal,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.level,
    this.ageYears,
    this.heightCm,
    this.weightKg,
    this.sex,
    required this.injuries,
    this.injuryNotes,
    required this.location,
    required this.equipment,
    required this.coachPersonality,
    required this.runDays,
    this.disclaimerAcceptedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<DateTime>(pushedAt);
    }
    map['id'] = Variable<String>(id);
    map['goal'] = Variable<String>(goal);
    map['days_per_week'] = Variable<int>(daysPerWeek);
    map['session_minutes'] = Variable<int>(sessionMinutes);
    map['level'] = Variable<String>(level);
    if (!nullToAbsent || ageYears != null) {
      map['age_years'] = Variable<int>(ageYears);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    map['injuries'] = Variable<String>(injuries);
    if (!nullToAbsent || injuryNotes != null) {
      map['injury_notes'] = Variable<String>(injuryNotes);
    }
    map['location'] = Variable<String>(location);
    map['equipment'] = Variable<String>(equipment);
    map['coach_personality'] = Variable<String>(coachPersonality);
    map['run_days'] = Variable<String>(runDays);
    if (!nullToAbsent || disclaimerAcceptedAt != null) {
      map['disclaimer_accepted_at'] = Variable<DateTime>(disclaimerAcceptedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
      id: Value(id),
      goal: Value(goal),
      daysPerWeek: Value(daysPerWeek),
      sessionMinutes: Value(sessionMinutes),
      level: Value(level),
      ageYears: ageYears == null && nullToAbsent
          ? const Value.absent()
          : Value(ageYears),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      injuries: Value(injuries),
      injuryNotes: injuryNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(injuryNotes),
      location: Value(location),
      equipment: Value(equipment),
      coachPersonality: Value(coachPersonality),
      runDays: Value(runDays),
      disclaimerAcceptedAt: disclaimerAcceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disclaimerAcceptedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      pushedAt: serializer.fromJson<DateTime?>(json['pushedAt']),
      id: serializer.fromJson<String>(json['id']),
      goal: serializer.fromJson<String>(json['goal']),
      daysPerWeek: serializer.fromJson<int>(json['daysPerWeek']),
      sessionMinutes: serializer.fromJson<int>(json['sessionMinutes']),
      level: serializer.fromJson<String>(json['level']),
      ageYears: serializer.fromJson<int?>(json['ageYears']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      sex: serializer.fromJson<String?>(json['sex']),
      injuries: serializer.fromJson<String>(json['injuries']),
      injuryNotes: serializer.fromJson<String?>(json['injuryNotes']),
      location: serializer.fromJson<String>(json['location']),
      equipment: serializer.fromJson<String>(json['equipment']),
      coachPersonality: serializer.fromJson<String>(json['coachPersonality']),
      runDays: serializer.fromJson<String>(json['runDays']),
      disclaimerAcceptedAt: serializer.fromJson<DateTime?>(
        json['disclaimerAcceptedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'pushedAt': serializer.toJson<DateTime?>(pushedAt),
      'id': serializer.toJson<String>(id),
      'goal': serializer.toJson<String>(goal),
      'daysPerWeek': serializer.toJson<int>(daysPerWeek),
      'sessionMinutes': serializer.toJson<int>(sessionMinutes),
      'level': serializer.toJson<String>(level),
      'ageYears': serializer.toJson<int?>(ageYears),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'sex': serializer.toJson<String?>(sex),
      'injuries': serializer.toJson<String>(injuries),
      'injuryNotes': serializer.toJson<String?>(injuryNotes),
      'location': serializer.toJson<String>(location),
      'equipment': serializer.toJson<String>(equipment),
      'coachPersonality': serializer.toJson<String>(coachPersonality),
      'runDays': serializer.toJson<String>(runDays),
      'disclaimerAcceptedAt': serializer.toJson<DateTime?>(
        disclaimerAcceptedAt,
      ),
    };
  }

  ProfileRow copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<DateTime?> pushedAt = const Value.absent(),
    String? id,
    String? goal,
    int? daysPerWeek,
    int? sessionMinutes,
    String? level,
    Value<int?> ageYears = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    String? injuries,
    Value<String?> injuryNotes = const Value.absent(),
    String? location,
    String? equipment,
    String? coachPersonality,
    String? runDays,
    Value<DateTime?> disclaimerAcceptedAt = const Value.absent(),
  }) => ProfileRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
    id: id ?? this.id,
    goal: goal ?? this.goal,
    daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    sessionMinutes: sessionMinutes ?? this.sessionMinutes,
    level: level ?? this.level,
    ageYears: ageYears.present ? ageYears.value : this.ageYears,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    sex: sex.present ? sex.value : this.sex,
    injuries: injuries ?? this.injuries,
    injuryNotes: injuryNotes.present ? injuryNotes.value : this.injuryNotes,
    location: location ?? this.location,
    equipment: equipment ?? this.equipment,
    coachPersonality: coachPersonality ?? this.coachPersonality,
    runDays: runDays ?? this.runDays,
    disclaimerAcceptedAt: disclaimerAcceptedAt.present
        ? disclaimerAcceptedAt.value
        : this.disclaimerAcceptedAt,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
      id: data.id.present ? data.id.value : this.id,
      goal: data.goal.present ? data.goal.value : this.goal,
      daysPerWeek: data.daysPerWeek.present
          ? data.daysPerWeek.value
          : this.daysPerWeek,
      sessionMinutes: data.sessionMinutes.present
          ? data.sessionMinutes.value
          : this.sessionMinutes,
      level: data.level.present ? data.level.value : this.level,
      ageYears: data.ageYears.present ? data.ageYears.value : this.ageYears,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      sex: data.sex.present ? data.sex.value : this.sex,
      injuries: data.injuries.present ? data.injuries.value : this.injuries,
      injuryNotes: data.injuryNotes.present
          ? data.injuryNotes.value
          : this.injuryNotes,
      location: data.location.present ? data.location.value : this.location,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      coachPersonality: data.coachPersonality.present
          ? data.coachPersonality.value
          : this.coachPersonality,
      runDays: data.runDays.present ? data.runDays.value : this.runDays,
      disclaimerAcceptedAt: data.disclaimerAcceptedAt.present
          ? data.disclaimerAcceptedAt.value
          : this.disclaimerAcceptedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('goal: $goal, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('sessionMinutes: $sessionMinutes, ')
          ..write('level: $level, ')
          ..write('ageYears: $ageYears, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('sex: $sex, ')
          ..write('injuries: $injuries, ')
          ..write('injuryNotes: $injuryNotes, ')
          ..write('location: $location, ')
          ..write('equipment: $equipment, ')
          ..write('coachPersonality: $coachPersonality, ')
          ..write('runDays: $runDays, ')
          ..write('disclaimerAcceptedAt: $disclaimerAcceptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    goal,
    daysPerWeek,
    sessionMinutes,
    level,
    ageYears,
    heightCm,
    weightKg,
    sex,
    injuries,
    injuryNotes,
    location,
    equipment,
    coachPersonality,
    runDays,
    disclaimerAcceptedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.pushedAt == this.pushedAt &&
          other.id == this.id &&
          other.goal == this.goal &&
          other.daysPerWeek == this.daysPerWeek &&
          other.sessionMinutes == this.sessionMinutes &&
          other.level == this.level &&
          other.ageYears == this.ageYears &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.sex == this.sex &&
          other.injuries == this.injuries &&
          other.injuryNotes == this.injuryNotes &&
          other.location == this.location &&
          other.equipment == this.equipment &&
          other.coachPersonality == this.coachPersonality &&
          other.runDays == this.runDays &&
          other.disclaimerAcceptedAt == this.disclaimerAcceptedAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<DateTime?> pushedAt;
  final Value<String> id;
  final Value<String> goal;
  final Value<int> daysPerWeek;
  final Value<int> sessionMinutes;
  final Value<String> level;
  final Value<int?> ageYears;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<String?> sex;
  final Value<String> injuries;
  final Value<String?> injuryNotes;
  final Value<String> location;
  final Value<String> equipment;
  final Value<String> coachPersonality;
  final Value<String> runDays;
  final Value<DateTime?> disclaimerAcceptedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pushedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.goal = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.sessionMinutes = const Value.absent(),
    this.level = const Value.absent(),
    this.ageYears = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.sex = const Value.absent(),
    this.injuries = const Value.absent(),
    this.injuryNotes = const Value.absent(),
    this.location = const Value.absent(),
    this.equipment = const Value.absent(),
    this.coachPersonality = const Value.absent(),
    this.runDays = const Value.absent(),
    this.disclaimerAcceptedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.pushedAt = const Value.absent(),
    required String id,
    required String goal,
    required int daysPerWeek,
    required int sessionMinutes,
    required String level,
    this.ageYears = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.sex = const Value.absent(),
    this.injuries = const Value.absent(),
    this.injuryNotes = const Value.absent(),
    required String location,
    this.equipment = const Value.absent(),
    required String coachPersonality,
    this.runDays = const Value.absent(),
    this.disclaimerAcceptedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       id = Value(id),
       goal = Value(goal),
       daysPerWeek = Value(daysPerWeek),
       sessionMinutes = Value(sessionMinutes),
       level = Value(level),
       location = Value(location),
       coachPersonality = Value(coachPersonality);
  static Insertable<ProfileRow> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? pushedAt,
    Expression<String>? id,
    Expression<String>? goal,
    Expression<int>? daysPerWeek,
    Expression<int>? sessionMinutes,
    Expression<String>? level,
    Expression<int>? ageYears,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? sex,
    Expression<String>? injuries,
    Expression<String>? injuryNotes,
    Expression<String>? location,
    Expression<String>? equipment,
    Expression<String>? coachPersonality,
    Expression<String>? runDays,
    Expression<DateTime>? disclaimerAcceptedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (pushedAt != null) 'pushed_at': pushedAt,
      if (id != null) 'id': id,
      if (goal != null) 'goal': goal,
      if (daysPerWeek != null) 'days_per_week': daysPerWeek,
      if (sessionMinutes != null) 'session_minutes': sessionMinutes,
      if (level != null) 'level': level,
      if (ageYears != null) 'age_years': ageYears,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (sex != null) 'sex': sex,
      if (injuries != null) 'injuries': injuries,
      if (injuryNotes != null) 'injury_notes': injuryNotes,
      if (location != null) 'location': location,
      if (equipment != null) 'equipment': equipment,
      if (coachPersonality != null) 'coach_personality': coachPersonality,
      if (runDays != null) 'run_days': runDays,
      if (disclaimerAcceptedAt != null)
        'disclaimer_accepted_at': disclaimerAcceptedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<DateTime?>? pushedAt,
    Value<String>? id,
    Value<String>? goal,
    Value<int>? daysPerWeek,
    Value<int>? sessionMinutes,
    Value<String>? level,
    Value<int?>? ageYears,
    Value<double?>? heightCm,
    Value<double?>? weightKg,
    Value<String?>? sex,
    Value<String>? injuries,
    Value<String?>? injuryNotes,
    Value<String>? location,
    Value<String>? equipment,
    Value<String>? coachPersonality,
    Value<String>? runDays,
    Value<DateTime?>? disclaimerAcceptedAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      pushedAt: pushedAt ?? this.pushedAt,
      id: id ?? this.id,
      goal: goal ?? this.goal,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      level: level ?? this.level,
      ageYears: ageYears ?? this.ageYears,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      sex: sex ?? this.sex,
      injuries: injuries ?? this.injuries,
      injuryNotes: injuryNotes ?? this.injuryNotes,
      location: location ?? this.location,
      equipment: equipment ?? this.equipment,
      coachPersonality: coachPersonality ?? this.coachPersonality,
      runDays: runDays ?? this.runDays,
      disclaimerAcceptedAt: disclaimerAcceptedAt ?? this.disclaimerAcceptedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<DateTime>(pushedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (daysPerWeek.present) {
      map['days_per_week'] = Variable<int>(daysPerWeek.value);
    }
    if (sessionMinutes.present) {
      map['session_minutes'] = Variable<int>(sessionMinutes.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (ageYears.present) {
      map['age_years'] = Variable<int>(ageYears.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (injuries.present) {
      map['injuries'] = Variable<String>(injuries.value);
    }
    if (injuryNotes.present) {
      map['injury_notes'] = Variable<String>(injuryNotes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (coachPersonality.present) {
      map['coach_personality'] = Variable<String>(coachPersonality.value);
    }
    if (runDays.present) {
      map['run_days'] = Variable<String>(runDays.value);
    }
    if (disclaimerAcceptedAt.present) {
      map['disclaimer_accepted_at'] = Variable<DateTime>(
        disclaimerAcceptedAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('goal: $goal, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('sessionMinutes: $sessionMinutes, ')
          ..write('level: $level, ')
          ..write('ageYears: $ageYears, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('sex: $sex, ')
          ..write('injuries: $injuries, ')
          ..write('injuryNotes: $injuryNotes, ')
          ..write('location: $location, ')
          ..write('equipment: $equipment, ')
          ..write('coachPersonality: $coachPersonality, ')
          ..write('runDays: $runDays, ')
          ..write('disclaimerAcceptedAt: $disclaimerAcceptedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, PlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pushedAt = GeneratedColumn<DateTime>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _runDaysMeta = const VerificationMeta(
    'runDays',
  );
  @override
  late final GeneratedColumn<String> runDays = GeneratedColumn<String>(
    'run_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _runSuggestionKeysMeta = const VerificationMeta(
    'runSuggestionKeys',
  );
  @override
  late final GeneratedColumn<String> runSuggestionKeys =
      GeneratedColumn<String>(
        'run_suggestion_keys',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    profileId,
    templateId,
    goal,
    createdAt,
    isActive,
    runDays,
    runSuggestionKeys,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('run_days')) {
      context.handle(
        _runDaysMeta,
        runDays.isAcceptableOrUnknown(data['run_days']!, _runDaysMeta),
      );
    }
    if (data.containsKey('run_suggestion_keys')) {
      context.handle(
        _runSuggestionKeysMeta,
        runSuggestionKeys.isAcceptableOrUnknown(
          data['run_suggestion_keys']!,
          _runSuggestionKeysMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pushed_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      runDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_days'],
      )!,
      runSuggestionKeys: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_suggestion_keys'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final DateTime updatedAt;

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  final DateTime? deletedAt;

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  final String deviceId;

  /// The [updatedAt] the server last acknowledged, or null for never.
  ///
  /// The one sync column that is **not** replicated: it is this install's
  /// record of what has been uploaded, and it is what makes the dirty set
  /// exact. A row is pending while `pushed_at IS NULL OR pushed_at <
  /// updated_at`, so the only thing a local write has to remember is to bump
  /// `updated_at` — which it already must do for the conflict rule, rather
  /// than being a second piece of bookkeeping to forget.
  ///
  /// The alternative, comparing `updated_at` against a single watermark,
  /// silently drops an edit made by a device whose clock is behind. Added in
  /// v2: the three columns v1 chose were the right ones for resolving a
  /// conflict and not enough for noticing there was something to resolve.
  final DateTime? pushedAt;
  final String id;
  final String profileId;
  final String templateId;
  final String goal;
  final DateTime createdAt;

  /// Exactly one revision per profile is active at a time.
  final bool isActive;

  /// JSON array of ISO weekdays the plan was scheduled around.
  final String runDays;

  /// JSON array of ARB keys for the text running suggestions.
  final String runSuggestionKeys;

  /// JSON array of `{kind, detail, weekday}` objects: why the plan does not
  /// look like the plain template. Stored because the UI explains a short or
  /// simplified plan from them, and an edit rewrites them.
  final String notes;
  const PlanRow({
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.pushedAt,
    required this.id,
    required this.profileId,
    required this.templateId,
    required this.goal,
    required this.createdAt,
    required this.isActive,
    required this.runDays,
    required this.runSuggestionKeys,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<DateTime>(pushedAt);
    }
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['template_id'] = Variable<String>(templateId);
    map['goal'] = Variable<String>(goal);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    map['run_days'] = Variable<String>(runDays);
    map['run_suggestion_keys'] = Variable<String>(runSuggestionKeys);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
      id: Value(id),
      profileId: Value(profileId),
      templateId: Value(templateId),
      goal: Value(goal),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
      runDays: Value(runDays),
      runSuggestionKeys: Value(runSuggestionKeys),
      notes: Value(notes),
    );
  }

  factory PlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      pushedAt: serializer.fromJson<DateTime?>(json['pushedAt']),
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      templateId: serializer.fromJson<String>(json['templateId']),
      goal: serializer.fromJson<String>(json['goal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      runDays: serializer.fromJson<String>(json['runDays']),
      runSuggestionKeys: serializer.fromJson<String>(json['runSuggestionKeys']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'pushedAt': serializer.toJson<DateTime?>(pushedAt),
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'templateId': serializer.toJson<String>(templateId),
      'goal': serializer.toJson<String>(goal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
      'runDays': serializer.toJson<String>(runDays),
      'runSuggestionKeys': serializer.toJson<String>(runSuggestionKeys),
      'notes': serializer.toJson<String>(notes),
    };
  }

  PlanRow copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<DateTime?> pushedAt = const Value.absent(),
    String? id,
    String? profileId,
    String? templateId,
    String? goal,
    DateTime? createdAt,
    bool? isActive,
    String? runDays,
    String? runSuggestionKeys,
    String? notes,
  }) => PlanRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    templateId: templateId ?? this.templateId,
    goal: goal ?? this.goal,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
    runDays: runDays ?? this.runDays,
    runSuggestionKeys: runSuggestionKeys ?? this.runSuggestionKeys,
    notes: notes ?? this.notes,
  );
  PlanRow copyWithCompanion(PlansCompanion data) {
    return PlanRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      goal: data.goal.present ? data.goal.value : this.goal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      runDays: data.runDays.present ? data.runDays.value : this.runDays,
      runSuggestionKeys: data.runSuggestionKeys.present
          ? data.runSuggestionKeys.value
          : this.runSuggestionKeys,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('templateId: $templateId, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('runDays: $runDays, ')
          ..write('runSuggestionKeys: $runSuggestionKeys, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    profileId,
    templateId,
    goal,
    createdAt,
    isActive,
    runDays,
    runSuggestionKeys,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.pushedAt == this.pushedAt &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.templateId == this.templateId &&
          other.goal == this.goal &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive &&
          other.runDays == this.runDays &&
          other.runSuggestionKeys == this.runSuggestionKeys &&
          other.notes == this.notes);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<DateTime?> pushedAt;
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> templateId;
  final Value<String> goal;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  final Value<String> runDays;
  final Value<String> runSuggestionKeys;
  final Value<String> notes;
  final Value<int> rowid;
  const PlansCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pushedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.goal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.runDays = const Value.absent(),
    this.runSuggestionKeys = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.pushedAt = const Value.absent(),
    required String id,
    required String profileId,
    required String templateId,
    required String goal,
    required DateTime createdAt,
    this.isActive = const Value.absent(),
    this.runDays = const Value.absent(),
    this.runSuggestionKeys = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       id = Value(id),
       profileId = Value(profileId),
       templateId = Value(templateId),
       goal = Value(goal),
       createdAt = Value(createdAt);
  static Insertable<PlanRow> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? pushedAt,
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? templateId,
    Expression<String>? goal,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
    Expression<String>? runDays,
    Expression<String>? runSuggestionKeys,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (pushedAt != null) 'pushed_at': pushedAt,
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (templateId != null) 'template_id': templateId,
      if (goal != null) 'goal': goal,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (runDays != null) 'run_days': runDays,
      if (runSuggestionKeys != null) 'run_suggestion_keys': runSuggestionKeys,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<DateTime?>? pushedAt,
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? templateId,
    Value<String>? goal,
    Value<DateTime>? createdAt,
    Value<bool>? isActive,
    Value<String>? runDays,
    Value<String>? runSuggestionKeys,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      pushedAt: pushedAt ?? this.pushedAt,
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      templateId: templateId ?? this.templateId,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      runDays: runDays ?? this.runDays,
      runSuggestionKeys: runSuggestionKeys ?? this.runSuggestionKeys,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<DateTime>(pushedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (runDays.present) {
      map['run_days'] = Variable<String>(runDays.value);
    }
    if (runSuggestionKeys.present) {
      map['run_suggestion_keys'] = Variable<String>(runSuggestionKeys.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('templateId: $templateId, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('runDays: $runDays, ')
          ..write('runSuggestionKeys: $runSuggestionKeys, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanDaysTable extends PlanDays
    with TableInfo<$PlanDaysTable, PlanDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pushedAt = GeneratedColumn<DateTime>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayTypeMeta = const VerificationMeta(
    'dayType',
  );
  @override
  late final GeneratedColumn<String> dayType = GeneratedColumn<String>(
    'day_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelKeyMeta = const VerificationMeta(
    'labelKey',
  );
  @override
  late final GeneratedColumn<String> labelKey = GeneratedColumn<String>(
    'label_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precedesRunDayMeta = const VerificationMeta(
    'precedesRunDay',
  );
  @override
  late final GeneratedColumn<bool> precedesRunDay = GeneratedColumn<bool>(
    'precedes_run_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("precedes_run_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    planId,
    weekday,
    dayType,
    labelKey,
    precedesRunDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('day_type')) {
      context.handle(
        _dayTypeMeta,
        dayType.isAcceptableOrUnknown(data['day_type']!, _dayTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_dayTypeMeta);
    }
    if (data.containsKey('label_key')) {
      context.handle(
        _labelKeyMeta,
        labelKey.isAcceptableOrUnknown(data['label_key']!, _labelKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_labelKeyMeta);
    }
    if (data.containsKey('precedes_run_day')) {
      context.handle(
        _precedesRunDayMeta,
        precedesRunDay.isAcceptableOrUnknown(
          data['precedes_run_day']!,
          _precedesRunDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanDayRow(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pushed_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      dayType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_type'],
      )!,
      labelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_key'],
      )!,
      precedesRunDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}precedes_run_day'],
      )!,
    );
  }

  @override
  $PlanDaysTable createAlias(String alias) {
    return $PlanDaysTable(attachedDatabase, alias);
  }
}

class PlanDayRow extends DataClass implements Insertable<PlanDayRow> {
  final DateTime updatedAt;

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  final DateTime? deletedAt;

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  final String deviceId;

  /// The [updatedAt] the server last acknowledged, or null for never.
  ///
  /// The one sync column that is **not** replicated: it is this install's
  /// record of what has been uploaded, and it is what makes the dirty set
  /// exact. A row is pending while `pushed_at IS NULL OR pushed_at <
  /// updated_at`, so the only thing a local write has to remember is to bump
  /// `updated_at` — which it already must do for the conflict rule, rather
  /// than being a second piece of bookkeeping to forget.
  ///
  /// The alternative, comparing `updated_at` against a single watermark,
  /// silently drops an edit made by a device whose clock is behind. Added in
  /// v2: the three columns v1 chose were the right ones for resolving a
  /// conflict and not enough for noticing there was something to resolve.
  final DateTime? pushedAt;
  final String id;
  final String planId;

  /// ISO weekday, 1 = Monday. The weekday is the identity of a session: the
  /// scheduler places days around run days, and moving a day changes this.
  final int weekday;

  /// `DayType` name, e.g. push. Needed to rebuild the day, since the label
  /// alone does not say what kind of session it is.
  final String dayType;
  final String labelKey;

  /// Whether a run falls the day after this one. Leg volume is capped on
  /// these days.
  final bool precedesRunDay;
  const PlanDayRow({
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.pushedAt,
    required this.id,
    required this.planId,
    required this.weekday,
    required this.dayType,
    required this.labelKey,
    required this.precedesRunDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<DateTime>(pushedAt);
    }
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['weekday'] = Variable<int>(weekday);
    map['day_type'] = Variable<String>(dayType);
    map['label_key'] = Variable<String>(labelKey);
    map['precedes_run_day'] = Variable<bool>(precedesRunDay);
    return map;
  }

  PlanDaysCompanion toCompanion(bool nullToAbsent) {
    return PlanDaysCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
      id: Value(id),
      planId: Value(planId),
      weekday: Value(weekday),
      dayType: Value(dayType),
      labelKey: Value(labelKey),
      precedesRunDay: Value(precedesRunDay),
    );
  }

  factory PlanDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanDayRow(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      pushedAt: serializer.fromJson<DateTime?>(json['pushedAt']),
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      dayType: serializer.fromJson<String>(json['dayType']),
      labelKey: serializer.fromJson<String>(json['labelKey']),
      precedesRunDay: serializer.fromJson<bool>(json['precedesRunDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'pushedAt': serializer.toJson<DateTime?>(pushedAt),
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'weekday': serializer.toJson<int>(weekday),
      'dayType': serializer.toJson<String>(dayType),
      'labelKey': serializer.toJson<String>(labelKey),
      'precedesRunDay': serializer.toJson<bool>(precedesRunDay),
    };
  }

  PlanDayRow copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<DateTime?> pushedAt = const Value.absent(),
    String? id,
    String? planId,
    int? weekday,
    String? dayType,
    String? labelKey,
    bool? precedesRunDay,
  }) => PlanDayRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
    id: id ?? this.id,
    planId: planId ?? this.planId,
    weekday: weekday ?? this.weekday,
    dayType: dayType ?? this.dayType,
    labelKey: labelKey ?? this.labelKey,
    precedesRunDay: precedesRunDay ?? this.precedesRunDay,
  );
  PlanDayRow copyWithCompanion(PlanDaysCompanion data) {
    return PlanDayRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      dayType: data.dayType.present ? data.dayType.value : this.dayType,
      labelKey: data.labelKey.present ? data.labelKey.value : this.labelKey,
      precedesRunDay: data.precedesRunDay.present
          ? data.precedesRunDay.value
          : this.precedesRunDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanDayRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekday: $weekday, ')
          ..write('dayType: $dayType, ')
          ..write('labelKey: $labelKey, ')
          ..write('precedesRunDay: $precedesRunDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    planId,
    weekday,
    dayType,
    labelKey,
    precedesRunDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanDayRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.pushedAt == this.pushedAt &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.weekday == this.weekday &&
          other.dayType == this.dayType &&
          other.labelKey == this.labelKey &&
          other.precedesRunDay == this.precedesRunDay);
}

class PlanDaysCompanion extends UpdateCompanion<PlanDayRow> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<DateTime?> pushedAt;
  final Value<String> id;
  final Value<String> planId;
  final Value<int> weekday;
  final Value<String> dayType;
  final Value<String> labelKey;
  final Value<bool> precedesRunDay;
  final Value<int> rowid;
  const PlanDaysCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pushedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.dayType = const Value.absent(),
    this.labelKey = const Value.absent(),
    this.precedesRunDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanDaysCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.pushedAt = const Value.absent(),
    required String id,
    required String planId,
    required int weekday,
    required String dayType,
    required String labelKey,
    this.precedesRunDay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       id = Value(id),
       planId = Value(planId),
       weekday = Value(weekday),
       dayType = Value(dayType),
       labelKey = Value(labelKey);
  static Insertable<PlanDayRow> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? pushedAt,
    Expression<String>? id,
    Expression<String>? planId,
    Expression<int>? weekday,
    Expression<String>? dayType,
    Expression<String>? labelKey,
    Expression<bool>? precedesRunDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (pushedAt != null) 'pushed_at': pushedAt,
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (weekday != null) 'weekday': weekday,
      if (dayType != null) 'day_type': dayType,
      if (labelKey != null) 'label_key': labelKey,
      if (precedesRunDay != null) 'precedes_run_day': precedesRunDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanDaysCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<DateTime?>? pushedAt,
    Value<String>? id,
    Value<String>? planId,
    Value<int>? weekday,
    Value<String>? dayType,
    Value<String>? labelKey,
    Value<bool>? precedesRunDay,
    Value<int>? rowid,
  }) {
    return PlanDaysCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      pushedAt: pushedAt ?? this.pushedAt,
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekday: weekday ?? this.weekday,
      dayType: dayType ?? this.dayType,
      labelKey: labelKey ?? this.labelKey,
      precedesRunDay: precedesRunDay ?? this.precedesRunDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<DateTime>(pushedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (dayType.present) {
      map['day_type'] = Variable<String>(dayType.value);
    }
    if (labelKey.present) {
      map['label_key'] = Variable<String>(labelKey.value);
    }
    if (precedesRunDay.present) {
      map['precedes_run_day'] = Variable<bool>(precedesRunDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanDaysCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekday: $weekday, ')
          ..write('dayType: $dayType, ')
          ..write('labelKey: $labelKey, ')
          ..write('precedesRunDay: $precedesRunDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanExercisesTable extends PlanExercises
    with TableInfo<$PlanExercisesTable, PlanExerciseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pushedAt = GeneratedColumn<DateTime>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planDayIdMeta = const VerificationMeta(
    'planDayId',
  );
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
    'plan_day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotPatternMeta = const VerificationMeta(
    'slotPattern',
  );
  @override
  late final GeneratedColumn<String> slotPattern = GeneratedColumn<String>(
    'slot_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateSetsMeta = const VerificationMeta(
    'templateSets',
  );
  @override
  late final GeneratedColumn<int> templateSets = GeneratedColumn<int>(
    'template_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsPerRepMeta = const VerificationMeta(
    'secondsPerRep',
  );
  @override
  late final GeneratedColumn<double> secondsPerRep = GeneratedColumn<double>(
    'seconds_per_rep',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRepsMinMeta = const VerificationMeta(
    'targetRepsMin',
  );
  @override
  late final GeneratedColumn<int> targetRepsMin = GeneratedColumn<int>(
    'target_reps_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRepsMaxMeta = const VerificationMeta(
    'targetRepsMax',
  );
  @override
  late final GeneratedColumn<int> targetRepsMax = GeneratedColumn<int>(
    'target_reps_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetHoldSecondsMeta = const VerificationMeta(
    'targetHoldSeconds',
  );
  @override
  late final GeneratedColumn<int> targetHoldSeconds = GeneratedColumn<int>(
    'target_hold_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    planDayId,
    orderIndex,
    exerciseId,
    slotPattern,
    priority,
    targetSets,
    templateSets,
    metric,
    restSeconds,
    secondsPerRep,
    targetRepsMin,
    targetRepsMax,
    targetHoldSeconds,
    targetWeightKg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanExerciseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
        _planDayIdMeta,
        planDayId.isAcceptableOrUnknown(data['plan_day_id']!, _planDayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planDayIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('slot_pattern')) {
      context.handle(
        _slotPatternMeta,
        slotPattern.isAcceptableOrUnknown(
          data['slot_pattern']!,
          _slotPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_slotPatternMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetSetsMeta);
    }
    if (data.containsKey('template_sets')) {
      context.handle(
        _templateSetsMeta,
        templateSets.isAcceptableOrUnknown(
          data['template_sets']!,
          _templateSetsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateSetsMeta);
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_restSecondsMeta);
    }
    if (data.containsKey('seconds_per_rep')) {
      context.handle(
        _secondsPerRepMeta,
        secondsPerRep.isAcceptableOrUnknown(
          data['seconds_per_rep']!,
          _secondsPerRepMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_secondsPerRepMeta);
    }
    if (data.containsKey('target_reps_min')) {
      context.handle(
        _targetRepsMinMeta,
        targetRepsMin.isAcceptableOrUnknown(
          data['target_reps_min']!,
          _targetRepsMinMeta,
        ),
      );
    }
    if (data.containsKey('target_reps_max')) {
      context.handle(
        _targetRepsMaxMeta,
        targetRepsMax.isAcceptableOrUnknown(
          data['target_reps_max']!,
          _targetRepsMaxMeta,
        ),
      );
    }
    if (data.containsKey('target_hold_seconds')) {
      context.handle(
        _targetHoldSecondsMeta,
        targetHoldSeconds.isAcceptableOrUnknown(
          data['target_hold_seconds']!,
          _targetHoldSecondsMeta,
        ),
      );
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanExerciseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanExerciseRow(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pushed_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_day_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      slotPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_pattern'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      )!,
      templateSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_sets'],
      )!,
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      )!,
      secondsPerRep: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}seconds_per_rep'],
      )!,
      targetRepsMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps_min'],
      ),
      targetRepsMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps_max'],
      ),
      targetHoldSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_hold_seconds'],
      ),
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      ),
    );
  }

  @override
  $PlanExercisesTable createAlias(String alias) {
    return $PlanExercisesTable(attachedDatabase, alias);
  }
}

class PlanExerciseRow extends DataClass implements Insertable<PlanExerciseRow> {
  final DateTime updatedAt;

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  final DateTime? deletedAt;

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  final String deviceId;

  /// The [updatedAt] the server last acknowledged, or null for never.
  ///
  /// The one sync column that is **not** replicated: it is this install's
  /// record of what has been uploaded, and it is what makes the dirty set
  /// exact. A row is pending while `pushed_at IS NULL OR pushed_at <
  /// updated_at`, so the only thing a local write has to remember is to bump
  /// `updated_at` — which it already must do for the conflict rule, rather
  /// than being a second piece of bookkeeping to forget.
  ///
  /// The alternative, comparing `updated_at` against a single watermark,
  /// silently drops an edit made by a device whose clock is behind. Added in
  /// v2: the three columns v1 chose were the right ones for resolving a
  /// conflict and not enough for noticing there was something to resolve.
  final DateTime? pushedAt;
  final String id;
  final String planDayId;
  final int orderIndex;

  /// Catalog id from the exercise_library package, not a foreign key.
  final String exerciseId;

  /// `MovementPattern` name of the slot this fills, which is not always the
  /// exercise's own pattern: an isolation fallback can fill an accessory
  /// slot. A swap has to keep the slot, so the slot is stored.
  final String slotPattern;

  /// `SlotPriority` name. Decides what the time budget trims first.
  final String priority;
  final int targetSets;

  /// Sets the template asked for, before the pre-run leg cap or any time
  /// trimming. Without it an edit cannot tell a deliberately trimmed day
  /// from a full one, and moving a day could not restore its volume.
  final int templateSets;

  /// `MetricType` name: reps or holdSeconds.
  final String metric;
  final int restSeconds;
  final double secondsPerRep;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int? targetHoldSeconds;
  final double? targetWeightKg;
  const PlanExerciseRow({
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.pushedAt,
    required this.id,
    required this.planDayId,
    required this.orderIndex,
    required this.exerciseId,
    required this.slotPattern,
    required this.priority,
    required this.targetSets,
    required this.templateSets,
    required this.metric,
    required this.restSeconds,
    required this.secondsPerRep,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetHoldSeconds,
    this.targetWeightKg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<DateTime>(pushedAt);
    }
    map['id'] = Variable<String>(id);
    map['plan_day_id'] = Variable<String>(planDayId);
    map['order_index'] = Variable<int>(orderIndex);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['slot_pattern'] = Variable<String>(slotPattern);
    map['priority'] = Variable<String>(priority);
    map['target_sets'] = Variable<int>(targetSets);
    map['template_sets'] = Variable<int>(templateSets);
    map['metric'] = Variable<String>(metric);
    map['rest_seconds'] = Variable<int>(restSeconds);
    map['seconds_per_rep'] = Variable<double>(secondsPerRep);
    if (!nullToAbsent || targetRepsMin != null) {
      map['target_reps_min'] = Variable<int>(targetRepsMin);
    }
    if (!nullToAbsent || targetRepsMax != null) {
      map['target_reps_max'] = Variable<int>(targetRepsMax);
    }
    if (!nullToAbsent || targetHoldSeconds != null) {
      map['target_hold_seconds'] = Variable<int>(targetHoldSeconds);
    }
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    return map;
  }

  PlanExercisesCompanion toCompanion(bool nullToAbsent) {
    return PlanExercisesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
      id: Value(id),
      planDayId: Value(planDayId),
      orderIndex: Value(orderIndex),
      exerciseId: Value(exerciseId),
      slotPattern: Value(slotPattern),
      priority: Value(priority),
      targetSets: Value(targetSets),
      templateSets: Value(templateSets),
      metric: Value(metric),
      restSeconds: Value(restSeconds),
      secondsPerRep: Value(secondsPerRep),
      targetRepsMin: targetRepsMin == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRepsMin),
      targetRepsMax: targetRepsMax == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRepsMax),
      targetHoldSeconds: targetHoldSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(targetHoldSeconds),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
    );
  }

  factory PlanExerciseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanExerciseRow(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      pushedAt: serializer.fromJson<DateTime?>(json['pushedAt']),
      id: serializer.fromJson<String>(json['id']),
      planDayId: serializer.fromJson<String>(json['planDayId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      slotPattern: serializer.fromJson<String>(json['slotPattern']),
      priority: serializer.fromJson<String>(json['priority']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      templateSets: serializer.fromJson<int>(json['templateSets']),
      metric: serializer.fromJson<String>(json['metric']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      secondsPerRep: serializer.fromJson<double>(json['secondsPerRep']),
      targetRepsMin: serializer.fromJson<int?>(json['targetRepsMin']),
      targetRepsMax: serializer.fromJson<int?>(json['targetRepsMax']),
      targetHoldSeconds: serializer.fromJson<int?>(json['targetHoldSeconds']),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'pushedAt': serializer.toJson<DateTime?>(pushedAt),
      'id': serializer.toJson<String>(id),
      'planDayId': serializer.toJson<String>(planDayId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'slotPattern': serializer.toJson<String>(slotPattern),
      'priority': serializer.toJson<String>(priority),
      'targetSets': serializer.toJson<int>(targetSets),
      'templateSets': serializer.toJson<int>(templateSets),
      'metric': serializer.toJson<String>(metric),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'secondsPerRep': serializer.toJson<double>(secondsPerRep),
      'targetRepsMin': serializer.toJson<int?>(targetRepsMin),
      'targetRepsMax': serializer.toJson<int?>(targetRepsMax),
      'targetHoldSeconds': serializer.toJson<int?>(targetHoldSeconds),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
    };
  }

  PlanExerciseRow copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<DateTime?> pushedAt = const Value.absent(),
    String? id,
    String? planDayId,
    int? orderIndex,
    String? exerciseId,
    String? slotPattern,
    String? priority,
    int? targetSets,
    int? templateSets,
    String? metric,
    int? restSeconds,
    double? secondsPerRep,
    Value<int?> targetRepsMin = const Value.absent(),
    Value<int?> targetRepsMax = const Value.absent(),
    Value<int?> targetHoldSeconds = const Value.absent(),
    Value<double?> targetWeightKg = const Value.absent(),
  }) => PlanExerciseRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
    id: id ?? this.id,
    planDayId: planDayId ?? this.planDayId,
    orderIndex: orderIndex ?? this.orderIndex,
    exerciseId: exerciseId ?? this.exerciseId,
    slotPattern: slotPattern ?? this.slotPattern,
    priority: priority ?? this.priority,
    targetSets: targetSets ?? this.targetSets,
    templateSets: templateSets ?? this.templateSets,
    metric: metric ?? this.metric,
    restSeconds: restSeconds ?? this.restSeconds,
    secondsPerRep: secondsPerRep ?? this.secondsPerRep,
    targetRepsMin: targetRepsMin.present
        ? targetRepsMin.value
        : this.targetRepsMin,
    targetRepsMax: targetRepsMax.present
        ? targetRepsMax.value
        : this.targetRepsMax,
    targetHoldSeconds: targetHoldSeconds.present
        ? targetHoldSeconds.value
        : this.targetHoldSeconds,
    targetWeightKg: targetWeightKg.present
        ? targetWeightKg.value
        : this.targetWeightKg,
  );
  PlanExerciseRow copyWithCompanion(PlanExercisesCompanion data) {
    return PlanExerciseRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
      id: data.id.present ? data.id.value : this.id,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      slotPattern: data.slotPattern.present
          ? data.slotPattern.value
          : this.slotPattern,
      priority: data.priority.present ? data.priority.value : this.priority,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      templateSets: data.templateSets.present
          ? data.templateSets.value
          : this.templateSets,
      metric: data.metric.present ? data.metric.value : this.metric,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      secondsPerRep: data.secondsPerRep.present
          ? data.secondsPerRep.value
          : this.secondsPerRep,
      targetRepsMin: data.targetRepsMin.present
          ? data.targetRepsMin.value
          : this.targetRepsMin,
      targetRepsMax: data.targetRepsMax.present
          ? data.targetRepsMax.value
          : this.targetRepsMax,
      targetHoldSeconds: data.targetHoldSeconds.present
          ? data.targetHoldSeconds.value
          : this.targetHoldSeconds,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanExerciseRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('slotPattern: $slotPattern, ')
          ..write('priority: $priority, ')
          ..write('targetSets: $targetSets, ')
          ..write('templateSets: $templateSets, ')
          ..write('metric: $metric, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('secondsPerRep: $secondsPerRep, ')
          ..write('targetRepsMin: $targetRepsMin, ')
          ..write('targetRepsMax: $targetRepsMax, ')
          ..write('targetHoldSeconds: $targetHoldSeconds, ')
          ..write('targetWeightKg: $targetWeightKg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    planDayId,
    orderIndex,
    exerciseId,
    slotPattern,
    priority,
    targetSets,
    templateSets,
    metric,
    restSeconds,
    secondsPerRep,
    targetRepsMin,
    targetRepsMax,
    targetHoldSeconds,
    targetWeightKg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanExerciseRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.pushedAt == this.pushedAt &&
          other.id == this.id &&
          other.planDayId == this.planDayId &&
          other.orderIndex == this.orderIndex &&
          other.exerciseId == this.exerciseId &&
          other.slotPattern == this.slotPattern &&
          other.priority == this.priority &&
          other.targetSets == this.targetSets &&
          other.templateSets == this.templateSets &&
          other.metric == this.metric &&
          other.restSeconds == this.restSeconds &&
          other.secondsPerRep == this.secondsPerRep &&
          other.targetRepsMin == this.targetRepsMin &&
          other.targetRepsMax == this.targetRepsMax &&
          other.targetHoldSeconds == this.targetHoldSeconds &&
          other.targetWeightKg == this.targetWeightKg);
}

class PlanExercisesCompanion extends UpdateCompanion<PlanExerciseRow> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<DateTime?> pushedAt;
  final Value<String> id;
  final Value<String> planDayId;
  final Value<int> orderIndex;
  final Value<String> exerciseId;
  final Value<String> slotPattern;
  final Value<String> priority;
  final Value<int> targetSets;
  final Value<int> templateSets;
  final Value<String> metric;
  final Value<int> restSeconds;
  final Value<double> secondsPerRep;
  final Value<int?> targetRepsMin;
  final Value<int?> targetRepsMax;
  final Value<int?> targetHoldSeconds;
  final Value<double?> targetWeightKg;
  final Value<int> rowid;
  const PlanExercisesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pushedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.slotPattern = const Value.absent(),
    this.priority = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.templateSets = const Value.absent(),
    this.metric = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.secondsPerRep = const Value.absent(),
    this.targetRepsMin = const Value.absent(),
    this.targetRepsMax = const Value.absent(),
    this.targetHoldSeconds = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanExercisesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.pushedAt = const Value.absent(),
    required String id,
    required String planDayId,
    required int orderIndex,
    required String exerciseId,
    required String slotPattern,
    required String priority,
    required int targetSets,
    required int templateSets,
    required String metric,
    required int restSeconds,
    required double secondsPerRep,
    this.targetRepsMin = const Value.absent(),
    this.targetRepsMax = const Value.absent(),
    this.targetHoldSeconds = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       id = Value(id),
       planDayId = Value(planDayId),
       orderIndex = Value(orderIndex),
       exerciseId = Value(exerciseId),
       slotPattern = Value(slotPattern),
       priority = Value(priority),
       targetSets = Value(targetSets),
       templateSets = Value(templateSets),
       metric = Value(metric),
       restSeconds = Value(restSeconds),
       secondsPerRep = Value(secondsPerRep);
  static Insertable<PlanExerciseRow> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? pushedAt,
    Expression<String>? id,
    Expression<String>? planDayId,
    Expression<int>? orderIndex,
    Expression<String>? exerciseId,
    Expression<String>? slotPattern,
    Expression<String>? priority,
    Expression<int>? targetSets,
    Expression<int>? templateSets,
    Expression<String>? metric,
    Expression<int>? restSeconds,
    Expression<double>? secondsPerRep,
    Expression<int>? targetRepsMin,
    Expression<int>? targetRepsMax,
    Expression<int>? targetHoldSeconds,
    Expression<double>? targetWeightKg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (pushedAt != null) 'pushed_at': pushedAt,
      if (id != null) 'id': id,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (slotPattern != null) 'slot_pattern': slotPattern,
      if (priority != null) 'priority': priority,
      if (targetSets != null) 'target_sets': targetSets,
      if (templateSets != null) 'template_sets': templateSets,
      if (metric != null) 'metric': metric,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (secondsPerRep != null) 'seconds_per_rep': secondsPerRep,
      if (targetRepsMin != null) 'target_reps_min': targetRepsMin,
      if (targetRepsMax != null) 'target_reps_max': targetRepsMax,
      if (targetHoldSeconds != null) 'target_hold_seconds': targetHoldSeconds,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanExercisesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<DateTime?>? pushedAt,
    Value<String>? id,
    Value<String>? planDayId,
    Value<int>? orderIndex,
    Value<String>? exerciseId,
    Value<String>? slotPattern,
    Value<String>? priority,
    Value<int>? targetSets,
    Value<int>? templateSets,
    Value<String>? metric,
    Value<int>? restSeconds,
    Value<double>? secondsPerRep,
    Value<int?>? targetRepsMin,
    Value<int?>? targetRepsMax,
    Value<int?>? targetHoldSeconds,
    Value<double?>? targetWeightKg,
    Value<int>? rowid,
  }) {
    return PlanExercisesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      pushedAt: pushedAt ?? this.pushedAt,
      id: id ?? this.id,
      planDayId: planDayId ?? this.planDayId,
      orderIndex: orderIndex ?? this.orderIndex,
      exerciseId: exerciseId ?? this.exerciseId,
      slotPattern: slotPattern ?? this.slotPattern,
      priority: priority ?? this.priority,
      targetSets: targetSets ?? this.targetSets,
      templateSets: templateSets ?? this.templateSets,
      metric: metric ?? this.metric,
      restSeconds: restSeconds ?? this.restSeconds,
      secondsPerRep: secondsPerRep ?? this.secondsPerRep,
      targetRepsMin: targetRepsMin ?? this.targetRepsMin,
      targetRepsMax: targetRepsMax ?? this.targetRepsMax,
      targetHoldSeconds: targetHoldSeconds ?? this.targetHoldSeconds,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<DateTime>(pushedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (slotPattern.present) {
      map['slot_pattern'] = Variable<String>(slotPattern.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (templateSets.present) {
      map['template_sets'] = Variable<int>(templateSets.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (secondsPerRep.present) {
      map['seconds_per_rep'] = Variable<double>(secondsPerRep.value);
    }
    if (targetRepsMin.present) {
      map['target_reps_min'] = Variable<int>(targetRepsMin.value);
    }
    if (targetRepsMax.present) {
      map['target_reps_max'] = Variable<int>(targetRepsMax.value);
    }
    if (targetHoldSeconds.present) {
      map['target_hold_seconds'] = Variable<int>(targetHoldSeconds.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanExercisesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('slotPattern: $slotPattern, ')
          ..write('priority: $priority, ')
          ..write('targetSets: $targetSets, ')
          ..write('templateSets: $templateSets, ')
          ..write('metric: $metric, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('secondsPerRep: $secondsPerRep, ')
          ..write('targetRepsMin: $targetRepsMin, ')
          ..write('targetRepsMax: $targetRepsMax, ')
          ..write('targetHoldSeconds: $targetHoldSeconds, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pushedAt = GeneratedColumn<DateTime>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planDayIdMeta = const VerificationMeta(
    'planDayId',
  );
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
    'plan_day_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _painReportedMeta = const VerificationMeta(
    'painReported',
  );
  @override
  late final GeneratedColumn<bool> painReported = GeneratedColumn<bool>(
    'pain_reported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pain_reported" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    planDayId,
    startedAt,
    endedAt,
    rating,
    painReported,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
        _planDayIdMeta,
        planDayId.isAcceptableOrUnknown(data['plan_day_id']!, _planDayIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('pain_reported')) {
      context.handle(
        _painReportedMeta,
        painReported.isAcceptableOrUnknown(
          data['pain_reported']!,
          _painReportedMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pushed_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_day_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      painReported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pain_reported'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final DateTime updatedAt;

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  final DateTime? deletedAt;

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  final String deviceId;

  /// The [updatedAt] the server last acknowledged, or null for never.
  ///
  /// The one sync column that is **not** replicated: it is this install's
  /// record of what has been uploaded, and it is what makes the dirty set
  /// exact. A row is pending while `pushed_at IS NULL OR pushed_at <
  /// updated_at`, so the only thing a local write has to remember is to bump
  /// `updated_at` — which it already must do for the conflict rule, rather
  /// than being a second piece of bookkeeping to forget.
  ///
  /// The alternative, comparing `updated_at` against a single watermark,
  /// silently drops an edit made by a device whose clock is behind. Added in
  /// v2: the three columns v1 chose were the right ones for resolving a
  /// conflict and not enough for noticing there was something to resolve.
  final DateTime? pushedAt;
  final String id;
  final String? planDayId;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Post-session rating that feeds progression: tooEasy | right | tooHard.
  final String? rating;

  /// Set by the pain button. Never overwritten by progression.
  final bool painReported;
  final String? notes;
  const SessionRow({
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.pushedAt,
    required this.id,
    this.planDayId,
    required this.startedAt,
    this.endedAt,
    this.rating,
    required this.painReported,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<DateTime>(pushedAt);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || planDayId != null) {
      map['plan_day_id'] = Variable<String>(planDayId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    map['pain_reported'] = Variable<bool>(painReported);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
      id: Value(id),
      planDayId: planDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(planDayId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      painReported: Value(painReported),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      pushedAt: serializer.fromJson<DateTime?>(json['pushedAt']),
      id: serializer.fromJson<String>(json['id']),
      planDayId: serializer.fromJson<String?>(json['planDayId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      rating: serializer.fromJson<String?>(json['rating']),
      painReported: serializer.fromJson<bool>(json['painReported']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'pushedAt': serializer.toJson<DateTime?>(pushedAt),
      'id': serializer.toJson<String>(id),
      'planDayId': serializer.toJson<String?>(planDayId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'rating': serializer.toJson<String?>(rating),
      'painReported': serializer.toJson<bool>(painReported),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SessionRow copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<DateTime?> pushedAt = const Value.absent(),
    String? id,
    Value<String?> planDayId = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    bool? painReported,
    Value<String?> notes = const Value.absent(),
  }) => SessionRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
    id: id ?? this.id,
    planDayId: planDayId.present ? planDayId.value : this.planDayId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    rating: rating.present ? rating.value : this.rating,
    painReported: painReported ?? this.painReported,
    notes: notes.present ? notes.value : this.notes,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
      id: data.id.present ? data.id.value : this.id,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      rating: data.rating.present ? data.rating.value : this.rating,
      painReported: data.painReported.present
          ? data.painReported.value
          : this.painReported,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('rating: $rating, ')
          ..write('painReported: $painReported, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    planDayId,
    startedAt,
    endedAt,
    rating,
    painReported,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.pushedAt == this.pushedAt &&
          other.id == this.id &&
          other.planDayId == this.planDayId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.rating == this.rating &&
          other.painReported == this.painReported &&
          other.notes == this.notes);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<DateTime?> pushedAt;
  final Value<String> id;
  final Value<String?> planDayId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> rating;
  final Value<bool> painReported;
  final Value<String?> notes;
  final Value<int> rowid;
  const SessionsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pushedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.painReported = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.pushedAt = const Value.absent(),
    required String id,
    this.planDayId = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.painReported = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       id = Value(id),
       startedAt = Value(startedAt);
  static Insertable<SessionRow> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? pushedAt,
    Expression<String>? id,
    Expression<String>? planDayId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? rating,
    Expression<bool>? painReported,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (pushedAt != null) 'pushed_at': pushedAt,
      if (id != null) 'id': id,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (rating != null) 'rating': rating,
      if (painReported != null) 'pain_reported': painReported,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<DateTime?>? pushedAt,
    Value<String>? id,
    Value<String?>? planDayId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? rating,
    Value<bool>? painReported,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      pushedAt: pushedAt ?? this.pushedAt,
      id: id ?? this.id,
      planDayId: planDayId ?? this.planDayId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      rating: rating ?? this.rating,
      painReported: painReported ?? this.painReported,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<DateTime>(pushedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (painReported.present) {
      map['pain_reported'] = Variable<bool>(painReported.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('rating: $rating, ')
          ..write('painReported: $painReported, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetLogsTable extends SetLogs with TableInfo<$SetLogsTable, SetLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pushedAt = GeneratedColumn<DateTime>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planExerciseIdMeta = const VerificationMeta(
    'planExerciseId',
  );
  @override
  late final GeneratedColumn<String> planExerciseId = GeneratedColumn<String>(
    'plan_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holdSecondsMeta = const VerificationMeta(
    'holdSeconds',
  );
  @override
  late final GeneratedColumn<int> holdSeconds = GeneratedColumn<int>(
    'hold_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formScoreMeta = const VerificationMeta(
    'formScore',
  );
  @override
  late final GeneratedColumn<double> formScore = GeneratedColumn<double>(
    'form_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cameraAngleMeta = const VerificationMeta(
    'cameraAngle',
  );
  @override
  late final GeneratedColumn<String> cameraAngle = GeneratedColumn<String>(
    'camera_angle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    sessionId,
    planExerciseId,
    exerciseId,
    setIndex,
    reps,
    weightKg,
    holdSeconds,
    formScore,
    cameraAngle,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('plan_exercise_id')) {
      context.handle(
        _planExerciseIdMeta,
        planExerciseId.isAcceptableOrUnknown(
          data['plan_exercise_id']!,
          _planExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('hold_seconds')) {
      context.handle(
        _holdSecondsMeta,
        holdSeconds.isAcceptableOrUnknown(
          data['hold_seconds']!,
          _holdSecondsMeta,
        ),
      );
    }
    if (data.containsKey('form_score')) {
      context.handle(
        _formScoreMeta,
        formScore.isAcceptableOrUnknown(data['form_score']!, _formScoreMeta),
      );
    }
    if (data.containsKey('camera_angle')) {
      context.handle(
        _cameraAngleMeta,
        cameraAngle.isAcceptableOrUnknown(
          data['camera_angle']!,
          _cameraAngleMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetLogRow(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pushed_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      planExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_exercise_id'],
      ),
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      holdSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hold_seconds'],
      ),
      formScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}form_score'],
      ),
      cameraAngle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}camera_angle'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $SetLogsTable createAlias(String alias) {
    return $SetLogsTable(attachedDatabase, alias);
  }
}

class SetLogRow extends DataClass implements Insertable<SetLogRow> {
  final DateTime updatedAt;

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  final DateTime? deletedAt;

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  final String deviceId;

  /// The [updatedAt] the server last acknowledged, or null for never.
  ///
  /// The one sync column that is **not** replicated: it is this install's
  /// record of what has been uploaded, and it is what makes the dirty set
  /// exact. A row is pending while `pushed_at IS NULL OR pushed_at <
  /// updated_at`, so the only thing a local write has to remember is to bump
  /// `updated_at` — which it already must do for the conflict rule, rather
  /// than being a second piece of bookkeeping to forget.
  ///
  /// The alternative, comparing `updated_at` against a single watermark,
  /// silently drops an edit made by a device whose clock is behind. Added in
  /// v2: the three columns v1 chose were the right ones for resolving a
  /// conflict and not enough for noticing there was something to resolve.
  final DateTime? pushedAt;
  final String id;
  final String sessionId;
  final String? planExerciseId;
  final String exerciseId;
  final int setIndex;

  /// Reps the counter accepted. Rejected reps live in [RepLogs].
  final int reps;
  final double? weightKg;
  final int? holdSeconds;

  /// 0..100, mean over counted reps. Null when the set ran without camera.
  final double? formScore;
  final String? cameraAngle;
  final DateTime completedAt;
  const SetLogRow({
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.pushedAt,
    required this.id,
    required this.sessionId,
    this.planExerciseId,
    required this.exerciseId,
    required this.setIndex,
    required this.reps,
    this.weightKg,
    this.holdSeconds,
    this.formScore,
    this.cameraAngle,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<DateTime>(pushedAt);
    }
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || planExerciseId != null) {
      map['plan_exercise_id'] = Variable<String>(planExerciseId);
    }
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_index'] = Variable<int>(setIndex);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || holdSeconds != null) {
      map['hold_seconds'] = Variable<int>(holdSeconds);
    }
    if (!nullToAbsent || formScore != null) {
      map['form_score'] = Variable<double>(formScore);
    }
    if (!nullToAbsent || cameraAngle != null) {
      map['camera_angle'] = Variable<String>(cameraAngle);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  SetLogsCompanion toCompanion(bool nullToAbsent) {
    return SetLogsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
      id: Value(id),
      sessionId: Value(sessionId),
      planExerciseId: planExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(planExerciseId),
      exerciseId: Value(exerciseId),
      setIndex: Value(setIndex),
      reps: Value(reps),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      holdSeconds: holdSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(holdSeconds),
      formScore: formScore == null && nullToAbsent
          ? const Value.absent()
          : Value(formScore),
      cameraAngle: cameraAngle == null && nullToAbsent
          ? const Value.absent()
          : Value(cameraAngle),
      completedAt: Value(completedAt),
    );
  }

  factory SetLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetLogRow(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      pushedAt: serializer.fromJson<DateTime?>(json['pushedAt']),
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      planExerciseId: serializer.fromJson<String?>(json['planExerciseId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      reps: serializer.fromJson<int>(json['reps']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      holdSeconds: serializer.fromJson<int?>(json['holdSeconds']),
      formScore: serializer.fromJson<double?>(json['formScore']),
      cameraAngle: serializer.fromJson<String?>(json['cameraAngle']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'pushedAt': serializer.toJson<DateTime?>(pushedAt),
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'planExerciseId': serializer.toJson<String?>(planExerciseId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setIndex': serializer.toJson<int>(setIndex),
      'reps': serializer.toJson<int>(reps),
      'weightKg': serializer.toJson<double?>(weightKg),
      'holdSeconds': serializer.toJson<int?>(holdSeconds),
      'formScore': serializer.toJson<double?>(formScore),
      'cameraAngle': serializer.toJson<String?>(cameraAngle),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  SetLogRow copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<DateTime?> pushedAt = const Value.absent(),
    String? id,
    String? sessionId,
    Value<String?> planExerciseId = const Value.absent(),
    String? exerciseId,
    int? setIndex,
    int? reps,
    Value<double?> weightKg = const Value.absent(),
    Value<int?> holdSeconds = const Value.absent(),
    Value<double?> formScore = const Value.absent(),
    Value<String?> cameraAngle = const Value.absent(),
    DateTime? completedAt,
  }) => SetLogRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    planExerciseId: planExerciseId.present
        ? planExerciseId.value
        : this.planExerciseId,
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    reps: reps ?? this.reps,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    holdSeconds: holdSeconds.present ? holdSeconds.value : this.holdSeconds,
    formScore: formScore.present ? formScore.value : this.formScore,
    cameraAngle: cameraAngle.present ? cameraAngle.value : this.cameraAngle,
    completedAt: completedAt ?? this.completedAt,
  );
  SetLogRow copyWithCompanion(SetLogsCompanion data) {
    return SetLogRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      planExerciseId: data.planExerciseId.present
          ? data.planExerciseId.value
          : this.planExerciseId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      holdSeconds: data.holdSeconds.present
          ? data.holdSeconds.value
          : this.holdSeconds,
      formScore: data.formScore.present ? data.formScore.value : this.formScore,
      cameraAngle: data.cameraAngle.present
          ? data.cameraAngle.value
          : this.cameraAngle,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetLogRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('planExerciseId: $planExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('holdSeconds: $holdSeconds, ')
          ..write('formScore: $formScore, ')
          ..write('cameraAngle: $cameraAngle, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    sessionId,
    planExerciseId,
    exerciseId,
    setIndex,
    reps,
    weightKg,
    holdSeconds,
    formScore,
    cameraAngle,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetLogRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.pushedAt == this.pushedAt &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.planExerciseId == this.planExerciseId &&
          other.exerciseId == this.exerciseId &&
          other.setIndex == this.setIndex &&
          other.reps == this.reps &&
          other.weightKg == this.weightKg &&
          other.holdSeconds == this.holdSeconds &&
          other.formScore == this.formScore &&
          other.cameraAngle == this.cameraAngle &&
          other.completedAt == this.completedAt);
}

class SetLogsCompanion extends UpdateCompanion<SetLogRow> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<DateTime?> pushedAt;
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String?> planExerciseId;
  final Value<String> exerciseId;
  final Value<int> setIndex;
  final Value<int> reps;
  final Value<double?> weightKg;
  final Value<int?> holdSeconds;
  final Value<double?> formScore;
  final Value<String?> cameraAngle;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const SetLogsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pushedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.planExerciseId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.holdSeconds = const Value.absent(),
    this.formScore = const Value.absent(),
    this.cameraAngle = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetLogsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.pushedAt = const Value.absent(),
    required String id,
    required String sessionId,
    this.planExerciseId = const Value.absent(),
    required String exerciseId,
    required int setIndex,
    required int reps,
    this.weightKg = const Value.absent(),
    this.holdSeconds = const Value.absent(),
    this.formScore = const Value.absent(),
    this.cameraAngle = const Value.absent(),
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       id = Value(id),
       sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       setIndex = Value(setIndex),
       reps = Value(reps),
       completedAt = Value(completedAt);
  static Insertable<SetLogRow> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? pushedAt,
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? planExerciseId,
    Expression<String>? exerciseId,
    Expression<int>? setIndex,
    Expression<int>? reps,
    Expression<double>? weightKg,
    Expression<int>? holdSeconds,
    Expression<double>? formScore,
    Expression<String>? cameraAngle,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (pushedAt != null) 'pushed_at': pushedAt,
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (planExerciseId != null) 'plan_exercise_id': planExerciseId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setIndex != null) 'set_index': setIndex,
      if (reps != null) 'reps': reps,
      if (weightKg != null) 'weight_kg': weightKg,
      if (holdSeconds != null) 'hold_seconds': holdSeconds,
      if (formScore != null) 'form_score': formScore,
      if (cameraAngle != null) 'camera_angle': cameraAngle,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetLogsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<DateTime?>? pushedAt,
    Value<String>? id,
    Value<String>? sessionId,
    Value<String?>? planExerciseId,
    Value<String>? exerciseId,
    Value<int>? setIndex,
    Value<int>? reps,
    Value<double?>? weightKg,
    Value<int?>? holdSeconds,
    Value<double?>? formScore,
    Value<String?>? cameraAngle,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return SetLogsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      pushedAt: pushedAt ?? this.pushedAt,
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      planExerciseId: planExerciseId ?? this.planExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      formScore: formScore ?? this.formScore,
      cameraAngle: cameraAngle ?? this.cameraAngle,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<DateTime>(pushedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (planExerciseId.present) {
      map['plan_exercise_id'] = Variable<String>(planExerciseId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (holdSeconds.present) {
      map['hold_seconds'] = Variable<int>(holdSeconds.value);
    }
    if (formScore.present) {
      map['form_score'] = Variable<double>(formScore.value);
    }
    if (cameraAngle.present) {
      map['camera_angle'] = Variable<String>(cameraAngle.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetLogsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('planExerciseId: $planExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('holdSeconds: $holdSeconds, ')
          ..write('formScore: $formScore, ')
          ..write('cameraAngle: $cameraAngle, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RepLogsTable extends RepLogs with TableInfo<$RepLogsTable, RepLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RepLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setLogIdMeta = const VerificationMeta(
    'setLogId',
  );
  @override
  late final GeneratedColumn<String> setLogId = GeneratedColumn<String>(
    'set_log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repIndexMeta = const VerificationMeta(
    'repIndex',
  );
  @override
  late final GeneratedColumn<int> repIndex = GeneratedColumn<int>(
    'rep_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countedMeta = const VerificationMeta(
    'counted',
  );
  @override
  late final GeneratedColumn<bool> counted = GeneratedColumn<bool>(
    'counted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _rejectionReasonMeta = const VerificationMeta(
    'rejectionReason',
  );
  @override
  late final GeneratedColumn<String> rejectionReason = GeneratedColumn<String>(
    'rejection_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peakAngleMeta = const VerificationMeta(
    'peakAngle',
  );
  @override
  late final GeneratedColumn<double> peakAngle = GeneratedColumn<double>(
    'peak_angle',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rangeOfMotionMeta = const VerificationMeta(
    'rangeOfMotion',
  );
  @override
  late final GeneratedColumn<double> rangeOfMotion = GeneratedColumn<double>(
    'range_of_motion',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formScoreMeta = const VerificationMeta(
    'formScore',
  );
  @override
  late final GeneratedColumn<double> formScore = GeneratedColumn<double>(
    'form_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    setLogId,
    repIndex,
    counted,
    rejectionReason,
    durationMs,
    peakAngle,
    rangeOfMotion,
    formScore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rep_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RepLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('set_log_id')) {
      context.handle(
        _setLogIdMeta,
        setLogId.isAcceptableOrUnknown(data['set_log_id']!, _setLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setLogIdMeta);
    }
    if (data.containsKey('rep_index')) {
      context.handle(
        _repIndexMeta,
        repIndex.isAcceptableOrUnknown(data['rep_index']!, _repIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_repIndexMeta);
    }
    if (data.containsKey('counted')) {
      context.handle(
        _countedMeta,
        counted.isAcceptableOrUnknown(data['counted']!, _countedMeta),
      );
    } else if (isInserting) {
      context.missing(_countedMeta);
    }
    if (data.containsKey('rejection_reason')) {
      context.handle(
        _rejectionReasonMeta,
        rejectionReason.isAcceptableOrUnknown(
          data['rejection_reason']!,
          _rejectionReasonMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('peak_angle')) {
      context.handle(
        _peakAngleMeta,
        peakAngle.isAcceptableOrUnknown(data['peak_angle']!, _peakAngleMeta),
      );
    }
    if (data.containsKey('range_of_motion')) {
      context.handle(
        _rangeOfMotionMeta,
        rangeOfMotion.isAcceptableOrUnknown(
          data['range_of_motion']!,
          _rangeOfMotionMeta,
        ),
      );
    }
    if (data.containsKey('form_score')) {
      context.handle(
        _formScoreMeta,
        formScore.isAcceptableOrUnknown(data['form_score']!, _formScoreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RepLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RepLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      setLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_log_id'],
      )!,
      repIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rep_index'],
      )!,
      counted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counted'],
      )!,
      rejectionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejection_reason'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      peakAngle: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak_angle'],
      ),
      rangeOfMotion: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}range_of_motion'],
      ),
      formScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}form_score'],
      ),
    );
  }

  @override
  $RepLogsTable createAlias(String alias) {
    return $RepLogsTable(attachedDatabase, alias);
  }
}

class RepLogRow extends DataClass implements Insertable<RepLogRow> {
  final String id;
  final String setLogId;
  final int repIndex;

  /// Whether this rep counted, and if not why — the user-facing ledger.
  final bool counted;
  final String? rejectionReason;
  final int durationMs;
  final double? peakAngle;
  final double? rangeOfMotion;
  final double? formScore;
  const RepLogRow({
    required this.id,
    required this.setLogId,
    required this.repIndex,
    required this.counted,
    this.rejectionReason,
    required this.durationMs,
    this.peakAngle,
    this.rangeOfMotion,
    this.formScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_log_id'] = Variable<String>(setLogId);
    map['rep_index'] = Variable<int>(repIndex);
    map['counted'] = Variable<bool>(counted);
    if (!nullToAbsent || rejectionReason != null) {
      map['rejection_reason'] = Variable<String>(rejectionReason);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || peakAngle != null) {
      map['peak_angle'] = Variable<double>(peakAngle);
    }
    if (!nullToAbsent || rangeOfMotion != null) {
      map['range_of_motion'] = Variable<double>(rangeOfMotion);
    }
    if (!nullToAbsent || formScore != null) {
      map['form_score'] = Variable<double>(formScore);
    }
    return map;
  }

  RepLogsCompanion toCompanion(bool nullToAbsent) {
    return RepLogsCompanion(
      id: Value(id),
      setLogId: Value(setLogId),
      repIndex: Value(repIndex),
      counted: Value(counted),
      rejectionReason: rejectionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectionReason),
      durationMs: Value(durationMs),
      peakAngle: peakAngle == null && nullToAbsent
          ? const Value.absent()
          : Value(peakAngle),
      rangeOfMotion: rangeOfMotion == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeOfMotion),
      formScore: formScore == null && nullToAbsent
          ? const Value.absent()
          : Value(formScore),
    );
  }

  factory RepLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RepLogRow(
      id: serializer.fromJson<String>(json['id']),
      setLogId: serializer.fromJson<String>(json['setLogId']),
      repIndex: serializer.fromJson<int>(json['repIndex']),
      counted: serializer.fromJson<bool>(json['counted']),
      rejectionReason: serializer.fromJson<String?>(json['rejectionReason']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      peakAngle: serializer.fromJson<double?>(json['peakAngle']),
      rangeOfMotion: serializer.fromJson<double?>(json['rangeOfMotion']),
      formScore: serializer.fromJson<double?>(json['formScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setLogId': serializer.toJson<String>(setLogId),
      'repIndex': serializer.toJson<int>(repIndex),
      'counted': serializer.toJson<bool>(counted),
      'rejectionReason': serializer.toJson<String?>(rejectionReason),
      'durationMs': serializer.toJson<int>(durationMs),
      'peakAngle': serializer.toJson<double?>(peakAngle),
      'rangeOfMotion': serializer.toJson<double?>(rangeOfMotion),
      'formScore': serializer.toJson<double?>(formScore),
    };
  }

  RepLogRow copyWith({
    String? id,
    String? setLogId,
    int? repIndex,
    bool? counted,
    Value<String?> rejectionReason = const Value.absent(),
    int? durationMs,
    Value<double?> peakAngle = const Value.absent(),
    Value<double?> rangeOfMotion = const Value.absent(),
    Value<double?> formScore = const Value.absent(),
  }) => RepLogRow(
    id: id ?? this.id,
    setLogId: setLogId ?? this.setLogId,
    repIndex: repIndex ?? this.repIndex,
    counted: counted ?? this.counted,
    rejectionReason: rejectionReason.present
        ? rejectionReason.value
        : this.rejectionReason,
    durationMs: durationMs ?? this.durationMs,
    peakAngle: peakAngle.present ? peakAngle.value : this.peakAngle,
    rangeOfMotion: rangeOfMotion.present
        ? rangeOfMotion.value
        : this.rangeOfMotion,
    formScore: formScore.present ? formScore.value : this.formScore,
  );
  RepLogRow copyWithCompanion(RepLogsCompanion data) {
    return RepLogRow(
      id: data.id.present ? data.id.value : this.id,
      setLogId: data.setLogId.present ? data.setLogId.value : this.setLogId,
      repIndex: data.repIndex.present ? data.repIndex.value : this.repIndex,
      counted: data.counted.present ? data.counted.value : this.counted,
      rejectionReason: data.rejectionReason.present
          ? data.rejectionReason.value
          : this.rejectionReason,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      peakAngle: data.peakAngle.present ? data.peakAngle.value : this.peakAngle,
      rangeOfMotion: data.rangeOfMotion.present
          ? data.rangeOfMotion.value
          : this.rangeOfMotion,
      formScore: data.formScore.present ? data.formScore.value : this.formScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RepLogRow(')
          ..write('id: $id, ')
          ..write('setLogId: $setLogId, ')
          ..write('repIndex: $repIndex, ')
          ..write('counted: $counted, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('durationMs: $durationMs, ')
          ..write('peakAngle: $peakAngle, ')
          ..write('rangeOfMotion: $rangeOfMotion, ')
          ..write('formScore: $formScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    setLogId,
    repIndex,
    counted,
    rejectionReason,
    durationMs,
    peakAngle,
    rangeOfMotion,
    formScore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RepLogRow &&
          other.id == this.id &&
          other.setLogId == this.setLogId &&
          other.repIndex == this.repIndex &&
          other.counted == this.counted &&
          other.rejectionReason == this.rejectionReason &&
          other.durationMs == this.durationMs &&
          other.peakAngle == this.peakAngle &&
          other.rangeOfMotion == this.rangeOfMotion &&
          other.formScore == this.formScore);
}

class RepLogsCompanion extends UpdateCompanion<RepLogRow> {
  final Value<String> id;
  final Value<String> setLogId;
  final Value<int> repIndex;
  final Value<bool> counted;
  final Value<String?> rejectionReason;
  final Value<int> durationMs;
  final Value<double?> peakAngle;
  final Value<double?> rangeOfMotion;
  final Value<double?> formScore;
  final Value<int> rowid;
  const RepLogsCompanion({
    this.id = const Value.absent(),
    this.setLogId = const Value.absent(),
    this.repIndex = const Value.absent(),
    this.counted = const Value.absent(),
    this.rejectionReason = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.peakAngle = const Value.absent(),
    this.rangeOfMotion = const Value.absent(),
    this.formScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RepLogsCompanion.insert({
    required String id,
    required String setLogId,
    required int repIndex,
    required bool counted,
    this.rejectionReason = const Value.absent(),
    required int durationMs,
    this.peakAngle = const Value.absent(),
    this.rangeOfMotion = const Value.absent(),
    this.formScore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       setLogId = Value(setLogId),
       repIndex = Value(repIndex),
       counted = Value(counted),
       durationMs = Value(durationMs);
  static Insertable<RepLogRow> custom({
    Expression<String>? id,
    Expression<String>? setLogId,
    Expression<int>? repIndex,
    Expression<bool>? counted,
    Expression<String>? rejectionReason,
    Expression<int>? durationMs,
    Expression<double>? peakAngle,
    Expression<double>? rangeOfMotion,
    Expression<double>? formScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setLogId != null) 'set_log_id': setLogId,
      if (repIndex != null) 'rep_index': repIndex,
      if (counted != null) 'counted': counted,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (durationMs != null) 'duration_ms': durationMs,
      if (peakAngle != null) 'peak_angle': peakAngle,
      if (rangeOfMotion != null) 'range_of_motion': rangeOfMotion,
      if (formScore != null) 'form_score': formScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RepLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? setLogId,
    Value<int>? repIndex,
    Value<bool>? counted,
    Value<String?>? rejectionReason,
    Value<int>? durationMs,
    Value<double?>? peakAngle,
    Value<double?>? rangeOfMotion,
    Value<double?>? formScore,
    Value<int>? rowid,
  }) {
    return RepLogsCompanion(
      id: id ?? this.id,
      setLogId: setLogId ?? this.setLogId,
      repIndex: repIndex ?? this.repIndex,
      counted: counted ?? this.counted,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      durationMs: durationMs ?? this.durationMs,
      peakAngle: peakAngle ?? this.peakAngle,
      rangeOfMotion: rangeOfMotion ?? this.rangeOfMotion,
      formScore: formScore ?? this.formScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setLogId.present) {
      map['set_log_id'] = Variable<String>(setLogId.value);
    }
    if (repIndex.present) {
      map['rep_index'] = Variable<int>(repIndex.value);
    }
    if (counted.present) {
      map['counted'] = Variable<bool>(counted.value);
    }
    if (rejectionReason.present) {
      map['rejection_reason'] = Variable<String>(rejectionReason.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (peakAngle.present) {
      map['peak_angle'] = Variable<double>(peakAngle.value);
    }
    if (rangeOfMotion.present) {
      map['range_of_motion'] = Variable<double>(rangeOfMotion.value);
    }
    if (formScore.present) {
      map['form_score'] = Variable<double>(formScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepLogsCompanion(')
          ..write('id: $id, ')
          ..write('setLogId: $setLogId, ')
          ..write('repIndex: $repIndex, ')
          ..write('counted: $counted, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('durationMs: $durationMs, ')
          ..write('peakAngle: $peakAngle, ')
          ..write('rangeOfMotion: $rangeOfMotion, ')
          ..write('formScore: $formScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormEventsTable extends FormEvents
    with TableInfo<$FormEventsTable, FormEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setLogIdMeta = const VerificationMeta(
    'setLogId',
  );
  @override
  late final GeneratedColumn<String> setLogId = GeneratedColumn<String>(
    'set_log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repIndexMeta = const VerificationMeta(
    'repIndex',
  );
  @override
  late final GeneratedColumn<int> repIndex = GeneratedColumn<int>(
    'rep_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _magnitudeMeta = const VerificationMeta(
    'magnitude',
  );
  @override
  late final GeneratedColumn<double> magnitude = GeneratedColumn<double>(
    'magnitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
    'at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    setLogId,
    repIndex,
    ruleId,
    severity,
    magnitude,
    atMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'form_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<FormEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('set_log_id')) {
      context.handle(
        _setLogIdMeta,
        setLogId.isAcceptableOrUnknown(data['set_log_id']!, _setLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setLogIdMeta);
    }
    if (data.containsKey('rep_index')) {
      context.handle(
        _repIndexMeta,
        repIndex.isAcceptableOrUnknown(data['rep_index']!, _repIndexMeta),
      );
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('magnitude')) {
      context.handle(
        _magnitudeMeta,
        magnitude.isAcceptableOrUnknown(data['magnitude']!, _magnitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_magnitudeMeta);
    }
    if (data.containsKey('at_ms')) {
      context.handle(
        _atMsMeta,
        atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta),
      );
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FormEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      setLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_log_id'],
      )!,
      repIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rep_index'],
      ),
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      magnitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}magnitude'],
      )!,
      atMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_ms'],
      )!,
    );
  }

  @override
  $FormEventsTable createAlias(String alias) {
    return $FormEventsTable(attachedDatabase, alias);
  }
}

class FormEventRow extends DataClass implements Insertable<FormEventRow> {
  final String id;
  final String setLogId;
  final int? repIndex;

  /// Rule id from the exercise catalog, e.g. squat_depth.
  final String ruleId;
  final String severity;
  final double magnitude;
  final int atMs;
  const FormEventRow({
    required this.id,
    required this.setLogId,
    this.repIndex,
    required this.ruleId,
    required this.severity,
    required this.magnitude,
    required this.atMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_log_id'] = Variable<String>(setLogId);
    if (!nullToAbsent || repIndex != null) {
      map['rep_index'] = Variable<int>(repIndex);
    }
    map['rule_id'] = Variable<String>(ruleId);
    map['severity'] = Variable<String>(severity);
    map['magnitude'] = Variable<double>(magnitude);
    map['at_ms'] = Variable<int>(atMs);
    return map;
  }

  FormEventsCompanion toCompanion(bool nullToAbsent) {
    return FormEventsCompanion(
      id: Value(id),
      setLogId: Value(setLogId),
      repIndex: repIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(repIndex),
      ruleId: Value(ruleId),
      severity: Value(severity),
      magnitude: Value(magnitude),
      atMs: Value(atMs),
    );
  }

  factory FormEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormEventRow(
      id: serializer.fromJson<String>(json['id']),
      setLogId: serializer.fromJson<String>(json['setLogId']),
      repIndex: serializer.fromJson<int?>(json['repIndex']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      severity: serializer.fromJson<String>(json['severity']),
      magnitude: serializer.fromJson<double>(json['magnitude']),
      atMs: serializer.fromJson<int>(json['atMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setLogId': serializer.toJson<String>(setLogId),
      'repIndex': serializer.toJson<int?>(repIndex),
      'ruleId': serializer.toJson<String>(ruleId),
      'severity': serializer.toJson<String>(severity),
      'magnitude': serializer.toJson<double>(magnitude),
      'atMs': serializer.toJson<int>(atMs),
    };
  }

  FormEventRow copyWith({
    String? id,
    String? setLogId,
    Value<int?> repIndex = const Value.absent(),
    String? ruleId,
    String? severity,
    double? magnitude,
    int? atMs,
  }) => FormEventRow(
    id: id ?? this.id,
    setLogId: setLogId ?? this.setLogId,
    repIndex: repIndex.present ? repIndex.value : this.repIndex,
    ruleId: ruleId ?? this.ruleId,
    severity: severity ?? this.severity,
    magnitude: magnitude ?? this.magnitude,
    atMs: atMs ?? this.atMs,
  );
  FormEventRow copyWithCompanion(FormEventsCompanion data) {
    return FormEventRow(
      id: data.id.present ? data.id.value : this.id,
      setLogId: data.setLogId.present ? data.setLogId.value : this.setLogId,
      repIndex: data.repIndex.present ? data.repIndex.value : this.repIndex,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      severity: data.severity.present ? data.severity.value : this.severity,
      magnitude: data.magnitude.present ? data.magnitude.value : this.magnitude,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormEventRow(')
          ..write('id: $id, ')
          ..write('setLogId: $setLogId, ')
          ..write('repIndex: $repIndex, ')
          ..write('ruleId: $ruleId, ')
          ..write('severity: $severity, ')
          ..write('magnitude: $magnitude, ')
          ..write('atMs: $atMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, setLogId, repIndex, ruleId, severity, magnitude, atMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormEventRow &&
          other.id == this.id &&
          other.setLogId == this.setLogId &&
          other.repIndex == this.repIndex &&
          other.ruleId == this.ruleId &&
          other.severity == this.severity &&
          other.magnitude == this.magnitude &&
          other.atMs == this.atMs);
}

class FormEventsCompanion extends UpdateCompanion<FormEventRow> {
  final Value<String> id;
  final Value<String> setLogId;
  final Value<int?> repIndex;
  final Value<String> ruleId;
  final Value<String> severity;
  final Value<double> magnitude;
  final Value<int> atMs;
  final Value<int> rowid;
  const FormEventsCompanion({
    this.id = const Value.absent(),
    this.setLogId = const Value.absent(),
    this.repIndex = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.severity = const Value.absent(),
    this.magnitude = const Value.absent(),
    this.atMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormEventsCompanion.insert({
    required String id,
    required String setLogId,
    this.repIndex = const Value.absent(),
    required String ruleId,
    required String severity,
    required double magnitude,
    required int atMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       setLogId = Value(setLogId),
       ruleId = Value(ruleId),
       severity = Value(severity),
       magnitude = Value(magnitude),
       atMs = Value(atMs);
  static Insertable<FormEventRow> custom({
    Expression<String>? id,
    Expression<String>? setLogId,
    Expression<int>? repIndex,
    Expression<String>? ruleId,
    Expression<String>? severity,
    Expression<double>? magnitude,
    Expression<int>? atMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setLogId != null) 'set_log_id': setLogId,
      if (repIndex != null) 'rep_index': repIndex,
      if (ruleId != null) 'rule_id': ruleId,
      if (severity != null) 'severity': severity,
      if (magnitude != null) 'magnitude': magnitude,
      if (atMs != null) 'at_ms': atMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? setLogId,
    Value<int?>? repIndex,
    Value<String>? ruleId,
    Value<String>? severity,
    Value<double>? magnitude,
    Value<int>? atMs,
    Value<int>? rowid,
  }) {
    return FormEventsCompanion(
      id: id ?? this.id,
      setLogId: setLogId ?? this.setLogId,
      repIndex: repIndex ?? this.repIndex,
      ruleId: ruleId ?? this.ruleId,
      severity: severity ?? this.severity,
      magnitude: magnitude ?? this.magnitude,
      atMs: atMs ?? this.atMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setLogId.present) {
      map['set_log_id'] = Variable<String>(setLogId.value);
    }
    if (repIndex.present) {
      map['rep_index'] = Variable<int>(repIndex.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (magnitude.present) {
      map['magnitude'] = Variable<double>(magnitude.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormEventsCompanion(')
          ..write('id: $id, ')
          ..write('setLogId: $setLogId, ')
          ..write('repIndex: $repIndex, ')
          ..write('ruleId: $ruleId, ')
          ..write('severity: $severity, ')
          ..write('magnitude: $magnitude, ')
          ..write('atMs: $atMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalRecordsTable extends PersonalRecords
    with TableInfo<$PersonalRecordsTable, PersonalRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pushedAt = GeneratedColumn<DateTime>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievedAtMeta = const VerificationMeta(
    'achievedAt',
  );
  @override
  late final GeneratedColumn<DateTime> achievedAt = GeneratedColumn<DateTime>(
    'achieved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    exerciseId,
    kind,
    value,
    achievedAt,
    sessionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('achieved_at')) {
      context.handle(
        _achievedAtMeta,
        achievedAt.isAcceptableOrUnknown(data['achieved_at']!, _achievedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_achievedAtMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalRecordRow(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pushed_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      achievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}achieved_at'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
    );
  }

  @override
  $PersonalRecordsTable createAlias(String alias) {
    return $PersonalRecordsTable(attachedDatabase, alias);
  }
}

class PersonalRecordRow extends DataClass
    implements Insertable<PersonalRecordRow> {
  final DateTime updatedAt;

  /// Soft delete. A hard delete is invisible to peers, so rows are tombstoned
  /// and reaped after the change has propagated.
  final DateTime? deletedAt;

  /// Which install wrote this revision; used for last-writer-wins tie-breaks.
  final String deviceId;

  /// The [updatedAt] the server last acknowledged, or null for never.
  ///
  /// The one sync column that is **not** replicated: it is this install's
  /// record of what has been uploaded, and it is what makes the dirty set
  /// exact. A row is pending while `pushed_at IS NULL OR pushed_at <
  /// updated_at`, so the only thing a local write has to remember is to bump
  /// `updated_at` — which it already must do for the conflict rule, rather
  /// than being a second piece of bookkeeping to forget.
  ///
  /// The alternative, comparing `updated_at` against a single watermark,
  /// silently drops an edit made by a device whose clock is behind. Added in
  /// v2: the three columns v1 chose were the right ones for resolving a
  /// conflict and not enough for noticing there was something to resolve.
  final DateTime? pushedAt;
  final String id;
  final String exerciseId;

  /// maxWeight | estimated1Rm | maxVolume | maxHold
  final String kind;
  final double value;
  final DateTime achievedAt;
  final String? sessionId;
  const PersonalRecordRow({
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.pushedAt,
    required this.id,
    required this.exerciseId,
    required this.kind,
    required this.value,
    required this.achievedAt,
    this.sessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<DateTime>(pushedAt);
    }
    map['id'] = Variable<String>(id);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<double>(value);
    map['achieved_at'] = Variable<DateTime>(achievedAt);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    return map;
  }

  PersonalRecordsCompanion toCompanion(bool nullToAbsent) {
    return PersonalRecordsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
      id: Value(id),
      exerciseId: Value(exerciseId),
      kind: Value(kind),
      value: Value(value),
      achievedAt: Value(achievedAt),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
    );
  }

  factory PersonalRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalRecordRow(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      pushedAt: serializer.fromJson<DateTime?>(json['pushedAt']),
      id: serializer.fromJson<String>(json['id']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<double>(json['value']),
      achievedAt: serializer.fromJson<DateTime>(json['achievedAt']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'pushedAt': serializer.toJson<DateTime?>(pushedAt),
      'id': serializer.toJson<String>(id),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<double>(value),
      'achievedAt': serializer.toJson<DateTime>(achievedAt),
      'sessionId': serializer.toJson<String?>(sessionId),
    };
  }

  PersonalRecordRow copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<DateTime?> pushedAt = const Value.absent(),
    String? id,
    String? exerciseId,
    String? kind,
    double? value,
    DateTime? achievedAt,
    Value<String?> sessionId = const Value.absent(),
  }) => PersonalRecordRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    kind: kind ?? this.kind,
    value: value ?? this.value,
    achievedAt: achievedAt ?? this.achievedAt,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
  );
  PersonalRecordRow copyWithCompanion(PersonalRecordsCompanion data) {
    return PersonalRecordRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      achievedAt: data.achievedAt.present
          ? data.achievedAt.value
          : this.achievedAt,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecordRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    deviceId,
    pushedAt,
    id,
    exerciseId,
    kind,
    value,
    achievedAt,
    sessionId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalRecordRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.pushedAt == this.pushedAt &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.achievedAt == this.achievedAt &&
          other.sessionId == this.sessionId);
}

class PersonalRecordsCompanion extends UpdateCompanion<PersonalRecordRow> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<DateTime?> pushedAt;
  final Value<String> id;
  final Value<String> exerciseId;
  final Value<String> kind;
  final Value<double> value;
  final Value<DateTime> achievedAt;
  final Value<String?> sessionId;
  final Value<int> rowid;
  const PersonalRecordsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pushedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalRecordsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.pushedAt = const Value.absent(),
    required String id,
    required String exerciseId,
    required String kind,
    required double value,
    required DateTime achievedAt,
    this.sessionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       id = Value(id),
       exerciseId = Value(exerciseId),
       kind = Value(kind),
       value = Value(value),
       achievedAt = Value(achievedAt);
  static Insertable<PersonalRecordRow> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? pushedAt,
    Expression<String>? id,
    Expression<String>? exerciseId,
    Expression<String>? kind,
    Expression<double>? value,
    Expression<DateTime>? achievedAt,
    Expression<String>? sessionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (pushedAt != null) 'pushed_at': pushedAt,
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (sessionId != null) 'session_id': sessionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalRecordsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<DateTime?>? pushedAt,
    Value<String>? id,
    Value<String>? exerciseId,
    Value<String>? kind,
    Value<double>? value,
    Value<DateTime>? achievedAt,
    Value<String?>? sessionId,
    Value<int>? rowid,
  }) {
    return PersonalRecordsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      pushedAt: pushedAt ?? this.pushedAt,
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      achievedAt: achievedAt ?? this.achievedAt,
      sessionId: sessionId ?? this.sessionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<DateTime>(pushedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<DateTime>(achievedAt.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecordsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('pushedAt: $pushedAt, ')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('sessionId: $sessionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [targetTable, cursor, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {targetTable};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  /// Which table this cursor is for.
  ///
  /// Not `tableName`: drift's own [Table] declares that getter for naming a
  /// table, and the clash is invisible in the app's generated code and fails
  /// to compile only in the generated *migration* helper, where the column
  /// name is turned back into a getter.
  final String targetTable;

  /// The server's own replication stamp, kept opaque.
  ///
  /// Deliberately not parsed here. It is the server's ordering, not a time
  /// this app can reason about, and a client that read it as a date would
  /// start comparing it against its own clock.
  final String? cursor;

  /// When a sync last finished this table, for telling the user.
  final DateTime? syncedAt;
  const SyncStateRow({required this.targetTable, this.cursor, this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['target_table'] = Variable<String>(targetTable);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      targetTable: Value(targetTable),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      targetTable: serializer.fromJson<String>(json['targetTable']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'targetTable': serializer.toJson<String>(targetTable),
      'cursor': serializer.toJson<String?>(cursor),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SyncStateRow copyWith({
    String? targetTable,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => SyncStateRow(
    targetTable: targetTable ?? this.targetTable,
    cursor: cursor.present ? cursor.value : this.cursor,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('targetTable: $targetTable, ')
          ..write('cursor: $cursor, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(targetTable, cursor, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.targetTable == this.targetTable &&
          other.cursor == this.cursor &&
          other.syncedAt == this.syncedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> targetTable;
  final Value<String?> cursor;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.targetTable = const Value.absent(),
    this.cursor = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String targetTable,
    this.cursor = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : targetTable = Value(targetTable);
  static Insertable<SyncStateRow> custom({
    Expression<String>? targetTable,
    Expression<String>? cursor,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (targetTable != null) 'target_table': targetTable,
      if (cursor != null) 'cursor': cursor,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? targetTable,
    Value<String?>? cursor,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      targetTable: targetTable ?? this.targetTable,
      cursor: cursor ?? this.cursor,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('targetTable: $targetTable, ')
          ..write('cursor: $cursor, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalIdentityTable extends LocalIdentity
    with TableInfo<$LocalIdentityTable, LocalIdentityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalIdentityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('this_device'),
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _claimedAtMeta = const VerificationMeta(
    'claimedAt',
  );
  @override
  late final GeneratedColumn<DateTime> claimedAt = GeneratedColumn<DateTime>(
    'claimed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    installId,
    userId,
    email,
    claimedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_identity';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalIdentityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('claimed_at')) {
      context.handle(
        _claimedAtMeta,
        claimedAt.isAcceptableOrUnknown(data['claimed_at']!, _claimedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalIdentityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalIdentityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      claimedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}claimed_at'],
      ),
    );
  }

  @override
  $LocalIdentityTable createAlias(String alias) {
    return $LocalIdentityTable(attachedDatabase, alias);
  }
}

class LocalIdentityRow extends DataClass
    implements Insertable<LocalIdentityRow> {
  /// One row, ever. The default is spelled out rather than named, because
  /// `drift_dev schema dump` copies a column's default expression into a
  /// file of its own to run it, where a private constant does not exist —
  /// and the export then falls back to static analysis for the whole
  /// database.
  final String id;
  final String installId;

  /// Whose training this database holds, once somebody has signed in.
  ///
  /// Not "who is signed in right now" — that question is answered by
  /// whether there is a session in the keychain. This outlives a sign-out
  /// on purpose: the rows on this device belong to that account, and
  /// letting a second account sign in over them would push one person's
  /// training into another person's account.
  final String? userId;
  final String? email;
  final DateTime? claimedAt;
  const LocalIdentityRow({
    required this.id,
    required this.installId,
    this.userId,
    this.email,
    this.claimedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['install_id'] = Variable<String>(installId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || claimedAt != null) {
      map['claimed_at'] = Variable<DateTime>(claimedAt);
    }
    return map;
  }

  LocalIdentityCompanion toCompanion(bool nullToAbsent) {
    return LocalIdentityCompanion(
      id: Value(id),
      installId: Value(installId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      claimedAt: claimedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedAt),
    );
  }

  factory LocalIdentityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalIdentityRow(
      id: serializer.fromJson<String>(json['id']),
      installId: serializer.fromJson<String>(json['installId']),
      userId: serializer.fromJson<String?>(json['userId']),
      email: serializer.fromJson<String?>(json['email']),
      claimedAt: serializer.fromJson<DateTime?>(json['claimedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'installId': serializer.toJson<String>(installId),
      'userId': serializer.toJson<String?>(userId),
      'email': serializer.toJson<String?>(email),
      'claimedAt': serializer.toJson<DateTime?>(claimedAt),
    };
  }

  LocalIdentityRow copyWith({
    String? id,
    String? installId,
    Value<String?> userId = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<DateTime?> claimedAt = const Value.absent(),
  }) => LocalIdentityRow(
    id: id ?? this.id,
    installId: installId ?? this.installId,
    userId: userId.present ? userId.value : this.userId,
    email: email.present ? email.value : this.email,
    claimedAt: claimedAt.present ? claimedAt.value : this.claimedAt,
  );
  LocalIdentityRow copyWithCompanion(LocalIdentityCompanion data) {
    return LocalIdentityRow(
      id: data.id.present ? data.id.value : this.id,
      installId: data.installId.present ? data.installId.value : this.installId,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      claimedAt: data.claimedAt.present ? data.claimedAt.value : this.claimedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalIdentityRow(')
          ..write('id: $id, ')
          ..write('installId: $installId, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('claimedAt: $claimedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, installId, userId, email, claimedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalIdentityRow &&
          other.id == this.id &&
          other.installId == this.installId &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.claimedAt == this.claimedAt);
}

class LocalIdentityCompanion extends UpdateCompanion<LocalIdentityRow> {
  final Value<String> id;
  final Value<String> installId;
  final Value<String?> userId;
  final Value<String?> email;
  final Value<DateTime?> claimedAt;
  final Value<int> rowid;
  const LocalIdentityCompanion({
    this.id = const Value.absent(),
    this.installId = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.claimedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalIdentityCompanion.insert({
    this.id = const Value.absent(),
    required String installId,
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.claimedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : installId = Value(installId);
  static Insertable<LocalIdentityRow> custom({
    Expression<String>? id,
    Expression<String>? installId,
    Expression<String>? userId,
    Expression<String>? email,
    Expression<DateTime>? claimedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (installId != null) 'install_id': installId,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (claimedAt != null) 'claimed_at': claimedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalIdentityCompanion copyWith({
    Value<String>? id,
    Value<String>? installId,
    Value<String?>? userId,
    Value<String?>? email,
    Value<DateTime?>? claimedAt,
    Value<int>? rowid,
  }) {
    return LocalIdentityCompanion(
      id: id ?? this.id,
      installId: installId ?? this.installId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      claimedAt: claimedAt ?? this.claimedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (claimedAt.present) {
      map['claimed_at'] = Variable<DateTime>(claimedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalIdentityCompanion(')
          ..write('id: $id, ')
          ..write('installId: $installId, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('claimedAt: $claimedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $PlanDaysTable planDays = $PlanDaysTable(this);
  late final $PlanExercisesTable planExercises = $PlanExercisesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SetLogsTable setLogs = $SetLogsTable(this);
  late final $RepLogsTable repLogs = $RepLogsTable(this);
  late final $FormEventsTable formEvents = $FormEventsTable(this);
  late final $PersonalRecordsTable personalRecords = $PersonalRecordsTable(
    this,
  );
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $LocalIdentityTable localIdentity = $LocalIdentityTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    plans,
    planDays,
    planExercises,
    sessions,
    setLogs,
    repLogs,
    formEvents,
    personalRecords,
    syncState,
    localIdentity,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<DateTime?> pushedAt,
      required String id,
      required String goal,
      required int daysPerWeek,
      required int sessionMinutes,
      required String level,
      Value<int?> ageYears,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<String?> sex,
      Value<String> injuries,
      Value<String?> injuryNotes,
      required String location,
      Value<String> equipment,
      required String coachPersonality,
      Value<String> runDays,
      Value<DateTime?> disclaimerAcceptedAt,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<DateTime?> pushedAt,
      Value<String> id,
      Value<String> goal,
      Value<int> daysPerWeek,
      Value<int> sessionMinutes,
      Value<String> level,
      Value<int?> ageYears,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<String?> sex,
      Value<String> injuries,
      Value<String?> injuryNotes,
      Value<String> location,
      Value<String> equipment,
      Value<String> coachPersonality,
      Value<String> runDays,
      Value<DateTime?> disclaimerAcceptedAt,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionMinutes => $composableBuilder(
    column: $table.sessionMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ageYears => $composableBuilder(
    column: $table.ageYears,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get injuries => $composableBuilder(
    column: $table.injuries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get injuryNotes => $composableBuilder(
    column: $table.injuryNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coachPersonality => $composableBuilder(
    column: $table.coachPersonality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runDays => $composableBuilder(
    column: $table.runDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get disclaimerAcceptedAt => $composableBuilder(
    column: $table.disclaimerAcceptedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionMinutes => $composableBuilder(
    column: $table.sessionMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ageYears => $composableBuilder(
    column: $table.ageYears,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get injuries => $composableBuilder(
    column: $table.injuries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get injuryNotes => $composableBuilder(
    column: $table.injuryNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coachPersonality => $composableBuilder(
    column: $table.coachPersonality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runDays => $composableBuilder(
    column: $table.runDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get disclaimerAcceptedAt => $composableBuilder(
    column: $table.disclaimerAcceptedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessionMinutes => $composableBuilder(
    column: $table.sessionMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get ageYears =>
      $composableBuilder(column: $table.ageYears, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get injuries =>
      $composableBuilder(column: $table.injuries, builder: (column) => column);

  GeneratedColumn<String> get injuryNotes => $composableBuilder(
    column: $table.injuryNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get coachPersonality => $composableBuilder(
    column: $table.coachPersonality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get runDays =>
      $composableBuilder(column: $table.runDays, builder: (column) => column);

  GeneratedColumn<DateTime> get disclaimerAcceptedAt => $composableBuilder(
    column: $table.disclaimerAcceptedAt,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> pushedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<int> daysPerWeek = const Value.absent(),
                Value<int> sessionMinutes = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<int?> ageYears = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<String> injuries = const Value.absent(),
                Value<String?> injuryNotes = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String> coachPersonality = const Value.absent(),
                Value<String> runDays = const Value.absent(),
                Value<DateTime?> disclaimerAcceptedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                goal: goal,
                daysPerWeek: daysPerWeek,
                sessionMinutes: sessionMinutes,
                level: level,
                ageYears: ageYears,
                heightCm: heightCm,
                weightKg: weightKg,
                sex: sex,
                injuries: injuries,
                injuryNotes: injuryNotes,
                location: location,
                equipment: equipment,
                coachPersonality: coachPersonality,
                runDays: runDays,
                disclaimerAcceptedAt: disclaimerAcceptedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<DateTime?> pushedAt = const Value.absent(),
                required String id,
                required String goal,
                required int daysPerWeek,
                required int sessionMinutes,
                required String level,
                Value<int?> ageYears = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<String> injuries = const Value.absent(),
                Value<String?> injuryNotes = const Value.absent(),
                required String location,
                Value<String> equipment = const Value.absent(),
                required String coachPersonality,
                Value<String> runDays = const Value.absent(),
                Value<DateTime?> disclaimerAcceptedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                goal: goal,
                daysPerWeek: daysPerWeek,
                sessionMinutes: sessionMinutes,
                level: level,
                ageYears: ageYears,
                heightCm: heightCm,
                weightKg: weightKg,
                sex: sex,
                injuries: injuries,
                injuryNotes: injuryNotes,
                location: location,
                equipment: equipment,
                coachPersonality: coachPersonality,
                runDays: runDays,
                disclaimerAcceptedAt: disclaimerAcceptedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$PlansTableCreateCompanionBuilder =
    PlansCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<DateTime?> pushedAt,
      required String id,
      required String profileId,
      required String templateId,
      required String goal,
      required DateTime createdAt,
      Value<bool> isActive,
      Value<String> runDays,
      Value<String> runSuggestionKeys,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$PlansTableUpdateCompanionBuilder =
    PlansCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<DateTime?> pushedAt,
      Value<String> id,
      Value<String> profileId,
      Value<String> templateId,
      Value<String> goal,
      Value<DateTime> createdAt,
      Value<bool> isActive,
      Value<String> runDays,
      Value<String> runSuggestionKeys,
      Value<String> notes,
      Value<int> rowid,
    });

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runDays => $composableBuilder(
    column: $table.runDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runSuggestionKeys => $composableBuilder(
    column: $table.runSuggestionKeys,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runDays => $composableBuilder(
    column: $table.runDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runSuggestionKeys => $composableBuilder(
    column: $table.runSuggestionKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get runDays =>
      $composableBuilder(column: $table.runDays, builder: (column) => column);

  GeneratedColumn<String> get runSuggestionKeys => $composableBuilder(
    column: $table.runSuggestionKeys,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          PlanRow,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (PlanRow, BaseReferences<_$AppDatabase, $PlansTable, PlanRow>),
          PlanRow,
          PrefetchHooks Function()
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> pushedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> runDays = const Value.absent(),
                Value<String> runSuggestionKeys = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                profileId: profileId,
                templateId: templateId,
                goal: goal,
                createdAt: createdAt,
                isActive: isActive,
                runDays: runDays,
                runSuggestionKeys: runSuggestionKeys,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<DateTime?> pushedAt = const Value.absent(),
                required String id,
                required String profileId,
                required String templateId,
                required String goal,
                required DateTime createdAt,
                Value<bool> isActive = const Value.absent(),
                Value<String> runDays = const Value.absent(),
                Value<String> runSuggestionKeys = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                profileId: profileId,
                templateId: templateId,
                goal: goal,
                createdAt: createdAt,
                isActive: isActive,
                runDays: runDays,
                runSuggestionKeys: runSuggestionKeys,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      PlanRow,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (PlanRow, BaseReferences<_$AppDatabase, $PlansTable, PlanRow>),
      PlanRow,
      PrefetchHooks Function()
    >;
typedef $$PlanDaysTableCreateCompanionBuilder =
    PlanDaysCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<DateTime?> pushedAt,
      required String id,
      required String planId,
      required int weekday,
      required String dayType,
      required String labelKey,
      Value<bool> precedesRunDay,
      Value<int> rowid,
    });
typedef $$PlanDaysTableUpdateCompanionBuilder =
    PlanDaysCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<DateTime?> pushedAt,
      Value<String> id,
      Value<String> planId,
      Value<int> weekday,
      Value<String> dayType,
      Value<String> labelKey,
      Value<bool> precedesRunDay,
      Value<int> rowid,
    });

class $$PlanDaysTableFilterComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayType => $composableBuilder(
    column: $table.dayType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelKey => $composableBuilder(
    column: $table.labelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get precedesRunDay => $composableBuilder(
    column: $table.precedesRunDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayType => $composableBuilder(
    column: $table.dayType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelKey => $composableBuilder(
    column: $table.labelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get precedesRunDay => $composableBuilder(
    column: $table.precedesRunDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get dayType =>
      $composableBuilder(column: $table.dayType, builder: (column) => column);

  GeneratedColumn<String> get labelKey =>
      $composableBuilder(column: $table.labelKey, builder: (column) => column);

  GeneratedColumn<bool> get precedesRunDay => $composableBuilder(
    column: $table.precedesRunDay,
    builder: (column) => column,
  );
}

class $$PlanDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanDaysTable,
          PlanDayRow,
          $$PlanDaysTableFilterComposer,
          $$PlanDaysTableOrderingComposer,
          $$PlanDaysTableAnnotationComposer,
          $$PlanDaysTableCreateCompanionBuilder,
          $$PlanDaysTableUpdateCompanionBuilder,
          (
            PlanDayRow,
            BaseReferences<_$AppDatabase, $PlanDaysTable, PlanDayRow>,
          ),
          PlanDayRow,
          PrefetchHooks Function()
        > {
  $$PlanDaysTableTableManager(_$AppDatabase db, $PlanDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> pushedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<String> dayType = const Value.absent(),
                Value<String> labelKey = const Value.absent(),
                Value<bool> precedesRunDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanDaysCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                planId: planId,
                weekday: weekday,
                dayType: dayType,
                labelKey: labelKey,
                precedesRunDay: precedesRunDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<DateTime?> pushedAt = const Value.absent(),
                required String id,
                required String planId,
                required int weekday,
                required String dayType,
                required String labelKey,
                Value<bool> precedesRunDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanDaysCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                planId: planId,
                weekday: weekday,
                dayType: dayType,
                labelKey: labelKey,
                precedesRunDay: precedesRunDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanDaysTable,
      PlanDayRow,
      $$PlanDaysTableFilterComposer,
      $$PlanDaysTableOrderingComposer,
      $$PlanDaysTableAnnotationComposer,
      $$PlanDaysTableCreateCompanionBuilder,
      $$PlanDaysTableUpdateCompanionBuilder,
      (PlanDayRow, BaseReferences<_$AppDatabase, $PlanDaysTable, PlanDayRow>),
      PlanDayRow,
      PrefetchHooks Function()
    >;
typedef $$PlanExercisesTableCreateCompanionBuilder =
    PlanExercisesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<DateTime?> pushedAt,
      required String id,
      required String planDayId,
      required int orderIndex,
      required String exerciseId,
      required String slotPattern,
      required String priority,
      required int targetSets,
      required int templateSets,
      required String metric,
      required int restSeconds,
      required double secondsPerRep,
      Value<int?> targetRepsMin,
      Value<int?> targetRepsMax,
      Value<int?> targetHoldSeconds,
      Value<double?> targetWeightKg,
      Value<int> rowid,
    });
typedef $$PlanExercisesTableUpdateCompanionBuilder =
    PlanExercisesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<DateTime?> pushedAt,
      Value<String> id,
      Value<String> planDayId,
      Value<int> orderIndex,
      Value<String> exerciseId,
      Value<String> slotPattern,
      Value<String> priority,
      Value<int> targetSets,
      Value<int> templateSets,
      Value<String> metric,
      Value<int> restSeconds,
      Value<double> secondsPerRep,
      Value<int?> targetRepsMin,
      Value<int?> targetRepsMax,
      Value<int?> targetHoldSeconds,
      Value<double?> targetWeightKg,
      Value<int> rowid,
    });

class $$PlanExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planDayId => $composableBuilder(
    column: $table.planDayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slotPattern => $composableBuilder(
    column: $table.slotPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateSets => $composableBuilder(
    column: $table.templateSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get secondsPerRep => $composableBuilder(
    column: $table.secondsPerRep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetRepsMin => $composableBuilder(
    column: $table.targetRepsMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetRepsMax => $composableBuilder(
    column: $table.targetRepsMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetHoldSeconds => $composableBuilder(
    column: $table.targetHoldSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planDayId => $composableBuilder(
    column: $table.planDayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slotPattern => $composableBuilder(
    column: $table.slotPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateSets => $composableBuilder(
    column: $table.templateSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get secondsPerRep => $composableBuilder(
    column: $table.secondsPerRep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetRepsMin => $composableBuilder(
    column: $table.targetRepsMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetRepsMax => $composableBuilder(
    column: $table.targetRepsMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetHoldSeconds => $composableBuilder(
    column: $table.targetHoldSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get slotPattern => $composableBuilder(
    column: $table.slotPattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get templateSets => $composableBuilder(
    column: $table.templateSets,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get secondsPerRep => $composableBuilder(
    column: $table.secondsPerRep,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetRepsMin => $composableBuilder(
    column: $table.targetRepsMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetRepsMax => $composableBuilder(
    column: $table.targetRepsMax,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetHoldSeconds => $composableBuilder(
    column: $table.targetHoldSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );
}

class $$PlanExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanExercisesTable,
          PlanExerciseRow,
          $$PlanExercisesTableFilterComposer,
          $$PlanExercisesTableOrderingComposer,
          $$PlanExercisesTableAnnotationComposer,
          $$PlanExercisesTableCreateCompanionBuilder,
          $$PlanExercisesTableUpdateCompanionBuilder,
          (
            PlanExerciseRow,
            BaseReferences<_$AppDatabase, $PlanExercisesTable, PlanExerciseRow>,
          ),
          PlanExerciseRow,
          PrefetchHooks Function()
        > {
  $$PlanExercisesTableTableManager(_$AppDatabase db, $PlanExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> pushedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> planDayId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> slotPattern = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int> templateSets = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<double> secondsPerRep = const Value.absent(),
                Value<int?> targetRepsMin = const Value.absent(),
                Value<int?> targetRepsMax = const Value.absent(),
                Value<int?> targetHoldSeconds = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanExercisesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                planDayId: planDayId,
                orderIndex: orderIndex,
                exerciseId: exerciseId,
                slotPattern: slotPattern,
                priority: priority,
                targetSets: targetSets,
                templateSets: templateSets,
                metric: metric,
                restSeconds: restSeconds,
                secondsPerRep: secondsPerRep,
                targetRepsMin: targetRepsMin,
                targetRepsMax: targetRepsMax,
                targetHoldSeconds: targetHoldSeconds,
                targetWeightKg: targetWeightKg,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<DateTime?> pushedAt = const Value.absent(),
                required String id,
                required String planDayId,
                required int orderIndex,
                required String exerciseId,
                required String slotPattern,
                required String priority,
                required int targetSets,
                required int templateSets,
                required String metric,
                required int restSeconds,
                required double secondsPerRep,
                Value<int?> targetRepsMin = const Value.absent(),
                Value<int?> targetRepsMax = const Value.absent(),
                Value<int?> targetHoldSeconds = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanExercisesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                planDayId: planDayId,
                orderIndex: orderIndex,
                exerciseId: exerciseId,
                slotPattern: slotPattern,
                priority: priority,
                targetSets: targetSets,
                templateSets: templateSets,
                metric: metric,
                restSeconds: restSeconds,
                secondsPerRep: secondsPerRep,
                targetRepsMin: targetRepsMin,
                targetRepsMax: targetRepsMax,
                targetHoldSeconds: targetHoldSeconds,
                targetWeightKg: targetWeightKg,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanExercisesTable,
      PlanExerciseRow,
      $$PlanExercisesTableFilterComposer,
      $$PlanExercisesTableOrderingComposer,
      $$PlanExercisesTableAnnotationComposer,
      $$PlanExercisesTableCreateCompanionBuilder,
      $$PlanExercisesTableUpdateCompanionBuilder,
      (
        PlanExerciseRow,
        BaseReferences<_$AppDatabase, $PlanExercisesTable, PlanExerciseRow>,
      ),
      PlanExerciseRow,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<DateTime?> pushedAt,
      required String id,
      Value<String?> planDayId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<String?> rating,
      Value<bool> painReported,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<DateTime?> pushedAt,
      Value<String> id,
      Value<String?> planDayId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String?> rating,
      Value<bool> painReported,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planDayId => $composableBuilder(
    column: $table.planDayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get painReported => $composableBuilder(
    column: $table.painReported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planDayId => $composableBuilder(
    column: $table.planDayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get painReported => $composableBuilder(
    column: $table.painReported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<bool> get painReported => $composableBuilder(
    column: $table.painReported,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> pushedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> planDayId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<bool> painReported = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                planDayId: planDayId,
                startedAt: startedAt,
                endedAt: endedAt,
                rating: rating,
                painReported: painReported,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<DateTime?> pushedAt = const Value.absent(),
                required String id,
                Value<String?> planDayId = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<bool> painReported = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                planDayId: planDayId,
                startedAt: startedAt,
                endedAt: endedAt,
                rating: rating,
                painReported: painReported,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$SetLogsTableCreateCompanionBuilder =
    SetLogsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<DateTime?> pushedAt,
      required String id,
      required String sessionId,
      Value<String?> planExerciseId,
      required String exerciseId,
      required int setIndex,
      required int reps,
      Value<double?> weightKg,
      Value<int?> holdSeconds,
      Value<double?> formScore,
      Value<String?> cameraAngle,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$SetLogsTableUpdateCompanionBuilder =
    SetLogsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<DateTime?> pushedAt,
      Value<String> id,
      Value<String> sessionId,
      Value<String?> planExerciseId,
      Value<String> exerciseId,
      Value<int> setIndex,
      Value<int> reps,
      Value<double?> weightKg,
      Value<int?> holdSeconds,
      Value<double?> formScore,
      Value<String?> cameraAngle,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

class $$SetLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planExerciseId => $composableBuilder(
    column: $table.planExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get holdSeconds => $composableBuilder(
    column: $table.holdSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get formScore => $composableBuilder(
    column: $table.formScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cameraAngle => $composableBuilder(
    column: $table.cameraAngle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SetLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planExerciseId => $composableBuilder(
    column: $table.planExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get holdSeconds => $composableBuilder(
    column: $table.holdSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get formScore => $composableBuilder(
    column: $table.formScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cameraAngle => $composableBuilder(
    column: $table.cameraAngle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get planExerciseId => $composableBuilder(
    column: $table.planExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get holdSeconds => $composableBuilder(
    column: $table.holdSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get formScore =>
      $composableBuilder(column: $table.formScore, builder: (column) => column);

  GeneratedColumn<String> get cameraAngle => $composableBuilder(
    column: $table.cameraAngle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$SetLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetLogsTable,
          SetLogRow,
          $$SetLogsTableFilterComposer,
          $$SetLogsTableOrderingComposer,
          $$SetLogsTableAnnotationComposer,
          $$SetLogsTableCreateCompanionBuilder,
          $$SetLogsTableUpdateCompanionBuilder,
          (SetLogRow, BaseReferences<_$AppDatabase, $SetLogsTable, SetLogRow>),
          SetLogRow,
          PrefetchHooks Function()
        > {
  $$SetLogsTableTableManager(_$AppDatabase db, $SetLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> pushedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String?> planExerciseId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> holdSeconds = const Value.absent(),
                Value<double?> formScore = const Value.absent(),
                Value<String?> cameraAngle = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetLogsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                sessionId: sessionId,
                planExerciseId: planExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                reps: reps,
                weightKg: weightKg,
                holdSeconds: holdSeconds,
                formScore: formScore,
                cameraAngle: cameraAngle,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<DateTime?> pushedAt = const Value.absent(),
                required String id,
                required String sessionId,
                Value<String?> planExerciseId = const Value.absent(),
                required String exerciseId,
                required int setIndex,
                required int reps,
                Value<double?> weightKg = const Value.absent(),
                Value<int?> holdSeconds = const Value.absent(),
                Value<double?> formScore = const Value.absent(),
                Value<String?> cameraAngle = const Value.absent(),
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => SetLogsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                sessionId: sessionId,
                planExerciseId: planExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                reps: reps,
                weightKg: weightKg,
                holdSeconds: holdSeconds,
                formScore: formScore,
                cameraAngle: cameraAngle,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SetLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetLogsTable,
      SetLogRow,
      $$SetLogsTableFilterComposer,
      $$SetLogsTableOrderingComposer,
      $$SetLogsTableAnnotationComposer,
      $$SetLogsTableCreateCompanionBuilder,
      $$SetLogsTableUpdateCompanionBuilder,
      (SetLogRow, BaseReferences<_$AppDatabase, $SetLogsTable, SetLogRow>),
      SetLogRow,
      PrefetchHooks Function()
    >;
typedef $$RepLogsTableCreateCompanionBuilder =
    RepLogsCompanion Function({
      required String id,
      required String setLogId,
      required int repIndex,
      required bool counted,
      Value<String?> rejectionReason,
      required int durationMs,
      Value<double?> peakAngle,
      Value<double?> rangeOfMotion,
      Value<double?> formScore,
      Value<int> rowid,
    });
typedef $$RepLogsTableUpdateCompanionBuilder =
    RepLogsCompanion Function({
      Value<String> id,
      Value<String> setLogId,
      Value<int> repIndex,
      Value<bool> counted,
      Value<String?> rejectionReason,
      Value<int> durationMs,
      Value<double?> peakAngle,
      Value<double?> rangeOfMotion,
      Value<double?> formScore,
      Value<int> rowid,
    });

class $$RepLogsTableFilterComposer
    extends Composer<_$AppDatabase, $RepLogsTable> {
  $$RepLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setLogId => $composableBuilder(
    column: $table.setLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repIndex => $composableBuilder(
    column: $table.repIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get counted => $composableBuilder(
    column: $table.counted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get peakAngle => $composableBuilder(
    column: $table.peakAngle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rangeOfMotion => $composableBuilder(
    column: $table.rangeOfMotion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get formScore => $composableBuilder(
    column: $table.formScore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RepLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $RepLogsTable> {
  $$RepLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setLogId => $composableBuilder(
    column: $table.setLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repIndex => $composableBuilder(
    column: $table.repIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get counted => $composableBuilder(
    column: $table.counted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get peakAngle => $composableBuilder(
    column: $table.peakAngle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rangeOfMotion => $composableBuilder(
    column: $table.rangeOfMotion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get formScore => $composableBuilder(
    column: $table.formScore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RepLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RepLogsTable> {
  $$RepLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get setLogId =>
      $composableBuilder(column: $table.setLogId, builder: (column) => column);

  GeneratedColumn<int> get repIndex =>
      $composableBuilder(column: $table.repIndex, builder: (column) => column);

  GeneratedColumn<bool> get counted =>
      $composableBuilder(column: $table.counted, builder: (column) => column);

  GeneratedColumn<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get peakAngle =>
      $composableBuilder(column: $table.peakAngle, builder: (column) => column);

  GeneratedColumn<double> get rangeOfMotion => $composableBuilder(
    column: $table.rangeOfMotion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get formScore =>
      $composableBuilder(column: $table.formScore, builder: (column) => column);
}

class $$RepLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RepLogsTable,
          RepLogRow,
          $$RepLogsTableFilterComposer,
          $$RepLogsTableOrderingComposer,
          $$RepLogsTableAnnotationComposer,
          $$RepLogsTableCreateCompanionBuilder,
          $$RepLogsTableUpdateCompanionBuilder,
          (RepLogRow, BaseReferences<_$AppDatabase, $RepLogsTable, RepLogRow>),
          RepLogRow,
          PrefetchHooks Function()
        > {
  $$RepLogsTableTableManager(_$AppDatabase db, $RepLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RepLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RepLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RepLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> setLogId = const Value.absent(),
                Value<int> repIndex = const Value.absent(),
                Value<bool> counted = const Value.absent(),
                Value<String?> rejectionReason = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<double?> peakAngle = const Value.absent(),
                Value<double?> rangeOfMotion = const Value.absent(),
                Value<double?> formScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RepLogsCompanion(
                id: id,
                setLogId: setLogId,
                repIndex: repIndex,
                counted: counted,
                rejectionReason: rejectionReason,
                durationMs: durationMs,
                peakAngle: peakAngle,
                rangeOfMotion: rangeOfMotion,
                formScore: formScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String setLogId,
                required int repIndex,
                required bool counted,
                Value<String?> rejectionReason = const Value.absent(),
                required int durationMs,
                Value<double?> peakAngle = const Value.absent(),
                Value<double?> rangeOfMotion = const Value.absent(),
                Value<double?> formScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RepLogsCompanion.insert(
                id: id,
                setLogId: setLogId,
                repIndex: repIndex,
                counted: counted,
                rejectionReason: rejectionReason,
                durationMs: durationMs,
                peakAngle: peakAngle,
                rangeOfMotion: rangeOfMotion,
                formScore: formScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RepLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RepLogsTable,
      RepLogRow,
      $$RepLogsTableFilterComposer,
      $$RepLogsTableOrderingComposer,
      $$RepLogsTableAnnotationComposer,
      $$RepLogsTableCreateCompanionBuilder,
      $$RepLogsTableUpdateCompanionBuilder,
      (RepLogRow, BaseReferences<_$AppDatabase, $RepLogsTable, RepLogRow>),
      RepLogRow,
      PrefetchHooks Function()
    >;
typedef $$FormEventsTableCreateCompanionBuilder =
    FormEventsCompanion Function({
      required String id,
      required String setLogId,
      Value<int?> repIndex,
      required String ruleId,
      required String severity,
      required double magnitude,
      required int atMs,
      Value<int> rowid,
    });
typedef $$FormEventsTableUpdateCompanionBuilder =
    FormEventsCompanion Function({
      Value<String> id,
      Value<String> setLogId,
      Value<int?> repIndex,
      Value<String> ruleId,
      Value<String> severity,
      Value<double> magnitude,
      Value<int> atMs,
      Value<int> rowid,
    });

class $$FormEventsTableFilterComposer
    extends Composer<_$AppDatabase, $FormEventsTable> {
  $$FormEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setLogId => $composableBuilder(
    column: $table.setLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repIndex => $composableBuilder(
    column: $table.repIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get magnitude => $composableBuilder(
    column: $table.magnitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FormEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $FormEventsTable> {
  $$FormEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setLogId => $composableBuilder(
    column: $table.setLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repIndex => $composableBuilder(
    column: $table.repIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get magnitude => $composableBuilder(
    column: $table.magnitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FormEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FormEventsTable> {
  $$FormEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get setLogId =>
      $composableBuilder(column: $table.setLogId, builder: (column) => column);

  GeneratedColumn<int> get repIndex =>
      $composableBuilder(column: $table.repIndex, builder: (column) => column);

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<double> get magnitude =>
      $composableBuilder(column: $table.magnitude, builder: (column) => column);

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);
}

class $$FormEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FormEventsTable,
          FormEventRow,
          $$FormEventsTableFilterComposer,
          $$FormEventsTableOrderingComposer,
          $$FormEventsTableAnnotationComposer,
          $$FormEventsTableCreateCompanionBuilder,
          $$FormEventsTableUpdateCompanionBuilder,
          (
            FormEventRow,
            BaseReferences<_$AppDatabase, $FormEventsTable, FormEventRow>,
          ),
          FormEventRow,
          PrefetchHooks Function()
        > {
  $$FormEventsTableTableManager(_$AppDatabase db, $FormEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> setLogId = const Value.absent(),
                Value<int?> repIndex = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<double> magnitude = const Value.absent(),
                Value<int> atMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FormEventsCompanion(
                id: id,
                setLogId: setLogId,
                repIndex: repIndex,
                ruleId: ruleId,
                severity: severity,
                magnitude: magnitude,
                atMs: atMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String setLogId,
                Value<int?> repIndex = const Value.absent(),
                required String ruleId,
                required String severity,
                required double magnitude,
                required int atMs,
                Value<int> rowid = const Value.absent(),
              }) => FormEventsCompanion.insert(
                id: id,
                setLogId: setLogId,
                repIndex: repIndex,
                ruleId: ruleId,
                severity: severity,
                magnitude: magnitude,
                atMs: atMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FormEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FormEventsTable,
      FormEventRow,
      $$FormEventsTableFilterComposer,
      $$FormEventsTableOrderingComposer,
      $$FormEventsTableAnnotationComposer,
      $$FormEventsTableCreateCompanionBuilder,
      $$FormEventsTableUpdateCompanionBuilder,
      (
        FormEventRow,
        BaseReferences<_$AppDatabase, $FormEventsTable, FormEventRow>,
      ),
      FormEventRow,
      PrefetchHooks Function()
    >;
typedef $$PersonalRecordsTableCreateCompanionBuilder =
    PersonalRecordsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<DateTime?> pushedAt,
      required String id,
      required String exerciseId,
      required String kind,
      required double value,
      required DateTime achievedAt,
      Value<String?> sessionId,
      Value<int> rowid,
    });
typedef $$PersonalRecordsTableUpdateCompanionBuilder =
    PersonalRecordsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<DateTime?> pushedAt,
      Value<String> id,
      Value<String> exerciseId,
      Value<String> kind,
      Value<double> value,
      Value<DateTime> achievedAt,
      Value<String?> sessionId,
      Value<int> rowid,
    });

class $$PersonalRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonalRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonalRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);
}

class $$PersonalRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalRecordsTable,
          PersonalRecordRow,
          $$PersonalRecordsTableFilterComposer,
          $$PersonalRecordsTableOrderingComposer,
          $$PersonalRecordsTableAnnotationComposer,
          $$PersonalRecordsTableCreateCompanionBuilder,
          $$PersonalRecordsTableUpdateCompanionBuilder,
          (
            PersonalRecordRow,
            BaseReferences<
              _$AppDatabase,
              $PersonalRecordsTable,
              PersonalRecordRow
            >,
          ),
          PersonalRecordRow,
          PrefetchHooks Function()
        > {
  $$PersonalRecordsTableTableManager(
    _$AppDatabase db,
    $PersonalRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> pushedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<DateTime> achievedAt = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalRecordsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                exerciseId: exerciseId,
                kind: kind,
                value: value,
                achievedAt: achievedAt,
                sessionId: sessionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<DateTime?> pushedAt = const Value.absent(),
                required String id,
                required String exerciseId,
                required String kind,
                required double value,
                required DateTime achievedAt,
                Value<String?> sessionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalRecordsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                pushedAt: pushedAt,
                id: id,
                exerciseId: exerciseId,
                kind: kind,
                value: value,
                achievedAt: achievedAt,
                sessionId: sessionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonalRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalRecordsTable,
      PersonalRecordRow,
      $$PersonalRecordsTableFilterComposer,
      $$PersonalRecordsTableOrderingComposer,
      $$PersonalRecordsTableAnnotationComposer,
      $$PersonalRecordsTableCreateCompanionBuilder,
      $$PersonalRecordsTableUpdateCompanionBuilder,
      (
        PersonalRecordRow,
        BaseReferences<_$AppDatabase, $PersonalRecordsTable, PersonalRecordRow>,
      ),
      PersonalRecordRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String targetTable,
      Value<String?> cursor,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> targetTable,
      Value<String?> cursor,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> targetTable = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                targetTable: targetTable,
                cursor: cursor,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String targetTable,
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                targetTable: targetTable,
                cursor: cursor,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$LocalIdentityTableCreateCompanionBuilder =
    LocalIdentityCompanion Function({
      Value<String> id,
      required String installId,
      Value<String?> userId,
      Value<String?> email,
      Value<DateTime?> claimedAt,
      Value<int> rowid,
    });
typedef $$LocalIdentityTableUpdateCompanionBuilder =
    LocalIdentityCompanion Function({
      Value<String> id,
      Value<String> installId,
      Value<String?> userId,
      Value<String?> email,
      Value<DateTime?> claimedAt,
      Value<int> rowid,
    });

class $$LocalIdentityTableFilterComposer
    extends Composer<_$AppDatabase, $LocalIdentityTable> {
  $$LocalIdentityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalIdentityTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalIdentityTable> {
  $$LocalIdentityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalIdentityTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalIdentityTable> {
  $$LocalIdentityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get claimedAt =>
      $composableBuilder(column: $table.claimedAt, builder: (column) => column);
}

class $$LocalIdentityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalIdentityTable,
          LocalIdentityRow,
          $$LocalIdentityTableFilterComposer,
          $$LocalIdentityTableOrderingComposer,
          $$LocalIdentityTableAnnotationComposer,
          $$LocalIdentityTableCreateCompanionBuilder,
          $$LocalIdentityTableUpdateCompanionBuilder,
          (
            LocalIdentityRow,
            BaseReferences<
              _$AppDatabase,
              $LocalIdentityTable,
              LocalIdentityRow
            >,
          ),
          LocalIdentityRow,
          PrefetchHooks Function()
        > {
  $$LocalIdentityTableTableManager(_$AppDatabase db, $LocalIdentityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalIdentityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalIdentityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalIdentityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<DateTime?> claimedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalIdentityCompanion(
                id: id,
                installId: installId,
                userId: userId,
                email: email,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String installId,
                Value<String?> userId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<DateTime?> claimedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalIdentityCompanion.insert(
                id: id,
                installId: installId,
                userId: userId,
                email: email,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalIdentityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalIdentityTable,
      LocalIdentityRow,
      $$LocalIdentityTableFilterComposer,
      $$LocalIdentityTableOrderingComposer,
      $$LocalIdentityTableAnnotationComposer,
      $$LocalIdentityTableCreateCompanionBuilder,
      $$LocalIdentityTableUpdateCompanionBuilder,
      (
        LocalIdentityRow,
        BaseReferences<_$AppDatabase, $LocalIdentityTable, LocalIdentityRow>,
      ),
      LocalIdentityRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$PlanDaysTableTableManager get planDays =>
      $$PlanDaysTableTableManager(_db, _db.planDays);
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db, _db.planExercises);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SetLogsTableTableManager get setLogs =>
      $$SetLogsTableTableManager(_db, _db.setLogs);
  $$RepLogsTableTableManager get repLogs =>
      $$RepLogsTableTableManager(_db, _db.repLogs);
  $$FormEventsTableTableManager get formEvents =>
      $$FormEventsTableTableManager(_db, _db.formEvents);
  $$PersonalRecordsTableTableManager get personalRecords =>
      $$PersonalRecordsTableTableManager(_db, _db.personalRecords);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$LocalIdentityTableTableManager get localIdentity =>
      $$LocalIdentityTableTableManager(_db, _db.localIdentity);
}
