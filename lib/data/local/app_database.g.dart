// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _regNumberMeta =
      const VerificationMeta('regNumber');
  @override
  late final GeneratedColumn<String> regNumber = GeneratedColumn<String>(
      'reg_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _departmentMeta =
      const VerificationMeta('department');
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
      'department', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentLevelMeta =
      const VerificationMeta('currentLevel');
  @override
  late final GeneratedColumn<int> currentLevel = GeneratedColumn<int>(
      'current_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _entryYearMeta =
      const VerificationMeta('entryYear');
  @override
  late final GeneratedColumn<int> entryYear = GeneratedColumn<int>(
      'entry_year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expectedGraduationYearMeta =
      const VerificationMeta('expectedGraduationYear');
  @override
  late final GeneratedColumn<int> expectedGraduationYear = GeneratedColumn<int>(
      'expected_graduation_year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _activeSchemeIdMeta =
      const VerificationMeta('activeSchemeId');
  @override
  late final GeneratedColumn<String> activeSchemeId = GeneratedColumn<String>(
      'active_scheme_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fullName,
        regNumber,
        department,
        currentLevel,
        entryYear,
        expectedGraduationYear,
        activeSchemeId,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('reg_number')) {
      context.handle(_regNumberMeta,
          regNumber.isAcceptableOrUnknown(data['reg_number']!, _regNumberMeta));
    } else if (isInserting) {
      context.missing(_regNumberMeta);
    }
    if (data.containsKey('department')) {
      context.handle(
          _departmentMeta,
          department.isAcceptableOrUnknown(
              data['department']!, _departmentMeta));
    } else if (isInserting) {
      context.missing(_departmentMeta);
    }
    if (data.containsKey('current_level')) {
      context.handle(
          _currentLevelMeta,
          currentLevel.isAcceptableOrUnknown(
              data['current_level']!, _currentLevelMeta));
    } else if (isInserting) {
      context.missing(_currentLevelMeta);
    }
    if (data.containsKey('entry_year')) {
      context.handle(_entryYearMeta,
          entryYear.isAcceptableOrUnknown(data['entry_year']!, _entryYearMeta));
    } else if (isInserting) {
      context.missing(_entryYearMeta);
    }
    if (data.containsKey('expected_graduation_year')) {
      context.handle(
          _expectedGraduationYearMeta,
          expectedGraduationYear.isAcceptableOrUnknown(
              data['expected_graduation_year']!, _expectedGraduationYearMeta));
    } else if (isInserting) {
      context.missing(_expectedGraduationYearMeta);
    }
    if (data.containsKey('active_scheme_id')) {
      context.handle(
          _activeSchemeIdMeta,
          activeSchemeId.isAcceptableOrUnknown(
              data['active_scheme_id']!, _activeSchemeIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      regNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reg_number'])!,
      department: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}department'])!,
      currentLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_level'])!,
      entryYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_year'])!,
      expectedGraduationYear: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}expected_graduation_year'])!,
      activeSchemeId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_scheme_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String fullName;
  final String regNumber;
  final String department;
  final int currentLevel;
  final int entryYear;
  final int expectedGraduationYear;
  final String? activeSchemeId;
  final DateTime updatedAt;
  const Profile(
      {required this.id,
      required this.fullName,
      required this.regNumber,
      required this.department,
      required this.currentLevel,
      required this.entryYear,
      required this.expectedGraduationYear,
      this.activeSchemeId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['reg_number'] = Variable<String>(regNumber);
    map['department'] = Variable<String>(department);
    map['current_level'] = Variable<int>(currentLevel);
    map['entry_year'] = Variable<int>(entryYear);
    map['expected_graduation_year'] = Variable<int>(expectedGraduationYear);
    if (!nullToAbsent || activeSchemeId != null) {
      map['active_scheme_id'] = Variable<String>(activeSchemeId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      fullName: Value(fullName),
      regNumber: Value(regNumber),
      department: Value(department),
      currentLevel: Value(currentLevel),
      entryYear: Value(entryYear),
      expectedGraduationYear: Value(expectedGraduationYear),
      activeSchemeId: activeSchemeId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeSchemeId),
      updatedAt: Value(updatedAt),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      regNumber: serializer.fromJson<String>(json['regNumber']),
      department: serializer.fromJson<String>(json['department']),
      currentLevel: serializer.fromJson<int>(json['currentLevel']),
      entryYear: serializer.fromJson<int>(json['entryYear']),
      expectedGraduationYear:
          serializer.fromJson<int>(json['expectedGraduationYear']),
      activeSchemeId: serializer.fromJson<String?>(json['activeSchemeId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'regNumber': serializer.toJson<String>(regNumber),
      'department': serializer.toJson<String>(department),
      'currentLevel': serializer.toJson<int>(currentLevel),
      'entryYear': serializer.toJson<int>(entryYear),
      'expectedGraduationYear': serializer.toJson<int>(expectedGraduationYear),
      'activeSchemeId': serializer.toJson<String?>(activeSchemeId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Profile copyWith(
          {String? id,
          String? fullName,
          String? regNumber,
          String? department,
          int? currentLevel,
          int? entryYear,
          int? expectedGraduationYear,
          Value<String?> activeSchemeId = const Value.absent(),
          DateTime? updatedAt}) =>
      Profile(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        regNumber: regNumber ?? this.regNumber,
        department: department ?? this.department,
        currentLevel: currentLevel ?? this.currentLevel,
        entryYear: entryYear ?? this.entryYear,
        expectedGraduationYear:
            expectedGraduationYear ?? this.expectedGraduationYear,
        activeSchemeId:
            activeSchemeId.present ? activeSchemeId.value : this.activeSchemeId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      regNumber: data.regNumber.present ? data.regNumber.value : this.regNumber,
      department:
          data.department.present ? data.department.value : this.department,
      currentLevel: data.currentLevel.present
          ? data.currentLevel.value
          : this.currentLevel,
      entryYear: data.entryYear.present ? data.entryYear.value : this.entryYear,
      expectedGraduationYear: data.expectedGraduationYear.present
          ? data.expectedGraduationYear.value
          : this.expectedGraduationYear,
      activeSchemeId: data.activeSchemeId.present
          ? data.activeSchemeId.value
          : this.activeSchemeId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('regNumber: $regNumber, ')
          ..write('department: $department, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('entryYear: $entryYear, ')
          ..write('expectedGraduationYear: $expectedGraduationYear, ')
          ..write('activeSchemeId: $activeSchemeId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      fullName,
      regNumber,
      department,
      currentLevel,
      entryYear,
      expectedGraduationYear,
      activeSchemeId,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.regNumber == this.regNumber &&
          other.department == this.department &&
          other.currentLevel == this.currentLevel &&
          other.entryYear == this.entryYear &&
          other.expectedGraduationYear == this.expectedGraduationYear &&
          other.activeSchemeId == this.activeSchemeId &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> regNumber;
  final Value<String> department;
  final Value<int> currentLevel;
  final Value<int> entryYear;
  final Value<int> expectedGraduationYear;
  final Value<String?> activeSchemeId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.regNumber = const Value.absent(),
    this.department = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.entryYear = const Value.absent(),
    this.expectedGraduationYear = const Value.absent(),
    this.activeSchemeId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String fullName,
    required String regNumber,
    required String department,
    required int currentLevel,
    required int entryYear,
    required int expectedGraduationYear,
    this.activeSchemeId = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fullName = Value(fullName),
        regNumber = Value(regNumber),
        department = Value(department),
        currentLevel = Value(currentLevel),
        entryYear = Value(entryYear),
        expectedGraduationYear = Value(expectedGraduationYear),
        updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? regNumber,
    Expression<String>? department,
    Expression<int>? currentLevel,
    Expression<int>? entryYear,
    Expression<int>? expectedGraduationYear,
    Expression<String>? activeSchemeId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (regNumber != null) 'reg_number': regNumber,
      if (department != null) 'department': department,
      if (currentLevel != null) 'current_level': currentLevel,
      if (entryYear != null) 'entry_year': entryYear,
      if (expectedGraduationYear != null)
        'expected_graduation_year': expectedGraduationYear,
      if (activeSchemeId != null) 'active_scheme_id': activeSchemeId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? fullName,
      Value<String>? regNumber,
      Value<String>? department,
      Value<int>? currentLevel,
      Value<int>? entryYear,
      Value<int>? expectedGraduationYear,
      Value<String?>? activeSchemeId,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      regNumber: regNumber ?? this.regNumber,
      department: department ?? this.department,
      currentLevel: currentLevel ?? this.currentLevel,
      entryYear: entryYear ?? this.entryYear,
      expectedGraduationYear:
          expectedGraduationYear ?? this.expectedGraduationYear,
      activeSchemeId: activeSchemeId ?? this.activeSchemeId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (regNumber.present) {
      map['reg_number'] = Variable<String>(regNumber.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (currentLevel.present) {
      map['current_level'] = Variable<int>(currentLevel.value);
    }
    if (entryYear.present) {
      map['entry_year'] = Variable<int>(entryYear.value);
    }
    if (expectedGraduationYear.present) {
      map['expected_graduation_year'] =
          Variable<int>(expectedGraduationYear.value);
    }
    if (activeSchemeId.present) {
      map['active_scheme_id'] = Variable<String>(activeSchemeId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('regNumber: $regNumber, ')
          ..write('department: $department, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('entryYear: $entryYear, ')
          ..write('expectedGraduationYear: $expectedGraduationYear, ')
          ..write('activeSchemeId: $activeSchemeId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, SemesterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionMeta =
      const VerificationMeta('session');
  @override
  late final GeneratedColumn<String> session = GeneratedColumn<String>(
      'session', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SemesterTerm, String> term =
      GeneratedColumn<String>('term', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<SemesterTerm>($SemestersTable.$converterterm);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, profileId, session, term, level, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(Insertable<SemesterRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('session')) {
      context.handle(_sessionMeta,
          session.isAcceptableOrUnknown(data['session']!, _sessionMeta));
    } else if (isInserting) {
      context.missing(_sessionMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SemesterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemesterRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      session: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session'])!,
      term: $SemestersTable.$converterterm.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}term'])!),
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SemesterTerm, String, String> $converterterm =
      const EnumNameConverter<SemesterTerm>(SemesterTerm.values);
}

class SemesterRow extends DataClass implements Insertable<SemesterRow> {
  final String id;
  final String profileId;
  final String session;
  final SemesterTerm term;
  final int level;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SemesterRow(
      {required this.id,
      required this.profileId,
      required this.session,
      required this.term,
      required this.level,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['session'] = Variable<String>(session);
    {
      map['term'] =
          Variable<String>($SemestersTable.$converterterm.toSql(term));
    }
    map['level'] = Variable<int>(level);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      profileId: Value(profileId),
      session: Value(session),
      term: Value(term),
      level: Value(level),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SemesterRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemesterRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      session: serializer.fromJson<String>(json['session']),
      term: $SemestersTable.$converterterm
          .fromJson(serializer.fromJson<String>(json['term'])),
      level: serializer.fromJson<int>(json['level']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'session': serializer.toJson<String>(session),
      'term': serializer
          .toJson<String>($SemestersTable.$converterterm.toJson(term)),
      'level': serializer.toJson<int>(level),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SemesterRow copyWith(
          {String? id,
          String? profileId,
          String? session,
          SemesterTerm? term,
          int? level,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SemesterRow(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        session: session ?? this.session,
        term: term ?? this.term,
        level: level ?? this.level,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SemesterRow copyWithCompanion(SemestersCompanion data) {
    return SemesterRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      session: data.session.present ? data.session.value : this.session,
      term: data.term.present ? data.term.value : this.term,
      level: data.level.present ? data.level.value : this.level,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SemesterRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('session: $session, ')
          ..write('term: $term, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, session, term, level, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemesterRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.session == this.session &&
          other.term == this.term &&
          other.level == this.level &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SemestersCompanion extends UpdateCompanion<SemesterRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> session;
  final Value<SemesterTerm> term;
  final Value<int> level;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.session = const Value.absent(),
    this.term = const Value.absent(),
    this.level = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SemestersCompanion.insert({
    required String id,
    required String profileId,
    required String session,
    required SemesterTerm term,
    required int level,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        session = Value(session),
        term = Value(term),
        level = Value(level),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SemesterRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? session,
    Expression<String>? term,
    Expression<int>? level,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (session != null) 'session': session,
      if (term != null) 'term': term,
      if (level != null) 'level': level,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SemestersCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? session,
      Value<SemesterTerm>? term,
      Value<int>? level,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SemestersCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      session: session ?? this.session,
      term: term ?? this.term,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (session.present) {
      map['session'] = Variable<String>(session.value);
    }
    if (term.present) {
      map['term'] =
          Variable<String>($SemestersTable.$converterterm.toSql(term.value));
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('session: $session, ')
          ..write('term: $term, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseResultsTable extends CourseResults
    with TableInfo<$CourseResultsTable, CourseResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _semesterIdMeta =
      const VerificationMeta('semesterId');
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
      'semester_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courseCodeMeta =
      const VerificationMeta('courseCode');
  @override
  late final GeneratedColumn<String> courseCode = GeneratedColumn<String>(
      'course_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courseTitleMeta =
      const VerificationMeta('courseTitle');
  @override
  late final GeneratedColumn<String> courseTitle = GeneratedColumn<String>(
      'course_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _creditUnitMeta =
      const VerificationMeta('creditUnit');
  @override
  late final GeneratedColumn<int> creditUnit = GeneratedColumn<int>(
      'credit_unit', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
      'grade', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _attemptMeta =
      const VerificationMeta('attempt');
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
      'attempt', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _supersedesResultIdMeta =
      const VerificationMeta('supersedesResultId');
  @override
  late final GeneratedColumn<String> supersedesResultId =
      GeneratedColumn<String>('supersedes_result_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<ResultSource, String> source =
      GeneratedColumn<String>('source', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ResultSource>($CourseResultsTable.$convertersource);
  static const VerificationMeta _extractionConfidenceMeta =
      const VerificationMeta('extractionConfidence');
  @override
  late final GeneratedColumn<double> extractionConfidence =
      GeneratedColumn<double>('extraction_confidence', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        semesterId,
        courseCode,
        courseTitle,
        creditUnit,
        grade,
        score,
        attempt,
        supersedesResultId,
        source,
        extractionConfidence,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_results';
  @override
  VerificationContext validateIntegrity(Insertable<CourseResultRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
          _semesterIdMeta,
          semesterId.isAcceptableOrUnknown(
              data['semester_id']!, _semesterIdMeta));
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('course_code')) {
      context.handle(
          _courseCodeMeta,
          courseCode.isAcceptableOrUnknown(
              data['course_code']!, _courseCodeMeta));
    } else if (isInserting) {
      context.missing(_courseCodeMeta);
    }
    if (data.containsKey('course_title')) {
      context.handle(
          _courseTitleMeta,
          courseTitle.isAcceptableOrUnknown(
              data['course_title']!, _courseTitleMeta));
    }
    if (data.containsKey('credit_unit')) {
      context.handle(
          _creditUnitMeta,
          creditUnit.isAcceptableOrUnknown(
              data['credit_unit']!, _creditUnitMeta));
    } else if (isInserting) {
      context.missing(_creditUnitMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
          _gradeMeta, grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta));
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('attempt')) {
      context.handle(_attemptMeta,
          attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta));
    }
    if (data.containsKey('supersedes_result_id')) {
      context.handle(
          _supersedesResultIdMeta,
          supersedesResultId.isAcceptableOrUnknown(
              data['supersedes_result_id']!, _supersedesResultIdMeta));
    }
    if (data.containsKey('extraction_confidence')) {
      context.handle(
          _extractionConfidenceMeta,
          extractionConfidence.isAcceptableOrUnknown(
              data['extraction_confidence']!, _extractionConfidenceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseResultRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      semesterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semester_id'])!,
      courseCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_code'])!,
      courseTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_title']),
      creditUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}credit_unit'])!,
      grade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grade'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score']),
      attempt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt'])!,
      supersedesResultId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}supersedes_result_id']),
      source: $CourseResultsTable.$convertersource.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!),
      extractionConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}extraction_confidence']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CourseResultsTable createAlias(String alias) {
    return $CourseResultsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ResultSource, String, String> $convertersource =
      const EnumNameConverter<ResultSource>(ResultSource.values);
}

class CourseResultRow extends DataClass implements Insertable<CourseResultRow> {
  final String id;
  final String semesterId;
  final String courseCode;
  final String? courseTitle;
  final int creditUnit;
  final String grade;
  final int? score;
  final int attempt;
  final String? supersedesResultId;
  final ResultSource source;
  final double? extractionConfidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CourseResultRow(
      {required this.id,
      required this.semesterId,
      required this.courseCode,
      this.courseTitle,
      required this.creditUnit,
      required this.grade,
      this.score,
      required this.attempt,
      this.supersedesResultId,
      required this.source,
      this.extractionConfidence,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['semester_id'] = Variable<String>(semesterId);
    map['course_code'] = Variable<String>(courseCode);
    if (!nullToAbsent || courseTitle != null) {
      map['course_title'] = Variable<String>(courseTitle);
    }
    map['credit_unit'] = Variable<int>(creditUnit);
    map['grade'] = Variable<String>(grade);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    map['attempt'] = Variable<int>(attempt);
    if (!nullToAbsent || supersedesResultId != null) {
      map['supersedes_result_id'] = Variable<String>(supersedesResultId);
    }
    {
      map['source'] =
          Variable<String>($CourseResultsTable.$convertersource.toSql(source));
    }
    if (!nullToAbsent || extractionConfidence != null) {
      map['extraction_confidence'] = Variable<double>(extractionConfidence);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CourseResultsCompanion toCompanion(bool nullToAbsent) {
    return CourseResultsCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      courseCode: Value(courseCode),
      courseTitle: courseTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(courseTitle),
      creditUnit: Value(creditUnit),
      grade: Value(grade),
      score:
          score == null && nullToAbsent ? const Value.absent() : Value(score),
      attempt: Value(attempt),
      supersedesResultId: supersedesResultId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersedesResultId),
      source: Value(source),
      extractionConfidence: extractionConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionConfidence),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CourseResultRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseResultRow(
      id: serializer.fromJson<String>(json['id']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      courseCode: serializer.fromJson<String>(json['courseCode']),
      courseTitle: serializer.fromJson<String?>(json['courseTitle']),
      creditUnit: serializer.fromJson<int>(json['creditUnit']),
      grade: serializer.fromJson<String>(json['grade']),
      score: serializer.fromJson<int?>(json['score']),
      attempt: serializer.fromJson<int>(json['attempt']),
      supersedesResultId:
          serializer.fromJson<String?>(json['supersedesResultId']),
      source: $CourseResultsTable.$convertersource
          .fromJson(serializer.fromJson<String>(json['source'])),
      extractionConfidence:
          serializer.fromJson<double?>(json['extractionConfidence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'semesterId': serializer.toJson<String>(semesterId),
      'courseCode': serializer.toJson<String>(courseCode),
      'courseTitle': serializer.toJson<String?>(courseTitle),
      'creditUnit': serializer.toJson<int>(creditUnit),
      'grade': serializer.toJson<String>(grade),
      'score': serializer.toJson<int?>(score),
      'attempt': serializer.toJson<int>(attempt),
      'supersedesResultId': serializer.toJson<String?>(supersedesResultId),
      'source': serializer
          .toJson<String>($CourseResultsTable.$convertersource.toJson(source)),
      'extractionConfidence': serializer.toJson<double?>(extractionConfidence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CourseResultRow copyWith(
          {String? id,
          String? semesterId,
          String? courseCode,
          Value<String?> courseTitle = const Value.absent(),
          int? creditUnit,
          String? grade,
          Value<int?> score = const Value.absent(),
          int? attempt,
          Value<String?> supersedesResultId = const Value.absent(),
          ResultSource? source,
          Value<double?> extractionConfidence = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CourseResultRow(
        id: id ?? this.id,
        semesterId: semesterId ?? this.semesterId,
        courseCode: courseCode ?? this.courseCode,
        courseTitle: courseTitle.present ? courseTitle.value : this.courseTitle,
        creditUnit: creditUnit ?? this.creditUnit,
        grade: grade ?? this.grade,
        score: score.present ? score.value : this.score,
        attempt: attempt ?? this.attempt,
        supersedesResultId: supersedesResultId.present
            ? supersedesResultId.value
            : this.supersedesResultId,
        source: source ?? this.source,
        extractionConfidence: extractionConfidence.present
            ? extractionConfidence.value
            : this.extractionConfidence,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CourseResultRow copyWithCompanion(CourseResultsCompanion data) {
    return CourseResultRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId:
          data.semesterId.present ? data.semesterId.value : this.semesterId,
      courseCode:
          data.courseCode.present ? data.courseCode.value : this.courseCode,
      courseTitle:
          data.courseTitle.present ? data.courseTitle.value : this.courseTitle,
      creditUnit:
          data.creditUnit.present ? data.creditUnit.value : this.creditUnit,
      grade: data.grade.present ? data.grade.value : this.grade,
      score: data.score.present ? data.score.value : this.score,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      supersedesResultId: data.supersedesResultId.present
          ? data.supersedesResultId.value
          : this.supersedesResultId,
      source: data.source.present ? data.source.value : this.source,
      extractionConfidence: data.extractionConfidence.present
          ? data.extractionConfidence.value
          : this.extractionConfidence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseResultRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseTitle: $courseTitle, ')
          ..write('creditUnit: $creditUnit, ')
          ..write('grade: $grade, ')
          ..write('score: $score, ')
          ..write('attempt: $attempt, ')
          ..write('supersedesResultId: $supersedesResultId, ')
          ..write('source: $source, ')
          ..write('extractionConfidence: $extractionConfidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      semesterId,
      courseCode,
      courseTitle,
      creditUnit,
      grade,
      score,
      attempt,
      supersedesResultId,
      source,
      extractionConfidence,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseResultRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.courseCode == this.courseCode &&
          other.courseTitle == this.courseTitle &&
          other.creditUnit == this.creditUnit &&
          other.grade == this.grade &&
          other.score == this.score &&
          other.attempt == this.attempt &&
          other.supersedesResultId == this.supersedesResultId &&
          other.source == this.source &&
          other.extractionConfidence == this.extractionConfidence &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CourseResultsCompanion extends UpdateCompanion<CourseResultRow> {
  final Value<String> id;
  final Value<String> semesterId;
  final Value<String> courseCode;
  final Value<String?> courseTitle;
  final Value<int> creditUnit;
  final Value<String> grade;
  final Value<int?> score;
  final Value<int> attempt;
  final Value<String?> supersedesResultId;
  final Value<ResultSource> source;
  final Value<double?> extractionConfidence;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CourseResultsCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.courseCode = const Value.absent(),
    this.courseTitle = const Value.absent(),
    this.creditUnit = const Value.absent(),
    this.grade = const Value.absent(),
    this.score = const Value.absent(),
    this.attempt = const Value.absent(),
    this.supersedesResultId = const Value.absent(),
    this.source = const Value.absent(),
    this.extractionConfidence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseResultsCompanion.insert({
    required String id,
    required String semesterId,
    required String courseCode,
    this.courseTitle = const Value.absent(),
    required int creditUnit,
    required String grade,
    this.score = const Value.absent(),
    this.attempt = const Value.absent(),
    this.supersedesResultId = const Value.absent(),
    required ResultSource source,
    this.extractionConfidence = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        semesterId = Value(semesterId),
        courseCode = Value(courseCode),
        creditUnit = Value(creditUnit),
        grade = Value(grade),
        source = Value(source),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CourseResultRow> custom({
    Expression<String>? id,
    Expression<String>? semesterId,
    Expression<String>? courseCode,
    Expression<String>? courseTitle,
    Expression<int>? creditUnit,
    Expression<String>? grade,
    Expression<int>? score,
    Expression<int>? attempt,
    Expression<String>? supersedesResultId,
    Expression<String>? source,
    Expression<double>? extractionConfidence,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (courseCode != null) 'course_code': courseCode,
      if (courseTitle != null) 'course_title': courseTitle,
      if (creditUnit != null) 'credit_unit': creditUnit,
      if (grade != null) 'grade': grade,
      if (score != null) 'score': score,
      if (attempt != null) 'attempt': attempt,
      if (supersedesResultId != null)
        'supersedes_result_id': supersedesResultId,
      if (source != null) 'source': source,
      if (extractionConfidence != null)
        'extraction_confidence': extractionConfidence,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseResultsCompanion copyWith(
      {Value<String>? id,
      Value<String>? semesterId,
      Value<String>? courseCode,
      Value<String?>? courseTitle,
      Value<int>? creditUnit,
      Value<String>? grade,
      Value<int?>? score,
      Value<int>? attempt,
      Value<String?>? supersedesResultId,
      Value<ResultSource>? source,
      Value<double?>? extractionConfidence,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CourseResultsCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      creditUnit: creditUnit ?? this.creditUnit,
      grade: grade ?? this.grade,
      score: score ?? this.score,
      attempt: attempt ?? this.attempt,
      supersedesResultId: supersedesResultId ?? this.supersedesResultId,
      source: source ?? this.source,
      extractionConfidence: extractionConfidence ?? this.extractionConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (courseCode.present) {
      map['course_code'] = Variable<String>(courseCode.value);
    }
    if (courseTitle.present) {
      map['course_title'] = Variable<String>(courseTitle.value);
    }
    if (creditUnit.present) {
      map['credit_unit'] = Variable<int>(creditUnit.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (supersedesResultId.present) {
      map['supersedes_result_id'] = Variable<String>(supersedesResultId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
          $CourseResultsTable.$convertersource.toSql(source.value));
    }
    if (extractionConfidence.present) {
      map['extraction_confidence'] =
          Variable<double>(extractionConfidence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseResultsCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseTitle: $courseTitle, ')
          ..write('creditUnit: $creditUnit, ')
          ..write('grade: $grade, ')
          ..write('score: $score, ')
          ..write('attempt: $attempt, ')
          ..write('supersedesResultId: $supersedesResultId, ')
          ..write('source: $source, ')
          ..write('extractionConfidence: $extractionConfidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GradingSchemesTable extends GradingSchemes
    with TableInfo<$GradingSchemesTable, GradingSchemeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradingSchemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _institutionIdMeta =
      const VerificationMeta('institutionId');
  @override
  late final GeneratedColumn<String> institutionId = GeneratedColumn<String>(
      'institution_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _effectiveFromMeta =
      const VerificationMeta('effectiveFrom');
  @override
  late final GeneratedColumn<DateTime> effectiveFrom =
      GeneratedColumn<DateTime>('effective_from', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _effectiveUntilMeta =
      const VerificationMeta('effectiveUntil');
  @override
  late final GeneratedColumn<DateTime> effectiveUntil =
      GeneratedColumn<DateTime>('effective_until', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _maxPointMeta =
      const VerificationMeta('maxPoint');
  @override
  late final GeneratedColumn<double> maxPoint = GeneratedColumn<double>(
      'max_point', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<GradeDefinition>, String>
      grades = GeneratedColumn<String>('grades', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<GradeDefinition>>(
              $GradingSchemesTable.$convertergrades);
  @override
  late final GeneratedColumnWithTypeConverter<List<ClassificationBand>, String>
      classifications = GeneratedColumn<String>(
              'classifications', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<ClassificationBand>>(
              $GradingSchemesTable.$converterclassifications);
  @override
  late final GeneratedColumnWithTypeConverter<RepeatPolicy, String>
      repeatPolicy = GeneratedColumn<String>(
              'repeat_policy', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<RepeatPolicy>(
              $GradingSchemesTable.$converterrepeatPolicy);
  static const VerificationMeta _repeatCapPointMeta =
      const VerificationMeta('repeatCapPoint');
  @override
  late final GeneratedColumn<double> repeatCapPoint = GeneratedColumn<double>(
      'repeat_cap_point', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        institutionId,
        name,
        version,
        effectiveFrom,
        effectiveUntil,
        maxPoint,
        grades,
        classifications,
        repeatPolicy,
        repeatCapPoint,
        isCustom
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grading_schemes';
  @override
  VerificationContext validateIntegrity(Insertable<GradingSchemeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('institution_id')) {
      context.handle(
          _institutionIdMeta,
          institutionId.isAcceptableOrUnknown(
              data['institution_id']!, _institutionIdMeta));
    } else if (isInserting) {
      context.missing(_institutionIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
          _effectiveFromMeta,
          effectiveFrom.isAcceptableOrUnknown(
              data['effective_from']!, _effectiveFromMeta));
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('effective_until')) {
      context.handle(
          _effectiveUntilMeta,
          effectiveUntil.isAcceptableOrUnknown(
              data['effective_until']!, _effectiveUntilMeta));
    }
    if (data.containsKey('max_point')) {
      context.handle(_maxPointMeta,
          maxPoint.isAcceptableOrUnknown(data['max_point']!, _maxPointMeta));
    } else if (isInserting) {
      context.missing(_maxPointMeta);
    }
    if (data.containsKey('repeat_cap_point')) {
      context.handle(
          _repeatCapPointMeta,
          repeatCapPoint.isAcceptableOrUnknown(
              data['repeat_cap_point']!, _repeatCapPointMeta));
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GradingSchemeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradingSchemeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      institutionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}institution_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      effectiveFrom: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}effective_from'])!,
      effectiveUntil: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}effective_until']),
      maxPoint: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_point'])!,
      grades: $GradingSchemesTable.$convertergrades.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grades'])!),
      classifications: $GradingSchemesTable.$converterclassifications.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}classifications'])!),
      repeatPolicy: $GradingSchemesTable.$converterrepeatPolicy.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}repeat_policy'])!),
      repeatCapPoint: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}repeat_cap_point']),
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
    );
  }

  @override
  $GradingSchemesTable createAlias(String alias) {
    return $GradingSchemesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<GradeDefinition>, String> $convertergrades =
      const GradeDefinitionListConverter();
  static TypeConverter<List<ClassificationBand>, String>
      $converterclassifications = const ClassificationBandListConverter();
  static JsonTypeConverter2<RepeatPolicy, String, String>
      $converterrepeatPolicy =
      const EnumNameConverter<RepeatPolicy>(RepeatPolicy.values);
}

class GradingSchemeRow extends DataClass
    implements Insertable<GradingSchemeRow> {
  final String id;
  final String institutionId;
  final String name;
  final int version;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final double maxPoint;
  final List<GradeDefinition> grades;
  final List<ClassificationBand> classifications;
  final RepeatPolicy repeatPolicy;
  final double? repeatCapPoint;
  final bool isCustom;
  const GradingSchemeRow(
      {required this.id,
      required this.institutionId,
      required this.name,
      required this.version,
      required this.effectiveFrom,
      this.effectiveUntil,
      required this.maxPoint,
      required this.grades,
      required this.classifications,
      required this.repeatPolicy,
      this.repeatCapPoint,
      required this.isCustom});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['institution_id'] = Variable<String>(institutionId);
    map['name'] = Variable<String>(name);
    map['version'] = Variable<int>(version);
    map['effective_from'] = Variable<DateTime>(effectiveFrom);
    if (!nullToAbsent || effectiveUntil != null) {
      map['effective_until'] = Variable<DateTime>(effectiveUntil);
    }
    map['max_point'] = Variable<double>(maxPoint);
    {
      map['grades'] =
          Variable<String>($GradingSchemesTable.$convertergrades.toSql(grades));
    }
    {
      map['classifications'] = Variable<String>($GradingSchemesTable
          .$converterclassifications
          .toSql(classifications));
    }
    {
      map['repeat_policy'] = Variable<String>(
          $GradingSchemesTable.$converterrepeatPolicy.toSql(repeatPolicy));
    }
    if (!nullToAbsent || repeatCapPoint != null) {
      map['repeat_cap_point'] = Variable<double>(repeatCapPoint);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    return map;
  }

  GradingSchemesCompanion toCompanion(bool nullToAbsent) {
    return GradingSchemesCompanion(
      id: Value(id),
      institutionId: Value(institutionId),
      name: Value(name),
      version: Value(version),
      effectiveFrom: Value(effectiveFrom),
      effectiveUntil: effectiveUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveUntil),
      maxPoint: Value(maxPoint),
      grades: Value(grades),
      classifications: Value(classifications),
      repeatPolicy: Value(repeatPolicy),
      repeatCapPoint: repeatCapPoint == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatCapPoint),
      isCustom: Value(isCustom),
    );
  }

  factory GradingSchemeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradingSchemeRow(
      id: serializer.fromJson<String>(json['id']),
      institutionId: serializer.fromJson<String>(json['institutionId']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<int>(json['version']),
      effectiveFrom: serializer.fromJson<DateTime>(json['effectiveFrom']),
      effectiveUntil: serializer.fromJson<DateTime?>(json['effectiveUntil']),
      maxPoint: serializer.fromJson<double>(json['maxPoint']),
      grades: serializer.fromJson<List<GradeDefinition>>(json['grades']),
      classifications: serializer
          .fromJson<List<ClassificationBand>>(json['classifications']),
      repeatPolicy: $GradingSchemesTable.$converterrepeatPolicy
          .fromJson(serializer.fromJson<String>(json['repeatPolicy'])),
      repeatCapPoint: serializer.fromJson<double?>(json['repeatCapPoint']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'institutionId': serializer.toJson<String>(institutionId),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<int>(version),
      'effectiveFrom': serializer.toJson<DateTime>(effectiveFrom),
      'effectiveUntil': serializer.toJson<DateTime?>(effectiveUntil),
      'maxPoint': serializer.toJson<double>(maxPoint),
      'grades': serializer.toJson<List<GradeDefinition>>(grades),
      'classifications':
          serializer.toJson<List<ClassificationBand>>(classifications),
      'repeatPolicy': serializer.toJson<String>(
          $GradingSchemesTable.$converterrepeatPolicy.toJson(repeatPolicy)),
      'repeatCapPoint': serializer.toJson<double?>(repeatCapPoint),
      'isCustom': serializer.toJson<bool>(isCustom),
    };
  }

  GradingSchemeRow copyWith(
          {String? id,
          String? institutionId,
          String? name,
          int? version,
          DateTime? effectiveFrom,
          Value<DateTime?> effectiveUntil = const Value.absent(),
          double? maxPoint,
          List<GradeDefinition>? grades,
          List<ClassificationBand>? classifications,
          RepeatPolicy? repeatPolicy,
          Value<double?> repeatCapPoint = const Value.absent(),
          bool? isCustom}) =>
      GradingSchemeRow(
        id: id ?? this.id,
        institutionId: institutionId ?? this.institutionId,
        name: name ?? this.name,
        version: version ?? this.version,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        effectiveUntil:
            effectiveUntil.present ? effectiveUntil.value : this.effectiveUntil,
        maxPoint: maxPoint ?? this.maxPoint,
        grades: grades ?? this.grades,
        classifications: classifications ?? this.classifications,
        repeatPolicy: repeatPolicy ?? this.repeatPolicy,
        repeatCapPoint:
            repeatCapPoint.present ? repeatCapPoint.value : this.repeatCapPoint,
        isCustom: isCustom ?? this.isCustom,
      );
  GradingSchemeRow copyWithCompanion(GradingSchemesCompanion data) {
    return GradingSchemeRow(
      id: data.id.present ? data.id.value : this.id,
      institutionId: data.institutionId.present
          ? data.institutionId.value
          : this.institutionId,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      effectiveUntil: data.effectiveUntil.present
          ? data.effectiveUntil.value
          : this.effectiveUntil,
      maxPoint: data.maxPoint.present ? data.maxPoint.value : this.maxPoint,
      grades: data.grades.present ? data.grades.value : this.grades,
      classifications: data.classifications.present
          ? data.classifications.value
          : this.classifications,
      repeatPolicy: data.repeatPolicy.present
          ? data.repeatPolicy.value
          : this.repeatPolicy,
      repeatCapPoint: data.repeatCapPoint.present
          ? data.repeatCapPoint.value
          : this.repeatCapPoint,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradingSchemeRow(')
          ..write('id: $id, ')
          ..write('institutionId: $institutionId, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveUntil: $effectiveUntil, ')
          ..write('maxPoint: $maxPoint, ')
          ..write('grades: $grades, ')
          ..write('classifications: $classifications, ')
          ..write('repeatPolicy: $repeatPolicy, ')
          ..write('repeatCapPoint: $repeatCapPoint, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      institutionId,
      name,
      version,
      effectiveFrom,
      effectiveUntil,
      maxPoint,
      grades,
      classifications,
      repeatPolicy,
      repeatCapPoint,
      isCustom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradingSchemeRow &&
          other.id == this.id &&
          other.institutionId == this.institutionId &&
          other.name == this.name &&
          other.version == this.version &&
          other.effectiveFrom == this.effectiveFrom &&
          other.effectiveUntil == this.effectiveUntil &&
          other.maxPoint == this.maxPoint &&
          other.grades == this.grades &&
          other.classifications == this.classifications &&
          other.repeatPolicy == this.repeatPolicy &&
          other.repeatCapPoint == this.repeatCapPoint &&
          other.isCustom == this.isCustom);
}

class GradingSchemesCompanion extends UpdateCompanion<GradingSchemeRow> {
  final Value<String> id;
  final Value<String> institutionId;
  final Value<String> name;
  final Value<int> version;
  final Value<DateTime> effectiveFrom;
  final Value<DateTime?> effectiveUntil;
  final Value<double> maxPoint;
  final Value<List<GradeDefinition>> grades;
  final Value<List<ClassificationBand>> classifications;
  final Value<RepeatPolicy> repeatPolicy;
  final Value<double?> repeatCapPoint;
  final Value<bool> isCustom;
  final Value<int> rowid;
  const GradingSchemesCompanion({
    this.id = const Value.absent(),
    this.institutionId = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveUntil = const Value.absent(),
    this.maxPoint = const Value.absent(),
    this.grades = const Value.absent(),
    this.classifications = const Value.absent(),
    this.repeatPolicy = const Value.absent(),
    this.repeatCapPoint = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GradingSchemesCompanion.insert({
    required String id,
    required String institutionId,
    required String name,
    required int version,
    required DateTime effectiveFrom,
    this.effectiveUntil = const Value.absent(),
    required double maxPoint,
    required List<GradeDefinition> grades,
    required List<ClassificationBand> classifications,
    required RepeatPolicy repeatPolicy,
    this.repeatCapPoint = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        institutionId = Value(institutionId),
        name = Value(name),
        version = Value(version),
        effectiveFrom = Value(effectiveFrom),
        maxPoint = Value(maxPoint),
        grades = Value(grades),
        classifications = Value(classifications),
        repeatPolicy = Value(repeatPolicy);
  static Insertable<GradingSchemeRow> custom({
    Expression<String>? id,
    Expression<String>? institutionId,
    Expression<String>? name,
    Expression<int>? version,
    Expression<DateTime>? effectiveFrom,
    Expression<DateTime>? effectiveUntil,
    Expression<double>? maxPoint,
    Expression<String>? grades,
    Expression<String>? classifications,
    Expression<String>? repeatPolicy,
    Expression<double>? repeatCapPoint,
    Expression<bool>? isCustom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (institutionId != null) 'institution_id': institutionId,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (effectiveUntil != null) 'effective_until': effectiveUntil,
      if (maxPoint != null) 'max_point': maxPoint,
      if (grades != null) 'grades': grades,
      if (classifications != null) 'classifications': classifications,
      if (repeatPolicy != null) 'repeat_policy': repeatPolicy,
      if (repeatCapPoint != null) 'repeat_cap_point': repeatCapPoint,
      if (isCustom != null) 'is_custom': isCustom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GradingSchemesCompanion copyWith(
      {Value<String>? id,
      Value<String>? institutionId,
      Value<String>? name,
      Value<int>? version,
      Value<DateTime>? effectiveFrom,
      Value<DateTime?>? effectiveUntil,
      Value<double>? maxPoint,
      Value<List<GradeDefinition>>? grades,
      Value<List<ClassificationBand>>? classifications,
      Value<RepeatPolicy>? repeatPolicy,
      Value<double?>? repeatCapPoint,
      Value<bool>? isCustom,
      Value<int>? rowid}) {
    return GradingSchemesCompanion(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
      name: name ?? this.name,
      version: version ?? this.version,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveUntil: effectiveUntil ?? this.effectiveUntil,
      maxPoint: maxPoint ?? this.maxPoint,
      grades: grades ?? this.grades,
      classifications: classifications ?? this.classifications,
      repeatPolicy: repeatPolicy ?? this.repeatPolicy,
      repeatCapPoint: repeatCapPoint ?? this.repeatCapPoint,
      isCustom: isCustom ?? this.isCustom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (institutionId.present) {
      map['institution_id'] = Variable<String>(institutionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom.value);
    }
    if (effectiveUntil.present) {
      map['effective_until'] = Variable<DateTime>(effectiveUntil.value);
    }
    if (maxPoint.present) {
      map['max_point'] = Variable<double>(maxPoint.value);
    }
    if (grades.present) {
      map['grades'] = Variable<String>(
          $GradingSchemesTable.$convertergrades.toSql(grades.value));
    }
    if (classifications.present) {
      map['classifications'] = Variable<String>($GradingSchemesTable
          .$converterclassifications
          .toSql(classifications.value));
    }
    if (repeatPolicy.present) {
      map['repeat_policy'] = Variable<String>($GradingSchemesTable
          .$converterrepeatPolicy
          .toSql(repeatPolicy.value));
    }
    if (repeatCapPoint.present) {
      map['repeat_cap_point'] = Variable<double>(repeatCapPoint.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradingSchemesCompanion(')
          ..write('id: $id, ')
          ..write('institutionId: $institutionId, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveUntil: $effectiveUntil, ')
          ..write('maxPoint: $maxPoint, ')
          ..write('grades: $grades, ')
          ..write('classifications: $classifications, ')
          ..write('repeatPolicy: $repeatPolicy, ')
          ..write('repeatCapPoint: $repeatCapPoint, ')
          ..write('isCustom: $isCustom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bandLabelMeta =
      const VerificationMeta('bandLabel');
  @override
  late final GeneratedColumn<String> bandLabel = GeneratedColumn<String>(
      'band_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bandShortLabelMeta =
      const VerificationMeta('bandShortLabel');
  @override
  late final GeneratedColumn<String> bandShortLabel = GeneratedColumn<String>(
      'band_short_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bandMinCgpaMeta =
      const VerificationMeta('bandMinCgpa');
  @override
  late final GeneratedColumn<double> bandMinCgpa = GeneratedColumn<double>(
      'band_min_cgpa', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bandMaxCgpaMeta =
      const VerificationMeta('bandMaxCgpa');
  @override
  late final GeneratedColumn<double> bandMaxCgpa = GeneratedColumn<double>(
      'band_max_cgpa', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _semestersRemainingMeta =
      const VerificationMeta('semestersRemaining');
  @override
  late final GeneratedColumn<int> semestersRemaining = GeneratedColumn<int>(
      'semesters_remaining', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        profileId,
        bandLabel,
        bandShortLabel,
        bandMinCgpa,
        bandMaxCgpa,
        semestersRemaining,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('band_label')) {
      context.handle(_bandLabelMeta,
          bandLabel.isAcceptableOrUnknown(data['band_label']!, _bandLabelMeta));
    } else if (isInserting) {
      context.missing(_bandLabelMeta);
    }
    if (data.containsKey('band_short_label')) {
      context.handle(
          _bandShortLabelMeta,
          bandShortLabel.isAcceptableOrUnknown(
              data['band_short_label']!, _bandShortLabelMeta));
    } else if (isInserting) {
      context.missing(_bandShortLabelMeta);
    }
    if (data.containsKey('band_min_cgpa')) {
      context.handle(
          _bandMinCgpaMeta,
          bandMinCgpa.isAcceptableOrUnknown(
              data['band_min_cgpa']!, _bandMinCgpaMeta));
    } else if (isInserting) {
      context.missing(_bandMinCgpaMeta);
    }
    if (data.containsKey('band_max_cgpa')) {
      context.handle(
          _bandMaxCgpaMeta,
          bandMaxCgpa.isAcceptableOrUnknown(
              data['band_max_cgpa']!, _bandMaxCgpaMeta));
    } else if (isInserting) {
      context.missing(_bandMaxCgpaMeta);
    }
    if (data.containsKey('semesters_remaining')) {
      context.handle(
          _semestersRemainingMeta,
          semestersRemaining.isAcceptableOrUnknown(
              data['semesters_remaining']!, _semestersRemainingMeta));
    } else if (isInserting) {
      context.missing(_semestersRemainingMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      bandLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}band_label'])!,
      bandShortLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}band_short_label'])!,
      bandMinCgpa: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}band_min_cgpa'])!,
      bandMaxCgpa: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}band_max_cgpa'])!,
      semestersRemaining: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}semesters_remaining'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String profileId;
  final String bandLabel;
  final String bandShortLabel;
  final double bandMinCgpa;
  final double bandMaxCgpa;
  final int semestersRemaining;
  final DateTime updatedAt;
  const Goal(
      {required this.profileId,
      required this.bandLabel,
      required this.bandShortLabel,
      required this.bandMinCgpa,
      required this.bandMaxCgpa,
      required this.semestersRemaining,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<String>(profileId);
    map['band_label'] = Variable<String>(bandLabel);
    map['band_short_label'] = Variable<String>(bandShortLabel);
    map['band_min_cgpa'] = Variable<double>(bandMinCgpa);
    map['band_max_cgpa'] = Variable<double>(bandMaxCgpa);
    map['semesters_remaining'] = Variable<int>(semestersRemaining);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      profileId: Value(profileId),
      bandLabel: Value(bandLabel),
      bandShortLabel: Value(bandShortLabel),
      bandMinCgpa: Value(bandMinCgpa),
      bandMaxCgpa: Value(bandMaxCgpa),
      semestersRemaining: Value(semestersRemaining),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      profileId: serializer.fromJson<String>(json['profileId']),
      bandLabel: serializer.fromJson<String>(json['bandLabel']),
      bandShortLabel: serializer.fromJson<String>(json['bandShortLabel']),
      bandMinCgpa: serializer.fromJson<double>(json['bandMinCgpa']),
      bandMaxCgpa: serializer.fromJson<double>(json['bandMaxCgpa']),
      semestersRemaining: serializer.fromJson<int>(json['semestersRemaining']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<String>(profileId),
      'bandLabel': serializer.toJson<String>(bandLabel),
      'bandShortLabel': serializer.toJson<String>(bandShortLabel),
      'bandMinCgpa': serializer.toJson<double>(bandMinCgpa),
      'bandMaxCgpa': serializer.toJson<double>(bandMaxCgpa),
      'semestersRemaining': serializer.toJson<int>(semestersRemaining),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith(
          {String? profileId,
          String? bandLabel,
          String? bandShortLabel,
          double? bandMinCgpa,
          double? bandMaxCgpa,
          int? semestersRemaining,
          DateTime? updatedAt}) =>
      Goal(
        profileId: profileId ?? this.profileId,
        bandLabel: bandLabel ?? this.bandLabel,
        bandShortLabel: bandShortLabel ?? this.bandShortLabel,
        bandMinCgpa: bandMinCgpa ?? this.bandMinCgpa,
        bandMaxCgpa: bandMaxCgpa ?? this.bandMaxCgpa,
        semestersRemaining: semestersRemaining ?? this.semestersRemaining,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      bandLabel: data.bandLabel.present ? data.bandLabel.value : this.bandLabel,
      bandShortLabel: data.bandShortLabel.present
          ? data.bandShortLabel.value
          : this.bandShortLabel,
      bandMinCgpa:
          data.bandMinCgpa.present ? data.bandMinCgpa.value : this.bandMinCgpa,
      bandMaxCgpa:
          data.bandMaxCgpa.present ? data.bandMaxCgpa.value : this.bandMaxCgpa,
      semestersRemaining: data.semestersRemaining.present
          ? data.semestersRemaining.value
          : this.semestersRemaining,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('profileId: $profileId, ')
          ..write('bandLabel: $bandLabel, ')
          ..write('bandShortLabel: $bandShortLabel, ')
          ..write('bandMinCgpa: $bandMinCgpa, ')
          ..write('bandMaxCgpa: $bandMaxCgpa, ')
          ..write('semestersRemaining: $semestersRemaining, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, bandLabel, bandShortLabel,
      bandMinCgpa, bandMaxCgpa, semestersRemaining, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.profileId == this.profileId &&
          other.bandLabel == this.bandLabel &&
          other.bandShortLabel == this.bandShortLabel &&
          other.bandMinCgpa == this.bandMinCgpa &&
          other.bandMaxCgpa == this.bandMaxCgpa &&
          other.semestersRemaining == this.semestersRemaining &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> profileId;
  final Value<String> bandLabel;
  final Value<String> bandShortLabel;
  final Value<double> bandMinCgpa;
  final Value<double> bandMaxCgpa;
  final Value<int> semestersRemaining;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.profileId = const Value.absent(),
    this.bandLabel = const Value.absent(),
    this.bandShortLabel = const Value.absent(),
    this.bandMinCgpa = const Value.absent(),
    this.bandMaxCgpa = const Value.absent(),
    this.semestersRemaining = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String profileId,
    required String bandLabel,
    required String bandShortLabel,
    required double bandMinCgpa,
    required double bandMaxCgpa,
    required int semestersRemaining,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : profileId = Value(profileId),
        bandLabel = Value(bandLabel),
        bandShortLabel = Value(bandShortLabel),
        bandMinCgpa = Value(bandMinCgpa),
        bandMaxCgpa = Value(bandMaxCgpa),
        semestersRemaining = Value(semestersRemaining),
        updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? profileId,
    Expression<String>? bandLabel,
    Expression<String>? bandShortLabel,
    Expression<double>? bandMinCgpa,
    Expression<double>? bandMaxCgpa,
    Expression<int>? semestersRemaining,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (bandLabel != null) 'band_label': bandLabel,
      if (bandShortLabel != null) 'band_short_label': bandShortLabel,
      if (bandMinCgpa != null) 'band_min_cgpa': bandMinCgpa,
      if (bandMaxCgpa != null) 'band_max_cgpa': bandMaxCgpa,
      if (semestersRemaining != null) 'semesters_remaining': semestersRemaining,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith(
      {Value<String>? profileId,
      Value<String>? bandLabel,
      Value<String>? bandShortLabel,
      Value<double>? bandMinCgpa,
      Value<double>? bandMaxCgpa,
      Value<int>? semestersRemaining,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return GoalsCompanion(
      profileId: profileId ?? this.profileId,
      bandLabel: bandLabel ?? this.bandLabel,
      bandShortLabel: bandShortLabel ?? this.bandShortLabel,
      bandMinCgpa: bandMinCgpa ?? this.bandMinCgpa,
      bandMaxCgpa: bandMaxCgpa ?? this.bandMaxCgpa,
      semestersRemaining: semestersRemaining ?? this.semestersRemaining,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (bandLabel.present) {
      map['band_label'] = Variable<String>(bandLabel.value);
    }
    if (bandShortLabel.present) {
      map['band_short_label'] = Variable<String>(bandShortLabel.value);
    }
    if (bandMinCgpa.present) {
      map['band_min_cgpa'] = Variable<double>(bandMinCgpa.value);
    }
    if (bandMaxCgpa.present) {
      map['band_max_cgpa'] = Variable<double>(bandMaxCgpa.value);
    }
    if (semestersRemaining.present) {
      map['semesters_remaining'] = Variable<int>(semestersRemaining.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('profileId: $profileId, ')
          ..write('bandLabel: $bandLabel, ')
          ..write('bandShortLabel: $bandShortLabel, ')
          ..write('bandMinCgpa: $bandMinCgpa, ')
          ..write('bandMaxCgpa: $bandMaxCgpa, ')
          ..write('semestersRemaining: $semestersRemaining, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $CourseResultsTable courseResults = $CourseResultsTable(this);
  late final $GradingSchemesTable gradingSchemes = $GradingSchemesTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final SemesterDao semesterDao = SemesterDao(this as AppDatabase);
  late final CourseResultDao courseResultDao =
      CourseResultDao(this as AppDatabase);
  late final GradingSchemeDao gradingSchemeDao =
      GradingSchemeDao(this as AppDatabase);
  late final GoalDao goalDao = GoalDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [profiles, semesters, courseResults, gradingSchemes, goals];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String fullName,
  required String regNumber,
  required String department,
  required int currentLevel,
  required int entryYear,
  required int expectedGraduationYear,
  Value<String?> activeSchemeId,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> fullName,
  Value<String> regNumber,
  Value<String> department,
  Value<int> currentLevel,
  Value<int> entryYear,
  Value<int> expectedGraduationYear,
  Value<String?> activeSchemeId,
  Value<DateTime> updatedAt,
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
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regNumber => $composableBuilder(
      column: $table.regNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentLevel => $composableBuilder(
      column: $table.currentLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entryYear => $composableBuilder(
      column: $table.entryYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expectedGraduationYear => $composableBuilder(
      column: $table.expectedGraduationYear,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeSchemeId => $composableBuilder(
      column: $table.activeSchemeId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
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
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regNumber => $composableBuilder(
      column: $table.regNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentLevel => $composableBuilder(
      column: $table.currentLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entryYear => $composableBuilder(
      column: $table.entryYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expectedGraduationYear => $composableBuilder(
      column: $table.expectedGraduationYear,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeSchemeId => $composableBuilder(
      column: $table.activeSchemeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get regNumber =>
      $composableBuilder(column: $table.regNumber, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => column);

  GeneratedColumn<int> get currentLevel => $composableBuilder(
      column: $table.currentLevel, builder: (column) => column);

  GeneratedColumn<int> get entryYear =>
      $composableBuilder(column: $table.entryYear, builder: (column) => column);

  GeneratedColumn<int> get expectedGraduationYear => $composableBuilder(
      column: $table.expectedGraduationYear, builder: (column) => column);

  GeneratedColumn<String> get activeSchemeId => $composableBuilder(
      column: $table.activeSchemeId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
    Profile,
    PrefetchHooks Function()> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String> regNumber = const Value.absent(),
            Value<String> department = const Value.absent(),
            Value<int> currentLevel = const Value.absent(),
            Value<int> entryYear = const Value.absent(),
            Value<int> expectedGraduationYear = const Value.absent(),
            Value<String?> activeSchemeId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            fullName: fullName,
            regNumber: regNumber,
            department: department,
            currentLevel: currentLevel,
            entryYear: entryYear,
            expectedGraduationYear: expectedGraduationYear,
            activeSchemeId: activeSchemeId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fullName,
            required String regNumber,
            required String department,
            required int currentLevel,
            required int entryYear,
            required int expectedGraduationYear,
            Value<String?> activeSchemeId = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            fullName: fullName,
            regNumber: regNumber,
            department: department,
            currentLevel: currentLevel,
            entryYear: entryYear,
            expectedGraduationYear: expectedGraduationYear,
            activeSchemeId: activeSchemeId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
    Profile,
    PrefetchHooks Function()>;
typedef $$SemestersTableCreateCompanionBuilder = SemestersCompanion Function({
  required String id,
  required String profileId,
  required String session,
  required SemesterTerm term,
  required int level,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SemestersTableUpdateCompanionBuilder = SemestersCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> session,
  Value<SemesterTerm> term,
  Value<int> level,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get session => $composableBuilder(
      column: $table.session, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SemesterTerm, SemesterTerm, String> get term =>
      $composableBuilder(
          column: $table.term,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get session => $composableBuilder(
      column: $table.session, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get session =>
      $composableBuilder(column: $table.session, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SemesterTerm, String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SemestersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SemestersTable,
    SemesterRow,
    $$SemestersTableFilterComposer,
    $$SemestersTableOrderingComposer,
    $$SemestersTableAnnotationComposer,
    $$SemestersTableCreateCompanionBuilder,
    $$SemestersTableUpdateCompanionBuilder,
    (SemesterRow, BaseReferences<_$AppDatabase, $SemestersTable, SemesterRow>),
    SemesterRow,
    PrefetchHooks Function()> {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> session = const Value.absent(),
            Value<SemesterTerm> term = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SemestersCompanion(
            id: id,
            profileId: profileId,
            session: session,
            term: term,
            level: level,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String session,
            required SemesterTerm term,
            required int level,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SemestersCompanion.insert(
            id: id,
            profileId: profileId,
            session: session,
            term: term,
            level: level,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SemestersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SemestersTable,
    SemesterRow,
    $$SemestersTableFilterComposer,
    $$SemestersTableOrderingComposer,
    $$SemestersTableAnnotationComposer,
    $$SemestersTableCreateCompanionBuilder,
    $$SemestersTableUpdateCompanionBuilder,
    (SemesterRow, BaseReferences<_$AppDatabase, $SemestersTable, SemesterRow>),
    SemesterRow,
    PrefetchHooks Function()>;
typedef $$CourseResultsTableCreateCompanionBuilder = CourseResultsCompanion
    Function({
  required String id,
  required String semesterId,
  required String courseCode,
  Value<String?> courseTitle,
  required int creditUnit,
  required String grade,
  Value<int?> score,
  Value<int> attempt,
  Value<String?> supersedesResultId,
  required ResultSource source,
  Value<double?> extractionConfidence,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CourseResultsTableUpdateCompanionBuilder = CourseResultsCompanion
    Function({
  Value<String> id,
  Value<String> semesterId,
  Value<String> courseCode,
  Value<String?> courseTitle,
  Value<int> creditUnit,
  Value<String> grade,
  Value<int?> score,
  Value<int> attempt,
  Value<String?> supersedesResultId,
  Value<ResultSource> source,
  Value<double?> extractionConfidence,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CourseResultsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseResultsTable> {
  $$CourseResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get semesterId => $composableBuilder(
      column: $table.semesterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseTitle => $composableBuilder(
      column: $table.courseTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get creditUnit => $composableBuilder(
      column: $table.creditUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grade => $composableBuilder(
      column: $table.grade, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempt => $composableBuilder(
      column: $table.attempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersedesResultId => $composableBuilder(
      column: $table.supersedesResultId,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ResultSource, ResultSource, String>
      get source => $composableBuilder(
          column: $table.source,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get extractionConfidence => $composableBuilder(
      column: $table.extractionConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CourseResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseResultsTable> {
  $$CourseResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get semesterId => $composableBuilder(
      column: $table.semesterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseTitle => $composableBuilder(
      column: $table.courseTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get creditUnit => $composableBuilder(
      column: $table.creditUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grade => $composableBuilder(
      column: $table.grade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempt => $composableBuilder(
      column: $table.attempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersedesResultId => $composableBuilder(
      column: $table.supersedesResultId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get extractionConfidence => $composableBuilder(
      column: $table.extractionConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CourseResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseResultsTable> {
  $$CourseResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get semesterId => $composableBuilder(
      column: $table.semesterId, builder: (column) => column);

  GeneratedColumn<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => column);

  GeneratedColumn<String> get courseTitle => $composableBuilder(
      column: $table.courseTitle, builder: (column) => column);

  GeneratedColumn<int> get creditUnit => $composableBuilder(
      column: $table.creditUnit, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<String> get supersedesResultId => $composableBuilder(
      column: $table.supersedesResultId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ResultSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get extractionConfidence => $composableBuilder(
      column: $table.extractionConfidence, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CourseResultsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CourseResultsTable,
    CourseResultRow,
    $$CourseResultsTableFilterComposer,
    $$CourseResultsTableOrderingComposer,
    $$CourseResultsTableAnnotationComposer,
    $$CourseResultsTableCreateCompanionBuilder,
    $$CourseResultsTableUpdateCompanionBuilder,
    (
      CourseResultRow,
      BaseReferences<_$AppDatabase, $CourseResultsTable, CourseResultRow>
    ),
    CourseResultRow,
    PrefetchHooks Function()> {
  $$CourseResultsTableTableManager(_$AppDatabase db, $CourseResultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> semesterId = const Value.absent(),
            Value<String> courseCode = const Value.absent(),
            Value<String?> courseTitle = const Value.absent(),
            Value<int> creditUnit = const Value.absent(),
            Value<String> grade = const Value.absent(),
            Value<int?> score = const Value.absent(),
            Value<int> attempt = const Value.absent(),
            Value<String?> supersedesResultId = const Value.absent(),
            Value<ResultSource> source = const Value.absent(),
            Value<double?> extractionConfidence = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CourseResultsCompanion(
            id: id,
            semesterId: semesterId,
            courseCode: courseCode,
            courseTitle: courseTitle,
            creditUnit: creditUnit,
            grade: grade,
            score: score,
            attempt: attempt,
            supersedesResultId: supersedesResultId,
            source: source,
            extractionConfidence: extractionConfidence,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String semesterId,
            required String courseCode,
            Value<String?> courseTitle = const Value.absent(),
            required int creditUnit,
            required String grade,
            Value<int?> score = const Value.absent(),
            Value<int> attempt = const Value.absent(),
            Value<String?> supersedesResultId = const Value.absent(),
            required ResultSource source,
            Value<double?> extractionConfidence = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CourseResultsCompanion.insert(
            id: id,
            semesterId: semesterId,
            courseCode: courseCode,
            courseTitle: courseTitle,
            creditUnit: creditUnit,
            grade: grade,
            score: score,
            attempt: attempt,
            supersedesResultId: supersedesResultId,
            source: source,
            extractionConfidence: extractionConfidence,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CourseResultsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CourseResultsTable,
    CourseResultRow,
    $$CourseResultsTableFilterComposer,
    $$CourseResultsTableOrderingComposer,
    $$CourseResultsTableAnnotationComposer,
    $$CourseResultsTableCreateCompanionBuilder,
    $$CourseResultsTableUpdateCompanionBuilder,
    (
      CourseResultRow,
      BaseReferences<_$AppDatabase, $CourseResultsTable, CourseResultRow>
    ),
    CourseResultRow,
    PrefetchHooks Function()>;
typedef $$GradingSchemesTableCreateCompanionBuilder = GradingSchemesCompanion
    Function({
  required String id,
  required String institutionId,
  required String name,
  required int version,
  required DateTime effectiveFrom,
  Value<DateTime?> effectiveUntil,
  required double maxPoint,
  required List<GradeDefinition> grades,
  required List<ClassificationBand> classifications,
  required RepeatPolicy repeatPolicy,
  Value<double?> repeatCapPoint,
  Value<bool> isCustom,
  Value<int> rowid,
});
typedef $$GradingSchemesTableUpdateCompanionBuilder = GradingSchemesCompanion
    Function({
  Value<String> id,
  Value<String> institutionId,
  Value<String> name,
  Value<int> version,
  Value<DateTime> effectiveFrom,
  Value<DateTime?> effectiveUntil,
  Value<double> maxPoint,
  Value<List<GradeDefinition>> grades,
  Value<List<ClassificationBand>> classifications,
  Value<RepeatPolicy> repeatPolicy,
  Value<double?> repeatCapPoint,
  Value<bool> isCustom,
  Value<int> rowid,
});

class $$GradingSchemesTableFilterComposer
    extends Composer<_$AppDatabase, $GradingSchemesTable> {
  $$GradingSchemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get institutionId => $composableBuilder(
      column: $table.institutionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get effectiveUntil => $composableBuilder(
      column: $table.effectiveUntil,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxPoint => $composableBuilder(
      column: $table.maxPoint, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<GradeDefinition>, List<GradeDefinition>,
          String>
      get grades => $composableBuilder(
          column: $table.grades,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<ClassificationBand>,
          List<ClassificationBand>, String>
      get classifications => $composableBuilder(
          column: $table.classifications,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<RepeatPolicy, RepeatPolicy, String>
      get repeatPolicy => $composableBuilder(
          column: $table.repeatPolicy,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get repeatCapPoint => $composableBuilder(
      column: $table.repeatCapPoint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnFilters(column));
}

class $$GradingSchemesTableOrderingComposer
    extends Composer<_$AppDatabase, $GradingSchemesTable> {
  $$GradingSchemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get institutionId => $composableBuilder(
      column: $table.institutionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get effectiveUntil => $composableBuilder(
      column: $table.effectiveUntil,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxPoint => $composableBuilder(
      column: $table.maxPoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grades => $composableBuilder(
      column: $table.grades, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classifications => $composableBuilder(
      column: $table.classifications,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatPolicy => $composableBuilder(
      column: $table.repeatPolicy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get repeatCapPoint => $composableBuilder(
      column: $table.repeatCapPoint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnOrderings(column));
}

class $$GradingSchemesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradingSchemesTable> {
  $$GradingSchemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get institutionId => $composableBuilder(
      column: $table.institutionId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveUntil => $composableBuilder(
      column: $table.effectiveUntil, builder: (column) => column);

  GeneratedColumn<double> get maxPoint =>
      $composableBuilder(column: $table.maxPoint, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<GradeDefinition>, String> get grades =>
      $composableBuilder(column: $table.grades, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<ClassificationBand>, String>
      get classifications => $composableBuilder(
          column: $table.classifications, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RepeatPolicy, String> get repeatPolicy =>
      $composableBuilder(
          column: $table.repeatPolicy, builder: (column) => column);

  GeneratedColumn<double> get repeatCapPoint => $composableBuilder(
      column: $table.repeatCapPoint, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);
}

class $$GradingSchemesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GradingSchemesTable,
    GradingSchemeRow,
    $$GradingSchemesTableFilterComposer,
    $$GradingSchemesTableOrderingComposer,
    $$GradingSchemesTableAnnotationComposer,
    $$GradingSchemesTableCreateCompanionBuilder,
    $$GradingSchemesTableUpdateCompanionBuilder,
    (
      GradingSchemeRow,
      BaseReferences<_$AppDatabase, $GradingSchemesTable, GradingSchemeRow>
    ),
    GradingSchemeRow,
    PrefetchHooks Function()> {
  $$GradingSchemesTableTableManager(
      _$AppDatabase db, $GradingSchemesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradingSchemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradingSchemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradingSchemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> institutionId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> effectiveFrom = const Value.absent(),
            Value<DateTime?> effectiveUntil = const Value.absent(),
            Value<double> maxPoint = const Value.absent(),
            Value<List<GradeDefinition>> grades = const Value.absent(),
            Value<List<ClassificationBand>> classifications =
                const Value.absent(),
            Value<RepeatPolicy> repeatPolicy = const Value.absent(),
            Value<double?> repeatCapPoint = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GradingSchemesCompanion(
            id: id,
            institutionId: institutionId,
            name: name,
            version: version,
            effectiveFrom: effectiveFrom,
            effectiveUntil: effectiveUntil,
            maxPoint: maxPoint,
            grades: grades,
            classifications: classifications,
            repeatPolicy: repeatPolicy,
            repeatCapPoint: repeatCapPoint,
            isCustom: isCustom,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String institutionId,
            required String name,
            required int version,
            required DateTime effectiveFrom,
            Value<DateTime?> effectiveUntil = const Value.absent(),
            required double maxPoint,
            required List<GradeDefinition> grades,
            required List<ClassificationBand> classifications,
            required RepeatPolicy repeatPolicy,
            Value<double?> repeatCapPoint = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GradingSchemesCompanion.insert(
            id: id,
            institutionId: institutionId,
            name: name,
            version: version,
            effectiveFrom: effectiveFrom,
            effectiveUntil: effectiveUntil,
            maxPoint: maxPoint,
            grades: grades,
            classifications: classifications,
            repeatPolicy: repeatPolicy,
            repeatCapPoint: repeatCapPoint,
            isCustom: isCustom,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GradingSchemesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GradingSchemesTable,
    GradingSchemeRow,
    $$GradingSchemesTableFilterComposer,
    $$GradingSchemesTableOrderingComposer,
    $$GradingSchemesTableAnnotationComposer,
    $$GradingSchemesTableCreateCompanionBuilder,
    $$GradingSchemesTableUpdateCompanionBuilder,
    (
      GradingSchemeRow,
      BaseReferences<_$AppDatabase, $GradingSchemesTable, GradingSchemeRow>
    ),
    GradingSchemeRow,
    PrefetchHooks Function()>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String profileId,
  required String bandLabel,
  required String bandShortLabel,
  required double bandMinCgpa,
  required double bandMaxCgpa,
  required int semestersRemaining,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> profileId,
  Value<String> bandLabel,
  Value<String> bandShortLabel,
  Value<double> bandMinCgpa,
  Value<double> bandMaxCgpa,
  Value<int> semestersRemaining,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bandLabel => $composableBuilder(
      column: $table.bandLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bandShortLabel => $composableBuilder(
      column: $table.bandShortLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bandMinCgpa => $composableBuilder(
      column: $table.bandMinCgpa, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bandMaxCgpa => $composableBuilder(
      column: $table.bandMaxCgpa, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get semestersRemaining => $composableBuilder(
      column: $table.semestersRemaining,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bandLabel => $composableBuilder(
      column: $table.bandLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bandShortLabel => $composableBuilder(
      column: $table.bandShortLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bandMinCgpa => $composableBuilder(
      column: $table.bandMinCgpa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bandMaxCgpa => $composableBuilder(
      column: $table.bandMaxCgpa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get semestersRemaining => $composableBuilder(
      column: $table.semestersRemaining,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get bandLabel =>
      $composableBuilder(column: $table.bandLabel, builder: (column) => column);

  GeneratedColumn<String> get bandShortLabel => $composableBuilder(
      column: $table.bandShortLabel, builder: (column) => column);

  GeneratedColumn<double> get bandMinCgpa => $composableBuilder(
      column: $table.bandMinCgpa, builder: (column) => column);

  GeneratedColumn<double> get bandMaxCgpa => $composableBuilder(
      column: $table.bandMaxCgpa, builder: (column) => column);

  GeneratedColumn<int> get semestersRemaining => $composableBuilder(
      column: $table.semestersRemaining, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
    Goal,
    PrefetchHooks Function()> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> profileId = const Value.absent(),
            Value<String> bandLabel = const Value.absent(),
            Value<String> bandShortLabel = const Value.absent(),
            Value<double> bandMinCgpa = const Value.absent(),
            Value<double> bandMaxCgpa = const Value.absent(),
            Value<int> semestersRemaining = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion(
            profileId: profileId,
            bandLabel: bandLabel,
            bandShortLabel: bandShortLabel,
            bandMinCgpa: bandMinCgpa,
            bandMaxCgpa: bandMaxCgpa,
            semestersRemaining: semestersRemaining,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String profileId,
            required String bandLabel,
            required String bandShortLabel,
            required double bandMinCgpa,
            required double bandMaxCgpa,
            required int semestersRemaining,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            profileId: profileId,
            bandLabel: bandLabel,
            bandShortLabel: bandShortLabel,
            bandMinCgpa: bandMinCgpa,
            bandMaxCgpa: bandMaxCgpa,
            semestersRemaining: semestersRemaining,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
    Goal,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$CourseResultsTableTableManager get courseResults =>
      $$CourseResultsTableTableManager(_db, _db.courseResults);
  $$GradingSchemesTableTableManager get gradingSchemes =>
      $$GradingSchemesTableTableManager(_db, _db.gradingSchemes);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
}
