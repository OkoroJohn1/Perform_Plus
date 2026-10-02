import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/domain/models/goal_target.dart';
import 'package:perform_plus/domain/models/note.dart';
import 'package:perform_plus/features/auth/providers/profile_provider.dart';
import 'package:perform_plus/features/me/services/data_export_service.dart';

void main() {
  final profile = StudentProfile(
    fullName: 'Ada Obi',
    regNumber: '20211258122',
    department: 'Computer Science',
    currentLevel: 200,
    entryYear: 2022,
    expectedGraduationYear: 2027,
  );

  final semester = Semester(
    id: 's1',
    profileId: 'local-profile',
    session: '2023/2024',
    term: SemesterTerm.first,
    level: 100,
    results: [
      CourseResult(
        id: 'r1',
        semesterId: 's1',
        courseCode: 'CSC101',
        creditUnit: 3,
        grade: 'A',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final note = Note(
    id: 'n1',
    profileId: 'local-profile',
    title: 'CSC101 lecture notes',
    filePath: '/tmp/n1.pdf',
    fileType: NoteFileType.pdf,
    totalPages: 40,
    colourIndex: 0,
    uploadedAt: DateTime(2024),
  );

  test('produces a payload that round-trips through JSON without loss', () {
    final payload = buildExportPayload(
      profile: profile,
      record: AcademicRecord(semesters: [semester], scheme: defaultSchemes['futo']!),
      notes: [note],
      pagesReadByNote: {'n1': 12},
      goal: GoalTarget(band: defaultSchemes['futo']!.classifications.first, semestersRemaining: 4),
    );

    final encoded = jsonEncode(payload);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;

    expect(decoded['profile']['fullName'], 'Ada Obi');
    expect(decoded['profile']['regNumber'], '20211258122');
    expect((decoded['semesters'] as List).length, 1);
    expect(decoded['semesters'][0]['results'][0]['courseCode'], 'CSC101');
    expect(decoded['semesters'][0]['results'][0]['grade'], 'A');
    expect(decoded['notes'][0]['title'], 'CSC101 lecture notes');
    expect(decoded['notes'][0]['pagesRead'], 12);
    expect(decoded['goal']['semestersRemaining'], 4);
  });

  test('a null profile and no goal export as null, not a crash', () {
    final payload = buildExportPayload(
      profile: null,
      record: AcademicRecord(semesters: const [], scheme: defaultSchemes['futo']!),
      notes: const [],
      pagesReadByNote: const {},
      goal: null,
    );

    final decoded = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;

    expect(decoded['profile'], isNull);
    expect(decoded['goal'], isNull);
    expect(decoded['semesters'], isEmpty);
    expect(decoded['notes'], isEmpty);
  });
}
