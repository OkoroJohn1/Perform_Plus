/// Seed data for Nigerian institutions.
///
/// IMPORTANT — VERIFY BEFORE SHIPPING:
/// These schemes are reasonable defaults, not verified transcripts of
/// official policy. Every one must be checked against the institution's
/// current student handbook before release, and the carryover policy in
/// particular must be confirmed with the registry. A wrong repeat policy
/// produces a plausible-looking wrong CGPA, which is worse than an obvious
/// error because the student will not know to question it.
///
/// The `Other (custom)` entry exists so a student at an unlisted school —
/// or one whose department deviates — is never blocked.
library;

import '../../domain/models/grading_scheme.dart';

class Institution {
  final String id;
  final String name;
  final String abbreviation;
  final String state;
  final List<String> faculties;

  const Institution({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.state,
    this.faculties = const [],
  });
}

/// The standard Nigerian 5.0 scale letter grades.
const _standardFivePointGrades = <GradeDefinition>[
  GradeDefinition(letter: 'A', point: 5.0, minScore: 70, maxScore: 100),
  GradeDefinition(letter: 'B', point: 4.0, minScore: 60, maxScore: 69),
  GradeDefinition(letter: 'C', point: 3.0, minScore: 50, maxScore: 59),
  GradeDefinition(letter: 'D', point: 2.0, minScore: 45, maxScore: 49),
  GradeDefinition(letter: 'E', point: 1.0, minScore: 40, maxScore: 44),
  GradeDefinition(letter: 'F', point: 0.0, minScore: 0, maxScore: 39),
];

/// The most widely used classification bands on the 5.0 scale.
/// Note the 2:2 floor — some institutions use 2.40, others 2.50. This is
/// exactly the kind of detail that must be verified per school.
const _standardFivePointBands = <ClassificationBand>[
  ClassificationBand(
    label: 'First Class Honours',
    shortLabel: 'First Class',
    minCgpa: 4.50,
    maxCgpa: 5.00,
  ),
  ClassificationBand(
    label: 'Second Class Honours (Upper Division)',
    shortLabel: '2:1',
    minCgpa: 3.50,
    maxCgpa: 4.49,
  ),
  ClassificationBand(
    label: 'Second Class Honours (Lower Division)',
    shortLabel: '2:2',
    minCgpa: 2.40,
    maxCgpa: 3.49,
  ),
  ClassificationBand(
    label: 'Third Class Honours',
    shortLabel: 'Third Class',
    minCgpa: 1.50,
    maxCgpa: 2.39,
  ),
  ClassificationBand(
    label: 'Pass',
    shortLabel: 'Pass',
    minCgpa: 1.00,
    maxCgpa: 1.49,
  ),
];

const nigerianInstitutions = <Institution>[
  Institution(
    id: 'futo',
    name: 'Federal University of Technology, Owerri',
    abbreviation: 'FUTO',
    state: 'Imo',
    faculties: [
      'School of Engineering and Engineering Technology',
      'School of Information and Communication Technology',
      'School of Physical Sciences',
      'School of Biological Sciences',
      'School of Health Technology',
      'School of Agriculture and Agricultural Technology',
      'School of Environmental Sciences',
      'School of Management Technology',
    ],
  ),
  Institution(
    id: 'unilag',
    name: 'University of Lagos',
    abbreviation: 'UNILAG',
    state: 'Lagos',
  ),
  Institution(
    id: 'ui',
    name: 'University of Ibadan',
    abbreviation: 'UI',
    state: 'Oyo',
  ),
  Institution(
    id: 'unn',
    name: 'University of Nigeria, Nsukka',
    abbreviation: 'UNN',
    state: 'Enugu',
  ),
  Institution(
    id: 'oau',
    name: 'Obafemi Awolowo University',
    abbreviation: 'OAU',
    state: 'Osun',
  ),
  Institution(
    id: 'abu',
    name: 'Ahmadu Bello University',
    abbreviation: 'ABU',
    state: 'Kaduna',
  ),
  Institution(
    id: 'futa',
    name: 'Federal University of Technology, Akure',
    abbreviation: 'FUTA',
    state: 'Ondo',
  ),
  Institution(
    id: 'uniport',
    name: 'University of Port Harcourt',
    abbreviation: 'UNIPORT',
    state: 'Rivers',
  ),
  Institution(
    id: 'covenant',
    name: 'Covenant University',
    abbreviation: 'CU',
    state: 'Ogun',
  ),
  Institution(
    id: 'custom',
    name: 'Other (enter my own scale)',
    abbreviation: 'CUSTOM',
    state: '',
  ),
];

GradingScheme _fivePointScheme({
  required String institutionId,
  required String name,
  RepeatPolicy repeatPolicy = RepeatPolicy.countBothAttempts,
  double? repeatCapPoint,
  List<ClassificationBand>? bands,
}) =>
    GradingScheme(
      id: '${institutionId}_v1',
      institutionId: institutionId,
      name: name,
      version: 1,
      effectiveFrom: DateTime(2015, 1, 1),
      maxPoint: 5.0,
      grades: _standardFivePointGrades,
      classifications: bands ?? _standardFivePointBands,
      repeatPolicy: repeatPolicy,
      repeatCapPoint: repeatCapPoint,
    );

/// Default scheme per institution. Keyed by institution id.
final Map<String, GradingScheme> defaultSchemes = {
  'futo': _fivePointScheme(
    institutionId: 'futo',
    name: 'FUTO 5.0 Scale',
    // VERIFY: FUTO carryover treatment with the registry before release.
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'unilag': _fivePointScheme(
    institutionId: 'unilag',
    name: 'UNILAG 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'ui': _fivePointScheme(
    institutionId: 'ui',
    name: 'UI 7.0 Scale (approximated as 5.0 — VERIFY)',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'unn': _fivePointScheme(
    institutionId: 'unn',
    name: 'UNN 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'oau': _fivePointScheme(
    institutionId: 'oau',
    name: 'OAU 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'abu': _fivePointScheme(
    institutionId: 'abu',
    name: 'ABU 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'futa': _fivePointScheme(
    institutionId: 'futa',
    name: 'FUTA 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'uniport': _fivePointScheme(
    institutionId: 'uniport',
    name: 'UNIPORT 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'covenant': _fivePointScheme(
    institutionId: 'covenant',
    name: 'Covenant 5.0 Scale',
    repeatPolicy: RepeatPolicy.replaceOriginal,
  ),
  'custom': _fivePointScheme(
    institutionId: 'custom',
    name: 'Custom Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ).copyWith(isCustom: true),
};

/// Fallback used before a student has chosen an institution.
GradingScheme get fallbackScheme => defaultSchemes['custom']!;
