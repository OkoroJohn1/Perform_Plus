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
  static const VerificationMeta _facultyMeta =
      const VerificationMeta('faculty');
  @override
  late final GeneratedColumn<String> faculty = GeneratedColumn<String>(
      'faculty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        faculty,
        photoPath,
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
    if (data.containsKey('faculty')) {
      context.handle(_facultyMeta,
          faculty.isAcceptableOrUnknown(data['faculty']!, _facultyMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
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
      faculty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}faculty']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
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
  final String? faculty;
  final String? photoPath;
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
      this.faculty,
      this.photoPath,
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
    if (!nullToAbsent || faculty != null) {
      map['faculty'] = Variable<String>(faculty);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
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
      faculty: faculty == null && nullToAbsent
          ? const Value.absent()
          : Value(faculty),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
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
      faculty: serializer.fromJson<String?>(json['faculty']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
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
      'faculty': serializer.toJson<String?>(faculty),
      'photoPath': serializer.toJson<String?>(photoPath),
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
          Value<String?> faculty = const Value.absent(),
          Value<String?> photoPath = const Value.absent(),
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
        faculty: faculty.present ? faculty.value : this.faculty,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
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
      faculty: data.faculty.present ? data.faculty.value : this.faculty,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
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
          ..write('faculty: $faculty, ')
          ..write('photoPath: $photoPath, ')
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
      faculty,
      photoPath,
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
          other.faculty == this.faculty &&
          other.photoPath == this.photoPath &&
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
  final Value<String?> faculty;
  final Value<String?> photoPath;
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
    this.faculty = const Value.absent(),
    this.photoPath = const Value.absent(),
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
    this.faculty = const Value.absent(),
    this.photoPath = const Value.absent(),
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
    Expression<String>? faculty,
    Expression<String>? photoPath,
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
      if (faculty != null) 'faculty': faculty,
      if (photoPath != null) 'photo_path': photoPath,
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
      Value<String?>? faculty,
      Value<String?>? photoPath,
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
      faculty: faculty ?? this.faculty,
      photoPath: photoPath ?? this.photoPath,
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
    if (faculty.present) {
      map['faculty'] = Variable<String>(faculty.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
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
          ..write('faculty: $faculty, ')
          ..write('photoPath: $photoPath, ')
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
  @override
  late final GeneratedColumnWithTypeConverter<CgpaAggregationMode, String>
      cgpaAggregation = GeneratedColumn<String>(
              'cgpa_aggregation', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(CgpaAggregationMode.creditWeighted.name))
          .withConverter<CgpaAggregationMode>(
              $GradingSchemesTable.$convertercgpaAggregation);
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
  static const VerificationMeta _isVerifiedMeta =
      const VerificationMeta('isVerified');
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
      'is_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_verified" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _firstTermLabelMeta =
      const VerificationMeta('firstTermLabel');
  @override
  late final GeneratedColumn<String> firstTermLabel = GeneratedColumn<String>(
      'first_term_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('First Semester'));
  static const VerificationMeta _secondTermLabelMeta =
      const VerificationMeta('secondTermLabel');
  @override
  late final GeneratedColumn<String> secondTermLabel = GeneratedColumn<String>(
      'second_term_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Second Semester'));
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
        cgpaAggregation,
        isCustom,
        isVerified,
        firstTermLabel,
        secondTermLabel
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
    if (data.containsKey('is_verified')) {
      context.handle(
          _isVerifiedMeta,
          isVerified.isAcceptableOrUnknown(
              data['is_verified']!, _isVerifiedMeta));
    }
    if (data.containsKey('first_term_label')) {
      context.handle(
          _firstTermLabelMeta,
          firstTermLabel.isAcceptableOrUnknown(
              data['first_term_label']!, _firstTermLabelMeta));
    }
    if (data.containsKey('second_term_label')) {
      context.handle(
          _secondTermLabelMeta,
          secondTermLabel.isAcceptableOrUnknown(
              data['second_term_label']!, _secondTermLabelMeta));
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
      cgpaAggregation: $GradingSchemesTable.$convertercgpaAggregation.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}cgpa_aggregation'])!),
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      isVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_verified'])!,
      firstTermLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}first_term_label'])!,
      secondTermLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}second_term_label'])!,
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
  static JsonTypeConverter2<CgpaAggregationMode, String, String>
      $convertercgpaAggregation =
      const EnumNameConverter<CgpaAggregationMode>(CgpaAggregationMode.values);
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
  final CgpaAggregationMode cgpaAggregation;
  final bool isCustom;
  final bool isVerified;
  final String firstTermLabel;
  final String secondTermLabel;
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
      required this.cgpaAggregation,
      required this.isCustom,
      required this.isVerified,
      required this.firstTermLabel,
      required this.secondTermLabel});
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
    {
      map['cgpa_aggregation'] = Variable<String>($GradingSchemesTable
          .$convertercgpaAggregation
          .toSql(cgpaAggregation));
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['is_verified'] = Variable<bool>(isVerified);
    map['first_term_label'] = Variable<String>(firstTermLabel);
    map['second_term_label'] = Variable<String>(secondTermLabel);
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
      cgpaAggregation: Value(cgpaAggregation),
      isCustom: Value(isCustom),
      isVerified: Value(isVerified),
      firstTermLabel: Value(firstTermLabel),
      secondTermLabel: Value(secondTermLabel),
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
      cgpaAggregation: $GradingSchemesTable.$convertercgpaAggregation
          .fromJson(serializer.fromJson<String>(json['cgpaAggregation'])),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      isVerified: serializer.fromJson<bool>(json['isVerified']),
      firstTermLabel: serializer.fromJson<String>(json['firstTermLabel']),
      secondTermLabel: serializer.fromJson<String>(json['secondTermLabel']),
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
      'cgpaAggregation': serializer.toJson<String>($GradingSchemesTable
          .$convertercgpaAggregation
          .toJson(cgpaAggregation)),
      'isCustom': serializer.toJson<bool>(isCustom),
      'isVerified': serializer.toJson<bool>(isVerified),
      'firstTermLabel': serializer.toJson<String>(firstTermLabel),
      'secondTermLabel': serializer.toJson<String>(secondTermLabel),
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
          CgpaAggregationMode? cgpaAggregation,
          bool? isCustom,
          bool? isVerified,
          String? firstTermLabel,
          String? secondTermLabel}) =>
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
        cgpaAggregation: cgpaAggregation ?? this.cgpaAggregation,
        isCustom: isCustom ?? this.isCustom,
        isVerified: isVerified ?? this.isVerified,
        firstTermLabel: firstTermLabel ?? this.firstTermLabel,
        secondTermLabel: secondTermLabel ?? this.secondTermLabel,
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
      cgpaAggregation: data.cgpaAggregation.present
          ? data.cgpaAggregation.value
          : this.cgpaAggregation,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      isVerified:
          data.isVerified.present ? data.isVerified.value : this.isVerified,
      firstTermLabel: data.firstTermLabel.present
          ? data.firstTermLabel.value
          : this.firstTermLabel,
      secondTermLabel: data.secondTermLabel.present
          ? data.secondTermLabel.value
          : this.secondTermLabel,
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
          ..write('cgpaAggregation: $cgpaAggregation, ')
          ..write('isCustom: $isCustom, ')
          ..write('isVerified: $isVerified, ')
          ..write('firstTermLabel: $firstTermLabel, ')
          ..write('secondTermLabel: $secondTermLabel')
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
      cgpaAggregation,
      isCustom,
      isVerified,
      firstTermLabel,
      secondTermLabel);
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
          other.cgpaAggregation == this.cgpaAggregation &&
          other.isCustom == this.isCustom &&
          other.isVerified == this.isVerified &&
          other.firstTermLabel == this.firstTermLabel &&
          other.secondTermLabel == this.secondTermLabel);
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
  final Value<CgpaAggregationMode> cgpaAggregation;
  final Value<bool> isCustom;
  final Value<bool> isVerified;
  final Value<String> firstTermLabel;
  final Value<String> secondTermLabel;
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
    this.cgpaAggregation = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.firstTermLabel = const Value.absent(),
    this.secondTermLabel = const Value.absent(),
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
    this.cgpaAggregation = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.firstTermLabel = const Value.absent(),
    this.secondTermLabel = const Value.absent(),
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
    Expression<String>? cgpaAggregation,
    Expression<bool>? isCustom,
    Expression<bool>? isVerified,
    Expression<String>? firstTermLabel,
    Expression<String>? secondTermLabel,
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
      if (cgpaAggregation != null) 'cgpa_aggregation': cgpaAggregation,
      if (isCustom != null) 'is_custom': isCustom,
      if (isVerified != null) 'is_verified': isVerified,
      if (firstTermLabel != null) 'first_term_label': firstTermLabel,
      if (secondTermLabel != null) 'second_term_label': secondTermLabel,
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
      Value<CgpaAggregationMode>? cgpaAggregation,
      Value<bool>? isCustom,
      Value<bool>? isVerified,
      Value<String>? firstTermLabel,
      Value<String>? secondTermLabel,
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
      cgpaAggregation: cgpaAggregation ?? this.cgpaAggregation,
      isCustom: isCustom ?? this.isCustom,
      isVerified: isVerified ?? this.isVerified,
      firstTermLabel: firstTermLabel ?? this.firstTermLabel,
      secondTermLabel: secondTermLabel ?? this.secondTermLabel,
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
    if (cgpaAggregation.present) {
      map['cgpa_aggregation'] = Variable<String>($GradingSchemesTable
          .$convertercgpaAggregation
          .toSql(cgpaAggregation.value));
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (firstTermLabel.present) {
      map['first_term_label'] = Variable<String>(firstTermLabel.value);
    }
    if (secondTermLabel.present) {
      map['second_term_label'] = Variable<String>(secondTermLabel.value);
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
          ..write('cgpaAggregation: $cgpaAggregation, ')
          ..write('isCustom: $isCustom, ')
          ..write('isVerified: $isVerified, ')
          ..write('firstTermLabel: $firstTermLabel, ')
          ..write('secondTermLabel: $secondTermLabel, ')
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

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<NoteFileType, String> fileType =
      GeneratedColumn<String>('file_type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<NoteFileType>($NotesTable.$converterfileType);
  static const VerificationMeta _totalPagesMeta =
      const VerificationMeta('totalPages');
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
      'total_pages', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colourIndexMeta =
      const VerificationMeta('colourIndex');
  @override
  late final GeneratedColumn<int> colourIndex = GeneratedColumn<int>(
      'colour_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _uploadedAtMeta =
      const VerificationMeta('uploadedAt');
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
      'uploaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
      'last_opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<NoteCategory, String> category =
      GeneratedColumn<String>('category', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('note'))
          .withConverter<NoteCategory>($NotesTable.$convertercategory);
  static const VerificationMeta _courseCodeMeta =
      const VerificationMeta('courseCode');
  @override
  late final GeneratedColumn<String> courseCode = GeneratedColumn<String>(
      'course_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _examYearMeta =
      const VerificationMeta('examYear');
  @override
  late final GeneratedColumn<int> examYear = GeneratedColumn<int>(
      'exam_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _storagePathMeta =
      const VerificationMeta('storagePath');
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
      'storage_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        title,
        filePath,
        fileType,
        totalPages,
        colourIndex,
        uploadedAt,
        lastOpenedAt,
        category,
        courseCode,
        examYear,
        storagePath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<NoteRow> instance,
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('total_pages')) {
      context.handle(
          _totalPagesMeta,
          totalPages.isAcceptableOrUnknown(
              data['total_pages']!, _totalPagesMeta));
    } else if (isInserting) {
      context.missing(_totalPagesMeta);
    }
    if (data.containsKey('colour_index')) {
      context.handle(
          _colourIndexMeta,
          colourIndex.isAcceptableOrUnknown(
              data['colour_index']!, _colourIndexMeta));
    } else if (isInserting) {
      context.missing(_colourIndexMeta);
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
          _uploadedAtMeta,
          uploadedAt.isAcceptableOrUnknown(
              data['uploaded_at']!, _uploadedAtMeta));
    } else if (isInserting) {
      context.missing(_uploadedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    }
    if (data.containsKey('course_code')) {
      context.handle(
          _courseCodeMeta,
          courseCode.isAcceptableOrUnknown(
              data['course_code']!, _courseCodeMeta));
    }
    if (data.containsKey('exam_year')) {
      context.handle(_examYearMeta,
          examYear.isAcceptableOrUnknown(data['exam_year']!, _examYearMeta));
    }
    if (data.containsKey('storage_path')) {
      context.handle(
          _storagePathMeta,
          storagePath.isAcceptableOrUnknown(
              data['storage_path']!, _storagePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileType: $NotesTable.$converterfileType.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_type'])!),
      totalPages: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_pages'])!,
      colourIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}colour_index'])!,
      uploadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}uploaded_at'])!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_opened_at']),
      category: $NotesTable.$convertercategory.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!),
      courseCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_code']),
      examYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exam_year']),
      storagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_path']),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NoteFileType, String, String> $converterfileType =
      const EnumNameConverter<NoteFileType>(NoteFileType.values);
  static JsonTypeConverter2<NoteCategory, String, String> $convertercategory =
      const EnumNameConverter<NoteCategory>(NoteCategory.values);
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String id;
  final String profileId;
  final String title;
  final String filePath;
  final NoteFileType fileType;
  final int totalPages;
  final int colourIndex;
  final DateTime uploadedAt;
  final DateTime? lastOpenedAt;
  final NoteCategory category;
  final String? courseCode;
  final int? examYear;
  final String? storagePath;
  const NoteRow(
      {required this.id,
      required this.profileId,
      required this.title,
      required this.filePath,
      required this.fileType,
      required this.totalPages,
      required this.colourIndex,
      required this.uploadedAt,
      this.lastOpenedAt,
      required this.category,
      this.courseCode,
      this.examYear,
      this.storagePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['title'] = Variable<String>(title);
    map['file_path'] = Variable<String>(filePath);
    {
      map['file_type'] =
          Variable<String>($NotesTable.$converterfileType.toSql(fileType));
    }
    map['total_pages'] = Variable<int>(totalPages);
    map['colour_index'] = Variable<int>(colourIndex);
    map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    {
      map['category'] =
          Variable<String>($NotesTable.$convertercategory.toSql(category));
    }
    if (!nullToAbsent || courseCode != null) {
      map['course_code'] = Variable<String>(courseCode);
    }
    if (!nullToAbsent || examYear != null) {
      map['exam_year'] = Variable<int>(examYear);
    }
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      title: Value(title),
      filePath: Value(filePath),
      fileType: Value(fileType),
      totalPages: Value(totalPages),
      colourIndex: Value(colourIndex),
      uploadedAt: Value(uploadedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      category: Value(category),
      courseCode: courseCode == null && nullToAbsent
          ? const Value.absent()
          : Value(courseCode),
      examYear: examYear == null && nullToAbsent
          ? const Value.absent()
          : Value(examYear),
      storagePath: storagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePath),
    );
  }

  factory NoteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      title: serializer.fromJson<String>(json['title']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileType: $NotesTable.$converterfileType
          .fromJson(serializer.fromJson<String>(json['fileType'])),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      colourIndex: serializer.fromJson<int>(json['colourIndex']),
      uploadedAt: serializer.fromJson<DateTime>(json['uploadedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      category: $NotesTable.$convertercategory
          .fromJson(serializer.fromJson<String>(json['category'])),
      courseCode: serializer.fromJson<String?>(json['courseCode']),
      examYear: serializer.fromJson<int?>(json['examYear']),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'title': serializer.toJson<String>(title),
      'filePath': serializer.toJson<String>(filePath),
      'fileType': serializer
          .toJson<String>($NotesTable.$converterfileType.toJson(fileType)),
      'totalPages': serializer.toJson<int>(totalPages),
      'colourIndex': serializer.toJson<int>(colourIndex),
      'uploadedAt': serializer.toJson<DateTime>(uploadedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'category': serializer
          .toJson<String>($NotesTable.$convertercategory.toJson(category)),
      'courseCode': serializer.toJson<String?>(courseCode),
      'examYear': serializer.toJson<int?>(examYear),
      'storagePath': serializer.toJson<String?>(storagePath),
    };
  }

  NoteRow copyWith(
          {String? id,
          String? profileId,
          String? title,
          String? filePath,
          NoteFileType? fileType,
          int? totalPages,
          int? colourIndex,
          DateTime? uploadedAt,
          Value<DateTime?> lastOpenedAt = const Value.absent(),
          NoteCategory? category,
          Value<String?> courseCode = const Value.absent(),
          Value<int?> examYear = const Value.absent(),
          Value<String?> storagePath = const Value.absent()}) =>
      NoteRow(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        title: title ?? this.title,
        filePath: filePath ?? this.filePath,
        fileType: fileType ?? this.fileType,
        totalPages: totalPages ?? this.totalPages,
        colourIndex: colourIndex ?? this.colourIndex,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        lastOpenedAt:
            lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
        category: category ?? this.category,
        courseCode: courseCode.present ? courseCode.value : this.courseCode,
        examYear: examYear.present ? examYear.value : this.examYear,
        storagePath: storagePath.present ? storagePath.value : this.storagePath,
      );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      title: data.title.present ? data.title.value : this.title,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      totalPages:
          data.totalPages.present ? data.totalPages.value : this.totalPages,
      colourIndex:
          data.colourIndex.present ? data.colourIndex.value : this.colourIndex,
      uploadedAt:
          data.uploadedAt.present ? data.uploadedAt.value : this.uploadedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      category: data.category.present ? data.category.value : this.category,
      courseCode:
          data.courseCode.present ? data.courseCode.value : this.courseCode,
      examYear: data.examYear.present ? data.examYear.value : this.examYear,
      storagePath:
          data.storagePath.present ? data.storagePath.value : this.storagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('totalPages: $totalPages, ')
          ..write('colourIndex: $colourIndex, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('category: $category, ')
          ..write('courseCode: $courseCode, ')
          ..write('examYear: $examYear, ')
          ..write('storagePath: $storagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      title,
      filePath,
      fileType,
      totalPages,
      colourIndex,
      uploadedAt,
      lastOpenedAt,
      category,
      courseCode,
      examYear,
      storagePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.title == this.title &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.totalPages == this.totalPages &&
          other.colourIndex == this.colourIndex &&
          other.uploadedAt == this.uploadedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.category == this.category &&
          other.courseCode == this.courseCode &&
          other.examYear == this.examYear &&
          other.storagePath == this.storagePath);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> title;
  final Value<String> filePath;
  final Value<NoteFileType> fileType;
  final Value<int> totalPages;
  final Value<int> colourIndex;
  final Value<DateTime> uploadedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<NoteCategory> category;
  final Value<String?> courseCode;
  final Value<int?> examYear;
  final Value<String?> storagePath;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.title = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.colourIndex = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.category = const Value.absent(),
    this.courseCode = const Value.absent(),
    this.examYear = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String profileId,
    required String title,
    required String filePath,
    required NoteFileType fileType,
    required int totalPages,
    required int colourIndex,
    required DateTime uploadedAt,
    this.lastOpenedAt = const Value.absent(),
    this.category = const Value.absent(),
    this.courseCode = const Value.absent(),
    this.examYear = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        title = Value(title),
        filePath = Value(filePath),
        fileType = Value(fileType),
        totalPages = Value(totalPages),
        colourIndex = Value(colourIndex),
        uploadedAt = Value(uploadedAt);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? title,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<int>? totalPages,
    Expression<int>? colourIndex,
    Expression<DateTime>? uploadedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<String>? category,
    Expression<String>? courseCode,
    Expression<int>? examYear,
    Expression<String>? storagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (title != null) 'title': title,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (totalPages != null) 'total_pages': totalPages,
      if (colourIndex != null) 'colour_index': colourIndex,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (category != null) 'category': category,
      if (courseCode != null) 'course_code': courseCode,
      if (examYear != null) 'exam_year': examYear,
      if (storagePath != null) 'storage_path': storagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? title,
      Value<String>? filePath,
      Value<NoteFileType>? fileType,
      Value<int>? totalPages,
      Value<int>? colourIndex,
      Value<DateTime>? uploadedAt,
      Value<DateTime?>? lastOpenedAt,
      Value<NoteCategory>? category,
      Value<String?>? courseCode,
      Value<int?>? examYear,
      Value<String?>? storagePath,
      Value<int>? rowid}) {
    return NotesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      totalPages: totalPages ?? this.totalPages,
      colourIndex: colourIndex ?? this.colourIndex,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      category: category ?? this.category,
      courseCode: courseCode ?? this.courseCode,
      examYear: examYear ?? this.examYear,
      storagePath: storagePath ?? this.storagePath,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(
          $NotesTable.$converterfileType.toSql(fileType.value));
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (colourIndex.present) {
      map['colour_index'] = Variable<int>(colourIndex.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
          $NotesTable.$convertercategory.toSql(category.value));
    }
    if (courseCode.present) {
      map['course_code'] = Variable<String>(courseCode.value);
    }
    if (examYear.present) {
      map['exam_year'] = Variable<int>(examYear.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('totalPages: $totalPages, ')
          ..write('colourIndex: $colourIndex, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('category: $category, ')
          ..write('courseCode: $courseCode, ')
          ..write('examYear: $examYear, ')
          ..write('storagePath: $storagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotePagesTable extends NotePages
    with TableInfo<$NotePagesTable, NotePageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotePagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIndexMeta =
      const VerificationMeta('pageIndex');
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
      'page_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
      'read_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dwellSecondsMeta =
      const VerificationMeta('dwellSeconds');
  @override
  late final GeneratedColumn<int> dwellSeconds = GeneratedColumn<int>(
      'dwell_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [noteId, pageIndex, isRead, readAt, dwellSeconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_pages';
  @override
  VerificationContext validateIntegrity(Insertable<NotePageRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(_pageIndexMeta,
          pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta));
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('read_at')) {
      context.handle(_readAtMeta,
          readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta));
    }
    if (data.containsKey('dwell_seconds')) {
      context.handle(
          _dwellSecondsMeta,
          dwellSeconds.isAcceptableOrUnknown(
              data['dwell_seconds']!, _dwellSecondsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, pageIndex};
  @override
  NotePageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotePageRow(
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      pageIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_index'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      readAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}read_at']),
      dwellSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dwell_seconds'])!,
    );
  }

  @override
  $NotePagesTable createAlias(String alias) {
    return $NotePagesTable(attachedDatabase, alias);
  }
}

class NotePageRow extends DataClass implements Insertable<NotePageRow> {
  final String noteId;
  final int pageIndex;
  final bool isRead;
  final DateTime? readAt;
  final int dwellSeconds;
  const NotePageRow(
      {required this.noteId,
      required this.pageIndex,
      required this.isRead,
      this.readAt,
      required this.dwellSeconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['page_index'] = Variable<int>(pageIndex);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    map['dwell_seconds'] = Variable<int>(dwellSeconds);
    return map;
  }

  NotePagesCompanion toCompanion(bool nullToAbsent) {
    return NotePagesCompanion(
      noteId: Value(noteId),
      pageIndex: Value(pageIndex),
      isRead: Value(isRead),
      readAt:
          readAt == null && nullToAbsent ? const Value.absent() : Value(readAt),
      dwellSeconds: Value(dwellSeconds),
    );
  }

  factory NotePageRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotePageRow(
      noteId: serializer.fromJson<String>(json['noteId']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      dwellSeconds: serializer.fromJson<int>(json['dwellSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'isRead': serializer.toJson<bool>(isRead),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'dwellSeconds': serializer.toJson<int>(dwellSeconds),
    };
  }

  NotePageRow copyWith(
          {String? noteId,
          int? pageIndex,
          bool? isRead,
          Value<DateTime?> readAt = const Value.absent(),
          int? dwellSeconds}) =>
      NotePageRow(
        noteId: noteId ?? this.noteId,
        pageIndex: pageIndex ?? this.pageIndex,
        isRead: isRead ?? this.isRead,
        readAt: readAt.present ? readAt.value : this.readAt,
        dwellSeconds: dwellSeconds ?? this.dwellSeconds,
      );
  NotePageRow copyWithCompanion(NotePagesCompanion data) {
    return NotePageRow(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      dwellSeconds: data.dwellSeconds.present
          ? data.dwellSeconds.value
          : this.dwellSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotePageRow(')
          ..write('noteId: $noteId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('dwellSeconds: $dwellSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(noteId, pageIndex, isRead, readAt, dwellSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotePageRow &&
          other.noteId == this.noteId &&
          other.pageIndex == this.pageIndex &&
          other.isRead == this.isRead &&
          other.readAt == this.readAt &&
          other.dwellSeconds == this.dwellSeconds);
}

class NotePagesCompanion extends UpdateCompanion<NotePageRow> {
  final Value<String> noteId;
  final Value<int> pageIndex;
  final Value<bool> isRead;
  final Value<DateTime?> readAt;
  final Value<int> dwellSeconds;
  final Value<int> rowid;
  const NotePagesCompanion({
    this.noteId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    this.dwellSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotePagesCompanion.insert({
    required String noteId,
    required int pageIndex,
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    this.dwellSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : noteId = Value(noteId),
        pageIndex = Value(pageIndex);
  static Insertable<NotePageRow> custom({
    Expression<String>? noteId,
    Expression<int>? pageIndex,
    Expression<bool>? isRead,
    Expression<DateTime>? readAt,
    Expression<int>? dwellSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (isRead != null) 'is_read': isRead,
      if (readAt != null) 'read_at': readAt,
      if (dwellSeconds != null) 'dwell_seconds': dwellSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotePagesCompanion copyWith(
      {Value<String>? noteId,
      Value<int>? pageIndex,
      Value<bool>? isRead,
      Value<DateTime?>? readAt,
      Value<int>? dwellSeconds,
      Value<int>? rowid}) {
    return NotePagesCompanion(
      noteId: noteId ?? this.noteId,
      pageIndex: pageIndex ?? this.pageIndex,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      dwellSeconds: dwellSeconds ?? this.dwellSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (dwellSeconds.present) {
      map['dwell_seconds'] = Variable<int>(dwellSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotePagesCompanion(')
          ..write('noteId: $noteId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('dwellSeconds: $dwellSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _pagesReadMeta =
      const VerificationMeta('pagesRead');
  @override
  late final GeneratedColumn<int> pagesRead = GeneratedColumn<int>(
      'pages_read', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _activeSecondsMeta =
      const VerificationMeta('activeSeconds');
  @override
  late final GeneratedColumn<int> activeSeconds = GeneratedColumn<int>(
      'active_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, noteId, startedAt, endedAt, pagesRead, activeSeconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ReadingSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('pages_read')) {
      context.handle(_pagesReadMeta,
          pagesRead.isAcceptableOrUnknown(data['pages_read']!, _pagesReadMeta));
    } else if (isInserting) {
      context.missing(_pagesReadMeta);
    }
    if (data.containsKey('active_seconds')) {
      context.handle(
          _activeSecondsMeta,
          activeSeconds.isAcceptableOrUnknown(
              data['active_seconds']!, _activeSecondsMeta));
    } else if (isInserting) {
      context.missing(_activeSecondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at'])!,
      pagesRead: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pages_read'])!,
      activeSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}active_seconds'])!,
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSessionRow extends DataClass
    implements Insertable<ReadingSessionRow> {
  final String id;
  final String noteId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int pagesRead;
  final int activeSeconds;
  const ReadingSessionRow(
      {required this.id,
      required this.noteId,
      required this.startedAt,
      required this.endedAt,
      required this.pagesRead,
      required this.activeSeconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['pages_read'] = Variable<int>(pagesRead);
    map['active_seconds'] = Variable<int>(activeSeconds);
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      pagesRead: Value(pagesRead),
      activeSeconds: Value(activeSeconds),
    );
  }

  factory ReadingSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSessionRow(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      pagesRead: serializer.fromJson<int>(json['pagesRead']),
      activeSeconds: serializer.fromJson<int>(json['activeSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'pagesRead': serializer.toJson<int>(pagesRead),
      'activeSeconds': serializer.toJson<int>(activeSeconds),
    };
  }

  ReadingSessionRow copyWith(
          {String? id,
          String? noteId,
          DateTime? startedAt,
          DateTime? endedAt,
          int? pagesRead,
          int? activeSeconds}) =>
      ReadingSessionRow(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        pagesRead: pagesRead ?? this.pagesRead,
        activeSeconds: activeSeconds ?? this.activeSeconds,
      );
  ReadingSessionRow copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSessionRow(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      pagesRead: data.pagesRead.present ? data.pagesRead.value : this.pagesRead,
      activeSeconds: data.activeSeconds.present
          ? data.activeSeconds.value
          : this.activeSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionRow(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('activeSeconds: $activeSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, noteId, startedAt, endedAt, pagesRead, activeSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSessionRow &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.pagesRead == this.pagesRead &&
          other.activeSeconds == this.activeSeconds);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSessionRow> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> pagesRead;
  final Value<int> activeSeconds;
  final Value<int> rowid;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.activeSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    required String id,
    required String noteId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int pagesRead,
    required int activeSeconds,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        startedAt = Value(startedAt),
        endedAt = Value(endedAt),
        pagesRead = Value(pagesRead),
        activeSeconds = Value(activeSeconds);
  static Insertable<ReadingSessionRow> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? pagesRead,
    Expression<int>? activeSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (pagesRead != null) 'pages_read': pagesRead,
      if (activeSeconds != null) 'active_seconds': activeSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? noteId,
      Value<DateTime>? startedAt,
      Value<DateTime>? endedAt,
      Value<int>? pagesRead,
      Value<int>? activeSeconds,
      Value<int>? rowid}) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      pagesRead: pagesRead ?? this.pagesRead,
      activeSeconds: activeSeconds ?? this.activeSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (pagesRead.present) {
      map['pages_read'] = Variable<int>(pagesRead.value);
    }
    if (activeSeconds.present) {
      map['active_seconds'] = Variable<int>(activeSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('activeSeconds: $activeSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyStreaksTable extends StudyStreaks
    with TableInfo<$StudyStreaksTable, StudyStreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyStreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentStreakMeta =
      const VerificationMeta('currentStreak');
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
      'current_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReadDateMeta =
      const VerificationMeta('lastReadDate');
  @override
  late final GeneratedColumn<DateTime> lastReadDate = GeneratedColumn<DateTime>(
      'last_read_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [profileId, currentStreak, lastReadDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_streaks';
  @override
  VerificationContext validateIntegrity(Insertable<StudyStreakRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('current_streak')) {
      context.handle(
          _currentStreakMeta,
          currentStreak.isAcceptableOrUnknown(
              data['current_streak']!, _currentStreakMeta));
    }
    if (data.containsKey('last_read_date')) {
      context.handle(
          _lastReadDateMeta,
          lastReadDate.isAcceptableOrUnknown(
              data['last_read_date']!, _lastReadDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  StudyStreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyStreakRow(
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      currentStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_streak'])!,
      lastReadDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_read_date']),
    );
  }

  @override
  $StudyStreaksTable createAlias(String alias) {
    return $StudyStreaksTable(attachedDatabase, alias);
  }
}

class StudyStreakRow extends DataClass implements Insertable<StudyStreakRow> {
  final String profileId;
  final int currentStreak;
  final DateTime? lastReadDate;
  const StudyStreakRow(
      {required this.profileId,
      required this.currentStreak,
      this.lastReadDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<String>(profileId);
    map['current_streak'] = Variable<int>(currentStreak);
    if (!nullToAbsent || lastReadDate != null) {
      map['last_read_date'] = Variable<DateTime>(lastReadDate);
    }
    return map;
  }

  StudyStreaksCompanion toCompanion(bool nullToAbsent) {
    return StudyStreaksCompanion(
      profileId: Value(profileId),
      currentStreak: Value(currentStreak),
      lastReadDate: lastReadDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadDate),
    );
  }

  factory StudyStreakRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyStreakRow(
      profileId: serializer.fromJson<String>(json['profileId']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      lastReadDate: serializer.fromJson<DateTime?>(json['lastReadDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<String>(profileId),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'lastReadDate': serializer.toJson<DateTime?>(lastReadDate),
    };
  }

  StudyStreakRow copyWith(
          {String? profileId,
          int? currentStreak,
          Value<DateTime?> lastReadDate = const Value.absent()}) =>
      StudyStreakRow(
        profileId: profileId ?? this.profileId,
        currentStreak: currentStreak ?? this.currentStreak,
        lastReadDate:
            lastReadDate.present ? lastReadDate.value : this.lastReadDate,
      );
  StudyStreakRow copyWithCompanion(StudyStreaksCompanion data) {
    return StudyStreakRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      lastReadDate: data.lastReadDate.present
          ? data.lastReadDate.value
          : this.lastReadDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyStreakRow(')
          ..write('profileId: $profileId, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastReadDate: $lastReadDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, currentStreak, lastReadDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyStreakRow &&
          other.profileId == this.profileId &&
          other.currentStreak == this.currentStreak &&
          other.lastReadDate == this.lastReadDate);
}

class StudyStreaksCompanion extends UpdateCompanion<StudyStreakRow> {
  final Value<String> profileId;
  final Value<int> currentStreak;
  final Value<DateTime?> lastReadDate;
  final Value<int> rowid;
  const StudyStreaksCompanion({
    this.profileId = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.lastReadDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyStreaksCompanion.insert({
    required String profileId,
    this.currentStreak = const Value.absent(),
    this.lastReadDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId);
  static Insertable<StudyStreakRow> custom({
    Expression<String>? profileId,
    Expression<int>? currentStreak,
    Expression<DateTime>? lastReadDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (lastReadDate != null) 'last_read_date': lastReadDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyStreaksCompanion copyWith(
      {Value<String>? profileId,
      Value<int>? currentStreak,
      Value<DateTime?>? lastReadDate,
      Value<int>? rowid}) {
    return StudyStreaksCompanion(
      profileId: profileId ?? this.profileId,
      currentStreak: currentStreak ?? this.currentStreak,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (lastReadDate.present) {
      map['last_read_date'] = Variable<DateTime>(lastReadDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyStreaksCompanion(')
          ..write('profileId: $profileId, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastReadDate: $lastReadDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, AchievementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<BadgeId, String> badgeId =
      GeneratedColumn<String>('badge_id', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<BadgeId>($AchievementsTable.$converterbadgeId);
  static const VerificationMeta _unlockedAtMeta =
      const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
      'unlocked_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, profileId, badgeId, unlockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(Insertable<AchievementRow> instance,
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
    if (data.containsKey('unlocked_at')) {
      context.handle(
          _unlockedAtMeta,
          unlockedAt.isAcceptableOrUnknown(
              data['unlocked_at']!, _unlockedAtMeta));
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AchievementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      badgeId: $AchievementsTable.$converterbadgeId.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}badge_id'])!),
      unlockedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}unlocked_at'])!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BadgeId, String, String> $converterbadgeId =
      const EnumNameConverter<BadgeId>(BadgeId.values);
}

class AchievementRow extends DataClass implements Insertable<AchievementRow> {
  final String id;
  final String profileId;
  final BadgeId badgeId;
  final DateTime unlockedAt;
  const AchievementRow(
      {required this.id,
      required this.profileId,
      required this.badgeId,
      required this.unlockedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    {
      map['badge_id'] =
          Variable<String>($AchievementsTable.$converterbadgeId.toSql(badgeId));
    }
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      badgeId: Value(badgeId),
      unlockedAt: Value(unlockedAt),
    );
  }

  factory AchievementRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      badgeId: $AchievementsTable.$converterbadgeId
          .fromJson(serializer.fromJson<String>(json['badgeId'])),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'badgeId': serializer
          .toJson<String>($AchievementsTable.$converterbadgeId.toJson(badgeId)),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
    };
  }

  AchievementRow copyWith(
          {String? id,
          String? profileId,
          BadgeId? badgeId,
          DateTime? unlockedAt}) =>
      AchievementRow(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        badgeId: badgeId ?? this.badgeId,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
  AchievementRow copyWithCompanion(AchievementsCompanion data) {
    return AchievementRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      badgeId: data.badgeId.present ? data.badgeId.value : this.badgeId,
      unlockedAt:
          data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('badgeId: $badgeId, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, badgeId, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.badgeId == this.badgeId &&
          other.unlockedAt == this.unlockedAt);
}

class AchievementsCompanion extends UpdateCompanion<AchievementRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<BadgeId> badgeId;
  final Value<DateTime> unlockedAt;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.badgeId = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required String profileId,
    required BadgeId badgeId,
    required DateTime unlockedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        badgeId = Value(badgeId),
        unlockedAt = Value(unlockedAt);
  static Insertable<AchievementRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? badgeId,
    Expression<DateTime>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (badgeId != null) 'badge_id': badgeId,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<BadgeId>? badgeId,
      Value<DateTime>? unlockedAt,
      Value<int>? rowid}) {
    return AchievementsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      badgeId: badgeId ?? this.badgeId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
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
    if (badgeId.present) {
      map['badge_id'] = Variable<String>(
          $AchievementsTable.$converterbadgeId.toSql(badgeId.value));
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('badgeId: $badgeId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, NotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<AppNotificationType, String>
      type = GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AppNotificationType>(
              $NotificationsTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, String>, String>
      payload = GeneratedColumn<String>('payload', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('{}'))
          .withConverter<Map<String, String>>(
              $NotificationsTable.$converterpayload);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
      'read_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, profileId, type, title, body, payload, createdAt, readAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(Insertable<NotificationRow> instance,
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(_readAtMeta,
          readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      type: $NotificationsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      payload: $NotificationsTable.$converterpayload.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      readAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}read_at']),
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AppNotificationType, String, String>
      $convertertype =
      const EnumNameConverter<AppNotificationType>(AppNotificationType.values);
  static TypeConverter<Map<String, String>, String> $converterpayload =
      const StringMapConverter();
}

class NotificationRow extends DataClass implements Insertable<NotificationRow> {
  final String id;
  final String profileId;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, String> payload;
  final DateTime createdAt;
  final DateTime? readAt;
  const NotificationRow(
      {required this.id,
      required this.profileId,
      required this.type,
      required this.title,
      required this.body,
      required this.payload,
      required this.createdAt,
      this.readAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    {
      map['type'] =
          Variable<String>($NotificationsTable.$convertertype.toSql(type));
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    {
      map['payload'] = Variable<String>(
          $NotificationsTable.$converterpayload.toSql(payload));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      payload: Value(payload),
      createdAt: Value(createdAt),
      readAt:
          readAt == null && nullToAbsent ? const Value.absent() : Value(readAt),
    );
  }

  factory NotificationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      type: $NotificationsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      payload: serializer.fromJson<Map<String, String>>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'type': serializer
          .toJson<String>($NotificationsTable.$convertertype.toJson(type)),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'payload': serializer.toJson<Map<String, String>>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
    };
  }

  NotificationRow copyWith(
          {String? id,
          String? profileId,
          AppNotificationType? type,
          String? title,
          String? body,
          Map<String, String>? payload,
          DateTime? createdAt,
          Value<DateTime?> readAt = const Value.absent()}) =>
      NotificationRow(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        readAt: readAt.present ? readAt.value : this.readAt,
      );
  NotificationRow copyWithCompanion(NotificationsCompanion data) {
    return NotificationRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, type, title, body, payload, createdAt, readAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.readAt == this.readAt);
}

class NotificationsCompanion extends UpdateCompanion<NotificationRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<AppNotificationType> type;
  final Value<String> title;
  final Value<String> body;
  final Value<Map<String, String>> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime?> readAt;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    required String profileId,
    required AppNotificationType type,
    required String title,
    required String body,
    this.payload = const Value.absent(),
    required DateTime createdAt,
    this.readAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        type = Value(type),
        title = Value(title),
        body = Value(body),
        createdAt = Value(createdAt);
  static Insertable<NotificationRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? readAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (readAt != null) 'read_at': readAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<AppNotificationType>? type,
      Value<String>? title,
      Value<String>? body,
      Value<Map<String, String>>? payload,
      Value<DateTime>? createdAt,
      Value<DateTime?>? readAt,
      Value<int>? rowid}) {
    return NotificationsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
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
    if (type.present) {
      map['type'] = Variable<String>(
          $NotificationsTable.$convertertype.toSql(type.value));
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(
          $NotificationsTable.$converterpayload.toSql(payload.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory LocalSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSetting copyWith({String? key, String? value}) => LocalSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarMarksTable extends CalendarMarks
    with TableInfo<$CalendarMarksTable, CalendarMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarMarksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
      [id, profileId, date, note, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_marks';
  @override
  VerificationContext validateIntegrity(Insertable<CalendarMarkRow> instance,
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
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
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
  CalendarMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarMarkRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CalendarMarksTable createAlias(String alias) {
    return $CalendarMarksTable(attachedDatabase, alias);
  }
}

class CalendarMarkRow extends DataClass implements Insertable<CalendarMarkRow> {
  final String id;
  final String profileId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarMarkRow(
      {required this.id,
      required this.profileId,
      required this.date,
      this.note,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarMarksCompanion toCompanion(bool nullToAbsent) {
    return CalendarMarksCompanion(
      id: Value(id),
      profileId: Value(profileId),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarMarkRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarMarkRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
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
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarMarkRow copyWith(
          {String? id,
          String? profileId,
          DateTime? date,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CalendarMarkRow(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        date: date ?? this.date,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CalendarMarkRow copyWithCompanion(CalendarMarksCompanion data) {
    return CalendarMarkRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarMarkRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, date, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarMarkRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.date == this.date &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarMarksCompanion extends UpdateCompanion<CalendarMarkRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<DateTime> date;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalendarMarksCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarMarksCompanion.insert({
    required String id,
    required String profileId,
    required DateTime date,
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        date = Value(date),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CalendarMarkRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarMarksCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<DateTime>? date,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CalendarMarksCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      date: date ?? this.date,
      note: note ?? this.note,
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
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('CalendarMarksCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SlipUploadsTable extends SlipUploads
    with TableInfo<$SlipUploadsTable, SlipUploadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SlipUploadsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _extractedCourseCountMeta =
      const VerificationMeta('extractedCourseCount');
  @override
  late final GeneratedColumn<int> extractedCourseCount = GeneratedColumn<int>(
      'extracted_course_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
      'captured_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, profileId, kind, filePath, extractedCourseCount, capturedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'slip_uploads';
  @override
  VerificationContext validateIntegrity(Insertable<SlipUploadRow> instance,
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
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('extracted_course_count')) {
      context.handle(
          _extractedCourseCountMeta,
          extractedCourseCount.isAcceptableOrUnknown(
              data['extracted_course_count']!, _extractedCourseCountMeta));
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SlipUploadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SlipUploadRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      extractedCourseCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}extracted_course_count']),
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}captured_at'])!,
    );
  }

  @override
  $SlipUploadsTable createAlias(String alias) {
    return $SlipUploadsTable(attachedDatabase, alias);
  }
}

class SlipUploadRow extends DataClass implements Insertable<SlipUploadRow> {
  final String id;
  final String profileId;

  /// Stored as text (`SlipKind.name`) rather than an int index -- same
  /// reasoning as `NoteCategory`'s `textEnum` elsewhere: a reordered enum
  /// can never silently relabel an old row.
  final String kind;
  final String filePath;
  final int? extractedCourseCount;
  final DateTime capturedAt;
  const SlipUploadRow(
      {required this.id,
      required this.profileId,
      required this.kind,
      required this.filePath,
      this.extractedCourseCount,
      required this.capturedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['kind'] = Variable<String>(kind);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || extractedCourseCount != null) {
      map['extracted_course_count'] = Variable<int>(extractedCourseCount);
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    return map;
  }

  SlipUploadsCompanion toCompanion(bool nullToAbsent) {
    return SlipUploadsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      kind: Value(kind),
      filePath: Value(filePath),
      extractedCourseCount: extractedCourseCount == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedCourseCount),
      capturedAt: Value(capturedAt),
    );
  }

  factory SlipUploadRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SlipUploadRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      kind: serializer.fromJson<String>(json['kind']),
      filePath: serializer.fromJson<String>(json['filePath']),
      extractedCourseCount:
          serializer.fromJson<int?>(json['extractedCourseCount']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'kind': serializer.toJson<String>(kind),
      'filePath': serializer.toJson<String>(filePath),
      'extractedCourseCount': serializer.toJson<int?>(extractedCourseCount),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
    };
  }

  SlipUploadRow copyWith(
          {String? id,
          String? profileId,
          String? kind,
          String? filePath,
          Value<int?> extractedCourseCount = const Value.absent(),
          DateTime? capturedAt}) =>
      SlipUploadRow(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        kind: kind ?? this.kind,
        filePath: filePath ?? this.filePath,
        extractedCourseCount: extractedCourseCount.present
            ? extractedCourseCount.value
            : this.extractedCourseCount,
        capturedAt: capturedAt ?? this.capturedAt,
      );
  SlipUploadRow copyWithCompanion(SlipUploadsCompanion data) {
    return SlipUploadRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      kind: data.kind.present ? data.kind.value : this.kind,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      extractedCourseCount: data.extractedCourseCount.present
          ? data.extractedCourseCount.value
          : this.extractedCourseCount,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SlipUploadRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('filePath: $filePath, ')
          ..write('extractedCourseCount: $extractedCourseCount, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, profileId, kind, filePath, extractedCourseCount, capturedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SlipUploadRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.kind == this.kind &&
          other.filePath == this.filePath &&
          other.extractedCourseCount == this.extractedCourseCount &&
          other.capturedAt == this.capturedAt);
}

class SlipUploadsCompanion extends UpdateCompanion<SlipUploadRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> kind;
  final Value<String> filePath;
  final Value<int?> extractedCourseCount;
  final Value<DateTime> capturedAt;
  final Value<int> rowid;
  const SlipUploadsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.kind = const Value.absent(),
    this.filePath = const Value.absent(),
    this.extractedCourseCount = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SlipUploadsCompanion.insert({
    required String id,
    required String profileId,
    required String kind,
    required String filePath,
    this.extractedCourseCount = const Value.absent(),
    required DateTime capturedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        kind = Value(kind),
        filePath = Value(filePath),
        capturedAt = Value(capturedAt);
  static Insertable<SlipUploadRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? kind,
    Expression<String>? filePath,
    Expression<int>? extractedCourseCount,
    Expression<DateTime>? capturedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (kind != null) 'kind': kind,
      if (filePath != null) 'file_path': filePath,
      if (extractedCourseCount != null)
        'extracted_course_count': extractedCourseCount,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SlipUploadsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? kind,
      Value<String>? filePath,
      Value<int?>? extractedCourseCount,
      Value<DateTime>? capturedAt,
      Value<int>? rowid}) {
    return SlipUploadsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      kind: kind ?? this.kind,
      filePath: filePath ?? this.filePath,
      extractedCourseCount: extractedCourseCount ?? this.extractedCourseCount,
      capturedAt: capturedAt ?? this.capturedAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (extractedCourseCount.present) {
      map['extracted_course_count'] = Variable<int>(extractedCourseCount.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SlipUploadsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('filePath: $filePath, ')
          ..write('extractedCourseCount: $extractedCourseCount, ')
          ..write('capturedAt: $capturedAt, ')
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
  late final $NotesTable notes = $NotesTable(this);
  late final $NotePagesTable notePages = $NotePagesTable(this);
  late final $ReadingSessionsTable readingSessions =
      $ReadingSessionsTable(this);
  late final $StudyStreaksTable studyStreaks = $StudyStreaksTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $CalendarMarksTable calendarMarks = $CalendarMarksTable(this);
  late final $SlipUploadsTable slipUploads = $SlipUploadsTable(this);
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final SemesterDao semesterDao = SemesterDao(this as AppDatabase);
  late final CourseResultDao courseResultDao =
      CourseResultDao(this as AppDatabase);
  late final GradingSchemeDao gradingSchemeDao =
      GradingSchemeDao(this as AppDatabase);
  late final GoalDao goalDao = GoalDao(this as AppDatabase);
  late final NoteDao noteDao = NoteDao(this as AppDatabase);
  late final AchievementDao achievementDao =
      AchievementDao(this as AppDatabase);
  late final NotificationDao notificationDao =
      NotificationDao(this as AppDatabase);
  late final LocalSettingsDao localSettingsDao =
      LocalSettingsDao(this as AppDatabase);
  late final CalendarMarkDao calendarMarkDao =
      CalendarMarkDao(this as AppDatabase);
  late final SlipUploadDao slipUploadDao = SlipUploadDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        semesters,
        courseResults,
        gradingSchemes,
        goals,
        notes,
        notePages,
        readingSessions,
        studyStreaks,
        achievements,
        notifications,
        localSettings,
        calendarMarks,
        slipUploads
      ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String fullName,
  required String regNumber,
  required String department,
  required int currentLevel,
  required int entryYear,
  required int expectedGraduationYear,
  Value<String?> faculty,
  Value<String?> photoPath,
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
  Value<String?> faculty,
  Value<String?> photoPath,
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

  ColumnFilters<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get faculty =>
      $composableBuilder(column: $table.faculty, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

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
            Value<String?> faculty = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
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
            faculty: faculty,
            photoPath: photoPath,
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
            Value<String?> faculty = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
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
            faculty: faculty,
            photoPath: photoPath,
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
  Value<CgpaAggregationMode> cgpaAggregation,
  Value<bool> isCustom,
  Value<bool> isVerified,
  Value<String> firstTermLabel,
  Value<String> secondTermLabel,
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
  Value<CgpaAggregationMode> cgpaAggregation,
  Value<bool> isCustom,
  Value<bool> isVerified,
  Value<String> firstTermLabel,
  Value<String> secondTermLabel,
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

  ColumnWithTypeConverterFilters<CgpaAggregationMode, CgpaAggregationMode,
          String>
      get cgpaAggregation => $composableBuilder(
          column: $table.cgpaAggregation,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstTermLabel => $composableBuilder(
      column: $table.firstTermLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get secondTermLabel => $composableBuilder(
      column: $table.secondTermLabel,
      builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get cgpaAggregation => $composableBuilder(
      column: $table.cgpaAggregation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstTermLabel => $composableBuilder(
      column: $table.firstTermLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get secondTermLabel => $composableBuilder(
      column: $table.secondTermLabel,
      builder: (column) => ColumnOrderings(column));
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

  GeneratedColumnWithTypeConverter<CgpaAggregationMode, String>
      get cgpaAggregation => $composableBuilder(
          column: $table.cgpaAggregation, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => column);

  GeneratedColumn<String> get firstTermLabel => $composableBuilder(
      column: $table.firstTermLabel, builder: (column) => column);

  GeneratedColumn<String> get secondTermLabel => $composableBuilder(
      column: $table.secondTermLabel, builder: (column) => column);
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
            Value<CgpaAggregationMode> cgpaAggregation = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<bool> isVerified = const Value.absent(),
            Value<String> firstTermLabel = const Value.absent(),
            Value<String> secondTermLabel = const Value.absent(),
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
            cgpaAggregation: cgpaAggregation,
            isCustom: isCustom,
            isVerified: isVerified,
            firstTermLabel: firstTermLabel,
            secondTermLabel: secondTermLabel,
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
            Value<CgpaAggregationMode> cgpaAggregation = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<bool> isVerified = const Value.absent(),
            Value<String> firstTermLabel = const Value.absent(),
            Value<String> secondTermLabel = const Value.absent(),
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
            cgpaAggregation: cgpaAggregation,
            isCustom: isCustom,
            isVerified: isVerified,
            firstTermLabel: firstTermLabel,
            secondTermLabel: secondTermLabel,
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
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  required String profileId,
  required String title,
  required String filePath,
  required NoteFileType fileType,
  required int totalPages,
  required int colourIndex,
  required DateTime uploadedAt,
  Value<DateTime?> lastOpenedAt,
  Value<NoteCategory> category,
  Value<String?> courseCode,
  Value<int?> examYear,
  Value<String?> storagePath,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> title,
  Value<String> filePath,
  Value<NoteFileType> fileType,
  Value<int> totalPages,
  Value<int> colourIndex,
  Value<DateTime> uploadedAt,
  Value<DateTime?> lastOpenedAt,
  Value<NoteCategory> category,
  Value<String?> courseCode,
  Value<int?> examYear,
  Value<String?> storagePath,
  Value<int> rowid,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<NoteFileType, NoteFileType, String>
      get fileType => $composableBuilder(
          column: $table.fileType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get totalPages => $composableBuilder(
      column: $table.totalPages, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colourIndex => $composableBuilder(
      column: $table.colourIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<NoteCategory, NoteCategory, String>
      get category => $composableBuilder(
          column: $table.category,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get examYear => $composableBuilder(
      column: $table.examYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnFilters(column));
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalPages => $composableBuilder(
      column: $table.totalPages, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colourIndex => $composableBuilder(
      column: $table.colourIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get examYear => $composableBuilder(
      column: $table.examYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NoteFileType, String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<int> get totalPages => $composableBuilder(
      column: $table.totalPages, builder: (column) => column);

  GeneratedColumn<int> get colourIndex => $composableBuilder(
      column: $table.colourIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NoteCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => column);

  GeneratedColumn<int> get examYear =>
      $composableBuilder(column: $table.examYear, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => column);
}

class $$NotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTable,
    NoteRow,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
    NoteRow,
    PrefetchHooks Function()> {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<NoteFileType> fileType = const Value.absent(),
            Value<int> totalPages = const Value.absent(),
            Value<int> colourIndex = const Value.absent(),
            Value<DateTime> uploadedAt = const Value.absent(),
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<NoteCategory> category = const Value.absent(),
            Value<String?> courseCode = const Value.absent(),
            Value<int?> examYear = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotesCompanion(
            id: id,
            profileId: profileId,
            title: title,
            filePath: filePath,
            fileType: fileType,
            totalPages: totalPages,
            colourIndex: colourIndex,
            uploadedAt: uploadedAt,
            lastOpenedAt: lastOpenedAt,
            category: category,
            courseCode: courseCode,
            examYear: examYear,
            storagePath: storagePath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String title,
            required String filePath,
            required NoteFileType fileType,
            required int totalPages,
            required int colourIndex,
            required DateTime uploadedAt,
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<NoteCategory> category = const Value.absent(),
            Value<String?> courseCode = const Value.absent(),
            Value<int?> examYear = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotesCompanion.insert(
            id: id,
            profileId: profileId,
            title: title,
            filePath: filePath,
            fileType: fileType,
            totalPages: totalPages,
            colourIndex: colourIndex,
            uploadedAt: uploadedAt,
            lastOpenedAt: lastOpenedAt,
            category: category,
            courseCode: courseCode,
            examYear: examYear,
            storagePath: storagePath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTable,
    NoteRow,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
    NoteRow,
    PrefetchHooks Function()>;
typedef $$NotePagesTableCreateCompanionBuilder = NotePagesCompanion Function({
  required String noteId,
  required int pageIndex,
  Value<bool> isRead,
  Value<DateTime?> readAt,
  Value<int> dwellSeconds,
  Value<int> rowid,
});
typedef $$NotePagesTableUpdateCompanionBuilder = NotePagesCompanion Function({
  Value<String> noteId,
  Value<int> pageIndex,
  Value<bool> isRead,
  Value<DateTime?> readAt,
  Value<int> dwellSeconds,
  Value<int> rowid,
});

class $$NotePagesTableFilterComposer
    extends Composer<_$AppDatabase, $NotePagesTable> {
  $$NotePagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dwellSeconds => $composableBuilder(
      column: $table.dwellSeconds, builder: (column) => ColumnFilters(column));
}

class $$NotePagesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotePagesTable> {
  $$NotePagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dwellSeconds => $composableBuilder(
      column: $table.dwellSeconds,
      builder: (column) => ColumnOrderings(column));
}

class $$NotePagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotePagesTable> {
  $$NotePagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<int> get dwellSeconds => $composableBuilder(
      column: $table.dwellSeconds, builder: (column) => column);
}

class $$NotePagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotePagesTable,
    NotePageRow,
    $$NotePagesTableFilterComposer,
    $$NotePagesTableOrderingComposer,
    $$NotePagesTableAnnotationComposer,
    $$NotePagesTableCreateCompanionBuilder,
    $$NotePagesTableUpdateCompanionBuilder,
    (NotePageRow, BaseReferences<_$AppDatabase, $NotePagesTable, NotePageRow>),
    NotePageRow,
    PrefetchHooks Function()> {
  $$NotePagesTableTableManager(_$AppDatabase db, $NotePagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotePagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotePagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotePagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> noteId = const Value.absent(),
            Value<int> pageIndex = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime?> readAt = const Value.absent(),
            Value<int> dwellSeconds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotePagesCompanion(
            noteId: noteId,
            pageIndex: pageIndex,
            isRead: isRead,
            readAt: readAt,
            dwellSeconds: dwellSeconds,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String noteId,
            required int pageIndex,
            Value<bool> isRead = const Value.absent(),
            Value<DateTime?> readAt = const Value.absent(),
            Value<int> dwellSeconds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotePagesCompanion.insert(
            noteId: noteId,
            pageIndex: pageIndex,
            isRead: isRead,
            readAt: readAt,
            dwellSeconds: dwellSeconds,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotePagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotePagesTable,
    NotePageRow,
    $$NotePagesTableFilterComposer,
    $$NotePagesTableOrderingComposer,
    $$NotePagesTableAnnotationComposer,
    $$NotePagesTableCreateCompanionBuilder,
    $$NotePagesTableUpdateCompanionBuilder,
    (NotePageRow, BaseReferences<_$AppDatabase, $NotePagesTable, NotePageRow>),
    NotePageRow,
    PrefetchHooks Function()>;
typedef $$ReadingSessionsTableCreateCompanionBuilder = ReadingSessionsCompanion
    Function({
  required String id,
  required String noteId,
  required DateTime startedAt,
  required DateTime endedAt,
  required int pagesRead,
  required int activeSeconds,
  Value<int> rowid,
});
typedef $$ReadingSessionsTableUpdateCompanionBuilder = ReadingSessionsCompanion
    Function({
  Value<String> id,
  Value<String> noteId,
  Value<DateTime> startedAt,
  Value<DateTime> endedAt,
  Value<int> pagesRead,
  Value<int> activeSeconds,
  Value<int> rowid,
});

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pagesRead => $composableBuilder(
      column: $table.pagesRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activeSeconds => $composableBuilder(
      column: $table.activeSeconds, builder: (column) => ColumnFilters(column));
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pagesRead => $composableBuilder(
      column: $table.pagesRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activeSeconds => $composableBuilder(
      column: $table.activeSeconds,
      builder: (column) => ColumnOrderings(column));
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get pagesRead =>
      $composableBuilder(column: $table.pagesRead, builder: (column) => column);

  GeneratedColumn<int> get activeSeconds => $composableBuilder(
      column: $table.activeSeconds, builder: (column) => column);
}

class $$ReadingSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadingSessionsTable,
    ReadingSessionRow,
    $$ReadingSessionsTableFilterComposer,
    $$ReadingSessionsTableOrderingComposer,
    $$ReadingSessionsTableAnnotationComposer,
    $$ReadingSessionsTableCreateCompanionBuilder,
    $$ReadingSessionsTableUpdateCompanionBuilder,
    (
      ReadingSessionRow,
      BaseReferences<_$AppDatabase, $ReadingSessionsTable, ReadingSessionRow>
    ),
    ReadingSessionRow,
    PrefetchHooks Function()> {
  $$ReadingSessionsTableTableManager(
      _$AppDatabase db, $ReadingSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> noteId = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> endedAt = const Value.absent(),
            Value<int> pagesRead = const Value.absent(),
            Value<int> activeSeconds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingSessionsCompanion(
            id: id,
            noteId: noteId,
            startedAt: startedAt,
            endedAt: endedAt,
            pagesRead: pagesRead,
            activeSeconds: activeSeconds,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String noteId,
            required DateTime startedAt,
            required DateTime endedAt,
            required int pagesRead,
            required int activeSeconds,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingSessionsCompanion.insert(
            id: id,
            noteId: noteId,
            startedAt: startedAt,
            endedAt: endedAt,
            pagesRead: pagesRead,
            activeSeconds: activeSeconds,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReadingSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReadingSessionsTable,
    ReadingSessionRow,
    $$ReadingSessionsTableFilterComposer,
    $$ReadingSessionsTableOrderingComposer,
    $$ReadingSessionsTableAnnotationComposer,
    $$ReadingSessionsTableCreateCompanionBuilder,
    $$ReadingSessionsTableUpdateCompanionBuilder,
    (
      ReadingSessionRow,
      BaseReferences<_$AppDatabase, $ReadingSessionsTable, ReadingSessionRow>
    ),
    ReadingSessionRow,
    PrefetchHooks Function()>;
typedef $$StudyStreaksTableCreateCompanionBuilder = StudyStreaksCompanion
    Function({
  required String profileId,
  Value<int> currentStreak,
  Value<DateTime?> lastReadDate,
  Value<int> rowid,
});
typedef $$StudyStreaksTableUpdateCompanionBuilder = StudyStreaksCompanion
    Function({
  Value<String> profileId,
  Value<int> currentStreak,
  Value<DateTime?> lastReadDate,
  Value<int> rowid,
});

class $$StudyStreaksTableFilterComposer
    extends Composer<_$AppDatabase, $StudyStreaksTable> {
  $$StudyStreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReadDate => $composableBuilder(
      column: $table.lastReadDate, builder: (column) => ColumnFilters(column));
}

class $$StudyStreaksTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyStreaksTable> {
  $$StudyStreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReadDate => $composableBuilder(
      column: $table.lastReadDate,
      builder: (column) => ColumnOrderings(column));
}

class $$StudyStreaksTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyStreaksTable> {
  $$StudyStreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReadDate => $composableBuilder(
      column: $table.lastReadDate, builder: (column) => column);
}

class $$StudyStreaksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudyStreaksTable,
    StudyStreakRow,
    $$StudyStreaksTableFilterComposer,
    $$StudyStreaksTableOrderingComposer,
    $$StudyStreaksTableAnnotationComposer,
    $$StudyStreaksTableCreateCompanionBuilder,
    $$StudyStreaksTableUpdateCompanionBuilder,
    (
      StudyStreakRow,
      BaseReferences<_$AppDatabase, $StudyStreaksTable, StudyStreakRow>
    ),
    StudyStreakRow,
    PrefetchHooks Function()> {
  $$StudyStreaksTableTableManager(_$AppDatabase db, $StudyStreaksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyStreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyStreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyStreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> profileId = const Value.absent(),
            Value<int> currentStreak = const Value.absent(),
            Value<DateTime?> lastReadDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudyStreaksCompanion(
            profileId: profileId,
            currentStreak: currentStreak,
            lastReadDate: lastReadDate,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String profileId,
            Value<int> currentStreak = const Value.absent(),
            Value<DateTime?> lastReadDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudyStreaksCompanion.insert(
            profileId: profileId,
            currentStreak: currentStreak,
            lastReadDate: lastReadDate,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudyStreaksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudyStreaksTable,
    StudyStreakRow,
    $$StudyStreaksTableFilterComposer,
    $$StudyStreaksTableOrderingComposer,
    $$StudyStreaksTableAnnotationComposer,
    $$StudyStreaksTableCreateCompanionBuilder,
    $$StudyStreaksTableUpdateCompanionBuilder,
    (
      StudyStreakRow,
      BaseReferences<_$AppDatabase, $StudyStreaksTable, StudyStreakRow>
    ),
    StudyStreakRow,
    PrefetchHooks Function()>;
typedef $$AchievementsTableCreateCompanionBuilder = AchievementsCompanion
    Function({
  required String id,
  required String profileId,
  required BadgeId badgeId,
  required DateTime unlockedAt,
  Value<int> rowid,
});
typedef $$AchievementsTableUpdateCompanionBuilder = AchievementsCompanion
    Function({
  Value<String> id,
  Value<String> profileId,
  Value<BadgeId> badgeId,
  Value<DateTime> unlockedAt,
  Value<int> rowid,
});

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<BadgeId, BadgeId, String> get badgeId =>
      $composableBuilder(
          column: $table.badgeId,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnFilters(column));
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
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

  ColumnOrderings<String> get badgeId => $composableBuilder(
      column: $table.badgeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<BadgeId, String> get badgeId =>
      $composableBuilder(column: $table.badgeId, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => column);
}

class $$AchievementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AchievementsTable,
    AchievementRow,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (
      AchievementRow,
      BaseReferences<_$AppDatabase, $AchievementsTable, AchievementRow>
    ),
    AchievementRow,
    PrefetchHooks Function()> {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<BadgeId> badgeId = const Value.absent(),
            Value<DateTime> unlockedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AchievementsCompanion(
            id: id,
            profileId: profileId,
            badgeId: badgeId,
            unlockedAt: unlockedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required BadgeId badgeId,
            required DateTime unlockedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AchievementsCompanion.insert(
            id: id,
            profileId: profileId,
            badgeId: badgeId,
            unlockedAt: unlockedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AchievementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AchievementsTable,
    AchievementRow,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (
      AchievementRow,
      BaseReferences<_$AppDatabase, $AchievementsTable, AchievementRow>
    ),
    AchievementRow,
    PrefetchHooks Function()>;
typedef $$NotificationsTableCreateCompanionBuilder = NotificationsCompanion
    Function({
  required String id,
  required String profileId,
  required AppNotificationType type,
  required String title,
  required String body,
  Value<Map<String, String>> payload,
  required DateTime createdAt,
  Value<DateTime?> readAt,
  Value<int> rowid,
});
typedef $$NotificationsTableUpdateCompanionBuilder = NotificationsCompanion
    Function({
  Value<String> id,
  Value<String> profileId,
  Value<AppNotificationType> type,
  Value<String> title,
  Value<String> body,
  Value<Map<String, String>> payload,
  Value<DateTime> createdAt,
  Value<DateTime?> readAt,
  Value<int> rowid,
});

class $$NotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<AppNotificationType, AppNotificationType,
          String>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Map<String, String>, Map<String, String>,
          String>
      get payload => $composableBuilder(
          column: $table.payload,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnFilters(column));
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnOrderings(column));
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<AppNotificationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, String>, String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);
}

class $$NotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotificationsTable,
    NotificationRow,
    $$NotificationsTableFilterComposer,
    $$NotificationsTableOrderingComposer,
    $$NotificationsTableAnnotationComposer,
    $$NotificationsTableCreateCompanionBuilder,
    $$NotificationsTableUpdateCompanionBuilder,
    (
      NotificationRow,
      BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>
    ),
    NotificationRow,
    PrefetchHooks Function()> {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<AppNotificationType> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<Map<String, String>> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> readAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationsCompanion(
            id: id,
            profileId: profileId,
            type: type,
            title: title,
            body: body,
            payload: payload,
            createdAt: createdAt,
            readAt: readAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required AppNotificationType type,
            required String title,
            required String body,
            Value<Map<String, String>> payload = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> readAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationsCompanion.insert(
            id: id,
            profileId: profileId,
            type: type,
            title: title,
            body: body,
            payload: payload,
            createdAt: createdAt,
            readAt: readAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotificationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotificationsTable,
    NotificationRow,
    $$NotificationsTableFilterComposer,
    $$NotificationsTableOrderingComposer,
    $$NotificationsTableAnnotationComposer,
    $$NotificationsTableCreateCompanionBuilder,
    $$NotificationsTableUpdateCompanionBuilder,
    (
      NotificationRow,
      BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>
    ),
    NotificationRow,
    PrefetchHooks Function()>;
typedef $$LocalSettingsTableCreateCompanionBuilder = LocalSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$LocalSettingsTableUpdateCompanionBuilder = LocalSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSettingsTable,
    LocalSetting,
    $$LocalSettingsTableFilterComposer,
    $$LocalSettingsTableOrderingComposer,
    $$LocalSettingsTableAnnotationComposer,
    $$LocalSettingsTableCreateCompanionBuilder,
    $$LocalSettingsTableUpdateCompanionBuilder,
    (
      LocalSetting,
      BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>
    ),
    LocalSetting,
    PrefetchHooks Function()> {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSettingsTable,
    LocalSetting,
    $$LocalSettingsTableFilterComposer,
    $$LocalSettingsTableOrderingComposer,
    $$LocalSettingsTableAnnotationComposer,
    $$LocalSettingsTableCreateCompanionBuilder,
    $$LocalSettingsTableUpdateCompanionBuilder,
    (
      LocalSetting,
      BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>
    ),
    LocalSetting,
    PrefetchHooks Function()>;
typedef $$CalendarMarksTableCreateCompanionBuilder = CalendarMarksCompanion
    Function({
  required String id,
  required String profileId,
  required DateTime date,
  Value<String?> note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CalendarMarksTableUpdateCompanionBuilder = CalendarMarksCompanion
    Function({
  Value<String> id,
  Value<String> profileId,
  Value<DateTime> date,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CalendarMarksTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarMarksTable> {
  $$CalendarMarksTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CalendarMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarMarksTable> {
  $$CalendarMarksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CalendarMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarMarksTable> {
  $$CalendarMarksTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CalendarMarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalendarMarksTable,
    CalendarMarkRow,
    $$CalendarMarksTableFilterComposer,
    $$CalendarMarksTableOrderingComposer,
    $$CalendarMarksTableAnnotationComposer,
    $$CalendarMarksTableCreateCompanionBuilder,
    $$CalendarMarksTableUpdateCompanionBuilder,
    (
      CalendarMarkRow,
      BaseReferences<_$AppDatabase, $CalendarMarksTable, CalendarMarkRow>
    ),
    CalendarMarkRow,
    PrefetchHooks Function()> {
  $$CalendarMarksTableTableManager(_$AppDatabase db, $CalendarMarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarMarksCompanion(
            id: id,
            profileId: profileId,
            date: date,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required DateTime date,
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarMarksCompanion.insert(
            id: id,
            profileId: profileId,
            date: date,
            note: note,
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

typedef $$CalendarMarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalendarMarksTable,
    CalendarMarkRow,
    $$CalendarMarksTableFilterComposer,
    $$CalendarMarksTableOrderingComposer,
    $$CalendarMarksTableAnnotationComposer,
    $$CalendarMarksTableCreateCompanionBuilder,
    $$CalendarMarksTableUpdateCompanionBuilder,
    (
      CalendarMarkRow,
      BaseReferences<_$AppDatabase, $CalendarMarksTable, CalendarMarkRow>
    ),
    CalendarMarkRow,
    PrefetchHooks Function()>;
typedef $$SlipUploadsTableCreateCompanionBuilder = SlipUploadsCompanion
    Function({
  required String id,
  required String profileId,
  required String kind,
  required String filePath,
  Value<int?> extractedCourseCount,
  required DateTime capturedAt,
  Value<int> rowid,
});
typedef $$SlipUploadsTableUpdateCompanionBuilder = SlipUploadsCompanion
    Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> kind,
  Value<String> filePath,
  Value<int?> extractedCourseCount,
  Value<DateTime> capturedAt,
  Value<int> rowid,
});

class $$SlipUploadsTableFilterComposer
    extends Composer<_$AppDatabase, $SlipUploadsTable> {
  $$SlipUploadsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get extractedCourseCount => $composableBuilder(
      column: $table.extractedCourseCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));
}

class $$SlipUploadsTableOrderingComposer
    extends Composer<_$AppDatabase, $SlipUploadsTable> {
  $$SlipUploadsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get extractedCourseCount => $composableBuilder(
      column: $table.extractedCourseCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));
}

class $$SlipUploadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SlipUploadsTable> {
  $$SlipUploadsTableAnnotationComposer({
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

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get extractedCourseCount => $composableBuilder(
      column: $table.extractedCourseCount, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);
}

class $$SlipUploadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SlipUploadsTable,
    SlipUploadRow,
    $$SlipUploadsTableFilterComposer,
    $$SlipUploadsTableOrderingComposer,
    $$SlipUploadsTableAnnotationComposer,
    $$SlipUploadsTableCreateCompanionBuilder,
    $$SlipUploadsTableUpdateCompanionBuilder,
    (
      SlipUploadRow,
      BaseReferences<_$AppDatabase, $SlipUploadsTable, SlipUploadRow>
    ),
    SlipUploadRow,
    PrefetchHooks Function()> {
  $$SlipUploadsTableTableManager(_$AppDatabase db, $SlipUploadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SlipUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SlipUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SlipUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<int?> extractedCourseCount = const Value.absent(),
            Value<DateTime> capturedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SlipUploadsCompanion(
            id: id,
            profileId: profileId,
            kind: kind,
            filePath: filePath,
            extractedCourseCount: extractedCourseCount,
            capturedAt: capturedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String kind,
            required String filePath,
            Value<int?> extractedCourseCount = const Value.absent(),
            required DateTime capturedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SlipUploadsCompanion.insert(
            id: id,
            profileId: profileId,
            kind: kind,
            filePath: filePath,
            extractedCourseCount: extractedCourseCount,
            capturedAt: capturedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SlipUploadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SlipUploadsTable,
    SlipUploadRow,
    $$SlipUploadsTableFilterComposer,
    $$SlipUploadsTableOrderingComposer,
    $$SlipUploadsTableAnnotationComposer,
    $$SlipUploadsTableCreateCompanionBuilder,
    $$SlipUploadsTableUpdateCompanionBuilder,
    (
      SlipUploadRow,
      BaseReferences<_$AppDatabase, $SlipUploadsTable, SlipUploadRow>
    ),
    SlipUploadRow,
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
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$NotePagesTableTableManager get notePages =>
      $$NotePagesTableTableManager(_db, _db.notePages);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$StudyStreaksTableTableManager get studyStreaks =>
      $$StudyStreaksTableTableManager(_db, _db.studyStreaks);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$CalendarMarksTableTableManager get calendarMarks =>
      $$CalendarMarksTableTableManager(_db, _db.calendarMarks);
  $$SlipUploadsTableTableManager get slipUploads =>
      $$SlipUploadsTableTableManager(_db, _db.slipUploads);
}
